import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../../core/auth/auth_identity_provider.dart';
import '../../../core/auth/auth_session.dart';
import '../../../core/auth/auth_status.dart';
import '../../../core/security/credential_store.dart';
import 'oauth_callback_router.dart';
import 'oauth_client_configuration.dart';

/// Authenticates the native app against the same account service as
/// voidscriptor.com. The browser performs Google/GitHub OAuth; the app only
/// receives a short-lived, one-time authorization code and exchanges it with
/// PKCE for an HMAC-signed session token.
final class WebAccountAuthIdentityProvider
    implements
        AuthIdentityProvider,
        SocialAuthIdentityProvider,
        AuthSessionRestorer {
  WebAccountAuthIdentityProvider({
    required this.tokenStore,
    required this.browserLauncher,
    Uri? baseUri,
    http.Client? client,
    Random? random,
    this.requestTimeout = const Duration(seconds: 20),
  }) : baseUri = baseUri ?? _defaultBaseUri,
       client = client ?? http.Client(),
       random = random ?? Random.secure();

  static final Uri _defaultBaseUri = Uri(
    scheme: 'https',
    host: 'voidscriptor.com',
  );
  static const String callbackScheme = 'vscriptor';
  static const String callbackUri = 'vscriptor://oauth/callback';
  static const String _sessionTokenKey = 'account.session_token';
  static const String _pkceMethod = 'S256';

  final CredentialStore tokenStore;
  final OAuthBrowserLauncher browserLauncher;
  final Uri baseUri;
  final http.Client client;
  final Random random;
  final Duration requestTimeout;
  _PendingSignIn? _pending;
  Timer? _pendingTimeout;

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) {
    throw const AuthIdentityUnavailable();
  }

  @override
  Future<AuthSession> signInWithProvider({required String provider}) async {
    final normalizedProvider = provider.trim().toLowerCase();
    if (normalizedProvider != 'google' && normalizedProvider != 'github') {
      throw const AuthProviderUnavailable();
    }
    if (_pending != null) throw const AuthFlowInProgress();

    final verifier = _randomToken(48);
    final challenge = _pkceChallenge(verifier);
    final state = _randomToken(24);
    final pending = _PendingSignIn(
      provider: normalizedProvider,
      state: state,
      verifier: verifier,
      completer: Completer<AuthSession>(),
    );
    _pending = pending;
    _pendingTimeout = Timer(const Duration(minutes: 5), () {
      if (identical(_pending, pending)) {
        _pending = null;
        pending.completer.completeError(const AuthFlowExpired());
      }
    });

    final authorizationUri = _endpoint('/api/auth/$normalizedProvider').replace(
      queryParameters: <String, String>{
        'client': 'desktop',
        'redirect_uri': callbackUri,
        'state': state,
        'code_challenge': challenge,
        'code_challenge_method': _pkceMethod,
      },
    );
    final launched = await browserLauncher.launch(authorizationUri);
    if (!launched) {
      _clearPending(pending);
      throw const AuthBrowserLaunchFailed();
    }

    try {
      return await pending.completer.future.timeout(requestTimeout * 15);
    } finally {
      _clearPending(pending);
    }
  }

  /// Consumes a native protocol callback. Returns true when this provider had
  /// a pending flow and therefore owns the callback, including a rejected
  /// state/error callback. A callback for another OAuth connector returns
  /// false so the existing cloud-connector flow can handle it.
  Future<bool> completeCallback(Uri uri) async {
    final envelope = OAuthCallbackRouter.parse(uri);
    final pending = _pending;
    if (envelope == null || pending == null) return false;

    if (envelope.state != pending.state) {
      _completeError(pending, const AuthOAuthStateMismatch());
      return true;
    }
    if (!envelope.isAuthorizationSuccess) {
      _completeError(pending, const AuthProviderCancelled());
      return true;
    }

    try {
      final response = await client
          .post(
            _endpoint('/api/auth/exchange'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(<String, String>{
              'code': envelope.code!,
              'code_verifier': pending.verifier,
              'redirect_uri': callbackUri,
            }),
          )
          .timeout(requestTimeout);
      final body = _jsonObject(response.body);
      if (response.statusCode != 200 || body['ok'] != true) {
        throw AuthRemoteRequestFailed(_errorCode(body));
      }
      final token = body['session_token'];
      if (token is! String || token.trim().isEmpty) {
        throw const AuthRemoteRequestFailed('missing_session_token');
      }
      final session = _sessionFromUser(body['user']);
      await tokenStore.write(key: _sessionTokenKey, value: token);
      _completeSuccess(pending, session);
    } on AuthException catch (error, stackTrace) {
      _completeError(pending, error, stackTrace);
    } on Object catch (error, stackTrace) {
      _completeError(
        pending,
        AuthRemoteRequestFailed(_safeNetworkCode(error)),
        stackTrace,
      );
    }
    return true;
  }

  @override
  Future<AuthSession?> restoreSession() async {
    final token = await tokenStore.read(_sessionTokenKey);
    if (token == null || token.trim().isEmpty) return null;
    try {
      final response = await client
          .get(
            _endpoint('/api/account/me'),
            headers: <String, String>{'authorization': 'Bearer $token'},
          )
          .timeout(requestTimeout);
      if (response.statusCode == 401 || response.statusCode == 403) {
        await tokenStore.delete(_sessionTokenKey);
        return null;
      }
      if (response.statusCode != 200) return null;
      final body = _jsonObject(response.body);
      if (body['ok'] != true) return null;
      return _sessionFromUser(body['user']);
    } on Object {
      // A transient outage must not prevent local/offline startup.
      return null;
    }
  }

  @override
  Future<void> logoutRemote() async {
    final token = await tokenStore.read(_sessionTokenKey);
    try {
      if (token != null && token.trim().isNotEmpty) {
        await client
            .post(
              _endpoint('/api/auth/logout'),
              headers: <String, String>{'authorization': 'Bearer $token'},
            )
            .timeout(requestTimeout);
      }
    } on Object {
      // Token is removed locally regardless of remote availability.
    } finally {
      await tokenStore.delete(_sessionTokenKey);
    }
  }

  Uri _endpoint(String path) => baseUri.resolve(path);

  String _randomToken(int length) {
    final bytes = Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _pkceChallenge(String verifier) => base64UrlEncode(
    sha256.convert(utf8.encode(verifier)).bytes,
  ).replaceAll('=', '');

  void _clearPending(_PendingSignIn pending) {
    if (identical(_pending, pending)) _pending = null;
    _pendingTimeout?.cancel();
    _pendingTimeout = null;
  }

  void _completeSuccess(_PendingSignIn pending, AuthSession session) {
    _clearPending(pending);
    if (!pending.completer.isCompleted) pending.completer.complete(session);
  }

  void _completeError(
    _PendingSignIn pending,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    _clearPending(pending);
    if (!pending.completer.isCompleted) {
      pending.completer.completeError(error, stackTrace ?? StackTrace.current);
    }
  }

  AuthSession _sessionFromUser(Object? value) {
    if (value is! Map) throw const AuthRemoteRequestFailed('invalid_user');
    final id = value['id'];
    if (id is! String || id.trim().isEmpty) {
      throw const AuthRemoteRequestFailed('invalid_user');
    }
    String? optionalString(Object? input) =>
        input is String && input.trim().isNotEmpty ? input.trim() : null;
    return AuthSession(
      status: AuthStatus.authenticated,
      userId: id,
      displayName: optionalString(value['name']),
      email: optionalString(value['email']),
    );
  }

  static Map<String, dynamic> _jsonObject(String value) {
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } on Object {
      return <String, dynamic>{};
    }
  }

  static String _errorCode(Map<String, dynamic> body) =>
      body['error'] is String ? body['error'] as String : 'request_failed';

  static String _safeNetworkCode(Object error) =>
      error is TimeoutException ? 'timeout' : 'network_error';
}

final class _PendingSignIn {
  const _PendingSignIn({
    required this.provider,
    required this.state,
    required this.verifier,
    required this.completer,
  });

  final String provider;
  final String state;
  final String verifier;
  final Completer<AuthSession> completer;
}

sealed class AuthException implements Exception {
  const AuthException(this.code);

  final String code;

  @override
  String toString() => code;
}

final class AuthProviderUnavailable extends AuthException {
  const AuthProviderUnavailable() : super('provider_unavailable');
}

final class AuthFlowInProgress extends AuthException {
  const AuthFlowInProgress() : super('flow_in_progress');
}

final class AuthFlowExpired extends AuthException {
  const AuthFlowExpired() : super('flow_expired');
}

final class AuthBrowserLaunchFailed extends AuthException {
  const AuthBrowserLaunchFailed() : super('browser_launch_failed');
}

final class AuthOAuthStateMismatch extends AuthException {
  const AuthOAuthStateMismatch() : super('state_mismatch');
}

final class AuthProviderCancelled extends AuthException {
  const AuthProviderCancelled() : super('provider_cancelled');
}

final class AuthRemoteRequestFailed extends AuthException {
  const AuthRemoteRequestFailed(super.code);
}
