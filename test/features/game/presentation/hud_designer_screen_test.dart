import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/game/presentation/hud_designer_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan 8 elemen HUD', (tester) async {
    await tester.pumpWidget(wrap(const HudDesignerScreen()));
    expect(find.text('HUD Designer'), findsOneWidget);
    expect(find.text('Health'), findsOneWidget);
    expect(find.text('Energy'), findsOneWidget);
    expect(find.text('Ability'), findsOneWidget);
    expect(find.text('Weapon'), findsOneWidget);
    expect(find.text('Minimap'), findsOneWidget);
    expect(find.text('Quest'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const HudDesignerScreen()));
    expect(tester.takeException(), isNull);
  });
}
