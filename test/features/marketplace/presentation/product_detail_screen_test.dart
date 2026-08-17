import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/marketplace/presentation/product_detail_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan detail produk', (tester) async {
    await tester.pumpWidget(wrap(const ProductDetailScreen()));
    expect(find.text('Product'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('Rating'), findsOneWidget);
    expect(find.text('Reviews'), findsOneWidget);
  });

  testWidgets('menampilkan CTA', (tester) async {
    await tester.pumpWidget(wrap(const ProductDetailScreen()));
    expect(find.text('Install'), findsOneWidget);
    expect(find.text('Buy'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const ProductDetailScreen()));
    expect(tester.takeException(), isNull);
  });
}
