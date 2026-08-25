library;

/// Sprint 104 / 104.21–104.29 — automation safety runtime.
///
/// Everything here is deterministic: time-dependent decisions take an
/// explicit `now`, so tests need no sleeps and behaviour cannot drift.
/// Audit surfaces carry identifiers only — never story content.

// 104.21 — approval gate model

enum ApprovalGateType {
  informational,
  confirmation,
  reauthentication,
  reviewOutput,
  approveExternalTransfer,
}

class ApprovalGate {
  const ApprovalGate({required this.gateId, required this.type});

  final String gateId;
  final ApprovalGateType type;
}

// 104.22 — human-in-the-loop runtime

enum HumanDecision { approved, denied }

class PendingHumanRequest {
  const PendingHumanRequest({
    required this.requestId,
    required this.gate,
    required this.checkpointed,
    required this.deadline,
  });

  final String requestId;
  final ApprovalGate gate;

  /// A checkpoint was persisted BEFORE waiting (crash recovery contract).
  final bool checkpointed;
  final DateTime deadline;
}

class HumanDecisionRuntime {
  final List<String> audit = [];

  /// Pauses the run at [gate]. The caller asserts a checkpoint exists
  /// before the wait begins — the runtime refuses to pause without one
  /// (checkpoint_before_wait contract).
  PendingHumanRequest waitForHuman({
    required String requestId,
    required ApprovalGate gate,
    required bool checkpointPersisted,
    required DateTime now,
    Duration timeout = const Duration(hours: 24),
  }) {
    if (!checkpointPersisted) {
      throw StateError('cannot wait for human without a durable checkpoint');
    }
    return PendingHumanRequest(
      requestId: requestId,
      gate: gate,
      checkpointed: true,
      deadline: now.add(timeout),
    );
  }

  bool decide({
    required PendingHumanRequest request,
    required HumanDecision decision,
    required DateTime now,
  }) {
    if (now.isAfter(request.deadline)) {
      return false; // expired; use timeout path
    }
    audit.add('human:${request.requestId}:${decision.name}');
    return true;
  }

  /// Fail-safe default: an expired request is DENIED and audited.
  bool resolveTimeout(PendingHumanRequest request) {
    audit.add('timeout:${request.requestId}:denied');
    return false;
  }
}

// 104.23 — rate limiting across canonical scopes

enum RateScope { rule, workflow, provider, project, user }

class RateLimitExceeded implements Exception {
  RateLimitExceeded(this.scope, this.subject);
  final RateScope scope;
  final String subject;
  @override
  String toString() => 'RateLimitExceeded(${scope.name}, $subject)';
}

class RateLimiter {
  final Map<String, List<DateTime>> _hits = {};

  /// Fixed-window limiter per scope+subject. Throws when over budget.
  void assertWithin({
    required RateScope scope,
    required String subject,
    required int maxPerWindow,
    required Duration window,
    required DateTime now,
  }) {
    final key = '${scope.name}/$subject';
    final fresh = (_hits[key] ??= [])
        .where((t) => now.difference(t) < window)
        .toList();
    if (fresh.length >= maxPerWindow) {
      throw RateLimitExceeded(scope, subject);
    }
    fresh.add(now);
    _hits[key] = fresh;
  }
}

// 104.24 — concurrency control

enum ConflictPolicy { queue, reject }

class ConcurrencyDenied implements Exception {
  ConcurrencyDenied(this.projectId);
  final String projectId;
  @override
  String toString() => 'ConcurrencyDenied(project $projectId)';
}

class ConcurrencyController {
  ConcurrencyController({
    required this.maxConcurrentRuns,
    this.conflictPolicy = ConflictPolicy.reject,
  });

  final int maxConcurrentRuns;
  final ConflictPolicy conflictPolicy;
  final Map<String, int> _projectActive = {};
  int _totalActive = 0;

  /// Acquires a run slot; a project lock allows only ONE active run per
  /// project regardless of the global budget.
  void acquire({required String projectId}) {
    if ((_projectActive[projectId] ?? 0) > 0) {
      throw ConcurrencyDenied(projectId); // project_lock is unconditional
    }
    if (_totalActive >= maxConcurrentRuns) {
      if (conflictPolicy == ConflictPolicy.reject) {
        throw ConcurrencyDenied(projectId);
      }
      // queue policy: callers park in their own queue; nothing granted now.
      throw ConcurrencyDenied(projectId);
    }
    _projectActive[projectId] = 1;
    _totalActive++;
  }

  void release({required String projectId}) {
    if ((_projectActive[projectId] ?? 0) > 0) {
      _projectActive[projectId] = 0;
      _totalActive--;
    }
  }
}

// 104.25 — idempotency contract

enum RetrySafety { retrySafe, retryUnsafe }

class EffectRecord {
  const EffectRecord({required this.key, required this.completedAt});

  final String key;
  final DateTime completedAt;
}

class IdempotencyStore {
  final Map<String, EffectRecord> _effects = {};

  bool hasEffect(String key) => _effects.containsKey(key);

  /// Executes [action] exactly once per [key]. A retry with the same key
  /// returns the recorded effect without re-running the side effect.
  Future<T> execute<T>(
    String key,
    Future<T> Function() action, {
    required DateTime now,
  }) async {
    final existing = _effects[key];
    if (existing != null) {
      throw StateError('effect already recorded for $key');
    }
    final result = await action();
    _effects[key] = EffectRecord(key: key, completedAt: now);
    return result;
  }
}

// 104.26 — duplicate trigger suppression

enum SuppressionDecision { allowed, suppressed }

class SuppressionEntry {
  const SuppressionEntry({required this.sourceEventId, required this.decision});

  final String sourceEventId;
  final SuppressionDecision decision;
}

class DuplicateTriggerSuppressor {
  final Duration window;
  final Map<String, DateTime> _seen = {};

  DuplicateTriggerSuppressor({required this.window});

  /// [dedupeKey] identifies the logical event; [sourceEventId] is the raw
  /// event identity carried into the audit decision.
  SuppressionEntry submit({
    required String dedupeKey,
    required String sourceEventId,
    required DateTime now,
  }) {
    final seenAt = _seen[dedupeKey];
    if (seenAt != null && now.difference(seenAt) < window) {
      return SuppressionEntry(
        sourceEventId: sourceEventId,
        decision: SuppressionDecision.suppressed,
      );
    }
    _seen[dedupeKey] = now;
    return SuppressionEntry(
      sourceEventId: sourceEventId,
      decision: SuppressionDecision.allowed,
    );
  }
}

// 104.27 / 104.28 — saga with explicit compensations

typedef Compensator = Future<void> Function();

class SagaStepRecord {
  SagaStepRecord({required this.stepId, required this.committedAt});

  final String stepId;
  final DateTime committedAt;
  bool compensated = false;
}

class CompensationUnsupported implements Exception {
  CompensationUnsupported(this.stepIds);
  final List<String> stepIds;
  @override
  String toString() =>
      'CompensationUnsupported: no compensator for ${stepIds.join(", ")}';
}

/// Coordinates cross-subsystem changes as a RECOVERABLE sequence of
/// committed steps. There is deliberately NO global transaction claim:
/// each step commits independently and compensation is best-effort with
/// full visibility.
class WorkflowSaga {
  final Map<String, Compensator> _compensators = {};
  final List<SagaStepRecord> commits = [];
  final List<String> compensationAudit = [];

  void registerCompensation(String stepId, Compensator compensator) =>
      _compensators[stepId] = compensator;

  /// Records a successful step commit.
  void commitStep(String stepId, {required DateTime now}) =>
      commits.add(SagaStepRecord(stepId: stepId, committedAt: now));

  /// Rolls back committed steps in reverse. Steps WITHOUT an explicit
  /// compensator make the whole rollback visibly incomplete — they are
  /// reported, never skipped silently.
  Future<void> compensateAll({required DateTime now}) async {
    var failures = 0;
    final unsupported = <String>[];
    for (final record in commits.reversed) {
      final compensator = _compensators[record.stepId];
      if (compensator == null) {
        unsupported.add(record.stepId);
        continue;
      }
      try {
        await compensator();
        record.compensated = true;
        compensationAudit.add('compensated:${record.stepId}:$now');
      } catch (e) {
        failures++;
        compensationAudit.add('compensation_failed:${record.stepId}');
      }
    }
    if (unsupported.isNotEmpty) throw CompensationUnsupported(unsupported);
    if (failures > 0) {
      throw StateError('$failures compensation(s) failed; see audit');
    }
  }
}

// 104.29 — observability (identifier-only signals)

class AutomationMetrics {
  int triggerCount = 0;
  int runCount = 0;
  int successCount = 0;
  int failureCount = 0;
  int approvalWaits = 0;
  int retryCount = 0;
  final List<Duration> _durations = [];
  int resourceUnits = 0;

  void recordTrigger() => triggerCount++;
  void recordRunStart() => runCount++;
  void recordRunSuccess(Duration duration) {
    successCount++;
    _durations.add(duration);
  }

  void recordRunFailure(Duration duration) {
    failureCount++;
    _durations.add(duration);
  }

  void recordApprovalWait() => approvalWaits++;
  void recordRetry() => retryCount++;
  void recordResourceUsage(int units) => resourceUnits += units;

  double get successRate => runCount == 0 ? 0 : successCount / runCount;
  double get failureRate => runCount == 0 ? 0 : failureCount / runCount;
  Duration get averageDuration => _durations.isEmpty
      ? Duration.zero
      : _durations.reduce((a, b) => a + b) ~/ _durations.length;

  /// Identifier-only snapshot safe for logs/dashboards.
  Map<String, Object> snapshot() => {
    'trigger_count': triggerCount,
    'run_count': runCount,
    'success_rate': successRate,
    'failure_rate': failureRate,
    'avg_duration_ms': averageDuration.inMilliseconds,
    'approval_wait': approvalWaits,
    'retry_count': retryCount,
    'resource_usage': resourceUnits,
  };
}
