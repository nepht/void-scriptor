import '../domain/canon_conflict.dart';
import '../domain/canon_rule.dart';
import 'canon_validator.dart';

class CanonScanReport {
  const CanonScanReport({
    required this.conflicts,
    required this.evaluatedRules,
    required this.skippedRules,
  });

  final List<CanonConflict> conflicts;
  final int evaluatedRules;
  final int skippedRules;
}

/// Canon scan orchestration (Step 21.30 / 21.31).
///
/// A full project scan is not a single validator call: it maps each enabled
/// rule onto every entity that falls within its scope and aggregates the
/// resulting conflicts. Exceptions (Step 21.35) suppress conflicts for the
/// named targets.
class CanonScanService {
  CanonScanService({CanonValidator? validator})
    : _validator = validator ?? CanonValidator();

  final CanonValidator _validator;

  CanonScanReport scan({
    required Iterable<CanonRule> rules,
    required Iterable<CanonRuleCondition> conditions,
    required Map<String, Map<String, Object?>> entities,
    Set<String> exceptions = const {},
  }) {
    final conflicts = <CanonConflict>[];
    final byRule = <String, List<CanonRuleCondition>>{};
    for (final condition in conditions) {
      byRule.putIfAbsent(condition.ruleId, () => []).add(condition);
    }

    var evaluated = 0;
    var skipped = 0;
    for (final rule in rules) {
      if (!rule.enabled) {
        skipped++;
        continue;
      }
      evaluated++;
      final ruleConditions = byRule[rule.id] ?? const [];
      if (ruleConditions.isEmpty) continue;

      for (final entry in entities.entries) {
        final targetId = entry.key;
        final values = entry.value;
        // Uniqueness conditions need the count of matching values in scope.
        final scoped = _scopedValues(rule, ruleConditions, entities);
        final augmented = Map<String, Object?>.from(values)
          ..putIfAbsent(
            'count',
            () =>
                scoped[values[ruleConditions
                    .firstWhere(
                      (c) => c.validatorType == CanonValidatorType.uniqueness,
                      orElse: () => ruleConditions.first,
                    )
                    .targetField]] ??
                1,
          );
        for (final condition in ruleConditions) {
          conflicts.addAll(
            _validator.validate(
              rule: rule,
              condition: condition,
              targetId: targetId,
              values: augmented,
              exceptionTargetIds: exceptions,
            ),
          );
        }
      }
    }
    return CanonScanReport(
      conflicts: conflicts,
      evaluatedRules: evaluated,
      skippedRules: skipped,
    );
  }

  Map<Object?, int> _scopedValues(
    CanonRule rule,
    List<CanonRuleCondition> conditions,
    Map<String, Map<String, Object?>> entities,
  ) {
    final counts = <Object?, int>{};
    for (final condition in conditions) {
      if (condition.validatorType != CanonValidatorType.uniqueness) continue;
      final field = condition.targetField;
      for (final values in entities.values) {
        counts[values[field]] = (counts[values[field]] ?? 0) + 1;
      }
    }
    return counts;
  }
}
