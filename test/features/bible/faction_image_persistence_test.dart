import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/bible/application/create_faction_service.dart';
import 'package:void_scriptor/features/bible/application/faction_image_importer.dart';
import 'package:void_scriptor/features/bible/application/faction_repository.dart';

/// run236 (Choi: "terapkan juga untuk world building dan timeline"):
/// faksi BUKAN baris `assets` (CreateFactionService hanya menulis tabel
/// Factions dengan assetId UUID), sehingga kartu thumbnail aset lama tidak
/// bisa dipakai. Faksi mendapat kolom gambar sendiri di wave 61 yang sama
/// dengan era; kontrak import meniru AssetThumbnailImporter/TimelineEraImageImporter.
void main() {
  final pngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  Future<(ProjectDatabase, Directory)> openDb(String tag) async {
    final dir = await Directory.systemTemp.createTemp('faction-img-$tag-');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });
    final db = ProjectDatabase(NativeDatabase(File('${dir.path}/project.db')));
    addTearDown(db.close);
    return (db, dir);
  }

  test('faction imagePath round-trips through save/listForProject', () async {
    final (db, _) = await openDb('roundtrip');
    final created = await const CreateFactionService().create(
      db,
      projectId: 'project-1',
      name: 'Echo Guild',
    );
    final repo = FactionRepository(db);
    final stored = (await repo.get(created.assetId))!;
    expect(stored.imagePath, '');

    await repo.save(
      stored.copyWith(imagePath: 'C:/pkg/assets/faction_images/x.png'),
    );
    final reloaded = await repo.get(created.assetId);
    expect(reloaded!.imagePath, 'C:/pkg/assets/faction_images/x.png');
    final listed = await repo.listForProject('project-1');
    expect(listed.single.imagePath, 'C:/pkg/assets/faction_images/x.png');
  });

  test(
    'faction importer copies into package namespace and updates the row',
    () async {
      final (db, dir) = await openDb('import');
      final created = await const CreateFactionService().create(
        db,
        projectId: 'project-1',
        name: 'Quiet Circle',
      );
      final source = File(p.join(dir.path, 'sigil.png'))
        ..writeAsBytesSync(pngBytes);
      final assetsDir = Directory(p.join(dir.path, 'assets'))
        ..createSync(recursive: true);

      final written = await FactionImageImporter(
        database: db,
        assetsDirectory: assetsDir,
      ).importFromFile(assetId: created.assetId, sourcePath: source.path);

      expect(written, contains(p.join('faction_images')));
      expect(File(written).existsSync(), isTrue);
      expect(
        (await FactionRepository(db).get(created.assetId))!.imagePath,
        written,
      );

      // Re-import supersedes the old package file; external source untouched.
      final second = File(p.join(dir.path, 'sigil2.png'))
        ..writeAsBytesSync(pngBytes);
      final written2 = await FactionImageImporter(
        database: db,
        assetsDirectory: assetsDir,
      ).importFromFile(assetId: created.assetId, sourcePath: second.path);
      expect(File(written).existsSync(), isFalse);
      expect(File(written2).existsSync(), isTrue);
      expect(source.existsSync(), isTrue);

      final bogus = File(p.join(dir.path, 'notes.txt'))..writeAsStringSync('x');
      await expectLater(
        () => FactionImageImporter(
          database: db,
          assetsDirectory: assetsDir,
        ).importFromFile(assetId: created.assetId, sourcePath: bogus.path),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        () => FactionImageImporter(
          database: db,
          assetsDirectory: assetsDir,
        ).importFromFile(assetId: 'missing', sourcePath: source.path),
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    'schema 60 -> 61 adds image_path to factions too, without losing rows',
    () async {
      final file = File(
        '${(await Directory.systemTemp.createTemp('faction-mig-')).path}/project.db',
      );
      var db = ProjectDatabase(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
      await const CreateFactionService().create(
        db,
        projectId: 'project-1',
        name: 'Bronze Pact',
        ideology: 'memory',
      );
      await db.close();

      db = ProjectDatabase(NativeDatabase(file));
      await db.customStatement('ALTER TABLE factions DROP COLUMN image_path');
      await db.customStatement('PRAGMA user_version = 60');
      await db.close();

      db = ProjectDatabase(NativeDatabase(file));
      addTearDown(db.close);
      final cols = await db.customSelect('PRAGMA table_info(factions)').get();
      expect(cols.any((row) => row.data['name'] == 'image_path'), isTrue);
      final rows = await db.select(db.factions).get();
      expect(rows.single.name, 'Bronze Pact');
      expect(rows.single.ideology, 'memory');
      expect(rows.single.imagePath, '');
    },
  );
}
