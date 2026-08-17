import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/presentation/world_simulation_workspace_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan workspace simulasi dunia', (tester) async {
    await tester.pumpWidget(wrap(const WorldSimulationWorkspaceScreen()));
    expect(find.text('World Simulation'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Population'), findsOneWidget);
    expect(find.text('Economy'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const WorldSimulationWorkspaceScreen()));
    expect(tester.takeException(), isNull);
  });
}
