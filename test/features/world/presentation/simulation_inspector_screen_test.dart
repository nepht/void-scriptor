import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/presentation/simulation_inspector_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan inspector simulasi', (tester) async {
    await tester.pumpWidget(wrap(const SimulationInspectorScreen()));
    expect(find.text('Neo Megacity'), findsOneWidget);
    expect(find.text('Population'), findsOneWidget);
    expect(find.text('Weather'), findsOneWidget);
    expect(find.text('Threat'), findsOneWidget);
    expect(find.text('Active Events'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const SimulationInspectorScreen()));
    expect(tester.takeException(), isNull);
  });
}
