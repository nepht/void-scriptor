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

  /// The public client ID supplied by the release configuration.
  ///
  /// A desktop OAuth client ID is not a secret, but it must still come from
  /// the operator's Google Cloud project rather than from a guessed literal.
  /// The corresponding client secret must never be shipped in this app.
  static const String _managedGoogleDriveClientId = String.fromEnvironment(
    'VOID_GOOGLE_DRIVE_CLIENT_ID',
  );

  static String keyFor(String providerId) =>
      'oauth.client_id.${providerId.trim().toLowerCase()}';

  /// Returns the build-managed public client ID for a supported provider.
  ///
  /// The value is intentionally not exposed for providers that do not have a
  /// managed release configuration. Empty build values fail closed.
  static String? managedClientIdFor(String providerId) {
    if (providerId.trim().toLowerCase() != 'google_drive') return null;
    final normalized = _managedGoogleDriveClientId.trim();
    return normalized.isEmpty ? null : normalized;
  }

  bool hasManagedClientId(String providerId) =>
      managedClientIdFor(providerId) != null;

  Future<String?> readClientId(String providerId) async {
    final managed = managedClientIdFor(providerId);
    if (managed != null) return managed;
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

typedef OAuthProcessRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments);

typedef OAuthPlatformCheck = bool Function();

/// Opens the system browser without shell parsing or exposing OAuth values to
/// logs. `rundll32` receives the URL as one direct argument, so query
/// separators such as `&` cannot be interpreted as command operators.
final class WindowsOAuthBrowserLauncher implements OAuthBrowserLauncher {
  const WindowsOAuthBrowserLauncher({this.processRunner, this.platformCheck});

  final OAuthProcessRunner? processRunner;
  final OAuthPlatformCheck? platformCheck;

  @override
  Future<bool> launch(Uri authorizationUri) async {
    if (!(platformCheck?.call() ?? Platform.isWindows) ||
        authorizationUri.scheme != 'https') {
      return false;
    }
    final result = await (processRunner ?? _runProcess)(
      'rundll32.exe',
      <String>['url.dll,FileProtocolHandler', authorizationUri.toString()],
    );
    return result.exitCode == 0;
  }

  static Future<ProcessResult> _runProcess(
    String executable,
    List<String> arguments,
  ) => Process.run(executable, arguments, runInShell: false);
}
