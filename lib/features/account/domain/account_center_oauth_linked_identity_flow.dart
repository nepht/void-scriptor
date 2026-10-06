/// Sprint 115.11 — OAuth & Linked Identity Flow.
///
/// A local, dependency-free authorization-code + PKCE flow contract. Network
/// calls and revocation are delegated to an injected broker. Durable token
/// storage belongs to step 115.12 and is intentionally not implemented here.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'account_center_provider_connector_manifest.dart';

enum OAuthFlowErrorCode {
  connectorUnavailable,
  unsupportedAuthType,
  consentRequired,
  scopeEscalation,
  callbackMismatch,
  callbackInvalid,
  stateMismatch,
  nonceMissing,
  nonceMismatch,
  authorizationDenied,
  tokenExchangeFailed,
  invalidTokenResponse,
  implausibleTokenLifetime,
  staleTokenGeneration,
  refreshTokenNotRotated,
  revocationFailed,
}

final class OAuthFlowException implements Exception {
  const OAuthFlowException(this.code, this.message);

  final OAuthFlowErrorCode code;
  final String message;

  @override
  String toString() => 'OAuthFlowException(${code.name}): $message';
}

final class OAuthProviderConfiguration {
  OAuthProviderConfiguration({
    required this.connector,
    required this.authorizationEndpoint,
    required this.redirectUri,
    required Iterable<String> scopes,
    this.tokenEndpoint,
    this.revocationEndpoint,
    this.nonceRequired = true,
    this.supportsRefresh = true,
  }) : scopes = _normalizeScopes(scopes) {
    if (authorizationEndpoint.scheme != 'https' ||
        authorizationEndpoint.host.isEmpty ||
        authorizationEndpoint.userInfo.isNotEmpty) {
      throw ArgumentError.value(
        authorizationEndpoint,
        'authorizationEndpoint',
        'Authorization endpoint must be an absolute HTTPS URI without user info.',
      );
    }
    if (redirectUri.scheme.isEmpty ||
        redirectUri.host.isEmpty ||
        redirectUri.path.isEmpty ||
        redirectUri.hasQuery ||
        redirectUri.hasFragment ||
        redirectUri.userInfo.isNotEmpty) {
      throw ArgumentError.value(
        redirectUri,
        'redirectUri',
        'Redirect URI must be absolute and must not contain query or fragment.',
      );
    }
    // 117.32: the redirect URI was never checked for `http`, while the
    // authorization endpoint two clauses up was required to be `https`. A
    // cleartext redirect is exactly where the authorization code and state
    // land, so registering one meant the code returned in the clear to any
    // network observer. Loopback `http` stays legal because the desktop
    // native-redirect flow depends on it, and a custom scheme (`voidscriptor:`)
    // is unaffected — only a remote `http` authority is refused.
    if (redirectUri.scheme == 'http' && !_isLoopback(redirectUri.host)) {
      throw ArgumentError.value(
        redirectUri,
        'redirectUri',
        'Redirect URI must use https; http is only allowed for loopback hosts.',
      );
    }
  }

  final ProviderConnectorEntry connector;
  final Uri authorizationEndpoint;
  final Uri redirectUri;
  final Set<String> scopes;
  final Uri? tokenEndpoint;
  final Uri? revocationEndpoint;
  final bool nonceRequired;
  final bool supportsRefresh;

  /// Loopback authorities, the only hosts allowed to receive a cleartext
  /// redirect. `localhost` and the RFC 1122 `.localhost` special-use domain
  /// never leave the machine; `127.0.0.0/8` and `[::1]` are literal
  /// loopback. Anything else is a remote authority.
  static bool _isLoopback(String host) {
    if (host.isEmpty) return false;
    final lower = host.toLowerCase();
    if (lower == 'localhost' || lower.endsWith('.localhost')) return true;
    if (lower == '[::1]' || lower == '::1') return true;
    final octets = lower.split('.');
    if (octets.length != 4) return false;
    if (octets.any((o) => int.tryParse(o) == null || int.parse(o) > 255)) {
      return false;
    }
    return octets.first == '127';
  }

  static Set<String> _normalizeScopes(Iterable<String> scopes) {
    final normalized = scopes
        .map((scope) => scope.trim())
        .where((scope) => scope.isNotEmpty)
        .toSet();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        scopes,
        'scopes',
        'OAuth authorization requires at least one explicit scope.',
      );
    }
    if (normalized.any((scope) => RegExp(r'[\s\x00-\x1f]').hasMatch(scope))) {
      throw ArgumentError.value(
        scopes,
        'scopes',
        'OAuth scopes must not contain whitespace or control characters.',
      );
    }
    return Set<String>.unmodifiable(normalized);
  }
}

final class OAuthScopeConsent {
  OAuthScopeConsent({
    required Iterable<String> requestedScopes,
    required Iterable<String> grantedScopes,
    required this.explicitlyApproved,
  }) : requestedScopes = _normalizeScopes(requestedScopes),
       grantedScopes = _normalizeScopes(grantedScopes);

  final Set<String> requestedScopes;
  final Set<String> grantedScopes;
  final bool explicitlyApproved;

  static Set<String> _normalizeScopes(Iterable<String> scopes) {
    final normalized = scopes
        .map((scope) => scope.trim())
        .where((scope) => scope.isNotEmpty)
        .toSet();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        scopes,
        'scopes',
        'OAuth scope consent requires at least one explicit scope.',
      );
    }
    return Set<String>.unmodifiable(normalized);
  }
}

final class OAuthAuthorizationRequest {
  OAuthAuthorizationRequest._({
    required this.configuration,
    required this.consent,
    required this.state,
    required this.nonce,
    required this.codeVerifier,
    required this.codeChallenge,
    required this.createdAt,
  });

  final OAuthProviderConfiguration configuration;
  final OAuthScopeConsent consent;
  final String state;
  final String? nonce;
  final String codeVerifier;
  final String codeChallenge;
  final DateTime createdAt;

  String get providerId => configuration.connector.providerId;
  Uri get redirectUri => configuration.redirectUri;
  String get redirectUriText => redirectUri.toString();
  Uri get authorizationUri => configuration.authorizationEndpoint.replace(
    queryParameters: <String, String>{
      'response_type': 'code',
      'client_id': providerId,
      'redirect_uri': redirectUriText,
      'scope': (consent.grantedScopes.toList()..sort()).join(' '),
      'state': state,
      'nonce': ?nonce,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    },
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'provider_id': providerId,
    'redirect_uri': redirectUriText,
    'scopes': consent.grantedScopes.toList(growable: false)..sort(),
    'state': state,
    'nonce': nonce,
    'code_challenge': codeChallenge,
    'code_challenge_method': 'S256',
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  @override
  String toString() => jsonEncode(toJson());
}

final class OAuthTokenExchangeRequest {
  const OAuthTokenExchangeRequest({
    required this.configuration,
    required this.code,
    required this.codeVerifier,
    required this.redirectUri,
    required this.scopes,
  });

  final OAuthProviderConfiguration configuration;
  final String code;
  final String codeVerifier;
  final Uri redirectUri;
  final Set<String> scopes;
}

final class OAuthTokenRefreshRequest {
  const OAuthTokenRefreshRequest({required this.grant});

  final OAuthTokenGrant grant;
}

final class OAuthTokenResponse {
  OAuthTokenResponse({
    required String providerId,
    required String providerAccountId,
    required String displayName,
    required String accessToken,
    required String refreshToken,
    required this.accessTokenExpiresAt,
    this.supportsRefresh = true,
    DateTime? issuedAt,
    required Iterable<String> scopes,
  }) : providerId = providerId.trim().toLowerCase(),
       providerAccountId = providerAccountId.trim(),
       displayName = displayName.trim(),
       accessToken = _requireSecret(accessToken, 'accessToken'),
       refreshToken = refreshToken.trim(),
       issuedAt = (issuedAt ?? DateTime.now().toUtc()).toUtc(),
       scopes = Set<String>.unmodifiable(scopes) {
    if (this.providerId.isEmpty || this.providerAccountId.isEmpty) {
      throw ArgumentError(
        'Token response requires providerId and providerAccountId.',
      );
    }
    if (this.displayName.isEmpty) {
      throw ArgumentError('Token response requires a non-empty displayName.');
    }
    if (this.scopes.isEmpty) {
      throw ArgumentError('Token response requires explicit granted scopes.');
    }
  }

  final String providerId;
  final String providerAccountId;
  final String displayName;
  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;
  final bool supportsRefresh;

  /// When the provider claims to have issued the token.
  ///
  /// Needed to judge the stated lifetime: an expiry stamp alone cannot tell a
  /// normal one-hour token from one valid for the next seventy years.
  final DateTime issuedAt;
  final Set<String> scopes;

  /// Lifetime the provider stated.
  Duration get accessTokenLifetime =>
      accessTokenExpiresAt.toUtc().difference(issuedAt);

  /// Whether the stated lifetime is longer than a token should ever live.
  ///
  /// Measured, the flow accepted an expiry of `2099-01-01` without comment and
  /// stored it, and the resulting connection reported itself healthy for the
  /// next seventy-three years with no expiry pressure anyone could act on.
  bool get hasImplausibleLifetime =>
      accessTokenLifetime > OAuthTokenGrant.maxPlausibleLifetime;

  static String _requireSecret(String value, String field) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        field,
        'Token response field is required.',
      );
    }
    return normalized;
  }
}

final class OAuthTokenGrant {
  OAuthTokenGrant._({
    required this.connectionId,
    required this.providerId,
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    required this.supportsRefresh,
    required this.scopes,
    required this.generation,
    DateTime? installedAt,
  }) : installedAt = (installedAt ?? DateTime.now().toUtc()).toUtc();

  final String connectionId;
  final String providerId;
  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;
  final bool supportsRefresh;
  final Set<String> scopes;
  final int generation;

  /// When this generation was installed.
  ///
  /// The provider states only an absolute expiry, so a grant whose expiry was
  /// stamped years in the future was accepted at install time and could never
  /// be flagged afterwards: measured, the flow accepted an expiry of
  /// `2099-01-01` and the installed grant exposed no way to ask whether it was
  /// already dead. An absurd lifetime is a provider or clock fault, not a valid
  /// grant, and it must be reported rather than stored.
  final DateTime installedAt;

  /// Lifetime the provider asked for.
  Duration get accessTokenLifetime =>
      accessTokenExpiresAt.difference(installedAt);

  /// A grant is expired when its access token's expiry has passed.
  ///
  /// Strictly before: a token expiring at exactly [at] is still valid at [at],
  /// and treating the boundary as expired would rotate a live token. Measured,
  /// the implementation used `!isAfter(at)`, so the boundary instant itself
  /// reported expired while this contract and `remainingAt` both say it is not.
  bool isExpiredAt(DateTime at) =>
      accessTokenExpiresAt.toUtc().isBefore(at.toUtc());

  /// How long until expiry; negative once expired.
  Duration remainingAt(DateTime at) =>
      accessTokenExpiresAt.toUtc().difference(at.toUtc());

  /// Whether the token's stated lifetime is implausible and therefore unsafe.
  ///
  /// A provider that hands back a token valid for longer than
  /// [maxPlausibleLifetime] has either lost track of clock skew or is issuing
  /// something that will not be revocable in time. Storing it silently makes
  /// the connection look healthy for years with no path back.
  bool get hasImplausibleLifetime => accessTokenLifetime > maxPlausibleLifetime;

  /// Upper bound accepted on a provider-stated access-token lifetime.
  static const Duration maxPlausibleLifetime = Duration(days: 90);

  @override
  String toString() =>
      'OAuthTokenGrant($connectionId, generation: $generation, '
      'expires: ${accessTokenExpiresAt.toIso8601String()}, '
      'access: [REDACTED], refresh: [REDACTED])';
}

final class LinkedIdentity {
  const LinkedIdentity({
    required this.connectionId,
    required this.providerId,
    required this.accountLabel,
    required this.scopes,
    required this.tokenGeneration,
  });

  final String connectionId;
  final String providerId;
  final String accountLabel;
  final Set<String> scopes;
  final int tokenGeneration;
}

final class LinkedIdentityResult {
  const LinkedIdentityResult({
    required this.identity,
    required this.tokenGrant,
  });

  final LinkedIdentity identity;
  final OAuthTokenGrant tokenGrant;

  @override
  String toString() => 'LinkedIdentityResult(${identity.connectionId})';
}

enum OAuthUnlinkDecision { keepLinked, unlink }

/// Production HTTP-based broker for public OAuth 2.0 PKCE providers.
///
/// Executes token exchange, refresh, and revocation via explicit HTTPS endpoints.
/// Never accepts client secrets, logs no token bodies, and fails closed on malformed
/// payloads or network errors.
final class HttpOAuthTokenBroker implements OAuthTokenBroker {
  HttpOAuthTokenBroker({
    http.Client? client,
    DateTime Function()? clock,
  })  : _client = client ?? http.Client(),
        _clock = clock ?? (() => DateTime.now().toUtc());

  final http.Client _client;
  final DateTime Function() _clock;

  @override
  Future<OAuthTokenResponse> exchange(OAuthTokenExchangeRequest request) async {
    final endpoint = request.configuration.tokenEndpoint;
    if (endpoint == null) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.tokenExchangeFailed,
        'OAuth token endpoint is not configured.',
      );
    }

    final http.Response response;
    try {
      response = await _client.post(
        endpoint,
        headers: const <String, String>{
          'content-type': 'application/x-www-form-urlencoded',
          'accept': 'application/json',
        },
        body: <String, String>{
          'grant_type': 'authorization_code',
          'client_id': request.configuration.connector.providerId,
          'code': request.code,
          'code_verifier': request.codeVerifier,
          'redirect_uri': request.redirectUri.toString(),
        },
      );
    } catch (e) {
      throw OAuthFlowException(
        OAuthFlowErrorCode.tokenExchangeFailed,
        'Failed to connect to OAuth token endpoint: $e',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OAuthFlowException(
        OAuthFlowErrorCode.tokenExchangeFailed,
        'OAuth token endpoint returned status code ${response.statusCode}.',
      );
    }

    return _parseTokenResponse(
      response.body,
      expectedProviderId: request.configuration.connector.providerId,
    );
  }

  @override
  Future<OAuthTokenResponse> refresh(OAuthTokenRefreshRequest request) async {
    throw const OAuthFlowException(
      OAuthFlowErrorCode.tokenExchangeFailed,
      'Refresh via HttpOAuthTokenBroker requires configuration-aware invocation.',
    );
  }

  /// Refreshes tokens using explicit provider configuration.
  Future<OAuthTokenResponse> refreshWithConfiguration({
    required OAuthTokenGrant grant,
    required OAuthProviderConfiguration configuration,
  }) async {
    final endpoint = configuration.tokenEndpoint;
    if (endpoint == null) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.tokenExchangeFailed,
        'OAuth token endpoint is not configured for refresh.',
      );
    }

    final http.Response response;
    try {
      response = await _client.post(
        endpoint,
        headers: const <String, String>{
          'content-type': 'application/x-www-form-urlencoded',
          'accept': 'application/json',
        },
        body: <String, String>{
          'grant_type': 'refresh_token',
          'client_id': configuration.connector.providerId,
          'refresh_token': grant.refreshToken,
        },
      );
    } catch (e) {
      throw OAuthFlowException(
        OAuthFlowErrorCode.tokenExchangeFailed,
        'Failed to connect to OAuth token endpoint during refresh: $e',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OAuthFlowException(
        OAuthFlowErrorCode.tokenExchangeFailed,
        'OAuth token refresh returned status code ${response.statusCode}.',
      );
    }

    return _parseTokenResponse(
      response.body,
      expectedProviderId: configuration.connector.providerId,
    );
  }

  @override
  Future<void> revoke(OAuthTokenGrant grant) async {
    throw const OAuthFlowException(
      OAuthFlowErrorCode.revocationFailed,
      'Revocation via HttpOAuthTokenBroker requires configuration-aware invocation.',
    );
  }

  /// Revokes tokens using explicit provider configuration.
  Future<void> revokeWithConfiguration({
    required OAuthTokenGrant grant,
    required OAuthProviderConfiguration configuration,
  }) async {
    final endpoint = configuration.revocationEndpoint;
    if (endpoint == null) {
      return;
    }

    final http.Response response;
    try {
      response = await _client.post(
        endpoint,
        headers: const <String, String>{
          'content-type': 'application/x-www-form-urlencoded',
        },
        body: <String, String>{
          'client_id': configuration.connector.providerId,
          'token': grant.refreshToken.isNotEmpty ? grant.refreshToken : grant.accessToken,
        },
      );
    } catch (e) {
      throw OAuthFlowException(
        OAuthFlowErrorCode.revocationFailed,
        'Failed to connect to OAuth revocation endpoint: $e',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OAuthFlowException(
        OAuthFlowErrorCode.revocationFailed,
        'OAuth revocation endpoint returned status code ${response.statusCode}.',
      );
    }
  }

  OAuthTokenResponse _parseTokenResponse(
    String body, {
    required String expectedProviderId,
  }) {
    final dynamic data;
    try {
      data = jsonDecode(body);
    } catch (_) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.invalidTokenResponse,
        'OAuth token response is not valid JSON.',
      );
    }

    if (data is! Map<String, dynamic>) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.invalidTokenResponse,
        'OAuth token response is not a JSON object.',
      );
    }

    final accessToken = data['access_token'];
    final refreshToken = data['refresh_token'];
    final expiresIn = data['expires_in'];
    final providerAccountId =
        data['provider_account_id']?.toString() ?? data['sub']?.toString();
    final displayName =
        data['display_name']?.toString() ?? data['name']?.toString() ?? providerAccountId;

    if (accessToken is! String || accessToken.isEmpty) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.invalidTokenResponse,
        'OAuth token response is missing a valid access_token.',
      );
    }

    if (providerAccountId == null || providerAccountId.isEmpty) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.invalidTokenResponse,
        'OAuth token response is missing a valid provider account identifier.',
      );
    }

    final List<String> scopeList;
    final rawScope = data['scope'];
    if (rawScope is String) {
      scopeList = rawScope.split(' ').where((s) => s.isNotEmpty).toList();
    } else if (rawScope is List) {
      scopeList = rawScope.map((s) => s.toString()).toList();
    } else {
      scopeList = const <String>[];
    }

    final now = _clock();
    final DateTime expiresAt;
    if (expiresIn is num && expiresIn > 0) {
      expiresAt = now.add(Duration(seconds: expiresIn.toInt()));
    } else {
      expiresAt = now.add(const Duration(hours: 1));
    }

    final String effectiveRefresh =
        (refreshToken is String && refreshToken.isNotEmpty)
            ? refreshToken
            : '';

    return OAuthTokenResponse(
      providerId: expectedProviderId,
      providerAccountId: providerAccountId,
      displayName: displayName ?? expectedProviderId,
      accessToken: accessToken,
      refreshToken: effectiveRefresh,
      accessTokenExpiresAt: expiresAt,
      issuedAt: now,
      scopes: scopeList,
    );
  }
}

abstract interface class OAuthTokenBroker {
  Future<OAuthTokenResponse> exchange(OAuthTokenExchangeRequest request);

  Future<OAuthTokenResponse> refresh(OAuthTokenRefreshRequest request);

  Future<void> revoke(OAuthTokenGrant grant);
}

final class AccountOAuthFlow {
  AccountOAuthFlow({
    required this.broker,
    List<int> Function(int length)? randomBytes,
    DateTime Function()? clock,
  }) : _randomBytes = randomBytes ?? _secureRandomBytes,
       _clock = clock ?? (() => DateTime.now().toUtc());

  static const String manifestPath =
      'docs/planning/v1.2/sprint_115_oauth_linked_identity_flow.json';
  static const String canonicalSprintPath =
      'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/'
      'sprint_115.json';
  static const String canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';
  static const List<String> canonicalAcceptance = <String>[
    'pkce',
    'state_validation',
    'nonce_when_required',
    'scoped_consent',
    'token_rotation',
    'revocation',
  ];

  final OAuthTokenBroker broker;
  final List<int> Function(int length) _randomBytes;
  final DateTime Function() _clock;
  final Map<String, _PendingAuthorization> _pending =
      <String, _PendingAuthorization>{};
  final Map<String, LinkedIdentity> _identities = <String, LinkedIdentity>{};
  final Map<String, OAuthTokenGrant> _grants = <String, OAuthTokenGrant>{};

  List<LinkedIdentity> get linkedIdentities =>
      List<LinkedIdentity>.unmodifiable(_identities.values);

  /// Authorizations that were issued and not yet resolved.
  ///
  /// 117.32: `_pending` only ever grew. A spent entry was flagged
  /// `consumed` and left in the map forever, so the PKCE verifier for every
  /// authorization the user ever started stayed resident in memory, and the
  /// map was the sole replay ledger — entries marked consumed from a year ago
  /// were indistinguishable from live ones. The entry is now released the
  /// moment it resolves, which makes the size of this map equal to the number
  /// of authorizations actually in flight.
  int get liveAuthorizationCount => _pending.length;

  OAuthAuthorizationRequest beginAuthorization({
    required OAuthProviderConfiguration configuration,
    required OAuthScopeConsent consent,
  }) {
    _validateProviderConfiguration(configuration);
    _validateConsent(configuration: configuration, consent: consent);
    final verifier = _randomToken(64);
    final state = _randomToken(32);
    final nonce = configuration.nonceRequired ? _randomToken(32) : null;
    final challenge = _base64Url(sha256.convert(utf8.encode(verifier)).bytes);
    final request = OAuthAuthorizationRequest._(
      configuration: configuration,
      consent: consent,
      state: state,
      nonce: nonce,
      codeVerifier: verifier,
      codeChallenge: challenge,
      createdAt: _clock(),
    );
    _pending[state] = _PendingAuthorization(request: request, consumed: false);
    return request;
  }

  Future<LinkedIdentityResult> completeAuthorization({
    required Uri callback,
  }) async {
    final query = _validateCallbackShape(callback);
    final state = _requiredQueryValue(
      query,
      'state',
      OAuthFlowErrorCode.stateMismatch,
    );
    final pending = _pending[state];
    if (pending == null || pending.consumed) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.stateMismatch,
        'OAuth callback state is unknown or already consumed.',
      );
    }

    if (query.containsKey('error')) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.authorizationDenied,
        'The provider denied the authorization request.',
      );
    }
    if (pending.request.nonce != null) {
      final nonce = _requiredQueryValue(
        query,
        'nonce',
        OAuthFlowErrorCode.nonceMissing,
      );
      if (!_constantTimeEquals(nonce, pending.request.nonce!)) {
        throw const OAuthFlowException(
          OAuthFlowErrorCode.nonceMismatch,
          'OAuth callback nonce does not match the authorization request.',
        );
      }
    }
    final code = _requiredQueryValue(
      query,
      'code',
      OAuthFlowErrorCode.callbackInvalid,
    );
    // The authorization is spent from this point on: the code is redeemed by
    // the broker call below and can never legitimately be replayed, so the
    // pending entry is released before that call rather than flagged and
    // retained. A broker fault therefore cannot leave a spent entry resident
    // either, and a second callback with the same state fails on the unknown
    // state rather than on a boolean nobody clears.
    _pending.remove(state);
    final response = await _callBroker(
      () => broker.exchange(
        OAuthTokenExchangeRequest(
          configuration: pending.request.configuration,
          code: code,
          codeVerifier: pending.request.codeVerifier,
          redirectUri: pending.request.configuration.redirectUri,
          scopes: pending.request.consent.grantedScopes,
        ),
      ),
    );
    _validateTokenResponse(
      response: response,
      expectedProviderId: pending.request.providerId,
      expectedAccountId: null,
      allowedScopes: pending.request.consent.grantedScopes,
      requireNewRefreshToken: null,
      supportsRefresh: pending.request.configuration.supportsRefresh,
    );
    return _installLinkedIdentity(
      response,
      scopes: pending.request.consent.grantedScopes,
      generation: 1,
    );
  }

  Future<LinkedIdentityResult> rotateTokens({
    required OAuthTokenGrant currentGrant,
  }) async {
    final current = _grants[currentGrant.connectionId];
    if (current == null || !identical(current, currentGrant)) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.staleTokenGeneration,
        'Only the current token generation can be rotated.',
      );
    }
    final response = await _callBroker(
      () => broker.refresh(OAuthTokenRefreshRequest(grant: current)),
    );
    _validateTokenResponse(
      response: response,
      expectedProviderId: current.providerId,
      expectedAccountId: null,
      allowedScopes: current.scopes,
      requireNewRefreshToken: current.refreshToken,
      supportsRefresh: current.supportsRefresh,
    );
    return _installLinkedIdentity(
      response,
      scopes: current.scopes,
      generation: current.generation + 1,
      requireKnownAccount: true,
    );
  }

  Future<bool> unlink({
    required OAuthTokenGrant grant,
    required OAuthUnlinkDecision decision,
  }) async {
    if (decision == OAuthUnlinkDecision.keepLinked) return false;
    final current = _grants[grant.connectionId];
    if (current == null || !identical(current, grant)) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.staleTokenGeneration,
        'Only the current token generation can be unlinked.',
      );
    }
    try {
      await broker.revoke(current);
    } catch (_) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.revocationFailed,
        'Provider revocation failed; the local link was preserved.',
      );
    }
    _grants.remove(current.connectionId);
    _identities.remove(current.connectionId);
    return true;
  }

  LinkedIdentityResult _installLinkedIdentity(
    OAuthTokenResponse response, {
    required Set<String> scopes,
    required int generation,
    bool requireKnownAccount = false,
  }) {
    final connectionId = '${response.providerId}/${response.providerAccountId}';
    if (requireKnownAccount && !_identities.containsKey(connectionId)) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.staleTokenGeneration,
        'Token response refers to an unknown linked account.',
      );
    }
    final grant = OAuthTokenGrant._(
      connectionId: connectionId,
      providerId: response.providerId,
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      accessTokenExpiresAt: response.accessTokenExpiresAt.toUtc(),
      supportsRefresh: response.supportsRefresh,
      scopes: Set<String>.unmodifiable(scopes),
      generation: generation,
      installedAt: _clock(),
    );
    final identity = LinkedIdentity(
      connectionId: connectionId,
      providerId: response.providerId,
      accountLabel: response.displayName,
      scopes: Set<String>.unmodifiable(scopes),
      tokenGeneration: generation,
    );
    _grants[connectionId] = grant;
    _identities[connectionId] = identity;
    return LinkedIdentityResult(identity: identity, tokenGrant: grant);
  }

  void _validateProviderConfiguration(
    OAuthProviderConfiguration configuration,
  ) {
    if (!configuration.connector.isConnectable) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.connectorUnavailable,
        'Connector is not explicitly certified and available.',
      );
    }
    if (configuration.connector.authType != ProviderAuthType.oauth2Pkce) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.unsupportedAuthType,
        'Only OAuth 2.0 authorization code with PKCE is supported.',
      );
    }
    if (!configuration.connector.capabilities.contains(
      ProviderConnectorCapability.identity,
    )) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.unsupportedAuthType,
        'Connector does not declare the identity capability.',
      );
    }
  }

  void _validateConsent({
    required OAuthProviderConfiguration configuration,
    required OAuthScopeConsent consent,
  }) {
    if (!consent.explicitlyApproved) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.consentRequired,
        'OAuth scopes require explicit user approval.',
      );
    }
    if (!_sameScopes(consent.requestedScopes, configuration.scopes) ||
        !_sameScopes(consent.grantedScopes, configuration.scopes)) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.scopeEscalation,
        'Granted scopes must exactly match the configured consent set.',
      );
    }
  }

  Map<String, String> _validateCallbackShape(Uri callback) {
    if (callback.scheme.isEmpty ||
        callback.host.isEmpty ||
        callback.path.isEmpty) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.callbackMismatch,
        'OAuth callback must be an absolute URI.',
      );
    }
    final values = callback.queryParametersAll;
    if (values.values.any((entries) => entries.length != 1) ||
        (values.containsKey('code') && values.containsKey('error'))) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.callbackInvalid,
        'OAuth callback contains duplicate or conflicting parameters.',
      );
    }
    final state = values['state']?.single;
    if (state == null) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.stateMismatch,
        'OAuth callback is missing state.',
      );
    }
    final pending = _pending[state];
    if (pending == null) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.stateMismatch,
        'OAuth callback state is unknown.',
      );
    }
    final expected = pending.request.configuration.redirectUri;
    // 117.32: the port and the callback's own user info were both ignored.
    // `https://app.example.test:8443/callback` and
    // `https://app.example.test/callback` were both accepted for a redirect
    // registered on port 443, and `https://user:pw@app.example.test/callback`
    // matched as well — user info is what a parser reads first when deciding
    // which host it is talking to, so a callback that looks like it names a
    // different authority was treated as the registered one. Scheme, host,
    // port, and path must all be identical, and the callback must carry no
    // user info of its own.
    if (callback.scheme != expected.scheme ||
        callback.host != expected.host ||
        callback.hasPort != expected.hasPort ||
        (callback.hasPort && callback.port != expected.port) ||
        callback.path != expected.path ||
        callback.userInfo.isNotEmpty) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.callbackMismatch,
        'OAuth callback does not match the registered redirect URI.',
      );
    }
    return values.map((key, entries) => MapEntry(key, entries.single));
  }

  void _validateTokenResponse({
    required OAuthTokenResponse response,
    required String expectedProviderId,
    required String? expectedAccountId,
    required Set<String> allowedScopes,
    required String? requireNewRefreshToken,
    required bool supportsRefresh,
  }) {
    final missingRefreshToken =
        supportsRefresh && response.refreshToken.isEmpty;
    // An expiry in the past makes the response unusable; an expiry absurdly far
    // in the future is a provider or clock fault that must not be stored as a
    // healthy long-lived connection. Measured before this check existed, a
    // response expiring in 2099 was accepted and installed without comment.
    final expired = response.accessTokenExpiresAt.toUtc().isBefore(_clock());
    final implausibleLifetime = response.hasImplausibleLifetime;
    if (response.providerId != expectedProviderId ||
        (expectedAccountId != null &&
            response.providerId == expectedProviderId &&
            response.providerAccountId != expectedAccountId) ||
        expired ||
        implausibleLifetime ||
        missingRefreshToken ||
        !_sameScopes(allowedScopes, response.scopes) ||
        (requireNewRefreshToken != null &&
            requireNewRefreshToken == response.refreshToken)) {
      final sameRefreshToken =
          requireNewRefreshToken != null &&
          requireNewRefreshToken == response.refreshToken;
      final wrongAccount =
          response.providerId != expectedProviderId ||
          (expectedAccountId != null &&
              response.providerAccountId != expectedAccountId);
      final code = missingRefreshToken
          ? OAuthFlowErrorCode.invalidTokenResponse
          : sameRefreshToken
          ? OAuthFlowErrorCode.refreshTokenNotRotated
          : implausibleLifetime
          ? OAuthFlowErrorCode.implausibleTokenLifetime
          : wrongAccount || expired
          ? OAuthFlowErrorCode.invalidTokenResponse
          : OAuthFlowErrorCode.scopeEscalation;
      throw OAuthFlowException(
        code,
        implausibleLifetime
            ? 'Token response states a lifetime longer than any token may '
                  'live; refusing to store it.'
            : 'Token response violates the current link contract.',
      );
    }
  }

  String _requiredQueryValue(
    Map<String, String> query,
    String key,
    OAuthFlowErrorCode code,
  ) {
    final value = query[key]?.trim();
    if (value == null || value.isEmpty) {
      throw OAuthFlowException(code, 'OAuth callback is missing $key.');
    }
    return value;
  }

  String _randomToken(int byteLength) {
    if (byteLength < 32 || byteLength > 128) {
      throw ArgumentError.value(
        byteLength,
        'byteLength',
        'OAuth random values require 32..128 bytes.',
      );
    }
    final bytes = List<int>.unmodifiable(_randomBytes(byteLength));
    if (bytes.length != byteLength) {
      throw StateError('Random-byte source returned the wrong length.');
    }
    return _base64Url(bytes);
  }

  Future<T> _callBroker<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on OAuthFlowException {
      rethrow;
    } catch (_) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.tokenExchangeFailed,
        'OAuth broker operation failed.',
      );
    }
  }

  static List<int> _secureRandomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  static bool _sameScopes(Set<String> first, Set<String> second) =>
      first.length == second.length && first.containsAll(second);

  static bool _constantTimeEquals(String first, String second) {
    final firstBytes = utf8.encode(first);
    final secondBytes = utf8.encode(second);
    var difference = firstBytes.length ^ secondBytes.length;
    final length = max(firstBytes.length, secondBytes.length);
    for (var index = 0; index < length; index++) {
      final left = index < firstBytes.length ? firstBytes[index] : 0;
      final right = index < secondBytes.length ? secondBytes[index] : 0;
      difference |= left ^ right;
    }
    return difference == 0;
  }

  static String _base64Url(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
}

final class _PendingAuthorization {
  _PendingAuthorization({required this.request, required this.consumed});

  final OAuthAuthorizationRequest request;
  bool consumed;
}
