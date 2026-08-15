import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/workspace_layout/domain/workspace_tab.dart';
import 'package:void_scriptor/features/workspace_layout/presentation/workspace_tab_bar.dart';

void main() {
  const tabs = [
    WorkspaceTab(
      id: 'a',
      assetId: 'asset-a',
      assetType: AssetType.character,
      title: 'Qowner',
    ),
    WorkspaceTab(
      id: 'b',
      assetId: 'asset-b',
      assetType: AssetType.weapon,
      title: 'Dagger',
    ),
  ];

  testWidgets('renders one tab per item and highlights active', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkspaceTabBar(
            tabs: tabs,
            activeTabId: 'a',
            onSelect: (_) {},
            onClose: (_) {},
            onCloseOthers: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Qowner'), findsOneWidget);
    expect(find.text('Dagger'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invokes onSelect when a tab is tapped', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkspaceTabBar(
            tabs: tabs,
            activeTabId: 'a',
            onSelect: (id) => selected = id,
            onClose: (_) {},
            onCloseOthers: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Dagger'));
    expect(selected, 'b');
  });

  testWidgets('invokes onClose when a tab close button is tapped', (
    tester,
  ) async {
    String? closed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WorkspaceTabBar(
            tabs: tabs,
            activeTabId: 'a',
            onSelect: (_) {},
            onClose: (id) => closed = id,
            onCloseOthers: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('close-tab-a')));
    expect(closed, 'a');
  });
}
