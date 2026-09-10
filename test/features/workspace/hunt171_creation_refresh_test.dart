import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/explorer/presentation/explorer_panel.dart';
import 'package:void_scriptor/features/project_resilience/application/project_session_manager.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';

/// hunt-run171 BUG-5 + BUG-6 (Referee REAL BUG Medium each):
///
/// BUG-5: onCreateNovel in the ProjectOverview branch selects the new story
/// and invalidates projectAssetsProvider, but storyExplorerProvider is never
/// invalidated, so the created novel stays absent from the Explorer story
/// list until an unrelated action rebuilds the graph. The panel creation
/// path already invalidates it; this path must mirror that (the code comment
/// even cites hunt-run157 BUG-05 — the same class of miss).
///
/// BUG-6: after "Create Faction", the created faction is selected but the
/// resolver's cached _WorldbuildingBodyState lists are never reloaded
/// (_load runs only while _factions == null), so the new faction never
/// appears in the Factions list without a remount.
///
/// Both locks use a real package + real Drift session; every tap that
/// launches real I/O runs inside tester.runAsync (proven pattern,
/// novel_options_refresh_after_story_creation_test.dart).
void main() {
  Future<(Directory, ProjectSession)> seed(WidgetTester tester) async {
    late Directory root;
    late ProjectSession session;
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('hunt171-refresh-');
      final package = await ProjectPackageService(
        rootDirectory: root,
      ).create(name: 'Hunt 171 Refresh');
      session = await ProjectSessionManager().open(package);
    });
    addTearDown(() async {
      await session.close();
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
    return (root, session);
  }

  Widget harness(Directory temp, ProjectSession session) => ProviderScope(
    overrides: [
      projectSessionProvider.overrideWith(() => _FixedSession(session)),
      projectPathsProvider.overrideWithValue(
        ProjectPaths(rootDirectory: Directory('${temp.path}/data')),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: WorkspaceResolver())),
  );

  /// Pumps inside runAsync until [ok] observes the tree (~5s budget).
  Future<void> waitFor(WidgetTester tester, bool Function() ok) async {
    for (var i = 0; i < 50; i++) {
      if (ok()) return;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    fail('condition not observed within timeout');
  }

  testWidgets(
    'BUG-5: novel created from ProjectOverview reaches the explorer story catalog immediately',
    (tester) async {
      final (temp, session) = await seed(tester);
      final projectId = session.manifest.id;
      await tester.pumpWidget(harness(temp, session));
      await tester.pumpAndSettle();

      // Warm the provider the way the real Explorer does: opening the story
      // list caches an empty snapshot BEFORE any creation.
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(WorkspaceResolver)),
      );
      final before = await tester.runAsync(
        () =>
            container.read(storyExplorerProvider(projectId).future)
                as Future<List<Asset>?>,
      );
      expect(before, isEmpty, reason: 'precondition: no stories yet');

      await tester.runAsync(() => tester.tap(find.text('Create Novel')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Void Cube Saga');
      // Proven pattern (novel_options_refresh_after_story_creation_test):
      // the whole real create chain runs inside runAsync; poll until the
      // selection lands, then pump real completions via pumpAndSettle.
      await tester.runAsync(() async {
        await tester.tap(find.widgetWithText(FilledButton, 'Create'));
        for (
          var i = 0;
          i < 100 && container.read(selectionProvider) == null;
          i++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      });
      await tester.pumpAndSettle();
      expect(
        container.read(selectionProvider)?.assetType,
        AssetType.story,
        reason: 'novel creation must complete and select the story',
      );

      // The SAME session's provider must serve the new story without any
      // unrelated invalidation.
      final stories = await tester.runAsync(
        () =>
            container.read(storyExplorerProvider(projectId).future)
                as Future<List<Asset>?>,
      );
      expect(
        stories?.map((asset) => asset.name),
        contains('Void Cube Saga'),
        reason:
            'BUG-5: storyExplorerProvider must be invalidated by onCreateNovel',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'BUG-6: faction created from the worldbuilding body appears in the Factions list immediately',
    (tester) async {
      final (temp, session) = await seed(tester);
      await tester.pumpWidget(harness(temp, session));
      await tester.pumpAndSettle();

      // Seed a typed worldbuilding intent without selection so the resolver
      // mounts WorldbuildingBody (Factions section) instead of ProjectOverview.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(WorkspaceResolver)),
      );
      container.read(workspaceIntentProvider.notifier).state = (
        session.manifest.id,
        AssetType.faction,
      );
      await tester.pumpAndSettle();
      expect(find.byType(WorldbuildingBody), findsOneWidget);
      expect(find.text('Create Faction'), findsOneWidget);

      // Deterministic RED: wait for the INITIAL load to finish (empty-state
      // label proves _factions is already a cached empty list), so the
      // later appearance of the faction can only come from an explicit
      // reload inside _createFaction — not from a still-in-flight first load.
      await waitFor(
        tester,
        () => find
            .text('Belum ada faksi. Buat faksi pertama.')
            .evaluate()
            .isNotEmpty,
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Create Faction'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Guild of Echoes');
      // Dialog plumbing runs on fake-async frames; the real Drift I/O of the
      // create service runs inside runAsync, like the proven refresh test.
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      await waitFor(
        tester,
        () => find.text('Guild of Echoes').evaluate().isNotEmpty,
      );

      // Exact bug signal: the empty-state label is driven by the cached
      // _factions list. It may only disappear if the list itself was
      // reloaded — appearing via the selected-asset detail branch does not
      // count (that path reads the row fresh, the list stays stale).
      expect(
        find.text('Belum ada faksi. Buat faksi pertama.'),
        findsNothing,
        reason: 'BUG-6: _createFaction must reload the Factions list',
      );
      // The refresh did not leave the body in a loading/error limbo.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

class _FixedSession extends ProjectSessionController {
  _FixedSession(this._session);

  final ProjectSession _session;

  @override
  Future<ProjectSession?> build() async => _session;
}
