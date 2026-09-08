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
  testWidgets('dashboard prioritizes the Core novelist journey', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1440, 1200)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_dashboardApp(size: const Size(1440, 1200)));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Your writing desk'), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-content')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('dashboard-content'))).width,
      lessThanOrEqualTo(1280),
    );
    expect(find.text('Welcome back, Guest'), findsOneWidget);
    expect(find.text('Recent Projects'), findsOneWidget);
    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Storage'), findsOneWidget);
    expect(find.text('AI Activity'), findsNothing);
    expect(find.text('Marketplace'), findsNothing);
    expect(find.text('Support Void Scriptor'), findsNothing);
    expect(find.text('Open Studio'), findsNothing);
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
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Welcome back, Guest'), findsOneWidget);
    expect(find.text('Recent Projects'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
