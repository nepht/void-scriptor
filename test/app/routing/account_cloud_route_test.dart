import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/app/routing/app_router.dart';
import 'package:void_scriptor/app/routing/app_routes.dart';
import 'package:void_scriptor/app/void_scriptor_app.dart';
import 'package:void_scriptor/features/account/application/account_cloud_connect_wiring.dart';
import 'package:void_scriptor/features/account/application/oauth_client_configuration.dart';

void main() {
  testWidgets('account and cloud center route renders the real screen', (
    tester,
  ) async {
    final router = createAppRouter(initialLocation: AppRoutes.accountCloud);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(child: VoidScriptorApp(routerConfig: router)),
    );
    await tester.pumpAndSettle();

    expect(find.text('ACCOUNT & CLOUD CENTER'), findsOneWidget);
    expect(find.text('ACCOUNT SUMMARY'), findsOneWidget);
    expect(find.text('Connected Accounts'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'managed OAuth builds do not ask for a client ID',
    (tester) async {
      final wiring = AccountCloudConnectWiring();
      final router = createAppRouter(
        initialLocation: AppRoutes.accountCloud,
        oauthWiring: wiring,
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(child: VoidScriptorApp(routerConfig: router)),
      );
      await tester.pumpAndSettle();

      final provider = find.byKey(
        const ValueKey('quick-connect-provider-google_drive'),
      );
      final configure = find.descendant(
        of: provider,
        matching: find.widgetWithText(TextButton, 'Configure'),
      );
      await tester.ensureVisible(configure);
      await tester.tap(configure);
      await tester.pumpAndSettle();

      expect(find.text('Google Drive managed configuration'), findsOneWidget);
      expect(find.text('OAuth client ID'), findsNothing);
    },
    skip: OAuthClientConfigurationStore.managedClientIdFor('google_drive') ==
        null,
  );
}
