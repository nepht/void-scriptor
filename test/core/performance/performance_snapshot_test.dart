import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/performance/performance_diagnostics.dart';

void main() {
  test('diagnostics snapshot aggregates runtime state', () {
    const snapshot = PerformanceDiagnosticsSnapshot(
      assetCount: 21482,
      databaseSizeBytes: 182 * 1024 * 1024,
      searchIndexHealthy: true,
      thumbnailCacheBytes: 1800 * 1024 * 1024,
      runningJobs: 2,
      recentQueryMs: 12,
      lastProjectOpenMs: 820,
    );

    expect(snapshot.assetCount, 21482);
    expect(snapshot.databaseSizeBytes, 182 * 1024 * 1024);
    expect(snapshot.searchIndexHealthy, isTrue);
    expect(snapshot.thumbnailCacheBytes, 1800 * 1024 * 1024);
    expect(snapshot.runningJobs, 2);
    expect(snapshot.recentQueryMs, 12);
    expect(snapshot.lastProjectOpenMs, 820);
  });

  test('frame indicators track build, raster, and dropped frames', () {
    final frames = FrameIndicators();

    frames.recordBuild(const Duration(milliseconds: 8));
    frames.recordRaster(const Duration(milliseconds: 4));
    frames.recordDrop();

    expect(frames.buildCount, 1);
    expect(frames.rasterCount, 1);
    expect(frames.droppedFrames, 1);
    expect(frames.totalBuildTime, const Duration(milliseconds: 8));
  });

  test('frame indicators reset clears counters', () {
    final frames = FrameIndicators();
    frames.recordBuild(const Duration(milliseconds: 8));
    frames.recordDrop();

    frames.reset();

    expect(frames.buildCount, 0);
    expect(frames.droppedFrames, 0);
    expect(frames.totalBuildTime, Duration.zero);
  });
}
