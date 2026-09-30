import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_developer_tools_connections.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';

void main() {
  group('AccountCenterDeveloperToolsConnections', () {
    test('manifest preserves every canonical 115.28 acceptance item', () {
      final manifest =
          jsonDecode(
                File(
                  'docs/planning/v1.2/sprint_115_developer_tools_connections.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;

      expect(manifest['canonical_step'], '115.28');
      expect(manifest['acceptance'], <String>[
        'manifest_driven',
        'scopes',
        'repository_access',
        'disconnect',
        'unavailable_state',
        'audit',
      ]);
    });

    test('lists only developer connectors from the supplied manifest', () {
      final connections = AccountCenterDeveloperToolsConnections(
        manifest: _manifest(),
      );

      expect(connections.connectors.map((item) => item.providerId), [
        'github',
        'gitlab',
      ]);
      expect(connections.connectors.map((item) => item.availability), [
        ProviderConnectorAvailability.available,
        ProviderConnectorAvailability.unverified,
      ]);
    });

    test(
      'standard manifest exposes named tools as unavailable until verified',
      () {
        final connections = AccountCenterDeveloperToolsConnections(
          manifest: ProviderConnectorManifest.standard,
        );

        final byId = {
          for (final item in connections.connectors) item.providerId: item,
        };
        expect(
          byId.keys,
          containsAll(['github', 'gitlab', 'bitbucket', 'azure_devops']),
        );
        for (final id in ['github', 'gitlab', 'bitbucket', 'azure_devops']) {
          expect(
            byId[id]!.availability,
            ProviderConnectorAvailability.unverified,
          );
          expect(byId[id]!.isConnectable, isFalse);
        }
      },
    );

    test(
      'records explicit scopes and repository access for available tools',
      () {
        final connections = AccountCenterDeveloperToolsConnections(
          manifest: _manifest(),
        );

        final connected = connections.connect(
          providerId: ' GITHUB ',
          connectionId: 'github/main',
          scopes: const {'repo:read', 'profile:read'},
          repositoryAccess: DeveloperRepositoryAccess.readOnly,
        );

        expect(connected.providerId, 'github');
        expect(connected.scopes, {'profile:read', 'repo:read'});
        expect(connected.repositoryAccess, DeveloperRepositoryAccess.readOnly);
        expect(
          () => connected.scopes.add('repo:write'),
          throwsUnsupportedError,
        );
      },
    );

    test(
      'fails closed for unavailable tools and invalid repository scopes',
      () {
        final connections = AccountCenterDeveloperToolsConnections(
          manifest: _manifest(),
        );

        expect(
          () => connections.connect(
            providerId: 'gitlab',
            connectionId: 'gitlab/main',
            scopes: const {'repo:read'},
            repositoryAccess: DeveloperRepositoryAccess.readOnly,
          ),
          throwsStateError,
        );
        expect(
          () => connections.connect(
            providerId: 'github',
            connectionId: 'github/write',
            scopes: const {'repo:read'},
            repositoryAccess: DeveloperRepositoryAccess.readWrite,
          ),
          throwsArgumentError,
        );
      },
    );

    test(
      'disconnecting a provider is a sensitive action and is gated',
      () async {
        // The product spec lists `disconnect_provider` among the sensitive
        // actions and `reauth_before_sensitive_action` among the secret
        // guarantees, so ending an authorized developer connection must not
        // rest on a caller's boolean alone. The sibling credential manager
        // (115.27) already gates every sensitive action and audits the
        // refusal; 115.28 did neither.
        var reauthenticated = false;
        final connections = AccountCenterDeveloperToolsConnections(
          manifest: _manifest(),
          now: () => DateTime.utc(2026, 9, 26, 3),
          reauthenticate: () async => reauthenticated,
        );
        connections.connect(
          providerId: 'github',
          connectionId: 'github/main',
          scopes: const {'repo:read'},
          repositoryAccess: DeveloperRepositoryAccess.readOnly,
        );

        final refused = await connections.disconnect(
          'github/main',
          confirmed: true,
        );

        expect(refused, isFalse);
        // A refused sensitive action changes nothing and says so in the trail.
        expect(connections.activeConnections, hasLength(1));
        expect(
          connections.audit.map((event) => event.action),
          contains('denied_disconnect'),
        );
        expect(
          connections.audit.map((event) => event.action),
          isNot(contains('disconnect')),
        );

        reauthenticated = true;
        expect(
          await connections.disconnect('github/main', confirmed: true),
          isTrue,
        );
        expect(connections.activeConnections, isEmpty);
        expect(
          connections.audit.map((event) => event.action),
          contains('disconnect'),
        );
      },
    );

    test(
      'disconnect is explicit and audit metadata contains no scopes',
      () async {
        final connections = AccountCenterDeveloperToolsConnections(
          manifest: _manifest(),
          now: () => DateTime.utc(2026, 9, 26, 3),
          reauthenticate: () async => true,
        );
        connections.connect(
          providerId: 'github',
          connectionId: 'github/main',
          scopes: const {'repo:read'},
          repositoryAccess: DeveloperRepositoryAccess.readOnly,
        );

        expect(
          await connections.disconnect('github/main', confirmed: false),
          isFalse,
        );
        expect(connections.activeConnections, hasLength(1));
        expect(
          await connections.disconnect('github/main', confirmed: true),
          isTrue,
        );
        expect(connections.activeConnections, isEmpty);
        expect(connections.audit.map((event) => event.action), [
          'connect',
          'denied_disconnect',
          'disconnect',
        ]);
        expect(
          connections.audit.map((event) => event.timestamp),
          everyElement(DateTime.utc(2026, 9, 26, 3)),
        );
        expect(
          connections.audit.expand((event) => event.toJson().keys),
          isNot(contains('scopes')),
        );
      },
    );
  });
}

ProviderConnectorManifest _manifest() => ProviderConnectorManifest([
  ProviderConnectorEntry.fixture(
    'github',
    category: ProviderConnectorCategory.developer,
    capabilities: const {ProviderConnectorCapability.developer},
    availability: ProviderConnectorAvailability.available,
  ),
  ProviderConnectorEntry.fixture(
    'gitlab',
    category: ProviderConnectorCategory.developer,
    capabilities: const {ProviderConnectorCapability.developer},
    availability: ProviderConnectorAvailability.unverified,
  ),
  ProviderConnectorEntry.fixture(
    'figma',
    category: ProviderConnectorCategory.creative,
    capabilities: const {ProviderConnectorCapability.creative},
    availability: ProviderConnectorAvailability.available,
  ),
]);
