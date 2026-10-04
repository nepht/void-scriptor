import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/asset_type.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/core/project_package/project_package_service.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/character/application/create_character_service.dart';
import 'package:void_scriptor/features/creatures/application/create_creature_service.dart';
import 'package:void_scriptor/features/creatures/domain/creature_model.dart';
import 'package:void_scriptor/features/creatures/presentation/creature_workspace_screen.dart';
import 'package:void_scriptor/features/explorer/presentation/explorer_panel.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';

/// Regression for void-scriptor-hunt-run171 BUG-18 (Referee: REAL BUG, Low):
/// `_CreatureGroup` is the only explorer group without `focused`/`onFocused`,
/// so its `ExpansionTile.onExpansionChanged` never fires and the creature
/// branch of `focusExplorerAsset` (the sync-restore added for hunt-20260910
/// BUG-05) is unreachable from the UI. Tapping the Creatures header toggles
/// the tile but never restores the remembered creature selection, never
/// stamps the typed workspace intent, and never highlights the header —
/// a feature-parity gap with StoryGroup/_CharacterGroup/EnvironmentGroup.
///
/// Contract under test (mirroring the other groups):
/// 1. Tapping the Creatures header restores the creature selection through
///    the sync-restore branch (intent typed, CreatureWorkspaceScreen opened)
///    without another explicit pick.
/// 2. The header receives the same focus treatment (explorerAssetFocusProvider
///    stamped for the active project and the focused background tint).
void main() {
  late Directory root;
  late String projectId;
  late ProviderContainer container;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('void-creature-focus-');
    final package = await ProjectPackageService(
      rootDirectory: root,
    ).create(name: 'Creature Focus');
    projectId = package.projectId;
    container = ProviderContainer(
      overrides: [
        projectPathsProvider.overrideWithValue(
          ProjectPaths(rootDirectory: root),
        ),
      ],
    );
    // Real async zone: session open runs here because widget test bodies
    // run under FakeAsync and cannot await real IO.
    await container.read(projectSessionProvider.future);
    await container
        .read(projectSessionProvider.notifier)
        .openProject(projectId);
  });

  tearDown(() async {
    await container.read(projectSessionProvider.notifier).closeProject();
    container.dispose();
    if (root.existsSync()) await root.delete(recursive: true);
  });

  Future<void> pumpShell(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                SizedBox(width: 320, child: ExplorerPanel()),
                Expanded(child: WorkspaceResolver()),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ExpansionTile creatureTile(WidgetTester tester) =>
      tester.widget<ExpansionTile>(
        find.ancestor(
          of: find.text('Creatures & Companions'),
          matching: find.byType(ExpansionTile),
        ),
      );

  testWidgets(
    'while a Character is selected, tapping the Creatures header switches to and restores the remembered creature',
    (tester) async {
      final session = container.read(projectSessionProvider).value!;
      final creatureId = await tester.runAsync(
        () =>
            CreateCreatureService(
              database: session.database,
              paths: ProjectPaths(rootDirectory: root),
            ).create(
              projectId: projectId,
              name: 'Nyx',
              category: CreatureCategory.companion,
            ),
      );
      final characterId = await tester.runAsync(
        () => CreateCharacterService(
          database: session.database,
          paths: ProjectPaths(rootDirectory: root),
        ).create(projectId: projectId, name: 'Kai'),
      );
      expect(creatureId, isNotNull);
      expect(characterId, isNotNull);

      await pumpShell(tester);

      final controller = container.read(selectionProvider.notifier);
      // Remember the creature selection (fills the per-workspace memory)...
      controller.select(
        SelectionModel(
          assetId: creatureId!,
          assetType: AssetType.creature,
          projectId: projectId,
        ),
      );
      // ...then the user works in Character: selection AND intent now point
      // elsewhere, and the catalog-recovery provider stays passive because
      // the selection is non-null. Only focusExplorerAsset(creature) can
      // bring the user back to 'Nyx' — the branch BUG-18 left unreachable.
      controller.select(
        SelectionModel(
          assetId: characterId!,
          assetType: AssetType.character,
          projectId: projectId,
        ),
      );
      await tester.pumpAndSettle();
      expect(container.read(selectionProvider)?.assetId, characterId);

      // BUG-18 RED: tapping the Creatures header must re-enter the creature
      // workspace; before the fix the tap only toggled the tile.
      await tester.tap(find.text('Creatures & Companions'));
      await tester.pumpAndSettle();
      // CreatureWorkspaceProvider loads through real IO; poll for the row.
      await tester.runAsync(() async {
        for (var i = 0; i < 50; i++) {
          if (find.text('Nyx').evaluate().isNotEmpty) return;
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      });
      await tester.pumpAndSettle();

      expect(container.read(workspaceIntentProvider), (
        projectId,
        AssetType.creature,
      ), reason: 'header tap must stamp the typed creature intent (BUG-18)');
      expect(
        container.read(selectionProvider)?.assetId,
        creatureId,
        reason:
            'header tap must restore the creature selection via the '
            'sync-restore branch (BUG-18)',
      );
      expect(find.byType(CreatureWorkspaceScreen), findsOneWidget);
      expect(find.text('Nyx'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('tapping the Creatures header focuses it like the other groups', (
    tester,
  ) async {
    await pumpShell(tester);

    expect(
      creatureTile(tester).backgroundColor,
      isNull,
      reason: 'sanity: idle header carries no focus tint',
    );

    await tester.tap(find.text('Creatures & Companions'));
    await tester.pumpAndSettle();

    expect(container.read(explorerAssetFocusProvider), (
      projectId,
      AssetType.creature,
    ), reason: 'header tap must stamp the project-scoped focus (BUG-18)');
    expect(
      creatureTile(tester).backgroundColor,
      isNotNull,
      reason:
          'focused header must carry the shared focus tint like '
          'Story/Character/Environment groups (BUG-18)',
    );
    expect(tester.takeException(), isNull);
  });
}
