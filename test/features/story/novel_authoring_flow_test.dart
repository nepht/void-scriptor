import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';

void main() {
  testWidgets('selected scene title and autosave follow scene selection', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(() async {
      final root = await Directory.systemTemp.createTemp('novel-authoring-');
      final paths = ProjectPaths(rootDirectory: root);
      final databaseService = ProjectDatabaseService();
      final dbPath = (await paths.database('project-1')).path;
      await databaseService.create(dbPath);
      final database = await databaseService.open(dbPath);
      final service = CreateStoryService(database: database, paths: paths);
      final storyId = await service.createStory(
        projectId: 'project-1',
        title: 'Novel Test',
      );
      final chapterId = await service.createChapter(
        storyId: storyId,
        title: 'Bab Satu',
        chapterNumber: 1,
      );
      final firstSceneId = await service.createScene(
        storyId: storyId,
        chapterId: chapterId,
        title: 'Scene Pertama',
        sceneNumber: 1,
      );
      final secondSceneId = await service.createScene(
        storyId: storyId,
        chapterId: chapterId,
        title: 'Scene Kedua',
        sceneNumber: 2,
      );
      final repository = StoryRepositoryImpl(
        database: database,
        projectId: 'project-1',
      );
      await repository.saveSceneDraft(firstSceneId, 'Draft pertama');
      await repository.saveSceneDraft(secondSceneId, 'Draft kedua');
      return _Fixture(
        root: root,
        database: database,
        repository: repository,
        storyId: storyId,
        firstSceneId: firstSceneId,
        secondSceneId: secondSceneId,
      );
    }))!;
    addTearDown(() async {
      await fixture.database.close();
      if (await fixture.root.exists()) {
        await fixture.root.delete(recursive: true);
      }
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryWorkspaceScreen(
            storyId: fixture.storyId,
            repository: fixture.repository,
            sceneId: fixture.firstSceneId,
            exportDirectory: Directory('${fixture.root.path}/exports'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Scene Pertama'), findsWidgets);
    await tester.tap(find.text('Scene Kedua').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Editing — Scene Kedua'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Teks khusus scene kedua');
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(
        await fixture.repository.getSceneDraft(fixture.firstSceneId),
        'Draft pertama',
      );
      expect(
        await fixture.repository.getSceneDraft(fixture.secondSceneId),
        'Teks khusus scene kedua',
      );
    });
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

class _Fixture {
  const _Fixture({
    required this.root,
    required this.database,
    required this.repository,
    required this.storyId,
    required this.firstSceneId,
    required this.secondSceneId,
  });

  final Directory root;
  final ProjectDatabase database;
  final StoryRepositoryImpl repository;
  final String storyId;
  final String firstSceneId;
  final String secondSceneId;
}
