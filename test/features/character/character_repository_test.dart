import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/character/domain/character_identity_profile.dart';
import 'package:void_scriptor/features/character/domain/character_reference.dart';

void main() {
  test('character project rejects a corrupt database file', () async {
    final root = await Directory.systemTemp.createTemp('s08-corrupt-db-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final databaseFile = await paths.database('project-1');
    await databaseFile.parent.create(recursive: true);
    await databaseFile.writeAsString('not a sqlite database');

    await expectLater(
      ProjectDatabaseService().open(databaseFile.path),
      throwsA(anything),
    );
  });

  test('searchCharacters is case-insensitive and project scoped', () async {
    final root = await Directory.systemTemp.createTemp('s08-search-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final service = ProjectDatabaseService();
    final firstPath = (await paths.database('project-1')).path;
    final secondPath = (await paths.database('project-2')).path;
    await service.create(firstPath);
    await service.create(secondPath);
    final secondDatabase = await service.open(secondPath);
    try {
      final second = CharacterRepositoryImpl(
        database: secondDatabase,
        projectId: 'project-2',
        paths: paths,
      );
      await second.createCharacter(name: 'Qowner Other Project');
    } finally {
      await secondDatabase.close();
    }

    final firstDatabase = await service.open(firstPath);
    try {
      final first = CharacterRepositoryImpl(
        database: firstDatabase,
        projectId: 'project-1',
        paths: paths,
      );
      await first.createCharacter(name: 'Qowner Prime');
      await first.createCharacter(name: 'Lyra');

      final matches = await first.searchCharacters('qOwNeR');

      expect(matches.map((character) => character.displayName), [
        'Qowner Prime',
      ]);
      expect(await first.searchCharacters('   '), hasLength(2));
    } finally {
      await firstDatabase.close();
    }
  });

  test('characters stay isolated across project databases', () async {
    final root = await Directory.systemTemp.createTemp('s08-isolation-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final service = ProjectDatabaseService();
    final firstPath = (await paths.database('project-1')).path;
    final secondPath = (await paths.database('project-2')).path;
    await service.create(firstPath);
    await service.create(secondPath);
    final firstDatabase = await service.open(firstPath);
    try {
      final first = CharacterRepositoryImpl(
        database: firstDatabase,
        projectId: 'project-1',
        paths: paths,
      );
      await first.createCharacter(name: 'First Only');
      expect(await first.getCharacters(), hasLength(1));
    } finally {
      await firstDatabase.close();
    }

    final secondDatabase = await service.open(secondPath);
    try {
      final second = CharacterRepositoryImpl(
        database: secondDatabase,
        projectId: 'project-2',
        paths: paths,
      );
      expect(await second.getCharacters(), isEmpty);
    } finally {
      await secondDatabase.close();
    }
  });

  test(
    'folder creation failure compensates committed character rows',
    () async {
      final root = await Directory.systemTemp.createTemp('s08-compensation-');
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      const projectId = 'project-1';
      final databasePath = (await paths.database(projectId)).path;
      final service = ProjectDatabaseService();
      await service.create(databasePath);
      final database = await service.open(databasePath);
      addTearDown(database.close);
      final assetsPath = '${(await paths.project(projectId)).path}/assets';
      await File(assetsPath).writeAsString('blocks directory creation');
      final repository = CharacterRepositoryImpl(
        database: database,
        projectId: projectId,
        paths: paths,
      );

      await expectLater(
        repository.createCharacter(name: 'Must Roll Back'),
        throwsA(isA<FileSystemException>()),
      );

      expect(await repository.getCharacters(), isEmpty);
      expect(await database.select(database.assets).get(), isEmpty);
      expect(await database.select(database.characterModes).get(), isEmpty);
    },
  );

  test(
    'CharacterRepository persists character CRUD after database reopen',
    () async {
      final root = await Directory.systemTemp.createTemp('s08-repository-');
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      const projectId = 'project-1';
      final databasePath = (await paths.database(projectId)).path;
      await ProjectDatabaseService().create(databasePath);

      var database = await ProjectDatabaseService().open(databasePath);
      final repository = CharacterRepositoryImpl(
        database: database,
        projectId: projectId,
        paths: paths,
      );
      final created = await repository.createCharacter(name: 'Qowner');
      expect((await repository.getCharacters()).single.displayName, 'Qowner');
      await repository.updateCharacter(created.copyWithName('Qowner Prime'));
      await database.close();

      database = await ProjectDatabaseService().open(databasePath);
      final reopened = CharacterRepositoryImpl(
        database: database,
        projectId: projectId,
        paths: paths,
      );
      expect(
        (await reopened.getCharacter(created.assetId))?.displayName,
        'Qowner Prime',
      );
      await reopened.deleteCharacter(created.assetId);
      expect(await reopened.getCharacters(), isEmpty);
      expect(
        await Directory(
          '${root.path}/project-1/assets/characters/${created.assetId}',
        ).exists(),
        isFalse,
      );
      await database.close();
    },
  );

  test('identity profile, references, tags, and relations persist', () async {
    final root = await Directory.systemTemp.createTemp('s08-hardening-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    const projectId = 'project-1';
    final databasePath = (await paths.database(projectId)).path;
    await ProjectDatabaseService().create(databasePath);
    final database = await ProjectDatabaseService().open(databasePath);
    addTearDown(database.close);

    final repository = CharacterRepositoryImpl(
      database: database,
      projectId: projectId,
      paths: paths,
    );
    final created = await repository.createCharacter(name: 'Qowner');
    await repository.updateIdentity(
      CharacterIdentityProfile(
        characterId: created.assetId,
        faceLock: false,
        outfitLock: true,
      ),
    );
    final identity = await repository.getIdentity(created.assetId);
    expect(identity?.faceLock, isFalse);
    expect(identity?.outfitLock, isTrue);

    await repository.addReference(
      CharacterReference(
        id: 'reference-1',
        characterId: created.assetId,
        type: 'face_front',
        filePath: 'references/face/front.png',
      ),
    );
    expect(
      (await repository.getReferences(created.assetId)).single.type,
      'face_front',
    );

    await repository.replaceTags(created.assetId, const ['void', 'white-hair']);
    expect(
      await repository.getTags(created.assetId),
      containsAll(['void', 'white-hair']),
    );

    await repository.addRelation(
      id: 'relation-1',
      sourceAssetId: created.assetId,
      targetAssetId: 'weapon-1',
      relationType: 'uses',
    );
    expect(await database.select(database.assetRelations).get(), hasLength(1));
  });
}
