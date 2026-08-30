library power_usage_ledger;

class PowerUsageSource {
  const PowerUsageSource._({required this.revision, required this.reason});
  final String revision;
  final String reason;
  factory PowerUsageSource.validated({
    required String revision,
    required String reason,
  }) {
    _nonEmpty(revision, 'revision');
    _nonEmpty(reason, 'reason');
    return PowerUsageSource._(revision: revision, reason: reason);
  }
}

class PowerResourceChange {
  const PowerResourceChange._({
    required this.resource,
    required this.amount,
    required this.reason,
  });
  final String resource;
  final num amount;
  final String reason;
  factory PowerResourceChange.validated({
    required String resource,
    required num amount,
    required String reason,
  }) {
    _nonEmpty(resource, 'resource');
    if (amount == 0) {
      throw ArgumentError.value(amount, 'amount', 'must not be zero');
    }
    _nonEmpty(reason, 'reason');
    return PowerResourceChange._(
      resource: resource,
      amount: amount,
      reason: reason,
    );
  }
}

class PowerConsequence {
  const PowerConsequence._({required this.description, required this.severity});
  final String description;
  final int severity;
  factory PowerConsequence.validated({
    required String description,
    required int severity,
  }) {
    _nonEmpty(description, 'description');
    if (severity < 0 || severity > 10) {
      throw ArgumentError.value(severity, 'severity', 'must be in [0,10]');
    }
    return PowerConsequence._(description: description, severity: severity);
  }
}

class PowerUsageEvent {
  const PowerUsageEvent._({
    required this.id,
    required this.abilityId,
    required this.actorId,
    required this.sceneId,
    required this.tick,
    required this.resourceChanges,
    required this.consequences,
    required this.source,
  });
  final String id;
  final String abilityId;
  final String actorId;
  final String sceneId;
  final int tick;
  final List<PowerResourceChange> resourceChanges;
  final List<PowerConsequence> consequences;
  final PowerUsageSource source;
  factory PowerUsageEvent.validated({
    required String id,
    required String abilityId,
    required String actorId,
    required String sceneId,
    required int tick,
    List<PowerResourceChange> resourceChanges = const [],
    List<PowerConsequence> consequences = const [],
    required PowerUsageSource source,
  }) {
    _nonEmpty(id, 'id');
    _nonEmpty(abilityId, 'abilityId');
    _nonEmpty(actorId, 'actorId');
    _nonEmpty(sceneId, 'sceneId');
    if (tick < 0) throw ArgumentError.value(tick, 'tick', 'must be >= 0');
    return PowerUsageEvent._(
      id: id,
      abilityId: abilityId,
      actorId: actorId,
      sceneId: sceneId,
      tick: tick,
      resourceChanges: List.unmodifiable(resourceChanges),
      consequences: List.unmodifiable(consequences),
      source: source,
    );
  }
}

class PowerUsageLedger {
  const PowerUsageLedger._(this.events);
  final List<PowerUsageEvent> events;
  factory PowerUsageLedger.validated({required List<PowerUsageEvent> events}) {
    final ids = <String>{};
    for (final event in events) {
      if (!ids.add(event.id)) {
        throw ArgumentError.value(event.id, 'events', 'duplicate event id');
      }
    }
    final ordered = [...events]..sort((a, b) => a.tick.compareTo(b.tick));
    return PowerUsageLedger._(List.unmodifiable(ordered));
  }
  List<PowerUsageEvent> forScene(String sceneId) =>
      List.unmodifiable(events.where((event) => event.sceneId == sceneId));
}

void _nonEmpty(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'must be non-empty');
  }
}
