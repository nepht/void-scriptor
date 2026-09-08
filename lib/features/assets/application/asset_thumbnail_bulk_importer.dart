import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../database/project/project_database.dart';
import 'asset_folder_matcher.dart';
import 'asset_thumbnail_importer.dart';

class _FolderCandidate {
  const _FolderCandidate({
    required this.folderName,
    required this.assetId,
    required this.strength,
    required this.images,
  });

  final String folderName;
  final String assetId;
  final AssetFolderMatchStrength strength;
  final List<String> images;
}

/// Ringkasan satu kali bulk import dari folder gambar referensi.
///
/// - `applied`: assetId -> path thumbnail yang terpasang.
/// - `extraImagesPerAsset`: assetId -> gambar lain di folder pemenang yang
///   tidak dipakai (satu aset hanya punya satu slot thumbnail).
/// - `unmatchedFolders`: nama folder tanpa aset yang cocok.
/// - `emptyMatchedFolders`: folder -> assetId; folder yang cocok ke aset
///   tetapi tidak berisi gambar — tidak ada yang bisa diterapkan.
/// - `outcompetedFolders`: folder yang cocok ke aset tetapi kalah dari
///   folder lain yang lebih spesifik untuk aset yang sama (mis. "QOWNER
///   ARMOR" prefix kalah dari "Qowner" exact) — tidak mengubah thumbnail.
/// - `skippedRootImages`: jumlah gambar lepas langsung di root (tidak bisa
///   diatribusikan ke aset mana pun dari nama foldernya).
class BulkThumbnailSummary {
  const BulkThumbnailSummary({
    required this.applied,
    required this.extraImagesPerAsset,
    required this.unmatchedFolders,
    required this.emptyMatchedFolders,
    required this.outcompetedFolders,
    required this.skippedRootImages,
  });

  final Map<String, String> applied;
  final Map<String, List<String>> extraImagesPerAsset;
  final List<String> unmatchedFolders;
  final Map<String, String> emptyMatchedFolders;
  final Map<String, String> outcompetedFolders;
  final int skippedRootImages;
}

/// Import massal thumbnail dari folder referensi per karakter.
///
/// Kontrak:
/// - Setiap sub-folder root dinilai kecocokannya ke aset berdasarkan nama:
///   exact (case-insensitive) > kesamaan himpunan token ("QOWNER FATHER" ->
///   "Father Qowner") > prefix ("Azrael Noctis ( Demon Lord )").
/// - Ketika beberapa folder menunjuk aset yang sama, hanya folder
///   terkuat yang dieksekusi (tie: nama folder alfabetis); folder lemah
///   dilaporkan di `outcompetedFolders` agar thumbnail tidak tertimpa
///   folder sembarangan.
/// - Gambar pertama (urut nama byte) menjadi thumbnail via
///   [AssetThumbnailImporter.importFromFile] sehingga aturan penyalinan,
///   penggantian, dan namespace yang sama berlaku.
/// - Folder meta (`_` prefix) dilewati; gambar langsung di root dihitung
///   sebagai skipped, bukan gagal.
/// - Kegagalan I/O import direthrow: data korup tidak boleh dilaporkan
///   sebagai sukses.
class AssetThumbnailBulkImporter {
  AssetThumbnailBulkImporter({
    required ProjectDatabase database,
    required Directory assetsDirectory,
  }) : _importer = AssetThumbnailImporter(
         database: database,
         assetsDirectory: assetsDirectory,
       );

  final AssetThumbnailImporter _importer;
  final AssetFolderMatcher _matcher = const AssetFolderMatcher();

  Future<BulkThumbnailSummary> importFromFolder({
    required Directory root,
  }) async {
    final assets = await _importer.database.assetDao.getAllAssets();
    final assetsByName = <String, String>{
      for (final asset in assets) asset.name.toLowerCase().trim(): asset.id,
    };

    final candidates = <_FolderCandidate>[];
    final unmatched = <String>[];
    final emptyMatched = <String, String>{};
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
      if (images.isEmpty) {
        emptyMatched[folderName] = assetId;
        continue;
      }
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

    // Resolusi konflik: folder terkuat per aset menang; sisanya dilaporkan.
    // Kandidat sudah terurut nama folder sehingga tie-break deterministik:
    // folder pertama (alfabetis) memegang posisi saat kekuatan sama.
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

    final applied = <String, String>{};
    final extraImages = <String, List<String>>{};
    final thumbnailDirectory = _importer.thumbnailDirectory();
    final orderedAssets = winners.keys.toList()..sort();
    for (final assetId in orderedAssets) {
      final candidate = winners[assetId]!;
      final appliedPath = await _importer.importFromFile(
        assetId: assetId,
        sourcePath: p.join(
          p.join(root.path, candidate.folderName),
          candidate.images.first,
        ),
      );
      applied[assetId] = appliedPath;
      if (candidate.images.length > 1) {
        extraImages[assetId] = candidate.images.sublist(1);
      }
      // Verifikasi namespace: salinan wajib berada di dalam paket.
      assert(
        p
            .canonicalize(p.dirname(appliedPath))
            .startsWith(p.canonicalize(thumbnailDirectory.path)),
      );
    }
    unmatched.sort();

    return BulkThumbnailSummary(
      applied: applied,
      extraImagesPerAsset: extraImages,
      unmatchedFolders: unmatched,
      emptyMatchedFolders: emptyMatched,
      outcompetedFolders: outcompeted,
      skippedRootImages: skippedRoot,
    );
  }
}
