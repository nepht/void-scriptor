import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/presentation/final_creator_dashboard_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan sidebar & header dashboard', (tester) async {
    await tester.pumpWidget(wrap(const FinalCreatorDashboardScreen()));
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Projects'), findsWidgets);
    expect(find.text('AI Studio'), findsOneWidget);
    expect(find.text('Assets'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('menampilkan 4 tab metrik', (tester) async {
    await tester.pumpWidget(wrap(const FinalCreatorDashboardScreen()));
    expect(find.text('Projects'), findsWidgets);
    expect(find.text('Portfolio'), findsWidgets);
    expect(find.text('Followers'), findsOneWidget);
    expect(find.text('Earnings'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const FinalCreatorDashboardScreen()));
    expect(tester.takeException(), isNull);
  });
}
