import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/presentation/donation_dashboard_screen.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  testWidgets('renders donation dashboard sections', (tester) async {
    await tester.pumpWidget(wrap(const DonationDashboardScreen()));

    expect(find.text('DONATION DASHBOARD'), findsOneWidget);
    expect(find.text('Monthly Goal'), findsOneWidget);
    expect(find.text('Top Supporters'), findsOneWidget);
  });

  testWidgets('no overflow at narrow width', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const DonationDashboardScreen()));

    expect(tester.takeException(), isNull);
    expect(find.text('DONATION DASHBOARD'), findsOneWidget);
  });

  testWidgets('no overflow at desktop width', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const DonationDashboardScreen()));

    expect(tester.takeException(), isNull);
    expect(find.text('Top Supporters'), findsOneWidget);
  });
}
