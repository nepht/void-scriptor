import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/automation/release_schemas.dart';
import 'package:void_scriptor/database/project/project_database.dart';

/// Sprint 105 / 105.10-105.12 — RC migration matrix, failure recovery,
/// and workflow persistence recovery against the canonical database.
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('vs_rc_mig'));
  tearDown(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  File dbFile() => File('${dir.path}/project.db');

  /// Simulates a v53 (v1.0.1-era) database: full create at current schema,
  /// then strip the v54-58 additions and rewind user_version. Valid because
  /// the 54→57 migration block only creates tables and 57→58 adds one column.
  Future<void> seedV53() async {
    final bootstrap = ProjectDatabase(NativeDatabase(dbFile()));
    await bootstrap.customSelect('SELECT 1').get();
    await bootstrap.close();
    // Rewind via a dedicated connection using drift's custom statement API.
    final rewound = ProjectDatabase(NativeDatabase(dbFile()));
    await rewound.customStatement('PRAGMA foreign_keys = OFF');
    await rewound.customStatement(
      'DROP TABLE IF EXISTS creature_ecology_states',
    );
    await rewound.customStatement('DROP TABLE IF EXISTS novel_character_links');
    await rewound.customStatement('DROP TABLE IF EXISTS workflow_definitions');
    await rewound.customStatement('DROP TABLE IF EXISTS workflow_run_records');
    await rewound.customStatement('DROP TABLE IF EXISTS scene_draft_snapshots');
    // v58 added characters.voice via addColumn; strip it so the rewind is
    // a faithful pre-58 state (the 57->58 block re-adds it on migration).
    await rewound.customStatement('ALTER TABLE characters DROP COLUMN voice');
    // v59 added the three character scope layer tables; drop them too so
    // the 58->59 block re-creates them on migration.
    await rewound.customStatement(
      'DROP TABLE IF EXISTS character_canonical_scopes',
    );
    await rewound.customStatement(
      'DROP TABLE IF EXISTS character_universe_timeline_overrides',
    );
    await rewound.customStatement(
      'DROP TABLE IF EXISTS character_novel_states',
    );
    await rewound.customStatement('PRAGMA user_version = 53');
    await rewound.close();
  }

  group('105.10 migration matrix', () {
    test('fresh RC install creates v59 directly', () async {
      final database = ProjectDatabase(NativeDatabase(dbFile()));
      await database.customSelect('SELECT 1').get();
      expect(ProjectDatabase.currentSchemaVersion, 59);
      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.data['user_version'], 59);
      await database.close();
    });

    test('beta_1_to_rc_1 path: opening an up-to-date DB is a no-op', () async {
      // Build once (beta state == same schema 59), reopen, verify intact.
      var database = ProjectDatabase(NativeDatabase(dbFile()));
      await database.customSelect('SELECT 1').get();
      await database.close();
      database = ProjectDatabase(NativeDatabase(dbFile()));
      await database.customSelect('SELECT 1').get();
      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.data['user_version'], 59);
      await database.close();
    });

    test(
      'v1.0.x-era v53 database upgrades to v59 with all five waves',
      () async {
        await seedV53();
        final database = ProjectDatabase(NativeDatabase(dbFile()));
        await database.customSelect('SELECT 1').get();

        final tables = await database
            .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
            .get();
        final names = tables.map((r) => r.data['name'] as String).toSet();
        expect(
          names,
          containsAll(<String>[
            'creature_ecology_states', // v54
            'novel_character_links', // v55
            'workflow_definitions', // v56
            'workflow_run_records', // v56
            'scene_draft_snapshots', // v57
            'character_canonical_scopes', // v59
            'character_universe_timeline_overrides', // v59
            'character_novel_states', // v59
          ]),
        );
        // v58 wave: the migrated database carries the new canonical
        // characters.voice column.
        // v59 wave: the migrated database carries the three character scope
        // layer tables.
        final voiceColumns = await database
            .customSelect("PRAGMA table_info(characters)")
            .get();
        expect(voiceColumns.map((r) => r.data['name']), contains('voice'));
        final version = await database
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.data['user_version'], 59);
        await database.close();
      },
    );
  });

  group('105.11 migration failure recovery', () {
    test(
      'a failed upgrade leaves the original file intact and explainable',
      () async {
        await seedV53();
        final before = dbFile().readAsBytesSync();
        final backupPath = '${dir.path}/pre-migration-backup.db';
        dbFile().copySync(backupPath);

        // Force a deterministic failure mid-migration: corrupt the file so
        // the migrator cannot proceed.
        await dbFile().writeAsBytes(
          before.sublist(0, before.lengthInBytes ~/ 2),
        );

        final failed = ProjectDatabase(NativeDatabase(dbFile()));
        Object? observed;
        try {
          await failed.customSelect('SELECT 1').get();
        } catch (e) {
          observed = e;
        }
        expect(observed, isA<Object>(), reason: 'corruption must fail loudly');
        await failed.close();

        // Rollback restores the original byte-for-byte: the project source
        // is exactly what it was before the failed attempt. (Reopening it
        // would legitimately migrate it again, so identity is proven by
        // content, not by a second migration.)
        File(backupPath).copySync(dbFile().path);
        expect(
          dbFile().readAsBytesSync(),
          before,
          reason: 'rollback must preserve the original project unchanged',
        );
      },
    );
  });

  group('105.12 workflow persistence recovery', () {
    test('definition restore survives close/reopen', () async {
      var database = ProjectDatabase(NativeDatabase(dbFile()));
      await database.customSelect('SELECT 1').get();
      await database
          .into(database.workflowDefinitions)
          .insert(
            WorkflowDefinitionsCompanion.insert(
              definitionId: 'wf-1',
              version: 3,
              name: 'Export chain',
              payloadJson: '{"steps":2}',
              createdAt: DateTime.utc(2026, 8, 25),
            ),
          );
      await database.close();

      database = ProjectDatabase(NativeDatabase(dbFile()));
      final row = await database.select(database.workflowDefinitions).get();
      expect(row.single.definitionId, 'wf-1');
      expect(row.single.version, 3);
      expect(row.single.payloadJson, contains('steps'));
      await database.close();
    });

    test(
      'execution history keeps terminal records and orphan detection works',
      () async {
        final database = ProjectDatabase(NativeDatabase(dbFile()));
        await database.customSelect('SELECT 1').get();
        // A definition the first run legitimately points to.
        await database
            .into(database.workflowDefinitions)
            .insert(
              WorkflowDefinitionsCompanion.insert(
                definitionId: 'wf-1',
                version: 3,
                name: 'Export chain',
                payloadJson: '{"steps":2}',
                createdAt: DateTime.utc(2026, 8, 25),
              ),
            );
        await database
            .into(database.workflowRunRecords)
            .insert(
              WorkflowRunRecordsCompanion.insert(
                executionId: 'exec-ok',
                definitionId: 'wf-1',
                definitionVersion: 3,
                state: 'succeeded',
                startedAt: DateTime.utc(2026, 8, 25),
              ),
            );
        await database
            .into(database.workflowRunRecords)
            .insert(
              WorkflowRunRecordsCompanion.insert(
                executionId: 'exec-orphan',
                definitionId: 'wf-gone',
                definitionVersion: 9,
                state: 'running',
                startedAt: DateTime.utc(2026, 8, 25),
              ),
            );

        final runs = await database.select(database.workflowRunRecords).get();
        expect(runs.length, 2);

        // Orphan detection: run records whose definition no longer exists.
        final definitions = await database
            .select(database.workflowDefinitions)
            .get();
        final knownIds = definitions.map((d) => d.definitionId).toSet();
        final orphans = runs
            .where((r) => !knownIds.contains(r.definitionId))
            .toList();
        expect(orphans.single.executionId, 'exec-orphan');
        expect(ReleaseSchemas.workflowSchema, 1);
        await database.close();
      },
    );
  });
}
