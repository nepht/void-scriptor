/// 117.46 — Wiring layer that connects the OAuth runtime machinery
/// (`HttpOAuthTokenBroker` ↔ `AccountOAuthFlow`) to the presentation layer
/// callback surface (`AccountCloudCenterScreen.onConnectProvider`).
///
/// Responsibilities:
///  1. Resolve a `ProviderConnectorEntry` into a valid
///     `OAuthProviderConfiguration` (provider-agnostic mapping).
///  2. Instantiate `AccountOAuthFlow` with the correct `OAuthTokenBroker`
///     (default `HttpOAuthTokenBroker` for production, injectable for test).
///  3. Expose a single `onConnectProvider` callback ready for the router.
///
/// This is deliberately a thin application layer — no framework dependency
/// except the domain types it glues.  Widget tests that pump
/// `AccountCloudCenterScreen` without this wiring remain valid because the
/// screen's `onConnectProvider` parameter stays optional and null-safe.
library;

import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'http_oauth_token_broker.dart';
import 'oauth_client_configuration.dart';
import 'oauth_token_grant_store.dart';
import '../../../core/security/credential_store.dart';
import '../domain/account_center_oauth_linked_identity_flow.dart';
import '../domain/account_center_provider_connector_manifest.dart';

/// Registry of known OAuth endpoints per `providerId`.
///
/// GA release ships with all 32 connectors `UNVERIFIED`; the entries here are
/// the *structural* wiring that will be used once a connector passes live
/// certification.  Adding an entry does NOT make a connector available to the
/// user — `ProviderConnectorEntry.isConnectable` gates the UI button.
final class OAuthProviderEndpoints {
  const OAuthProviderEndpoints._();

  /// Well-known OAuth2 endpoints indexed by `providerId` (lowercase).
  ///
  /// Client IDs are injected separately and are never inferred from providerId.
  static final Map<
    String,
    OAuthProviderConfiguration Function(ProviderConnectorEntry, String?)
  >
  _registry =
      <
        String,
        OAuthProviderConfiguration Function(ProviderConnectorEntry, String?)
      >{
        'google_drive': (entry, clientId) => OAuthProviderConfiguration(
          clientId: clientId,
          connector: entry,
          authorizationEndpoint: Uri.parse(
            'https://accounts.google.com/o/oauth2/v2/auth',
          ),
          redirectUri: _desktopRedirectUri,
          scopes: const <String>{'https://www.googleapis.com/auth/drive.file'},
          tokenEndpoint: Uri.parse('https://oauth2.googleapis.com/token'),
          revocationEndpoint: Uri.parse('https://oauth2.googleapis.com/revoke'),
        ),
        'onedrive': (entry, clientId) => OAuthProviderConfiguration(
          clientId: clientId,
          connector: entry,
          authorizationEndpoint: Uri.parse(
            'https://login.microsoftonline.com/common/oauth2/v2.0/authorize',
          ),
          redirectUri: _desktopRedirectUri,
          scopes: const <String>{'Files.ReadWrite.All', 'offline_access'},
          tokenEndpoint: Uri.parse(
            'https://login.microsoftonline.com/common/oauth2/v2.0/token',
          ),
          revocationEndpoint: null,
          supportsRefresh: true,
        ),
        'dropbox': (entry, clientId) => OAuthProviderConfiguration(
          clientId: clientId,
          connector: entry,
          authorizationEndpoint: Uri.parse(
            'https://www.dropbox.com/oauth2/authorize',
          ),
          redirectUri: _desktopRedirectUri,
          scopes: const <String>{'files.content.write', 'files.content.read'},
          tokenEndpoint: Uri.parse('https://api.dropboxapi.com/oauth2/token'),
          revocationEndpoint: Uri.parse(
            'https://api.dropboxapi.com/2/auth/token/revoke',
          ),
        ),
        'github': (entry, clientId) => OAuthProviderConfiguration(
          clientId: clientId,
          connector: entry,
          authorizationEndpoint: Uri.parse(
            'https://github.com/login/oauth/authorize',
          ),
          redirectUri: _desktopRedirectUri,
          scopes: const <String>{'repo', 'read:user'},
          tokenEndpoint: Uri.parse(
            'https://github.com/login/oauth/access_token',
          ),
          revocationEndpoint: null,
          nonceRequired: false,
          supportsRefresh: false,
        ),
      };

  /// Custom-scheme redirect URI for desktop OAuth PKCE flow.
  static final Uri _desktopRedirectUri = Uri.parse(
    'vscriptor://oauth/callback',
  );

  /// Returns the `OAuthProviderConfiguration` for [entry], or `null` if the
  /// provider is unknown to this registry (fail-closed: unknown = no connect).
  static OAuthProviderConfiguration? resolve(
    ProviderConnectorEntry entry, {
    String? clientId,
  }) {
    final factory = _registry[entry.providerId];
    return factory?.call(entry, clientId);
  }

  /// Whether the registry contains wiring for [providerId].
  static bool isKnown(String providerId) => _registry.containsKey(providerId);
}

/// Application-layer glue that produces the `onConnectProvider` callback
/// consumed by `AccountCloudCenterScreen`.
///
/// Usage in the router:
/// ```dart
/// final wiring = AccountCloudConnectWiring();
/// AccountCloudCenterScreen(
///   onConnectProvider: wiring.onConnectProvider,
/// )
/// ```
final class AccountCloudConnectWiring {
  AccountCloudConnectWiring({
    OAuthTokenBroker? broker,
    CredentialStore? credentialStore,
    OAuthBrowserLauncher? browserLauncher,
    OAuthTokenGrantStore? grantStore,
  }) : _flow = AccountOAuthFlow(broker: broker ?? HttpOAuthTokenBroker()),
       _clientConfiguration = OAuthClientConfigurationStore(
         store:
             credentialStore ??
             const SecureCredentialStore(FlutterSecureStorage()),
       ),
       _grantStore =
           grantStore ??
           OAuthTokenGrantStore(
             store:
                 credentialStore ??
                 const SecureCredentialStore(FlutterSecureStorage()),
           ),
       _browserLauncher =
           browserLauncher ?? const WindowsOAuthBrowserLauncher();

  final AccountOAuthFlow _flow;
  final OAuthClientConfigurationStore _clientConfiguration;
  final OAuthTokenGrantStore _grantStore;
  final OAuthBrowserLauncher _browserLauncher;

  /// Registers a public OAuth client ID through the secure configuration path.
  /// The value is never logged or included in application source.
  Future<void> setClientId({
    required String providerId,
    required String clientId,
  }) => _clientConfiguration.writeClientId(
    providerId: providerId,
    clientId: clientId,
  );

  Future<OAuthAuthorizationRequest?> _startAuthorization(
    ProviderConnectorEntry entry,
  ) async {
    if (!entry.isConnectable ||
        !OAuthProviderEndpoints.isKnown(entry.providerId)) {
      return null;
    }
    final clientId = await _clientConfiguration.readClientId(entry.providerId);
    final configuration = OAuthProviderEndpoints.resolve(
      entry,
      clientId: clientId,
    );
    if (configuration == null || configuration.clientId == null) return null;
    final consent = OAuthScopeConsent(
      requestedScopes: configuration.scopes,
      grantedScopes: configuration.scopes,
      explicitlyApproved: true,
    );
    final request = _flow.beginAuthorization(
      configuration: configuration,
      consent: consent,
    );
    if (!await _browserLauncher.launch(request.authorizationUri)) return null;
    return request;
  }

  /// The callback that bridges presentation → domain.
  ///
  /// When the user taps "Connect" on a provider tile, the screen calls this
  /// with the `ProviderConnectorEntry`.  This method:
  ///
  /// 1. Resolves the entry to an `OAuthProviderConfiguration` (or returns
  ///    early when the provider has no endpoint wiring).
  /// 2. Guards against connectors that are not yet certifiably available.
  /// 3. Creates an `OAuthScopeConsent` from the resolved configuration and
  ///    begins the authorization.
  ///
  /// The returned `OAuthAuthorizationRequest` carries the authorization URL
  /// the presentation layer can open in a browser / webview.
  void onConnectProvider(ProviderConnectorEntry entry) {
    // Presentation callbacks are intentionally fire-and-forget. The async
    // boundary protects the UI from blocking while the secure store is read.
    unawaited(_startAuthorization(entry));
  }

  /// Completes the currently pending OAuth request and persists the resulting
  /// grant through the injected secure store.
  Future<LinkedIdentityResult> completeAuthorization({
    required Uri callback,
  }) async {
    final result = await _flow.completeAuthorization(callback: callback);
    await _grantStore.write(result.tokenGrant);
    return result;
  }

  /// Revokes the active grant remotely before deleting its local secret record.
  Future<void> disconnect(OAuthTokenGrant grant) async {
    await _flow.unlink(grant: grant, decision: OAuthUnlinkDecision.unlink);
    await _grantStore.delete(grant.connectionId);
  }

  /// Expose the underlying flow for deep-link callback resolution and
  /// identity queries without duplicating state.
  AccountOAuthFlow get flow => _flow;
}
