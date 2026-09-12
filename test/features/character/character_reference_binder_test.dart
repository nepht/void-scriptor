import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/character/application/character_reference_binder.dart';

/// run243 (Choi: "lanjutkan" — parity gambar area ikon-only karakter):
/// karakter memiliki tabel `character_references` dengan kolom filePath yang
/// sejak awal tidak pernah ditulis jalur produksi; Primary References UI
/// karenanya selalu kotak label mati. Binder ini menulis baris itu dengan
/// berkas MILIK PAKET namespace `character_references/`, kontrak sama dengan
/// AssetThumbnailImporter.
void main() {
  final pngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  Future<(ProjectDatabase, Directory)> openDb(String tag) async {
    final dir = await Directory.systemTemp.createTemp('ref-bind-$tag-');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });
    final db = ProjectDatabase(NativeDatabase(File('${dir.path}/project.db')));
    addTearDown(db.close);
    final now = DateTime(2026);
    await db
        .into(db.assets)
        .insert(
          AssetsCompanion.insert(
            id: 'char-1',
            projectId: 'project-1',
            name: 'Qowner',
            type: 'character',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await db
        .into(db.characters)
        .insert(
          CharactersCompanion.insert(
            assetId: 'char-1',
            projectId: 'project-1',
            displayName: 'Qowner',
          ),
        );
    return (db, dir);
  }

  test(
    'bind writes a package-owned row and reads it back through the dao',
    () async {
      final (db, dir) = await openDb('bind');
      final source = File(p.join(dir.path, 'face.png'))
        ..writeAsBytesSync(pngBytes);
      final assetsDir = Directory(p.join(dir.path, 'assets'))
        ..createSync(recursive: true);

      final written = await CharacterReferenceBinder(
        database: db,
        assetsDirectory: assetsDir,
      ).bind(characterId: 'char-1', slotLabel: 'Face', sourcePath: source.path);

      expect(written, contains(p.join('character_references')));
      expect(File(written).existsSync(), isTrue);
      final rows = await db.characterDao.getReferences('char-1');
      expect(rows.single.type, 'Face');
      expect(rows.single.filePath, written);

      // Sumber eksternal tidak pernah dipindahkan/dihapus.
      expect(source.existsSync(), isTrue);
    },
  );

  test(
    're-binding the same slot supersedes the old package file only',
    () async {
      final (db, dir) = await openDb('supersede');
      final assetsDir = Directory(p.join(dir.path, 'assets'))
        ..createSync(recursive: true);
      final first = File(p.join(dir.path, 'a.png'))..writeAsBytesSync(pngBytes);
      final second = File(p.join(dir.path, 'b.png'))
        ..writeAsBytesSync(pngBytes);
      final binder = CharacterReferenceBinder(
        database: db,
        assetsDirectory: assetsDir,
      );

      final old = await binder.bind(
        characterId: 'char-1',
        slotLabel: 'Hair',
        sourcePath: first.path,
      );
      final fresh = await binder.bind(
        characterId: 'char-1',
        slotLabel: 'Hair',
        sourcePath: second.path,
      );

      expect(File(old).existsSync(), isFalse);
      expect(File(fresh).existsSync(), isTrue);
      final rows = await db.characterDao.getReferences('char-1');
      expect(rows.where((r) => r.type == 'Hair'), hasLength(1));
      // Slot lain tetap utuh; sumber luar tak tersentuh.
      expect(first.existsSync(), isTrue);
    },
  );

  test(
    'foreign legacy path is kept on disk, never deleted by supersede',
    () async {
      final (db, dir) = await openDb('legacy');
      final legacy = File(p.join(dir.path, 'legacy.png'))
        ..writeAsBytesSync(pngBytes);
      await db
          .into(db.characterReferences)
          .insert(
            CharacterReferencesCompanion.insert(
              id: 'legacy-row',
              characterId: 'char-1',
              type: 'Pose',
              filePath: legacy.path,
            ),
          );
      final assetsDir = Directory(p.join(dir.path, 'assets'))
        ..createSync(recursive: true);
      final source = File(p.join(dir.path, 'new.png'))
        ..writeAsBytesSync(pngBytes);

      await CharacterReferenceBinder(
        database: db,
        assetsDirectory: assetsDir,
      ).bind(characterId: 'char-1', slotLabel: 'Pose', sourcePath: source.path);
      expect(legacy.existsSync(), isTrue);
      final rows = await db.characterDao.getReferences('char-1');
      expect(rows.single.type, 'Pose');
      expect(rows.single.filePath, contains('character_references'));
    },
  );

  test('rejects non-image extension before touching the namespace', () async {
    final (db, dir) = await openDb('reject');
    final assetsDir = Directory(p.join(dir.path, 'assets'));
    final bogus = File(p.join(dir.path, 'notes.txt'))..writeAsStringSync('x');
    await expectLater(
      () => CharacterReferenceBinder(
        database: db,
        assetsDirectory: assetsDir,
      ).bind(characterId: 'char-1', slotLabel: 'Face', sourcePath: bogus.path),
      throwsA(isA<ArgumentError>()),
    );
    expect(assetsDir.existsSync(), isFalse);
  });

  test('unknown character is rejected honestly', () async {
    final (db, dir) = await openDb('unknown');
    final source = File(p.join(dir.path, 'face.png'))
      ..writeAsBytesSync(pngBytes);
    await expectLater(
      () => CharacterReferenceBinder(
        database: db,
        assetsDirectory: Directory(dir.path),
      ).bind(characterId: 'nobody', slotLabel: 'Face', sourcePath: source.path),
      throwsA(isA<StateError>()),
    );
  });
}
