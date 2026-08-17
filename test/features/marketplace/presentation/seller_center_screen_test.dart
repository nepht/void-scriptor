import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/marketplace/presentation/seller_center_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan seller center', (tester) async {
    await tester.pumpWidget(wrap(const SellerCenterScreen()));
    expect(find.text('Seller Center'), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Products'), findsWidgets);
    expect(find.text('Revenue'), findsWidgets);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const SellerCenterScreen()));
    expect(tester.takeException(), isNull);
  });
}
