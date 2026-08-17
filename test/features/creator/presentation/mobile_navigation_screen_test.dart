import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/presentation/mobile_navigation_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan bottom navigation 5 item', (tester) async {
    await tester.pumpWidget(wrap(const MobileNavigationScreen()));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });

  testWidgets('menampilkan label navigasi', (tester) async {
    await tester.pumpWidget(wrap(const MobileNavigationScreen()));
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Projects'), findsWidgets);
    expect(find.text('Create'), findsWidgets);
    expect(find.text('AI'), findsWidgets);
    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const MobileNavigationScreen()));
    expect(tester.takeException(), isNull);
  });
}
