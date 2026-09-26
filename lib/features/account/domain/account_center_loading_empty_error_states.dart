/// Sprint 115.42 — Loading, Empty & Error States.
///
/// Metadata-only state contract. It preserves local/cached data explicitly and
/// never turns an unavailable provider response into a fabricated value.
enum AccountCenterSurfaceState {
  loading,
  empty,
  partial,
  offline,
  permissionDenied,
  rateLimited,
  outage,
  unavailable,
  error,
  reauth,
}

final class AccountCenterLoadingEmptyErrorStates {
  const AccountCenterLoadingEmptyErrorStates._({
    required this.source,
    required this.state,
    required this.message,
    required this.hasData,
    required this.canRetry,
    required this.requiresPermission,
    required this.requiresReauthentication,
    required this.availableItemCount,
    this.retryAfter,
  });

  static const String canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';

  static const List<String> canonicalRequiredStates = <String>[
    'loading',
    'empty',
    'partial',
    'offline',
    'permission_denied',
    'rate_limited',
    'outage',
    'unavailable',
    'error',
    'reauth',
  ];

  final String source;
  final AccountCenterSurfaceState state;
  final String message;
  final bool hasData;
  final bool canRetry;
  final bool requiresPermission;
  final bool requiresReauthentication;
  final int availableItemCount;
  final Duration? retryAfter;

  factory AccountCenterLoadingEmptyErrorStates.loading({
    required String source,
  }) {
    final normalizedSource = source.trim();
    return _create(
      normalizedSource,
      AccountCenterSurfaceState.loading,
      'Loading $normalizedSource…',
    );
  }

  factory AccountCenterLoadingEmptyErrorStates.empty({required String source}) {
    final normalizedSource = source.trim();
    return _create(
      normalizedSource,
      AccountCenterSurfaceState.empty,
      'No $normalizedSource data available.',
    );
  }

  factory AccountCenterLoadingEmptyErrorStates.partial({
    required String source,
    required int availableItemCount,
    required String unavailableReason,
  }) {
    _validateCount(availableItemCount);
    return _create(
      source,
      AccountCenterSurfaceState.partial,
      unavailableReason,
      hasData: true,
      canRetry: true,
      availableItemCount: availableItemCount,
    );
  }

  factory AccountCenterLoadingEmptyErrorStates.offline({
    required String source,
    required bool hasCachedData,
  }) => _create(
    source,
    AccountCenterSurfaceState.offline,
    hasCachedData
        ? 'Offline. Showing cached data.'
        : 'Offline. Cached data is unavailable.',
    hasData: hasCachedData,
    canRetry: true,
  );

  factory AccountCenterLoadingEmptyErrorStates.permissionDenied({
    required String source,
    required String message,
  }) => _create(
    source,
    AccountCenterSurfaceState.permissionDenied,
    message,
    requiresPermission: true,
  );

  factory AccountCenterLoadingEmptyErrorStates.rateLimited({
    required String source,
    required Duration retryAfter,
  }) {
    if (retryAfter <= Duration.zero) {
      throw ArgumentError.value(retryAfter, 'retryAfter', 'must be positive');
    }
    final minutes = retryAfter.inMinutes;
    return _create(
      source,
      AccountCenterSurfaceState.rateLimited,
      'Rate limited. Try again after $minutes minutes.',
      canRetry: true,
      retryAfter: retryAfter,
    );
  }

  factory AccountCenterLoadingEmptyErrorStates.outage({
    required String source,
  }) => _create(
    source,
    AccountCenterSurfaceState.outage,
    'Provider outage. Try again later.',
    canRetry: true,
  );

  factory AccountCenterLoadingEmptyErrorStates.unavailable({
    required String source,
    required String reason,
  }) => _create(source, AccountCenterSurfaceState.unavailable, reason);

  factory AccountCenterLoadingEmptyErrorStates.error({
    required String source,
    required String message,
    required bool canRetry,
  }) {
    _validateMessage(message);
    return _create(
      source,
      AccountCenterSurfaceState.error,
      message,
      canRetry: canRetry,
    );
  }

  factory AccountCenterLoadingEmptyErrorStates.reauth({
    required String source,
    required bool hasLocalData,
  }) => _create(
    source,
    AccountCenterSurfaceState.reauth,
    'Reauthenticate to restore this connection. Local data is preserved.',
    hasData: hasLocalData,
    requiresReauthentication: true,
  );

  static AccountCenterLoadingEmptyErrorStates _create(
    String source,
    AccountCenterSurfaceState state,
    String message, {
    bool hasData = false,
    bool canRetry = false,
    bool requiresPermission = false,
    bool requiresReauthentication = false,
    int availableItemCount = 0,
    Duration? retryAfter,
  }) {
    final normalizedSource = source.trim();
    if (normalizedSource.isEmpty) {
      throw ArgumentError.value(source, 'source', 'must not be empty');
    }
    _validateMessage(message);
    return AccountCenterLoadingEmptyErrorStates._(
      source: normalizedSource,
      state: state,
      message: message.trim(),
      hasData: hasData,
      canRetry: canRetry,
      requiresPermission: requiresPermission,
      requiresReauthentication: requiresReauthentication,
      availableItemCount: availableItemCount,
      retryAfter: retryAfter,
    );
  }

  static void _validateCount(int count) {
    if (count < 0) {
      throw ArgumentError.value(
        count,
        'availableItemCount',
        'must not be negative',
      );
    }
  }

  static void _validateMessage(String message) {
    final normalized = message.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(message, 'message', 'must not be empty');
    }
    const secretMarkers = <String>[
      'bearer ',
      'api key',
      'api_key',
      'access token',
      'refresh token',
      'password',
      'sk-',
    ];
    if (secretMarkers.any(normalized.toLowerCase().contains)) {
      throw ArgumentError.value(
        message,
        'message',
        'must not contain credentials',
      );
    }
  }
}
