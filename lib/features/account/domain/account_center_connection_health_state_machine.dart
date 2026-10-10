/// Sprint 115.10 — Connection & Health State Machine.
///
/// A local, dependency-free state model for provider connections. The model
/// records states and user-visible recovery paths; it does not perform network
/// calls, store credentials, or claim that a provider is healthy.
library;

import 'dart:convert';

/// Canonical connection states from the Account & Cloud Center product spec.
enum AccountConnectionState {
  notConfigured('NOT_CONFIGURED'),
  connecting('CONNECTING'),
  connected('CONNECTED'),
  degraded('DEGRADED'),
  expired('EXPIRED'),
  revoked('REVOKED'),
  error('ERROR'),
  unavailable('UNAVAILABLE');

  const AccountConnectionState(this.wireName);

  final String wireName;
}

/// Canonical health states from the Account & Cloud Center product spec.
enum AccountHealthState {
  unknown('UNKNOWN'),
  healthy('HEALTHY'),
  degraded('DEGRADED'),
  outage('OUTAGE'),
  rateLimited('RATE_LIMITED'),
  latency('LATENCY');

  const AccountHealthState(this.wireName);

  final String wireName;
}

/// Explicit events accepted by [AccountConnectionHealthStateMachine].
///
/// Events are deliberately named instead of exposing arbitrary state writes;
/// callers cannot skip `CONNECTING` or turn a revoked connection back on
/// without creating a new connection configuration.
enum AccountConnectionTransition {
  beginConnecting('BEGIN_CONNECTING'),
  connectSucceeded('CONNECT_SUCCEEDED'),
  error('ERROR'),
  unavailable('UNAVAILABLE'),
  expire('EXPIRE'),
  revoke('REVOKE'),
  refreshHealth('REFRESH_HEALTH'),
  reauthenticate('REAUTHENTICATE'),
  retry('RETRY'),
  disconnectCleanup('DISCONNECT_CLEANUP');

  const AccountConnectionTransition(this.wireName);

  final String wireName;
}

/// Bounded retry policy for transient connection failures.
class AccountConnectionRetryPolicy {
  AccountConnectionRetryPolicy({this.maxAttempts = 3}) {
    if (maxAttempts <= 0) {
      throw ArgumentError.value(
        maxAttempts,
        'maxAttempts',
        'Retry attempts must be greater than zero.',
      );
    }
  }

  final int maxAttempts;
}

/// Immutable status surface consumed by Account Center surfaces.
///
/// The error text is intentionally separate from the state and is generated
/// from a redacted, non-secret explanation. The model never stores tokens,
/// API keys, passwords, or raw provider responses.
class AccountConnectionHealthSnapshot {
  const AccountConnectionHealthSnapshot({
    required this.providerId,
    required this.accountLabel,
    required this.connectionState,
    required this.healthState,
    required this.connectorVersion,
    required this.reauthRequired,
    required this.retryAttempt,
    this.lastCheckedAt,
    this.userVisibleError,
    this.errorCode,
  });

  final String providerId;
  final String accountLabel;
  final AccountConnectionState connectionState;
  final AccountHealthState healthState;
  final DateTime? lastCheckedAt;
  final bool reauthRequired;
  final String connectorVersion;
  final int retryAttempt;
  final String? userVisibleError;
  final String? errorCode;

  /// Text is always present for states where a user needs an explanation or
  /// recovery action. Health overrides the base connection label when a
  /// provider reports rate limiting, degradation, or an outage.
  String get statusLabel {
    switch (healthState) {
      case AccountHealthState.rateLimited:
        return 'Rate limited';
      case AccountHealthState.latency:
        return 'High latency';
      case AccountHealthState.outage:
        return 'Provider outage';
      case AccountHealthState.degraded:
        return 'Degraded';
      case AccountHealthState.healthy:
      case AccountHealthState.unknown:
        break;
    }
    switch (connectionState) {
      case AccountConnectionState.notConfigured:
        return 'Not configured';
      case AccountConnectionState.connecting:
        return 'Connecting';
      case AccountConnectionState.connected:
        return 'Connected';
      case AccountConnectionState.degraded:
        return 'Degraded';
      case AccountConnectionState.expired:
        return 'Connection expired';
      case AccountConnectionState.revoked:
        return 'Connection revoked';
      case AccountConnectionState.error:
        return 'Connection error';
      case AccountConnectionState.unavailable:
        return 'Provider unavailable';
    }
  }

  AccountConnectionHealthSnapshot copyWith({
    AccountConnectionState? connectionState,
    AccountHealthState? healthState,
    DateTime? lastCheckedAt,
    bool clearLastCheckedAt = false,
    bool? reauthRequired,
    String? connectorVersion,
    int? retryAttempt,
    String? userVisibleError,
    String? errorCode,
    bool clearError = false,
  }) => AccountConnectionHealthSnapshot(
    providerId: providerId,
    accountLabel: accountLabel,
    connectionState: connectionState ?? this.connectionState,
    healthState: healthState ?? this.healthState,
    lastCheckedAt: clearLastCheckedAt
        ? null
        : lastCheckedAt ?? this.lastCheckedAt,
    reauthRequired: reauthRequired ?? this.reauthRequired,
    connectorVersion: connectorVersion ?? this.connectorVersion,
    retryAttempt: retryAttempt ?? this.retryAttempt,
    userVisibleError: clearError
        ? null
        : userVisibleError ?? this.userVisibleError,
    errorCode: clearError ? null : errorCode ?? this.errorCode,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'provider_id': providerId,
    'account_label': accountLabel,
    'connection_state': connectionState.wireName,
    'health_state': healthState.wireName,
    'last_checked_at': lastCheckedAt?.toUtc().toIso8601String(),
    'reauth_required': reauthRequired,
    'connector_version': connectorVersion,
    'retry_attempt': retryAttempt,
    'user_visible_error': userVisibleError,
    'error_code': errorCode,
  };

  @override
  String toString() => jsonEncode(toJson());
}

/// Mutable per-connection state machine.
///
/// The machine owns mutable state per instance. It intentionally has no
/// static connection map: two accounts with the same provider must never share
/// health, retry, or reauthentication state.
class AccountConnectionHealthStateMachine {
  AccountConnectionHealthStateMachine._(this._snapshot, this._retryPolicy);

  factory AccountConnectionHealthStateMachine.notConfigured({
    required String providerId,
    required String accountLabel,
    String? connectorVersion,
    AccountConnectionRetryPolicy? retryPolicy,
  }) {
    final normalizedProviderId = _normalizeProviderId(providerId);
    final normalizedLabel = _normalizeText(accountLabel, field: 'accountLabel');
    final policy = retryPolicy ?? AccountConnectionRetryPolicy();
    return AccountConnectionHealthStateMachine._(
      AccountConnectionHealthSnapshot(
        providerId: normalizedProviderId,
        accountLabel: normalizedLabel,
        connectionState: AccountConnectionState.notConfigured,
        healthState: AccountHealthState.unknown,
        connectorVersion: _normalizeText(
          connectorVersion ?? 'manifest-v1',
          field: 'connectorVersion',
        ),
        reauthRequired: false,
        retryAttempt: 0,
      ),
      policy,
    );
  }

  static const String manifestPath =
      'docs/planning/v1.2/sprint_115_connection_health_state_machine.json';
  static const String canonicalSprintPath =
      'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/'
      'sprint_115.json';
  static const String canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';
  static const String productSpecDocument =
      'C:/Users/nepht/Documents/Codex/2026-08-22/'
      'referenced-chatgpt-conversation-this-is-an-2/outputs/'
      'account_cloud_center_spec.json';
  static const String productSpecSha256 =
      'f0589fe77428b94a608f44939df8bbd599e11b45d8605c59866ddaede99bd88a';
  static const String connectorSdkDocument =
      'C:/Users/nepht/Documents/Codex/2026-08-22/'
      'referenced-chatgpt-conversation-this-is-an-2/outputs/'
      'connector_sdk_spec.json';
  static const String connectorSdkSha256 =
      '052e8b240f772887bf39ce1337cef2919e52251e59c569440403cd6aa41528dc';

  static const List<String> canonicalAcceptance = <String>[
    'state_transitions',
    'retry_policy',
    'reauth_path',
    'revoke_path',
    'health_refresh',
    'user_visible_error',
  ];

  AccountConnectionHealthSnapshot _snapshot;
  final AccountConnectionRetryPolicy _retryPolicy;

  AccountConnectionHealthSnapshot get snapshot => _snapshot;
  AccountConnectionRetryPolicy get retryPolicy => _retryPolicy;
  int get retryAttempt => _snapshot.retryAttempt;

  List<AccountConnectionTransition> get availableTransitions =>
      AccountConnectionTransition.values
          .where(canTransition)
          .toList(growable: false);

  bool canTransition(AccountConnectionTransition transition) =>
      _allowedTransitions(_snapshot.connectionState).contains(transition);

  AccountConnectionHealthSnapshot transition(
    AccountConnectionTransition transition, {
    required DateTime at,
    AccountHealthState? healthState,
    String? errorCode,
    String? userVisibleError,
  }) {
    if (!canTransition(transition)) {
      throw StateError(
        'Transition ${transition.wireName} is not allowed from '
        '${_snapshot.connectionState.wireName}.',
      );
    }
    if (transition == AccountConnectionTransition.refreshHealth &&
        healthState == null) {
      throw ArgumentError.value(
        healthState,
        'healthState',
        'Health refresh requires an explicit health state.',
      );
    }
    if (_requiresExplicitVisibleError(transition)) {
      _validateVisibleError(userVisibleError);
    }
    final normalizedErrorCode = errorCode == null
        ? null
        : _normalizeText(errorCode, field: 'errorCode');
    final visibleError = _visibleErrorFor(
      transition,
      healthState: healthState,
      userVisibleError: userVisibleError,
    );

    switch (transition) {
      case AccountConnectionTransition.beginConnecting:
        _snapshot = _snapshot.copyWith(
          connectionState: AccountConnectionState.connecting,
          healthState: AccountHealthState.unknown,
          reauthRequired: false,
          retryAttempt: 0,
          clearError: true,
        );
      case AccountConnectionTransition.connectSucceeded:
        _snapshot = _snapshot.copyWith(
          connectionState: AccountConnectionState.connected,
          healthState: AccountHealthState.healthy,
          lastCheckedAt: at,
          reauthRequired: false,
          retryAttempt: 0,
          clearError: true,
        );
      case AccountConnectionTransition.error:
        _snapshot = _snapshot.copyWith(
          connectionState: AccountConnectionState.error,
          healthState: AccountHealthState.unknown,
          reauthRequired: false,
          userVisibleError: visibleError,
          errorCode: normalizedErrorCode,
        );
      case AccountConnectionTransition.unavailable:
        _snapshot = _snapshot.copyWith(
          connectionState: AccountConnectionState.unavailable,
          healthState: healthState ?? AccountHealthState.outage,
          reauthRequired: false,
          userVisibleError: visibleError,
          errorCode: normalizedErrorCode,
        );
      case AccountConnectionTransition.expire:
        _snapshot = _snapshot.copyWith(
          connectionState: AccountConnectionState.expired,
          healthState: AccountHealthState.unknown,
          reauthRequired: true,
          userVisibleError: visibleError,
          errorCode: normalizedErrorCode,
        );
      case AccountConnectionTransition.revoke:
        _snapshot = _snapshot.copyWith(
          connectionState: AccountConnectionState.revoked,
          healthState: AccountHealthState.unknown,
          reauthRequired: false,
          userVisibleError: visibleError,
          errorCode: normalizedErrorCode,
        );
      case AccountConnectionTransition.refreshHealth:
        _applyHealthRefresh(at, healthState!);
      case AccountConnectionTransition.reauthenticate:
        _snapshot = _snapshot.copyWith(
          connectionState: AccountConnectionState.connecting,
          healthState: AccountHealthState.unknown,
          reauthRequired: false,
          retryAttempt: 0,
          clearError: true,
        );
      case AccountConnectionTransition.retry:
        if (_snapshot.retryAttempt >= _retryPolicy.maxAttempts) {
          throw StateError('Retry policy exhausted.');
        }
        _snapshot = _snapshot.copyWith(
          connectionState: AccountConnectionState.connecting,
          healthState: AccountHealthState.unknown,
          reauthRequired: false,
          retryAttempt: _snapshot.retryAttempt + 1,
          clearError: true,
        );
      case AccountConnectionTransition.disconnectCleanup:
        _snapshot = _snapshot.copyWith(
          connectionState: AccountConnectionState.notConfigured,
          healthState: AccountHealthState.unknown,
          clearLastCheckedAt: true,
          reauthRequired: false,
          retryAttempt: 0,
          clearError: true,
        );
    }
    return _snapshot;
  }

  void _applyHealthRefresh(DateTime at, AccountHealthState health) {
    final nextConnection = switch (health) {
      AccountHealthState.healthy => AccountConnectionState.connected,
      AccountHealthState.degraded => AccountConnectionState.degraded,
      AccountHealthState.outage => AccountConnectionState.unavailable,
      AccountHealthState.rateLimited => AccountConnectionState.connected,
      AccountHealthState.latency => AccountConnectionState.degraded,
      AccountHealthState.unknown => _snapshot.connectionState,
    };
    _snapshot = _snapshot.copyWith(
      connectionState: nextConnection,
      healthState: health,
      lastCheckedAt: at,
      reauthRequired: false,
      userVisibleError: _messageForHealth(health),
      errorCode: switch (health) {
        AccountHealthState.healthy => null,
        AccountHealthState.latency => 'latency',
        _ => 'health',
      },
      clearError: health == AccountHealthState.healthy,
    );
  }

  static bool _requiresVisibleError(AccountConnectionTransition transition) =>
      transition == AccountConnectionTransition.error ||
      transition == AccountConnectionTransition.unavailable ||
      transition == AccountConnectionTransition.expire ||
      transition == AccountConnectionTransition.revoke;

  static bool _requiresExplicitVisibleError(
    AccountConnectionTransition transition,
  ) =>
      transition == AccountConnectionTransition.error ||
      transition == AccountConnectionTransition.unavailable;

  static String? _visibleErrorFor(
    AccountConnectionTransition transition, {
    required AccountHealthState? healthState,
    required String? userVisibleError,
  }) {
    if (!_requiresVisibleError(transition)) return null;
    if (userVisibleError != null && userVisibleError.trim().isNotEmpty) {
      return userVisibleError.trim();
    }
    return switch (transition) {
      AccountConnectionTransition.expire =>
        'Connection expired. Reauthenticate to restore this connection.',
      AccountConnectionTransition.revoke =>
        'Connection revoked. Configure a new connection before retrying.',
      AccountConnectionTransition.unavailable =>
        'Provider is currently unavailable. Try again later.',
      AccountConnectionTransition.error =>
        'The provider connection failed. Retry or reauthenticate as needed.',
      _ => throw StateError(
        'Unsupported visible-error transition: $transition',
      ),
    };
  }

  static String? _messageForHealth(
    AccountHealthState health,
  ) => switch (health) {
    AccountHealthState.healthy => null,
    AccountHealthState.unknown =>
      'Provider health is unknown. Refresh again when connectivity returns.',
    AccountHealthState.degraded =>
      'Provider is degraded. Retry may be available; local data is preserved.',
    AccountHealthState.outage =>
      'Provider is currently in outage. Try again later.',
    AccountHealthState.rateLimited =>
      'Provider rate limit reached. Try again after the provider window resets.',
    AccountHealthState.latency =>
      'Provider response latency is high. Retry may be available; local data is preserved.',
  };

  static void _validateVisibleError(String? value) {
    if (value == null || value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        'userVisibleError',
        'Failure transitions require a non-empty visible explanation.',
      );
    }
    final normalized = value.toLowerCase();
    const secretMarkers = <String>[
      'bearer ',
      'basic ',
      'api key',
      'api_key',
      'apikey',
      'access token',
      'refresh token',
      'client_secret',
      'password',
      'sk-',
      'ghp_',
      'xoxb-',
      '-----begin',
    ];
    if (secretMarkers.any(normalized.contains)) {
      throw ArgumentError.value(
        value,
        'userVisibleError',
        'User-visible errors must not contain credentials or raw secrets.',
      );
    }
  }

  static Set<AccountConnectionTransition> _allowedTransitions(
    AccountConnectionState state,
  ) => switch (state) {
    AccountConnectionState.notConfigured => {
      AccountConnectionTransition.beginConnecting,
    },
    AccountConnectionState.connecting => {
      AccountConnectionTransition.connectSucceeded,
      AccountConnectionTransition.error,
      AccountConnectionTransition.unavailable,
      AccountConnectionTransition.revoke,
    },
    AccountConnectionState.connected => {
      AccountConnectionTransition.refreshHealth,
      AccountConnectionTransition.error,
      AccountConnectionTransition.unavailable,
      AccountConnectionTransition.revoke,
      AccountConnectionTransition.expire,
    },
    AccountConnectionState.degraded => {
      AccountConnectionTransition.refreshHealth,
      AccountConnectionTransition.beginConnecting,
      AccountConnectionTransition.error,
      AccountConnectionTransition.unavailable,
      AccountConnectionTransition.revoke,
      AccountConnectionTransition.expire,
    },
    AccountConnectionState.expired => {
      AccountConnectionTransition.reauthenticate,
      AccountConnectionTransition.revoke,
    },
    AccountConnectionState.revoked => {
      AccountConnectionTransition.disconnectCleanup,
    },
    AccountConnectionState.error => {
      AccountConnectionTransition.retry,
      AccountConnectionTransition.reauthenticate,
      AccountConnectionTransition.revoke,
    },
    AccountConnectionState.unavailable => {
      AccountConnectionTransition.retry,
      AccountConnectionTransition.beginConnecting,
      AccountConnectionTransition.refreshHealth,
      AccountConnectionTransition.reauthenticate,
      AccountConnectionTransition.revoke,
    },
  };

  static String _normalizeProviderId(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        'providerId',
        'Provider id must not be empty.',
      );
    }
    return normalized;
  }

  static String _normalizeText(String value, {required String field}) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, field, 'Value must not be empty.');
    }
    return normalized;
  }
}
