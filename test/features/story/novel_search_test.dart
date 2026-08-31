import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';

void main() {
  test(
    'novel search finds scene drafts across the hierarchy with ordering',
    () async {
      final root = await Directory.systemTemp.createTemp('novel-search-');
      addTearDown(() => root.delete(recursive: true));
      final paths = ProjectPaths(rootDirectory: root);
      final databaseService = ProjectDatabaseService();
      final dbPath = (await paths.database('project-1')).path;
      await databaseService.create(dbPath);
      final database = await databaseService.open(dbPath);
      addTearDown(database.close);
      final storyService = CreateStoryService(database: database, paths: paths);
      final storyId = await storyService.createStory(
        projectId: 'project-1',
        title: 'Novel Searchable',
      );
      final chapterId = await storyService.createChapter(
        storyId: storyId,
        title: 'Bab Satu',
        chapterNumber: 1,
      );
      final firstSceneId = await storyService.createScene(
        storyId: storyId,
        chapterId: chapterId,
        title: 'Scene Pertama',
        sceneNumber: 1,
      );
      final secondSceneId = await storyService.createScene(
        storyId: storyId,
        chapterId: chapterId,
        title: 'Scene Kedua',
        sceneNumber: 2,
      );
      final repository = StoryRepositoryImpl(
        database: database,
        projectId: 'project-1',
      );
      await repository.saveSceneDraft(
        firstSceneId,
        'Qowner menyelam ke void neon rain.',
      );
      await repository.saveSceneDraft(secondSceneId, 'Tidak ada void di sini.');

      final results = await repository.searchNovel('neon');

      expect(results, isNotEmpty);
      expect(results.single.sceneId, firstSceneId);
      expect(results.single.sceneTitle, 'Scene Pertama');
      expect(results.single.chapterTitle, 'Bab Satu');
      expect(results.single.matchCount, 1);

      final all = await repository.searchNovel('void');
      expect(
        all.map((r) => r.sceneId).toList(),
        orderedEquals([firstSceneId, secondSceneId]),
      );
      expect(all.first.matchCount, greaterThanOrEqualTo(1));
      expect(all.last.matchCount, greaterThanOrEqualTo(1));

      final none = await repository.searchNovel('tidak-ada');
      expect(none, isEmpty);
    },
  );

  test('novel search is case-insensitive and trims the query', () async {
    final root = await Directory.systemTemp.createTemp('novel-search-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final databaseService = ProjectDatabaseService();
    final dbPath = (await paths.database('project-1')).path;
    await databaseService.create(dbPath);
    final database = await databaseService.open(dbPath);
    addTearDown(database.close);
    final storyService = CreateStoryService(database: database, paths: paths);
    final storyId = await storyService.createStory(
      projectId: 'project-1',
      title: 'Story',
    );
    final chapterId = await storyService.createChapter(
      storyId: storyId,
      title: 'Bab',
      chapterNumber: 1,
    );
    final sceneId = await storyService.createScene(
      storyId: storyId,
      chapterId: chapterId,
      title: 'Scene',
      sceneNumber: 1,
    );
    final repository = StoryRepositoryImpl(
      database: database,
      projectId: 'project-1',
    );
    await repository.saveSceneDraft(sceneId, 'NEON RAIN di tengah malam');

    final results = await repository.searchNovel('  neon  ');

    expect(results, hasLength(1));
    expect(results.single.sceneId, sceneId);
  });
}
