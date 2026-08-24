import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/workflow/workflow_definition.dart';
import 'package:void_scriptor/workflow/workflow_execution.dart';

/// Sprint 103 / 103.12 — deterministic dependency resolution + cycle
/// detection over the workflow step graph.
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
  test('independent steps resolve in declaration order', () {
    final plan = WorkflowDependencyResolver().plan(
      wf([
        WorkflowStep(stepId: 'a', commandType: 'c'),
        WorkflowStep(stepId: 'b', commandType: 'c'),
      ]),
    );
    expect(plan.executionOrder, ['a', 'b']);
    expect(plan.readyAt(0), equals({'a', 'b'}));
  });

  test('dependents come after dependencies (deterministic order)', () {
    final plan = WorkflowDependencyResolver().plan(
      wf([
        WorkflowStep(stepId: 'z', commandType: 'c', dependsOn: const ['b']),
        WorkflowStep(stepId: 'b', commandType: 'c'),
        WorkflowStep(stepId: 'm', commandType: 'c', dependsOn: const ['b']),
      ]),
    );
    expect(
      plan.executionOrder.indexOf('b'),
      lessThan(plan.executionOrder.indexOf('z')),
    );
    expect(
      plan.executionOrder.indexOf('b'),
      lessThan(plan.executionOrder.indexOf('m')),
    );
  });

  test('cycle detection throws with the cycle members', () {
    expect(
      () => WorkflowDependencyResolver().plan(
        wf([
          WorkflowStep(stepId: 's1', commandType: 'c', dependsOn: const ['s2']),
          WorkflowStep(stepId: 's2', commandType: 'c', dependsOn: const ['s1']),
        ]),
      ),
      throwsA(
        isA<WorkflowCycleException>().having(
          (e) => e.cycle.toSet().containsAll({'s1', 's2'}),
          'reports both members',
          isTrue,
        ),
      ),
    );
  });

  test('self-dependency is a cycle', () {
    expect(
      () => WorkflowDependencyResolver().plan(
        wf([
          WorkflowStep(stepId: 'x', commandType: 'c', dependsOn: const ['x']),
        ]),
      ),
      throwsA(isA<WorkflowCycleException>()),
    );
  });

  test('unknown dependency reference throws', () {
    expect(
      () => WorkflowDependencyResolver().plan(
        wf([
          WorkflowStep(
            stepId: 'a',
            commandType: 'c',
            dependsOn: const ['ghost'],
          ),
        ]),
      ),
      throwsA(isA<UnknownStepReference>()),
    );
  });
}
