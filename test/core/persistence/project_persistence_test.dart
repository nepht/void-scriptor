import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_scriptor/core/persistence/project_manifest.dart';

import 'package:void_scriptor/core/persistence/project_file_service.dart';
import 'package:void_scriptor/core/persistence/project_health_service.dart';
import 'package:void_scriptor/core/persistence/project_manifest_service.dart';
import 'package:void_scriptor/core/persistence/project_open_service.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/persistence/project_recovery_service.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/projects/domain/project_model.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

void main() {
  test('ProjectManifest round-trips JSON with schema version', () {
    final manifest = ProjectManifest(
      schemaVersion: 16,
      id: 'project-1',
      name: 'Void Universe',
      description: 'Main universe',
      projectVersion: '0.1.0',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
      appVersion: '0.1.0',
      tags: const ['fantasy', 'main'],
      databaseFilename: 'database/project.db',
    );

    final restored = ProjectManifest.fromJson(manifest.toJson());
    expect(restored.id, manifest.id);
    expect(restored.schemaVersion, 16);
    expect(restored.updatedAt, manifest.updatedAt);
    expect(restored.tags, manifest.tags);
    expect(restored.databaseFilename, 'database/project.db');
    expect(manifest.toJson()['database'], {'file': 'database/project.db'});
  });

  test('ProjectManifest rejects unsupported schema version', () {
    expect(
      () => ProjectManifest.fromJson({
        'schemaVersion': 99,
        'id': 'project-1',
        'name': 'Invalid',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('ProjectFileService creates complete project structure', () async {
    final root = await Directory.systemTemp.createTemp('s07-structure-');
    addTearDown(() => root.delete(recursive: true));
    final service = ProjectFileService(rootDirectory: root);

    final project = await service.createStructure('project-1');
    expect(
      project.path,
      endsWith('${Platform.pathSeparator}project-1.voidproject'),
    );
    for (final folder in ProjectFileService.requiredFolders) {
      expect(
        Directory(
          '${project.path}${Platform.pathSeparator}$folder',
        ).existsSync(),
        isTrue,
      );
    }
    expect(
      Directory('${project.path}${Platform.pathSeparator}story').existsSync(),
      isTrue,
    );
    expect(
      Directory(
        '${project.path}${Platform.pathSeparator}environments',
      ).existsSync(),
      isTrue,
    );
  });

  test('ProjectRegistryService persists and reloads projects', () async {
    final root = await Directory.systemTemp.createTemp('s07-registry-');
    addTearDown(() => root.delete(recursive: true));
    final service = ProjectRegistryService(rootDirectory: root);
    final project = ProjectModel(
      id: 'project-1',
      name: 'Void Universe',
      description: '',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
      lastOpenedAt: DateTime.utc(2026),
      localPath: '${root.path}/project-1',
      version: '0.1.0',
    );

    await service.upsert(project);
    final restored = await ProjectRegistryService(rootDirectory: root).load();
    expect(restored.single.id, project.id);
    expect(restored.single.name, project.name);
  });

  test(
    'ProjectRegistryService preserves multiple independent projects',
    () async {
      final root = await Directory.systemTemp.createTemp('s07-multi-registry-');
      addTearDown(() => root.delete(recursive: true));
      final service = ProjectRegistryService(rootDirectory: root);
      final now = DateTime.utc(2026);
      for (final id in ['project-1', 'project-2']) {
        await service.upsert(
          ProjectModel(
            id: id,
            name: 'Project $id',
            description: '',
            createdAt: now,
            updatedAt: now,
            lastOpenedAt: now,
            localPath: '${root.path}/$id.voidproject',
            version: '0.1.0',
          ),
        );
      }

      await service.remove('project-1');
      final restored = await ProjectRegistryService(rootDirectory: root).load();

      expect(restored.map((project) => project.id), ['project-2']);
      expect(restored.single.localPath, endsWith('project-2.voidproject'));
    },
  );

  test('ProjectPaths resolves project-local manifest and database', () async {
    final root = await Directory.systemTemp.createTemp('s07-paths-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    expect((await paths.project('abc')).path, endsWith('abc.voidproject'));
    expect(
      (await paths.manifest('abc')).path,
      endsWith(
        'abc.voidproject${Platform.pathSeparator}manifest${Platform.pathSeparator}project.json',
      ),
    );
    expect(
      (await paths.database('abc')).path,
      endsWith(
        'abc.voidproject${Platform.pathSeparator}database${Platform.pathSeparator}project.db',
      ),
    );
  });

  test('ProjectRegistryService rejects unsupported registry schema', () async {
    final root = await Directory.systemTemp.createTemp('s07-schema-');
    addTearDown(() => root.delete(recursive: true));
    final file = File('${root.path}${Platform.pathSeparator}projects.json');
    await file.writeAsString('{"schemaVersion": 99, "projects": []}');

    expect(
      ProjectRegistryService(rootDirectory: root).load(),
      throwsA(isA<FormatException>()),
    );
  });

  test('ProjectHealthService validates a complete project package', () async {
    final root = await Directory.systemTemp.createTemp('s07-health-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    const id = 'project-health';
    final directory = await ProjectFileService(
      paths: paths,
    ).createStructure(id);
    final now = DateTime.utc(2026, 1, 1);
    await ProjectManifestService(paths: paths).write(
      ProjectManifest(
        schemaVersion: 1,
        id: id,
        name: 'Health Project',
        description: '',
        projectVersion: '0.1.0',
        createdAt: now,
        updatedAt: now,
        appVersion: '0.1.0',
      ),
    );
    await ProjectDatabaseService().create((await paths.database(id)).path);

    final report = await ProjectHealthService(paths: paths).check(id);
    expect(report.isHealthy, isTrue);
    expect(report.databaseReadable, isTrue);
    expect(directory.existsSync(), isTrue);
  });

  test(
    'ProjectHealthService reports corrupt manifest without throwing',
    () async {
      final root = await Directory.systemTemp.createTemp(
        's07-corrupt-manifest-',
      );
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      const id = 'project-corrupt-manifest';
      await ProjectFileService(paths: paths).createStructure(id);
      final manifest = await paths.manifest(id);
      await manifest.parent.create(recursive: true);
      await manifest.writeAsString('{not-json');
      await ProjectDatabaseService().create((await paths.database(id)).path);

      final report = await ProjectHealthService(paths: paths).check(id);

      expect(report.manifestExists, isTrue);
      expect(report.manifestReadable, isFalse);
      expect(report.isHealthy, isFalse);
    },
  );

  test(
    'ProjectHealthService reports corrupt database without throwing',
    () async {
      final root = await Directory.systemTemp.createTemp(
        's07-corrupt-database-',
      );
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      const id = 'project-corrupt-database';
      await ProjectFileService(paths: paths).createStructure(id);
      final now = DateTime.utc(2026, 1, 1);
      await ProjectManifestService(paths: paths).write(
        ProjectManifest(
          schemaVersion: 1,
          id: id,
          name: 'Corrupt Database',
          description: '',
          projectVersion: '0.1.0',
          createdAt: now,
          updatedAt: now,
          appVersion: '0.1.0',
        ),
      );
      final database = await paths.database(id);
      await database.parent.create(recursive: true);
      await database.writeAsString('not a sqlite database');

      final report = await ProjectHealthService(paths: paths).check(id);

      expect(report.databaseExists, isTrue);
      expect(report.databaseReadable, isFalse);
      expect(report.isHealthy, isFalse);
    },
  );

  test(
    'ProjectOpenService opens manifest and project database together',
    () async {
      final root = await Directory.systemTemp.createTemp('s07-open-');
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      const id = 'project-open';
      await ProjectFileService(paths: paths).createStructure(id);
      final now = DateTime.utc(2026, 1, 1);
      await ProjectManifestService(paths: paths).write(
        ProjectManifest(
          schemaVersion: 1,
          id: id,
          name: 'Open Project',
          description: '',
          projectVersion: '0.1.0',
          createdAt: now,
          updatedAt: now,
          appVersion: '0.1.0',
        ),
      );
      await ProjectDatabaseService().create((await paths.database(id)).path);

      final opened = await ProjectOpenService(paths: paths).open(id);
      expect(opened.manifest.id, id);
      expect(
        await opened.database.select(opened.database.projectMetadata).get(),
        isNotEmpty,
      );
      await opened.close();
    },
  );

  test(
    'ProjectSessionController opens and closes the active project database',
    () async {
      final root = await Directory.systemTemp.createTemp('s07-session-');
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      const id = 'project-session';
      await ProjectFileService(paths: paths).createStructure(id);
      final now = DateTime.utc(2026, 1, 1);
      await ProjectManifestService(paths: paths).write(
        ProjectManifest(
          schemaVersion: 1,
          id: id,
          name: 'Session Project',
          description: '',
          projectVersion: '0.1.0',
          createdAt: now,
          updatedAt: now,
          appVersion: '0.1.0',
        ),
      );
      await ProjectDatabaseService().create((await paths.database(id)).path);
      final container = ProviderContainer(
        overrides: [projectPathsProvider.overrideWithValue(paths)],
      );
      addTearDown(container.dispose);

      final opened = await container
          .read(projectSessionProvider.notifier)
          .openProject(id);
      expect(opened.manifest.id, id);
      expect(container.read(projectSessionProvider).value?.manifest.id, id);
      expect(
        File(
          '${(await paths.project(id)).path}${Platform.pathSeparator}session.lock',
        ).existsSync(),
        isTrue,
      );
      await container.read(projectSessionProvider.notifier).closeProject();
      expect(container.read(projectSessionProvider).value, isNull);
    },
  );

  test(
    'ProjectDatabaseService creates a project database with metadata',
    () async {
      final root = await Directory.systemTemp.createTemp('s07-database-');
      addTearDown(() => root.delete(recursive: true));
      final databasePath = '${root.path}${Platform.pathSeparator}project.db';

      await ProjectDatabaseService().create(databasePath);
      expect(File(databasePath).existsSync(), isTrue);
    },
  );

  test(
    'ProjectRecoveryService keeps a backup during atomic replacement',
    () async {
      final root = await Directory.systemTemp.createTemp('s07-recovery-');
      addTearDown(() => root.delete(recursive: true));
      final file = File('${root.path}${Platform.pathSeparator}projects.json');
      const service = ProjectRecoveryService();

      await service.atomicWrite(target: file, content: 'first');
      await service.atomicWrite(target: file, content: 'second');
      expect(await file.readAsString(), 'second');
      expect(await File('${file.path}.bak').readAsString(), 'first');
      expect(await service.restoreBackup(file), isTrue);
      expect(await file.readAsString(), 'first');
    },
  );
}
