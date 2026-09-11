import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:void_scriptor/core/persistence/project_file_service.dart';
import 'package:void_scriptor/core/persistence/project_health_service.dart';
import 'package:void_scriptor/core/persistence/project_manifest.dart';
import 'package:void_scriptor/core/persistence/project_manifest_service.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';

/// void-scriptor-hunt-run197 BUG-10 companion: the flattened
/// `on Object { databaseReadable = false; }` collapsed the typed open
/// failure matrix (Locked / TooNew / Unavailable / WriteFailed) into one
/// boolean. The health report must preserve WHICH read-only open failure
/// occurred (one file over, the 145.42 failure matrix defines those typed
/// classes) instead of reporting a generic "unreadable".
void main() {
  late Directory root;
  late ProjectPaths paths;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hunt197-health-typed-');
    paths = ProjectPaths(rootDirectory: root);
  });

  tearDown(() async {
    try {
      await root.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  Future<void> buildHealthyPackage(String id) async {
    await ProjectFileService(paths: paths).createStructure(id);
    final now = DateTime.utc(2026, 9, 11);
    await ProjectManifestService(paths: paths).write(
      ProjectManifest(
        schemaVersion: 1,
        id: id,
        name: 'Health typed $id',
        description: '',
        projectVersion: '0.1.0',
        createdAt: now,
        updatedAt: now,
        appVersion: '0.1.0',
      ),
    );
    await ProjectDatabaseService().create((await paths.database(id)).path);
  }

  test('a future-schema database reports typed SchemaVersionTooNewException '
      'instead of a flattened unreadable flag (BUG-10 run197)', () async {
    const id = 'health-typed-too-new';
    await buildHealthyPackage(id);
    final databaseFile = await paths.database(id);

    // Forge a future schema directly (read-write on our own fixture):
    // open() refuses this file before any real open with
    // SchemaVersionTooNewException; the read-only probe must surface the
    // same typed failure rather than a bare boolean.
    final raw = sqlite.sqlite3.open(databaseFile.path);
    try {
      raw.execute(
        'PRAGMA user_version = ${ProjectDatabase.currentSchemaVersion + 5}',
      );
    } finally {
      raw.close();
    }

    final report = await ProjectHealthService(paths: paths).check(id);

    // The file opens and reads fine as SQLite (openReadOnly is version-
    // blind), so the mechanical probe succeeds - but the future schema
    // must surface as the TYPED failure and make the package unhealthy,
    // exactly like the production open path's guard.
    expect(report.databaseExists, isTrue);
    expect(report.databaseReadable, isTrue);
    expect(report.databaseFailure, isA<SchemaVersionTooNewException>());
    expect(report.isHealthy, isFalse);
  });
}
