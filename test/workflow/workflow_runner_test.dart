import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/jobs/background_job_queue.dart';
import 'package:void_scriptor/workflow/workflow_definition.dart';
import 'package:void_scriptor/workflow/workflow_execution.dart';
import 'package:void_scriptor/workflow/workflow_policies.dart';
import 'package:void_scriptor/workflow/workflow_runner.dart';

/// Sprint 103 / 103.8-103.16 — runner over the EXISTING BackgroundJobQueue.
WorkflowDefinition wf(List<WorkflowStep> steps) {
  final now = DateTime.utc(2026, 8, 24);
  return WorkflowDefinition(
    workflowId: 'wf',
    name: 'w',
    version: 1,
    steps: steps,
    inputs: const [],
    outputs: const [],
    policy: const WorkflowPolicy(allowedCapabilities: {}),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late BackgroundJobQueue queue;

  setUp(() {
    queue = BackgroundJobQueue(maxConcurrentJobs: 2);
  });

  test('runs an independent two-step workflow to completion', () async {
    final runner = WorkflowRunner(queue: queue);
    final workflow = wf([
      WorkflowStep(stepId: 'a', commandType: 'c'),
      WorkflowStep(stepId: 'b', commandType: 'c'),
    ]);
    final handle = runner.start(
      workflow: workflow,
      plan: WorkflowDependencyResolver().plan(workflow),
      executionId: 'e-ok',
      work: (step, context, attempt) async => step.stepId,
    );
    final result = await handle.result.timeout(const Duration(seconds: 10));
    expect(result.state, WorkflowExecutionState.succeeded);
    expect(result.completedSteps, containsAll(['a', 'b']));
  });

  test(
    'respects dependencies: dependent step waits for its dependency',
    () async {
      final runner = WorkflowRunner(queue: queue);
      final order = <String>[];
      final workflow = wf([
        WorkflowStep(stepId: 'z', commandType: 'c', dependsOn: const ['b']),
        WorkflowStep(stepId: 'b', commandType: 'c'),
      ]);
      final handle = runner.start(
        workflow: workflow,
        plan: WorkflowDependencyResolver().plan(workflow),
        executionId: 'e-dep',
        work: (step, context, attempt) async {
          order.add(step.stepId);
          return step.stepId;
        },
      );
      await handle.result.timeout(const Duration(seconds: 10));
      expect(order.indexOf('b'), lessThan(order.indexOf('z')));
    },
  );

  test('retries a transient failure up to the policy bound', () async {
    final runner = WorkflowRunner(queue: queue);
    final workflow = wf([
      WorkflowStep(
        stepId: 'flaky',
        commandType: 'c',
        retryPolicy: const WorkflowRetryPolicy(maxAttempts: 3),
      ),
    ]);
    var attempts = 0;
    final handle = runner.start(
      workflow: workflow,
      plan: WorkflowDependencyResolver().plan(workflow),
      executionId: 'e-retry',
      work: (step, context, attempt) async {
        attempts = attempt;
        if (attempt < 3) throw Exception('transient.io');
        return 'ok';
      },
    );
    final result = await handle.result.timeout(const Duration(seconds: 10));
    expect(result.state, WorkflowExecutionState.succeeded);
    expect(attempts, 3);
  });

  test('timeout kills a hanging step and fails the workflow', () async {
    final runner = WorkflowRunner(queue: queue);
    final workflow = wf([
      WorkflowStep(
        stepId: 'hang',
        commandType: 'c',
        timeout: const Duration(milliseconds: 50),
      ),
    ]);
    final handle = runner.start(
      workflow: workflow,
      plan: WorkflowDependencyResolver().plan(workflow),
      executionId: 'e-timeout',
      work: (step, context, attempt) =>
          Future<void>.delayed(const Duration(seconds: 5)),
    );
    final result = await handle.result.timeout(const Duration(seconds: 10));
    expect(result.state, WorkflowExecutionState.failed);
  });

  test(
    'optional failing step is skipped and workflow still completes',
    () async {
      final runner = WorkflowRunner(queue: queue);
      final workflow = wf([
        WorkflowStep(stepId: 'must', commandType: 'c'),
        WorkflowStep(stepId: 'nice', commandType: 'c', optional: true),
      ]);
      final handle = runner.start(
        workflow: workflow,
        plan: WorkflowDependencyResolver().plan(workflow),
        executionId: 'e-optional',
        work: (step, context, attempt) async {
          if (step.stepId == 'nice') throw Exception('boom');
          return 'ok';
        },
      );
      final result = await handle.result.timeout(const Duration(seconds: 10));
      expect(result.state, WorkflowExecutionState.succeeded);
      expect(result.completedSteps, contains('must'));
      expect(result.completedSteps, isNot(contains('nice')));
    },
  );

  test('mandatory failure stops dependents and marks the run failed', () async {
    final runner = WorkflowRunner(queue: queue);
    final ran = <String>{};
    final workflow = wf([
      WorkflowStep(stepId: 'bad', commandType: 'c'),
      WorkflowStep(stepId: 'after', commandType: 'c', dependsOn: const ['bad']),
    ]);
    final handle = runner.start(
      workflow: workflow,
      plan: WorkflowDependencyResolver().plan(workflow),
      executionId: 'e-fail',
      work: (step, context, attempt) async {
        ran.add(step.stepId);
        if (step.stepId == 'bad') throw Exception('fatal');
        return 'ok';
      },
    );
    final result = await handle.result.timeout(const Duration(seconds: 10));
    expect(result.state, WorkflowExecutionState.failed);
    expect(ran.contains('after'), isFalse);
  });

  test(
    'cancel before start finishes cancelled with nothing launched',
    () async {
      final runner = WorkflowRunner(queue: queue);
      final workflow = wf([WorkflowStep(stepId: 'a', commandType: 'c')]);
      final handle = runner.start(
        workflow: workflow,
        plan: WorkflowDependencyResolver().plan(workflow),
        executionId: 'e-cancel',
        work: (step, context, attempt) async => 'ok',
      );
      await runner.cancel('e-cancel');
      final result = await handle.result.timeout(const Duration(seconds: 10));
      expect(result.state, WorkflowExecutionState.cancelled);
      expect(handle.launched, isEmpty);
    },
  );

  test('pause holds the next boundary; resume releases it', () async {
    final runner = WorkflowRunner(queue: queue);
    final workflow = wf([
      WorkflowStep(stepId: 'first', commandType: 'c'),
      WorkflowStep(
        stepId: 'second',
        commandType: 'c',
        dependsOn: const ['first'],
      ),
    ]);
    final handle = runner.start(
      workflow: workflow,
      plan: WorkflowDependencyResolver().plan(workflow),
      executionId: 'e-pause',
      work: (step, context, attempt) async {
        // After the first step completes, pause before 'second' starts.
        if (step.stepId == 'first') runner.pause('e-pause');
        return step.stepId;
      },
    );
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(handle.finished, contains('first'));
    expect(handle.launched.contains('second'), isFalse);
    runner.resume('e-pause');
    final result = await handle.result.timeout(const Duration(seconds: 10));
    expect(result.state, WorkflowExecutionState.succeeded);
    expect(result.completedSteps, containsAll(['first', 'second']));
  });

  test(
    'checkpoints are written atomically after each completed step',
    () async {
      final dir = await Directory.systemTemp.createTemp('wf-checkpoints');
      final runner = WorkflowRunner(queue: queue, checkpointDirectory: dir);
      final workflow = wf([
        WorkflowStep(stepId: 's1', commandType: 'c'),
        WorkflowStep(stepId: 's2', commandType: 'c'),
      ]);
      final handle = runner.start(
        workflow: workflow,
        plan: WorkflowDependencyResolver().plan(workflow),
        executionId: 'e-ckpt',
        work: (step, context, attempt) async => step.stepId,
      );
      await handle.result.timeout(const Duration(seconds: 10));
      final store = WorkflowCheckpointStore(dir);
      final restored = await store.read('e-ckpt');
      expect(restored, isNotNull);
      expect(restored!.workflowVersion, 1);
      expect(restored.currentState, 'succeeded');
      expect(restored.completedSteps, isNotEmpty);
      expect(await store.read('missing-exec'), isNull);
      await dir.delete(recursive: true);
    },
  );
}
