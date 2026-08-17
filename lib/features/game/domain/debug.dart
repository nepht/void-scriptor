/// Sprint 47 — Step 47.85–47.88 Game Profiler, Performance Budget, Build Targets.
class PerformanceBudget {
  const PerformanceBudget({required this.frameTimeMs, required this.memoryMb});

  final double frameTimeMs;
  final int memoryMb;

  bool get isHealthy => frameTimeMs <= 16.7 && memoryMb <= 800;
}

enum BuildTarget { windows, macos, linux, web, android, ios, console }
