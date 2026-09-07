import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_file_service.dart';
import 'package:void_scriptor/core/persistence/project_health_service.dart';
import 'package:void_scriptor/core/persistence/project_manifest_service.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/void_project_format.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/core/persistence/project_manifest.dart';

void main() {
  late Directory root;
  late ProjectPaths paths;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('core-hunt-20260906-health-');
    paths = ProjectPaths(rootDirectory: root);
  });

  tearDown(() async {
    try {
      await root.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  Future<void> buildPackage(String id, int schemaVersion) async {
    await ProjectFileService(paths: paths).createStructure(id);
    final now = DateTime.utc(2026, 9, 6);
    await ProjectManifestService(paths: paths).write(
      ProjectManifest(
        schemaVersion: schemaVersion,
        id: id,
        name: 'Health $id',
        description: '',
        projectVersion: '0.1.0',
        createdAt: now,
        updatedAt: now,
        appVersion: '0.1.0',
      ),
    );
    await ProjectDatabaseService().create((await paths.database(id)).path);
  }

  group('core-hunt-20260906 health check schema range (BUG-01)', () {
    test(
      'a package written with the current schema (${VoidProjectFormat.currentSchema}) '
      'is healthy, not "unhealthy"',
      () async {
        const id = 'current-schema';
        await buildPackage(id, VoidProjectFormat.currentSchema);

        final report = await ProjectHealthService(paths: paths).check(id);

        expect(report.manifestReadable, isTrue);
        expect(report.schemaSupported, isTrue);
        expect(report.isHealthy, isTrue);
      },
    );

    test(
      'a manifest one schema above current is rejected as unsupported',
      () async {
        const id = 'future-schema';
        await buildPackage(id, VoidProjectFormat.currentSchema + 1);

        final report = await ProjectHealthService(paths: paths).check(id);

        expect(report.isHealthy, isFalse);
      },
    );

    test('a legacy schema-1 package stays healthy', () async {
      const id = 'legacy-schema';
      await buildPackage(id, 1);

      final report = await ProjectHealthService(paths: paths).check(id);

      expect(report.schemaSupported, isTrue);
      expect(report.isHealthy, isTrue);
    });
  });
}
