import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/performance/performance_runtime.dart';
import 'package:void_scriptor/core/performance/startup_metrics.dart';

void main() {
  test('startup phases follow the fast path order', () {
    expect(StartupPhase.ordered, [
      StartupPhase.manifest,
      StartupPhase.database,
      StartupPhase.workspace,
      StartupPhase.firstFrame,
    ]);
  });

  test('records each startup phase and computes total', () {
    final metrics = PerformanceMetrics();
    final recorder = StartupMetrics(metrics);

    recorder.record(StartupPhase.manifest, const Duration(milliseconds: 12));
    recorder.record(StartupPhase.database, const Duration(milliseconds: 80));
    recorder.record(StartupPhase.workspace, const Duration(milliseconds: 40));
    recorder.record(StartupPhase.firstFrame, const Duration(milliseconds: 16));

    expect(
      metrics.durationOf(StartupPhase.manifest.name),
      const Duration(milliseconds: 12),
    );
    expect(
      metrics.durationOf(StartupPhase.workspace.name),
      const Duration(milliseconds: 40),
    );
    expect(metrics.total, const Duration(milliseconds: 148));
  });

  test('fast path total excludes unknown phases', () {
    final metrics = PerformanceMetrics();
    final recorder = StartupMetrics(metrics);
    recorder.record(StartupPhase.database, const Duration(milliseconds: 50));

    expect(recorder.startupTotal, const Duration(milliseconds: 50));
  });
}
