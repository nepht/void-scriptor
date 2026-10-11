/// 117.46 — Unit tests for `AccountCloudConnectWiring` and
/// `OAuthProviderEndpoints`.
///
/// Validates:
///  1. Known providers resolve to valid `OAuthProviderConfiguration`.
///  2. Unknown providers return null (fail-closed).
///  3. `onConnectProvider` is a no-op for unverified connectors (defense in
///     depth).
///  4. `onConnectProvider` begins an authorization for certified connectors
///     with known endpoints.
///  5. The wiring layer accepts an injected broker so widget tests remain
///     network-free.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/features/account/application/account_cloud_connect_wiring.dart';
import 'package:void_scriptor/features/account/application/oauth_client_configuration.dart';
import 'package:void_scriptor/features/account/domain/account_center_oauth_linked_identity_flow.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';

/// A broker that records calls but never touches the network.
class _RecordingLauncher implements OAuthBrowserLauncher {
  int calls = 0;

  @override
  Future<bool> launch(Uri authorizationUri) async {
    calls++;
    return true;
  }
}

class _RecordingBroker implements OAuthTokenBroker {
  int exchangeCalls = 0;
  int refreshCalls = 0;
  int revokeCalls = 0;

  @override
  Future<OAuthTokenResponse> exchange(OAuthTokenExchangeRequest request) async {
    exchangeCalls++;
    return OAuthTokenResponse(
      providerId: request.configuration.connector.providerId,
      providerAccountId: 'test-account',
      displayName: 'test-account',
      accessToken: 'ACCESS',
      refreshToken: 'REFRESH',
      accessTokenExpiresAt: DateTime.utc(2099),
      issuedAt: DateTime.utc(2026),
      scopes: const <String>{'test'},
    );
  }

  @override
  Future<OAuthTokenResponse> refresh(OAuthTokenRefreshRequest request) async {
    refreshCalls++;
    return OAuthTokenResponse(
      providerId: request.grant.providerId,
      providerAccountId: 'test-account',
      displayName: 'test-account',
      accessToken: 'ACCESS-2',
      refreshToken: 'REFRESH-2',
      accessTokenExpiresAt: DateTime.utc(2099),
      issuedAt: DateTime.utc(2026),
      scopes: const <String>{'test'},
    );
  }

  @override
  Future<void> revoke(OAuthTokenGrant grant) async {
    revokeCalls++;
  }
}

ProviderConnectorEntry _entry(
  String providerId, {
  ProviderConnectorAvailability availability =
      ProviderConnectorAvailability.unverified,
}) => ProviderConnectorEntry(
  providerId: providerId,
  displayName: providerId,
  category: ProviderConnectorCategory.identity,
  capabilities: const <ProviderConnectorCapability>{
    ProviderConnectorCapability.identity,
    ProviderConnectorCapability.health,
  },
  availability: availability,
  regions: const <ProviderRegion>{ProviderRegion.global},
  connectorVersion: 'test-v1',
  authType: ProviderAuthType.oauth2Pkce,
  permissions: const <ProviderPermission>{ProviderPermission.accountMetadata},
);

void main() {
  group('OAuthProviderEndpoints', () {
    test('resolves known providers', () {
      for (final id in <String>[
        'google',
        'google_drive',
        'onedrive',
        'dropbox',
        'github',
      ]) {
        final entry = _entry(id);
        final config = OAuthProviderEndpoints.resolve(entry);
        expect(config, isNotNull, reason: '$id should resolve');
        expect(config!.connector.providerId, id);
        expect(
          config.authorizationEndpoint.scheme,
          'https',
          reason: '$id authorization endpoint must be HTTPS',
        );
        expect(
          config.redirectUri.scheme,
          'vscriptor',
          reason: '$id redirect URI must use custom scheme',
        );
        expect(config.scopes, isNotEmpty, reason: '$id must have scopes');
      }
    });

    test('returns null for unknown providers (fail-closed)', () {
      final entry = _entry('fictional_cloud');
      expect(OAuthProviderEndpoints.resolve(entry), isNull);
    });

    test('isKnown correctly differentiates', () {
      expect(OAuthProviderEndpoints.isKnown('google'), isTrue);
      expect(OAuthProviderEndpoints.isKnown('google_drive'), isTrue);
      expect(OAuthProviderEndpoints.isKnown('onedrive'), isTrue);
      expect(OAuthProviderEndpoints.isKnown('fictional_cloud'), isFalse);
    });
  });

  group('AccountCloudConnectWiring', () {
    test('accepts injected broker', () {
      final broker = _RecordingBroker();
      final wiring = AccountCloudConnectWiring(broker: broker);
      expect(wiring.flow, isA<AccountOAuthFlow>());
    });

    test('onConnectProvider is no-op for unverified connectors', () {
      final broker = _RecordingBroker();
      final wiring = AccountCloudConnectWiring(broker: broker);
      final entry = _entry('google_drive'); // default: unverified
      expect(entry.isConnectable, isFalse);

      // Should not throw and should not begin any authorization.
      wiring.onConnectProvider(entry);
      expect(wiring.flow.liveAuthorizationCount, 0);
    });

    test(
      'onConnectProvider is no-op for unknown providers even if available',
      () {
        final broker = _RecordingBroker();
        final wiring = AccountCloudConnectWiring(broker: broker);
        final entry = _entry(
          'fictional_cloud',
          availability: ProviderConnectorAvailability.available,
        );

        wiring.onConnectProvider(entry);
        expect(wiring.flow.liveAuthorizationCount, 0);
      },
    );

    test(
      'onConnectProvider begins authorization for certified and known connector',
      () async {
        final broker = _RecordingBroker();
        final launcher = _RecordingLauncher();
        final wiring = AccountCloudConnectWiring(
          broker: broker,
          credentialStore: MemoryCredentialStore(),
          browserLauncher: launcher,
        );
        await wiring.setClientId(
          providerId: 'google_drive',
          clientId: 'test-client',
        );
        final entry = _entry(
          'google_drive',
          availability: ProviderConnectorAvailability.available,
        );
        expect(entry.isConnectable, isTrue);

        wiring.onConnectProvider(entry);
        await Future<void>.delayed(Duration.zero);
        expect(wiring.flow.liveAuthorizationCount, 1);
        expect(launcher.calls, 1);
      },
    );

    test(
      'managed Google Drive client ID starts authorization without vault input',
      () async {
        final launcher = _RecordingLauncher();
        final wiring = AccountCloudConnectWiring(
          credentialStore: MemoryCredentialStore(),
          browserLauncher: launcher,
        );
        final entry = _entry(
          'google_drive',
          availability: ProviderConnectorAvailability.available,
        );

        wiring.onConnectProvider(entry);
        await Future<void>.delayed(Duration.zero);

        expect(wiring.flow.liveAuthorizationCount, 1);
        expect(launcher.calls, 1);
      },
      skip:
          OAuthClientConfigurationStore.managedClientIdFor('google_drive') ==
          null,
    );

    test(
      'multiple connect calls accumulate independent authorizations',
      () async {
        final broker = _RecordingBroker();
        final wiring = AccountCloudConnectWiring(
          broker: broker,
          credentialStore: MemoryCredentialStore(),
          browserLauncher: _RecordingLauncher(),
        );

        for (final id in <String>['google_drive', 'onedrive', 'dropbox']) {
          await wiring.setClientId(providerId: id, clientId: 'test-client-$id');
          final entry = _entry(
            id,
            availability: ProviderConnectorAvailability.available,
          );
          wiring.onConnectProvider(entry);
        }
        await Future<void>.delayed(Duration.zero);
        expect(wiring.flow.liveAuthorizationCount, 3);
      },
    );

    test('default wiring uses HttpOAuthTokenBroker', () {
      // This only verifies construction does not throw — it does NOT hit the
      // network because the `HttpOAuthTokenBroker` is never exercised.
      final wiring = AccountCloudConnectWiring();
      expect(wiring.flow, isA<AccountOAuthFlow>());
    });
  });
}
