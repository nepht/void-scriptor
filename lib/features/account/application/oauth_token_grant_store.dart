import '../../../core/security/credential_store.dart';
import '../domain/account_center_oauth_linked_identity_flow.dart';

/// Secure persistence boundary for OAuth grants.
///
/// Each field is stored separately so a future migration can rotate or remove
/// one secret without serializing a complete credential object into logs or
/// general application state. Values are never returned as diagnostics.
final class OAuthTokenGrantStore {
  OAuthTokenGrantStore({required this._store});

  final CredentialStore _store;

  static String _prefix(String connectionId) =>
      'oauth.grant.${connectionId.trim()}';

  Future<void> write(OAuthTokenGrant grant) async {
    final prefix = _prefix(grant.connectionId);
    await _store.write(key: '$prefix.provider_id', value: grant.providerId);
    await _store.write(key: '$prefix.access_token', value: grant.accessToken);
    await _store.write(key: '$prefix.refresh_token', value: grant.refreshToken);
    await _store.write(
      key: '$prefix.expires_at',
      value: grant.accessTokenExpiresAt.toUtc().toIso8601String(),
    );
    await _store.write(
      key: '$prefix.supports_refresh',
      value: grant.supportsRefresh.toString(),
    );
    await _store.write(
      key: '$prefix.scopes',
      value: (grant.scopes.toList()..sort()).join(' '),
    );
    await _store.write(
      key: '$prefix.generation',
      value: grant.generation.toString(),
    );
  }

  Future<void> delete(String connectionId) async {
    final prefix = _prefix(connectionId);
    for (final suffix in <String>[
      'provider_id',
      'access_token',
      'refresh_token',
      'expires_at',
      'supports_refresh',
      'scopes',
      'generation',
    ]) {
      await _store.delete('$prefix.$suffix');
    }
  }
}
