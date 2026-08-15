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
    // Include non-conflicting ours values as-is.
    for (final key in change.ours.keys) {
      if (!change.isConflictOn(key)) {
        merged[key] = change.ours[key];
      }
    }
    return merged;
  }
}
