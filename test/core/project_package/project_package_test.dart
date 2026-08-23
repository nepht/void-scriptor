import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_paths.dart';
import 'package:void_scriptor/core/project_package/void_project_format.dart';
import 'package:void_scriptor/core/persistence/project_manifest.dart';

void main() {
  test('package exposes canonical portable directories', () {
    final package = ProjectPackage(
      projectId: 'p-1',
      root: Directory('/tmp/Void Universe.voidproject'),
    );

    String portable(String path) => path.replaceAll('\\', '/');

    expect(
      portable(package.manifestFile.path),
      contains('manifest/project.json'),
    );
    expect(
      portable(package.databaseFile.path),
      contains('database/project.db'),
    );
    expect(
      portable(ProjectPackagePaths.audio(package).path),
      contains('assets/audio'),
    );
    expect(
      portable(ProjectPackagePaths.waveforms(package).path),
      contains('cache/waveforms'),
    );
  });

  test(
    'format and manifest serialize independent schema and application versions',
    () {
      final now = DateTime.utc(2026, 8, 14);
      final manifest = ProjectManifest(
        schemaVersion: VoidProjectFormat.currentSchema,
        id: 'p-1',
        name: 'Void Universe',
        description: 'A portable project',
        projectVersion: '0.1.0',
        createdAt: now,
        updatedAt: now,
        appVersion: '0.1.0',
      );

      final decoded = ProjectManifest.fromJson(manifest.toJson());
      expect(decoded.schemaVersion, 16);
      expect(decoded.appVersion, '0.1.0');
      expect(decoded.toJson()['format'], 'voidproject');
      expect(decoded.toJson()['database'], {'file': 'database/project.db'});
      expect(decoded.toJson()['assets'], {'root': 'assets'});
    },
  );
}
