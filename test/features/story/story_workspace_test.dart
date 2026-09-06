import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/application/debounced_autosave.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/story/presentation/scene_workspace_screen.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';
import 'package:void_scriptor/features/workspaces/application/workspace_projection_cache.dart';
import 'package:void_scriptor/features/workspaces/domain/novel_character_link.dart';

void main() {
  test(
    'story draft autosave persists after debounce and survives reopen',
    () async {
      final root = Directory(
        '${Directory.systemTemp.path}/s15-autosave-${DateTime.now().microsecondsSinceEpoch}',
      );
      await root.create(recursive: true);
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
        title: 'Autosave Story',
      );

      final arcId = await storyService.createArc(
        storyId: storyId,
        title: 'Arc',
      );
      final chapterId = await storyService.createChapter(
        storyId: storyId,
        arcId: arcId,
        title: 'Chapter',
        chapterNumber: 1,
      );
      final sceneId = await storyService.createScene(
        storyId: storyId,
        chapterId: chapterId,
        title: 'Scene',
        sceneNumber: 1,
        estimatedDurationSeconds: 5,
      );
      final repository = StoryRepositoryImpl(
        database: database,
        projectId: 'project-1',
      );

      final autosave = DebouncedAutosave(
        delay: const Duration(milliseconds: 20),
      );
      addTearDown(autosave.dispose);
      autosave.schedule(
        () => repository.saveSceneDraft(sceneId, 'Draft tersimpan'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(await repository.getSceneDraft(sceneId), 'Draft tersimpan');
      await database.close();
      final reopened = await databaseService.open(dbPath);
      addTearDown(reopened.close);
      final reopenedRepository = StoryRepositoryImpl(
        database: reopened,
        projectId: 'project-1',
      );
      expect(
        await reopenedRepository.getSceneDraft(sceneId),
        'Draft tersimpan',
      );
    },
  );

  testWidgets('story workspace and scene workspace render narrow layout', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: StoryWorkspaceScreen(storyId: 'story-1')),
        ),
      ),
    );
    expect(find.text('STORY STRUCTURE'), findsOneWidget);
    expect(find.text('CHAPTERS'), findsOneWidget);
    expect(find.text('SCENE EDITOR'), findsOneWidget);
    expect(find.text('Export Markdown'), findsOneWidget);
    expect(find.text('Export DOCX'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Satu dua tiga');
    await tester.pump();
    expect(find.text('3 kata'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SceneWorkspaceScreen(
              sceneId: 'scene-1',
              title: 'Megacity Landing',
            ),
          ),
        ),
      ),
    );
    expect(find.text('ACTION BEATS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('story workspace renders linked character projection', (
    tester,
  ) async {
    final projection = WorkspaceProjection(
      novelWorkspaceId: 'story-1',
      links: [
        NovelCharacterLink.create(
          linkId: 'link-1',
          novelWorkspaceId: 'story-1',
          characterWorkspaceId: 'character-workspace-1',
          characterId: 'character-1',
          role: 'protagonist',
          visibility: 'visible',
          now: DateTime.utc(2026, 8, 22),
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryWorkspaceScreen(
            storyId: 'story-1',
            workspaceProjection: Future.value(projection),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Linked Characters'), findsOneWidget);
    expect(find.text('character-1 · protagonist'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
