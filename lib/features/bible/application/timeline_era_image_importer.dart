import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../database/project/project_database.dart';
import 'bible_timeline_repository.dart';

/// run236 (Choi: "terapkan juga untuk world building dan timeline") —
/// import gambar referensi era timeline menjadi berkas milik paket.
///
/// Era BUKAN baris `assets` (tidak seperti faksi/lokasi), sehingga tidak
/// punya kolom thumbnail; gambar era hidup di kolom `timeline_eras.image_path`.
/// Kontrak meniru [AssetThumbnailImporter]:
/// - ekstensi gambar dibatasi (.png/.jpg/.jpeg/.webp/.gif); penolakan
///   terjadi sebelum direktori tujuan dibuat (tidak ada artefak tertinggal);
/// - era harus ada dan berkas sumber harus ada;
/// - import ulang menulis salinan baru dulu, baru baris era diperbarui,
///   lalu berkas lama dihapus — hanya berkas di dalam namespace
///   `era_images` yang boleh dihapus.
class TimelineEraImageImporter {
  const TimelineEraImageImporter({
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

  /// Direktori gambar era di dalam paket: `<assets>/era_images/`.
  Directory imageDirectory() =>
      Directory(p.join(assetsDirectory.path, 'era_images'));

  Future<String> importFromFile({
    required String eraId,
    required String sourcePath,
  }) async {
    final repo = BibleTimelineRepository(database);
    final eras = await repo.listErasById(eraId);
    if (eras.isEmpty) {
      throw StateError('Unknown era for image import: $eraId');
    }
    final era = eras.single;

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
    final target = File(p.join(directory.path, '${eraId}_$stamp$extension'));
    // Salin dulu: kegagalan I/O di sini meninggalkan keadaan lama utuh.
    await source.copy(target.path);

    await repo.saveEra(era.copyWith(imagePath: target.path));

    final superseded = era.imagePath;
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
