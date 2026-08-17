import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/release/presentation/revenue_dashboard_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan revenue dashboard', (tester) async {
    await tester.pumpWidget(wrap(const RevenueDashboardScreen()));
    expect(find.text('Revenue'), findsOneWidget);
    expect(find.text('Film'), findsOneWidget);
    expect(find.text('Games'), findsOneWidget);
    expect(find.text('Marketplace'), findsOneWidget);
    expect(find.text('Subscriptions'), findsOneWidget);
    expect(find.text('DLC'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const RevenueDashboardScreen()));
    expect(tester.takeException(), isNull);
  });
}
