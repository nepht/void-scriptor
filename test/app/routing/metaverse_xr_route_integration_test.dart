// Integrasi route XR Studio & Metaverse Studio.
//
// Adaptasi 2026-09-05 (otorisasi rekonsiliasi Choi): kedua route kini
// digate RouteCapabilityGuard sebagai capability demo engine (XR_STUDIO,
// METAVERSE_STUDIO — dibekukan Choi sebagai prasyarat 145.43). Intent
// asli dipertahankan: panel integration tetap teruji render — saat
// capability-nya di-allow — dan gate dialihkan ke dashboard selama
// capability masih deferred.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/routing/app_router.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';
import 'package:void_scriptor/app/void_scriptor_app.dart';

import '../../shared/theme_test_overrides.dart';

Widget _app(GoRouter router) {
  return ProviderScope(
    overrides: themeTestOverrides(),
    child: VoidScriptorApp(routerConfig: router),
  );
}

void main() {
  final routes = <String, ({String title, String capability})>{
    AppRoutes.xrStudio: (title: 'XR Studio', capability: 'XR_STUDIO'),
    AppRoutes.metaverse: (
      title: 'Metaverse Studio',
      capability: 'METAVERSE_STUDIO',
    ),
  };

  for (final entry in routes.entries) {
    testWidgets(
      'route ${entry.key} renders its integration panel when allowed',
      (tester) async {
        final router = createAppRouter(
          initialLocation: entry.key,
          allowedCapabilities: {entry.value.capability},
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(_app(router));
        await tester.pumpAndSettle();

        expect(find.text(entry.value.title), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'route ${entry.key} redirects to dashboard while capability deferred',
      (tester) async {
        final router = createAppRouter(initialLocation: entry.key);
        addTearDown(router.dispose);

        await tester.pumpWidget(_app(router));
        await tester.pumpAndSettle();

        expect(find.text(entry.value.title), findsNothing);
        expect(find.text('DASHBOARD'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
