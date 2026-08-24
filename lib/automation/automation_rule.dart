import 'automation_condition.dart';
import 'workflow_trigger.dart';

/// Sprint 104 / 104.5 — one automation rule binds a trigger, its entry
/// conditions, the target workflow, and the safety policies.

/// Human-in-the-loop requirement attached to every firing of the rule.
enum AutomationApprovalPolicy { notRequired, required }

/// What happens to THIS run when the workflow fails.
enum AutomationFailurePolicy { stopRun, skipRun }

class AutomationRule {
  const AutomationRule({
    required this.ruleId,
    required this.trigger,
    required this.conditions,
    required this.workflowId,
    this.approvalPolicy = AutomationApprovalPolicy.notRequired,
    this.failurePolicy = AutomationFailurePolicy.stopRun,
    this.enabled = true,
  });

  final String ruleId;
  final WorkflowTrigger trigger;
  final List<AutomationCondition> conditions;
  final String workflowId;
  final AutomationApprovalPolicy approvalPolicy;
  final AutomationFailurePolicy failurePolicy;
  final bool enabled;
}
