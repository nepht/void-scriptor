import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/asset_type.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/character/application/create_character_service.dart';
import 'package:void_scriptor/features/character/presentation/character_controller.dart';
import 'package:void_scriptor/features/explorer/presentation/explorer_panel.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';

void main() {
  late Directory root;
  late String projectId;
  late String characterId;
  late ProviderContainer container;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('void-focus-recovery-');
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Focus Recovery');
    projectId = package.projectId;
    container = ProviderContainer(
      overrides: [
        projectPathsProvider.overrideWithValue(
          ProjectPaths(rootDirectory: root),
        ),
      ],
    );
    // Real async zone: session open and fixture creation run here because
    // widget test bodies run under FakeAsync and cannot await real IO.
    await container.read(projectSessionProvider.future);
    await container
        .read(projectSessionProvider.notifier)
        .openProject(projectId);
    final session = container.read(projectSessionProvider).value!;
    final paths = ProjectPaths(rootDirectory: root);
    await CreateStoryService(
      database: session.database,
      paths: paths,
    ).createStory(projectId: projectId, title: 'Naskah Pertama');
    characterId = await CreateCharacterService(
      database: session.database,
      paths: paths,
    ).create(projectId: projectId, name: 'Lengkung Arka');
  });

  tearDown(() async {
    await container.read(projectSessionProvider.notifier).closeProject();
    container.dispose();
    await root.delete(recursive: true);
  });

  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: ExplorerPanel())),
      ),
    );
    await tester.pumpAndSettle();
    // Production shells keep the autoDispose intent provider alive.
    container.listen(workspaceIntentProvider, (_, _) {});
  }

  testWidgets(
    'invalidated catalog restores the remembered selection once data arrives',
    (tester) async {
      await pumpShell(tester);

      // Session memory: the user last worked on the novel in this project.
      container
          .read(selectionProvider.notifier)
          .select(
            SelectionModel(
              assetId: 'story-1',
              assetType: AssetType.story,
              projectId: projectId,
            ),
          );

      // User navigates to Characters while the character catalog reloads;
      // the remembered character must be restored without another tap.
      container.invalidate(characterControllerProvider(projectId));
      final header = find.text('Characters');
      await tester.ensureVisible(header);
      await tester.tap(header);
      await tester.pumpAndSettle();
      expect(container.read(workspaceIntentProvider)?.$2, AssetType.character);
      expect(container.read(selectionProvider)?.assetType, AssetType.character);
      expect(container.read(selectionProvider)?.assetId, characterId);
    },
  );

  testWidgets(
    'late catalog completion must not steal a selection the user made meanwhile',
    (tester) async {
      await pumpShell(tester);

      // Focus characters with a ready catalog; the character is restored.
      final header = find.text('Characters');
      await tester.ensureVisible(header);
      await tester.tap(header);
      await tester.pumpAndSettle();
      expect(container.read(selectionProvider)?.assetId, characterId);

      // Move to the novel workspace while its catalog reloads; the story
      // catalog completes and restores the remembered story without a tap.
      container.invalidate(storyExplorerProvider(projectId));
      final novel = find.text('Novel Workspace');
      await tester.ensureVisible(novel);
      await tester.tap(novel);
      await tester.pumpAndSettle();
      expect(find.text('Loading...'), findsNothing);
      final storyId = container
          .read(storyExplorerProvider(projectId))
          .value
          ?.first
          .id;
      expect(storyId, isNotNull);
      expect(container.read(selectionProvider)?.assetId, storyId);

      // The restored story is actually rendered as the selected item.
      final storyTile = find.text('Naskah Pertama');
      await tester.ensureVisible(storyTile);
      expect(storyTile, findsOneWidget);
    },
  );
}
