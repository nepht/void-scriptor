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
        SocialAccountLinker,
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
  _PendingSignIn? _pendingSignIn;
  _PendingLink? _pendingLink;
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
    if (_pendingSignIn != null || _pendingLink != null) {
      throw const AuthFlowInProgress();
    }

    final verifier = _randomToken(48);
    final challenge = _pkceChallenge(verifier);
    final state = _randomToken(24);
    final pending = _PendingSignIn(
      provider: normalizedProvider,
      state: state,
      verifier: verifier,
      completer: Completer<AuthSession>(),
    );
    _pendingSignIn = pending;
    _pendingTimeout = Timer(const Duration(minutes: 5), () {
      if (identical(_pendingSignIn, pending)) {
        _pendingSignIn = null;
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
      _clearPendingSignIn(pending);
      throw const AuthBrowserLaunchFailed();
    }

    try {
      return await pending.completer.future.timeout(requestTimeout * 15);
    } finally {
      _clearPendingSignIn(pending);
    }
  }

  @override
  Future<AuthSession> linkProvider({required String provider}) async {
    final normalizedProvider = provider.trim().toLowerCase();
    if (normalizedProvider != 'google' && normalizedProvider != 'github') {
      throw const AuthProviderUnavailable();
    }
    if (_pendingSignIn != null || _pendingLink != null) {
      throw const AuthFlowInProgress();
    }
    final token = await tokenStore.read(_sessionTokenKey);
    if (token == null || token.trim().isEmpty) {
      throw const AuthIdentityUnavailable();
    }

    final verifier = _randomToken(48);
    final challenge = _pkceChallenge(verifier);
    final state = _randomToken(24);
    final pending = _PendingLink(
      provider: normalizedProvider,
      state: state,
      verifier: verifier,
      completer: Completer<AuthSession>(),
    );
    _pendingLink = pending;
    _pendingTimeout = Timer(const Duration(minutes: 5), () {
      if (identical(_pendingLink, pending)) {
        _pendingLink = null;
        pending.completer.completeError(const AuthFlowExpired());
      }
    });

    try {
      final response = await client
          .post(
            _endpoint('/api/account/connections/link/start'),
            headers: <String, String>{
              'authorization': 'Bearer $token',
              'content-type': 'application/json',
            },
            body: jsonEncode(<String, String>{
              'provider': normalizedProvider,
              'redirect_uri': callbackUri,
              'state': state,
              'code_challenge': challenge,
              'code_challenge_method': _pkceMethod,
            }),
          )
          .timeout(requestTimeout);
      final body = _jsonObject(response.body);
      if (response.statusCode != 200 || body['ok'] != true) {
        throw AuthRemoteRequestFailed(_errorCode(body));
      }
      final rawAuthorizationUrl = body['authorization_url'];
      final authorizationUri = rawAuthorizationUrl is String
          ? Uri.tryParse(rawAuthorizationUrl)
          : null;
      if (authorizationUri == null || authorizationUri.scheme != 'https') {
        throw const AuthRemoteRequestFailed('missing_authorization_url');
      }
      if (!await browserLauncher.launch(authorizationUri)) {
        throw const AuthBrowserLaunchFailed();
      }
      return await pending.completer.future.timeout(requestTimeout * 15);
    } on AuthException {
      _clearPendingLink(pending);
      rethrow;
    } on Object catch (error) {
      _clearPendingLink(pending);
      throw AuthRemoteRequestFailed(_safeNetworkCode(error));
    }
  }

  /// Consumes a native protocol callback. Returns true when this provider had
  /// a pending flow and therefore owns the callback, including a rejected
  /// state/error callback. A callback for another OAuth connector returns
  /// false so the existing cloud-connector flow can handle it.
  Future<bool> completeCallback(Uri uri) async {
    final envelope = OAuthCallbackRouter.parse(uri);
    final pendingSignIn = _pendingSignIn;
    final pendingLink = _pendingLink;
    if (envelope == null || (pendingSignIn == null && pendingLink == null)) {
      return false;
    }
    final expectedState = pendingSignIn?.state ?? pendingLink!.state;

    if (envelope.state != expectedState) {
      if (pendingLink != null) {
        _completeLinkError(pendingLink, const AuthOAuthStateMismatch());
      } else {
        _completeSignInError(pendingSignIn!, const AuthOAuthStateMismatch());
      }
      return true;
    }
    if (pendingLink != null) {
      try {
        if (envelope.error != null) {
          throw AuthProviderCancelled();
        }
        if (envelope.uri.queryParameters['linked'] != pendingLink.provider) {
          throw AuthRemoteRequestFailed(
            envelope.error ?? envelope.errorDescription ?? 'link_failed',
          );
        }
        final session = await restoreSession();
        if (session == null) {
          throw const AuthRemoteRequestFailed('session_unavailable');
        }
        _completeLinkSuccess(pendingLink, session);
      } on AuthException catch (error, stackTrace) {
        _completeLinkError(pendingLink, error, stackTrace);
      } on Object catch (error, stackTrace) {
        _completeLinkError(
          pendingLink,
          AuthRemoteRequestFailed(_safeNetworkCode(error)),
          stackTrace,
        );
      }
      return true;
    }

    if (!envelope.isAuthorizationSuccess) {
      _completeSignInError(pendingSignIn!, const AuthProviderCancelled());
      return true;
    }

    try {
      final response = await client
          .post(
            _endpoint('/api/auth/exchange'),
            headers: const {'content-type': 'application/json'},
            body: jsonEncode(<String, String>{
              'code': envelope.code!,
              'code_verifier': pendingSignIn!.verifier,
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
      final session = _sessionFromUser(
        body['user'],
        fallbackProvider: pendingSignIn.provider,
      );
      await tokenStore.write(key: _sessionTokenKey, value: token);
      _completeSignInSuccess(pendingSignIn, session);
    } on AuthException catch (error, stackTrace) {
      _completeSignInError(pendingSignIn!, error, stackTrace);
    } on Object catch (error, stackTrace) {
      _completeSignInError(
        pendingSignIn!,
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
      final session = _sessionFromUser(body['user']);
      return await _withLinkedProviders(session, token);
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

  void _clearPendingSignIn(_PendingSignIn pending) {
    if (identical(_pendingSignIn, pending)) _pendingSignIn = null;
    _pendingTimeout?.cancel();
    _pendingTimeout = null;
  }

  void _clearPendingLink(_PendingLink pending) {
    if (identical(_pendingLink, pending)) _pendingLink = null;
    _pendingTimeout?.cancel();
    _pendingTimeout = null;
  }

  void _completeSignInSuccess(_PendingSignIn pending, AuthSession session) {
    _clearPendingSignIn(pending);
    if (!pending.completer.isCompleted) pending.completer.complete(session);
  }

  void _completeLinkSuccess(_PendingLink pending, AuthSession session) {
    _clearPendingLink(pending);
    if (!pending.completer.isCompleted) pending.completer.complete(session);
  }

  void _completeSignInError(
    _PendingSignIn pending,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    _clearPendingSignIn(pending);
    if (!pending.completer.isCompleted) {
      pending.completer.completeError(error, stackTrace ?? StackTrace.current);
    }
  }

  void _completeLinkError(
    _PendingLink pending,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    _clearPendingLink(pending);
    if (!pending.completer.isCompleted) {
      pending.completer.completeError(error, stackTrace ?? StackTrace.current);
    }
  }

  Future<AuthSession> _withLinkedProviders(
    AuthSession session,
    String token,
  ) async {
    try {
      final response = await client
          .get(
            _endpoint('/api/account/connections'),
            headers: <String, String>{'authorization': 'Bearer $token'},
          )
          .timeout(requestTimeout);
      final body = _jsonObject(response.body);
      final connections = body['connections'];
      if (response.statusCode != 200 ||
          body['ok'] != true ||
          connections is! List) {
        return session;
      }
      final providers = connections
          .whereType<Map<String, dynamic>>()
          .map((connection) => _knownProvider(connection['provider']))
          .whereType<String>()
          .followedBy(
            session.identityProvider == null
                ? const <String>[]
                : <String>[session.identityProvider!],
          )
          .toSet()
          .toList(growable: false);
      return AuthSession(
        status: session.status,
        userId: session.userId,
        displayName: session.displayName,
        email: session.email,
        identityProvider: session.identityProvider,
        linkedIdentityProviders: providers,
      );
    } on Object {
      return session;
    }
  }

  AuthSession _sessionFromUser(Object? value, {String? fallbackProvider}) {
    if (value is! Map) throw const AuthRemoteRequestFailed('invalid_user');
    final id = value['id'];
    if (id is! String || id.trim().isEmpty) {
      throw const AuthRemoteRequestFailed('invalid_user');
    }
    String? optionalString(Object? input) =>
        input is String && input.trim().isNotEmpty ? input.trim() : null;
    final provider = _knownProvider(value['provider']) ?? fallbackProvider;
    return AuthSession(
      status: AuthStatus.authenticated,
      userId: id,
      displayName: optionalString(value['name']),
      email: optionalString(value['email']),
      identityProvider: provider,
      linkedIdentityProviders: <String>[?provider],
    );
  }

  static String? _knownProvider(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'google' || 'github' => normalized,
      _ => null,
    };
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

final class _PendingLink {
  const _PendingLink({
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
