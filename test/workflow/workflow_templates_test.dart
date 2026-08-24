import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/workflow/workflow_definition.dart';
import 'package:void_scriptor/workflow/workflow_templates.dart';
import 'package:void_scriptor/workflow/workflow_validation.dart';

/// Sprint 103 / 103.23 — versioned template registry.
///
/// Templates are validated at registration; untrusted template content is
/// never auto-executed (trusted_execution_by_default=false).
WorkflowDefinition template({
  String id = 'tpl',
  int version = 1,
  List<WorkflowStep>? steps,
}) {
  final now = DateTime.utc(2026, 8, 24);
  return WorkflowDefinition(
    workflowId: id,
    name: 't',
    version: version,
    steps: steps ?? [WorkflowStep(stepId: 's1', commandType: 'a.cmd')],
    policy: const WorkflowPolicy(allowedCapabilities: {'fs.read'}),
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late WorkflowTemplateRegistry registry;

  setUp(() {
    registry = WorkflowTemplateRegistry(
      validationService: WorkflowValidationService(
        knownCommands: const {'a.cmd'},
        commandCapabilities: const {
          'a.cmd': {'fs.read'},
        },
      ),
    );
  });

  test('registers valid templates and instantiates them by id', () {
    registry.register(template());
    final instance = registry.instantiate(
      templateId: 'tpl',
      newExecutionId: 'exec-42',
    );
    expect(instance.workflowId, 'exec-42');
    expect(instance.name, 't');
    expect(instance.steps.single.stepId, 's1');
  });

  test('rejects invalid templates at registration time', () {
    expect(
      () => registry.register(
        template(
          steps: [WorkflowStep(stepId: 'x', commandType: 'unknown.cmd')],
        ),
      ),
      throwsA(isA<WorkflowTemplateInvalid>()),
    );
  });

  test('same-version re-registration is rejected (immutability)', () {
    registry.register(template(version: 2));
    expect(
      () => registry.register(template(version: 2)),
      throwsA(isA<WorkflowTemplateConflict>()),
    );
  });

  test('instantiating an unknown template fails loudly', () {
    expect(
      () => registry.instantiate(templateId: 'ghost', newExecutionId: 'e'),
      throwsA(isA<WorkflowTemplateNotFound>()),
    );
  });
}
