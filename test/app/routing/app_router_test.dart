import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';
import 'package:void_scriptor/app/routing/app_router.dart';
import 'package:void_scriptor/app/void_scriptor_app.dart';

import '../../shared/theme_test_overrides.dart';

Widget _app(GoRouter router) {
  return ProviderScope(
    overrides: themeTestOverrides(),
    child: VoidScriptorApp(routerConfig: router),
  );
}

void main() {
  testWidgets('router dimulai dari splash', (tester) async {
    final router = createAppRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    expect(find.text('SPLASH'), findsOneWidget);
  });

  for (final route in AppRoutes.foundationRoutes.entries) {
    testWidgets('route ${route.key} tersedia', (tester) async {
      final router = createAppRouter(initialLocation: route.value);
      addTearDown(router.dispose);

      await tester.pumpWidget(_app(router));
      await tester.pumpAndSettle();

      final expectedLabel = route.value == AppRoutes.workspace
          ? 'Workspace' // Mengubah dari 'VOID SCRIPTOR' menjadi 'Workspace'
          : route.value == AppRoutes.aiStudio
          ? 'Advanced AI Studio'
          : route.value == AppRoutes.collaborationComments
          ? 'Project Comments'
          : route.key;
      expect(find.text(expectedLabel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
