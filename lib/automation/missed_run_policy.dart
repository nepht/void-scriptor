/// Sprint 104 / 104.10 — behaviour when the app was not running at a
/// scheduled moment. Four canonical policies; decisions are pure and
/// deterministic.
library;

enum MissedRunPolicy {
  /// Silently drop the missed occurrence.
  skip,

  /// Run exactly once at startup, never retroactively loop.
  runOnceAtStartup,

  /// Defer to explicit human confirmation before running.
  requireConfirmation,

  /// Disable the schedule and surface a warning.
  disableAndWarn,
}

enum MissedRunDecision {
  onTime,
  none,
  runOnce,
  needsConfirmation,
  disabledWithWarning,
}

/// Pure decision function: [now] strictly after [scheduledAt] counts as
/// missed; equal-or-earlier is on time regardless of policy.
MissedRunDecision resolveMissedRun(
  MissedRunPolicy policy,
  DateTime scheduledAt,
  DateTime now,
) {
  if (!now.isAfter(scheduledAt)) return MissedRunDecision.onTime;
  return switch (policy) {
    MissedRunPolicy.skip => MissedRunDecision.none,
    MissedRunPolicy.runOnceAtStartup => MissedRunDecision.runOnce,
    MissedRunPolicy.requireConfirmation => MissedRunDecision.needsConfirmation,
    MissedRunPolicy.disableAndWarn => MissedRunDecision.disabledWithWarning,
  };
}
