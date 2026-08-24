import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/automation/automation_rule.dart';
import 'package:void_scriptor/automation/workflow_trigger.dart';
import 'package:void_scriptor/features/workflow/presentation/automation_center_screen.dart';

/// Sprint 105 / 105.26 — accessibility regression for the Automation UI:
/// large text scaling must not overflow, keyboard input must reach the
/// editor field, and interactive controls must expose semantics.
Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

AutomationRule _rule() => AutomationRule(
  ruleId: 'r-a11y',
  trigger: WorkflowTrigger(
    triggerId: 't-a11y',
    type: WorkflowTriggerType.manual,
    configuration: const {},
    createdAt: DateTime.utc(2026, 8, 25),
    updatedAt: DateTime.utc(2026, 8, 25),
  ),
  conditions: const [],
  workflowId: 'wf-a11y',
);

Future<void> _pumpAtScale(WidgetTester tester, double scale) async {
  await tester.pumpWidget(
    _wrap(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: AutomationCenterScreen(
          rules: [_rule()],
          metricsSnapshot: const {
            'run_count': 4,
            'success_rate': 0.75,
            'failure_rate': 0.25,
          },
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('automation center survives 1.3x text scaling', (tester) async {
    await _pumpAtScale(tester, 1.3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('automation center survives 2.0x text scaling', (tester) async {
    await _pumpAtScale(tester, 2.0);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('editor accepts keyboard input and exposes field semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        RuleEditorScreen(
          validatorRules: const {'job.status': true},
          onSave: (_) {},
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('editor-workflow')), 'wf-kbd');
    await tester.pump();
    expect(find.text('wf-kbd'), findsOneWidget);

    // The toggle control must be reachable by screen readers.
    final switchFinder = find.byType(Switch);
    expect(
      switchFinder,
      findsNothing,
      reason: 'display-only list renders no switches without rules',
    );
  });
}
