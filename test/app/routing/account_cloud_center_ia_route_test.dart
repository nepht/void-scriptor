/// Sprint 115.3 — route-level information architecture.
///
/// Proves acceptance: global_route, deep_links, back_navigation, and the
/// profile-shortcut wiring that points at the canonical route.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/navigation/app_navigation_registry.dart';
import 'package:void_scriptor/app/routing/app_router.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';
import 'package:void_scriptor/app/void_scriptor_app.dart';

void main() {
  test('account route contract follows the product-spec IA', () {
    expect(AppRoutes.accountCloud, '/account/cloud-center');
    expect(AppRoutes.accountCloudLegacy, '/account-cloud');
    expect(
      AppRoutes.foundationRoutes['ACCOUNT & CLOUD CENTER'],
      '/account/cloud-center',
    );

    final profileShortcut = navigationDestinationForKey('account-cloud');
    expect(profileShortcut.route, '/account/cloud-center');
    expect(profileShortcut.label, 'Account & Cloud');
  });

  testWidgets('canonical deep link opens the requested account tab', (
    tester,
  ) async {
    final router = createAppRouter(
      initialLocation: '${AppRoutes.accountCloud}?tab=api_keys',
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: VoidScriptorApp(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/account/cloud-center');
    expect(router.state.uri.queryParameters['tab'], 'api_keys');
    expect(find.text('Account & Cloud Center / API Keys'), findsOneWidget);
    expect(find.text('DEVELOPER TOOLS'), findsOneWidget);
    // Tab aktif hasil deep link wajib tereveal di strip, bukan off-screen.
    final activeTabRect = tester.getRect(find.text('API Keys'));
    expect(activeTabRect.left, greaterThanOrEqualTo(0));
    expect(activeTabRect.right, lessThanOrEqualTo(800));
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy /account-cloud path redirects to the canonical route', (
    tester,
  ) async {
    final router = createAppRouter(
      initialLocation: '/account-cloud?tab=billing',
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: VoidScriptorApp(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/account/cloud-center');
    expect(router.state.uri.queryParameters['tab'], 'billing');
    expect(find.text('Account & Cloud Center / Billing'), findsOneWidget);
    expect(find.text('PAYMENT METHODS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'tab changes record history so back returns to the previous tab',
    (tester) async {
      final router = createAppRouter(initialLocation: AppRoutes.accountCloud);
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(child: VoidScriptorApp(routerConfig: router)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Account & Cloud Center / Overview'), findsOneWidget);

      // Tab strip overflow di viewport uji 800px; panggil onTap tab langsung
      // (idiom repo untuk tab di luar viewport).
      final billingTab = tester.widget<InkWell>(
        find.ancestor(of: find.text('Billing'), matching: find.byType(InkWell)),
      );
      billingTab.onTap!();
      await tester.pumpAndSettle();

      expect(router.state.uri.queryParameters['tab'], 'billing');
      expect(find.text('Account & Cloud Center / Billing'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/account/cloud-center');
      expect(router.state.uri.queryParameters.containsKey('tab'), isFalse);
      expect(find.text('Account & Cloud Center / Overview'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unknown tab slug falls back to overview without crashing', (
    tester,
  ) async {
    final router = createAppRouter(
      initialLocation: '${AppRoutes.accountCloud}?tab=unknown-slug',
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: VoidScriptorApp(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Account & Cloud Center / Overview'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
