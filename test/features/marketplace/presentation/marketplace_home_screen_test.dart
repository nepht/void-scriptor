import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/marketplace/presentation/marketplace_home_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan home marketplace final', (tester) async {
    await tester.pumpWidget(wrap(const MarketplaceHomeScreen()));
    expect(find.text('Marketplace'), findsOneWidget);
    expect(find.text('Featured'), findsOneWidget);
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Trending'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const MarketplaceHomeScreen()));
    expect(tester.takeException(), isNull);
  });
}
