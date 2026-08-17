import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/platform/presentation/about_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan about screen', (tester) async {
    await tester.pumpWidget(wrap(const AboutScreen()));
    expect(find.text('VOID SCRIPTOR'), findsOneWidget);
    expect(find.textContaining('Version'), findsWidgets);
    expect(find.text('Licenses'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const AboutScreen()));
    expect(tester.takeException(), isNull);
  });
}
