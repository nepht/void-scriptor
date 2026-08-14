import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/character/application/update_character_identity_command.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/character/domain/character_identity_profile.dart';

void main() {
  test('identity command executes undoes and redoes', () async {
    final root = await Directory.systemTemp.createTemp('s25-identity-command-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final service = ProjectDatabaseService();
    final databaseFile = await paths.database('p1');
    await service.create(databaseFile.path);
    final database = await service.open(databaseFile.path);
    addTearDown(database.close);
    final repository = CharacterRepositoryImpl(
      database: database,
      projectId: 'p1',
      paths: paths,
    );
    final character = await repository.createCharacter(name: 'Qowner');
    final oldValue = (await repository.getIdentity(character.assetId))!;
    final newValue = CharacterIdentityProfile(
      characterId: character.assetId,
      faceLock: !oldValue.faceLock,
      hairLock: oldValue.hairLock,
      bodyLock: oldValue.bodyLock,
      colorLock: oldValue.colorLock,
      outfitLock: oldValue.outfitLock,
    );
    final command = UpdateCharacterIdentityCommand(
      id: 'identity-1',
      projectId: 'p1',
      repository: repository,
      oldValue: oldValue,
      newValue: newValue,
    );

    await command.execute();
    expect(
      (await repository.getIdentity(character.assetId))!.faceLock,
      newValue.faceLock,
    );
    await command.undo();
    expect(
      (await repository.getIdentity(character.assetId))!.faceLock,
      oldValue.faceLock,
    );
    await command.redo();
    expect(
      (await repository.getIdentity(character.assetId))!.faceLock,
      newValue.faceLock,
    );
  });
}
