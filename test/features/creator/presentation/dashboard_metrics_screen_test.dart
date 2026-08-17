import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/presentation/dashboard_metrics_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);

  testWidgets('menampilkan 8 metrik dashboard', (tester) async {
    await tester.pumpWidget(wrap(const DashboardMetricsScreen()));
    expect(find.text('Active Projects'), findsOneWidget);
    expect(find.text('Published Works'), findsOneWidget);
    expect(find.text('Portfolio Views'), findsOneWidget);
    expect(find.text('Followers'), findsOneWidget);
    expect(find.text('Collaborations'), findsOneWidget);
    expect(find.text('Asset Sales'), findsOneWidget);
    expect(find.text('AI Usage'), findsOneWidget);
    expect(find.text('Storage'), findsOneWidget);
  });

  testWidgets('menampilkan nilai metrik', (tester) async {
    await tester.pumpWidget(wrap(const DashboardMetricsScreen()));
    expect(find.text('12'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('tidak overflow di layar sempit', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(wrap(const DashboardMetricsScreen()));
    expect(tester.takeException(), isNull);
  });
}
