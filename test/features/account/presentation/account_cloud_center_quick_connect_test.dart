import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_cloud_snapshot.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';
import 'package:void_scriptor/features/account/presentation/account_cloud_center_screen.dart';

void main() {
  test('quick connect evidence pins the canonical acceptance contract', () {
    final sprint =
        jsonDecode(
              File(
                ProviderConnectorManifest.canonicalSprintPath,
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    final step = (sprint['steps'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .firstWhere((entry) => entry['id'] == '115.15');
    final evidence =
        jsonDecode(
              File(
                'docs/planning/v1.2/sprint_115_quick_connect_panel.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;

    expect(evidence['canonical_step'], '115.15');
    expect(evidence['title'], step['title']);
    expect(evidence['acceptance'], step['acceptance']);
  });

  testWidgets('quick connect is manifest-driven and fail-closed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AccountCloudCenterScreen(
          snapshot: AccountCloudSnapshot.localOnly(session: null),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('quick-connect-provider-google_drive')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('quick-connect-provider-onedrive')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('quick-connect-provider-dropbox')),
      findsOneWidget,
    );
    expect(find.text('Google Drive'), findsWidgets);
    expect(find.text('Provider unverified'), findsWidgets);
    expect(find.text('Health: Unknown'), findsWidgets);
    expect(find.text('Not available'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('quick-connect-provider-google_drive')),
        matching: find.byType(Image),
      ),
      findsOneWidget,
    );

    final unavailable = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Not available').first,
    );
    expect(unavailable.onPressed, isNull);
  });

  testWidgets('connect action is exposed only for available providers', (
    tester,
  ) async {
    final manifest = ProviderConnectorManifest([
      ProviderConnectorEntry.fixture(
        'available_provider',
        displayName: 'Available Provider',
        category: ProviderConnectorCategory.cloudStorage,
        availability: ProviderConnectorAvailability.available,
      ),
      ProviderConnectorEntry.fixture(
        'unsupported_provider',
        displayName: 'Unsupported Provider',
        category: ProviderConnectorCategory.cloudStorage,
        availability: ProviderConnectorAvailability.unsupportedRegion,
      ),
    ]);
    ProviderConnectorEntry? requested;

    await tester.pumpWidget(
      MaterialApp(
        home: AccountCloudCenterScreen(
          snapshot: AccountCloudSnapshot.localOnly(session: null),
          providerManifest: manifest,
          onConnectProvider: (entry) => requested = entry,
        ),
      ),
    );

    expect(find.text('Ready to connect'), findsOneWidget);
    expect(find.text('Unsupported in this region'), findsOneWidget);
    expect(find.text('Health: Unknown'), findsNWidgets(2));

    final connect = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Connect'),
    );
    final unavailable = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Not available'),
    );
    expect(connect.onPressed, isNotNull);
    expect(unavailable.onPressed, isNull);

    final connectFinder = find.widgetWithText(TextButton, 'Connect');
    await tester.ensureVisible(connectFinder);
    await tester.tap(connectFinder);
    expect(requested?.providerId, 'available_provider');
  });
}
