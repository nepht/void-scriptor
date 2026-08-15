enum SyncState { idle, syncing, synced, error, conflict }

class SyncStatus {
  const SyncStatus({
    this.state = SyncState.idle,
    this.startedAt,
    this.lastSyncAt,
    this.message,
  });

  const SyncStatus.syncing({DateTime? startedAt})
    : state = SyncState.syncing,
      startedAt = startedAt,
      lastSyncAt = null,
      message = null;

  final SyncState state;
  final DateTime? startedAt;
  final DateTime? lastSyncAt;
  final String? message;

  SyncStatus copyWith({
    SyncState? state,
    DateTime? startedAt,
    DateTime? lastSyncAt,
    String? message,
  }) {
    return SyncStatus(
      state: state ?? this.state,
      startedAt: startedAt ?? this.startedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      message: message ?? this.message,
    );
  }
}

class SyncChangeSet {
  const SyncChangeSet({
    required this.base,
    required this.ours,
    required this.theirs,
  });

  final Map<String, Object?> base;
  final Map<String, Object?> ours;
  final Map<String, Object?> theirs;

  Set<String> get changedKeys {
    final keys = <String>{...base.keys, ...ours.keys, ...theirs.keys};
    return keys
        .where((key) => base[key] != ours[key] || base[key] != theirs[key])
        .toSet();
  }

  bool isConflictOn(String key) {
    final baseValue = base[key];
    final oursChanged = baseValue != ours[key];
    final theirsChanged = baseValue != theirs[key];
    final bothChanged = oursChanged && theirsChanged;
    return bothChanged && ours[key] != theirs[key];
  }
}

class SyncResult {
  const SyncResult({
    required this.state,
    required this.applied,
    required this.total,
    this.conflictKeys = const {},
    this.message,
  });

  final SyncState state;
  final int applied;
  final int total;
  final Set<String> conflictKeys;
  final String? message;

  bool get hasConflicts => conflictKeys.isNotEmpty;
  bool get complete => applied == total && !hasConflicts;
}
