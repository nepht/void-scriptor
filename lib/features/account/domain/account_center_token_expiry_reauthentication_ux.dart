/// Sprint 115.43 — local token-expiry and reauthentication UX contract.
/// No provider request, credential access, or local-data mutation occurs here.
final class AccountCenterTokenExpiryReauthenticationUx {
  const AccountCenterTokenExpiryReauthenticationUx._({
    required this.providerId,
    required this.accountLabel,
    required this.affectedCapabilities,
    required this.requiresReauthentication,
    required this.canRetry,
    required this.canRevoke,
    required this.isRevoked,
    required this.localDataPreserved,
    required this.localDataScope,
    required this.notice,
  });

  static const List<String> canonicalAcceptance = <String>[
    'expiry_notice',
    'affected_scope',
    'reauth',
    'retry',
    'revoke',
    'local_data_preserved',
  ];

  final String providerId;
  final String accountLabel;
  final List<String> affectedCapabilities;
  final bool requiresReauthentication;
  final bool canRetry;
  final bool canRevoke;
  final bool isRevoked;

  /// Whether local data survives this connection outcome.
  ///
  /// This is a caller assertion, not a measurement. The seam has no view of the
  /// project store, so a caller that passes `hasLocalData: true` for a project
  /// whose files were already deleted gets `true` back (measured: the factory
  /// returned `localDataPreserved == true` for a call site with no store in
  /// reach). [localDataScope] now names what the assertion covers, so the claim
  /// can be read at the size it was actually made.
  final bool localDataPreserved;

  /// What [localDataPreserved] covers, in the caller's words.
  ///
  /// Empty means "unscoped claim": nothing was stated about what data survives.
  /// A non-empty scope is required before the claim can be treated as evidence.
  final String localDataScope;

  /// Whether the preservation claim names what it covers.
  bool get hasLocalDataScope => localDataScope.trim().isNotEmpty;

  /// The claim is usable evidence only when it is both positive and scoped.
  bool get localDataPreservedWithScope =>
      localDataPreserved && hasLocalDataScope;

  final String notice;

  String get retryLabel => affectedCapabilities.isEmpty
      ? 'Retry connection'
      : 'Retry ${affectedCapabilities.first}';

  /// Notice that carries the scope, so a screen cannot render a bare
  /// "local data preserved" with nothing behind it.
  String get scopedNotice => localDataPreservedWithScope
      ? '$notice Local data preserved: $localDataScope.'
      : notice;

  factory AccountCenterTokenExpiryReauthenticationUx.expired({
    required String providerId,
    required String accountLabel,
    required List<String> affectedCapabilities,
    required bool hasLocalData,
    String localDataScope = '',
  }) {
    final provider = _text(providerId, 'providerId');
    final label = _text(accountLabel, 'accountLabel');
    final capabilities = _capabilities(affectedCapabilities);
    return AccountCenterTokenExpiryReauthenticationUx._(
      providerId: provider,
      accountLabel: label,
      affectedCapabilities: capabilities,
      requiresReauthentication: true,
      canRetry: false,
      canRevoke: true,
      isRevoked: false,
      localDataPreserved: hasLocalData,
      localDataScope: localDataScope.trim(),
      notice: 'Connection expired for $label.',
    );
  }

  static AccountCenterTokenExpiryReauthenticationUx reauthenticatedState({
    required String providerId,
    required String accountLabel,
    required List<String> affectedCapabilities,
    required bool hasLocalData,
    String localDataScope = '',
  }) => AccountCenterTokenExpiryReauthenticationUx._(
    providerId: _text(providerId, 'providerId'),
    accountLabel: _text(accountLabel, 'accountLabel'),
    affectedCapabilities: _capabilities(affectedCapabilities),
    requiresReauthentication: false,
    canRetry: true,
    canRevoke: true,
    isRevoked: false,
    localDataPreserved: hasLocalData,
    localDataScope: localDataScope.trim(),
    notice: 'Connection restored for ${_text(accountLabel, 'accountLabel')}.',
  );

  AccountCenterTokenExpiryReauthenticationUx reauthenticated() =>
      reauthenticatedState(
        providerId: providerId,
        accountLabel: accountLabel,
        affectedCapabilities: affectedCapabilities,
        hasLocalData: localDataPreserved,
        localDataScope: localDataScope,
      );

  AccountCenterTokenExpiryReauthenticationUx revoked() =>
      AccountCenterTokenExpiryReauthenticationUx._(
        providerId: providerId,
        accountLabel: accountLabel,
        affectedCapabilities: affectedCapabilities,
        requiresReauthentication: false,
        canRetry: false,
        canRevoke: false,
        isRevoked: true,
        localDataPreserved: localDataPreserved,
        localDataScope: localDataScope,
        notice: 'Connection revoked for $accountLabel.',
      );

  AccountCenterRetryResult retry(String capability) {
    final normalized = capability.trim();
    if (!canRetry || !affectedCapabilities.contains(normalized)) {
      return const AccountCenterRetryResult(
        accepted: false,
        reason: 'Capability is not available for retry.',
      );
    }
    return const AccountCenterRetryResult(accepted: true);
  }

  static String _text(String value, String field) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, field, 'must not be empty');
    }
    return normalized;
  }

  static List<String> _capabilities(List<String> values) {
    final result = values
        .map((value) => _text(value, 'affectedCapabilities'))
        .toList(growable: false);
    if (result.toSet().length != result.length) {
      throw ArgumentError.value(
        values,
        'affectedCapabilities',
        'must not contain duplicates',
      );
    }
    return List.unmodifiable(result);
  }
}

final class AccountCenterRetryResult {
  const AccountCenterRetryResult({required this.accepted, this.reason});
  final bool accepted;
  final String? reason;
}
