import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../database/project/project_database.dart';

/// Sprint 145.44 - import gambar lokal menjadi thumbnail aset paket.
///
/// Menyalin satu berkas gambar ke namespace aset proyek
/// (`assets/asset_thumbnails/`) lalu mencatat path-nya di kolom
/// `thumbnail_path` milik aset, sehingga asset browser menampilkan
/// referensi visual tanpa bergantung pada berkas di luar paket
/// (sumber asli boleh berpindah/hilang setelah import).
///
/// Kontrak:
/// - Ekstensi gambar dibatasi (.png/.jpg/.jpeg/.webp/.gif); penolakan
///   terjadi sebelum direktori tujuan disiapkan sehingga tidak ada
///   artefak yang tertinggal untuk import yang ditolak.
/// - Berkas sumber harus ada; aset harus ada.
/// - Import ulang menggantikan berkas lama: salinan baru ditulis lebih
///   dulu, baris diperbarui, lalu berkas lama dihapus — hanya berkas di
///   dalam namespace `asset_thumbnails` yang boleh dihapus.
class AssetThumbnailImporter {
  const AssetThumbnailImporter({
    required this.database,
    required this.assetsDirectory,
  });

  final ProjectDatabase database;
  final Directory assetsDirectory;

  static const Set<String> allowedExtensions = <String>{
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
    '.gif',
  };

  /// Direktori thumbnail di dalam paket: `<assets>/asset_thumbnails/`.
  Directory thumbnailDirectory() =>
      Directory(p.join(assetsDirectory.path, 'asset_thumbnails'));

  Future<String> importFromFile({
    required String assetId,
    required String sourcePath,
  }) async {
    final asset = await database.assetDao.getById(assetId);
    if (asset == null) {
      throw StateError('Unknown asset for thumbnail import: $assetId');
    }

    final source = File(sourcePath);
    if (!await source.exists()) {
      throw StateError('Source image does not exist: $sourcePath');
    }

    final extension = p.extension(sourcePath).toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      throw ArgumentError.value(
        sourcePath,
        'sourcePath',
        'Unsupported image extension: $extension',
      );
    }

    final directory = thumbnailDirectory();
    await directory.create(recursive: true);

    final stamp = DateTime.now().microsecondsSinceEpoch;
    final target = File(p.join(directory.path, '${assetId}_$stamp$extension'));
    // Salin dulu: kegagalan I/O di sini meninggalkan keadaan lama utuh.
    await source.copy(target.path);

    final superseded = asset.thumbnailPath;
    try {
      await database.assetDao.setThumbnail(assetId, target.path);
    } on Object {
      // vs-hunt-20260913-importer BUG-4: update gagal = baris masih menunjuk
      // thumbnail lama; hapus salinan baru agar tidak yatim di namespace kita.
      try {
        await target.delete();
      } on FileSystemException {
        // Berkas terkunci: yatim tetap lebih baik daripada menggagalkan
        // laporan kegagalan update yang asli.
      }
      rethrow;
    }

    // Hapus berkas lama hanya bila masih berada di namespace kita;
    // path luar (mis. legacy manual) tidak pernah disentuh.
    if (superseded != null &&
        p.canonicalize(p.dirname(superseded)) ==
            p.canonicalize(directory.path)) {
      try {
        await File(superseded).delete();
      } on FileSystemException {
        // Berkas lama yang terkunci tidak boleh menggagalkan import;
        // ia hanya menyisakan berkas yatim di namespace thumbnail.
      }
    }
    return target.path;
  }
}
