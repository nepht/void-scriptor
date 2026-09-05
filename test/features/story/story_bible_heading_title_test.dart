import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/data/story_repository_impl.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';

/// Friksi UX native journey (ledger 117f157, input 145.43): heading
/// "Story Bible" harus menampilkan judul cerita dari hierarchy, bukan
/// UUID storyId mentah. I/O SQLite nyata di widget test wajib lewat
/// tester.runAsync (FakeAsync tidak memproses I/O nyata).
void main() {
  testWidgets('story bible heading shows story title once hierarchy loads', (
    tester,
  ) async {
    late final Directory root;
    late final ProjectDatabase database;
    late final String storyId;
    late final StoryRepositoryImpl repository;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('s145-heading-');
      final paths = ProjectPaths(rootDirectory: root);
      final databaseService = ProjectDatabaseService();
      final dbPath = (await paths.database('project-1')).path;
      await databaseService.create(dbPath);
      database = await databaseService.open(dbPath);
      final storyService = CreateStoryService(database: database, paths: paths);
      storyId = await storyService.createStory(
        projectId: 'project-1',
        title: 'Judul Cerita Uji',
      );
      repository = StoryRepositoryImpl(
        database: database,
        projectId: 'project-1',
      );
    });
    addTearDown(() async {
      try {
        await database.close();
      } catch (_) {}
      try {
        if (await root.exists()) {
          await root.delete(recursive: true);
        }
      } catch (_) {}
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: StoryWorkspaceScreen(
              storyId: storyId,
              repository: repository,
            ),
          ),
        ),
      ),
    );

    // Biarkan FutureBuilder hierarchy (I/O nyata) menyelesaikan datanya:
    // poll pump+runAsync interleave (I/O nyata butuh waktu riil di luar
    // zone FakeAsync).
    final heading = find.text('Story Bible — Judul Cerita Uji');
    var loaded = false;
    for (var i = 0; i < 40 && !loaded; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      loaded = tester.any(heading);
    }

    expect(find.text('Story Bible — Judul Cerita Uji'), findsOneWidget);
    expect(find.text('Story Bible — $storyId'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
