/// Sprint 104 / 104.6 — deterministic, bounded condition evaluation.
///
/// Security posture: there is NO expression language here and NO way to
/// inject code. Operators are a closed enum; evaluation is a pure function
/// over typed facts. Missing facts fail closed (even negations).
library;

enum ConditionOperator {
  equals,
  notEquals,
  greaterThan,
  lessThan,
  contains,
  inSet,
}

class AutomationCondition {
  const AutomationCondition({
    required this.field,
    required this.op,
    required this.value,
  });

  final String field;
  final ConditionOperator op;
  final Object value;
}

/// Immutable fact bag handed to the engine by the trigger source.
class AutomationContext {
  const AutomationContext({required this.facts});

  final Map<String, Object> facts;
}

class AutomationConditionEngine {
  const AutomationConditionEngine();

  /// AND over all conditions. Any miss fails the whole match.
  bool allMatch(
    List<AutomationCondition> conditions,
    AutomationContext context,
  ) => conditions.every((c) => _matches(c, context));

  bool _matches(AutomationCondition c, AutomationContext ctx) {
    // Fail closed: a missing fact can never satisfy anything, including
    // negations — absence of knowledge is not evidence.
    if (!ctx.facts.containsKey(c.field)) return false;
    final fact = ctx.facts[c.field];
    return switch (c.op) {
      ConditionOperator.equals => fact == c.value,
      ConditionOperator.notEquals => fact != c.value,
      ConditionOperator.greaterThan =>
        fact is num && c.value is num && fact > (c.value as num),
      ConditionOperator.lessThan =>
        fact is num && c.value is num && fact < (c.value as num),
      ConditionOperator.contains => _contains(fact, c.value),
      ConditionOperator.inSet =>
        c.value is List && (c.value as List).contains(fact),
    };
  }

  bool _contains(Object? fact, Object needle) {
    if (fact is Iterable<Object?>) return fact.contains(needle);
    if (fact is String && needle is String) return fact.contains(needle);
    return false;
  }
}
