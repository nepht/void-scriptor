// Sprint 145.27 — Core Worldbuilding Reduction (uniform non-Core route
// gating boundary): integrasi RouteCapabilityGuard ke router.
//
// Kontrak: `/publishing` dan `/plugins` adalah route non-Core deferred
// (PUBLIC_PUBLISHING, CONNECTOR_MARKETPLACE). Selama capability-nya belum
// direaktivasi (approval 145.17) dan owning flag masih OFF, navigasi ke
// route tersebut dialihkan ke fallback Core `/dashboard`. Route Core tidak
// pernah dialihkan.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';
import 'package:void_scriptor/app/routing/app_router.dart';
import 'package:void_scriptor/app/void_scriptor_app.dart';
import 'package:void_scriptor/core/publishing/presentation/publishing_panel.dart';
import 'package:void_scriptor/core/plugin/presentation/plugin_manager_screen.dart';

import '../../shared/theme_test_overrides.dart';

Widget _app(GoRouter router) {
  return ProviderScope(
    overrides: themeTestOverrides(),
    child: VoidScriptorApp(routerConfig: router),
  );
}

void main() {
  testWidgets('publishing route redirects to dashboard while deferred', (
    tester,
  ) async {
    final router = createAppRouter(initialLocation: AppRoutes.publishing);
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    expect(find.byType(PublishingPanel), findsNothing);
    expect(find.text('DASHBOARD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('plugins route redirects to dashboard while deferred', (
    tester,
  ) async {
    final router = createAppRouter(initialLocation: AppRoutes.plugins);
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    expect(find.byType(PluginManagerScreen), findsNothing);
    expect(find.text('DASHBOARD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('core route dashboard is never redirected', (tester) async {
    final router = createAppRouter(initialLocation: AppRoutes.dashboard);
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    expect(find.text('DASHBOARD'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
