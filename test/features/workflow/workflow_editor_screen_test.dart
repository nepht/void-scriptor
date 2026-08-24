import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workflow/presentation/workflow_editor_screen.dart';
import 'package:void_scriptor/workflow/workflow_definition.dart';
import 'package:void_scriptor/workflow/workflow_validation.dart';

/// Sprint 103 / 103.25 — Workflow Editor widget tests.
WorkflowValidationService service() => WorkflowValidationService(
  knownCommands: const {'manual.noop'},
  commandCapabilities: const {'manual.noop': {}},
);

void main() {
  testWidgets('draft validates live; save only when clean', (tester) async {
    WorkflowDefinition? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: WorkflowEditorScreen(
          validationService: service(),
          defaultCommandType: 'manual.noop',
          onSave: (d) => saved = d,
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('editor-id')), 'my-flow');
    await tester.enterText(find.byKey(const Key('editor-name')), 'My Flow');
    await tester.pump();
    // No steps yet -> draft incomplete, no issues shown either.
    expect(find.byKey(const Key('editor-save')), findsNothing);

    await tester.enterText(find.byKey(const Key('editor-steps')), 'one, two');
    await tester.pump();
    expect(find.byKey(const Key('editor-issues')), findsNothing);
    await tester.tap(find.byKey(const Key('editor-save')));
    expect(saved, isNotNull);
    expect(saved!.steps.map((s) => s.stepId), ['one', 'two']);
    expect(saved!.version, 1);
  });

  testWidgets('duplicate step ids surface validation issues', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WorkflowEditorScreen(
          validationService: service(),
          defaultCommandType: 'manual.noop',
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('editor-id')), 'dup');
    await tester.enterText(find.byKey(const Key('editor-steps')), 'x, x');
    await tester.pump();
    expect(find.byKey(const Key('editor-issues')), findsOneWidget);
  });
}
