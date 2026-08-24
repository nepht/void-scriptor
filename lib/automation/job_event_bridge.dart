library;

import 'dart:async';

import 'automation_condition.dart';
import 'automation_rule.dart';
import 'job_triggers.dart';
import 'workflow_trigger.dart';
import '../core/jobs/background_job.dart';

/// Sprint 104 / 104.13 — the JOB side of the canonical event-bus
/// integration (104.8). Subscribes to `BackgroundJobQueue.updates`
/// (the existing queue stream — no second bus) and translates terminal
/// statuses into job trigger firings:
///
/// completed → jobSucceeded · failed → jobFailed · cancelled → jobCancelled.
///
/// queued/running are non-terminal and can never fire. Facts are the
/// identifier-only vocabulary from `job_triggers.dart`. [dispose] is
/// idempotent.

typedef JobFireHandler =
    void Function(String ruleId, Map<String, Object> facts);

class JobEventBridge {
  JobEventBridge({
    Stream<BackgroundJob>? jobUpdates,
    List<AutomationRule> rules = const [],
    required this.onFire,
  }) : _rules = List.of(rules) {
    final jobs = jobUpdates;
    if (jobs != null) {
      _subscription = jobs.listen(_onJobUpdate);
    }
  }

  final JobFireHandler onFire;
  final List<AutomationRule> _rules;
  StreamSubscription<BackgroundJob>? _subscription;
  bool _disposed = false;

  void register(AutomationRule rule) => _rules.add(rule);

  void _onJobUpdate(BackgroundJob job) {
    if (_disposed) return;
    final JobRuntimeEvent? event = switch (job.status) {
      BackgroundJobStatus.completed => JobRuntimeEvent.jobSucceeded,
      BackgroundJobStatus.failed => JobRuntimeEvent.jobFailed,
      BackgroundJobStatus.cancelled => JobRuntimeEvent.jobCancelled,
      _ => null,
    };
    if (event == null) return;
    final facts = jobFacts(event, jobId: job.id, projectId: job.projectId);
    for (final rule in _rules.where(
      (r) => r.enabled && r.trigger.type == WorkflowTriggerType.jobEvent,
    )) {
      onFire(rule.ruleId, Map.of(facts));
    }
  }

  /// Idempotent: a second call is a no-op; disposed bridges stay silent.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_subscription?.cancel());
    _rules.clear();
  }
}

/// Convenience: evaluate a rule's conditions against job facts using the
/// deterministic 104.6 engine.
bool ruleMatchesJobFacts(
  AutomationRule rule,
  Map<String, Object> facts,
  AutomationConditionEngine engine,
) =>
    rule.enabled &&
    engine.allMatch(rule.conditions, AutomationContext(facts: facts));
