import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/multiverse/presentation/portability_wizard_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan portability wizard', (tester) async {
    await tester.pumpWidget(wrap(const PortabilityWizardScreen()));
    expect(find.text('Portability Wizard'), findsOneWidget);
    expect(find.text('Select Assets'), findsOneWidget);
    expect(find.text('Start Port'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const PortabilityWizardScreen()));
    expect(tester.takeException(), isNull);
  });
}
