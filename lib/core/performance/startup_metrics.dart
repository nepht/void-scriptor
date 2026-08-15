import 'performance_runtime.dart';

/// Startup fast path phases (Steps 26.63/64/65).
///
/// The canonical startup order for a project is manifest → database →
/// workspace → first frame. Recording each phase keeps the fast path auditable
/// and surfaces which phase regresses.
enum StartupPhase {
  manifest,
  database,
  workspace,
  firstFrame;

  static const List<StartupPhase> ordered = [
    manifest,
    database,
    workspace,
    firstFrame,
  ];
}

/// Thin recorder that funnels startup phase timings into [PerformanceMetrics].
class StartupMetrics {
  const StartupMetrics(this.metrics);

  final PerformanceMetrics metrics;

  void record(StartupPhase phase, Duration duration) =>
      metrics.record(phase.name, duration);

  Duration get startupTotal => StartupPhase.ordered.fold(
    Duration.zero,
    (total, phase) => total + (metrics.durationOf(phase.name) ?? Duration.zero),
  );
}
