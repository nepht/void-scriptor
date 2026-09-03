import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:void_scriptor/database/project/project_database.dart'
    hide CharacterIdentityProfile;
import 'package:void_scriptor/database/project/project_database_service.dart';

/// Sprint 145.33 (Portable Import Export) - future-schema database guard.
///
/// Documented risk finding (2026-09-03e cron): a database whose user_version
/// is NEWER than [ProjectDatabase.currentSchemaVersion] was accepted by the
/// production open path and silently downgraded on disk. Opening a future
/// database with an older application can corrupt data written by the newer
/// schema, so the production open path must reject it with
/// [SchemaVersionTooNewException] without touching the file.
void main() {
  late Directory root;
  setUp(
    () async => root = await Directory.systemTemp.createTemp('hermes-vschema-'),
  );
  tearDown(() => root.delete(recursive: true));

  int readOnDiskVersion(String path) {
    final raw = sqlite.sqlite3.open(path, mode: sqlite.OpenMode.readOnly);
    try {
      return raw.select('PRAGMA user_version').single['user_version'] as int;
    } finally {
      raw.close();
    }
  }

  test(
    'production open rejects a database newer than the supported schema',
    () async {
      final dbPath = '${root.path}/project.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);
      final raw = sqlite.sqlite3.open(dbPath);
      raw.execute(
        'PRAGMA user_version = ${ProjectDatabase.currentSchemaVersion + 1}',
      );
      raw.close();

      await expectLater(
        service.open(dbPath),
        throwsA(isA<SchemaVersionTooNewException>()),
      );

      // The rejected open must not rewrite the on-disk schema version:
      // no silent downgrade as a side effect of the failed open.
      expect(
        readOnDiskVersion(dbPath),
        ProjectDatabase.currentSchemaVersion + 1,
      );
    },
  );

  test(
    'older database versions still open through the production path',
    () async {
      final dbPath = '${root.path}/project-old.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);
      final raw = sqlite.sqlite3.open(dbPath);
      raw.execute('PRAGMA user_version = 53');
      raw.close();

      // Older versions remain the forward-migration contract: the guard
      // passes them through and the production open migrates forward
      // (the full 53->59 wave is covered by portable_schema_compatibility_test).
      final opened = await service.open(dbPath);
      final version = await opened
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(
        version.data['user_version'],
        ProjectDatabase.currentSchemaVersion,
      );
      await opened.close();
    },
  );

  test(
    'current-schema database still opens through the production path',
    () async {
      final dbPath = '${root.path}/project-current.db';
      final service = ProjectDatabaseService();
      await service.create(dbPath);

      final opened = await service.open(dbPath);
      final version = await opened
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(
        version.data['user_version'],
        ProjectDatabase.currentSchemaVersion,
      );
      await opened.close();
    },
  );
}
