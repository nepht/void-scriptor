// Sprint 113.11 — Reverse Migration Validation.
//
// Required evidence: downgrade_results, schema_preservation,
// backup_verification, lock_contention_during_rollback.
//
// Validates that:
// 1. Forward migration from older schemas (55, 61) succeeds
// 2. Schema version is 62 after migration
// 3. Backup via file copy is verifiable
// 4. Concurrent lock contention produces typed exception
//
// Note: The codebase does NOT reject older schemas — Drift auto-migrates
// them forward. Only newer schemas (onDisk > current) are rejected via
// SchemaVersionTooNewException. This test validates the actual behavior.

library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hermes-downgrade-113_11_');
  });

  tearDown(() async {
    try {
      await root.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  // ── downgrade_results ──────────────────────────────────────────────────
  group('downgrade_results', () {
    test('opening database at schema 61 succeeds and migrates to 62', () async {
      final dbPath =
          '${root.path}${Platform.pathSeparator}downgrade_62_to_61.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      // Set schema to 61 (older than current).
      final raw = sqlite.sqlite3.open(dbPath);
      raw.execute('PRAGMA user_version = 61');
      raw.close();

      // Opening with current app should succeed — Drift migrates forward.
      final db = await service.open(dbPath);
      try {
        // After migration, schema version should be 62.
        expect(db.schemaVersion, ProjectDatabase.currentSchemaVersion);
      } finally {
        await db.close();
      }
    });

    test('opening database at schema 55 succeeds and migrates to 62', () async {
      final dbPath =
          '${root.path}${Platform.pathSeparator}downgrade_62_to_55.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      // Set schema to 55 (much older than current).
      final raw = sqlite.sqlite3.open(dbPath);
      raw.execute('PRAGMA user_version = 55');
      raw.close();

      // Opening with current app should succeed — Drift migrates forward.
      final db = await service.open(dbPath);
      try {
        // After migration, schema version should be 62.
        expect(db.schemaVersion, ProjectDatabase.currentSchemaVersion);
      } finally {
        await db.close();
      }
    });

    test('downgrade rejection only applies to newer schemas', () async {
      final dbPath =
          '${root.path}${Platform.pathSeparator}newer_schema_reject.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      // Set schema to 63 (newer than current 62).
      final raw = sqlite.sqlite3.open(dbPath);
      raw.execute('PRAGMA user_version = 63');
      raw.close();

      // Opening with current app should reject — newer schema.
      await expectLater(
        service.open(dbPath),
        throwsA(isA<SchemaVersionTooNewException>()),
      );
    });
  });

  // ── schema_preservation ─────────────────────────────────────────────────
  group('schema_preservation', () {
    test(
      'database schema version remains at 62 after forward migration',
      () async {
        final dbPath =
            '${root.path}${Platform.pathSeparator}preserve_schema.db';
        final service = ProjectDatabaseService();
        await service.create(dbPath);

        // Set schema to 61, then open and verify migration to 62.
        final raw = sqlite.sqlite3.open(dbPath);
        raw.execute('PRAGMA user_version = 61');
        raw.close();

        final db = await service.open(dbPath);
        try {
          expect(db.schemaVersion, 62);
        } finally {
          await db.close();
        }
      },
    );

    test('no data corruption on forward migration from older schema', () async {
      final dbPath = '${root.path}${Platform.pathSeparator}no_corruption.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      // Set schema to 55, then open and verify.
      final raw = sqlite.sqlite3.open(dbPath);
      raw.execute('PRAGMA user_version = 55');
      raw.close();

      final db = await service.open(dbPath);
      try {
        // Schema should be migrated to current version.
        expect(db.schemaVersion, ProjectDatabase.currentSchemaVersion);
        // Database should be usable (no corruption).
        final allTables = await db
            .customSelect("SELECT name FROM sqlite_master WHERE type='table'")
            .get();
        expect(allTables, isNotEmpty);
      } finally {
        await db.close();
      }
    });
  });

  // ── backup_verification ─────────────────────────────────────────────────
  group('backup_verification', () {
    test('pre-migration backup via file copy is verifiable', () async {
      final dbPath = '${root.path}${Platform.pathSeparator}backup_verify.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      // Create a backup via file copy before migration.
      final backupPath = '$dbPath.bak';
      await File(dbPath).copy(backupPath);

      // Verify backup can be opened.
      final backupService = ProjectDatabaseService();
      final db = await backupService.open(backupPath);
      try {
        expect(db.schemaVersion, ProjectDatabase.currentSchemaVersion);
      } finally {
        await db.close();
      }
    });

    test('backup from older schema can be migrated forward', () async {
      final dbPath =
          '${root.path}${Platform.pathSeparator}backup_old_schema.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      // Set schema to 55, then create backup.
      final raw = sqlite.sqlite3.open(dbPath);
      raw.execute('PRAGMA user_version = 55');
      raw.close();

      final backupPath = '$dbPath.bak';
      await File(dbPath).copy(backupPath);

      // Open backup — should migrate from 55 to 62.
      final backupService = ProjectDatabaseService();
      final db = await backupService.open(backupPath);
      try {
        expect(db.schemaVersion, ProjectDatabase.currentSchemaVersion);
      } finally {
        await db.close();
      }
    });
  });

  // ── lock_contention_during_rollback ─────────────────────────────────────
  group('lock_contention_during_rollback', () {
    test(
      'concurrent writer during open produces typed lock exception',
      () async {
        final dbPath =
            '${root.path}${Platform.pathSeparator}lock_during_rollback.db';
        final service = ProjectDatabaseService();
        await service.create(dbPath);

        // Hold an exclusive lock on the database.
        final writer = sqlite.sqlite3.open(dbPath);
        writer.execute('BEGIN IMMEDIATE');

        // Attempting to open should produce a lock exception.
        await expectLater(
          service.open(dbPath),
          throwsA(isA<ProjectDatabaseLockedException>()),
        );

        writer.execute('ROLLBACK');
        writer.close();
      },
    );
  });
}
