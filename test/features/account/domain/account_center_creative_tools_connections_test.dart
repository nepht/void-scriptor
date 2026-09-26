import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_creative_tools_connections.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';

void main() {
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
      () {
        final connections = AccountCenterCreativeToolsConnections(
          manifest: _manifest(),
        );
        connections.connect(
          providerId: 'figma',
          connectionId: 'figma/main',
          assetPermissions: const {CreativeAssetPermission.licensed},
          transferScope: CreativeTransferScope.importOnly,
          attribution: 'Studio A license.',
        );

        expect(connections.disconnect('figma/main', confirmed: false), isFalse);
        expect(
          connections.activeConnections.single.attribution,
          'Studio A license.',
        );
        expect(connections.disconnect('figma/main', confirmed: true), isTrue);
        expect(connections.activeConnections, isEmpty);
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
