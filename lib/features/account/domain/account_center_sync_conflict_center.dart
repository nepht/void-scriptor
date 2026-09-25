/// Sprint 115.23 — Sync Conflict Center.
///
/// Local, provider-agnostic conflict metadata contract. It models detection,
/// preview, resolution, history, and backup gating without claiming live sync.
library;

import 'dart:collection';

enum SyncConflictStatus { unresolved, resolved }

enum SyncConflictResolution { keepLocal, keepRemote, merge }

enum SyncConflictFallbackStatus {
  unresolvedPreserved,
  alreadyResolved,
  notFound,
}

final class SyncConflictVersion {
  SyncConflictVersion({
    required String versionId,
    required DateTime modifiedAt,
    required String preview,
  }) : versionId = _required(versionId, 'versionId'),
       modifiedAt = modifiedAt.toUtc(),
       preview = _required(preview, 'preview');

  final String versionId;
  final DateTime modifiedAt;
  final String preview;
}

final class ConflictBackupEvidence {
  ConflictBackupEvidence._({required this.backupId, required this.completedAt});

  factory ConflictBackupEvidence.pending() =>
      ConflictBackupEvidence._(backupId: null, completedAt: null);

  factory ConflictBackupEvidence.completed({
    required String backupId,
    required DateTime completedAt,
  }) => ConflictBackupEvidence._(
    backupId: _required(backupId, 'backupId'),
    completedAt: completedAt.toUtc(),
  );

  final String? backupId;
  final DateTime? completedAt;

  bool get isCompleted => backupId != null && completedAt != null;
}

final class SyncConflict {
  SyncConflict._({
    required this.conflictId,
    required this.sourceId,
    required this.itemId,
    required this.local,
    required this.remote,
    required this.mergeSupported,
    required this.status,
    required this.resolution,
    required this.selectedVersion,
  });

  factory SyncConflict.detect({
    required String conflictId,
    required String sourceId,
    required String itemId,
    required SyncConflictVersion local,
    required SyncConflictVersion remote,
    required bool mergeSupported,
  }) {
    if (local.versionId == remote.versionId) {
      throw ArgumentError.value(local.versionId, 'local.versionId');
    }
    return SyncConflict._(
      conflictId: _required(conflictId, 'conflictId'),
      sourceId: _required(sourceId, 'sourceId'),
      itemId: _required(itemId, 'itemId'),
      local: local,
      remote: remote,
      mergeSupported: mergeSupported,
      status: SyncConflictStatus.unresolved,
      resolution: null,
      selectedVersion: null,
    );
  }

  final String conflictId;
  final String sourceId;
  final String itemId;
  final SyncConflictVersion local;
  final SyncConflictVersion remote;
  final bool mergeSupported;
  final SyncConflictStatus status;
  final SyncConflictResolution? resolution;
  final SyncConflictVersion? selectedVersion;

  SyncConflict _resolved({
    required SyncConflictResolution resolution,
    required SyncConflictVersion selectedVersion,
  }) => SyncConflict._(
    conflictId: conflictId,
    sourceId: sourceId,
    itemId: itemId,
    local: local,
    remote: remote,
    mergeSupported: mergeSupported,
    status: SyncConflictStatus.resolved,
    resolution: resolution,
    selectedVersion: selectedVersion,
  );
}

final class SyncConflictHistoryEntry {
  const SyncConflictHistoryEntry({
    required this.conflictId,
    required this.resolution,
    required this.selectedVersionId,
    required this.backupId,
    required this.resolvedAt,
  });

  final String conflictId;
  final SyncConflictResolution resolution;
  final String selectedVersionId;
  final String backupId;
  final DateTime resolvedAt;
}

final class SyncConflictFallback {
  const SyncConflictFallback({required this.status, required this.conflict});

  final SyncConflictFallbackStatus status;
  final SyncConflict? conflict;
}

final class AccountCenterSyncConflictCenter {
  AccountCenterSyncConflictCenter(Iterable<SyncConflict> conflicts)
    : this._(conflicts, const []);

  AccountCenterSyncConflictCenter._(
    Iterable<SyncConflict> conflicts,
    Iterable<SyncConflictHistoryEntry> history,
  ) : _conflicts = Map.unmodifiable({
        for (final conflict in conflicts) conflict.conflictId: conflict,
      }),
      history = UnmodifiableListView(history.toList(growable: false)) {
    if (_conflicts.length != conflicts.length) {
      throw ArgumentError('Conflict IDs must be unique.');
    }
  }

  final Map<String, SyncConflict> _conflicts;
  final List<SyncConflictHistoryEntry> history;

  List<SyncConflict> get conflicts =>
      UnmodifiableListView(_conflicts.values.toList(growable: false));

  AccountCenterSyncConflictCenter resolve({
    required String conflictId,
    required SyncConflictResolution strategy,
    required ConflictBackupEvidence backup,
    required DateTime resolvedAt,
    SyncConflictVersion? mergedVersion,
  }) {
    final normalizedId = _required(conflictId, 'conflictId');
    final conflict = _conflicts[normalizedId];
    if (conflict == null) throw StateError('Sync conflict was not found.');
    if (conflict.status == SyncConflictStatus.resolved) {
      throw StateError('Sync conflict is already resolved.');
    }
    if (!backup.isCompleted) {
      throw StateError('A completed backup is required before resolution.');
    }
    if (backup.completedAt!.isAfter(resolvedAt.toUtc())) {
      throw StateError('Backup must complete before conflict resolution.');
    }

    final selectedVersion = switch (strategy) {
      SyncConflictResolution.keepLocal => conflict.local,
      SyncConflictResolution.keepRemote => conflict.remote,
      SyncConflictResolution.merge => _validatedMerge(conflict, mergedVersion),
    };
    final updated = conflict._resolved(
      resolution: strategy,
      selectedVersion: selectedVersion,
    );
    final nextConflicts = Map<String, SyncConflict>.of(_conflicts)
      ..[normalizedId] = updated;
    final entry = SyncConflictHistoryEntry(
      conflictId: normalizedId,
      resolution: strategy,
      selectedVersionId: selectedVersion.versionId,
      backupId: backup.backupId!,
      resolvedAt: resolvedAt.toUtc(),
    );
    return AccountCenterSyncConflictCenter._(nextConflicts.values, [
      ...history,
      entry,
    ]);
  }

  SyncConflictFallback safeFallback({required String conflictId}) {
    final conflict = _conflicts[conflictId.trim()];
    if (conflict == null) {
      return const SyncConflictFallback(
        status: SyncConflictFallbackStatus.notFound,
        conflict: null,
      );
    }
    return SyncConflictFallback(
      status: conflict.status == SyncConflictStatus.resolved
          ? SyncConflictFallbackStatus.alreadyResolved
          : SyncConflictFallbackStatus.unresolvedPreserved,
      conflict: conflict,
    );
  }

  static SyncConflictVersion _validatedMerge(
    SyncConflict conflict,
    SyncConflictVersion? mergedVersion,
  ) {
    if (!conflict.mergeSupported) {
      throw StateError('Merge is not supported for this conflict.');
    }
    if (mergedVersion == null) {
      throw ArgumentError.notNull('mergedVersion');
    }
    if (mergedVersion.versionId == conflict.local.versionId ||
        mergedVersion.versionId == conflict.remote.versionId) {
      throw ArgumentError.value(mergedVersion.versionId, 'mergedVersion');
    }
    return mergedVersion;
  }
}

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, field);
  return normalized;
}
