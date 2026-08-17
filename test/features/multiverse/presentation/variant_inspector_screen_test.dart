import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/multiverse/presentation/variant_inspector_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan variant inspector', (tester) async {
    await tester.pumpWidget(wrap(const VariantInspectorScreen()));
    expect(find.text('Variant Inspector'), findsOneWidget);
    expect(find.text('Base'), findsOneWidget);
    expect(find.text('Variant'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const VariantInspectorScreen()));
    expect(tester.takeException(), isNull);
  });
}
