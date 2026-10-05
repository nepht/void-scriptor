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

/// Regression for void-scriptor-hunt-20260910b BUG-2 (Referee: REAL BUG,
/// Medium): selection-memory hydration happened once per app lifetime and
/// the persist listener wrote the whole in-memory map (all projects) into
/// the CURRENT project's snapshot file. Opening project B after project A
/// in one app run therefore (a) never loaded B's persisted memory and
/// (b) overwrote B's selection_memory.json with a merged cross-project
/// snapshot missing B's own prior entries — permanent loss of persisted
/// navigation memory plus cross-project pollution.
void main() {
  group('selection memory per-project isolation', () {
    test(
      're-hydrates on project switch and never persists foreign entries',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'void-selmem-perproject-',
        );
        addTearDown(() async {
          try {
            await root.delete(recursive: true);
          } catch (_) {}
        });

        final service = ProjectPackageService(rootDirectory: root);
        final packageA = await service.create(name: 'Projek A');
        final packageB = await service.create(name: 'Projek B');
        final idA = packageA.projectId;
        final idB = packageB.projectId;
        final fileB = File(
          p.join(packageB.cacheDirectory.path, kSelectionMemoryFileName),
        );

        // Pre-seed B's persisted memory so the run can prove the file is
        // loaded on switch and not clobbered by a merged snapshot.
        await persistSelectionMemorySnapshot(fileB, {
          (idB, AssetType.character): 'b-char-remembered',
        });

        final container = ProviderContainer(
          overrides: [
            projectPathsProvider.overrideWithValue(
              ProjectPaths(rootDirectory: root),
            ),
          ],
        );
        addTearDown(container.dispose);
        await container.read(projectSessionProvider.future);
        final notifier = container.read(projectSessionProvider.notifier);

        // --- App run, project A first ----------------------------------
        await notifier.openProject(idA);
        container.listen(selectionMemoryPersistenceProvider, (_, _) {});
        container
            .read(selectionProvider.notifier)
            .select(
              SelectionModel(
                assetId: 'a-story-picked',
                assetType: AssetType.story,
                projectId: idA,
              ),
            );
        expect(
          container.read(selectionProvider.notifier).isWorkspaceMemoryHydrated,
          isTrue,
        );

        // --- Switch to project B in the SAME app run --------------------
        await notifier.openProject(idB);
        container.listen(selectionMemoryPersistenceProvider, (_, _) {});

        // BUG-2(a): B's persisted memory must be loaded after the switch.
        final controllerB = container.read(selectionProvider.notifier);
        expect(
          controllerB.isWorkspaceMemoryHydratedForProject(idB),
          isTrue,
          reason: 'opening project B must hydrate B persisted selection memory',
        );
        expect(
          controllerB.workspaceMemorySnapshot()[(idB, AssetType.character)],
          'b-char-remembered',
          reason: 'B remembered entry must survive the project switch',
        );
        // A-phase entries may remain in the keyed in-session map (they are
        // inert: every consumer path keys on (projectId, type) and the
        // persisted snapshot below is project-scoped); the observable
        // contract is that B's FILE never receives foreign entries.

        // BUG-2(a) file guarantee: A's file stays A-only and B's file keeps
        // its own pre-seeded entry across the switch.
        final fileA = File(
          p.join(packageA.cacheDirectory.path, kSelectionMemoryFileName),
        );
        expect(
          loadSelectionMemorySnapshotSync(fileB)[(idB, AssetType.character)],
          'b-char-remembered',
        );
        expect(
          loadSelectionMemorySnapshotSync(fileB)[(idA, AssetType.story)],
          isNull,
        );
        // The A-phase persist must still have captured A's own pick.
        expect(
          loadSelectionMemorySnapshotSync(fileA)[(idA, AssetType.story)],
          'a-story-picked',
        );

        // BUG-2(b): a selection change in B persists ONLY B's entries.
        container
            .read(selectionProvider.notifier)
            .select(
              SelectionModel(
                assetId: 'b-story-picked',
                assetType: AssetType.story,
                projectId: idB,
              ),
            );
        final persistedB = loadSelectionMemorySnapshotSync(fileB);
        expect(persistedB[(idB, AssetType.story)], 'b-story-picked');
        expect(persistedB[(idA, AssetType.story)], isNull);
        // The pre-seeded B entry stays (not wiped by a merged snapshot).
        expect(persistedB[(idB, AssetType.character)], 'b-char-remembered');

        await notifier.closeProject();
      },
    );
  });
}
