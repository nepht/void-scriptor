import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/release/presentation/publishing_dashboard_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan publishing dashboard', (tester) async {
    await tester.pumpWidget(wrap(const PublishingDashboardScreen()));
    expect(find.text('Publish'), findsOneWidget);
    expect(find.text('Overview'), findsWidgets);
    expect(find.text('New Release'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const PublishingDashboardScreen()));
    expect(tester.takeException(), isNull);
  });
}
