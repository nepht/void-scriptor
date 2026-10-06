import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:void_scriptor/core/network/http_oauth_token_broker.dart';
import 'package:void_scriptor/features/account/domain/account_center_oauth_linked_identity_flow.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_connector_manifest.dart';

void main() {
  group('HttpOAuthTokenBroker', () {
    late ProviderConnectorEntry dummyConnector;
    late OAuthProviderConfiguration dummyConfig;

    setUp(() {
      dummyConnector = ProviderConnectorEntry.fixture(
        'test_provider',
        authType: ProviderAuthType.oauth2Pkce,
        capabilities: const {
          ProviderConnectorCapability.identity,
          ProviderConnectorCapability.health,
        },
      );
      dummyConfig = OAuthProviderConfiguration(
        connector: dummyConnector,
        authorizationEndpoint: Uri.parse('https://provider.example.com/oauth/authorize'),
        tokenEndpoint: Uri.parse('https://provider.example.com/oauth/token'),
        revocationEndpoint: Uri.parse('https://provider.example.com/oauth/revoke'),
        redirectUri: Uri.parse('http://127.0.0.1:8080/callback'),
        scopes: const {'identity:read'},
      );
    });

    test('exchanges code for tokens using POST and correct parameters', () async {
      final client = MockClient((request) async {
        expect(request.url, dummyConfig.tokenEndpoint);
        expect(request.method, 'POST');
        expect(request.headers['content-type'], 'application/x-www-form-urlencoded');

        final body = request.bodyFields;
        expect(body['grant_type'], 'authorization_code');
        expect(body['client_id'], 'test_provider');
        expect(body['code'], 'valid_auth_code');
        expect(body['code_verifier'], 'pkce_verifier_secret');
        expect(body['redirect_uri'], 'http://127.0.0.1:8080/callback');

        return http.Response(
          jsonEncode({
            'access_token': 'test_access_token_123',
            'refresh_token': 'test_refresh_token_456',
            'expires_in': 3600,
            'sub': 'user_999',
            'name': 'Test User',
            'scope': 'identity:read',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final broker = HttpOAuthTokenBroker(client: client);
      final response = await broker.exchange(
        OAuthTokenExchangeRequest(
          configuration: dummyConfig,
          code: 'valid_auth_code',
          codeVerifier: 'pkce_verifier_secret',
          redirectUri: dummyConfig.redirectUri,
          scopes: const {'identity:read'},
        ),
      );

      expect(response.providerId, 'test_provider');
      expect(response.providerAccountId, 'user_999');
      expect(response.displayName, 'Test User');
      expect(response.accessToken, 'test_access_token_123');
      expect(response.refreshToken, 'test_refresh_token_456');
      expect(response.scopes, contains('identity:read'));
    });

    test('fails closed when token endpoint returns error status', () async {
      final client = MockClient((request) async {
        return http.Response('{"error": "invalid_grant"}', 400);
      });

      final broker = HttpOAuthTokenBroker(client: client);
      expect(
        () => broker.exchange(
          OAuthTokenExchangeRequest(
            configuration: dummyConfig,
            code: 'bad_code',
            codeVerifier: 'pkce_verifier',
            redirectUri: dummyConfig.redirectUri,
            scopes: const {'identity:read'},
          ),
        ),
        throwsA(
          isA<OAuthFlowException>().having(
            (e) => e.code,
            'code',
            OAuthFlowErrorCode.tokenExchangeFailed,
          ),
        ),
      );
    });

    test('fails closed when token endpoint is not configured', () async {
      final noEndpointConfig = OAuthProviderConfiguration(
        connector: dummyConnector,
        authorizationEndpoint: Uri.parse('https://provider.example.com/oauth/authorize'),
        redirectUri: Uri.parse('http://127.0.0.1:8080/callback'),
        scopes: const {'identity:read'},
      );

      final broker = HttpOAuthTokenBroker();
      expect(
        () => broker.exchange(
          OAuthTokenExchangeRequest(
            configuration: noEndpointConfig,
            code: 'code',
            codeVerifier: 'verifier',
            redirectUri: noEndpointConfig.redirectUri,
            scopes: const {'identity:read'},
          ),
        ),
        throwsA(
          isA<OAuthFlowException>().having(
            (e) => e.code,
            'code',
            OAuthFlowErrorCode.tokenExchangeFailed,
          ),
        ),
      );
    });

    test('fails closed on malformed JSON payload', () async {
      final client = MockClient((request) async {
        return http.Response('not-json-content', 200);
      });

      final broker = HttpOAuthTokenBroker(client: client);
      expect(
        () => broker.exchange(
          OAuthTokenExchangeRequest(
            configuration: dummyConfig,
            code: 'code',
            codeVerifier: 'verifier',
            redirectUri: dummyConfig.redirectUri,
            scopes: const {'identity:read'},
          ),
        ),
        throwsA(
          isA<OAuthFlowException>().having(
            (e) => e.code,
            'code',
            OAuthFlowErrorCode.invalidTokenResponse,
          ),
        ),
      );
    });
  });
}
