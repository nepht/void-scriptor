import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/shell/desktop/void_status_bar.dart';

void main() {
  testWidgets('cloud and AI indicators default to inactive', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: VoidStatusBar())),
    );

    expect(find.bySemanticsLabel('Local: Active'), findsOneWidget);
    expect(find.bySemanticsLabel('Cloud: Inactive'), findsOneWidget);
    expect(find.bySemanticsLabel('AI: Inactive'), findsOneWidget);
  });

  testWidgets('connected capabilities can be reported explicitly', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VoidStatusBar(cloudConnected: true, aiConnected: true),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Cloud: Active'), findsOneWidget);
    expect(find.bySemanticsLabel('AI: Active'), findsOneWidget);
  });
}
