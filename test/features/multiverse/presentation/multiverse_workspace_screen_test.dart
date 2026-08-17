import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/multiverse/presentation/multiverse_workspace_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan multiverse workspace', (tester) async {
    await tester.pumpWidget(wrap(const MultiverseWorkspaceScreen()));
    expect(find.text('Multiverse'), findsOneWidget);
    expect(find.text('Universes'), findsWidgets);
    expect(find.text('Timelines'), findsOneWidget);
    expect(find.text('Crossovers'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const MultiverseWorkspaceScreen()));
    expect(tester.takeException(), isNull);
  });
}
