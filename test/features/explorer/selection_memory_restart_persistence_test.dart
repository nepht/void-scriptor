import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:void_scriptor/core/domain/asset_type.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_memory_snapshot.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/explorer/presentation/explorer_panel.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/story/application/create_story_service.dart';

Future<void> _waitUntil(
  Future<bool> Function() probe, {
  required String description,
}) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(deadline)) {
    if (await probe()) return;
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
  fail('Timed out waiting for $description');
}

void main() {
  group('selection memory snapshot file contract', () {
    test('missing file loads empty and round-trips entries', () async {
      final dir = await Directory.systemTemp.createTemp('void-selmem-');
      addTearDown(() => dir.delete(recursive: true));
      final file = File(p.join(dir.path, 'selection_memory.json'));

      expect(await loadSelectionMemorySnapshot(file), isEmpty);

      await persistSelectionMemorySnapshot(file, {
        ('p1', AssetType.story): 'story-2',
        ('p1', AssetType.character): 'character-1',
        ('p2', AssetType.story): 'other-project-story',
      });

      final loaded = await loadSelectionMemorySnapshot(file);
      expect(loaded[('p1', AssetType.story)], 'story-2');
      expect(loaded[('p1', AssetType.character)], 'character-1');
      expect(loaded[('p2', AssetType.story)], 'other-project-story');
    });

    test(
      'corrupt or unknown content never throws and yields no entries',
      () async {
        final dir = await Directory.systemTemp.createTemp('void-selmem-');
        addTearDown(() => dir.delete(recursive: true));
        final file = File(p.join(dir.path, 'selection_memory.json'));

        await file.writeAsString('{not json');
        expect(await loadSelectionMemorySnapshot(file), isEmpty);

        await file.writeAsString(
          '{"version":1,"workspaces":{"p1":{"noSuchType":"x"}}}',
        );
        expect(await loadSelectionMemorySnapshot(file), isEmpty);
      },
    );
  });

  group('controller hydration', () {
    late ProviderContainer container;
    setUp(() {
      container = ProviderContainer();
    });
    tearDown(() => container.dispose());

    test('hydrated memory restores the remembered asset, not the first', () {
      final controller = container.read(selectionProvider.notifier);
      controller.hydrateWorkspaceMemory({
        ('p1', AssetType.story): 'story-2',
      }, projectId: 'p1');

      controller.selectWorkspace(
        projectId: 'p1',
        type: AssetType.story,
        availableAssetIds: const ['story-1', 'story-2'],
      );
      expect(container.read(selectionProvider)?.assetId, 'story-2');
    });

    test(
      'user picks win over hydrated memory and drain exposes the snapshot',
      () {
        final controller = container.read(selectionProvider.notifier);
        controller.hydrateWorkspaceMemory({
          ('p1', AssetType.story): 'story-2',
        }, projectId: 'p1');
        controller.select(
          const SelectionModel(
            assetId: 'story-1',
            assetType: AssetType.story,
            projectId: 'p1',
          ),
        );

        expect(
          controller.workspaceMemorySnapshot(projectId: 'p1')[(
            'p1',
            AssetType.story,
          )],
          'story-1',
        );

        // Re-hydration must never resurrect stale entries over live picks.
        controller.hydrateWorkspaceMemory({
          ('p1', AssetType.story): 'story-2',
        }, projectId: 'p1');
        expect(
          controller.workspaceMemorySnapshot(projectId: 'p1')[(
            'p1',
            AssetType.story,
          )],
          'story-1',
        );
      },
    );

    test('hydration happens once per project and is reported', () {
      final controller = container.read(selectionProvider.notifier);
      expect(controller.isWorkspaceMemoryHydrated, isFalse);
      controller.hydrateWorkspaceMemory({
        ('p1', AssetType.story): 'story-2',
      }, projectId: 'p1');
      expect(controller.isWorkspaceMemoryHydrated, isTrue);
      // Same project: re-hydration must not resurrect stale entries over
      // the already-hydrated memory.
      controller.hydrateWorkspaceMemory({
        ('p1', AssetType.story): 'story-9',
      }, projectId: 'p1');
      expect(
        controller.workspaceMemorySnapshot(projectId: 'p1')[(
          'p1',
          AssetType.story,
        )],
        'story-2',
      );
      // A different project hydrates independently (hunt-20260910b BUG-2).
      expect(controller.isWorkspaceMemoryHydratedForProject('p2'), isFalse);
      controller.hydrateWorkspaceMemory({
        ('p2', AssetType.character): 'character-9',
      }, projectId: 'p2');
      expect(controller.isWorkspaceMemoryHydratedForProject('p2'), isTrue);
      expect(
        controller.workspaceMemorySnapshot(projectId: 'p2')[(
          'p2',
          AssetType.character,
        )],
        'character-9',
      );
    });
  });

  group('restart persistence journey', () {
    test(
      'selection memory survives an app restart through the real snapshot file',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'void-selmem-restart-',
        );
        addTearDown(() async {
          try {
            await root.delete(recursive: true);
          } catch (_) {}
        });

        final package = await ProjectPackageService(
          rootDirectory: root,
        ).create(name: 'Restart Memory');
        final projectId = package.projectId;
        final paths = ProjectPaths(rootDirectory: root);

        // --- App run 1 -----------------------------------------------------
        final containerA = ProviderContainer(
          overrides: [projectPathsProvider.overrideWithValue(paths)],
        );
        await containerA.read(projectSessionProvider.future);
        final sessionA = await containerA
            .read(projectSessionProvider.notifier)
            .openProject(projectId);
        final service = CreateStoryService(
          database: sessionA.database,
          paths: paths,
        );
        final story1 = await service.createStory(
          projectId: projectId,
          title: 'Pertama',
        );
        final story2 = await service.createStory(
          projectId: projectId,
          title: 'Kedua',
        );

        // Production shells mount the persistence provider through the
        // explorer/resolver; an active listener keeps it alive identically.
        containerA.listen(selectionMemoryPersistenceProvider, (_, _) {});

        // The user works on the second novel.
        containerA
            .read(selectionProvider.notifier)
            .select(
              SelectionModel(
                assetId: story2,
                assetType: AssetType.story,
                projectId: projectId,
              ),
            );

        final snapshotFile = File(
          p.join(sessionA.package.cacheDirectory.path, 'selection_memory.json'),
        );
        await _waitUntil(
          () => snapshotFile.exists(),
          description: 'snapshot file written before restart',
        );
        final persisted = await loadSelectionMemorySnapshot(snapshotFile);
        expect(persisted[(projectId, AssetType.story)], story2);

        // Orderly shutdown of app run 1 before relaunch: closing the
        // session releases the project lock. The container is intentionally
        // not disposed so the session is closed exactly once.
        await sessionA.close();

        final containerB = ProviderContainer(
          overrides: [projectPathsProvider.overrideWithValue(paths)],
        );
        addTearDown(containerB.dispose);
        await containerB.read(projectSessionProvider.future);
        await containerB
            .read(projectSessionProvider.notifier)
            .openProject(projectId);
        containerB.listen(selectionMemoryPersistenceProvider, (_, _) {});

        final controllerB = containerB.read(selectionProvider.notifier);
        await _waitUntil(
          () async => controllerB.isWorkspaceMemoryHydrated,
          description: 'hydration after restart',
        );

        // The user taps back into the Novel workspace; the remembered novel
        // must be restored instead of the first catalog entry.
        controllerB.selectWorkspace(
          projectId: projectId,
          type: AssetType.story,
          availableAssetIds: [story1, story2],
        );
        expect(containerB.read(selectionProvider)?.assetId, story2);
      },
    );
  });
}
