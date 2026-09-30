import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_creative_tools_connections.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';

void main() {
  // The instant every audit row is measured against, so the expectations below
  // are decided by the mechanism rather than by the day the test ran.
  final fixedNow = DateTime.utc(2026, 1, 1, 12);

  group('AccountCenterCreativeToolsConnections', () {
    test('manifest preserves every canonical 115.29 acceptance item', () {
      final manifest =
          jsonDecode(
                File(
                  'docs/planning/v1.2/sprint_115_creative_tools_connections.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;

      expect(manifest['canonical_step'], '115.29');
      expect(manifest['acceptance'], <String>[
        'manifest_driven',
        'asset_permissions',
        'import_export_scope',
        'disconnect',
        'unavailable_state',
        'attribution',
      ]);
    });

    test('lists only creative connectors from the supplied manifest', () {
      final connections = AccountCenterCreativeToolsConnections(
        manifest: _manifest(),
      );

      expect(connections.connectors.map((item) => item.providerId), [
        'figma',
        'canva',
      ]);
      expect(connections.connectors.map((item) => item.availability), [
        ProviderConnectorAvailability.available,
        ProviderConnectorAvailability.unverified,
      ]);
    });

    test('standard creative connectors remain unavailable until verified', () {
      final connections = AccountCenterCreativeToolsConnections(
        manifest: ProviderConnectorManifest.standard,
      );

      expect(connections.connectors, isNotEmpty);
      expect(
        connections.connectors,
        everyElement(
          isA<CreativeToolConnector>()
              .having((item) => item.isConnectable, 'isConnectable', isFalse)
              .having(
                (item) => item.availability,
                'availability',
                ProviderConnectorAvailability.unverified,
              ),
        ),
      );
    });

    test('records immutable asset rights and import-export scope', () {
      final connections = AccountCenterCreativeToolsConnections(
        manifest: _manifest(),
      );

      final connection = connections.connect(
        providerId: ' FIGMA ',
        connectionId: 'figma/main',
        assetPermissions: const {
          CreativeAssetPermission.owned,
          CreativeAssetPermission.licensed,
        },
        transferScope: CreativeTransferScope.importExport,
        attribution: 'Design system by Studio A — licensed for this project.',
      );

      expect(connection.providerId, 'figma');
      expect(connection.transferScope, CreativeTransferScope.importExport);
      expect(connection.assetPermissions, {
        CreativeAssetPermission.owned,
        CreativeAssetPermission.licensed,
      });
      expect(
        () => connection.assetPermissions.add(
          CreativeAssetPermission.publicDomain,
        ),
        throwsUnsupportedError,
      );
    });

    test('fails closed for unavailable tools and missing attribution', () {
      final connections = AccountCenterCreativeToolsConnections(
        manifest: _manifest(),
      );

      expect(
        () => connections.connect(
          providerId: 'canva',
          connectionId: 'canva/main',
          assetPermissions: const {CreativeAssetPermission.owned},
          transferScope: CreativeTransferScope.importOnly,
        ),
        throwsStateError,
      );
      expect(
        () => connections.connect(
          providerId: 'figma',
          connectionId: 'figma/licensed',
          assetPermissions: const {CreativeAssetPermission.licensed},
          transferScope: CreativeTransferScope.exportOnly,
        ),
        throwsArgumentError,
      );
    });

    test(
      'disconnect requires confirmation and preserves attribution metadata',
      () async {
        var allowed = false;
        final connections = AccountCenterCreativeToolsConnections(
          manifest: _manifest(),
          now: () => fixedNow,
          reauthenticate: () async => allowed,
        );
        connections.connect(
          providerId: 'figma',
          connectionId: 'figma/main',
          assetPermissions: const {CreativeAssetPermission.licensed},
          transferScope: CreativeTransferScope.importOnly,
          attribution: 'Studio A license.',
        );

        expect(
          await connections.disconnect('figma/main', confirmed: false),
          isFalse,
        );
        expect(
          connections.activeConnections.single.attribution,
          'Studio A license.',
        );
        allowed = true;
        expect(
          await connections.disconnect('figma/main', confirmed: true),
          isTrue,
        );
        expect(connections.activeConnections, isEmpty);
      },
    );

    test(
      'ending a creative connection is gated, not decided by a caller flag',
      () async {
        // `disconnect_provider` is one of the product spec's sensitive actions
        // and `reauth_before_sensitive_action` is one of its secret guarantees,
        // so a caller-supplied `confirmed: true` must not be enough on its own
        // to drop an authorized creative connection.
        var allowed = false;
        final connections = AccountCenterCreativeToolsConnections(
          manifest: _manifest(),
          now: () => fixedNow,
          reauthenticate: () async => allowed,
        );
        connections.connect(
          providerId: 'figma',
          connectionId: 'figma/main',
          assetPermissions: const {CreativeAssetPermission.licensed},
          transferScope: CreativeTransferScope.importExport,
          attribution: 'Studio A license.',
        );

        expect(
          await connections.disconnect('figma/main', confirmed: true),
          isFalse,
          reason: 'the gate refused, so the connection must survive',
        );
        expect(connections.activeConnections, hasLength(1));

        allowed = true;
        expect(
          await connections.disconnect('figma/main', confirmed: true),
          isTrue,
        );
        expect(connections.activeConnections, isEmpty);
      },
    );

    test('a caller that supplies no gate cannot end a connection', () async {
      // Fail-closed: no gate supplied means the user was never proven present,
      // which is a refusal rather than consent.
      final connections = AccountCenterCreativeToolsConnections(
        manifest: _manifest(),
      );
      connections.connect(
        providerId: 'figma',
        connectionId: 'figma/main',
        assetPermissions: const {CreativeAssetPermission.owned},
        transferScope: CreativeTransferScope.importOnly,
      );

      expect(
        await connections.disconnect('figma/main', confirmed: true),
        isFalse,
      );
      expect(connections.activeConnections, hasLength(1));
    });

    test(
      'a refused disconnect is audited rather than silently absent',
      () async {
        final connections = AccountCenterCreativeToolsConnections(
          manifest: _manifest(),
          now: () => fixedNow,
          reauthenticate: () async => false,
        );
        connections.connect(
          providerId: 'figma',
          connectionId: 'figma/main',
          assetPermissions: const {CreativeAssetPermission.licensed},
          transferScope: CreativeTransferScope.importOnly,
          attribution: 'Studio A license.',
        );

        // Refused at the gate, and refused before the connection is even
        // resolved: both are attempts worth keeping.
        await connections.disconnect('figma/main', confirmed: true);
        await connections.disconnect('figma/never-connected', confirmed: false);

        expect(connections.audit.map((row) => row.action), <String>[
          'connect',
          'denied_disconnect',
          'denied_disconnect',
        ]);
        expect(connections.audit.map((row) => row.connectionId), <String>[
          'figma/main',
          'figma/main',
          'figma/never-connected',
        ]);
        for (final row in connections.audit) {
          expect(row.timestamp, fixedNow.toUtc());
        }
        // `audit_redaction` is a declared guarantee, so no row may carry the
        // rights or attribution material the connection holds.
        for (final row in connections.audit) {
          final encoded = jsonEncode(row.toJson());
          expect(encoded, isNot(contains('Studio A license')));
          expect(encoded, isNot(contains('licensed')));
          expect(row.toJson().keys, hasLength(4));
        }
      },
    );
  });
}

ProviderConnectorManifest _manifest() => ProviderConnectorManifest([
  ProviderConnectorEntry.fixture(
    'figma',
    category: ProviderConnectorCategory.creative,
    capabilities: const {ProviderConnectorCapability.creative},
    availability: ProviderConnectorAvailability.available,
  ),
  ProviderConnectorEntry.fixture(
    'canva',
    category: ProviderConnectorCategory.creative,
    capabilities: const {ProviderConnectorCapability.creative},
    availability: ProviderConnectorAvailability.unverified,
  ),
  ProviderConnectorEntry.fixture(
    'github',
    category: ProviderConnectorCategory.developer,
    capabilities: const {ProviderConnectorCapability.developer},
    availability: ProviderConnectorAvailability.available,
  ),
]);
