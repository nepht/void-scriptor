import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/workflow/workflow_definition.dart';
import 'package:void_scriptor/workflow/workflow_limits.dart';

/// Sprint 103 / 103.28 — performance & resource limits.
WorkflowDefinition wfWithSteps(int n) {
  final now = DateTime.utc(2026, 8, 24);
  return WorkflowDefinition(
    workflowId: 'wf',
    name: 'w',
    version: 1,
    steps: List.generate(
      n,
      (i) => WorkflowStep(stepId: 's$i', commandType: 'c'),
    ),
    policy: const WorkflowPolicy(allowedCapabilities: {}),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('WorkflowResourceLimits (103.28)', () {
    test('defaults are bounded and documented', () {
      const limits = WorkflowResourceLimits();
      expect(limits.maxConcurrentExecutions, greaterThan(0));
      expect(limits.maxConcurrentExecutions, lessThanOrEqualTo(8));
      expect(limits.maxStepsPerWorkflow, greaterThan(0));
      expect(limits.maxCheckpointFileBytes, greaterThan(0));
    });

    test('rejects oversized workflows before execution', () {
      const limits = WorkflowResourceLimits(maxStepsPerWorkflow: 3);
      expect(
        () => limits.assertWorkflowAllowed(wfWithSteps(2).steps.length),
        returnsNormally,
      );
      expect(
        () => limits.assertWorkflowAllowed(wfWithSteps(4).steps.length),
        throwsA(isA<WorkflowLimitExceeded>()),
      );
    });

    test('execution slots: acquire up to max, release frees a slot', () {
      const limits = WorkflowResourceLimits(maxConcurrentExecutions: 2);
      final enforcer = WorkflowExecutionSlotTracker(limits: limits);
      expect(enforcer.tryAcquire(), isTrue);
      expect(enforcer.tryAcquire(), isTrue);
      expect(enforcer.tryAcquire(), isFalse, reason: 'cap reached');
      enforcer.release();
      expect(enforcer.tryAcquire(), isTrue);
    });
  });
}
