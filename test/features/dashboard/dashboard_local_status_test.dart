import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/core/auth/auth_controller.dart';
import 'package:void_scriptor/core/auth/auth_session.dart';
import 'package:void_scriptor/core/auth/auth_status.dart';
import 'package:void_scriptor/features/dashboard/presentation/dashboard_screen.dart';

/// Sprint 145.23 — Startup Path Simplification.
///
/// The objective requires the Dashboard to "expose clear local-only status".
/// A Guest/Offline local session must be visibly honest about being local-only
/// (no account, no cloud), while an authenticated session must not claim it.
class _GuestAuthController extends AuthController {
  @override
  Future<AuthSession> build() async => const AuthSession.guest();
}

class _OfflineAuthController extends AuthController {
  @override
  Future<AuthSession> build() async => const AuthSession.offline();
}

class _AuthenticatedAuthController extends AuthController {
  @override
  Future<AuthSession> build() async => const AuthSession(
    status: AuthStatus.authenticated,
    userId: 'u-1',
    displayName: 'Choi',
    email: 'choi@example.com',
  );
}

Widget _dashboardApp({
  required AuthController Function() controller,
  Size size = const Size(1440, 1200),
}) {
  return ProviderScope(
    overrides: [authControllerProvider.overrideWith(controller)],
    child: MaterialApp(
      home: const DashboardScreen(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(size: size),
        child: child!,
      ),
    ),
  );
}

void main() {
  testWidgets('guest local session exposes an honest local-only status', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1440, 1200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _dashboardApp(controller: _GuestAuthController.new),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Dashboard'), findsOneWidget);
    expect(
      find.textContaining('Local-only'),
      findsOneWidget,
      reason: 'a Guest session must be visibly local-only',
    );
    expect(
      find.byIcon(Icons.cloud_off),
      findsWidgets,
      reason: 'local-only status must carry an explicit no-cloud icon',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('offline local session exposes the same local-only status', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _dashboardApp(controller: _OfflineAuthController.new),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Local-only'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('authenticated session does not claim local-only status', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1440, 1200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _dashboardApp(controller: _AuthenticatedAuthController.new),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Welcome back, Choi'), findsOneWidget);
    expect(
      find.textContaining('Local-only'),
      findsNothing,
      reason: 'an authenticated session is not local-only and must not lie',
    );
    expect(tester.takeException(), isNull);
  });
}
