/// Performance mode presets (Step 26.69).
///
/// Users should not need to understand thread counts to use the app normally.
/// A `PerformanceMode` bundles thumbnail quality, background worker count, AI
/// download concurrency, and preload aggressiveness into named presets.
enum PerformanceMode {
  low,
  balanced,
  high;

  static const PerformanceMode defaultMode = PerformanceMode.balanced;

  /// Lower is cheaper.
  int get thumbnailQuality => switch (this) {
    PerformanceMode.low => 0,
    PerformanceMode.balanced => 1,
    PerformanceMode.high => 2,
  };

  int get backgroundWorkers => switch (this) {
    PerformanceMode.low => 1,
    PerformanceMode.balanced => 2,
    PerformanceMode.high => 4,
  };

  int get aiDownloadConcurrency => switch (this) {
    PerformanceMode.low => 1,
    PerformanceMode.balanced => 2,
    PerformanceMode.high => 4,
  };

  int get preloadAggressiveness => switch (this) {
    PerformanceMode.low => 0,
    PerformanceMode.balanced => 1,
    PerformanceMode.high => 2,
  };
}
