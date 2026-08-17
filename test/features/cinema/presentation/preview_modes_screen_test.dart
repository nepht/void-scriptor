import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/cinema/presentation/preview_modes_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan 5 mode preview', (tester) async {
    await tester.pumpWidget(wrap(const PreviewModesScreen()));
    expect(find.text('Storyboard'), findsOneWidget);
    expect(find.text('Animatic'), findsOneWidget);
    expect(find.text('Low Quality'), findsOneWidget);
    expect(find.text('Real-Time'), findsOneWidget);
    expect(find.text('Final Preview'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const PreviewModesScreen()));
    expect(tester.takeException(), isNull);
  });
}
