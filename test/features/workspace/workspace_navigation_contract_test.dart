import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/asset_type.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/character/domain/character_model.dart';
import 'package:void_scriptor/features/character/presentation/character_workspace_controller.dart';
import 'package:void_scriptor/features/character/presentation/character_workspace_screen.dart';
import 'package:void_scriptor/features/character/presentation/widgets/character_header.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_panel.dart';
import 'package:void_scriptor/features/workspace_layout/domain/workspace_tab.dart';
import 'package:void_scriptor/features/workspace_layout/presentation/workspace_tab_bar.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart' as asset;

/// Contract for the consolidated workspace navigation header (PR #17):
/// one 36px header bar carries `Character > [name]` plus the Favorite /
/// History / Delete actions, and the main module tab bar is 36px too.
void main() {
  const character = CharacterModel(
    assetId: 'character-1',
    projectId: 'project-1',
    displayName: 'Qowner',
  );

  List<Override> overrides() => [
    characterWorkspaceProvider(
      'character-1',
    ).overrideWith((ref) async => character),
  ];

  /// Pumps [WorkspacePanel] and selects the character asset.
  Future<void> pumpPanelWithCharacter(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: const MaterialApp(home: Scaffold(body: WorkspacePanel())),
      ),
    );
    await tester.pump();
    ProviderScope.containerOf(tester.element(find.byType(WorkspacePanel)))
        .read(selectionProvider.notifier)
        .select(
          const SelectionModel(
            assetId: 'character-1',
            assetType: AssetType.character,
            projectId: 'project-1',
          ),
        );
    // Character name arrives via an async provider override; the future
    // completes after this frame, so settle it, then rebuild once more.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
  }

  /// Returns the ancestor Container of [text] that is exactly [height] tall.
  Finder tightHeightContainerFor(Finder text, double height) {
    final matches = <Element>[];
    for (final element
        in find
            .ancestor(of: text, matching: find.byType(Container))
            .evaluate()) {
      final widget = element.widget;
      if (widget is! Container) continue;
      final constraints = widget.constraints;
      if (constraints == null) continue;
      if (constraints.hasTightHeight && constraints.maxHeight == height) {
        matches.add(element);
      }
    }
    expect(matches, hasLength(1), reason: 'expected one ${height}px container');
    return find.byElementPredicate(
      (element) => identical(element, matches.first),
    );
  }

  testWidgets('character context renders inside a 36px workspace header', (
    tester,
  ) async {
    await pumpPanelWithCharacter(tester);

    expect(find.text('Character'), findsOneWidget);
    expect(find.text('Qowner'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    final header = tightHeightContainerFor(find.text('Qowner'), 36);
    expect(tester.getSize(header).height, 36);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Favorite, History, and Delete live in that same header', (
    tester,
  ) async {
    await pumpPanelWithCharacter(tester);

    final header = tightHeightContainerFor(find.text('Character'), 36);
    for (final tooltip in ['Favorite', 'History', 'Delete']) {
      expect(
        find.descendant(of: header, matching: find.byTooltip(tooltip)),
        findsOneWidget,
        reason: tooltip,
      );
    }

    // Without an active project session, delete stays honest (disabled).
    final deleteButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byTooltip('Delete'),
        matching: find.byType(IconButton),
      ),
    );
    expect(deleteButton.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('main module section bar is 36px', (tester) async {
    await pumpPanelWithCharacter(tester);

    final sectionsBar = tightHeightContainerFor(find.text('Overview'), 36);
    final barHeight = tester.getSize(sectionsBar).height;
    expect(barHeight, 36);

    // The tab itself fills the bar minus the 1px bottom divider that is part
    // of the shell contract ("Divider antar-area: 1 px" inside the 36px total).
    expect(
      tester
          .getSize(find.byKey(const ValueKey('workspace-section-Overview')))
          .height,
      barHeight - 1,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('workspace tab bar is 36px', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              WorkspaceTabBar(
                tabs: [
                  WorkspaceTab(
                    id: 'a',
                    assetId: 'asset-a',
                    assetType: asset.AssetType.character,
                    title: 'Qowner',
                  ),
                ],
                activeTabId: 'a',
                onSelect: _noop,
                onClose: _noop,
                onCloseOthers: _noop,
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(WorkspaceTabBar)).height, 36);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'character workspace has no separate breadcrumb and no character-sheet tabs',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: overrides(),
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1280,
                height: 900,
                child: CharacterWorkspaceScreen(
                  characterId: 'character-1',
                  activeSection: 'Character Sheet',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // The removed standalone breadcrumb widget must stay gone.
      expect(find.byType(CharacterHeader), findsNothing);
      // Contextual sheet tabs must stay gone (main module tabs own nav now).
      for (final section in [
        'Design Sheet',
        'Turnaround',
        'Silhouette',
        'Portrait',
        'Expressions',
        'Pose',
        'Details',
      ]) {
        expect(
          find.byKey(ValueKey('character-sheet-section-$section')),
          findsNothing,
          reason: section,
        );
      }
      // Content is still delivered without those tabs.
      expect(find.text('MAIN PORTRAIT'), findsWidgets);
      expect(find.text('Primary References'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

void _noop(String _) {}
