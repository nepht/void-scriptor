import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/platform/presentation/optional_tour_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan optional tour', (tester) async {
    await tester.pumpWidget(wrap(const OptionalTourScreen()));
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Character'), findsOneWidget);
    expect(find.text('AI Studio'), findsOneWidget);
    expect(find.text('Publish'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const OptionalTourScreen()));
    expect(tester.takeException(), isNull);
  });
}
