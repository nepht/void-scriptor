import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workflow/presentation/workflow_library_screen.dart';
import 'package:void_scriptor/workflow/workflow_definition.dart';
import 'package:void_scriptor/workflow/workflow_templates.dart';
import 'package:void_scriptor/workflow/workflow_validation.dart';

/// Sprint 103 / 103.24 — Workflow Library widget tests.
WorkflowDefinition tpl() {
  final now = DateTime.utc(2026, 8, 24);
  return WorkflowDefinition(
    workflowId: 'rename-asset',
    name: 'Rename asset',
    version: 2,
    steps: [WorkflowStep(stepId: 'do-rename', commandType: 'a.cmd')],
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
    )..register(tpl());
  });

  testWidgets('lists templates and instantiates on tap', (tester) async {
    WorkflowDefinition? instantiated;
    await tester.pumpWidget(
      MaterialApp(
        home: WorkflowLibraryScreen(
          registry: registry,
          onInstantiate: (d) => instantiated = d,
        ),
      ),
    );
    expect(find.text('rename-asset@2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('run-rename-asset@2')));
    expect(instantiated, isNotNull);
    expect(instantiated!.workflowId, startsWith('exec-'));
    expect(instantiated!.steps.single.stepId, 'do-rename');
  });

  testWidgets('empty registry shows explicit state', (tester) async {
    final empty = WorkflowTemplateRegistry(
      validationService: WorkflowValidationService(
        knownCommands: const {},
        commandCapabilities: const {},
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: WorkflowLibraryScreen(registry: empty)),
    );
    expect(find.text('No templates registered'), findsOneWidget);
  });
}
