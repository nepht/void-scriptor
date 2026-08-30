/// Domain models for Sprint 110 step 110.39: Technology Node & Prerequisite Model.
///
/// Stores the knowledge, materials, tools, infrastructure, and discovery events
/// a technology requires. Domain-only, deterministic, no persistence, UI,
/// wall clock, locale, randomness, or network.
library;

enum TechnologyScope { military, civil, magic, scientific, industrial }

class TechnologySource {
  final String revision;
  final String reason;
  const TechnologySource._({required this.revision, required this.reason});
  factory TechnologySource.validated({
    required String revision,
    required String reason,
  }) {
    if (revision.isEmpty) {
      throw ArgumentError.value(revision, 'revision', 'must not be empty');
    }
    if (reason.isEmpty) {
      throw ArgumentError.value(reason, 'reason', 'must not be empty');
    }
    return TechnologySource._(revision: revision, reason: reason);
  }
}

class TechnologyResource {
  final String id;
  final String kind;
  final num amount;
  final String reason;
  const TechnologyResource._({
    required this.id,
    required this.kind,
    required this.amount,
    required this.reason,
  });
  factory TechnologyResource.validated({
    required String id,
    required String kind,
    required num amount,
    required String reason,
  }) {
    if (id.isEmpty) throw ArgumentError.value(id, 'id', 'must not be empty');
    if (kind.isEmpty) {
      throw ArgumentError.value(kind, 'kind', 'must not be empty');
    }
    if (amount <= 0) throw ArgumentError.value(amount, 'amount', 'must be > 0');
    if (reason.isEmpty) {
      throw ArgumentError.value(reason, 'reason', 'must not be empty');
    }
    return TechnologyResource._(
      id: id,
      kind: kind,
      amount: amount,
      reason: reason,
    );
  }
}

class TechnologyInfrastructure {
  final String id;
  final String kind;
  final int capacity;
  final String reason;
  const TechnologyInfrastructure._({
    required this.id,
    required this.kind,
    required this.capacity,
    required this.reason,
  });
  factory TechnologyInfrastructure.validated({
    required String id,
    required String kind,
    required int capacity,
    required String reason,
  }) {
    if (id.isEmpty) throw ArgumentError.value(id, 'id', 'must not be empty');
    if (kind.isEmpty) {
      throw ArgumentError.value(kind, 'kind', 'must not be empty');
    }
    if (capacity <= 0) {
      throw ArgumentError.value(capacity, 'capacity', 'must be > 0');
    }
    if (reason.isEmpty) {
      throw ArgumentError.value(reason, 'reason', 'must not be empty');
    }
    return TechnologyInfrastructure._(
      id: id,
      kind: kind,
      capacity: capacity,
      reason: reason,
    );
  }
}

class TechnologyNode {
  final String id;
  final String name;
  final String? culture;
  final TechnologyScope scope;
  final String branch;
  final int tier;
  final List<String> prerequisites;
  final List<TechnologyResource> resources;
  final List<TechnologyInfrastructure> infrastructure;
  final String summary;
  final TechnologySource source;
  const TechnologyNode._({
    required this.id,
    required this.name,
    required this.culture,
    required this.scope,
    required this.branch,
    required this.tier,
    required this.prerequisites,
    required this.resources,
    required this.infrastructure,
    required this.summary,
    required this.source,
  });
  factory TechnologyNode.validated({
    required String id,
    required String name,
    String? culture,
    TechnologyScope scope = TechnologyScope.civil,
    String branch = 'prime',
    int tier = 1,
    List<String>? prerequisites,
    List<TechnologyResource>? resources,
    List<TechnologyInfrastructure>? infrastructure,
    String summary = '',
    required TechnologySource source,
  }) {
    if (id.isEmpty) throw ArgumentError.value(id, 'id', 'must not be empty');
    if (name.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    if (branch.isEmpty) {
      throw ArgumentError.value(branch, 'branch', 'must not be empty');
    }
    if (tier < 1) throw ArgumentError.value(tier, 'tier', 'must be >= 1');
    final prereq = List<String>.unmodifiable(prerequisites ?? const <String>[]);
    final res = List<TechnologyResource>.unmodifiable(
      resources ?? const <TechnologyResource>[],
    );
    final inf = List<TechnologyInfrastructure>.unmodifiable(
      infrastructure ?? const <TechnologyInfrastructure>[],
    );
    return TechnologyNode._(
      id: id,
      name: name,
      culture: culture,
      scope: scope,
      branch: branch,
      tier: tier,
      prerequisites: prereq,
      resources: res,
      infrastructure: inf,
      summary: summary,
      source: source,
    );
  }
}

class TechnologyDiscoveryEvent {
  final String id;
  final String technologyId;
  final int tick;
  final String summary;
  final String? discoveredBy;
  final TechnologySource source;
  const TechnologyDiscoveryEvent._({
    required this.id,
    required this.technologyId,
    required this.tick,
    required this.summary,
    required this.discoveredBy,
    required this.source,
  });
  factory TechnologyDiscoveryEvent.validated({
    required String id,
    required String technologyId,
    required int tick,
    required String summary,
    String? discoveredBy,
    required TechnologySource source,
  }) {
    if (id.isEmpty) throw ArgumentError.value(id, 'id', 'must not be empty');
    if (technologyId.isEmpty) {
      throw ArgumentError.value(
        technologyId,
        'technologyId',
        'must not be empty',
      );
    }
    if (tick < 0) throw ArgumentError.value(tick, 'tick', 'must be >= 0');
    if (summary.isEmpty) {
      throw ArgumentError.value(summary, 'summary', 'must not be empty');
    }
    return TechnologyDiscoveryEvent._(
      id: id,
      technologyId: technologyId,
      tick: tick,
      summary: summary,
      discoveredBy: discoveredBy,
      source: source,
    );
  }
}

class TechnologyRegistry {
  final List<TechnologyNode> nodes;
  final Map<String, TechnologyNode> _byId;
  const TechnologyRegistry._(this.nodes, this._byId);
  factory TechnologyRegistry.validated({required List<TechnologyNode> nodes}) {
    final byId = <String, TechnologyNode>{};
    for (final n in nodes) {
      if (byId.containsKey(n.id)) {
        throw ArgumentError.value(
          n.id,
          'nodes',
          'duplicate technology node id',
        );
      }
      final seen = <String>{};
      for (final pid in n.prerequisites) {
        if (!seen.add(pid)) {
          throw ArgumentError.value(
            n.id,
            'prerequisites',
            'duplicate prerequisite id',
          );
        }
      }
      byId[n.id] = n;
    }
    return TechnologyRegistry._(
      List<TechnologyNode>.unmodifiable(nodes),
      Map<String, TechnologyNode>.unmodifiable(byId),
    );
  }
  TechnologyNode? nodeById(String id) => _byId[id];
}

class TechnologyDiscoveryTimeline {
  final List<TechnologyDiscoveryEvent> events;
  const TechnologyDiscoveryTimeline._(this.events);
  factory TechnologyDiscoveryTimeline.validated({
    required List<TechnologyDiscoveryEvent> events,
  }) {
    final sorted = [...events]..sort((a, b) => a.tick.compareTo(b.tick));
    return TechnologyDiscoveryTimeline._(
      List<TechnologyDiscoveryEvent>.unmodifiable(sorted),
    );
  }
  List<TechnologyDiscoveryEvent> eventsBetween({
    required int startTick,
    required int endTick,
  }) {
    if (startTick > endTick) {
      throw ArgumentError.value(startTick, 'startTick', 'must be <= endTick');
    }
    return events
        .where((e) => e.tick >= startTick && e.tick <= endTick)
        .toList(growable: false);
  }
}
