import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/commands/command_event_bus.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/character/application/rename_character_command.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/project_resilience/application/project_mutation_runtime.dart';

void main() {
  test('validators receive committed project mutation events', () async {
    final root = await Directory.systemTemp.createTemp('s25-event-bus-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final service = ProjectDatabaseService();
    final dbPath = (await paths.database('p1')).path;
    await service.create(dbPath);
    final database = await service.open(dbPath);
    addTearDown(database.close);
    final repository = CharacterRepositoryImpl(
      database: database,
      projectId: 'p1',
      paths: paths,
    );
    final character = await repository.createCharacter(name: 'Qowner');
    final runtime = await ProjectMutationRuntime.open(
      database: database,
      projectId: 'p1',
    );
    addTearDown(runtime.dispose);
    final received = Completer<ProjectMutationEvent>();
    final validation = MutationEventListener(
      runtime.eventBus,
      onMutation: (event) async {
        if (!received.isCompleted) received.complete(event);
      },
    );
    addTearDown(validation.dispose);

    await runtime.bus.execute(
      RenameCharacterCommand(
        id: 'rename-event',
        projectId: 'p1',
        repository: repository,
        characterId: character.assetId,
        oldName: 'Qowner',
        newName: 'Nyx',
      ),
    );

    final event = await received.future.timeout(const Duration(seconds: 1));
    expect(event.projectId, 'p1');
    expect(event.commandType, 'character.rename');
    expect(event.sequence, 1);
  });
}
