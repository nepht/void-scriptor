import 'dart:io';

import '../../../core/security/credential_store.dart';

/// Securely resolves registered public OAuth client IDs.
///
/// Client IDs are configuration, not secrets, but they are still kept out of
/// source code so the same build can be configured per deployment. Secrets and
/// tokens must never be handled by this class.
final class OAuthClientConfigurationStore {
  OAuthClientConfigurationStore({required this._store});

  final CredentialStore _store;

  static String keyFor(String providerId) =>
      'oauth.client_id.${providerId.trim().toLowerCase()}';

  Future<String?> readClientId(String providerId) async {
    final value = await _store.read(keyFor(providerId));
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  Future<void> writeClientId({
    required String providerId,
    required String clientId,
  }) async {
    final normalized = clientId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(clientId, 'clientId', 'Client ID is required.');
    }
    await _store.write(key: keyFor(providerId), value: normalized);
  }

  Future<void> deleteClientId(String providerId) =>
      _store.delete(keyFor(providerId));
}

abstract interface class OAuthBrowserLauncher {
  Future<bool> launch(Uri authorizationUri);
}

/// Opens the system browser without exposing OAuth values to logs.
final class WindowsOAuthBrowserLauncher implements OAuthBrowserLauncher {
  const WindowsOAuthBrowserLauncher();

  @override
  Future<bool> launch(Uri authorizationUri) async {
    if (!Platform.isWindows || authorizationUri.scheme != 'https') return false;
    final result = await Process.run('cmd.exe', <String>[
      '/c',
      'start',
      '',
      authorizationUri.toString(),
    ], runInShell: false);
    return result.exitCode == 0;
  }
}
