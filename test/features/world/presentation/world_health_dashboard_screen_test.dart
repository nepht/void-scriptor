import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/presentation/world_health_dashboard_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan 6 metrik kesehatan dunia', (tester) async {
    await tester.pumpWidget(wrap(const WorldHealthDashboardScreen()));
    expect(find.text('World Health'), findsOneWidget);
    expect(find.text('Population'), findsOneWidget);
    expect(find.text('Economy'), findsOneWidget);
    expect(find.text('Stability'), findsOneWidget);
    expect(find.text('Environment'), findsOneWidget);
    expect(find.text('Conflict'), findsOneWidget);
    expect(find.text('Resources'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const WorldHealthDashboardScreen()));
    expect(tester.takeException(), isNull);
  });
}
