import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/domain/asset_type.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_panel.dart';
import 'package:void_scriptor/features/workspace/application/workspace_section_controller.dart';

void main() {
  testWidgets('workspace chrome follows the selected work domain', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: WorkspacePanel())),
      ),
    );
    await tester.pump();

    expect(find.text('Novel Workspace'), findsOneWidget);
    expect(
      find.text('Manuscript, chapters, scenes, and export'),
      findsOneWidget,
    );
    expect(find.text('Manuscript'), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(WorkspacePanel)),
    );
    await tester.tap(
      find.byKey(const ValueKey('workspace-section-Manuscript')),
    );
    await tester.pump();
    expect(
      container.read(workspaceSectionProvider).activeFor(WorkspaceKind.novel),
      'Manuscript',
    );
    container
        .read(selectionProvider.notifier)
        .select(
          const SelectionModel(
            assetId: 'character-1',
            assetType: AssetType.character,
            projectId: 'project-1',
          ),
        );
    await tester.pump();

    expect(find.text('Character Workspace'), findsOneWidget);
    expect(
      find.text('Identity, voice, relationships, and references'),
      findsOneWidget,
    );
    expect(find.text('Relationships'), findsOneWidget);
    expect(find.text('Appearance & Gear'), findsOneWidget);
    expect(find.text('Companions & Carry'), findsOneWidget);
    final visualsTab = find.byKey(
      const ValueKey('workspace-section-Appearance & Gear'),
    );
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(-220, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(visualsTab);
    await tester.pump();
    expect(
      container
          .read(workspaceSectionProvider)
          .activeFor(WorkspaceKind.character),
      'Appearance & Gear',
    );

    container
        .read(selectionProvider.notifier)
        .select(
          const SelectionModel(
            assetId: 'environment-1',
            assetType: AssetType.environment,
            projectId: 'project-1',
          ),
        );
    await tester.pump();

    expect(find.text('Worldbuilding Workspace'), findsOneWidget);
    expect(
      find.text('Locations, factions, timeline, and lore'),
      findsOneWidget,
    );
    expect(find.text('Locations'), findsOneWidget);
    expect(find.text('Factions'), findsOneWidget);
    expect(find.text('Relationships'), findsOneWidget);
    expect(find.text('Lore Notes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
