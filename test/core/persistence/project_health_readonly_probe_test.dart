import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:void_scriptor/core/persistence/project_file_service.dart';
import 'package:void_scriptor/core/persistence/project_health_service.dart';
import 'package:void_scriptor/core/persistence/project_manifest.dart';
import 'package:void_scriptor/core/persistence/project_manifest_service.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';

/// void-scriptor-hunt-run197 BUG-10 (Referee REAL, High mechanism / Low
/// reachability): the health check opened the production database via
/// `ProjectDatabaseService().open()`, whose drift initialization runs an
/// unconditional `INSERT ... ON CONFLICT DO UPDATE` into `project_metadata`.
/// A diagnostic must never mutate the project it inspects, so the probe now
/// uses the read-only seam and keeps its hands off the file.
void main() {
  late Directory root;
  late ProjectPaths paths;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hunt197-health-ro-');
    paths = ProjectPaths(rootDirectory: root);
  });

  tearDown(() async {
    try {
      await root.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  Future<void> buildPackage(String id) async {
    await ProjectFileService(paths: paths).createStructure(id);
    final now = DateTime.utc(2026, 9, 11);
    await ProjectManifestService(paths: paths).write(
      ProjectManifest(
        schemaVersion: 1,
        id: id,
        name: 'Health RO $id',
        description: '',
        projectVersion: '0.1.0',
        createdAt: now,
        updatedAt: now,
        appVersion: '0.1.0',
      ),
    );
    await ProjectDatabaseService().create((await paths.database(id)).path);
  }

  test(
    'health check leaves project_metadata untouched (BUG-10 run197)',
    () async {
      const id = 'health-metadata-mutation';
      await buildPackage(id);
      final databaseFile = await paths.database(id);

      // Sabotage the metadata value a diagnostic would "repair": the
      // production open path's initialize() upserts schemaVersion back to
      // the app value on every open. A read-only probe must leave it alone.
      void writeMetadata(String value) {
        final raw = sqlite.sqlite3.open(databaseFile.path);
        try {
          raw.execute(
            "UPDATE project_metadata SET value = '$value' "
            "WHERE key = 'schemaVersion'",
          );
        } finally {
          raw.close();
        }
      }

      String readMetadata() {
        final raw = sqlite.sqlite3.open(
          databaseFile.path,
          mode: sqlite.OpenMode.readOnly,
        );
        try {
          return raw
                  .select(
                    "SELECT value FROM project_metadata WHERE key = 'schemaVersion'",
                  )
                  .single['value']!
              as String;
        } finally {
          raw.close();
        }
      }

      writeMetadata('999');
      expect(readMetadata(), '999');

      final report = await ProjectHealthService(paths: paths).check(id);

      // The check may still judge the package healthy (the database opens
      // read-only fine), but it must NOT have silently rewritten the
      // metadata row it found.
      expect(report.databaseReadable, isTrue);
      expect(readMetadata(), '999');
    },
  );
}
