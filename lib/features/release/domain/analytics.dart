/// Sprint 49 — Step 49.66–49.68 Release Analytics, Health, Crash Data.
class ReleaseAnalytics {
  const ReleaseAnalytics({
    required this.releaseId,
    required this.downloads,
    required this.crashRate,
    this.engagement = 0.0,
  });

  final String releaseId;
  final int downloads;
  final double crashRate;
  final double engagement;

  bool get isHealthy => crashRate < 0.05;
}

class CrashReport {
  const CrashReport({
    required this.id,
    required this.releaseId,
    required this.platform,
    required this.stackHash,
    required this.count,
  });

  final String id;
  final String releaseId;
  final String platform;
  final String stackHash;
  final int count;
}
