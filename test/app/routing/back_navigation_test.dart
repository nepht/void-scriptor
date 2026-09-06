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
  testWidgets('menu top bar membuka fitur dengan tombol back (desktop)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createAppRouter(initialLocation: AppRoutes.workspace);
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsNothing);

    // Buka fitur Assets dari kelompok Optional tools.
    await tester.tap(find.byTooltip('Optional tools'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assets'));
    await tester.pumpAndSettle();

    // Verifikasi lokasi router berubah ke Assets.
    expect(router.state.uri.path, AppRoutes.assets);
    expect(find.byType(BackButton), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Back kembali ke workspace shell.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.workspace);
  });

  testWidgets('push ke fitur menyediakan history untuk back', (tester) async {
    final router = createAppRouter(initialLocation: AppRoutes.dashboard);
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();

    router.push(AppRoutes.assets);
    await tester.pumpAndSettle();

    expect(router.canPop(), isTrue);
    expect(find.byType(BackButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI generator dari top bar memiliki tombol back', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = createAppRouter(initialLocation: AppRoutes.workspace);
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI Studio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Image Generator'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppRoutes.aiImageGenerator);
    expect(find.byType(BackButton), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppRoutes.workspace);
  });
}
