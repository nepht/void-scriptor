import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/adaptive/adaptive_app_shell.dart';

Future<void> _pumpAtWidth(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MaterialApp(home: AdaptiveAppShell()));
}

void main() {
  testWidgets('phone 599 memakai bottom navigation dan satu workspace', (
    tester,
  ) async {
    await _pumpAtWidth(tester, 599);

    expect(find.byKey(const Key('phone-app-bar')), findsOneWidget);
    expect(find.byKey(const Key('phone-bottom-navigation')), findsOneWidget);
    expect(find.byKey(const Key('adaptive-workspace')), findsOneWidget);
    expect(find.byKey(const Key('tablet-navigation-rail')), findsNothing);
    expect(find.byKey(const Key('desktop-sidebar')), findsNothing);

    await tester.tap(find.byKey(const Key('phone-open-inspector')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('phone-inspector-bottom-sheet')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet 600 memakai navigation rail tanpa sidebar desktop', (
    tester,
  ) async {
    await _pumpAtWidth(tester, 600);

    expect(find.byKey(const Key('tablet-navigation-rail')), findsOneWidget);
    expect(find.byKey(const Key('adaptive-workspace')), findsOneWidget);
    expect(find.byKey(const Key('desktop-sidebar')), findsNothing);
    expect(find.byKey(const Key('desktop-inspector')), findsNothing);

    await tester.tap(find.byKey(const Key('tablet-open-inspector')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tablet-inspector-overlay')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet 1023 tetap memakai navigation rail', (tester) async {
    await _pumpAtWidth(tester, 1023);

    expect(find.byKey(const Key('tablet-navigation-rail')), findsOneWidget);
    expect(find.byKey(const Key('desktop-sidebar')), findsNothing);
  });

  testWidgets('compact desktop 1024 memakai sidebar tanpa inspector permanen', (
    tester,
  ) async {
    await _pumpAtWidth(tester, 1024);

    expect(find.byKey(const Key('desktop-top-bar')), findsOneWidget);
    expect(find.byKey(const Key('desktop-sidebar')), findsOneWidget);
    expect(find.byKey(const Key('adaptive-workspace')), findsOneWidget);
    expect(find.byKey(const Key('desktop-inspector')), findsNothing);
    expect(find.byKey(const Key('desktop-status-bar')), findsOneWidget);

    await tester.tap(find.byKey(const Key('desktop-toggle-inspector')));
    await tester.pump();
    expect(find.byKey(const Key('desktop-inspector')), findsOneWidget);

    await tester.tap(find.byKey(const Key('desktop-toggle-inspector')));
    await tester.pump();
    expect(find.byKey(const Key('desktop-inspector')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact desktop 1439 masih tanpa inspector permanen', (
    tester,
  ) async {
    await _pumpAtWidth(tester, 1439);

    expect(find.byKey(const Key('desktop-sidebar')), findsOneWidget);
    expect(find.byKey(const Key('desktop-inspector')), findsNothing);
  });

  testWidgets('desktop 1440 memakai sidebar workspace dan inspector', (
    tester,
  ) async {
    await _pumpAtWidth(tester, 1440);

    expect(find.byKey(const Key('desktop-top-bar')), findsOneWidget);
    expect(find.byKey(const Key('desktop-sidebar')), findsOneWidget);
    expect(find.byKey(const Key('adaptive-workspace')), findsOneWidget);
    expect(find.byKey(const Key('desktop-inspector')), findsOneWidget);
    expect(find.byKey(const Key('desktop-status-bar')), findsOneWidget);
    expect(find.byKey(const Key('phone-bottom-navigation')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
