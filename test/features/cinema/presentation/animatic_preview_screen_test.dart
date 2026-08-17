import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/cinema/presentation/animatic_preview_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan animatic preview', (tester) async {
    await tester.pumpWidget(wrap(const AnimaticPreviewScreen()));
    expect(find.text('Pacing'), findsOneWidget);
    expect(find.text('Shot Duration'), findsOneWidget);
    expect(find.text('Dialogue Timing'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const AnimaticPreviewScreen()));
    expect(tester.takeException(), isNull);
  });
}
