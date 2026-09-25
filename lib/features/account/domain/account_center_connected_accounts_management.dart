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

final class AccountConnectedAccountsManagement {
  AccountConnectedAccountsManagement([
    Iterable<AccountConnectedAccount>? initial,
  ]) {
    for (final account in initial ?? const <AccountConnectedAccount>[]) {
      add(account);
    }
  }

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

  bool unlink(String connectionId, {required bool confirmed}) {
    if (!confirmed) return false;
    _require(connectionId);
    _accounts.remove(connectionId);
    return true;
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
    final checked = account.copyWith(
      connectionState: connectionState,
      healthState: healthState,
      lastCheckedAt: checkedAt.toUtc(),
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
