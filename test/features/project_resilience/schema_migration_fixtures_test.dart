import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_manifest.dart';
import 'package:void_scriptor/core/persistence/project_manifest_service.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database.dart'
    hide CharacterIdentityProfile;
import 'package:void_scriptor/database/project/project_database_service.dart';

/// Sprint 145.40 - Schema and Migration Fixtures.
///
/// Objective: Version Core schemas, create old/current/future/corrupt
/// fixtures, ordered migrations, invariant checks, backups, rollback/forward
/// recovery, and no silent data discard.
///
/// This slice proves the fixture matrix for the schema families that already
/// have real production support:
///   - OLD fixture (v53, v1.0.x-era): opens and migrates to current (v59),
///     Core rows are preserved (no silent discard on the forward path).
///   - CURRENT fixture: fresh create then reopen is a stable no-op at v59.
///   - CORRUPT fixture: a broken database is detected by health/open paths
///     and does not crash the check.
///   - FUTURE manifest fixture: an unsupported manifest schema is rejected
///     with FormatException instead of being silently accepted.
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('vs_fixture_matrix'));
  tearDown(() {
    try {
      dir.deleteSync(recursive: true);
    } catch (_) {}
  });

  File dbFile() => File('${dir.path}/project.db');

  /// Build a fresh v59 database with one Core character row, then rewind it
  /// to a faithful v53 (v1.0.x-era) state so the 53->59 migration waves
  /// re-apply on open. Mirrors the proven seedV53 recipe in
  /// test/release/rc_migration_recovery_test.dart.
  Future<void> seedV53WithCoreRow() async {
    final now = DateTime.now();
    var database = ProjectDatabase(NativeDatabase(dbFile()));
    await database.customSelect('SELECT 1').get();
    await database.transaction(() async {
      await database
          .into(database.assets)
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
      await database
          .into(database.characters)
          .insert(
            CharactersCompanion.insert(
              assetId: 'char-1',
              projectId: 'project-1',
              displayName: 'Qowner',
              biography: const Value('born in the Void'),
              voice: const Value('low hum'),
            ),
          );
    });
    await database.close();

    final rewound = ProjectDatabase(NativeDatabase(dbFile()));
    await rewound.customStatement('PRAGMA foreign_keys = OFF');
    await rewound.customStatement(
      'DROP TABLE IF EXISTS creature_ecology_states',
    );
    await rewound.customStatement('DROP TABLE IF EXISTS novel_character_links');
    await rewound.customStatement('DROP TABLE IF EXISTS workflow_definitions');
    await rewound.customStatement('DROP TABLE IF EXISTS workflow_run_records');
    await rewound.customStatement('DROP TABLE IF EXISTS scene_draft_snapshots');
    await rewound.customStatement('ALTER TABLE characters DROP COLUMN voice');
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

  group('145.40 fixture matrix', () {
    test(
      'CURRENT: fresh create opens at v59 and reopens as a stable no-op',
      () async {
        final service = ProjectDatabaseService();
        await service.create(dbFile().path);

        expect(await service.schemaVersion(dbFile().path), 59);

        var database = await service.open(dbFile().path);
        await database.customSelect('SELECT 1').get();
        await database.close();

        database = await service.open(dbFile().path);
        final version = await database
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.data['user_version'], 59);
        await database.close();
      },
    );

    test(
      'OLD v53: migration to v59 preserves Core rows (no silent discard)',
      () async {
        await seedV53WithCoreRow();
        final service = ProjectDatabaseService();
        final database = await service.open(dbFile().path);

        final version = await database
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.data['user_version'], 59);

        final voiceColumns = await database
            .customSelect('PRAGMA table_info(characters)')
            .get();
        expect(voiceColumns.map((r) => r.data['name']), contains('voice'));

        final chars = await database.select(database.characters).get();
        expect(chars, hasLength(1));
        expect(chars.single.displayName, 'Qowner');
        expect(chars.single.biography, 'born in the Void');
        expect(chars.single.voice, '');

        final tables = await database
            .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
            .get();
        final names = tables.map((r) => r.data['name'] as String).toSet();
        expect(
          names,
          containsAll(<String>[
            'character_canonical_scopes',
            'character_universe_timeline_overrides',
            'character_novel_states',
          ]),
        );
        await database.close();
      },
    );

    test('CORRUPT: broken database is detected without crashing', () async {
      dbFile().parent.createSync(recursive: true);
      dbFile().writeAsBytesSync(List<int>.filled(512, 0xAB));
      final service = ProjectDatabaseService();

      expect(await service.schemaVersion(dbFile().path), isNull);

      await expectLater(service.open(dbFile().path), throwsA(anything));
    });

    test('FUTURE manifest: unsupported schema version is rejected', () async {
      final paths = ProjectPaths(rootDirectory: dir);
      final manifest = ProjectManifest(
        schemaVersion: 99,
        id: 'project-future',
        name: 'Future',
        description: '',
        projectVersion: '0.1.0',
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        appVersion: '1.0.0',
      );
      await ProjectManifestService(paths: paths).write(manifest);

      await expectLater(
        ProjectManifestService(paths: paths).read('project-future'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('145.40 interrupted migration forward recovery', () {
    test(
      'HALF-APPLIED wave objects with stale user_version still reopen cleanly',
      () async {
        // Simulate the crash state a process death mid-migration leaves
        // behind: wave 54..59 object changes already applied by hand, but
        // user_version still at 53 (drift only bumps it after onUpgrade
        // completes, so a crash inside the wave leaves this exact state).
        await seedV53WithCoreRow();
        // Apply the 54..59 object changes by hand through a raw sqlite3
        // connection (no drift migrator -> no automatic user_version bump),
        // leaving the database in the exact half-applied crash state.
        final raw = sqlite3.open(dbFile().path);
        raw.execute(
          'CREATE TABLE IF NOT EXISTS creature_ecology_states '
          '(id TEXT NOT NULL PRIMARY KEY, asset_id TEXT NOT NULL, '
          'project_id TEXT NOT NULL, payload TEXT)',
        );
        raw.execute(
          'CREATE TABLE IF NOT EXISTS novel_character_links '
          '(id TEXT NOT NULL PRIMARY KEY, project_id TEXT NOT NULL, '
          'asset_id TEXT NOT NULL, role TEXT)',
        );
        raw.execute(
          'CREATE TABLE IF NOT EXISTS workflow_definitions '
          '(id TEXT NOT NULL PRIMARY KEY, project_id TEXT NOT NULL, '
          'name TEXT NOT NULL)',
        );
        raw.execute(
          'CREATE TABLE IF NOT EXISTS workflow_run_records '
          '(id TEXT NOT NULL PRIMARY KEY, project_id TEXT NOT NULL, '
          'definition_id TEXT NOT NULL)',
        );
        raw.execute(
          'CREATE TABLE IF NOT EXISTS scene_draft_snapshots '
          '(id TEXT NOT NULL PRIMARY KEY, project_id TEXT NOT NULL, '
          'scene_id TEXT NOT NULL, label TEXT NOT NULL, payload TEXT)',
        );
        raw.execute(
          "ALTER TABLE characters ADD COLUMN \"voice\" TEXT NOT NULL DEFAULT ''",
        );
        raw.execute(
          'CREATE TABLE IF NOT EXISTS character_canonical_scopes '
          '(id TEXT NOT NULL PRIMARY KEY, character_asset_id TEXT NOT NULL, '
          'project_id TEXT NOT NULL)',
        );
        raw.execute(
          'CREATE TABLE IF NOT EXISTS character_universe_timeline_overrides '
          '(id TEXT NOT NULL PRIMARY KEY, character_asset_id TEXT NOT NULL, '
          'project_id TEXT NOT NULL)',
        );
        raw.execute(
          'CREATE TABLE IF NOT EXISTS character_novel_states '
          '(id TEXT NOT NULL PRIMARY KEY, character_asset_id TEXT NOT NULL, '
          'project_id TEXT NOT NULL)',
        );
        raw.execute('PRAGMA user_version = 53');
        raw.close();

        // Forward recovery: opening the half-applied database must succeed
        // (the create-table waves are CREATE TABLE IF NOT EXISTS idempotent,
        // the voice add-column wave is guarded to tolerate an existing
        // column) and must preserve the Core character row.
        final opened = ProjectDatabase(NativeDatabase(dbFile()));
        await opened.customSelect('SELECT 1').get();
        final versionRow = await opened
            .customSelect('PRAGMA user_version')
            .get();
        expect(versionRow.first.data['user_version'], 59);
        final coreRows = await opened.select(opened.characters).get();
        expect(coreRows, hasLength(1));
        expect(coreRows.first.displayName, 'Qowner');
        final assetRows = await opened.select(opened.assets).get();
        expect(assetRows, hasLength(1));
        await opened.close();
      },
    );
  });
}
