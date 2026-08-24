import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/automation/automation_condition.dart';
import 'package:void_scriptor/automation/automation_rule.dart';
import 'package:void_scriptor/automation/workflow_trigger.dart';

/// Sprint 104 / 104.5 — automation rule ties trigger + conditions +
/// workflow + policies together.
WorkflowTrigger trigger() => WorkflowTrigger(
  triggerId: 't-1',
  type: WorkflowTriggerType.jobEvent,
  configuration: const {'jobType': 'export'},
  createdAt: DateTime.utc(2026, 8, 25),
  updatedAt: DateTime.utc(2026, 8, 25),
);

void main() {
  test('rule wires every canonical field', () {
    final rule = AutomationRule(
      ruleId: 'r-1',
      trigger: trigger(),
      conditions: [
        const AutomationCondition(
          field: 'job.status',
          op: ConditionOperator.equals,
          value: 'completed',
        ),
      ],
      workflowId: 'wf-export',
      approvalPolicy: AutomationApprovalPolicy.required,
      failurePolicy: AutomationFailurePolicy.skipRun,
    );
    expect(rule.enabled, isTrue);
    expect(rule.workflowId, 'wf-export');
    expect(rule.conditions.single.op, ConditionOperator.equals);
    expect(rule.approvalPolicy, AutomationApprovalPolicy.required);
  });

  test('disabled rules are representable without deleting them', () {
    final rule = AutomationRule(
      ruleId: 'r-2',
      trigger: trigger(),
      conditions: const [],
      workflowId: 'wf-x',
      approvalPolicy: AutomationApprovalPolicy.notRequired,
      failurePolicy: AutomationFailurePolicy.stopRun,
      enabled: false,
    );
    expect(rule.enabled, isFalse);
  });
}
