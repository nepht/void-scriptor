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
    final isUniqueness =
        condition.validatorType == CanonValidatorType.uniqueness;
    final message = isUniqueness
        // vs-hunt-20260913-bible BUG-2: uniqueness has no expected value;
        // the shared template used to render `value "null" conflicts...`.
        ? _uniquenessMessage(rule, condition, values)
        : _message(rule, expected, actual);
    return [
      CanonConflict(
        id: '${rule.id}:$targetId:${condition.id}',
        projectId: rule.projectId,
        ruleId: rule.id,
        targetId: targetId,
        message: message,
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

  /// Human-readable conflict message for a uniqueness violation.
  ///
  /// Uniqueness conditions never carry an [CanonRuleCondition.expectedValue],
  /// so the shared [_message] template would render `value "null"`. This names
  /// the duplicated field value (or the field, or the rule) plus the observed
  /// count instead.
  String _uniquenessMessage(
    CanonRule rule,
    CanonRuleCondition condition,
    Map<String, Object?> values,
  ) {
    final count = (values['count'] as num?)?.toInt();
    final field = condition.targetField;
    final fieldValue = field == null ? null : values[field];
    final subject = fieldValue != null
        ? '"$fieldValue"'
        : (field != null ? 'value of "$field"' : 'this target');
    return '${rule.title}: $subject appears ${count ?? 1} times, but the '
        'canon rule requires it to be unique.';
  }
}
