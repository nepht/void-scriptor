import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/workflow/workflow_execution.dart';

/// Sprint 103 / 103.7 — explicit execution state machine (9 canonical states).
void main() {
  test('all nine canonical states exist', () {
    expect(
      WorkflowExecutionState.values.map((s) => s.name).toSet(),
      equals({
        'queued',
        'running',
        'pausing',
        'paused',
        'cancelling',
        'cancelled',
        'succeeded',
        'failed',
        'recovering',
      }),
    );
  });

  test('legal transitions from queued', () {
    expect(WorkflowExecutionState.queued.canGoTo('running'), isTrue);
    expect(WorkflowExecutionState.queued.canGoTo('cancelled'), isTrue);
    expect(WorkflowExecutionState.queued.canGoTo('succeeded'), isFalse);
  });

  test('pause path: running -> pausing -> paused -> running', () {
    expect(WorkflowExecutionState.running.canGoTo('pausing'), isTrue);
    expect(WorkflowExecutionState.pausing.canGoTo('paused'), isTrue);
    expect(WorkflowExecutionState.paused.canGoTo('running'), isTrue);
  });

  test('cancel is reachable while active, terminal states accept nothing', () {
    expect(WorkflowExecutionState.running.canGoTo('cancelling'), isTrue);
    expect(WorkflowExecutionState.cancelling.canGoTo('cancelled'), isTrue);
    expect(WorkflowExecutionState.cancelling.canGoTo('failed'), isFalse);
    for (final t in [
      WorkflowExecutionState.cancelled,
      WorkflowExecutionState.succeeded,
      WorkflowExecutionState.failed,
    ]) {
      expect(
        t.canGoTo('running'),
        isFalse,
        reason: '${t.name} must be terminal',
      );
    }
  });

  test('failure and recovery loop', () {
    expect(WorkflowExecutionState.failed.canGoTo('recovering'), isTrue);
    expect(WorkflowExecutionState.recovering.canGoTo('running'), isTrue);
    expect(WorkflowExecutionState.recovering.canGoTo('cancelled'), isTrue);
    expect(WorkflowExecutionState.succeeded.canGoTo('failed'), isFalse);
  });

  test('byName is case-insensitive and throws on unknown', () {
    expect(
      WorkflowExecutionState.byName('RUNNING'),
      same(WorkflowExecutionState.running),
    );
    expect(() => WorkflowExecutionState.byName('nope'), throwsArgumentError);
  });
}
