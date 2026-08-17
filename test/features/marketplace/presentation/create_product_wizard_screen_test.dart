import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/marketplace/presentation/create_product_wizard_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan wizard 4 langkah', (tester) async {
    await tester.pumpWidget(wrap(const CreateProductWizardScreen()));
    expect(find.text('Create Product'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
    expect(find.text('Pricing'), findsOneWidget);
    expect(find.text('Files'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
  });

  testWidgets('menampilkan tombol navigasi', (tester) async {
    await tester.pumpWidget(wrap(const CreateProductWizardScreen()));
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const CreateProductWizardScreen()));
    expect(tester.takeException(), isNull);
  });
}
