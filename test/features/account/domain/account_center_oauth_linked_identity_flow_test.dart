import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_oauth_linked_identity_flow.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';
import '../../../canonical_source_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final manifestFile = File(AccountOAuthFlow.manifestPath);

  Map<String, dynamic> readManifest() {
    expect(manifestFile.existsSync(), isTrue);
    return jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  }

  String sha256Of(String path) {
    final file = File(path);
    if (!file.existsSync()) return '';
    return sha256.convert(file.readAsBytesSync()).toString();
  }

  OAuthProviderConfiguration configuration({
    bool nonceRequired = true,
    bool supportsRefresh = true,
  }) => OAuthProviderConfiguration(
    connector: ProviderConnectorEntry.fixture(
      'fixture-identity',
      displayName: 'Fixture Identity',
      category: ProviderConnectorCategory.identity,
      capabilities: const {
        ProviderConnectorCapability.identity,
        ProviderConnectorCapability.health,
      },
      availability: ProviderConnectorAvailability.available,
      authType: ProviderAuthType.oauth2Pkce,
      permissions: const {
        ProviderPermission.accountMetadata,
        ProviderPermission.providerConnection,
      },
    ),
    authorizationEndpoint: Uri.parse(
      'https://identity.example.test/oauth/authorize',
    ),
    redirectUri: Uri.parse('voidscriptor://oauth/callback'),
    scopes: const {'openid', 'profile', 'offline_access'},
    nonceRequired: nonceRequired,
    supportsRefresh: supportsRefresh,
  );

  OAuthScopeConsent consent({bool explicitlyApproved = true}) =>
      OAuthScopeConsent(
        requestedScopes: configuration().scopes,
        grantedScopes: configuration().scopes,
        explicitlyApproved: explicitlyApproved,
      );

  AccountOAuthFlow flowWith(FakeOAuthTokenBroker broker) {
    var cursor = 0;
    return AccountOAuthFlow(
      randomBytes: (length) => List<int>.generate(
        length,
        (_) => (cursor++ % 251) + 1,
        growable: false,
      ),
      clock: () => DateTime.utc(2026, 9, 25, 8),
      broker: broker,
    );
  }

  OAuthTokenResponse responseFor(
    OAuthTokenExchangeRequest request, {
    Set<String>? scopes,
    String refreshToken = 'refresh-initial',
    DateTime? accessTokenExpiresAt,
  }) => OAuthTokenResponse(
    providerId: request.configuration.connector.providerId,
    providerAccountId: 'account-42',
    displayName: 'Fixture User',
    accessToken: 'access-initial',
    refreshToken: refreshToken,
    accessTokenExpiresAt: accessTokenExpiresAt ?? DateTime.utc(2026, 9, 25, 9),
    supportsRefresh: request.configuration.supportsRefresh,
    scopes: scopes ?? request.scopes,
  );

  group('115.11 OAuth & Linked Identity Flow contract', () {
    test('pins the canonical acceptance and immutable source hashes', () {
      if (skipUnlessExternalCanonical(
        "pins the canonical acceptance and immutable source hashes",
      )) {
        return;
      }
      final sprint = File(AccountOAuthFlow.canonicalSprintPath);
      expect(sprint.existsSync(), isTrue);
      final json =
          jsonDecode(sprint.readAsStringSync()) as Map<String, dynamic>;
      final step = (json['steps'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((entry) => entry['id'] == '115.11');

      expect(step['title'], 'OAuth & Linked Identity Flow');
      expect(step['acceptance'], AccountOAuthFlow.canonicalAcceptance);
      expect(
        AccountOAuthFlow.canonicalSprintSha256,
        'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba',
      );

      final manifest = readManifest();
      expect(manifest['canonical_step'], '115.11');
      expect(
        manifest['document_role'],
        'SPRINT_115_OAUTH_LINKED_IDENTITY_FLOW_MANIFEST',
      );
      expect(manifest['acceptance'], AccountOAuthFlow.canonicalAcceptance);
      final sources = manifest['sources'] as Map<String, dynamic>;
      final canonical = sources['canonical_steps'] as Map<String, dynamic>;
      final productSpec = sources['product_spec'] as Map<String, dynamic>;
      final connectorSdk =
          sources['connector_sdk_spec'] as Map<String, dynamic>;
      expect(sha256Of(canonical['path'] as String), canonical['sha256']);
      expect(sha256Of(productSpec['path'] as String), productSpec['sha256']);
      expect(sha256Of(connectorSdk['path'] as String), connectorSdk['sha256']);
    });

    test(
      'manifest keeps live networking, durable secrets, and UI deferred',
      () {
        final manifest = readManifest();
        final deferred = manifest['deferred_scope'] as Map<String, dynamic>;
        final boundary = manifest['evidence_boundary'] as String;

        expect(deferred['secure_token_storage'], '115.12');
        expect(deferred['connected_accounts_ui'], '115.14');
        expect(deferred['quick_connect_ui'], '115.15');
        expect(boundary.toLowerCase(), contains('does not claim'));
        expect(boundary.toLowerCase(), contains('live'));
      },
    );
  });

  group('authorization request and PKCE', () {
    test(
      'builds authorization-code S256 request without exposing verifier',
      () {
        final broker = FakeOAuthTokenBroker(responseFor);
        final flow = flowWith(broker);
        final request = flow.beginAuthorization(
          configuration: configuration(),
          consent: consent(),
        );

        final verifier = _base64Url(
          List<int>.generate(64, (index) => index + 1),
        );
        final challenge = _base64Url(
          sha256.convert(utf8.encode(verifier)).bytes,
        );
        final uri = request.authorizationUri;

        expect(uri.scheme, 'https');
        expect(uri.host, 'identity.example.test');
        expect(uri.queryParameters['response_type'], 'code');
        expect(uri.queryParameters['client_id'], 'fixture-identity');
        expect(
          uri.queryParameters['redirect_uri'],
          'voidscriptor://oauth/callback',
        );
        expect(uri.queryParameters['scope'], 'offline_access openid profile');
        expect(uri.queryParameters['state'], request.state);
        expect(uri.queryParameters['nonce'], isNotEmpty);
        expect(uri.queryParameters['code_challenge'], challenge);
        expect(uri.queryParameters['code_challenge_method'], 'S256');
        expect(request.toJson().containsKey('code_verifier'), isFalse);
        expect(request.toString(), isNot(contains(verifier)));
      },
    );

    test('omits nonce when the provider does not require it', () {
      final request = flowWith(FakeOAuthTokenBroker(responseFor))
          .beginAuthorization(
            configuration: configuration(nonceRequired: false),
            consent: OAuthScopeConsent(
              requestedScopes: configuration().scopes,
              grantedScopes: configuration().scopes,
              explicitlyApproved: true,
            ),
          );

      expect(request.nonce, isNull);
      expect(
        request.authorizationUri.queryParameters.containsKey('nonce'),
        isFalse,
      );
    });

    test('fails closed for unverified or non-PKCE connectors', () {
      final flow = flowWith(FakeOAuthTokenBroker(responseFor));
      final unverified = configuration();
      final unverifiedConnector = ProviderConnectorEntry.fixture(
        'unverified',
        availability: ProviderConnectorAvailability.unverified,
        authType: ProviderAuthType.oauth2Pkce,
      );
      final apiKeyConnector = ProviderConnectorEntry.fixture(
        'api-key',
        availability: ProviderConnectorAvailability.available,
        authType: ProviderAuthType.apiKey,
      );

      expect(
        () => flow.beginAuthorization(
          configuration: OAuthProviderConfiguration(
            connector: unverifiedConnector,
            authorizationEndpoint: unverified.authorizationEndpoint,
            redirectUri: unverified.redirectUri,
            scopes: unverified.scopes,
          ),
          consent: consent(),
        ),
        throwsA(
          isA<OAuthFlowException>().having(
            (error) => error.code,
            'code',
            OAuthFlowErrorCode.connectorUnavailable,
          ),
        ),
      );
      expect(
        () => flow.beginAuthorization(
          configuration: OAuthProviderConfiguration(
            connector: apiKeyConnector,
            authorizationEndpoint: unverified.authorizationEndpoint,
            redirectUri: unverified.redirectUri,
            scopes: unverified.scopes,
          ),
          consent: consent(),
        ),
        throwsA(
          isA<OAuthFlowException>().having(
            (error) => error.code,
            'code',
            OAuthFlowErrorCode.unsupportedAuthType,
          ),
        ),
      );
    });

    test('requires explicit exact scoped consent and safe endpoints', () {
      final flow = flowWith(FakeOAuthTokenBroker(responseFor));
      final config = configuration();

      expect(
        () => flow.beginAuthorization(
          configuration: config,
          consent: OAuthScopeConsent(
            requestedScopes: config.scopes,
            grantedScopes: config.scopes,
            explicitlyApproved: false,
          ),
        ),
        throwsA(
          isA<OAuthFlowException>().having(
            (error) => error.code,
            'code',
            OAuthFlowErrorCode.consentRequired,
          ),
        ),
      );
      expect(
        () => flow.beginAuthorization(
          configuration: config,
          consent: OAuthScopeConsent(
            requestedScopes: config.scopes,
            grantedScopes: const {'openid', 'profile', 'admin'},
            explicitlyApproved: true,
          ),
        ),
        throwsA(
          isA<OAuthFlowException>().having(
            (error) => error.code,
            'code',
            OAuthFlowErrorCode.scopeEscalation,
          ),
        ),
      );
      expect(
        () => OAuthProviderConfiguration(
          connector: config.connector,
          authorizationEndpoint: Uri.parse('http://identity.example.test'),
          redirectUri: config.redirectUri,
          scopes: config.scopes,
        ),
        throwsArgumentError,
      );
      expect(
        () => OAuthProviderConfiguration(
          connector: config.connector,
          authorizationEndpoint: config.authorizationEndpoint,
          redirectUri: Uri.parse('https://callback.example.test/#fragment'),
          scopes: config.scopes,
        ),
        throwsArgumentError,
      );
    });
  });

  group('callback validation and linking', () {
    // All broker-backed completion and revocation paths are asynchronous.
    // Tests below await each operation before asserting the immutable result.
    test(
      'validates state, nonce, code, and links only granted scopes',
      () async {
        final broker = FakeOAuthTokenBroker(responseFor);
        final flow = flowWith(broker);
        final request = flow.beginAuthorization(
          configuration: configuration(),
          consent: consent(),
        );
        final callback = Uri(
          scheme: 'voidscriptor',
          host: 'oauth',
          path: '/callback',
          queryParameters: <String, String>{
            'code': 'authorization-code',
            'state': request.state,
            'nonce': request.nonce!,
          },
        );

        final result = await flow.completeAuthorization(callback: callback);

        expect(result.identity.connectionId, 'fixture-identity/account-42');
        expect(result.identity.providerId, 'fixture-identity');
        expect(result.identity.accountLabel, 'Fixture User');
        expect(result.identity.scopes, consent().grantedScopes);
        expect(result.identity.tokenGeneration, 1);
        expect(result.tokenGrant.generation, 1);
        expect(result.tokenGrant.refreshToken, 'refresh-initial');
        expect(broker.exchangeRequests, hasLength(1));
        expect(broker.exchangeRequests.single.codeVerifier, isNotEmpty);
        expect(result.toString(), isNot(contains('access-initial')));
        expect(result.toString(), isNot(contains('refresh-initial')));
      },
    );

    test('consumes state once and rejects replay or unknown state', () async {
      final flow = flowWith(FakeOAuthTokenBroker(responseFor));
      final request = flow.beginAuthorization(
        configuration: configuration(),
        consent: consent(),
      );
      final callback = Uri(
        scheme: 'voidscriptor',
        host: 'oauth',
        path: '/callback',
        queryParameters: <String, String>{
          'code': 'authorization-code',
          'state': request.state,
          'nonce': request.nonce!,
        },
      );

      await flow.completeAuthorization(callback: callback);
      await expectLater(
        flow.completeAuthorization(callback: callback),
        throwsA(
          isA<OAuthFlowException>().having(
            (error) => error.code,
            'code',
            OAuthFlowErrorCode.stateMismatch,
          ),
        ),
      );
    });

    test(
      'rejects redirect, state, nonce, duplicate, and provider errors',
      () async {
        final flow = flowWith(FakeOAuthTokenBroker(responseFor));
        final request = flow.beginAuthorization(
          configuration: configuration(),
          consent: consent(),
        );

        await expectLater(
          flow.completeAuthorization(
            callback: Uri.parse(
              'https://attacker.example.test/callback?code=x&state=${request.state}&nonce=${request.nonce}',
            ),
          ),
          throwsA(
            isA<OAuthFlowException>().having(
              (error) => error.code,
              'code',
              OAuthFlowErrorCode.callbackMismatch,
            ),
          ),
        );
        await expectLater(
          flow.completeAuthorization(
            callback: _callback(request, state: 'wrong-state'),
          ),
          throwsA(
            isA<OAuthFlowException>().having(
              (error) => error.code,
              'code',
              OAuthFlowErrorCode.stateMismatch,
            ),
          ),
        );
        await expectLater(
          flow.completeAuthorization(
            callback: _callback(request, omitNonce: true),
          ),
          throwsA(
            isA<OAuthFlowException>().having(
              (error) => error.code,
              'code',
              OAuthFlowErrorCode.nonceMissing,
            ),
          ),
        );
        await expectLater(
          flow.completeAuthorization(
            callback: _callback(request, nonce: 'wrong-nonce'),
          ),
          throwsA(
            isA<OAuthFlowException>().having(
              (error) => error.code,
              'code',
              OAuthFlowErrorCode.nonceMismatch,
            ),
          ),
        );

        final duplicate = Uri(
          scheme: request.redirectUri.scheme,
          host: request.redirectUri.host,
          path: request.redirectUri.path,
          queryParameters: <String, List<String>>{
            'code': const ['one', 'two'],
            'state': [request.state],
            'nonce': [request.nonce!],
          },
        );
        await expectLater(
          flow.completeAuthorization(callback: duplicate),
          throwsA(
            isA<OAuthFlowException>().having(
              (error) => error.code,
              'code',
              OAuthFlowErrorCode.callbackInvalid,
            ),
          ),
        );

        final denied = Uri(
          scheme: request.redirectUri.scheme,
          host: request.redirectUri.host,
          path: request.redirectUri.path,
          queryParameters: <String, String>{
            'error': 'access_denied',
            'error_description': 'secret raw provider detail',
            'state': request.state,
          },
        );
        await expectLater(
          flow.completeAuthorization(callback: denied),
          throwsA(
            isA<OAuthFlowException>().having(
              (error) => error.code,
              'code',
              OAuthFlowErrorCode.authorizationDenied,
            ),
          ),
        );
        expect(
          flow.linkedIdentities,
          isEmpty,
          reason: 'failed callbacks must never create a link',
        );
      },
    );

    test(
      'rejects token scope escalation, missing refresh token, and expiry',
      () async {
        OAuthProviderConfiguration customConfiguration({
          Set<String>? grantedScopes,
          bool supportsRefresh = true,
        }) {
          final config = configuration(supportsRefresh: supportsRefresh);
          return OAuthProviderConfiguration(
            connector: config.connector,
            authorizationEndpoint: config.authorizationEndpoint,
            redirectUri: config.redirectUri,
            scopes: grantedScopes ?? config.scopes,
            nonceRequired: true,
            supportsRefresh: supportsRefresh,
          );
        }

        final providerConfig = customConfiguration();
        final broker = FakeOAuthTokenBroker(
          (request) =>
              responseFor(request, scopes: {...providerConfig.scopes, 'admin'}),
        );
        final flow = flowWith(broker);
        final request = flow.beginAuthorization(
          configuration: providerConfig,
          consent: consent(),
        );

        final response = flow.completeAuthorization(
          callback: _callback(request),
        );
        await expectLater(
          response,
          throwsA(
            isA<OAuthFlowException>().having(
              (error) => error.code,
              'code',
              OAuthFlowErrorCode.scopeEscalation,
            ),
          ),
        );
        expect(flow.linkedIdentities, isEmpty);
      },
    );

    test(
      'refresh token is required when the connector advertises it',
      () async {
        final config = configuration();
        final flow = flowWith(
          FakeOAuthTokenBroker(
            (request) => responseFor(request, refreshToken: ''),
          ),
        );
        final request = flow.beginAuthorization(
          configuration: config,
          consent: OAuthScopeConsent(
            requestedScopes: config.scopes,
            grantedScopes: config.scopes,
            explicitlyApproved: true,
          ),
        );

        await expectLater(
          flow.completeAuthorization(callback: _callback(request)),
          throwsA(
            isA<OAuthFlowException>().having(
              (error) => error.code,
              'code',
              OAuthFlowErrorCode.invalidTokenResponse,
            ),
          ),
        );
      },
    );

    test('expired access token is rejected before linking', () async {
      final flow = flowWith(
        FakeOAuthTokenBroker(
          (request) => responseFor(
            request,
            accessTokenExpiresAt: DateTime.utc(2026, 9, 25, 7, 59),
          ),
        ),
      );
      final request = flow.beginAuthorization(
        configuration: configuration(),
        consent: consent(),
      );

      await expectLater(
        flow.completeAuthorization(callback: _callback(request)),
        throwsA(
          isA<OAuthFlowException>().having(
            (error) => error.code,
            'code',
            OAuthFlowErrorCode.invalidTokenResponse,
          ),
        ),
      );
      expect(flow.linkedIdentities, isEmpty);
    });
  });

  group('token rotation and unlink', () {
    test(
      'rotates refresh token, increments generation, and blocks escalation',
      () async {
        final broker = FakeOAuthTokenBroker(responseFor);
        final flow = flowWith(broker);
        final request = flow.beginAuthorization(
          configuration: configuration(),
          consent: consent(),
        );
        final linked = await flow.completeAuthorization(
          callback: _callback(request),
        );
        broker.refreshResponse = (current) => OAuthTokenResponse(
          providerId: current.grant.providerId,
          providerAccountId: 'account-42',
          displayName: 'Fixture User',
          accessToken: 'access-rotated',
          refreshToken: 'refresh-rotated',
          accessTokenExpiresAt: DateTime.utc(2026, 9, 25, 10),
          scopes: current.grant.scopes,
        );

        final rotated = await flow.rotateTokens(
          currentGrant: linked.tokenGrant,
        );

        expect(rotated.identity.tokenGeneration, 2);
        expect(rotated.tokenGrant.generation, 2);
        expect(rotated.tokenGrant.refreshToken, 'refresh-rotated');
        expect(
          rotated.tokenGrant.toString(),
          isNot(contains('refresh-rotated')),
        );
        await expectLater(
          flow.rotateTokens(currentGrant: linked.tokenGrant),
          throwsA(
            isA<OAuthFlowException>().having(
              (error) => error.code,
              'code',
              OAuthFlowErrorCode.staleTokenGeneration,
            ),
          ),
        );

        broker.refreshResponse = (current) => OAuthTokenResponse(
          providerId: current.grant.providerId,
          providerAccountId: 'account-42',
          displayName: 'Fixture User',
          accessToken: 'access-escalated',
          refreshToken: 'refresh-escalated',
          accessTokenExpiresAt: DateTime.utc(2026, 9, 25, 11),
          scopes: {...current.grant.scopes, 'admin'},
        );
        await expectLater(
          flow.rotateTokens(currentGrant: rotated.tokenGrant),
          throwsA(
            isA<OAuthFlowException>().having(
              (error) => error.code,
              'code',
              OAuthFlowErrorCode.scopeEscalation,
            ),
          ),
        );
      },
    );

    test('requires a genuinely new refresh token on rotation', () async {
      final broker = FakeOAuthTokenBroker(responseFor);
      final flow = flowWith(broker);
      final request = flow.beginAuthorization(
        configuration: configuration(),
        consent: consent(),
      );
      final linked = await flow.completeAuthorization(
        callback: _callback(request),
      );
      broker.refreshResponse = (current) => OAuthTokenResponse(
        providerId: current.grant.providerId,
        providerAccountId: 'account-42',
        displayName: 'Fixture User',
        accessToken: 'access-reused',
        refreshToken: current.grant.refreshToken,
        accessTokenExpiresAt: DateTime.utc(2026, 9, 25, 10),
        scopes: current.grant.scopes,
      );

      await expectLater(
        flow.rotateTokens(currentGrant: linked.tokenGrant),
        throwsA(
          isA<OAuthFlowException>().having(
            (error) => error.code,
            'code',
            OAuthFlowErrorCode.refreshTokenNotRotated,
          ),
        ),
      );
    });

    test(
      'unlink is explicit, revokes remotely, and preserves link on failure',
      () async {
        final broker = FakeOAuthTokenBroker(responseFor);
        final flow = flowWith(broker);
        final request = flow.beginAuthorization(
          configuration: configuration(),
          consent: consent(),
        );
        final linked = await flow.completeAuthorization(
          callback: _callback(request),
        );

        expect(
          await flow.unlink(
            grant: linked.tokenGrant,
            decision: OAuthUnlinkDecision.keepLinked,
          ),
          isFalse,
        );
        expect(broker.revokedGrants, isEmpty);
        expect(flow.linkedIdentities, hasLength(1));

        broker.failRevocation = true;
        await expectLater(
          flow.unlink(
            grant: linked.tokenGrant,
            decision: OAuthUnlinkDecision.unlink,
          ),
          throwsA(
            isA<OAuthFlowException>().having(
              (error) => error.code,
              'code',
              OAuthFlowErrorCode.revocationFailed,
            ),
          ),
        );
        expect(flow.linkedIdentities, hasLength(1));

        broker.failRevocation = false;
        expect(
          await flow.unlink(
            grant: linked.tokenGrant,
            decision: OAuthUnlinkDecision.unlink,
          ),
          isTrue,
        );
        expect(
          broker.revokedGrants.single.connectionId,
          linked.identity.connectionId,
        );
        expect(flow.linkedIdentities, isEmpty);
      },
    );
  });
}

Uri _callback(
  OAuthAuthorizationRequest request, {
  String? state,
  String? nonce,
  bool omitNonce = false,
}) => Uri(
  scheme: request.redirectUri.scheme,
  host: request.redirectUri.host,
  path: request.redirectUri.path,
  queryParameters: <String, String>{
    'code': 'authorization-code',
    'state': state ?? request.state,
    if (!omitNonce && (nonce != null || request.nonce != null))
      'nonce': nonce ?? request.nonce!,
  },
);

String _base64Url(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

typedef OAuthTokenResponder =
    OAuthTokenResponse Function(OAuthTokenExchangeRequest request);

class FakeOAuthTokenBroker implements OAuthTokenBroker {
  FakeOAuthTokenBroker(this.exchangeResponder);

  final OAuthTokenResponder exchangeResponder;
  final List<OAuthTokenExchangeRequest> exchangeRequests =
      <OAuthTokenExchangeRequest>[];
  final List<OAuthTokenGrant> revokedGrants = <OAuthTokenGrant>[];
  OAuthTokenRefreshResponder? refreshResponse;
  bool failRevocation = false;

  @override
  Future<OAuthTokenResponse> exchange(OAuthTokenExchangeRequest request) async {
    exchangeRequests.add(request);
    return exchangeResponder(request);
  }

  @override
  Future<OAuthTokenResponse> refresh(OAuthTokenRefreshRequest request) async {
    final responder = refreshResponse;
    if (responder == null) {
      throw StateError('refresh response not configured');
    }
    return responder(request);
  }

  @override
  Future<void> revoke(OAuthTokenGrant grant) async {
    if (failRevocation) throw StateError('fixture revoke failure');
    revokedGrants.add(grant);
  }
}

typedef OAuthTokenRefreshResponder =
    OAuthTokenResponse Function(OAuthTokenRefreshRequest request);
