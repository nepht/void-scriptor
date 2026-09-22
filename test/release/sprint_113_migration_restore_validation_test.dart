// Sprint 113.12 — Migration & Restore Validation.
//
// Required evidence: migration_results, backup_results, restore_results,
// repair_results, interruption_results, integrity_report.
//
// Validates that:
// 1. Migration from older schemas to current (62) succeeds with data preservation
// 2. Backup before migration is verifiable
// 3. Restore from backup works and preserves data
// 4. Corrupt database is detected and repair via backup is possible
// 5. Interrupted migration is recoverable via backup restore
// 6. PRAGMA integrity_check returns 'ok' on restored database

library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/world_logic/domain/migration_restore_validation.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp(
      'hermes-migration-restore-113_12_',
    );
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

  String readIntegrityCheck(String path) {
    final raw = sqlite.sqlite3.open(path, mode: sqlite.OpenMode.readOnly);
    try {
      final result = raw.select('PRAGMA integrity_check').single;
      return result.values.first as String;
    } finally {
      raw.close();
    }
  }

  int countUserTables(String path) {
    final raw = sqlite.sqlite3.open(path, mode: sqlite.OpenMode.readOnly);
    try {
      final rows = raw.select(
        "SELECT COUNT(*) as cnt FROM sqlite_master WHERE type='table' "
        "AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'drift_%'",
      );
      return rows.single['cnt'] as int;
    } finally {
      raw.close();
    }
  }

  // ── manifest_validation ─────────────────────────────────────────────
  group('manifest_validation', () {
    test('domain class validates the manifest structure', () {
      final result = MigrationRestoreValidation.validate();
      expect(result.isValid, isTrue, reason: result.errors.join('; '));
      expect(result.errors, isEmpty);
    });

    test('manifest has all required evidence sections', () {
      final file = File(MigrationRestoreValidation.manifestPath);
      expect(file.existsSync(), isTrue);

      final doc = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(doc['canonical_step'], '113.12');
      expect(doc['migration_results'], isNotNull);
      expect(doc['backup_results'], isNotNull);
      expect(doc['restore_results'], isNotNull);
      expect(doc['repair_results'], isNotNull);
      expect(doc['interruption_results'], isNotNull);
      expect(doc['integrity_report'], isNotNull);
    });
  });

  // ── migration_results ───────────────────────────────────────────────
  group('migration_results', () {
    test('database created at schema 61 migrates to 62', () async {
      final dbPath = '${root.path}${Platform.pathSeparator}migrate_61.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      // Rewind to schema 61.
      final raw = sqlite.sqlite3.open(dbPath);
      raw.execute('PRAGMA user_version = 61');
      raw.close();

      expect(readOnDiskVersion(dbPath), 61);

      // Open should migrate forward.
      final db = await service.open(dbPath);
      try {
        expect(db.schemaVersion, 62);
      } finally {
        await db.close();
      }
      expect(readOnDiskVersion(dbPath), 62);
    });

    test('database created at schema 55 migrates to 62', () async {
      final dbPath = '${root.path}${Platform.pathSeparator}migrate_55.db';
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
    });

    test('tables survive forward migration (61 → 62)', () async {
      final dbPath = '${root.path}${Platform.pathSeparator}tables_migrate.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      final preTableCount = countUserTables(dbPath);

      final raw = sqlite.sqlite3.open(dbPath);
      raw.execute('PRAGMA user_version = 61');
      raw.close();

      final db = await service.open(dbPath);
      try {
        expect(db.schemaVersion, 62);
        final postTableCount = countUserTables(dbPath);
        // After migration, table count should be >= pre-migration.
        expect(postTableCount, greaterThanOrEqualTo(preTableCount));
      } finally {
        await db.close();
      }
    });
  });

  // ── backup_results ──────────────────────────────────────────────────
  group('backup_results', () {
    test('pre-migration backup is verifiable and openable', () async {
      final dbPath = '${root.path}${Platform.pathSeparator}backup_test.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      // Create backup before any migration manipulation.
      final backupPath = '$dbPath.bak';
      await File(dbPath).copy(backupPath);

      // Verify backup is a valid database.
      expect(File(backupPath).existsSync(), isTrue);
      final backupSize = await File(backupPath).length();
      expect(backupSize, greaterThan(0));

      // Backup should be openable independently.
      final backupService = ProjectDatabaseService();
      final db = await backupService.open(backupPath);
      try {
        expect(db.schemaVersion, 62);
        expect(readIntegrityCheck(backupPath), 'ok');
      } finally {
        await db.close();
      }
    });

    test('backup preserves schema version of source', () async {
      final dbPath = '${root.path}${Platform.pathSeparator}backup_schema.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      // Rewind to 60, then backup.
      final raw = sqlite.sqlite3.open(dbPath);
      raw.execute('PRAGMA user_version = 60');
      raw.close();

      final backupPath = '$dbPath.bak';
      await File(dbPath).copy(backupPath);

      // Backup should retain schema 60 on disk (raw copy).
      expect(readOnDiskVersion(backupPath), 60);

      // But opening it should migrate to 62.
      final backupService = ProjectDatabaseService();
      final db = await backupService.open(backupPath);
      try {
        expect(db.schemaVersion, 62);
      } finally {
        await db.close();
      }
    });
  });

  // ── restore_results ─────────────────────────────────────────────────
  group('restore_results', () {
    test('restore from backup overwrites corrupt database', () async {
      final dbPath = '${root.path}${Platform.pathSeparator}restore_corrupt.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      // Create backup.
      final backupPath = '$dbPath.bak';
      await File(dbPath).copy(backupPath);

      // Corrupt the database by writing garbage.
      await File(dbPath).writeAsBytes([0xDE, 0xAD, 0xBE, 0xEF]);

      // Restore: copy backup back.
      await File(backupPath).copy(dbPath);

      // Should be openable after restore.
      final db = await service.open(dbPath);
      try {
        expect(db.schemaVersion, 62);
      } finally {
        await db.close();
      }
    });

    test('restore from pre-migration backup migrates forward', () async {
      final dbPath = '${root.path}${Platform.pathSeparator}restore_old.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      // Rewind to 55 and backup.
      final raw = sqlite.sqlite3.open(dbPath);
      raw.execute('PRAGMA user_version = 55');
      raw.close();

      final backupPath = '$dbPath.bak';
      await File(dbPath).copy(backupPath);

      // Restore the old backup to the db path.
      await File(backupPath).copy(dbPath);

      // Open should migrate from 55 to 62.
      final db = await service.open(dbPath);
      try {
        expect(db.schemaVersion, 62);
      } finally {
        await db.close();
      }
    });

    test('restore preserves data integrity', () async {
      final dbPath =
          '${root.path}${Platform.pathSeparator}restore_integrity.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      // Create backup after initial creation.
      final backupPath = '$dbPath.bak';
      await File(dbPath).copy(backupPath);

      // Open, insert a row via raw SQL, close.
      final db = await service.open(dbPath);
      try {
        await db.customInsert(
          "INSERT INTO assets (id, project_id, type, name, created_at, updated_at) "
          "VALUES ('test-restore-id', 'proj-1', 'character', 'Restore Test', "
          "datetime('now'), datetime('now'))",
        );
      } finally {
        await db.close();
      }

      // Restore from backup (pre-insert backup).
      await File(backupPath).copy(dbPath);

      final db2 = await service.open(dbPath);
      try {
        // The row should NOT exist (restored to pre-insert state).
        final rows = await db2
            .customSelect("SELECT * FROM assets WHERE id = 'test-restore-id'")
            .get();
        expect(rows, isEmpty);
      } finally {
        await db2.close();
      }
    });
  });

  // ── repair_results ──────────────────────────────────────────────────
  group('repair_results', () {
    test('corrupt database file is detected on open', () async {
      final dbPath = '${root.path}${Platform.pathSeparator}detect_corrupt.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      // Create backup before corrupting.
      final backupPath = '$dbPath.bak';
      await File(dbPath).copy(backupPath);

      // Corrupt by overwriting with invalid data.
      await File(dbPath).writeAsBytes([0xDE, 0xAD, 0xBE, 0xEF]);

      // Opening should throw an exception (corrupt).
      await expectLater(
        service.open(dbPath),
        throwsA(
          anyOf(
            isA<sqlite.SqliteException>(),
            isA<ProjectDatabaseUnreadableException>(),
            isA<ProjectDatabaseUnavailableException>(),
            isA<FileSystemException>(),
            isA<FormatException>(),
          ),
        ),
      );
    });

    test('repair via backup restore produces valid database', () async {
      final dbPath = '${root.path}${Platform.pathSeparator}repair_restore.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      final backupPath = '$dbPath.bak';
      await File(dbPath).copy(backupPath);

      // Corrupt.
      await File(dbPath).writeAsBytes([0xDE, 0xAD, 0xBE, 0xEF]);

      // Restore.
      await File(backupPath).copy(dbPath);

      // Intact after repair.
      final db = await service.open(dbPath);
      try {
        expect(db.schemaVersion, 62);
        expect(readIntegrityCheck(dbPath), 'ok');
      } finally {
        await db.close();
      }
    });
  });

  // ── interruption_results ────────────────────────────────────────────
  group('interruption_results', () {
    test('database lock during migration produces typed exception', () async {
      final dbPath = '${root.path}${Platform.pathSeparator}interrupt_lock.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      // Rewind to trigger migration.
      final raw = sqlite.sqlite3.open(dbPath);
      raw.execute('PRAGMA user_version = 60');
      raw.execute('BEGIN IMMEDIATE');
      raw.close();

      // Note: closing after BEGIN IMMEDIATE releases the lock.
      // Use a separate process simulation: hold the lock open.
      final lockWriter = sqlite.sqlite3.open(dbPath);
      lockWriter.execute('BEGIN IMMEDIATE');

      // Attempt to open — should fail with lock.
      await expectLater(
        service.open(dbPath),
        throwsA(isA<ProjectDatabaseLockedException>()),
      );

      lockWriter.execute('ROLLBACK');
      lockWriter.close();
    });

    test('interrupted migration recoverable via backup restore', () async {
      final dbPath =
          '${root.path}${Platform.pathSeparator}interrupt_recover.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      // Rewind to 60.
      final raw = sqlite.sqlite3.open(dbPath);
      raw.execute('PRAGMA user_version = 60');
      raw.close();

      // Create backup at old schema state.
      final backupPath = '$dbPath.bak';
      await File(dbPath).copy(backupPath);

      // Simulate interruption: partially write then corrupt.
      await File(dbPath).writeAsBytes([0x00, 0x01]);

      // Restore from pre-migration backup.
      await File(backupPath).copy(dbPath);

      // Open — should succeed and migrate from 60 to 62.
      final db = await service.open(dbPath);
      try {
        expect(db.schemaVersion, 62);
      } finally {
        await db.close();
      }
    });
  });

  // ── integrity_report ────────────────────────────────────────────────
  group('integrity_report', () {
    test('PRAGMA integrity_check returns ok on fresh database', () async {
      final dbPath = '${root.path}${Platform.pathSeparator}integrity_fresh.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      expect(readIntegrityCheck(dbPath), 'ok');
    });

    test('PRAGMA integrity_check returns ok after migration', () async {
      final dbPath = '${root.path}${Platform.pathSeparator}integrity_mig.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      // Rewind and migrate.
      final raw = sqlite.sqlite3.open(dbPath);
      raw.execute('PRAGMA user_version = 61');
      raw.close();

      final db = await service.open(dbPath);
      await db.close();

      expect(readIntegrityCheck(dbPath), 'ok');
    });

    test('PRAGMA integrity_check returns ok after backup-restore', () async {
      final dbPath = '${root.path}${Platform.pathSeparator}integrity_bak.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      final backupPath = '$dbPath.bak';
      await File(dbPath).copy(backupPath);

      // Corrupt then restore.
      await File(dbPath).writeAsBytes([0xDE, 0xAD]);
      await File(backupPath).copy(dbPath);

      expect(readIntegrityCheck(dbPath), 'ok');
    });

    test('schema version is 62 after restore', () async {
      final dbPath = '${root.path}${Platform.pathSeparator}integrity_schema.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      final backupPath = '$dbPath.bak';
      await File(dbPath).copy(backupPath);

      await File(dbPath).writeAsBytes([0xFF]);
      await File(backupPath).copy(dbPath);

      expect(readOnDiskVersion(dbPath), 62);
    });

    test('table count is preserved after restore', () async {
      final dbPath = '${root.path}${Platform.pathSeparator}integrity_tbls.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      final tableCountBefore = countUserTables(dbPath);

      final backupPath = '$dbPath.bak';
      await File(dbPath).copy(backupPath);

      // Corrupt and restore.
      await File(dbPath).writeAsBytes([0x00]);
      await File(backupPath).copy(dbPath);

      final tableCountAfter = countUserTables(dbPath);
      expect(tableCountAfter, tableCountBefore);
    });
  });
}
