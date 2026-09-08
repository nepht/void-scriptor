import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:path/path.dart' as p;

import '../../../database/project/project_database.dart';
import '../../assets/application/asset_folder_matcher.dart';
import '../../assets/application/asset_thumbnail_importer.dart';
import '../domain/reference_models.dart';

/// Ringkasan satu kali bulk reference import.
class BulkReferenceSummary {
  const BulkReferenceSummary({
    required this.importedPerAsset,
    required this.primaryPerAsset,
    required this.filesPerAsset,
    required this.unmatchedFolders,
    required this.skippedRootImages,
  });

  /// assetId -> jumlah baris referensi baru yang dibuat.
  final Map<String, int> importedPerAsset;

  /// assetId -> nama file gambar yang menjadi primary reference.
  final Map<String, String> primaryPerAsset;

  /// assetId -> daftar nama file sumber yang di-import per aset.
  final Map<String, List<String>> filesPerAsset;

  final List<String> unmatchedFolders;
  final int skippedRootImages;
}

/// Import massal gambar referensi per karakter ke tabel `references`
/// (galeri multi-gambar per aset) tanpa menyentuh thumbnail.
///
/// Kontrak:
/// - Matcher yang sama dengan bulk thumbnail ([AssetFolderMatcher]):
///   exact > token-set > prefix; folder `_meta` dan root loose dilaporkan.
/// - Setiap gambar disalin ke `assets/references/<assetId>/<hash12><ext>` dan
///   dibuat baris referensi dengan content hash SHA-256; re-import file yang
///   sama idempoten (tidak menduplikasi baris).
/// - Gambar pertama (urut nama) menjadi primary reference dengan priority
///   tertinggi; sisanya mengikuti urutan menurun.
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

    final imported = <String, int>{};
    final primary = <String, String>{};
    final files = <String, List<String>>{};
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
      final (assetId, _) = match;

      final images = await sortedImageFiles(
        entry,
        AssetThumbnailImporter.allowedExtensions,
      );
      if (images.isEmpty) continue;

      final targetDir = Directory(
        p.join(assetsDirectory.path, 'references', assetId),
      );
      await targetDir.create(recursive: true);

      var created = 0;
      final createdFiles = <String>[];
      for (var i = 0; i < images.length; i++) {
        final source = File(p.join(entry.path, images[i]));
        final bytes = await source.readAsBytes();
        final digest = crypto.sha256.convert(bytes).toString();

        // Idempoten: hash sama untuk project ini tidak dibuat ulang.
        final existing = await database.referenceDao.byContentHash(
          projectId,
          digest,
        );
        if (existing != null) continue;

        final ext = p.extension(images[i]).toLowerCase();
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
          name: images[i],
          filePath: target.path,
          priority: images.length - i,
          primary: i == 0,
          enabled: true,
          contentHash: digest,
        );
        await database.referenceDao.insertReference(reference: reference);
        created++;
        createdFiles.add(images[i]);
        if (i == 0) primary[assetId] = images[i];
      }
      if (created > 0) {
        imported[assetId] = created;
        files[assetId] = createdFiles;
      }
    }
    unmatched.sort();

    return BulkReferenceSummary(
      importedPerAsset: imported,
      primaryPerAsset: primary,
      filesPerAsset: files,
      unmatchedFolders: unmatched,
      skippedRootImages: skippedRoot,
    );
  }

  String _tick() =>
      (DateTime.now().microsecondsSinceEpoch % 1000000).toString();
}
