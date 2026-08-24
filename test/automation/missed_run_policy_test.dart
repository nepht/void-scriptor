import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/automation/missed_run_policy.dart';

/// Sprint 104 / 104.10 — what happens when the app was not running at the
/// scheduled moment. Four canonical policies, deterministic decisions.
void main() {
  final scheduled = DateTime.utc(2026, 8, 25, 2, 0);
  final later = DateTime.utc(2026, 8, 25, 4, 0);

  test('SKIP silently drops the missed occurrence', () {
    expect(
      resolveMissedRun(MissedRunPolicy.skip, scheduled, later),
      MissedRunDecision.none,
    );
  });

  test('RUN_ONCE_AT_STARTUP runs exactly once, never retroactively loops', () {
    expect(
      resolveMissedRun(MissedRunPolicy.runOnceAtStartup, scheduled, later),
      MissedRunDecision.runOnce,
    );
  });

  test('REQUIRE_CONFIRMATION defers to the human', () {
    expect(
      resolveMissedRun(MissedRunPolicy.requireConfirmation, scheduled, later),
      MissedRunDecision.needsConfirmation,
    );
  });

  test('DISABLE_AND_WARN retires the schedule loudly', () {
    final decision = resolveMissedRun(
      MissedRunPolicy.disableAndWarn,
      scheduled,
      later,
    );
    expect(decision, MissedRunDecision.disabledWithWarning);
  });

  test('an on-time evaluation never counts as missed', () {
    for (final policy in MissedRunPolicy.values) {
      expect(
        resolveMissedRun(policy, scheduled, scheduled),
        MissedRunDecision.onTime,
      );
    }
  });
}
