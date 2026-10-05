import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/automation/automation_rule.dart';
import 'package:void_scriptor/automation/job_event_bridge.dart';
import 'package:void_scriptor/automation/workflow_trigger.dart';
import 'package:void_scriptor/core/jobs/background_job.dart';

/// Sprint 104 / 104.13 — the job side of the event-bus integration:
/// terminal `BackgroundJobQueue.updates` statuses translate into job
/// trigger firings. No second bus; cleanup is explicit; queued/running
/// never fire.
void main() {
  BackgroundJob jobOf(BackgroundJobStatus status) => BackgroundJob(
    id: 'j-1',
    projectId: 'p-1',
    type: BackgroundJobType.export,
    label: 'Export story package',
    status: status,
    priority: BackgroundJobPriority.normal,
    progress: 1,
    createdAt: DateTime.utc(2026, 8, 25),
    persistence: JobPersistence.transient,
  );

  test('terminal statuses map to canonical job events', () async {
    final seen = <Map<String, Object>>[];
    final stream = StreamController<BackgroundJob>.broadcast();
    final rule = AutomationRule(
      ruleId: 'r-job',
      trigger: WorkflowTrigger(
        triggerId: 't-job',
        type: WorkflowTriggerType.jobEvent,
        configuration: const {},
        createdAt: DateTime.utc(2026, 8, 25),
        updatedAt: DateTime.utc(2026, 8, 25),
      ),
      conditions: const [],
      workflowId: 'wf-1',
    );
    // The bridge is intentionally unnamed: only its side effects matter.
    JobEventBridge(
      jobUpdates: stream.stream,
      rules: [rule],
      onFire: (ruleId, facts) => seen.add(facts),
    );
    await Future<void>.delayed(Duration.zero);

    for (final status in [
      BackgroundJobStatus.completed,
      BackgroundJobStatus.failed,
      BackgroundJobStatus.cancelled,
    ]) {
      stream.add(jobOf(status));
    }
    await Future<void>.delayed(Duration.zero);
    await stream.close();

    expect(seen.map((f) => f['job.event']).toList(), [
      'jobSucceeded',
      'jobFailed',
      'jobCancelled',
    ]);
    expect(seen.every((f) => f['job.id'] == 'j-1'), isTrue);
  });

  test('queued and running updates NEVER fire', () async {
    var fires = 0;
    final stream = StreamController<BackgroundJob>.broadcast();
    JobEventBridge(jobUpdates: stream.stream, onFire: (_, _) => fires++);
    await Future<void>.delayed(Duration.zero);

    stream.add(jobOf(BackgroundJobStatus.queued));
    stream.add(jobOf(BackgroundJobStatus.running));
    await Future<void>.delayed(Duration.zero);

    expect(fires, 0);
    await stream.close();
  });

  test('disabled rules stay silent', () async {
    var fires = 0;
    final stream = StreamController<BackgroundJob>.broadcast();
    final rule = AutomationRule(
      ruleId: 'r-job',
      trigger: WorkflowTrigger(
        triggerId: 't-job',
        type: WorkflowTriggerType.jobEvent,
        configuration: const {},
        createdAt: DateTime.utc(2026, 8, 25),
        updatedAt: DateTime.utc(2026, 8, 25),
      ),
      conditions: const [],
      workflowId: 'wf-1',
      enabled: false,
    );
    JobEventBridge(
      jobUpdates: stream.stream,
      rules: [rule],
      onFire: (_, _) => fires++,
    );
    await Future<void>.delayed(Duration.zero);

    stream.add(jobOf(BackgroundJobStatus.completed));
    await Future<void>.delayed(Duration.zero);
    expect(fires, 0);
    await stream.close();
  });

  test('dispose cancels the subscription exactly once (idempotent)', () async {
    var fires = 0;
    final stream = StreamController<BackgroundJob>.broadcast();
    final bridge = JobEventBridge(
      jobUpdates: stream.stream,
      onFire: (_, _) => fires++,
    );
    bridge.dispose();
    bridge.dispose();

    unawaited(stream.close());
    expect(fires, 0);
  });
}
