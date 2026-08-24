import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/automation/automation_rule.dart';
import 'package:void_scriptor/automation/safety_runtime.dart';
import 'package:void_scriptor/automation/workflow_trigger.dart';
import 'package:void_scriptor/features/workflow/presentation/automation_center_screen.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

AutomationRule sampleRule() => AutomationRule(
  ruleId: 'r-1',
  trigger: WorkflowTrigger(
    triggerId: 't-1',
    type: WorkflowTriggerType.jobEvent,
    configuration: const {},
    createdAt: DateTime.utc(2026, 8, 25),
    updatedAt: DateTime.utc(2026, 8, 25),
  ),
  conditions: const [],
  workflowId: 'wf-1',
);

void main() {
  testWidgets('renders rules and metrics snapshot without overflow', (
    tester,
  ) async {
    final metrics = AutomationMetrics()
      ..recordTrigger()
      ..recordRunStart()
      ..recordRunSuccess(const Duration(milliseconds: 90));

    await tester.pumpWidget(
      _wrap(
        AutomationCenterScreen(
          rules: [sampleRule()],
          metricsSnapshot: metrics.snapshot(),
        ),
      ),
    );

    expect(find.byKey(const Key('automation-center')), findsOneWidget);
    expect(find.text('r-1'), findsOneWidget);
    expect(find.byKey(const Key('metrics-panel')), findsOneWidget);

    // Desktop and phone widths must both stay overflow-free.
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('rule editor validates before enabling save', (tester) async {
    String? savedWorkflow;
    await tester.pumpWidget(
      _wrap(
        RuleEditorScreen(
          validatorRules: const {'job.status': true},
          onSave: (rule) => savedWorkflow = rule.workflowId,
        ),
      ),
    );

    // Empty draft: no save button yet.
    expect(find.byKey(const Key('editor-save')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('editor-workflow')),
      'wf-export',
    );
    await tester.pump();

    final saveFinder = find.byKey(const Key('editor-save'));
    expect(saveFinder, findsOneWidget);
    await tester.tap(saveFinder);
    await tester.pump();

    expect(savedWorkflow, 'wf-export');
  });

  testWidgets('templates list can instantiate into a rule', (tester) async {
    AutomationRule? instantiated;
    await tester.pumpWidget(
      _wrap(
        AutomationTemplatesScreen(onInstantiate: (rule) => instantiated = rule),
      ),
    );

    expect(find.byKey(const Key('template-list')), findsOneWidget);
    await tester.tap(find.byKey(const Key('template-instantiate-0')).first);
    await tester.pump();

    expect(instantiated, isNotNull);
    expect(instantiated!.workflowId, isNotEmpty);
  });

  group('104.33 import & export', () {
    test('export produces JSON; import round-trips the same rules', () {
      final rules = [sampleRule()];
      final jsonText = exportRules(rules);
      final imported = importRules(jsonText);
      expect(imported.single.ruleId, 'r-1');
      expect(imported.single.workflowId, 'wf-1');
      expect(imported.single.trigger.type, WorkflowTriggerType.jobEvent);
    });

    test('import refuses payloads with secret-shaped keys', () {
      const malicious =
          '[{"ruleId":"r-x","secret_key":"hunter2","workflowId":"w"}]';
      expect(() => importRules(malicious), throwsArgumentError);
    });
  });
}
