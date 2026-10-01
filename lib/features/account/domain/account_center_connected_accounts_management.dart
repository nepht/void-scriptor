/// Sprint 115.14 — Connected Accounts Management.
///
/// Local management seam for linked identities. It owns labels, scope review,
/// reauthentication intent, unlink confirmation, and caller-provided health
/// observations; it performs no network calls and stores no credentials.
library;

import 'account_center_connection_health_state_machine.dart';

final class AccountConnectedAccount {
  AccountConnectedAccount({
    required String connectionId,
    required String providerId,
    required String accountLabel,
    required Iterable<String> scopes,
    required this.connectionState,
    required this.healthState,
    required this.lastCheckedAt,
    required this.reauthRequired,
  }) : connectionId = _required(connectionId, 'connectionId'),
       providerId = _required(providerId, 'providerId').toLowerCase(),
       accountLabel = _required(accountLabel, 'accountLabel'),
       scopes = _normalizeScopes(scopes);

  final String connectionId;
  final String providerId;
  final String accountLabel;
  final Set<String> scopes;
  final AccountConnectionState connectionState;
  final AccountHealthState healthState;
  final DateTime? lastCheckedAt;
  final bool reauthRequired;

  AccountConnectedAccount copyWith({
    String? accountLabel,
    AccountConnectionState? connectionState,
    AccountHealthState? healthState,
    DateTime? lastCheckedAt,
    bool? reauthRequired,
  }) => AccountConnectedAccount(
    connectionId: connectionId,
    providerId: providerId,
    accountLabel: accountLabel ?? this.accountLabel,
    scopes: scopes,
    connectionState: connectionState ?? this.connectionState,
    healthState: healthState ?? this.healthState,
    lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
    reauthRequired: reauthRequired ?? this.reauthRequired,
  );

  static String _required(String value, String field) {
    final normalized = value.trim();
    if (normalized.isEmpty) throw ArgumentError.value(value, field);
    return normalized;
  }

  static Set<String> _normalizeScopes(Iterable<String> values) {
    final normalized = values
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    if (normalized.isEmpty) throw ArgumentError.value(values, 'scopes');
    return Set<String>.unmodifiable(normalized);
  }
}

final class AccountReauthenticationRequest {
  const AccountReauthenticationRequest({
    required this.connectionId,
    required this.providerId,
    required this.scopes,
  });

  final String connectionId;
  final String providerId;
  final Set<String> scopes;
}

/// Outcome of a disconnect attempt on [AccountConnectedAccountsManagement].
///
/// A local disconnect has three honest outcomes, and collapsing them into a
/// single `bool` is what made the disconnect path unmeasurable: measured,
/// `unlink(confirmed: true)` returned `true` in every case, so a row whose
/// provider was revoked and a row whose provider was never told looked the same
/// to every caller and to every test.
final class AccountDisconnectResult {
  AccountDisconnectResult({
    required this.connectionId,
    required this.localRemoved,
    required this.providerRevokeAttempted,
    required this.providerRevoked,
    this.providerRevokeError,
  }) {
    if (!providerRevokeAttempted && providerRevoked) {
      throw ArgumentError.value(
        providerRevoked,
        'providerRevoked',
        'A revocation cannot be confirmed without attempting it.',
      );
    }
  }

  final String connectionId;

  /// Whether the local link was dropped.
  final bool localRemoved;

  /// Whether a provider call was actually made for this decision.
  final bool providerRevokeAttempted;

  /// Whether the provider confirmed the revocation.
  ///
  /// `false` for a `keepLinked` decision and for a declared-absent revoker
  /// (disconnect without provider call), which is not the same as "tried and
  /// failed": see [providerRevokeAttempted].
  final bool providerRevoked;

  /// Why the revocation failed, when it was attempted and did not succeed.
  final Object? providerRevokeError;

  /// The local link is gone and nothing was left half-done at the provider.
  bool get isComplete => localRemoved && providerRevoked;

  /// The local link is gone but the provider still holds a live grant.
  ///
  /// This is the state that must not be reported as a finished disconnect: the
  /// token remains usable at the provider until the revocation is retried.
  bool get needsProviderRetry =>
      localRemoved && providerRevokeAttempted && !providerRevoked;

  /// Text a caller can show without leaking provider internals.
  String get summary => providerRevokeAttempted
      ? localRemoved
            ? providerRevoked
                  ? 'Disconnected and revoked at $connectionId.'
                  : 'Disconnected locally; the provider revocation at '
                        '$connectionId did not complete and can be retried.'
            : 'The link was kept: the provider revocation at $connectionId '
                  'failed.'
      : localRemoved
      ? 'Disconnected locally at $connectionId; no provider call was made.'
      : 'The link at $connectionId was kept.';

  Map<String, Object?> toJson() => <String, Object?>{
    'connection_id': connectionId,
    'local_removed': localRemoved,
    'provider_revoked': providerRevoked,
    'provider_revoke_attempted': providerRevokeAttempted,
    'provider_revoke_failed': providerRevokeAttempted && !providerRevoked,
    'needs_provider_retry': needsProviderRetry,
    if (providerRevokeError != null)
      'provider_revoke_error': providerRevokeError.runtimeType.toString(),
    'summary': summary,
  };

  @override
  String toString() => summary;
}

/// Requests a provider-side revocation for a connection being disconnected.
typedef AccountProviderRevoker =
    Future<bool> Function(String connectionId, String providerId);

final class AccountConnectedAccountsManagement {
  AccountConnectedAccountsManagement({
    Iterable<AccountConnectedAccount>? initial,
    // `prefer_initializing_formals` is suppressed on the initializer below:
    // Dart forbids `this._providerRevoker` in a *named* parameter list, and
    // the public parameter must keep the name `providerRevoker` because eight
    // call sites pass it by that name. The initializing formal the lint asks
    // for cannot be written without breaking that API.
    AccountProviderRevoker? providerRevoker,
    // ignore: prefer_initializing_formals
  }) : _providerRevoker = providerRevoker {
    for (final account in initial ?? const <AccountConnectedAccount>[]) {
      add(account);
    }
  }

  final AccountProviderRevoker? _providerRevoker;

  /// Whether this seam can revoke at the provider at all.
  ///
  /// Declared-absent means the caller supplied no revoker, so a disconnect is
  /// local-only by construction rather than by accident. That distinction is
  /// what [AccountDisconnectResult.providerRevokeAttempted] reports.
  bool get canRevokeAtProvider => _providerRevoker != null;

  final Map<String, AccountConnectedAccount> _accounts =
      <String, AccountConnectedAccount>{};

  List<AccountConnectedAccount> get connections =>
      List<AccountConnectedAccount>.unmodifiable(_accounts.values);

  void add(AccountConnectedAccount account) {
    if (_accounts.containsKey(account.connectionId)) {
      throw ArgumentError.value(
        account.connectionId,
        'connectionId',
        'Connection already exists.',
      );
    }
    _accounts[account.connectionId] = account;
  }

  AccountConnectedAccount rename({
    required String connectionId,
    required String label,
  }) {
    final account = _require(connectionId);
    final renamed = account.copyWith(accountLabel: label);
    _accounts[connectionId] = renamed;
    return renamed;
  }

  Set<String> scopeReview(String connectionId) =>
      Set<String>.unmodifiable(_require(connectionId).scopes);

  AccountReauthenticationRequest reauthenticate(String connectionId) {
    final account = _require(connectionId);
    _accounts[connectionId] = account.copyWith(reauthRequired: true);
    return AccountReauthenticationRequest(
      connectionId: account.connectionId,
      providerId: account.providerId,
      scopes: Set<String>.unmodifiable(account.scopes),
    );
  }

  /// Disconnects a connection, reporting whether the provider was actually told.
  ///
  /// The old signature returned a bare `bool` that was `true` for every
  /// confirmed disconnect, so a caller could not tell a revoked-at-provider row
  /// from a local-only deletion, and the disconnect path produced no audit
  /// evidence of the provider call at all. `confirmed: false` is still a no-op,
  /// now reported as such instead of silently returning `false`.
  Future<AccountDisconnectResult> unlink(
    String connectionId, {
    required bool confirmed,
    bool revokeAtProvider = true,
  }) async {
    if (!confirmed) {
      return AccountDisconnectResult(
        connectionId: connectionId,
        localRemoved: false,
        providerRevokeAttempted: false,
        providerRevoked: false,
      );
    }
    final account = _require(connectionId);
    final revoker = _providerRevoker;
    if (!revokeAtProvider || revoker == null) {
      // Disconnect without a provider call is a declared outcome, not a silent
      // one: the caller asked for a local drop and the result says the provider
      // was never told, so nobody can read this row as a revoked token.
      _accounts.remove(connectionId);
      return AccountDisconnectResult(
        connectionId: connectionId,
        localRemoved: true,
        providerRevokeAttempted: false,
        providerRevoked: false,
      );
    }
    Object? failure;
    var revoked = false;
    try {
      revoked = await revoker(connectionId, account.providerId);
    } catch (error) {
      failure = error;
    }
    if (revoked) {
      _accounts.remove(connectionId);
    }
    // A revocation that did not happen leaves the local link in place: dropping
    // it anyway would strand a live grant at the provider with no row left to
    // retry from, which is the opposite of a clean disconnect.
    return AccountDisconnectResult(
      connectionId: connectionId,
      localRemoved: revoked,
      providerRevokeAttempted: true,
      providerRevoked: revoked,
      providerRevokeError: failure,
    );
  }

  AccountConnectedAccount recordHealthCheck(
    String connectionId, {
    required AccountHealthState healthState,
    required DateTime checkedAt,
  }) {
    final account = _require(connectionId);
    final connectionState = switch (healthState) {
      AccountHealthState.healthy ||
      AccountHealthState.rateLimited => AccountConnectionState.connected,
      AccountHealthState.degraded => AccountConnectionState.degraded,
      AccountHealthState.outage => AccountConnectionState.unavailable,
      AccountHealthState.unknown => account.connectionState,
    };
    // A health observation is itself the proof that the provider answered with
    // the token it is being asked about, so it clears a pending reauthentication
    // request. Leaving the flag set here made a satisfied request indistinguishable
    // from an outstanding one, and the banner asking the user to reauthenticate
    // for a connection that demonstrably works never went away. 115.10 already
    // clears `reauthRequired` on every health refresh; this seam did not.
    final checked = account.copyWith(
      connectionState: connectionState,
      healthState: healthState,
      lastCheckedAt: checkedAt.toUtc(),
      reauthRequired: false,
    );
    _accounts[connectionId] = checked;
    return checked;
  }

  AccountConnectedAccount _require(String connectionId) {
    final account = _accounts[connectionId];
    if (account == null) throw StateError('Unknown connection: $connectionId');
    return account;
  }
}
