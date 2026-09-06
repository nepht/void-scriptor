import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/marketplace/presentation/marketplace_workspace_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan menu utama marketplace', (tester) async {
    await tester.pumpWidget(wrap(const MarketplaceWorkspaceScreen()));
    expect(find.text('Marketplace'), findsWidgets);
    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('AI Agents'), findsOneWidget);
    expect(find.text('Workflows'), findsOneWidget);
    expect(find.text('Prompts'), findsOneWidget);
    expect(find.text('My Library'), findsOneWidget);
  });

  testWidgets('menu marketplace notifies parent when selected', (tester) async {
    String? selected;
    await tester.pumpWidget(
      wrap(
        MarketplaceWorkspaceScreen(onMenuSelected: (value) => selected = value),
      ),
    );

    await tester.tap(find.text('Discover'));
    expect(selected, 'Discover');
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const MarketplaceWorkspaceScreen()));
    expect(tester.takeException(), isNull);
  });
}
