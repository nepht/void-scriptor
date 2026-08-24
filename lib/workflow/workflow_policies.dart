/// Sprint 103 / 103.17-103.19 — bounded retry, timeout, and failure policies.
///
/// Design rules from the canonical spec:
///   * retry only when the failure class is retryable AND the step is
///     idempotent (103.17 idempotency_requirement);
///   * per-step timeout is mandatory, whole-workflow timeout optional,
///     timeouts audited downstream by the runner (103.18);
///   * five explicit failure behaviors; default derived from optionality
///     (103.19).
library;

/// Bounded retry policy for one step.
class WorkflowRetryPolicy {
  const WorkflowRetryPolicy({
    this.maxAttempts = 3,
    this.backoff = const Duration(seconds: 2),
    this.retryableErrors = const {
      'transient.network',
      'transient.io',
      'transient.timeout',
    },
    this.idempotent = true,
  });

  /// Hard upper bound; spec forbids unbounded retry loops.
  static const int absoluteMaxAttempts = 5;

  final int maxAttempts;
  final Duration backoff;
  final Set<String> retryableErrors;

  /// Non-idempotent steps must never auto-retry.
  final bool idempotent;

  /// Attempt is 1-based: `attempt == maxAttempts` means no further try.
  bool shouldRetry({required String errorCode, required int attempt}) {
    if (!idempotent) return false;
    if (attempt >= maxAttempts) return false;
    return retryableErrors.contains(errorCode);
  }
}

/// Wall-clock budgets (103.18).
class WorkflowTimeoutPolicy {
  const WorkflowTimeoutPolicy({required this.perStep, this.workflowTimeout});

  final Duration perStep;
  final Duration? workflowTimeout;
}

/// Explicit behavior when a step fails (103.19).
enum WorkflowFailurePolicy {
  stop,
  retry,
  skipIfOptional,
  rollbackSupportedChanges,
  requireUserDecision;

  /// Default derivation: optional steps skip, mandatory steps stop.
  static WorkflowFailurePolicy forStep({required bool optional}) =>
      optional ? skipIfOptional : stop;
}
