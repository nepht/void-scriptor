import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../database/project/project_database.dart';

/// run243 (Choi: "lanjutkan" — parity gambar area ikon-only karakter):
/// menyalin satu gambar referensi menjadi berkas MILIK PAKET lalu mencatatnya
/// sebagai baris `character_references` (kolom filePath sudah ada sejak skema
/// awal; selama ini tidak ada satu pun jalur produksi yang menulisinya).
///
/// Kontrak meniru [AssetThumbnailImporter]:
/// - ekstensi gambar dibatasi (.png/.jpg/.jpeg/.webp/.gif); penolakan terjadi
///   sebelum direktori tujuan dibuat, tanpa artefak tertinggal;
/// - berkas sumber dan karakter harus ada;
/// - slot bertipe sama diganti: salinan baru ditulis dulu, baris lama dihapus,
///   berkas lama hanya boleh dihapus bila berada di namespace ini.
class CharacterReferenceBinder {
  const CharacterReferenceBinder({
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

  /// Direktori gambar di dalam paket: `<assets>/character_references/`.
  Directory imageDirectory() =>
      Directory(p.join(assetsDirectory.path, 'character_references'));

  Future<String> bind({
    required String characterId,
    required String slotLabel,
    required String sourcePath,
  }) async {
    final character = await database.characterDao.getCharacter(characterId);
    if (character == null) {
      throw StateError('Unknown character for reference bind: $characterId');
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
    final slug = slotLabel.trim().toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );
    final target = File(
      p.join(directory.path, '${characterId}_${slug}_$stamp$extension'),
    );
    // Salin dulu: kegagalan I/O di sini meninggalkan keadaan lama utuh.
    await source.copy(target.path);

    final repo = database.characterDao;
    final existing = await repo.getReferences(characterId);
    for (final row in existing) {
      if (row.type.trim().toLowerCase() != slotLabel.trim().toLowerCase()) {
        continue;
      }
      await repo.removeReference(row.id);
      if (p.canonicalize(p.dirname(row.filePath)) ==
          p.canonicalize(directory.path)) {
        try {
          await File(row.filePath).delete();
        } on FileSystemException {
          // Berkas lama terkunci tidak menggagalkan bind; hanya yatim.
        }
      }
    }

    await repo.addReference(
      CharacterReferencesCompanion.insert(
        id: const Uuid().v4(),
        characterId: characterId,
        type: slotLabel.trim(),
        filePath: target.path,
        priority: Value(existing.length),
        primaryReference: const Value(false),
      ),
    );
    return target.path;
  }
}
