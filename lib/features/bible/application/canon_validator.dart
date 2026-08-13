import '../domain/canon_conflict.dart';
import '../domain/canon_rule.dart';

class CanonValidator {
  List<CanonConflict> validate({
    required CanonRule rule,
    required CanonRuleCondition condition,
    required String targetId,
    required Map<String, Object?> values,
    Set<String> exceptionTargetIds = const {},
  }) {
    if (!rule.enabled) return const [];
    if (exceptionTargetIds.contains(targetId)) return const [];

    final expected = condition.expectedValue;
    final actual = condition.targetField == null
        ? null
        : values[condition.targetField!];
    final violates = switch (condition.validatorType) {
      CanonValidatorType.forbiddenValue => _forbiddenValueViolation(
        actual,
        condition.operator,
        expected,
      ),
      CanonValidatorType.uniqueness =>
        (values['count'] as num?)?.toInt() != null &&
            (values['count'] as num).toInt() > 1,
      _ => false,
    };
    if (!violates) return const [];

    final severity = condition.validatorType == CanonValidatorType.uniqueness
        ? CanonConflictSeverity.critical
        : _severity(rule.severity);
    return [
      CanonConflict(
        id: '${rule.id}:$targetId:${condition.id}',
        projectId: rule.projectId,
        ruleId: rule.id,
        targetId: targetId,
        message: _message(rule, expected, actual),
        severity: severity,
      ),
    ];
  }

  bool _forbiddenValueViolation(
    Object? actual,
    String? operator,
    String? expected,
  ) {
    if (actual == null || expected == null) return false;
    final text = actual.toString();
    return switch (operator) {
      'equals' => text == expected,
      'contains' || null => text.toLowerCase().contains(expected.toLowerCase()),
      _ => false,
    };
  }

  CanonConflictSeverity _severity(CanonRuleSeverity severity) =>
      switch (severity) {
        CanonRuleSeverity.info => CanonConflictSeverity.info,
        CanonRuleSeverity.warning => CanonConflictSeverity.warning,
        CanonRuleSeverity.hard => CanonConflictSeverity.error,
      };

  String _message(CanonRule rule, String? expected, Object? actual) =>
      '${rule.title}: value "$expected" conflicts with the canon rule. '
      'Actual: ${actual ?? 'missing'}.';
}
