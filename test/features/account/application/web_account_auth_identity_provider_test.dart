import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/auth/auth_status.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/features/account/application/oauth_client_configuration.dart';
import 'package:void_scriptor/features/account/application/web_account_auth_identity_provider.dart';

class _FakeLauncher implements OAuthBrowserLauncher {
  Uri? lastUri;

  @override
  Future<bool> launch(Uri authorizationUri) async {
    lastUri = authorizationUri;
    return true;
  }
}

class _FakeClient extends http.BaseClient {
  _FakeClient(this.handler);

  final Future<http.Response> Function(http.BaseRequest request) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
    );
  }
}

Future<http.Response> _jsonResponse(
  int status,
  Map<String, dynamic> body,
) async => http.Response(
  jsonEncode(body),
  status,
  headers: const {'content-type': 'application/json'},
);

void main() {
  test('opens PKCE provider flow and exchanges one-time callback code', () async {
    final launcher = _FakeLauncher();
    final credentials = MemoryCredentialStore();
    String? exchangeBody;
    final client = _FakeClient((request) async {
      if (request.url.path == '/api/auth/exchange') {
        exchangeBody = await request.finalize().bytesToString();
        return _jsonResponse(200, {
          'ok': true,
          'session_token': 'signed-session-fixture',
          'user': {
            'id': 'usr_fixture',
            'provider': 'google',
            'name': 'Qowner',
            'email': 'qowner@example.com',
          },
        });
      }
      return _jsonResponse(404, {'ok': false});
    });
    final provider = WebAccountAuthIdentityProvider(
      tokenStore: credentials,
      browserLauncher: launcher,
      baseUri: Uri.parse('https://voidscriptor.test'),
      client: client,
    );

    final signIn = provider.signInWithProvider(provider: 'google');
    await Future<void>.delayed(Duration.zero);
    final authorizationUri = launcher.lastUri!;
    expect(authorizationUri.path, '/api/auth/google');
    expect(authorizationUri.queryParameters['client'], 'desktop');
    expect(authorizationUri.queryParameters['code_challenge_method'], 'S256');
    expect(
      authorizationUri.queryParameters['redirect_uri'],
      'vscriptor://oauth/callback',
    );

    final consumed = await provider.completeCallback(
      Uri.parse(
        'vscriptor://oauth/callback?code=one-time-fixture&state=${authorizationUri.queryParameters['state']}',
      ),
    );
    final session = await signIn;

    expect(consumed, isTrue);
    expect(session.status, AuthStatus.authenticated);
    expect(session.userId, 'usr_fixture');
    expect(session.identityProvider, 'google');
    expect(
      await credentials.read('account.session_token'),
      'signed-session-fixture',
    );
    final request = jsonDecode(exchangeBody!) as Map<String, dynamic>;
    expect(request['code'], 'one-time-fixture');
    expect(request['redirect_uri'], 'vscriptor://oauth/callback');
    expect(
      (request['code_verifier'] as String).length,
      greaterThanOrEqualTo(43),
    );
  });

  test(
    'rejects a callback with the wrong state without sending a code',
    () async {
      final launcher = _FakeLauncher();
      final provider = WebAccountAuthIdentityProvider(
        tokenStore: MemoryCredentialStore(),
        browserLauncher: launcher,
        client: _FakeClient((_) async => _jsonResponse(500, {'ok': false})),
        requestTimeout: const Duration(milliseconds: 100),
      );

      final signIn = provider.signInWithProvider(provider: 'github');
      final failure = expectLater(
        signIn,
        throwsA(isA<AuthOAuthStateMismatch>()),
      );
      await Future<void>.delayed(Duration.zero);
      final consumed = await provider.completeCallback(
        Uri.parse('vscriptor://oauth/callback?code=fixture&state=wrong-state'),
      );

      expect(consumed, isTrue);
      await failure;
    },
  );

  test('restores a stored token through the account endpoint', () async {
    final credentials = MemoryCredentialStore();
    await credentials.write(
      key: 'account.session_token',
      value: 'signed-session',
    );
    String? authorization;
    final provider = WebAccountAuthIdentityProvider(
      tokenStore: credentials,
      browserLauncher: _FakeLauncher(),
      client: _FakeClient((request) async {
        authorization = request.headers['authorization'];
        return _jsonResponse(200, {
          'ok': true,
          'user': {
            'id': 'usr_restore',
            'provider': 'github',
            'name': 'Restored Creator',
          },
        });
      }),
    );

    final session = await provider.restoreSession();

    expect(authorization, 'Bearer signed-session');
    expect(session?.status, AuthStatus.authenticated);
    expect(session?.userId, 'usr_restore');
    expect(session?.identityProvider, 'github');
  });
}
