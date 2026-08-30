library power_rulebook;

/// Deterministic, domain-only power-system rulebook.
///
/// The rulebook keeps narrative constraints explicit: an ability may require
/// prerequisites, consume resources, have usage limits, impose side effects,
/// and expose counters. It contains no persistence, clock, randomness, or UI.

class PowerPrerequisite {
  final String id;
  final String description;
  const PowerPrerequisite._({required this.id, required this.description});

  factory PowerPrerequisite.validated({
    required String id,
    required String description,
  }) {
    _nonEmpty(id, 'id');
    _nonEmpty(description, 'description');
    return PowerPrerequisite._(id: id, description: description);
  }
}

class PowerCost {
  final String resource;
  final num amount;
  final String reason;
  const PowerCost._({
    required this.resource,
    required this.amount,
    required this.reason,
  });

  factory PowerCost.validated({
    required String resource,
    required num amount,
    required String reason,
  }) {
    _nonEmpty(resource, 'resource');
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'must be > 0');
    }
    _nonEmpty(reason, 'reason');
    return PowerCost._(resource: resource, amount: amount, reason: reason);
  }
}

class PowerLimit {
  final String metric;
  final num maximum;
  final String reason;
  const PowerLimit._({
    required this.metric,
    required this.maximum,
    required this.reason,
  });

  factory PowerLimit.validated({
    required String metric,
    required num maximum,
    required String reason,
  }) {
    _nonEmpty(metric, 'metric');
    if (maximum <= 0) {
      throw ArgumentError.value(maximum, 'maximum', 'must be > 0');
    }
    _nonEmpty(reason, 'reason');
    return PowerLimit._(metric: metric, maximum: maximum, reason: reason);
  }
}

class PowerSideEffect {
  final String description;
  final int severity;
  const PowerSideEffect._({required this.description, required this.severity});

  factory PowerSideEffect.validated({
    required String description,
    required int severity,
  }) {
    _nonEmpty(description, 'description');
    if (severity < 0 || severity > 10) {
      throw ArgumentError.value(severity, 'severity', 'must be in [0,10]');
    }
    return PowerSideEffect._(description: description, severity: severity);
  }
}

class PowerCounter {
  final String description;
  final double effectiveness;
  const PowerCounter._({
    required this.description,
    required this.effectiveness,
  });

  factory PowerCounter.validated({
    required String description,
    required double effectiveness,
  }) {
    _nonEmpty(description, 'description');
    if (effectiveness < 0 || effectiveness > 1) {
      throw ArgumentError.value(
        effectiveness,
        'effectiveness',
        'must be in [0,1]',
      );
    }
    return PowerCounter._(
      description: description,
      effectiveness: effectiveness,
    );
  }
}

class PowerAbility {
  final String id;
  final String name;
  final List<PowerPrerequisite> prerequisites;
  final List<PowerCost> costs;
  final List<PowerLimit> limits;
  final List<PowerSideEffect> sideEffects;
  final List<PowerCounter> counters;
  const PowerAbility._({
    required this.id,
    required this.name,
    required this.prerequisites,
    required this.costs,
    required this.limits,
    required this.sideEffects,
    required this.counters,
  });

  factory PowerAbility.validated({
    required String id,
    required String name,
    List<PowerPrerequisite> prerequisites = const [],
    List<PowerCost> costs = const [],
    List<PowerLimit> limits = const [],
    List<PowerSideEffect> sideEffects = const [],
    List<PowerCounter> counters = const [],
  }) {
    _nonEmpty(id, 'id');
    _nonEmpty(name, 'name');
    return PowerAbility._(
      id: id,
      name: name,
      prerequisites: List.unmodifiable(prerequisites),
      costs: List.unmodifiable(costs),
      limits: List.unmodifiable(limits),
      sideEffects: List.unmodifiable(sideEffects),
      counters: List.unmodifiable(counters),
    );
  }
}

class PowerRulebook {
  final List<PowerAbility> abilities;
  const PowerRulebook._({required this.abilities});

  factory PowerRulebook.validated({required List<PowerAbility> abilities}) {
    final ids = <String>{};
    for (final ability in abilities) {
      if (!ids.add(ability.id)) {
        throw ArgumentError.value(
          ability.id,
          'abilities',
          'duplicate ability id',
        );
      }
    }
    return PowerRulebook._(abilities: List.unmodifiable(abilities));
  }

  PowerAbility? abilityById(String id) {
    for (final ability in abilities) {
      if (ability.id == id) return ability;
    }
    return null;
  }
}

void _nonEmpty(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'must be non-empty');
  }
}
