import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/multiverse/presentation/create_universe_wizard_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan wizard create universe', (tester) async {
    await tester.pumpWidget(wrap(const CreateUniverseWizardScreen()));
    expect(find.text('Create Universe'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const CreateUniverseWizardScreen()));
    expect(tester.takeException(), isNull);
  });
}
