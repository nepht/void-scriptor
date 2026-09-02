import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/bible/application/lore_backlink_service.dart';
import 'package:void_scriptor/features/character/application/rename_character_command.dart';
import 'package:void_scriptor/features/character/data/character_repository_impl.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';

void main() {
  late Directory root;
  late ProjectDatabaseService service;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('s14527-rename-lore-');
    service = ProjectDatabaseService();
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('rename command retargets lore link segments in scene beats', () async {
    final paths = ProjectPaths(rootDirectory: root);
    final dbPath = (await paths.database('project-1')).path;
    await service.create(dbPath);
    final database = await service.open(dbPath);
    addTearDown(database.close);

    final repository = CharacterRepositoryImpl(
      database: database,
      projectId: 'project-1',
      paths: paths,
    );
    final storyRepo = StoryRepositoryImpl(
      database: database,
      projectId: 'project-1',
    );

    final character = await repository.createCharacter(name: 'Api');
    await database
        .into(database.stories)
        .insert(
          StoriesCompanion.insert(
            assetId: 'story-1',
            projectId: 'project-1',
            title: 'Saga Api',
          ),
        );
    await database
        .into(database.storyScenes)
        .insert(
          StoryScenesCompanion.insert(
            id: 'scene-1',
            storyId: 'story-1',
            chapterId: 'ch-1',
            title: 'Pembukaan',
            sceneNumber: 1,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
    await storyRepo.saveSceneDraft(
      'scene-1',
      'Api menyala. [[Api]] membakar \\[[Api]] dan teks polos Api.',
    );

    final command = RenameCharacterCommand(
      id: 'rename-lore-1',
      projectId: 'project-1',
      repository: repository,
      characterId: character.assetId,
      oldName: 'Api',
      newName: 'Naga Api',
      loreRetarget: const LoreBacklinkService(),
    );

    await command.execute();
    var beat = await (database.select(
      database.sceneBeats,
    )..where((row) => row.sceneId.equals('scene-1'))).getSingle();
    expect(
      beat.content,
      'Api menyala. [[Naga Api]] membakar \\[[Api]] dan teks polos Api.',
    );

    await command.undo();
    beat = await (database.select(
      database.sceneBeats,
    )..where((row) => row.sceneId.equals('scene-1'))).getSingle();
    expect(
      beat.content,
      'Api menyala. [[Api]] membakar \\[[Api]] dan teks polos Api.',
    );

    await command.redo();
    beat = await (database.select(
      database.sceneBeats,
    )..where((row) => row.sceneId.equals('scene-1'))).getSingle();
    expect(
      beat.content,
      'Api menyala. [[Naga Api]] membakar \\[[Api]] dan teks polos Api.',
    );
  });
  test(
    'rename without explicit service still retargets via default wiring',
    () async {
      final paths = ProjectPaths(rootDirectory: root);
      final dbPath = (await paths.database('project-default')).path;
      await service.create(dbPath);
      final database = await service.open(dbPath);
      addTearDown(database.close);

      final repository = CharacterRepositoryImpl(
        database: database,
        projectId: 'project-default',
        paths: paths,
      );
      final storyRepo = StoryRepositoryImpl(
        database: database,
        projectId: 'project-default',
      );

      final character = await repository.createCharacter(name: 'Sang Penjaga');
      await database
          .into(database.stories)
          .insert(
            StoriesCompanion.insert(
              assetId: 'story-d1',
              projectId: 'project-default',
              title: 'Default Wiring Saga',
            ),
          );
      await database
          .into(database.storyScenes)
          .insert(
            StoryScenesCompanion.insert(
              id: 'scene-d1',
              storyId: 'story-d1',
              chapterId: 'ch-d1',
              title: 'Bab Satu',
              sceneNumber: 1,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
      await storyRepo.saveSceneDraft(
        'scene-d1',
        'Guard muncul. [[Sang Penjaga]] berdiri.\\[[Sang Penjaga]] terluka.\\teks',
      );

      final command = RenameCharacterCommand(
        id: 'rename-default-1',
        projectId: 'project-default',
        repository: repository,
        characterId: character.assetId,
        oldName: 'Sang Penjaga',
        newName: 'Penjaga Terakhir',
      );

      await command.execute();
      final beat = await (database.select(
        database.sceneBeats,
      )..where((row) => row.sceneId.equals('scene-d1'))).getSingle();
      expect(
        beat.content,
        'Guard muncul. [[Penjaga Terakhir]] berdiri.\\[[Sang Penjaga]] terluka.\\teks',
      );
    },
  );
}
