import '../domain/sync_models.dart';

enum ConflictResolution { keepOurs, keepTheirs, manual }

/// Detects keys where both sides diverged from base to different values
/// (Step 29.7).
class ConflictDetector {
  static List<String> detect(SyncChangeSet change) {
    return change.changedKeys.where((key) => change.isConflictOn(key)).toList();
  }
}

/// Applies resolutions to produce a merged state (Step 29.8).
class ConflictResolver {
  static Map<String, Object?> resolve(
    SyncChangeSet change,
    Map<String, ConflictResolution> resolutions,
  ) {
    final merged = <String, Object?>{};
    for (final key in change.changedKeys) {
      final resolution = resolutions[key];
      if (resolution == ConflictResolution.keepOurs) {
        merged[key] = change.ours[key];
      } else if (resolution == ConflictResolution.keepTheirs) {
        merged[key] = change.theirs[key];
      }
      // manual → leave unresolved (not in merged)
    }
    // Carry the values neither side conflicted on. A key only the remote side
    // changed is not a conflict, so no resolution is supplied for it and it
    // never reaches the loop above; without this pass a remote-only edit would
    // be reverted to base or a remote-only addition dropped entirely.
    for (final key in change.changedKeys) {
      if (change.isConflictOn(key)) continue;
      // Divergence decides, not presence: when only the remote side moved,
      // `ours` still holds the base value, so taking `ours[key]` would revert
      // the remote edit. Same test as isConflictOn, so both sides agree on
      // which side won. A locally deleted key counts as ours diverging.
      final oursChanged = change.base[key] != change.ours[key];
      merged[key] = oursChanged ? change.ours[key] : change.theirs[key];
    }
    return merged;
  }
}
