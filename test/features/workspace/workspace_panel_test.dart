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
    // The workspace header is a single line by design: the domain description
    // is intentionally not rendered (Choi's decision, 2026-09-26).
    expect(find.text('Manuscript'), findsOneWidget);
    expect(find.text('Planning'), findsOneWidget);
    expect(find.text('Export'), findsNothing);
    await tester.tap(find.byTooltip('Document actions'));
    await tester.pumpAndSettle();
    expect(find.text('Export'), findsOneWidget);
    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();
    expect(containerSection(tester), 'Export');

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

    expect(find.text('Character'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Character Sheet'), findsOneWidget);
    expect(find.text('Expressions Library'), findsOneWidget);
    expect(find.text('AI Assets'), findsOneWidget);
    expect(find.text('Relations'), findsOneWidget);
    expect(find.text('Appearance'), findsNothing);
    expect(find.text('Identity'), findsNothing);
    expect(find.text('Companions & Carry'), findsNothing);
    final visualsTab = find.byKey(const ValueKey('workspace-section-Wardrobe'));
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
      'Wardrobe',
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
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Overview'), findsNothing);
    expect(find.text('Locations'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

String? containerSection(WidgetTester tester) => ProviderScope.containerOf(
  tester.element(find.byType(WorkspacePanel)),
).read(workspaceSectionProvider).activeFor(WorkspaceKind.novel);
