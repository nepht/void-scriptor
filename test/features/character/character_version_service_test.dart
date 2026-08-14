import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/character/application/character_version_service.dart';
import 'package:void_scriptor/features/character/application/rename_character_command.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/project_resilience/application/project_mutation_runtime.dart';
import 'package:void_scriptor/features/project_resilience/application/project_version_control_service.dart';

void main() {
  test('captures compares restores and undoes a character revision', () async {
    final root = await Directory.systemTemp.createTemp(
      's25-character-version-',
    );
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final packageRoot = await paths.project('p1');
    await packageRoot.create(recursive: true);
    final package = ProjectPackage(projectId: 'p1', root: packageRoot);
    final databaseFile = await paths.database('p1');
    final databaseService = ProjectDatabaseService();
    await databaseService.create(databaseFile.path);
    final database = await databaseService.open(databaseFile.path);
    addTearDown(database.close);
    final repository = CharacterRepositoryImpl(
      database: database,
      projectId: 'p1',
      paths: paths,
    );
    final runtime = await ProjectMutationRuntime.open(
      database: database,
      projectId: 'p1',
    );
    final service = CharacterVersionService(
      repository: repository,
      runtime: runtime,
      versions: ProjectVersionControlService(package),
    );
    final character = await repository.createCharacter(name: 'Qowner');
    final initial = await service.capture(character.assetId, label: 'Initial');
    await runtime.bus.execute(
      RenameCharacterCommand(
        id: 'rename-before-restore',
        projectId: 'p1',
        repository: repository,
        characterId: character.assetId,
        oldName: 'Qowner',
        newName: 'Nephthys',
      ),
    );
    final renamed = await service.capture(character.assetId, label: 'Renamed');

    final diff = await service.compare(initial.id, renamed.id);
    expect(diff.changed['displayName'], isNotNull);
    await service.restore(initial.id);
    expect(
      (await repository.getCharacter(character.assetId))!.displayName,
      'Qowner',
    );

    await runtime.bus.undo();
    expect(
      (await repository.getCharacter(character.assetId))!.displayName,
      'Nephthys',
    );
  });
}
