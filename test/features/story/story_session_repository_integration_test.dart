import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';

void main() {
  test(
    'session-backed story hierarchy survives repository round trip',
    () async {
      final root = await Directory.systemTemp.createTemp('hermes-s15-story-');
      addTearDown(() => root.delete(recursive: true));

      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Story Session Integration');
      final session = await ProjectSessionManager().open(package);
      try {
        final create = CreateStoryService(
          database: session.database,
          paths: ProjectPaths(rootDirectory: package.root.parent),
        );
        final storyId = await create.createStory(
          projectId: package.projectId,
          title: 'Session Story',
        );
        final arcId = await create.createArc(
          storyId: storyId,
          title: 'Act One',
        );
        final chapterId = await create.createChapter(
          storyId: storyId,
          arcId: arcId,
          title: 'Chapter One',
          chapterNumber: 1,
        );
        final sceneId = await create.createScene(
          storyId: storyId,
          chapterId: chapterId,
          title: 'Opening',
          sceneNumber: 1,
        );
        await create.addBeat(sceneId: sceneId, content: 'The story begins.');

        final hierarchy = await StoryRepositoryImpl(
          database: session.database,
          projectId: package.projectId,
        ).getStoryHierarchy(storyId);

        expect(hierarchy.story.title, 'Session Story');
        expect(hierarchy.arcs.single.id, arcId);
        expect(hierarchy.arcs.single.chapters.single.id, chapterId);
        expect(hierarchy.scenes.single.id, sceneId);
        expect(
          hierarchy.scenes.single.beats.single.content,
          'The story begins.',
        );
      } finally {
        await session.close();
      }
    },
  );
}
