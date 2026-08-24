import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/automation/automation_condition.dart';
import 'package:void_scriptor/automation/automation_rule.dart';
import 'package:void_scriptor/automation/rule_validation.dart';
import 'package:void_scriptor/automation/workflow_trigger.dart';

/// Sprint 104 / 104.7 — reject invalid or dangerous rule expressions
/// BEFORE activation: known fields, type compatibility, complexity cap,
/// and no secret exposure.
AutomationRule ruleOf(
  List<AutomationCondition> conditions, {
  WorkflowTriggerType type = WorkflowTriggerType.jobEvent,
}) => AutomationRule(
  ruleId: 'r-v',
  trigger: WorkflowTrigger(
    triggerId: 't-v',
    type: type,
    configuration: const {},
    createdAt: DateTime.utc(2026, 8, 25),
    updatedAt: DateTime.utc(2026, 8, 25),
  ),
  conditions: conditions,
  workflowId: 'wf-1',
  approvalPolicy: AutomationApprovalPolicy.notRequired,
  failurePolicy: AutomationFailurePolicy.stopRun,
);

AutomationCondition c(String f, ConditionOperator op, Object v) =>
    AutomationCondition(field: f, op: op, value: v);

AutomationRuleValidator service() => const AutomationRuleValidator(
  allowedFieldsByType: {
    WorkflowTriggerType.jobEvent: {'job.status', 'attempt'},
    WorkflowTriggerType.schedule: {'schedule.fired'},
  },
  maxConditionsPerRule: 3,
);

void main() {
  test('a clean rule validates with zero issues', () {
    final issues = service().validate(
      ruleOf([
        c('job.status', ConditionOperator.equals, 'completed'),
        c('attempt', ConditionOperator.lessThan, 5),
      ]),
    );
    expect(issues, isEmpty);
  });

  test('fields outside the trigger schema are rejected', () {
    final issues = service().validate(
      ruleOf([c('net.host', ConditionOperator.equals, 'example.com')]),
    );
    expect(issues.single.kind, RuleIssueKind.unknownField);
  });

  test('comparison against a non-numeric value is a type mismatch', () {
    final issues = service().validate(
      ruleOf([c('attempt', ConditionOperator.greaterThan, 'many')]),
    );
    expect(issues.single.kind, RuleIssueKind.typeMismatch);
  });

  test('complexity beyond the configured cap is rejected wholesale', () {
    final issues = service().validate(
      ruleOf([
        c('attempt', ConditionOperator.greaterThan, 1),
        c('attempt', ConditionOperator.greaterThan, 2),
        c('attempt', ConditionOperator.greaterThan, 3),
        c('attempt', ConditionOperator.greaterThan, 4),
      ]),
    );
    expect(issues.map((i) => i.kind), contains(RuleIssueKind.complexityLimit));
  });

  test('secret-referencing fields can never appear in a rule', () {
    final issues = service().validate(
      ruleOf([c('secret.api_key', ConditionOperator.equals, 'x')]),
    );
    expect(issues.map((i) => i.kind), contains(RuleIssueKind.secretExposure));
  });
}
