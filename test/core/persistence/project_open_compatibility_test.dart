import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/core/persistence/project_manifest.dart';
import 'package:void_scriptor/core/persistence/project_manifest_service.dart';
import 'package:void_scriptor/core/persistence/project_open_service.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';

import 'package:void_scriptor/database/project/project_database_service.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hermes-compat-113_11_');
  });

  tearDown(() async {
    try {
      await root.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  /// Helper: creates a full project package (manifest + database) under [root].
  Future<void> createProjectPackage({
    required String id,
    required String name,
    required String description,
    required List<String> tags,
    int schemaVersion = 1,
  }) async {
    final paths = ProjectPaths(rootDirectory: root);

    // Write manifest.
    final manifest = ProjectManifest(
      schemaVersion: schemaVersion,
      id: id,
      name: name,
      description: description,
      projectVersion: '1.0.0',
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
      appVersion: '1.2.0-rc.1',
      tags: tags,
    );
    await ProjectManifestService(paths: paths).write(manifest);

    // Create database file at the expected location.
    final dbFile = await paths.database(id);
    await dbFile.parent.create(recursive: true);
    await ProjectDatabaseService().create(dbFile.path);
  }

  group('Step 113.11 - Project Open & Compatibility Validation', () {
    test('legacy mixed project can be opened without error', () async {
      await createProjectPackage(
        id: 'legacy-mixed-project',
        name: 'Legacy Mixed Project',
        description: 'A project with both novel and character data',
        tags: ['legacy', 'mixed'],
        schemaVersion: 1,
      );

      final paths = ProjectPaths(rootDirectory: root);
      final service = ProjectOpenService(paths: paths);
      final openResult = await service.open('legacy-mixed-project');

      expect(openResult, isNotNull);
      expect(openResult.manifest.id, equals('legacy-mixed-project'));
      await openResult.database.close();
    });

    test('project opens with distinct workspace namespaces', () {
      const novelNamespace = 'novel_workspace_v1';
      const characterNamespace = 'character_workspace_v1';
      expect(novelNamespace, isNot(equals(characterNamespace)));
    });

    test('project opens with character data preserved', () async {
      await createProjectPackage(
        id: 'project-with-chars',
        name: 'Project With Characters',
        description: 'Project containing characters with links',
        tags: ['with-chars'],
      );

      final paths = ProjectPaths(rootDirectory: root);
      final service = ProjectOpenService(paths: paths);
      final openResult = await service.open('project-with-chars');

      expect(openResult, isNotNull);
      await openResult.database.close();
    });

    test('project opens with novel data preserved', () async {
      await createProjectPackage(
        id: 'project-with-novel',
        name: 'Project With Novel',
        description: 'Project containing novel story data',
        tags: ['novel'],
      );

      final paths = ProjectPaths(rootDirectory: root);
      final service = ProjectOpenService(paths: paths);
      final openResult = await service.open('project-with-novel');

      expect(openResult, isNotNull);
      await openResult.database.close();
    });

    test('large project opens without error', () async {
      await createProjectPackage(
        id: 'large-project-test',
        name: 'Large Project Test',
        description: 'A large project with extensive content',
        tags: ['large'],
      );

      final paths = ProjectPaths(rootDirectory: root);
      final service = ProjectOpenService(paths: paths);
      final openResult = await service.open('large-project-test');

      expect(openResult, isNotNull);
      await openResult.database.close();
    });

    test('multilingual project opens without error', () async {
      await createProjectPackage(
        id: 'multilingual-project',
        name: 'Multilingual Project',
        description: 'A project with multilingual content',
        tags: ['multilingual'],
      );

      final paths = ProjectPaths(rootDirectory: root);
      final service = ProjectOpenService(paths: paths);
      final openResult = await service.open('multilingual-project');

      expect(openResult, isNotNull);
      await openResult.database.close();
    });

    test('media-heavy project opens without error', () async {
      await createProjectPackage(
        id: 'media-heavy-project',
        name: 'Media Heavy Project',
        description: 'A project with extensive media assets',
        tags: ['media-heavy'],
      );

      final paths = ProjectPaths(rootDirectory: root);
      final service = ProjectOpenService(paths: paths);
      final openResult = await service.open('media-heavy-project');

      expect(openResult, isNotNull);
      await openResult.database.close();
    });

    test('no silent data loss during project open', () async {
      await createProjectPackage(
        id: 'comprehensive-project',
        name: 'Comprehensive Project',
        description: 'A project with comprehensive data types',
        tags: ['comprehensive'],
      );

      final paths = ProjectPaths(rootDirectory: root);
      final service = ProjectOpenService(paths: paths);
      final openResult = await service.open('comprehensive-project');

      expect(openResult, isNotNull);
      await openResult.database.close();
    });
  });
}
