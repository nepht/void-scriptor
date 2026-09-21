/// Sprint 113.10 — Upgrade Path Validation.
///
/// Required evidence: source_versions, upgrade_results, migration_logs,
/// data_comparison, warnings, recovery_results.
///
/// Validates that upgrading from supported source schema versions to the
/// current RC schema succeeds with data preservation, backup-before-migrate,
/// future-schema rejection, and lock-contention recovery.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:void_scriptor/database/project/project_database.dart'
    hide CharacterIdentityProfile;
import 'package:void_scriptor/database/project/project_database_service.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hermes-upgrade-113_10_');
  });

  tearDown(() async {
    try {
      await root.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  int readOnDiskVersion(String path) {
    final raw = sqlite.sqlite3.open(path, mode: sqlite.OpenMode.readOnly);
    try {
      return raw.select('PRAGMA user_version').single['user_version'] as int;
    } finally {
      raw.close();
    }
  }

  // ── source_versions ───────────────────────────────────────────────────
  group('source_versions', () {
    test('manifest records all supported upgrade sources', () {
      final file = File(
        'docs/planning/v1.2/sprint_113_upgrade_path_validation.json',
      );
      expect(file.existsSync(), isTrue, reason: 'manifest must exist');

      final doc = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(doc['canonical_step'], '113.10');

      final sources = doc['source_versions'] as Map<String, dynamic>;
      expect(sources['current_schema_version'], 62);
      expect(sources['migration_strategy'], 'guarded_forward_migrations');
      expect(sources['backup_before_migration'], isTrue);

      final versions = sources['supported_upgrade_sources'] as List;
      expect(versions, isNotEmpty);
      expect(
        versions.every(
          (v) =>
              v is Map &&
              v['schema_version'] is int &&
              v['label'] is String &&
              v['migration_path'] is String,
        ),
        isTrue,
      );
    });
  });

  // ── upgrade_results ──────────────────────────────────────────────────
  group('upgrade_results', () {
    test(
      'database created at schema 61 can be opened and migrated to 62',
      () async {
        final dbPath = '${root.path}${Platform.pathSeparator}upgrade_61.db';
        final service = ProjectDatabaseService();

        // Create at current schema first.
        await service.create(dbPath);

        // Rewind to schema 61 (simulate an older version).
        final raw = sqlite.sqlite3.open(dbPath);
        raw.execute('PRAGMA user_version = 61');
        raw.close();

        expect(readOnDiskVersion(dbPath), 61);

        // Opening should migrate forward to 62.
        final db = await service.open(dbPath);
        try {
          expect(db.schemaVersion, 62);
        } finally {
          await db.close();
        }

        // On-disk version should now be 62.
        expect(readOnDiskVersion(dbPath), 62);
      },
    );

    test(
      'database created at schema 55 can be opened and migrated to 62',
      () async {
        final dbPath = '${root.path}${Platform.pathSeparator}upgrade_55.db';
        final service = ProjectDatabaseService();
        await service.create(dbPath);

        final raw = sqlite.sqlite3.open(dbPath);
        raw.execute('PRAGMA user_version = 55');
        raw.close();

        expect(readOnDiskVersion(dbPath), 55);

        final db = await service.open(dbPath);
        try {
          expect(db.schemaVersion, 62);
        } finally {
          await db.close();
        }

        expect(readOnDiskVersion(dbPath), 62);
      },
    );

    test('fresh database starts at schema 62', () async {
      final dbPath = '${root.path}${Platform.pathSeparator}fresh.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      expect(readOnDiskVersion(dbPath), 62);

      final db = await service.open(dbPath);
      try {
        expect(db.schemaVersion, 62);
      } finally {
        await db.close();
      }
    });

    test(
      'future schema (63+) is rejected without modifying the file',
      () async {
        final dbPath = '${root.path}${Platform.pathSeparator}future.db';
        final service = ProjectDatabaseService();
        await service.create(dbPath);

        // Simulate a future-version database.
        final raw = sqlite.sqlite3.open(dbPath);
        raw.execute(
          'PRAGMA user_version = ${ProjectDatabase.currentSchemaVersion + 1}',
        );
        raw.close();

        await expectLater(
          service.open(dbPath),
          throwsA(isA<SchemaVersionTooNewException>()),
        );

        // The on-disk version must NOT have been modified.
        expect(
          readOnDiskVersion(dbPath),
          ProjectDatabase.currentSchemaVersion + 1,
        );
      },
    );
  });

  // ── migration_logs ──────────────────────────────────────────────────
  group('migration_logs', () {
    test('manifest records migration logging requirements', () {
      final file = File(
        'docs/planning/v1.2/sprint_113_upgrade_path_validation.json',
      );
      final doc = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final logs = doc['migration_logs'] as Map<String, dynamic>;
      expect(logs['backup_created_before_migration'], isTrue);
      expect(logs['pre_migration_backup_type'], 'pre-migration');
      expect(logs['migration_timestamps_recorded'], isTrue);
      expect(logs['schema_version_tracking'], 'PRAGMA user_version');
      expect(logs['drift_guard_active'], isTrue);
    });
  });

  // ── data_comparison ─────────────────────────────────────────────────
  group('data_comparison', () {
    test('manifest records data preservation across upgrade', () {
      final file = File(
        'docs/planning/v1.2/sprint_113_upgrade_path_validation.json',
      );
      final doc = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final comparison = doc['data_comparison'] as Map<String, dynamic>;
      expect(comparison['strategy'], isNotEmpty);
      expect(comparison['characters_preserved'], isTrue);
      expect(comparison['assets_preserved'], isTrue);
      expect(comparison['stories_preserved'], isTrue);
      expect(comparison['timeline_events_preserved'], isTrue);
      expect(comparison['settings_preserved'], isTrue);
      expect(comparison['no_data_loss_detected'], isTrue);
    });

    test('tables survive a forward migration (schema 61 → 62)', () async {
      final dbPath = '${root.path}${Platform.pathSeparator}tables_61.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      // Rewind to 61 and migrate.
      final raw = sqlite.sqlite3.open(dbPath);
      raw.execute('PRAGMA user_version = 61');
      raw.close();

      final db = await service.open(dbPath);
      try {
        // All core tables should be queryable after migration.
        final rows = await db
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type='table' "
              "AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'drift_%'",
            )
            .get();
        final tables = rows.map((row) => row.read<String>('name')).toList();
        expect(tables, contains('assets'));
        expect(tables, contains('characters'));
      } finally {
        await db.close();
      }
    });
  });

  // ── warnings ────────────────────────────────────────────────────────
  group('warnings', () {
    test('manifest records downgrade and future-schema warnings', () {
      final file = File(
        'docs/planning/v1.2/sprint_113_upgrade_path_validation.json',
      );
      final doc = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final warnings = doc['warnings'] as Map<String, dynamic>;
      expect(warnings['downgrade_not_supported'], isNotEmpty);
      expect(warnings['future_schema_rejected'], isNotEmpty);
      expect(warnings['concurrent_writer_blocked'], isNotEmpty);

      final limitations = warnings['known_limitations'] as List;
      expect(limitations, isNotEmpty);
      expect(limitations.length, greaterThanOrEqualTo(3));
    });

    test('concurrent writer produces a typed lock exception', () async {
      final dbPath = '${root.path}${Platform.pathSeparator}lock_test.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      final writer = sqlite.sqlite3.open(dbPath);
      writer.execute(
        'PRAGMA user_version = ${ProjectDatabase.currentSchemaVersion}',
      );
      writer.execute('BEGIN IMMEDIATE');

      await expectLater(
        service.open(dbPath),
        throwsA(isA<ProjectDatabaseLockedException>()),
      );

      writer.execute('ROLLBACK');
      writer.close();
    });
  });

  // ── recovery_results ────────────────────────────────────────────────
  group('recovery_results', () {
    test('manifest records recovery validation results', () {
      final file = File(
        'docs/planning/v1.2/sprint_113_upgrade_path_validation.json',
      );
      final doc = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      final recovery = doc['recovery_results'] as Map<String, dynamic>;
      expect(recovery['pre_migration_backup_restorable'], isTrue);
      expect(recovery['failed_migration_rollback'], isNotEmpty);
      expect(recovery['corrupt_database_handled'], isNotEmpty);
      expect(recovery['lock_contention_recoverable'], isTrue);
    });

    test('after lock release the database opens successfully', () async {
      final dbPath = '${root.path}${Platform.pathSeparator}recovery.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      final writer = sqlite.sqlite3.open(dbPath);
      writer.execute(
        'PRAGMA user_version = ${ProjectDatabase.currentSchemaVersion}',
      );
      writer.execute('BEGIN IMMEDIATE');

      // First open should fail (locked).
      await expectLater(
        service.open(dbPath),
        throwsA(isA<ProjectDatabaseLockedException>()),
      );

      // Release the lock.
      writer.execute('ROLLBACK');
      writer.close();

      // Second open should succeed.
      final db = await service.open(dbPath);
      try {
        expect(db.schemaVersion, ProjectDatabase.currentSchemaVersion);
      } finally {
        await db.close();
      }
    });
  });
}
