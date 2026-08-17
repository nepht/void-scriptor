/// Sprint 50 — Step 50.116–50.142 Release Finale: Beta, Metrics, Safety, 1.0 Plan.
class BetaFeedback {
  const BetaFeedback({
    required this.id,
    required this.category,
    required this.message,
    required this.reportedAt,
  });

  final String id;
  final String category;
  final String message;
  final DateTime reportedAt;
}

class ProductMetric {
  const ProductMetric({
    required this.id,
    required this.name,
    required this.value,
    this.unit = 'count',
  });

  final String id;
  final String name;
  final double value;
  final String unit;
}

class AtomicSave {
  const AtomicSave({
    required this.id,
    required this.targetPath,
    required this.tempPath,
  });

  final String id;
  final String targetPath;
  final String tempPath;
}

class DiskSpaceGuard {
  const DiskSpaceGuard({
    required this.freeBytes,
    required this.minimumRequiredBytes,
  });

  final int freeBytes;
  final int minimumRequiredBytes;

  bool get isBlocked => freeBytes < minimumRequiredBytes;
}

class PluginApiVersion {
  const PluginApiVersion({required this.major, required this.minor});

  final int major;
  final int minor;

  bool isCompatibleWith(int majorVersion, int minorVersion) =>
      major == majorVersion && minor >= minorVersion;
}

/// Step 50.129–50.130 Production Defaults, Experimental Modules.
class ProductionDefaults {
  const ProductionDefaults({
    required this.autosaveIntervalSeconds,
    required this.backupEnabled,
  });

  final int autosaveIntervalSeconds;
  final bool backupEnabled;
}

/// Step 50.136–50.140 Gold Master, Staged Rollout, Patch Branch.
class ReleasePlan {
  const ReleasePlan({
    required this.goldMasterVersion,
    required this.stagedRolloutPercent,
  });

  final String goldMasterVersion;
  final int stagedRolloutPercent;
}

class PatchBranch {
  const PatchBranch({
    required this.id,
    required this.baseVersion,
    required this.branchName,
  });

  final String id;
  final String baseVersion;
  final String branchName;
}
