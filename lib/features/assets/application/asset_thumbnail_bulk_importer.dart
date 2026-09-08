import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../database/project/project_database.dart';
import 'asset_thumbnail_importer.dart';

/// Ringkasan satu kali bulk import dari folder gambar referensi.
///
/// - `applied`: assetId -> path thumbnail yang terpasang.
/// - `extraImagesPerAsset`: assetId -> gambar lain di folder yang tidak
///   dipakai (satu aset hanya punya satu slot thumbnail).
/// - `unmatchedFolders`: nama folder tanpa aset yang cocok.
/// - `skippedRootImages`: jumlah gambar lepas langsung di root (tidak bisa
///   diatribusikan ke aset mana pun dari nama foldernya).
class BulkThumbnailSummary {
  const BulkThumbnailSummary({
    required this.applied,
    required this.extraImagesPerAsset,
    required this.unmatchedFolders,
    required this.skippedRootImages,
  });

  final Map<String, String> applied;
  final Map<String, List<String>> extraImagesPerAsset;
  final List<String> unmatchedFolders;
  final int skippedRootImages;
}

/// Import massal thumbnail dari folder referensi per karakter.
///
/// Kontrak:
/// - Setiap sub-folder root dipetakan ke satu aset berdasarkan nama:
///   cocok exact (case-insensitive), lalu prefix — folder
///   "Azrael Noctis ( Demon Lord )" jatuh ke aset "Azrael Noctis";
///   aset terpanjang yang menang agar "Father Qowner" tidak tertukar
///   dengan "Qowner".
/// - Gambar pertama (urut nama byte) menjadi thumbnail via
///   [AssetThumbnailImporter.importFromFile] sehingga aturan penyalinan,
///   penggantian, dan namespace yang sama berlaku.
/// - Folder meta (`_` prefix) dilewati; gambar langsung di root dihitung
///   sebagai skipped, bukan gagal.
/// - Kegagalan I/O pada satu folder tidak menggagalkan folder lain;
///   folder bermasalah masuk [BulkThumbnailSummary.unmatchedFolders]
///   hanya bila penyebabnya pencocokan, sedangkan kegagalan import
///   direthrow (data korup tidak boleh dilaporkan sebagai sukses).
class AssetThumbnailBulkImporter {
  AssetThumbnailBulkImporter({
    required ProjectDatabase database,
    required Directory assetsDirectory,
  }) : _importer = AssetThumbnailImporter(
         database: database,
         assetsDirectory: assetsDirectory,
       );

  final AssetThumbnailImporter _importer;

  Future<BulkThumbnailSummary> importFromFolder({
    required Directory root,
  }) async {
    final assets = await _importer.database.assetDao.getAllAssets();
    final assetsByName = <String, String>{
      for (final asset in assets) asset.name.toLowerCase().trim(): asset.id,
    };
    final sortedNames = assetsByName.keys.toList()..sort();
    final applied = <String, String>{};
    final extraImages = <String, List<String>>{};
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

      final assetId = _matchAsset(folderName, assetsByName, sortedNames);
      if (assetId == null) {
        unmatched.add(folderName);
        continue;
      }

      final images =
          (await entry.list().toList())
              .whereType<File>()
              .where(
                (file) => AssetThumbnailImporter.allowedExtensions.contains(
                  p.extension(file.path).toLowerCase(),
                ),
              )
              .map((file) => p.basename(file.path))
              .toList()
            ..sort();
      if (images.isEmpty) continue;

      final appliedPath = await _importer.importFromFile(
        assetId: assetId,
        sourcePath: p.join(entry.path, images.first),
      );
      applied[assetId] = appliedPath;
      if (images.length > 1) {
        extraImages[assetId] = images.sublist(1);
      }
    }
    unmatched.sort();

    return BulkThumbnailSummary(
      applied: applied,
      extraImagesPerAsset: extraImages,
      unmatchedFolders: unmatched,
      skippedRootImages: skippedRoot,
    );
  }

  /// Exact match (case-insensitive) menang; jika tidak ada, prefix match
  /// dengan nama aset terpanjang (deterministik, sudah diurut).
  String? _matchAsset(
    String folderName,
    Map<String, String> assetsByName,
    List<String> sortedNames,
  ) {
    final needle = folderName.toLowerCase().trim();
    final exact = assetsByName[needle];
    if (exact != null) return exact;
    for (final name in sortedNames) {
      if (needle.startsWith('$name ')) return assetsByName[name]!;
    }
    return null;
  }
}
