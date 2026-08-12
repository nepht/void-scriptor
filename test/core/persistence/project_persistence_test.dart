import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_manifest.dart';

import 'package:void_scriptor/core/persistence/project_file_service.dart';
import 'package:void_scriptor/core/persistence/project_registry_service.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/persistence/project_recovery_service.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/projects/domain/project_model.dart';

void main() {
  test('ProjectManifest round-trips JSON with schema version', () {
    final manifest = ProjectManifest(
      schemaVersion: 1,
      id: 'project-1',
      name: 'Void Universe',
      description: 'Main universe',
      projectVersion: '0.1.0',
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
      appVersion: '0.1.0',
    );

    final restored = ProjectManifest.fromJson(manifest.toJson());
    expect(restored.id, manifest.id);
    expect(restored.schemaVersion, 1);
    expect(restored.updatedAt, manifest.updatedAt);
  });

  test('ProjectFileService creates complete project structure', () async {
    final root = await Directory.systemTemp.createTemp('s07-structure-');
    addTearDown(() => root.delete(recursive: true));
    final service = ProjectFileService(rootDirectory: root);

    final project = await service.createStructure('project-1');
    expect(project.path, endsWith('${Platform.pathSeparator}project-1'));
    for (final folder in ProjectFileService.requiredFolders) {
      expect(
        Directory(
          '${project.path}${Platform.pathSeparator}$folder',
        ).existsSync(),
        isTrue,
      );
    }
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

  test('ProjectPaths resolves project-local manifest and database', () async {
    final root = await Directory.systemTemp.createTemp('s07-paths-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    expect((await paths.project('abc')).path, endsWith('abc'));
    expect(
      (await paths.manifest('abc')).path,
      endsWith('abc${Platform.pathSeparator}project.json'),
    );
    expect(
      (await paths.database('abc')).path,
      endsWith('abc${Platform.pathSeparator}project.db'),
    );
  });

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
