import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/creator/presentation/donation_screen.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  testWidgets('renders donation header and options', (tester) async {
    await tester.pumpWidget(wrap(const DonationScreen()));

    expect(find.text('DONATIONS'), findsOneWidget);
    expect(find.text('Support the Creator'), findsOneWidget);
    expect(find.text('One-time'), findsOneWidget);
    expect(find.text('Subscription'), findsOneWidget);
  });

  testWidgets('no overflow at narrow width', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const DonationScreen()));

    expect(tester.takeException(), isNull);
    expect(find.text('DONATIONS'), findsOneWidget);
  });

  testWidgets('no overflow at desktop width', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(const DonationScreen()));

    expect(tester.takeException(), isNull);
    expect(find.text('Subscription'), findsOneWidget);
  });
}
