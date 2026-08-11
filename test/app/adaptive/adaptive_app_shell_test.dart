import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/adaptive/adaptive_app_shell.dart';

void main() {
  testWidgets('compact memakai app bar dan bottom navigation', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: AdaptiveAppShell()));

    expect(find.byKey(const Key('compact-app-bar')), findsOneWidget);
    expect(find.byKey(const Key('compact-bottom-navigation')), findsOneWidget);
    expect(find.byKey(const Key('desktop-explorer')), findsNothing);
    expect(find.byKey(const Key('desktop-inspector')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('medium memakai navigation rail tanpa inspector permanen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: AdaptiveAppShell()));

    expect(find.byKey(const Key('medium-navigation-rail')), findsOneWidget);
    expect(find.byKey(const Key('desktop-explorer')), findsNothing);
    expect(find.byKey(const Key('desktop-inspector')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'expanded memakai top bar explorer workspace inspector status bar',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: AdaptiveAppShell()));

      expect(find.byKey(const Key('desktop-top-bar')), findsOneWidget);
      expect(find.byKey(const Key('desktop-explorer')), findsOneWidget);
      expect(find.byKey(const Key('adaptive-workspace')), findsOneWidget);
      expect(find.byKey(const Key('desktop-inspector')), findsOneWidget);
      expect(find.byKey(const Key('desktop-status-bar')), findsOneWidget);
      expect(find.byKey(const Key('compact-bottom-navigation')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
