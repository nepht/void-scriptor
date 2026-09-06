import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_file_service.dart';
import 'package:void_scriptor/core/persistence/project_manifest.dart';
import 'package:void_scriptor/core/persistence/project_manifest_service.dart';
import 'package:void_scriptor/core/persistence/project_open_service.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';
import 'package:void_scriptor/core/project_package/void_project_format.dart';

void main() {
  group('Sprint 145.12 fixture matrix — manifest', () {
    test(
      'legacy manifest with id/version aliases parses to canonical fields',
      () {
        final legacy = ProjectManifest.fromJson({
          'format': VoidProjectFormat.name,
          'schemaVersion': 1,
          'id': 'legacy-project',
          'name': 'Legacy Universe',
          'description': '',
          'version': '0.3.0',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-02T00:00:00.000Z',
          'application': {'name': 'Void Scriptor', 'version': '0.9.0'},
          'database': 'project.db',
          'assets': {'root': 'assets'},
        });

        expect(legacy.id, 'legacy-project');
        expect(legacy.projectVersion, '0.3.0');
        expect(legacy.databaseFilename, 'project.db');
        expect(legacy.appVersion, '0.9.0');
      },
    );

    test('manifest one step above current schema is rejected explicitly', () {
      expect(
        () => ProjectManifest.fromJson({
          'schemaVersion': VoidProjectFormat.currentSchema + 1,
          'id': 'future-project',
          'name': 'Future',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-01T00:00:00.000Z',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'missing manifest file surfaces a filesystem failure, not a default',
      () async {
        final root = await Directory.systemTemp.createTemp(
          's14512-missing-manifest-',
        );
        addTearDown(() => root.delete(recursive: true));
        final paths = ProjectPaths(rootDirectory: root);

        expect(
          () => ProjectManifestService(paths: paths).read('never-created'),
          throwsA(isA<FileSystemException>()),
        );
      },
    );
  });

  group('Sprint 145.12 fixture matrix — registry', () {
    test(
      'missing registry file loads as empty without creating a file',
      () async {
        final root = await Directory.systemTemp.createTemp(
          's14512-missing-registry-',
        );
        addTearDown(() => root.delete(recursive: true));
        final service = ProjectRegistryService(rootDirectory: root);

        final projects = await service.load();

        expect(projects, isEmpty);
        expect(
          File(
            '${root.path}${Platform.pathSeparator}projects.json',
          ).existsSync(),
          isFalse,
        );
      },
    );

    test(
      'corrupt registry JSON fails load typed without overwriting the file',
      () async {
        final root = await Directory.systemTemp.createTemp(
          's14512-corrupt-registry-',
        );
        addTearDown(() => root.delete(recursive: true));
        final registryFile = File(
          '${root.path}${Platform.pathSeparator}projects.json',
        );
        await registryFile.writeAsString('{not-json');

        expect(
          ProjectRegistryService(rootDirectory: root).load(),
          throwsA(isA<ProjectRegistryUnreadableException>()),
        );
        expect(await registryFile.readAsString(), '{not-json');
      },
    );

    test('registry schema just above 1 is rejected', () async {
      final root = await Directory.systemTemp.createTemp(
        's14512-future-registry-',
      );
      addTearDown(() => root.delete(recursive: true));
      final file = File('${root.path}${Platform.pathSeparator}projects.json');
      await file.writeAsString(
        const JsonEncoder.withIndent(
          '  ',
        ).convert({'schemaVersion': 2, 'projects': <Object>[]}),
      );

      expect(
        ProjectRegistryService(rootDirectory: root).load(),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('Sprint 145.12 fixture matrix — open lifecycle', () {
    Future<ProjectPaths> buildPackage(
      Directory root,
      String id,
      Map<String, Object?> manifestJson,
    ) async {
      final paths = ProjectPaths(rootDirectory: root);
      await ProjectFileService(paths: paths).createStructure(id);
      final manifestFile = await paths.manifest(id);
      await manifestFile.parent.create(recursive: true);
      await manifestFile.writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(manifestJson)}\n',
      );
      return paths;
    }

    test(
      'open rejects a manifest whose ID does not match the request',
      () async {
        final root = await Directory.systemTemp.createTemp(
          's14512-id-mismatch-',
        );
        addTearDown(() => root.delete(recursive: true));
        const requestedId = 'requested';
        final paths = await buildPackage(root, requestedId, {
          'format': VoidProjectFormat.name,
          'schemaVersion': 1,
          'projectId': 'other-project',
          'name': 'Mismatched',
          'description': '',
          'projectVersion': '0.1.0',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-01T00:00:00.000Z',
          'application': {'name': 'Void Scriptor', 'version': '0.1.0'},
        });

        expect(
          () => ProjectOpenService(paths: paths).open(requestedId),
          throwsA(isA<StateError>()),
        );
      },
    );

    test(
      'open refuses a future-schema manifest before touching the database',
      () async {
        final root = await Directory.systemTemp.createTemp(
          's14512-open-future-schema-',
        );
        addTearDown(() => root.delete(recursive: true));
        const id = 'future-open';
        final paths = await buildPackage(root, id, {
          'format': VoidProjectFormat.name,
          'schemaVersion': VoidProjectFormat.currentSchema + 1,
          'projectId': id,
          'name': 'Future Open',
          'description': '',
          'projectVersion': '0.1.0',
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-01-01T00:00:00.000Z',
          'application': {'name': 'Void Scriptor', 'version': '0.1.0'},
        });

        expect(
          () => ProjectOpenService(paths: paths).open(id),
          throwsA(isA<FormatException>()),
        );
      },
    );
  });
}
