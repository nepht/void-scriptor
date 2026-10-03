import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/authentication/presentation/register_screen.dart';
import 'package:void_scriptor/design_system/widgets/void_button.dart';

const _expectedLabels = <String>[
  'Display name',
  'Email',
  'Password',
  'Confirm password',
  'Create Account',
  'Already have an account? Sign in',
];

Future<List<({String label, Rect rect})>> _stops(WidgetTester tester) async {
  final stops = <({String label, Rect rect})>[];
  final seen = <String>{};
  for (var i = 0; i < 8; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) break;
    final object = context.findRenderObject();
    final rect = object is RenderBox && object.hasSize
        ? object.localToGlobal(Offset.zero) & object.size
        : Rect.zero;
    final key = '${rect.left}|${rect.top}|${rect.width}|${rect.height}';
    if (!seen.add(key)) break;
    stops.add((label: _expectedLabels[i], rect: rect));
  }
  return stops;
}

void main() {
  testWidgets('Register Screen follows the measured WCAG 2.4.3 focus order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: RegisterScreen(onBackToLogin: () {})),
    );
    await tester.pumpAndSettle();

    final stops = await _stops(tester);
    expect(stops, hasLength(6));
    expect(stops.map((stop) => stop.label).toList(), _expectedLabels);
    expect(
      stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
      isTrue,
      reason: 'Every focus stop must have a non-zero focus area.',
    );

    for (var i = 1; i < stops.length; i++) {
      expect(
        stops[i - 1].rect.top,
        lessThan(stops[i].rect.top),
        reason: 'Tab order must follow the visible top-to-bottom order.',
      );
      expect(
        stops[i].rect.left,
        closeTo(stops[0].rect.left, 1),
        reason: 'Form controls share the same left alignment.',
      );
    }

    expect(find.widgetWithText(VoidButton, 'Create Account'), findsOneWidget);
    expect(find.text('Already have an account? Sign in'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
