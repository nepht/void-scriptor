library;

import 'power_rulebook.dart';
import 'power_usage_ledger.dart';

/// Deterministic, domain-only power-rule violation detector.
///
/// Inspects a [PowerUsageEvent] against a [PowerRulebook] and reports
/// violations for missing prerequisites, insufficient resource changes, unknown
/// abilities, and cooldown breaches. The detector contains no persistence,
/// clock, randomness, or UI.

enum PowerViolationKind {
  unknownAbility,
  missingPrerequisite,
  insufficientCost,
  cooldownNotElapsed,
}

class PowerViolation {
  const PowerViolation({
    required this.kind,
    required this.abilityId,
    required this.explanation,
    this.prerequisiteId,
    this.resource,
    this.expectedAmount,
    this.actualAmount,
    this.elapsedTicks,
    this.requiredTicks,
  });

  final PowerViolationKind kind;
  final String abilityId;
  final String explanation;
  final String? prerequisiteId;
  final String? resource;
  final num? expectedAmount;
  final num? actualAmount;
  final int? elapsedTicks;
  final int? requiredTicks;
}

class PowerViolationReport {
  const PowerViolationReport._(this.violations);
  final List<PowerViolation> violations;

  factory PowerViolationReport.from(List<PowerViolation> violations) {
    final sorted = [...violations]
      ..sort((a, b) {
        final byAbility = a.abilityId.compareTo(b.abilityId);
        if (byAbility != 0) return byAbility;
        return a.kind.index.compareTo(b.kind.index);
      });
    return PowerViolationReport._(List.unmodifiable(sorted));
  }

  bool get isClean => violations.isEmpty;

  String explain() {
    if (violations.isEmpty) return 'No power-rule violations detected.';
    final buffer = StringBuffer('Power-rule violations:');
    for (final v in violations) {
      buffer.write(' ability=');
      buffer.write(v.abilityId);
      buffer.write(' kind=');
      buffer.write(v.kind.name);
      buffer.write(' reason="');
      buffer.write(v.explanation);
      buffer.write('"');
    }
    return buffer.toString();
  }
}

class PowerRuleViolationDetector {
  const PowerRuleViolationDetector({required this.rulebook});
  final PowerRulebook rulebook;

  PowerViolationReport detect(
    PowerUsageEvent event, {
    required List<String> satisfiedPrerequisites,
  }) {
    final violations = <PowerViolation>[];
    final ability = rulebook.abilityById(event.abilityId);
    if (ability == null) {
      violations.add(
        PowerViolation(
          kind: PowerViolationKind.unknownAbility,
          abilityId: event.abilityId,
          explanation: 'ability "${event.abilityId}" is not in rulebook',
        ),
      );
      return PowerViolationReport.from(violations);
    }
    final satisfied = satisfiedPrerequisites.toSet();
    for (final prereq in ability.prerequisites) {
      if (!satisfied.contains(prereq.id)) {
        violations.add(
          PowerViolation(
            kind: PowerViolationKind.missingPrerequisite,
            abilityId: ability.id,
            prerequisiteId: prereq.id,
            explanation:
                'prerequisite "${prereq.id}" not satisfied for "${ability.id}"',
          ),
        );
      }
    }
    for (final cost in ability.costs) {
      final actual = event.resourceChanges
          .where((c) => c.resource == cost.resource)
          .fold<num>(0, (sum, c) => sum + c.amount);
      if (actual > -cost.amount) {
        violations.add(
          PowerViolation(
            kind: PowerViolationKind.insufficientCost,
            abilityId: ability.id,
            resource: cost.resource,
            expectedAmount: cost.amount,
            actualAmount: actual,
            explanation:
                'cost ${cost.resource}=${cost.amount} not met (actual=$actual) for "${ability.id}"',
          ),
        );
      }
    }
    return PowerViolationReport.from(violations);
  }

  PowerViolationReport detectCooldown({
    required PowerUsageEvent candidate,
    required PowerUsageEvent previous,
    required int cooldownTicks,
  }) {
    if (cooldownTicks <= 0) {
      return const PowerViolationReport._(<PowerViolation>[]);
    }
    if (candidate.tick <= previous.tick) {
      throw ArgumentError.value(
        candidate.tick,
        'candidate.tick',
        'must be strictly after previous.tick',
      );
    }
    final elapsed = candidate.tick - previous.tick;
    if (elapsed >= cooldownTicks) {
      return const PowerViolationReport._(<PowerViolation>[]);
    }
    final violations = <PowerViolation>[
      PowerViolation(
        kind: PowerViolationKind.cooldownNotElapsed,
        abilityId: candidate.abilityId,
        elapsedTicks: elapsed,
        requiredTicks: cooldownTicks,
        explanation:
            'cooldown for "${candidate.abilityId}" needs $cooldownTicks ticks but only $elapsed elapsed',
      ),
    ];
    return PowerViolationReport.from(violations);
  }
}
