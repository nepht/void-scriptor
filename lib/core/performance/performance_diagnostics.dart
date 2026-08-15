/// Performance diagnostics snapshot (Step 26.66) and lightweight frame
/// indicators (Step 26.68).
///
/// The diagnostics page aggregates runtime state into one snapshot so the
/// "Performance" screen can render counts and sizes without querying the
/// database on every frame. Frame indicators stay intentionally lightweight —
/// Flutter's own profiler does the heavy lifting.
class PerformanceDiagnosticsSnapshot {
  const PerformanceDiagnosticsSnapshot({
    required this.assetCount,
    required this.databaseSizeBytes,
    required this.searchIndexHealthy,
    required this.thumbnailCacheBytes,
    required this.runningJobs,
    required this.recentQueryMs,
    required this.lastProjectOpenMs,
  });

  final int assetCount;
  final int databaseSizeBytes;
  final bool searchIndexHealthy;
  final int thumbnailCacheBytes;
  final int runningJobs;
  final int recentQueryMs;
  final int lastProjectOpenMs;
}

class FrameIndicators {
  int _buildCount = 0;
  int _rasterCount = 0;
  int _droppedFrames = 0;
  Duration _totalBuildTime = Duration.zero;

  int get buildCount => _buildCount;
  int get rasterCount => _rasterCount;
  int get droppedFrames => _droppedFrames;
  Duration get totalBuildTime => _totalBuildTime;

  void recordBuild(Duration duration) {
    _buildCount++;
    _totalBuildTime += duration;
  }

  void recordRaster(Duration duration) => _rasterCount++;

  void recordDrop() => _droppedFrames++;

  void reset() {
    _buildCount = 0;
    _rasterCount = 0;
    _droppedFrames = 0;
    _totalBuildTime = Duration.zero;
  }
}
