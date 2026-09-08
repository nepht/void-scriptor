import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;

import '../../../database/project/project_database.dart';
import '../../assets/application/asset_folder_matcher.dart';
import '../../assets/application/asset_thumbnail_importer.dart';
import '../domain/reference_models.dart';

/// Kekuatan pencocokan folder referensi; makin tinggi makin spesifik.
typedef _Strength = AssetFolderMatchStrength;

class _FolderCandidate {
  const _FolderCandidate({
    required this.folderName,
    required this.assetId,
    required this.strength,
    required this.images,
  });

  final String folderName;
  final String assetId;
  final _Strength strength;
  final List<String> images;
}

/// Ringkasan satu kali bulk reference import.
class BulkReferenceSummary {
  const BulkReferenceSummary({
    required this.importedPerAsset,
    required this.primaryPerAsset,
    required this.filesPerAsset,
    required this.unmatchedFolders,
    required this.outcompetedFolders,
    required this.skippedRootImages,
  });

  /// assetId -> jumlah baris referensi baru yang dibuat.
  final Map<String, int> importedPerAsset;

  /// assetId -> nama file sumber yang menjadi primary reference.
  final Map<String, String> primaryPerAsset;

  /// assetId -> daftar nama file sumber yang di-import per aset.
  final Map<String, List<String>> filesPerAsset;

  final List<String> unmatchedFolders;

  /// Folder yang cocok ke aset tetapi kalah dari folder lebih spesifik untuk
  /// aset yang sama (mis. "QOWNER MOTHER" prefix kalah dari "Qowner" exact);
  /// tidak diimport agar galeri aset tetap milik satu sumber terkuat.
  final Map<String, String> outcompetedFolders;

  final int skippedRootImages;
}

/// Import massal gambar referensi per karakter ke tabel `references`
/// (galeri multi-gambar per aset) tanpa menyentuh thumbnail.
///
/// Kontrak:
/// - Matcher bersama dengan bulk thumbnail ([AssetFolderMatcher]); ketika
///   beberapa folder menunjuk aset yang sama, hanya folder terkuat yang
///   diimport (tie: nama folder alfabetis), sisanya dilaporkan di
///   `outcompetedFolders` — tidak ada primary ganda.
/// - Setiap gambar disalin ke `assets/references/<assetId>/<hash12><ext>` dan
///   dibuat baris referensi dengan content hash SHA-256; re-import file yang
///   sama idempoten (tidak menduplikasi baris).
/// - Gambar pertama (urut nama) menjadi satu-satunya primary reference dengan
///   priority tertinggi, ditetapkan via [ReferenceDao.setPrimary] sehingga
///   primary lama dibersihkan dalam scope aset.
/// - Kegagalan I/O direthrow — data korup tidak boleh dilaporkan sukses.
class ReferenceBulkImporter {
  ReferenceBulkImporter({
    required this.database,
    required this.assetsDirectory,
    required this.projectId,
  });

  final ProjectDatabase database;
  final Directory assetsDirectory;
  final String projectId;
  final AssetFolderMatcher _matcher = const AssetFolderMatcher();

  Future<BulkReferenceSummary> importFromFolder({
    required Directory root,
  }) async {
    final assets = await database.assetDao.getAllAssets();
    final assetsByName = <String, String>{
      for (final asset in assets) asset.name.toLowerCase().trim(): asset.id,
    };

    final candidates = <_FolderCandidate>[];
    final unmatched = <String>[];
    var skippedRoot = 0;

    final entries = await root.list().toList();
    for (final entry in entries) {
      if (entry is File) {
        if (AssetThumbnailImporter.allowedExtensions.contains(
          p.extension(entry.path).toLowerCase(),
        )) {
          skippedRoot++;
        }
        continue;
      }
      if (entry is! Directory) continue;
      final folderName = p.basename(entry.path);
      if (folderName.startsWith('_')) continue;

      final match = _matcher.match(folderName, assetsByName);
      if (match == null) {
        unmatched.add(folderName);
        continue;
      }
      final (assetId, strength) = match;
      final images = await sortedImageFiles(
        entry,
        AssetThumbnailImporter.allowedExtensions,
      );
      if (images.isEmpty) continue;
      candidates.add(
        _FolderCandidate(
          folderName: folderName,
          assetId: assetId,
          strength: strength,
          images: images,
        ),
      );
    }
    candidates.sort((a, b) => a.folderName.compareTo(b.folderName));

    // Resolusi kompetisi: folder terkuat per aset menang (folder sudah
    // terurut alfabetis sehingga tie deterministik); lemah dilaporkan.
    final winners = <String, _FolderCandidate>{};
    final outcompeted = <String, String>{};
    for (final candidate in candidates) {
      final incumbent = winners[candidate.assetId];
      if (incumbent == null) {
        winners[candidate.assetId] = candidate;
        continue;
      }
      if (candidate.strength.index > incumbent.strength.index) {
        outcompeted[incumbent.folderName] = candidate.assetId;
        winners[candidate.assetId] = candidate;
      } else {
        outcompeted[candidate.folderName] = candidate.assetId;
      }
    }
    unmatched.sort();

    final imported = <String, int>{};
    final primary = <String, String>{};
    final files = <String, List<String>>{};
    final orderedAssets = winners.keys.toList()..sort();
    for (final assetId in orderedAssets) {
      final candidate = winners[assetId]!;
      final targetDir = Directory(
        p.join(assetsDirectory.path, 'references', assetId),
      );
      await targetDir.create(recursive: true);

      var created = 0;
      final createdFiles = <String>[];
      String? firstImportedId;
      for (var i = 0; i < candidate.images.length; i++) {
        final fileName = candidate.images[i];
        final source = File(p.join(root.path, candidate.folderName, fileName));
        final bytes = await source.readAsBytes();
        final digest = crypto.sha256.convert(bytes).toString();

        // Idempoten: hash sama untuk project ini tidak dibuat ulang.
        final existing = await database.referenceDao.byContentHash(
          projectId,
          digest,
        );
        if (existing != null) {
          firstImportedId ??= existing.id;
          continue;
        }

        final ext = p.extension(fileName).toLowerCase();
        final target = File(
          p.join(targetDir.path, '${digest.substring(0, 12)}$ext'),
        );
        await target.writeAsBytes(bytes);

        final reference = ReferenceModel(
          id: '${digest.substring(0, 8)}-${_tick()}',
          projectId: projectId,
          ownerAssetId: assetId,
          type: ReferenceType.style,
          source: ReferenceSource.imported,
          name: fileName,
          filePath: target.path,
          priority: candidate.images.length - i,
          primary: false,
          enabled: true,
          contentHash: digest,
        );
        await database.referenceDao.insertReference(reference: reference);
        firstImportedId ??= reference.id;
        created++;
        createdFiles.add(fileName);
      }
      if (created > 0) {
        imported[assetId] = created;
        files[assetId] = createdFiles;
        primary[assetId] = candidate.images.first;
      }
      // Integritas: pastikan tepat satu primary per aset. Re-import penuh
      // (created == 0) dengan primary yang sudah ada adalah no-op; bila
      // belum ada primary (batch sebelumnya gagal di tengah), pulihkan.
      final existingRefs = await database.referenceDao.list(
        projectId: projectId,
        ownerAssetId: assetId,
        type: ReferenceType.style,
      );
      if (existingRefs.isNotEmpty &&
          !existingRefs.any((ref) => ref.primaryReference)) {
        await database.referenceDao.setPrimary(
          projectId: projectId,
          ownerAssetId: assetId,
          type: ReferenceType.style,
          referenceId: firstImportedId!,
        );
      }
    }

    return BulkReferenceSummary(
      importedPerAsset: imported,
      primaryPerAsset: primary,
      filesPerAsset: files,
      unmatchedFolders: unmatched,
      outcompetedFolders: outcompeted,
      skippedRootImages: skippedRoot,
    );
  }

  String _tick() =>
      (DateTime.now().microsecondsSinceEpoch % 1000000).toString();
}
