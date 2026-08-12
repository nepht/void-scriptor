import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:void_scriptor/core/auth/auth_controller.dart';
import 'package:void_scriptor/core/auth/auth_session.dart';
import 'package:void_scriptor/features/dashboard/presentation/dashboard_screen.dart';

class _DashboardAuthController extends AuthController {
  @override
  Future<AuthSession> build() async => const AuthSession.guest();
}

Widget _dashboardApp({required Size size}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(_DashboardAuthController.new),
    ],
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
  testWidgets('dashboard renders all Sprint 05 modules', (tester) async {
    tester.view
      ..physicalSize = const Size(1440, 1200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_dashboardApp(size: const Size(1440, 1200)));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsNWidgets(2));
    expect(find.text('Welcome back, Guest'), findsOneWidget);
    expect(find.text('Recent Projects'), findsOneWidget);
    expect(find.text('Recent Assets'), findsOneWidget);
    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('AI Activity'), findsOneWidget);
    expect(find.text('Storage'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Marketplace'), findsOneWidget);
    expect(find.text('Support Void Scriptor'), findsOneWidget);
  });

  testWidgets('dashboard keeps modules usable on narrow Android viewport', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_dashboardApp(size: const Size(390, 844)));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back, Guest'), findsOneWidget);
    expect(find.text('Recent Projects'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
