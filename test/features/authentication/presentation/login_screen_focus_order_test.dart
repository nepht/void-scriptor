import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/authentication/presentation/login_screen.dart';

const _expectedLabels = <String>[
  'Theme menu',
  'Email',
  'Password',
  'Show password',
  'Forgot password?',
  'Sign In',
  'Work Offline',
  'Continue as Guest',
  'Create account',
];

Future<List<({String label, Rect rect})>> _stops(WidgetTester tester) async {
  final stops = <({String label, Rect rect})>[];
  final seen = <String>{};
  for (var i = 0; i < _expectedLabels.length + 2; i++) {
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
    stops.add((label: _expectedLabels[stops.length], rect: rect));
  }
  return stops;
}

void main() {
  testWidgets('Login Screen follows measured WCAG 2.4.3 focus order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(onRegister: _noop, onForgotPassword: _noop),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final stops = await _stops(tester);
    expect(stops, hasLength(9));
    expect(stops.map((stop) => stop.label).toList(), _expectedLabels);
    expect(
      stops.every((stop) => stop.rect.width > 0 && stop.rect.height > 0),
      isTrue,
      reason: 'Every focus stop must have a non-zero focus area.',
    );

    expect(stops[0].rect.top, lessThan(stops[1].rect.top));
    expect(stops[0].rect.left, greaterThan(stops[1].rect.left));
    expect(stops[1].rect.top, lessThan(stops[2].rect.top));
    expect(stops[2].rect.top, greaterThan(stops[3].rect.top));
    expect(stops[3].rect.left, greaterThan(stops[2].rect.left));
    for (var i = 4; i < stops.length; i++) {
      expect(
        stops[i - 1].rect.top,
        lessThan(stops[i].rect.top),
        reason: 'Actions must follow the visible top-to-bottom order.',
      );
    }
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Work Offline'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
