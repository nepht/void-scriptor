import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/presentation/creator_dashboard_screen.dart';

void main() {
  testWidgets('CreatorDashboardScreen renders dashboard sections', (
    tester,
  ) async {
    // RED: This will fail because screen doesn't exist yet
    await tester.pumpWidget(const MaterialApp(home: CreatorDashboardScreen()));
    expect(find.text('CREATOR DASHBOARD'), findsOneWidget);
    expect(find.text('Active Projects'), findsOneWidget);
    expect(find.text('Portfolio Views'), findsOneWidget);
  });
}
