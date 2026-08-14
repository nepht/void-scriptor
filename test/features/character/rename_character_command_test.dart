import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/character/application/rename_character_command.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';

void main() {
  test('rename character command executes, undoes, and redoes', () async {
    final root = await Directory.systemTemp.createTemp(
      's25-character-command-',
    );
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final databasePath = (await paths.database('project-1')).path;
    final service = ProjectDatabaseService();
    await service.create(databasePath);
    final database = await service.open(databasePath);
    addTearDown(database.close);
    final repository = CharacterRepositoryImpl(
      database: database,
      projectId: 'project-1',
      paths: paths,
    );
    final character = await repository.createCharacter(name: 'Qowner');
    final command = RenameCharacterCommand(
      id: 'rename-character-1',
      projectId: 'project-1',
      repository: repository,
      characterId: character.assetId,
      oldName: 'Qowner',
      newName: 'Void Scriptor',
    );

    await command.execute();
    expect(
      (await repository.getCharacter(character.assetId))?.displayName,
      'Void Scriptor',
    );
    expect(
      (await database.assetDao.getById(character.assetId))?.name,
      'Void Scriptor',
    );

    await command.undo();
    expect(
      (await repository.getCharacter(character.assetId))?.displayName,
      'Qowner',
    );
    expect(
      (await database.assetDao.getById(character.assetId))?.name,
      'Qowner',
    );

    await command.redo();
    expect(
      (await repository.getCharacter(character.assetId))?.displayName,
      'Void Scriptor',
    );
  });
}
