import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/asset_type.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/features/explorer/presentation/explorer_panel.dart';
import 'package:void_scriptor/features/explorer/presentation/explorer_story_group.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

/// Regression for void-scriptor-hunt-run171 BUG-13 (Referee: REAL BUG, Low):
/// `explorerAssetFocusProvider` was a bare global `AssetType?` written by
/// `focusExplorerAsset` and watched raw by the Explorer body
/// (`focused: focusedType == AssetType.story`). It is never cleared and never
/// project-guarded: after focusing Novel in project A, opening project B in
/// the same app run renders B's StoryGroup highlighted without any focus in B.
/// The sibling contract `worldbuildingSectionIntentProvider` stores
/// `(projectId, section)` and its consumer guards on the active session
/// (workspace_resolver.dart) — the established repo pattern for typed intent.
///
/// RED asserts the observable mechanism at the real consumer: B's StoryGroup
/// must not carry `focused: true`. Positive control: focusing in B itself
/// still highlights.
void main() {
  testWidgets(
    'stale explorer focus from project A must not highlight StoryGroup in project B',
    (tester) async {
      final root = await tester.runAsync(
        () => Directory.systemTemp.createTemp('void-focus-bug13-'),
      );
      final paths = ProjectPaths(rootDirectory: root!);
      final packages = await tester.runAsync(() async {
        final service = ProjectPackageService(rootDirectory: root);
        final a = await service.create(name: 'Fokus A');
        final b = await service.create(name: 'Fokus B');
        return (a.projectId, b.projectId);
      });
      final (idA, idB) = packages!;

      final container = ProviderContainer(
        overrides: [projectPathsProvider.overrideWithValue(paths)],
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.runAsync(() async {
          try {
            await container
                .read(projectSessionProvider.notifier)
                .closeProject();
          } catch (_) {}
          container.dispose();
          if (root.existsSync()) await root.delete(recursive: true);
        });
      });

      await tester.runAsync(
        () => container.read(projectSessionProvider.notifier).openProject(idA),
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Row(
                children: [
                  const ExplorerPanel(),
                  Consumer(
                    builder: (context, ref, _) => TextButton(
                      key: const ValueKey('bug13-focus-story'),
                      onPressed: () => focusExplorerAsset(ref, AssetType.story),
                      child: const Text('FOCUS_STORY'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // --- Focus Novel in A: expected highlight in A ---------------------
      await tester.tap(find.byKey(const ValueKey('bug13-focus-story')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<StoryGroup>(find.byType(StoryGroup)).focused,
        isTrue,
        reason: 'sanity: explicit focus in the active project must highlight',
      );

      // --- Switch to project B in the SAME app run -----------------------
      await tester.runAsync(() async {
        final notifier = container.read(projectSessionProvider.notifier);
        await notifier.closeProject();
        await notifier.openProject(idB);
      });
      await tester.pumpAndSettle();

      // BUG-13: the stale A focus must not leak into B's explorer.
      expect(
        tester.widget<StoryGroup>(find.byType(StoryGroup)).focused,
        isFalse,
        reason:
            'focus typed in project A must not highlight project B groups '
            '(hunt-run171 BUG-13)',
      );

      // Positive control: focusing in B still highlights B.
      await tester.tap(find.byKey(const ValueKey('bug13-focus-story')));
      await tester.pumpAndSettle();
      expect(
        tester.widget<StoryGroup>(find.byType(StoryGroup)).focused,
        isTrue,
        reason: 'guard must not disable focus in the active project',
      );
    },
  );
}
