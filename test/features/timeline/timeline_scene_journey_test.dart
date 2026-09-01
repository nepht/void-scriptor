import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/presentation/scene_workspace_screen.dart';
import 'package:void_scriptor/features/timeline/application/create_timeline_service.dart';
import 'package:void_scriptor/features/timeline/presentation/timeline_workspace_screen.dart';

class _FakeProjectSessionController extends ProjectSessionController {
  _FakeProjectSessionController(this.session);
  final ProjectSession session;
  @override
  Future<ProjectSession?> build() async => session;
}

void main() {
  testWidgets('scene open timeline journey: live clip drag lands in database', (
    tester,
  ) async {
    late final Directory root;
    late final ProjectSession session;
    late final String sceneId;

    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('s145-timeline-journey-');
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Timeline Journey');
      session = await ProjectSessionManager().open(package);

      final story = CreateStoryService(
        database: session.database,
        paths: ProjectPaths(rootDirectory: root.parent),
      );
      final storyId = await story.createStory(
        projectId: package.projectId,
        title: 'Rise',
      );
      final chapterId = await story.createChapter(
        storyId: storyId,
        title: 'Arrival',
        chapterNumber: 1,
      );
      sceneId = await story.createScene(
        storyId: storyId,
        chapterId: chapterId,
        title: 'Landing',
        sceneNumber: 1,
        estimatedDurationSeconds: 10,
      );
      await story.addBeat(
        sceneId: sceneId,
        content: 'Descend',
        startSecond: 0,
        durationSeconds: 2,
      );
    });
    addTearDown(() => root.delete(recursive: true));
    addTearDown(session.close);

    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(
            () => _FakeProjectSessionController(session),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SceneWorkspaceScreen(sceneId: sceneId, title: 'Landing'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Production entry point from the scene workspace.
    expect(find.text('Open Timeline'), findsOneWidget);
    await tester.tap(find.text('Open Timeline'));
    await tester.pumpAndSettle();

    // TimelineWorkspaceScreen is pushed with the live clip from the database.
    expect(find.byType(TimelineWorkspaceScreen), findsOneWidget);
    expect(find.text('Landing'), findsOneWidget);
    expect(find.text('Descend'), findsOneWidget);

    // Drag the live clip 2 seconds to the right (160 px at 80 px/sec).
    await tester.drag(find.text('Descend'), const Offset(160, 0));
    await tester.pumpAndSettle();

    // The production command path must have written the new timing.
    final timelineService = CreateTimelineService(database: session.database);
    final timelineId = await timelineService.ensureTimelineForScene(
      projectId: session.manifest.id,
      sceneId: sceneId,
    );
    final clip = (await timelineService.getClips(timelineId)).single;
    expect(clip.startSeconds, 2);
    expect(tester.takeException(), isNull);
  });
}
