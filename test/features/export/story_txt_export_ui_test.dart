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
  testWidgets('Export TXT menulis naskah teks polos ke export directory', (
    tester,
  ) async {
    final fixture = (await tester.runAsync(() async {
      final root = await Directory.systemTemp.createTemp('s14535-txt-ui-');
      final paths = ProjectPaths(rootDirectory: root);
      final databaseService = ProjectDatabaseService();
      final dbPath = (await paths.database('project-txtui')).path;
      await databaseService.create(dbPath);
      final database = await databaseService.open(dbPath);
      final service = CreateStoryService(database: database, paths: paths);
      final storyId = await service.createStory(
        projectId: 'project-txtui',
        title: 'Novel Ekspor TXT',
      );
      final chapterId = await service.createChapter(
        storyId: storyId,
        title: 'Bab Awal',
        chapterNumber: 1,
      );
      final sceneId = await service.createScene(
        storyId: storyId,
        chapterId: chapterId,
        title: 'Adegan Pembuka',
        sceneNumber: 1,
      );
      final repository = StoryRepositoryImpl(
        database: database,
        projectId: 'project-txtui',
      );
      await repository.saveSceneDraft(sceneId, 'Awan ungu bergerak pelan.');
      return _Fixture(
        root: root,
        database: database,
        repository: repository,
        storyId: storyId,
      );
    }))!;
    addTearDown(() async {
      await fixture.database.close();
      if (await fixture.root.exists()) {
        await fixture.root.delete(recursive: true);
      }
    });

    final exportDir = Directory('${fixture.root.path}/exports');
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StoryWorkspaceScreen(
            storyId: fixture.storyId,
            repository: fixture.repository,
            exportDirectory: exportDir,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Export TXT'), findsOneWidget);
    final btn = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('Export TXT'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(btn.onPressed, isNotNull, reason: 'handler harus aktif dgn binding');
    // Handler menulis via dart:io async; tap dijalankan di real-async zone
    // (runAsync) agar IO ekspor benar-benar selesai, bukan beku di fake zone.
    await tester.runAsync(() async {
      await tester.tap(find.text('Export TXT'));
      final file = File('${exportDir.path}/story.txt');
      for (var i = 0; i < 150 && !file.existsSync(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    // The file can become visible just before the async button handler resumes
    // to enqueue its snackbar. Under a busy aggregate suite, pumpAndSettle may
    // otherwise observe no scheduled frame and return during that narrow gap.
    for (
      var i = 0;
      i < 50 && find.textContaining('TXT diekspor').evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();

    final written = File('${exportDir.path}/story.txt');
    expect(
      written.existsSync(),
      isTrue,
      reason: 'poll 1s habis, file belum ada',
    );
    expect(find.textContaining('TXT diekspor'), findsOneWidget);
    final text = written.readAsStringSync();
    expect(text, contains('Novel Ekspor TXT'));
    expect(text, contains('Awan ungu bergerak pelan.'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Export TXT disabled tanpa binding repository', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StoryWorkspaceScreen(storyId: 'story-1')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final button = find.ancestor(
      of: find.text('Export TXT'),
      matching: find.byType(OutlinedButton),
    );
    expect(button, findsOneWidget);
    final outlined = tester.widget<OutlinedButton>(button);
    expect(outlined.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });
}

class _Fixture {
  const _Fixture({
    required this.root,
    required this.database,
    required this.repository,
    required this.storyId,
  });

  final Directory root;
  final ProjectDatabase database;
  final StoryRepositoryImpl repository;
  final String storyId;
}
