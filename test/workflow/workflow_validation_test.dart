import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/workflow/workflow_definition.dart';
import 'package:void_scriptor/workflow/workflow_validation.dart';

/// Sprint 103 / 103.6 — reject invalid workflows before execution.
///
/// Canonical validation_rules: unique_step_ids, known_commands,
/// valid_bindings, acyclic_dependencies, permission_compatibility.
WorkflowDefinition build({
  List<WorkflowStep> steps = const [],
  Set<String> commands = const {'a.cmd'},
  List<String> inputs = const [],
}) {
  final now = DateTime.utc(2026, 8, 24);
  return WorkflowDefinition(
    workflowId: 'wf',
    name: 'w',
    version: 1,
    steps: steps,
    inputs: inputs,
    outputs: const [],
    policy: const WorkflowPolicy(allowedCapabilities: {'fs.read'}),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  final service = WorkflowValidationService(knownCommands: const {'a.cmd'});

  test('accepts a minimal valid workflow', () {
    final issues = service.validate(
      build(
        steps: [WorkflowStep(stepId: 's1', commandType: 'a.cmd')],
      ),
    );
    expect(issues, isEmpty);
  });

  test('rejects duplicate step ids', () {
    final issues = service.validate(
      build(
        steps: [
          WorkflowStep(stepId: 's1', commandType: 'a.cmd'),
          WorkflowStep(stepId: 's1', commandType: 'a.cmd'),
        ],
      ),
    );
    expect(issues.map((i) => i.code), contains('unique_step_ids'));
  });

  test('rejects unknown commands', () {
    final issues = service.validate(
      build(
        steps: [WorkflowStep(stepId: 's1', commandType: 'nope')],
      ),
    );
    expect(issues.map((i) => i.code), contains('known_commands'));
  });

  test('rejects a binding that references an undeclared source', () {
    final issues = service.validate(
      build(
        inputs: ['project'],
        steps: [
          WorkflowStep(
            stepId: 's1',
            commandType: 'a.cmd',
            inputBindings: [const WorkflowBinding('x', 'ghost.value')],
          ),
        ],
      ),
    );
    expect(issues.map((i) => i.code), contains('valid_bindings'));
  });

  test('accepts binding from declared input or earlier step output', () {
    final issues = service.validate(
      build(
        inputs: ['project'],
        steps: [
          WorkflowStep(
            stepId: 's1',
            commandType: 'a.cmd',
            outputBindings: [const WorkflowBinding('mid', 'out.mid')],
          ),
          WorkflowStep(
            stepId: 's2',
            commandType: 'a.cmd',
            dependsOn: const ['s1'],
            inputBindings: [
              const WorkflowBinding('p', 'in.project'),
              const WorkflowBinding('m', 'step.s1.mid'),
            ],
          ),
        ],
      ),
    );
    expect(issues, isEmpty);
  });

  test('rejects dependency cycles', () {
    final issues = service.validate(
      build(
        steps: [
          WorkflowStep(
            stepId: 's1',
            commandType: 'a.cmd',
            dependsOn: const ['s2'],
          ),
          WorkflowStep(
            stepId: 's2',
            commandType: 'a.cmd',
            dependsOn: const ['s1'],
          ),
        ],
      ),
    );
    expect(issues.map((i) => i.code), contains('acyclic_dependencies'));
  });

  test('rejects unknown dependency references', () {
    final issues = service.validate(
      build(
        steps: [
          WorkflowStep(
            stepId: 's1',
            commandType: 'a.cmd',
            dependsOn: const ['ghost'],
          ),
        ],
      ),
    );
    expect(issues.map((i) => i.code), contains('unknown_dependency'));
  });

  test('permission_compatibility: capability beyond policy is rejected', () {
    final strictService = WorkflowValidationService(
      knownCommands: const {'a.cmd'},
      commandCapabilities: const {
        'a.cmd': {'net.write'},
      },
    );
    final issues = strictService.validate(
      build(
        steps: [WorkflowStep(stepId: 's1', commandType: 'a.cmd')],
      ),
    );
    expect(issues.map((i) => i.code), contains('permission_compatibility'));
  });
}
