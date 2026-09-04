import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/story/presentation/story_workspace_screen.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';

void main() {
  testWidgets('workspace resolver shows project overview without selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: WorkspaceResolver())),
    );

    expect(find.byType(ProjectOverview), findsOneWidget);
    expect(
      find.text('Select an asset from Explorer to open its workspace.'),
      findsOneWidget,
    );
  });

  testWidgets('workspace resolver opens story workspace for story selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: WorkspaceResolver())),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(WorkspaceResolver)),
    );
    container
        .read(selectionProvider.notifier)
        .select(
          const SelectionModel(assetId: 'story-1', assetType: AssetType.story),
        );
    await tester.pump();

    expect(find.byType(StoryWorkspaceScreen), findsOneWidget);
    expect(find.text('Story Bible — story-1'), findsOneWidget);
    expect(find.text('STORY STRUCTURE'), findsOneWidget);
    expect(find.text('SCENE EDITOR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'story workspace resolver remains overflow-free on narrow width',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: WorkspaceResolver())),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(WorkspaceResolver)),
      );
      container
          .read(selectionProvider.notifier)
          .select(
            const SelectionModel(
              assetId: 'story-1',
              assetType: AssetType.story,
            ),
          );
      await tester.pump();

      expect(find.byType(StoryWorkspaceScreen), findsOneWidget);
      expect(find.text('Export Markdown'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
