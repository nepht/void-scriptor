import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/jobs/background_job_queue.dart';
import 'package:void_scriptor/workflow/workflow_definition.dart';
import 'package:void_scriptor/workflow/workflow_execution.dart';
import 'package:void_scriptor/workflow/workflow_recovery.dart';
import 'package:void_scriptor/workflow/workflow_runner.dart';

/// Sprint 103 / 103.16 — honest crash recovery over real checkpoints.
WorkflowDefinition wf(List<WorkflowStep> steps) {
  final now = DateTime.utc(2026, 8, 24);
  return WorkflowDefinition(
    workflowId: 'wf',
    name: 'w',
    version: 3,
    steps: steps,
    policy: const WorkflowPolicy(allowedCapabilities: {}),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late Directory dir;
  late BackgroundJobQueue queue;
  late WorkflowCheckpointStore store;
  late WorkflowRecoveryService recovery;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('wf-recovery');
    queue = BackgroundJobQueue(maxConcurrentJobs: 2);
    store = WorkflowCheckpointStore(dir);
    recovery = WorkflowRecoveryService(store: store);
  });

  tearDown(() {
    dir.deleteSync(recursive: true);
  });

  test('detects an interrupted run (non-terminal checkpoint)', () async {
    await store.writeAtomic(
      WorkflowCheckpoint(
        executionId: 'crash-1',
        workflowId: 'wf',
        workflowVersion: 3,
        completedSteps: ['a'],
        currentState: 'running',
      ),
    );
    final interrupted = recovery.detectInterruptedSync();
    expect(interrupted.single.executionId, 'crash-1');
    expect(interrupted.single.currentState, 'running');
  });

  test('terminal checkpoints are NOT offered for recovery', () async {
    await store.writeAtomic(
      WorkflowCheckpoint(
        executionId: 'done-1',
        workflowId: 'wf',
        workflowVersion: 3,
        completedSteps: ['a', 'b'],
        currentState: 'succeeded',
      ),
    );
    expect(recovery.detectInterruptedSync(), isEmpty);
  });

  test(
    'resume-from-checkpoint skips completed steps and finishes honestly',
    () async {
      await store.writeAtomic(
        WorkflowCheckpoint(
          executionId: 'crash-2',
          workflowId: 'wf',
          workflowVersion: 3,
          completedSteps: ['first'],
          currentState: 'running',
        ),
      );
      final workflow = wf([
        WorkflowStep(stepId: 'first', commandType: 'c'),
        WorkflowStep(
          stepId: 'second',
          commandType: 'c',
          dependsOn: const ['first'],
        ),
      ]);
      final ran = <String>[];
      final handle = recovery.resumeFromCheckpoint(
        runner: WorkflowRunner(queue: queue, checkpointDirectory: dir),
        checkpoint: store.readSync('crash-2')!,
        workflow: workflow,
        plan: WorkflowDependencyResolver().plan(workflow),
        work: (step, context, attempt) async {
          ran.add(step.stepId);
          return 'ok';
        },
      );
      final result = await handle.result.timeout(const Duration(seconds: 10));
      expect(result.state, WorkflowExecutionState.succeeded);
      expect(ran, ['second'], reason: 'completed steps must not re-execute');
      expect(result.completedSteps, containsAll(['first', 'second']));
    },
  );

  test(
    'cancel-and-cleanup deletes the checkpoint; inspect-only reads it',
    () async {
      await store.writeAtomic(
        WorkflowCheckpoint(
          executionId: 'crash-3',
          workflowId: 'wf',
          workflowVersion: 3,
          currentState: 'running',
        ),
      );
      final inspected = store.readSync('crash-3');
      expect(inspected, isNotNull);
      expect(inspected!.currentState, 'running');
      recovery.cancelAndCleanupSync('crash-3');
      expect(store.readSync('crash-3'), isNull);
      expect(recovery.detectInterruptedSync(), isEmpty);
    },
  );
}
