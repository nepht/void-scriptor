import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/cinema/presentation/shot_status_dashboard_screen.dart';

void main() {
  Widget wrap(Widget child) => ProviderScope(child: MaterialApp(home: child));

  testWidgets('menampilkan status shot', (tester) async {
    await tester.pumpWidget(wrap(const ShotStatusDashboardScreen()));
    expect(find.text('Total Shots'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('Blocked'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const ShotStatusDashboardScreen()));
    expect(tester.takeException(), isNull);
  });
}
