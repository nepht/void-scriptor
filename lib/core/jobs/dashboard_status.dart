/// Dashboard background status (Step 26.97).
///
/// The dashboard shows a compact "BACKGROUND TASKS" summary without becoming
/// a full telemetry wall. Task Center remains the primary detail view.
class DashboardBackgroundStatus {
  const DashboardBackgroundStatus({
    required this.runningJobs,
    required this.queuedJobs,
    required this.thumbnailCachePercent,
    required this.searchIndexReady,
  });

  final int runningJobs;
  final int queuedJobs;
  final int thumbnailCachePercent;
  final bool searchIndexReady;

  int get totalJobs => runningJobs + queuedJobs;
}
