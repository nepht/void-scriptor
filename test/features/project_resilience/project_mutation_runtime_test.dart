import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/character/application/rename_character_command.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/project_resilience/application/project_mutation_runtime.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';

void main() {
  test('runtime persists command history and mutation sequence', () async {
    final root = await Directory.systemTemp.createTemp('s25-runtime-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final dbPath = (await paths.database('p1')).path;
    final service = ProjectDatabaseService();
    await service.create(dbPath);
    final db = await service.open(dbPath);
    addTearDown(db.close);
    final repository = CharacterRepositoryImpl(
      database: db,
      projectId: 'p1',
      paths: paths,
    );
    final character = await repository.createCharacter(name: 'Qowner');
    final runtime = await ProjectMutationRuntime.open(
      database: db,
      projectId: 'p1',
    );
    final command = RenameCharacterCommand(
      id: 'rename-runtime-1',
      projectId: 'p1',
      repository: repository,
      characterId: character.assetId,
      oldName: 'Qowner',
      newName: 'Void Scriptor',
    );

    await runtime.bus.execute(command);

    expect(runtime.state.currentSequence, 1);
    expect(runtime.state.isDirty, isTrue);
    expect(
      (await runtime.historyRepository.list('p1')).single.commandType,
      'character.rename',
    );
    final metadata = await (db.select(
      db.projectMetadata,
    )..where((row) => row.key.equals('mutationSequence'))).getSingle();
    expect(metadata.value, '1');

    await runtime.bus.undo();
    expect(runtime.state.currentSequence, 2);
    expect(
      (await runtime.historyRepository.list('p1')).single.status.name,
      'undone',
    );

    await runtime.bus.redo();
    expect(runtime.state.currentSequence, 3);
    expect(
      (await runtime.historyRepository.list('p1')).single.status.name,
      'applied',
    );

    await runtime.markSaved();
    expect(runtime.state.isDirty, isFalse);
  });
}
