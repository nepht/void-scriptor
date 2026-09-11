import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/app/void_app.dart';
import 'package:void_scriptor/core/auth/auth_controller.dart';
import 'package:void_scriptor/core/auth/auth_session.dart';

import '../../shared/theme_test_overrides.dart';

Widget _app() {
  return ProviderScope(
    overrides: themeTestOverrides(),
    child: const VoidScriptorApp(),
  );
}

class _LoggedOutAuthController extends AuthController {
  @override
  Future<AuthSession> build() async => const AuthSession.loggedOut();
}

Widget _loggedOutApp() {
  return ProviderScope(
    overrides: [
      ...themeTestOverrides(),
      authControllerProvider.overrideWith(_LoggedOutAuthController.new),
    ],
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
  testWidgets('brand intro appears before the local dashboard', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.bySemanticsLabel('Void Scriptor logo'), findsOneWidget);
    expect(find.byKey(const Key('startup-byte-mascot')), findsNothing);
    expect(find.text('Welcome back, Offline User'), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back, Offline User'), findsOneWidget);
  });

  testWidgets('first launch opens the local dashboard without login', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await _settleAuth(tester);

    expect(find.text('Welcome back, Offline User'), findsOneWidget);
    expect(find.text('Welcome back'), findsNothing);
  });

  testWidgets('local user opens sign-in explicitly from Account & Cloud', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await _settleAuth(tester);

    await tester.tap(find.byTooltip('Account menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Account & Cloud'));
    await tester.pumpAndSettle();

    expect(find.text('ACCOUNT & CLOUD CENTER'), findsOneWidget);
    await tester.tap(find.text('Sign in or connect account'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('guest auth flow reaches dashboard and logout', (tester) async {
    await tester.pumpWidget(_loggedOutApp());
    await _settleAuth(tester);

    expect(find.text('Welcome back'), findsOneWidget);

    await _tapVisible(tester, find.text('Continue as Guest'));

    expect(find.text('Welcome back, Guest'), findsOneWidget);

    await tester.tap(find.byTooltip('Account menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('offline auth flow reaches dashboard', (tester) async {
    await tester.pumpWidget(_loggedOutApp());
    await _settleAuth(tester);

    await _tapVisible(tester, find.text('Work Offline'));

    expect(find.text('Welcome back, Offline User'), findsOneWidget);
  });

  testWidgets('account login fails closed when backend is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(_loggedOutApp());
    await _settleAuth(tester);

    await tester.enterText(find.byType(TextField).at(0), 'creator@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await _tapVisible(tester, find.text('Sign In'));
    await tester.pump(const Duration(milliseconds: 850));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    // Copy fail-closed berubah oleh refresh login UI interaktif 2026-09-11
    // (login_screen.dart uncommitted sibling): pesan kini inline di form,
    // bukan SnackBar. Kontrak fail-closed tetap: backend tidak tersedia harus
    // menahan pengguna di Login dengan pesan jujur, tidak masuk Dashboard.
    expect(
      find.text(
        'Sign-in could not be completed. Try again or use Guest or Offline mode.',
      ),
      findsOneWidget,
    );
    expect(find.text('Welcome Void Creator'), findsNothing);
  });

  testWidgets('register and forgot password return to login', (tester) async {
    await tester.pumpWidget(_loggedOutApp());
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

    await tester.pumpWidget(_loggedOutApp());
    await _settleAuth(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('register submit reports unavailable backend honestly', (
    tester,
  ) async {
    await tester.pumpWidget(_loggedOutApp());
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

    expect(find.text('Account creation is not connected yet.'), findsOneWidget);
  });

  testWidgets('forgot password reports that no reset was sent', (tester) async {
    await tester.pumpWidget(_loggedOutApp());
    await _settleAuth(tester);
    await _tapVisible(tester, find.text('Forgot password?'));

    await tester.enterText(find.byType(TextField), 'choirudin@example.com');
    await tester.tap(find.text('Send Reset Link'));
    await tester.pump();

    expect(
      find.text('Password reset is not connected; no email was sent.'),
      findsOneWidget,
    );
  });
}
