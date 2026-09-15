import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/bible/application/bible_timeline_repository.dart';
import 'package:void_scriptor/features/bible/application/timeline_era_image_importer.dart';
import 'package:void_scriptor/features/bible/domain/timeline_era.dart';

/// run236 (Choi: "terapkan juga untuk world building dan timeline"):
/// timeline era bukan baris `assets`, sehingga butuh kolom gambar sendiri
/// dengan migrasi 60->61 yang jujur: round-trip persist + forward-recovery.
void main() {
  final pngBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );

  Future<(ProjectDatabase, Directory)> openDb(String tag) async {
    final dir = await Directory.systemTemp.createTemp('era-$tag-');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    });
    final db = ProjectDatabase(NativeDatabase(File('${dir.path}/project.db')));
    addTearDown(db.close);
    return (db, dir);
  }

  test('era imagePath round-trips through saveEra/listEras', () async {
    final (db, _) = await openDb('roundtrip');
    final repo = BibleTimelineRepository(db);
    await repo.saveEra(
      const TimelineEraModel(
        id: 'era-1',
        projectId: 'project-1',
        name: 'Age of Echoes',
        orderIndex: 0,
        imagePath: 'C:/pkg/assets/era_images/era-1.png',
      ),
    );
    final loaded = await repo.listEras('project-1');
    expect(loaded.single.imagePath, 'C:/pkg/assets/era_images/era-1.png');

    // Update via saveEra (insertOnConflictUpdate) must persist the change.
    await repo.saveEra(loaded.single.copyWith(imagePath: 'C:/moved.png'));
    expect((await repo.listEras('project-1')).single.imagePath, 'C:/moved.png');
  });

  test(
    'importer copies into the package era_images namespace and updates the era',
    () async {
      final (db, dir) = await openDb('import');
      final repo = BibleTimelineRepository(db);
      await repo.saveEra(
        const TimelineEraModel(
          id: 'era-2',
          projectId: 'project-1',
          name: 'Quiet Age',
          orderIndex: 0,
        ),
      );
      final source = File(p.join(dir.path, 'art.png'));
      await source.writeAsBytes(pngBytes);
      final assetsDir = Directory(p.join(dir.path, 'assets'))
        ..createSync(recursive: true);

      final written = await TimelineEraImageImporter(
        database: db,
        assetsDirectory: assetsDir,
      ).importFromFile(eraId: 'era-2', sourcePath: source.path);

      expect(written, contains(p.join('era_images')));
      expect(File(written).existsSync(), isTrue);
      final reloaded = (await repo.listEras('project-1')).single;
      expect(reloaded.imagePath, written);

      // Re-import supersedes the old package file; the external source stays.
      final second = File(p.join(dir.path, 'art2.png'))
        ..writeAsBytesSync(pngBytes);
      final written2 = await TimelineEraImageImporter(
        database: db,
        assetsDirectory: assetsDir,
      ).importFromFile(eraId: 'era-2', sourcePath: second.path);
      expect(File(written).existsSync(), isFalse);
      expect(File(written2).existsSync(), isTrue);
      expect(source.existsSync(), isTrue);

      // Rejects non-image extensions before touching the destination.
      final bogus = File(p.join(dir.path, 'notes.txt'))..writeAsStringSync('x');
      await expectLater(
        () => TimelineEraImageImporter(
          database: db,
          assetsDirectory: assetsDir,
        ).importFromFile(eraId: 'era-2', sourcePath: bogus.path),
        throwsA(isA<ArgumentError>()),
      );
      await expectLater(
        () => TimelineEraImageImporter(
          database: db,
          assetsDirectory: assetsDir,
        ).importFromFile(eraId: 'missing', sourcePath: source.path),
        throwsA(isA<StateError>()),
      );
    },
  );

  test(
    'schema 60 -> 61 forward recovery adds image_path without losing rows',
    () async {
      final file = File(
        '${(await Directory.systemTemp.createTemp('era-mig-')).path}/project.db',
      );
      var db = ProjectDatabase(NativeDatabase(file));
      await db.customSelect('SELECT 1').get();
      await db
          .into(db.timelineEras)
          .insert(
            TimelineErasCompanion.insert(
              id: 'era-m',
              projectId: 'project-1',
              name: 'Bronze Age',
              orderIndex: 3,
              description: const Value('legacy row'),
            ),
          );
      await db.close();

      // Rewind: emulate a pre-61 package by dropping the column and version.
      db = ProjectDatabase(NativeDatabase(file));
      await db.customStatement(
        'ALTER TABLE timeline_eras DROP COLUMN image_path',
      );
      await db.customStatement('PRAGMA user_version = 60');
      await db.close();

      // Reopen migrates forward; existing rows survive untouched.
      db = ProjectDatabase(NativeDatabase(file));
      addTearDown(db.close);
      final cols = await db
          .customSelect('PRAGMA table_info(timeline_eras)')
          .get();
      expect(cols.any((row) => row.data['name'] == 'image_path'), isTrue);
      final rows = await (db.select(
        db.timelineEras,
      )..where((item) => item.id.equals('era-m'))).get();
      expect(rows.single.name, 'Bronze Age');
      expect(rows.single.orderIndex, 3);
      expect(rows.single.imagePath, '');
      final version = await db.customSelect('PRAGMA user_version').get();
      expect(
        version.single.data['user_version'],
        ProjectDatabase.currentSchemaVersion,
      );
    },
  );
}
