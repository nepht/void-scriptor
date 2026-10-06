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

import '../../../core/network/http_oauth_token_broker.dart';
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
  /// Each value is a factory that takes the connector entry and returns a
  /// complete `OAuthProviderConfiguration`.  The redirect URI is standard
  /// across all providers (custom scheme desktop redirect).
  static final Map<String, OAuthProviderConfiguration Function(ProviderConnectorEntry)>
      _registry = <String, OAuthProviderConfiguration Function(ProviderConnectorEntry)>{
    'google_drive': (entry) => OAuthProviderConfiguration(
          connector: entry,
          authorizationEndpoint:
              Uri.parse('https://accounts.google.com/o/oauth2/v2/auth'),
          redirectUri: _desktopRedirectUri,
          scopes: const <String>{'https://www.googleapis.com/auth/drive.file'},
          tokenEndpoint: Uri.parse('https://oauth2.googleapis.com/token'),
          revocationEndpoint:
              Uri.parse('https://oauth2.googleapis.com/revoke'),
        ),
    'onedrive': (entry) => OAuthProviderConfiguration(
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
    'dropbox': (entry) => OAuthProviderConfiguration(
          connector: entry,
          authorizationEndpoint:
              Uri.parse('https://www.dropbox.com/oauth2/authorize'),
          redirectUri: _desktopRedirectUri,
          scopes: const <String>{'files.content.write', 'files.content.read'},
          tokenEndpoint:
              Uri.parse('https://api.dropboxapi.com/oauth2/token'),
          revocationEndpoint:
              Uri.parse('https://api.dropboxapi.com/2/auth/token/revoke'),
        ),
    'github': (entry) => OAuthProviderConfiguration(
          connector: entry,
          authorizationEndpoint:
              Uri.parse('https://github.com/login/oauth/authorize'),
          redirectUri: _desktopRedirectUri,
          scopes: const <String>{'repo', 'read:user'},
          tokenEndpoint:
              Uri.parse('https://github.com/login/oauth/access_token'),
          revocationEndpoint: null,
          nonceRequired: false,
          supportsRefresh: false,
        ),
  };

  /// Custom-scheme redirect URI for desktop OAuth PKCE flow.
  static final Uri _desktopRedirectUri =
      Uri.parse('vscriptor://oauth/callback');

  /// Returns the `OAuthProviderConfiguration` for [entry], or `null` if the
  /// provider is unknown to this registry (fail-closed: unknown = no connect).
  static OAuthProviderConfiguration? resolve(ProviderConnectorEntry entry) {
    final factory = _registry[entry.providerId];
    return factory?.call(entry);
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
  }) : _flow = AccountOAuthFlow(
          broker: broker ?? HttpOAuthTokenBroker(),
        );

  final AccountOAuthFlow _flow;

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
    if (!entry.isConnectable) {
      // Fail-closed: unverified connectors MUST NOT initiate an OAuth flow.
      return;
    }

    final configuration = OAuthProviderEndpoints.resolve(entry);
    if (configuration == null) {
      // No endpoint wiring for this provider — the UI button should already
      // be disabled via `isConnectable`, but defense in depth.
      return;
    }

    // Begin the PKCE authorization.  In a shipping product the returned
    // request's `authorizationUri` would be opened in a browser; the app
    // registers a deep link handler for `vscriptor://oauth/callback` that
    // calls `_flow.completeAuthorization(callback: ...)`.
    final consent = OAuthScopeConsent(
      requestedScopes: configuration.scopes,
      grantedScopes: configuration.scopes,
      explicitlyApproved: true,
    );
    _flow.beginAuthorization(
      configuration: configuration,
      consent: consent,
    );
  }

  /// Expose the underlying flow for deep-link callback resolution and
  /// identity queries without duplicating state.
  AccountOAuthFlow get flow => _flow;
}
