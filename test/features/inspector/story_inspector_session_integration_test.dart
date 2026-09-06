import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/inspector/presentation/inspector_resolver.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';
import 'package:void_scriptor/features/story/presentation/story_inspector.dart';

class _FakeProjectSessionController extends ProjectSessionController {
  _FakeProjectSessionController(this.session);

  final ProjectSession session;

  @override
  Future<ProjectSession?> build() async => session;
}

void main() {
  testWidgets('story inspector resolves a story from a live project session', (
    tester,
  ) async {
    late final Directory root;
    late final ProjectPackage package;
    late final ProjectSession session;
    late final String storyId;

    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('s15-inspector-');
      package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Inspector Integration');
      session = await ProjectSessionManager().open(package);
      storyId = await CreateStoryService(
        database: session.database,
        paths: ProjectPaths(rootDirectory: package.root.parent),
      ).createStory(projectId: package.projectId, title: 'Live Session Story');
    });
    addTearDown(() => root.delete(recursive: true));
    addTearDown(session.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          projectSessionProvider.overrideWith(
            () => _FakeProjectSessionController(session),
          ),
        ],
        child: const MaterialApp(home: InspectorResolver()),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(InspectorResolver)),
    );
    container
        .read(selectionProvider.notifier)
        .select(SelectionModel(assetId: storyId, assetType: AssetType.story));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(StoryInspector), findsOneWidget);
    expect(find.text('Live Session Story'), findsOneWidget);
    expect(find.textContaining('Status'), findsOneWidget);
    expect(find.textContaining('draft'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
