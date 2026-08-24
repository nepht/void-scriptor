import 'automation_condition.dart';
import 'automation_rule.dart';
import 'workflow_trigger.dart';

/// Sprint 104 / 104.7 — reject invalid or dangerous rule expressions
/// BEFORE activation. Validation covers: known fields per trigger type,
/// known operators (closed enum by construction), type compatibility,
/// a hard complexity cap, and a structural ban on secret-referencing
/// fields inside rules.

enum RuleIssueKind {
  unknownField,
  typeMismatch,
  complexityLimit,
  secretExposure,
}

class RuleIssue {
  const RuleIssue(this.kind, this.detail);

  final RuleIssueKind kind;
  final String detail;

  @override
  String toString() => 'RuleIssue($kind, $detail)';
}

class AutomationRuleValidator {
  const AutomationRuleValidator({
    required this.allowedFieldsByType,
    this.maxConditionsPerRule = 8,
  });

  /// Per trigger type: the exact fact fields a rule may reference.
  final Map<WorkflowTriggerType, Set<String>> allowedFieldsByType;
  final int maxConditionsPerRule;

  List<RuleIssue> validate(AutomationRule rule) {
    final issues = <RuleIssue>[];

    if (rule.conditions.length > maxConditionsPerRule) {
      issues.add(
        RuleIssue(
          RuleIssueKind.complexityLimit,
          '${rule.conditions.length} conditions exceeds cap '
          '$maxConditionsPerRule',
        ),
      );
    }

    final allowed = allowedFieldsByType[rule.trigger.type] ?? const <String>{};

    for (final c in rule.conditions) {
      if (_isSecretField(c.field)) {
        issues.add(
          RuleIssue(
            RuleIssueKind.secretExposure,
            'field "${c.field}" must never appear in a rule',
          ),
        );
        continue;
      }
      if (!allowed.contains(c.field)) {
        issues.add(
          RuleIssue(
            RuleIssueKind.unknownField,
            'field "${c.field}" is not part of ${rule.trigger.type.name} '
            'trigger schema',
          ),
        );
        continue;
      }
      switch (c.op) {
        case ConditionOperator.greaterThan:
        case ConditionOperator.lessThan:
          if (c.value is! num) {
            issues.add(
              RuleIssue(
                RuleIssueKind.typeMismatch,
                '"${c.op.name}" needs a numeric literal, got '
                '${c.value.runtimeType}',
              ),
            );
          }
        case ConditionOperator.inSet:
          if (c.value is! List) {
            issues.add(
              RuleIssue(
                RuleIssueKind.typeMismatch,
                '"inSet" needs a list literal, got ${c.value.runtimeType}',
              ),
            );
          }
        case ConditionOperator.equals:
        case ConditionOperator.notEquals:
        case ConditionOperator.contains:
          break;
      }
    }
    return issues;
  }

  bool _isSecretField(String field) {
    final lower = field.toLowerCase();
    return lower.startsWith('secret.') || lower.contains('.secret.');
  }
}
