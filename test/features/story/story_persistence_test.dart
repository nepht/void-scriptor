import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';

void main() {
  test('story hierarchy and scene context survive database restart', () async {
    final root = await Directory.systemTemp.createTemp('s15-story-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final dbPath = (await paths.database('project-1')).path;
    final service = ProjectDatabaseService();
    await service.create(dbPath);
    final first = await service.open(dbPath);
    final storyService = CreateStoryService(database: first, paths: paths);
    final storyId = await storyService.createStory(
      projectId: 'project-1',
      title: 'Qowner: Rise of the Void',
    );
    final arcId = await storyService.createArc(
      storyId: storyId,
      title: 'Neo Megacity Arc',
    );
    final chapterId = await storyService.createChapter(
      storyId: storyId,
      arcId: arcId,
      title: 'Arrival',
      chapterNumber: 1,
    );
    final sceneId = await storyService.createScene(
      storyId: storyId,
      chapterId: chapterId,
      title: 'Megacity Landing',
      sceneNumber: 1,
      estimatedDurationSeconds: 10,
    );
    await storyService.addCharacter(
      sceneId: sceneId,
      characterId: 'character-1',
      modeId: 'mode-1',
      role: 'protagonist',
    );
    await storyService.setEnvironmentContext(
      sceneId: sceneId,
      environmentId: 'environment-1',
      zoneId: 'zone-1',
      timePreset: 'noon',
    );
    await storyService.addBeat(
      sceneId: sceneId,
      content: 'Qowner descends.',
      startSecond: 0,
      durationSeconds: 2,
    );
    await first.close();

    final second = await service.open(dbPath);
    addTearDown(second.close);
    final repository = StoryRepositoryImpl(
      database: second,
      projectId: 'project-1',
    );
    final hierarchy = await repository.getStoryHierarchy(storyId);
    expect(hierarchy.story.title, 'Qowner: Rise of the Void');
    expect(
      hierarchy.arcs.single.chapters.single.scenes.single.title,
      'Megacity Landing',
    );
    expect(hierarchy.scenes.single.characters.single.modeId, 'mode-1');
    expect(hierarchy.scenes.single.environment?.timePreset, 'noon');
    expect(hierarchy.scenes.single.beats.single.content, 'Qowner descends.');
    expect(second.schemaVersion, 51);
  });
}
