import '../../story/domain/canon_status.dart';

enum CanonRuleSeverity { info, warning, hard }

enum CanonRuleScope {
  global,
  character,
  faction,
  location,
  story,
  era,
  powerSystem,
}

enum CanonValidatorType {
  requiredRelation,
  forbiddenRelation,
  requiredTag,
  forbiddenTag,
  requiredValue,
  forbiddenValue,
  uniqueness,
  chronology,
}

class CanonRule {
  const CanonRule({
    required this.id,
    required this.projectId,
    required this.title,
    required this.ruleText,
    this.severity = CanonRuleSeverity.hard,
    this.scope = CanonRuleScope.global,
    this.scopeTargetId,
    this.enabled = true,
    this.status = CanonStatus.canon,
  });

  final String id;
  final String projectId;
  final String title;
  final String ruleText;
  final CanonRuleSeverity severity;
  final CanonRuleScope scope;
  final String? scopeTargetId;
  final bool enabled;
  final CanonStatus status;
}

class CanonRuleCondition {
  const CanonRuleCondition({
    required this.id,
    required this.ruleId,
    required this.validatorType,
    this.targetField,
    this.operator,
    this.expectedValue,
  });

  final String id;
  final String ruleId;
  final CanonValidatorType validatorType;
  final String? targetField;
  final String? operator;
  final String? expectedValue;
}
