import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../database/project/project_database.dart';
import 'faction_repository.dart';

/// run236 (Choi: "terapkan juga untuk world building dan timeline") —
/// import gambar lambang/preview faksi menjadi berkas milik paket.
///
/// Faksi BUKAN baris `assets` ([CreateFactionService] hanya menulis tabel
/// Factions), sehingga kolom `assets.thumbnail_path` dan
/// AssetThumbnailImporter tidak berlaku; gambar faksi hidup di kolom
/// `factions.image_path`. Kontrak meniru [AssetThumbnailImporter]:
/// - ekstensi gambar dibatasi (.png/.jpg/.jpeg/.webp/.gif); penolakan
///   terjadi sebelum direktori tujuan dibuat (tidak ada artefak);
/// - faksi dan berkas sumber harus ada;
/// - import ulang menulis salinan baru dulu, baru baris diperbarui, lalu
///   berkas lama dihapus — hanya berkas dalam namespace `faction_images`.
class FactionImageImporter {
  const FactionImageImporter({
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

  /// Direktori gambar faksi di dalam paket: `<assets>/faction_images/`.
  Directory imageDirectory() =>
      Directory(p.join(assetsDirectory.path, 'faction_images'));

  Future<String> importFromFile({
    required String assetId,
    required String sourcePath,
  }) async {
    final repo = FactionRepository(database);
    final faction = await repo.get(assetId);
    if (faction == null) {
      throw StateError('Unknown faction for image import: $assetId');
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

    final directory = imageDirectory();
    await directory.create(recursive: true);

    final stamp = DateTime.now().microsecondsSinceEpoch;
    final target = File(p.join(directory.path, '${assetId}_$stamp$extension'));
    // Salin dulu: kegagalan I/O di sini meninggalkan keadaan lama utuh.
    await source.copy(target.path);

    await repo.save(faction.copyWith(imagePath: target.path));

    final superseded = faction.imagePath;
    if (superseded.isNotEmpty &&
        p.canonicalize(p.dirname(superseded)) ==
            p.canonicalize(directory.path)) {
      try {
        await File(superseded).delete();
      } on FileSystemException {
        // Berkas lama terkunci tidak menggagalkan import; hanya yatim.
      }
    }
    return target.path;
  }
}
