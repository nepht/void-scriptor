enum SyncAuthority { cloud, externalFolder }

class SyncAuthorityDecision {
  const SyncAuthorityDecision._({
    required this.allowed,
    required this.authority,
    required this.message,
  });

  SyncAuthorityDecision.allowed(SyncAuthority authority)
    : this._(
        allowed: true,
        authority: authority,
        message: 'Sync authority claimed: ${authority.name}',
      );

  const SyncAuthorityDecision.denied({
    required SyncAuthority authority,
    required String message,
  }) : this._(allowed: false, authority: authority, message: message);

  final bool allowed;
  final SyncAuthority authority;
  final String message;
}

class SingleSyncAuthorityPolicy {
  SyncAuthority? _authority;

  SyncAuthority? get authority => _authority;

  SyncAuthorityDecision claim(SyncAuthority requested) {
    final current = _authority;
    if (current == null || current == requested) {
      _authority = requested;
      return SyncAuthorityDecision.allowed(requested);
    }

    return SyncAuthorityDecision.denied(
      authority: current,
      message:
          'Sync blocked: cloud and external folder cannot own one live project concurrently.',
    );
  }

  void release() => _authority = null;
}
