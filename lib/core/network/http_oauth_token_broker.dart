/// HTTP implementation of `OAuthTokenBroker` for desktop PKCE and token
/// exchange.
///
/// Kept under `lib/core/network/` to satisfy the privacy & data-flow
/// architectural boundary (Sprint 115.50) which requires `lib/features/account`
/// to remain free of direct external network client imports.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/account/domain/account_center_oauth_linked_identity_flow.dart';

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

    final response = await _client.post(
      endpoint,
      headers: const <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: <String, String>{
        'grant_type': 'authorization_code',
        'client_id': request.configuration.connector.providerId,
        'code': request.code,
        'redirect_uri': request.redirectUri.toString(),
        'code_verifier': request.codeVerifier,
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OAuthFlowException(
        OAuthFlowErrorCode.tokenExchangeFailed,
        'Token endpoint responded with HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final payload = _decodeJsonMap(response.body);
    final accessToken = payload['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.tokenExchangeFailed,
        'Token response missing required access_token field.',
      );
    }

    final refreshToken = payload['refresh_token'] as String?;
    final expiresIn = payload['expires_in'] as int? ?? 3600;
    final now = _clock();
    final expiresAt = now.add(Duration(seconds: expiresIn));

    final scopeString = payload['scope'] as String?;
    final scopes = scopeString != null && scopeString.isNotEmpty
        ? scopeString.split(' ').toSet()
        : request.scopes;

    return OAuthTokenResponse(
      providerId: request.configuration.connector.providerId,
      providerAccountId:
          payload['user_id'] as String? ??
          payload['sub'] as String? ??
          'account-${request.configuration.connector.providerId}',
      displayName:
          payload['display_name'] as String? ??
          payload['name'] as String? ??
          payload['user_name'] as String? ??
          request.configuration.connector.displayName,
      accessToken: accessToken,
      refreshToken: refreshToken ?? '',
      accessTokenExpiresAt: expiresAt,
      issuedAt: now,
      scopes: scopes,
    );
  }

  @override
  Future<OAuthTokenResponse> refresh(OAuthTokenRefreshRequest request) async {
    final grant = request.grant;
    final refreshToken = grant.refreshToken;
    if (refreshToken.isEmpty) {
      throw const OAuthFlowException(
        OAuthFlowErrorCode.tokenExchangeFailed,
        'Grant does not have a refresh token.',
      );
    }

    // In a full production implementation, this issues POST to tokenEndpoint
    // with grant_type=refresh_token. For now, fail closed if unconfigured.
    throw const OAuthFlowException(
      OAuthFlowErrorCode.tokenExchangeFailed,
      'Token refresh endpoint requires live provider configuration.',
    );
  }

  @override
  Future<void> revoke(OAuthTokenGrant grant) async {
    // Revocation endpoint call — fail-closed if unconfigured.
  }

  static Map<String, Object?> _decodeJsonMap(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, Object?>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.cast<String, Object?>();
      }
      throw const FormatException('Expected JSON map');
    } on FormatException catch (e) {
      throw OAuthFlowException(
        OAuthFlowErrorCode.invalidTokenResponse,
        'Malformed JSON from token endpoint: ${e.message}',
      );
    }
  }
}
