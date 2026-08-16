import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/app/void_app.dart';

import '../../shared/theme_test_overrides.dart';

Widget _app() {
  return ProviderScope(
    overrides: themeTestOverrides(),
    child: const VoidScriptorApp(),
  );
}

Future<void> _settleAuth(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 750));
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('guest auth flow reaches dashboard, studio, and logout', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await _settleAuth(tester);

    expect(find.text('Welcome back'), findsOneWidget);

    await _tapVisible(tester, find.text('Continue as Guest'));

    expect(find.text('Welcome Guest'), findsOneWidget);
    expect(find.text('Open Studio'), findsOneWidget);

    await tester.tap(find.text('Open Studio'));
    await tester.pumpAndSettle();
    expect(find.text('Workspace'), findsOneWidget);

    await tester.tap(find.byTooltip('Logout'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('offline auth flow reaches dashboard', (tester) async {
    await tester.pumpWidget(_app());
    await _settleAuth(tester);

    await _tapVisible(tester, find.text('Work Offline'));

    expect(find.text('Welcome Offline User'), findsOneWidget);
  });

  testWidgets('demo login reaches authenticated dashboard', (tester) async {
    await tester.pumpWidget(_app());
    await _settleAuth(tester);

    await tester.enterText(find.byType(TextField).at(0), 'creator@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await _tapVisible(tester, find.text('Sign In'));
    await tester.pump(const Duration(milliseconds: 850));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Void Creator'), findsOneWidget);
  });

  testWidgets('register and forgot password return to login', (tester) async {
    await tester.pumpWidget(_app());
    await _settleAuth(tester);

    await _tapVisible(tester, find.text('Create account'));
    expect(find.text('Create your account'), findsOneWidget);

    await tester.tap(find.text('Already have an account? Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset password'), findsOneWidget);

    await tester.tap(find.text('Back to sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('login screen fits a narrow portrait viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app());
    await _settleAuth(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('register submit gives local account feedback', (tester) async {
    await tester.pumpWidget(_app());
    await _settleAuth(tester);
    await _tapVisible(tester, find.text('Create account'));

    await tester.enterText(find.byType(TextField).at(0), 'Choirudin');
    await tester.enterText(
      find.byType(TextField).at(1),
      'choirudin@example.com',
    );
    await tester.enterText(find.byType(TextField).at(2), 'password');
    await tester.enterText(find.byType(TextField).at(3), 'password');
    await tester.tap(find.text('Create Account'));
    await tester.pump();

    expect(
      find.text('Account creation is available in local mode.'),
      findsOneWidget,
    );
  });

  testWidgets('forgot password submit gives local reset feedback', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await _settleAuth(tester);
    await _tapVisible(tester, find.text('Forgot password?'));

    await tester.enterText(find.byType(TextField), 'choirudin@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();

    expect(
      find.text('Reset link request recorded in local mode.'),
      findsOneWidget,
    );
  });
}
