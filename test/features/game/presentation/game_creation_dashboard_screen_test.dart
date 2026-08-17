import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/game/presentation/game_creation_dashboard_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan game creation dashboard', (tester) async {
    await tester.pumpWidget(wrap(const GameCreationDashboardScreen()));
    expect(find.text('Game'), findsOneWidget);
    expect(find.text('World'), findsOneWidget);
    expect(find.text('Levels'), findsOneWidget);
    expect(find.text('Characters'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Build'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const GameCreationDashboardScreen()));
    expect(tester.takeException(), isNull);
  });
}
