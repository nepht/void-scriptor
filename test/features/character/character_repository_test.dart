import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';

void main() {
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
      await database.close();
    },
  );
}
