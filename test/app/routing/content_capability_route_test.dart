import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/routing/app_router.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';
import 'package:void_scriptor/app/shell/desktop/void_top_bar.dart';
import 'package:void_scriptor/app/shell/mobile/void_mobile_shell.dart';
import 'package:void_scriptor/app/void_scriptor_app.dart';

void main() {
  testWidgets('content capability route renders the real matrix screen', (
    tester,
  ) async {
    final router = createAppRouter(
      initialLocation: AppRoutes.contentCapabilities,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: VoidScriptorApp(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Content Capability Matrix'), findsOneWidget);
    expect(
      find.textContaining('Status menilai integrasi produk'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop and mobile navigation expose the capability matrix', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final selected = <String>[];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: VoidTopBar(onMenuSelected: selected.add)),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Optional tools'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Module Coverage'));
    expect(selected, ['content-capabilities']);

    tester.view.physicalSize = const Size(800, 844);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: VoidMobileShell())),
    );
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Optional tools'));
    await tester.pumpAndSettle();
    expect(find.text('Module Coverage'), findsOneWidget);
  });
}
