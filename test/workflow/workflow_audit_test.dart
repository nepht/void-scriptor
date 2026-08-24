import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/workflow/workflow_audit.dart';
import 'package:void_scriptor/workflow/workflow_runner.dart';

/// Sprint 103 / 103.27 — audit trail for workflow decisions.
void main() {
  test('all canonical event kinds are auditable', () {
    expect(
      WorkflowAuditEventKind.values.map((k) => k.name).toSet(),
      equals({
        'created',
        'validated',
        'started',
        'paused',
        'resumed',
        'cancelled',
        'failed',
        'recovered',
        'completed',
      }),
    );
  });

  test('trail records events without leaking payload content', () {
    final trail = WorkflowAuditTrail();
    trail.record(
      kind: WorkflowAuditEventKind.started,
      executionId: 'e1',
      workflowId: 'wf',
      detail: 'secret story text must NOT be stored',
    );
    final entry = trail.entries.single;
    expect(entry.kind, WorkflowAuditEventKind.started);
    expect(entry.executionId, 'e1');
    expect(entry.toJson().toString().contains('secret'), isFalse);
  });

  test('forStepEvents maps runner events to audit kinds', () {
    expect(
      WorkflowAuditTrail.forRunnerEvent(
        const WorkflowRunnerEvent(
          kind: WorkflowRunnerEventKind.completed,
          executionId: 'e1',
        ),
      ).kind,
      WorkflowAuditEventKind.completed,
    );
    expect(
      WorkflowAuditTrail.forRunnerEvent(
        const WorkflowRunnerEvent(
          kind: WorkflowRunnerEventKind.stepFailed,
          executionId: 'e1',
        ),
      ).kind,
      WorkflowAuditEventKind.failed,
    );
  });
}
