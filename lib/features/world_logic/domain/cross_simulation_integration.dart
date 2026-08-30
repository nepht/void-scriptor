// Sprint 110.42 - Cross-Simulation Integration.
//
// Menghubungkan waktu, peta, perjalanan, tokoh, faksi, ekonomi, rumor,
// kekuatan, dan teknologi melalui contract stabil. Domain-only,
// deterministic, no persistence/UI/wall clock/locale/random/network.
library;

import 'route_network.dart';
import 'temporal_map_state.dart';
import 'world_time_state_authority.dart';
import 'rumor_propagation.dart';
import 'power_usage_ledger.dart';
import 'technology_node_prerequisite_model.dart';

class EventLinkReason {
  const EventLinkReason._(this.label);
  final String label;
  static const EventLinkReason manual = EventLinkReason._('manual');
  static const EventLinkReason implied = EventLinkReason._('implied');
  static const EventLinkReason discovered = EventLinkReason._('discovered');
  @override
  String toString() => label;
}

class EventLink {
  const EventLink._({
    required this.eventId,
    required this.tick,
    required this.participants,
    required this.sourceRevision,
    required this.reason,
  });

  factory EventLink.validated({
    required String eventId,
    required int tick,
    required List<String> participants,
    required String sourceRevision,
    EventLinkReason reason = EventLinkReason.manual,
  }) {
    if (eventId.isEmpty) {
      throw ArgumentError.value(eventId, 'eventId', 'eventId cannot be empty');
    }
    if (tick < 0) {
      throw ArgumentError.value(tick, 'tick', 'tick cannot be negative');
    }
    if (sourceRevision.isEmpty) {
      throw ArgumentError.value(
        sourceRevision,
        'sourceRevision',
        'sourceRevision cannot be empty',
      );
    }
    return EventLink._(
      eventId: eventId,
      tick: tick,
      participants: List<String>.unmodifiable(participants),
      sourceRevision: sourceRevision,
      reason: reason,
    );
  }

  final String eventId;
  final int tick;
  final List<String> participants;
  final String sourceRevision;
  final EventLinkReason reason;
}

class EventProvenance {
  const EventProvenance._({
    required this.eventId,
    required this.tick,
    required this.participants,
    required this.sourceRevision,
    required this.reason,
  });

  factory EventProvenance.fromLink(EventLink link) {
    return EventProvenance._(
      eventId: link.eventId,
      tick: link.tick,
      participants: link.participants,
      sourceRevision: link.sourceRevision,
      reason: link.reason,
    );
  }

  final String eventId;
  final int tick;
  final List<String> participants;
  final String sourceRevision;
  final EventLinkReason reason;
}

class OwnershipEdge {
  const OwnershipEdge({required this.ownerId, required this.ownedId});
  final String ownerId;
  final String ownedId;
}

class CircularOwnershipException implements Exception {
  CircularOwnershipException(this.cyclePath);
  final List<String> cyclePath;

  @override
  String toString() =>
      'CircularOwnershipException: ownership cycle detected through '
      '${cyclePath.join(' -> ')}';
}

class SharedLocationResolution {
  const SharedLocationResolution._({
    required this.locationId,
    required this.matchedRouteNodeId,
    required this.isActive,
    required this.sourceRevision,
  });

  final String locationId;
  final String? matchedRouteNodeId;
  final bool isActive;
  final String sourceRevision;
}

class IntegrationHealthReport {
  const IntegrationHealthReport._({
    required this.clockReady,
    required this.mapReady,
    required this.routeReady,
    required this.factionsReady,
    required this.timelineReady,
    required this.economyReady,
    required this.rumorReady,
    required this.powerReady,
    required this.technologyReady,
    required this.partial,
    required this.missingSubsystems,
    required this.sourceRevision,
  });

  factory IntegrationHealthReport.from({
    required bool clock,
    required bool map,
    required bool route,
    required bool factions,
    required bool timeline,
    required bool economy,
    required bool rumor,
    required bool power,
    required bool technology,
    required String sourceRevision,
  }) {
    final missing = <String>[];
    if (!clock) missing.add('clock');
    if (!map) missing.add('map');
    if (!route) missing.add('routes');
    if (!factions) missing.add('factions');
    if (!timeline) missing.add('timeline');
    if (!economy) missing.add('economy');
    if (!rumor) missing.add('rumor');
    if (!power) missing.add('power');
    if (!technology) missing.add('technology');
    return IntegrationHealthReport._(
      clockReady: clock,
      mapReady: map,
      routeReady: route,
      factionsReady: factions,
      timelineReady: timeline,
      economyReady: economy,
      rumorReady: rumor,
      powerReady: power,
      technologyReady: technology,
      partial: missing.isNotEmpty,
      missingSubsystems: List<String>.unmodifiable(missing),
      sourceRevision: sourceRevision,
    );
  }

  final bool clockReady;
  final bool mapReady;
  final bool routeReady;
  final bool factionsReady;
  final bool timelineReady;
  final bool economyReady;
  final bool rumorReady;
  final bool powerReady;
  final bool technologyReady;
  final bool partial;
  final List<String> missingSubsystems;
  final String sourceRevision;
}

class PartialResult<T> {
  const PartialResult._({
    required this.value,
    required this.isPartial,
    required this.reason,
  });

  factory PartialResult.available(T value) =>
      PartialResult<T>._(value: value, isPartial: false, reason: '');
  factory PartialResult.missing(String reason) =>
      PartialResult<T>._(value: null, isPartial: true, reason: reason);

  final T? value;
  final bool isPartial;
  final String reason;
}

class NarrativeSliceReport {
  const NarrativeSliceReport._({
    required this.tick,
    required this.linkedEvents,
    required this.linkedRumors,
    required this.linkedPowers,
    required this.linkedTechnologies,
    required this.sourceRevision,
  });

  final int tick;
  final List<String> linkedEvents;
  final List<String> linkedRumors;
  final List<String> linkedPowers;
  final List<String> linkedTechnologies;
  final String sourceRevision;
}

class CrossSimulationIntegration {
  CrossSimulationIntegration._({
    required this._clock,
    required this._mapState,
    required this._graph,
    required this._sourceRevision,
  });

  factory CrossSimulationIntegration.withDefaults({
    WorldClock? clock,
    TemporalMapState? mapState,
    RouteGraph? graph,
  }) {
    final resolvedClock = clock ?? WorldClock();
    final revision = 'csi-rev:clock:${resolvedClock.now}';
    return CrossSimulationIntegration._(
      clock: resolvedClock,
      mapState: mapState,
      graph: graph,
      sourceRevision: revision,
    );
  }

  final WorldClock _clock;
  final TemporalMapState? _mapState;
  final RouteGraph? _graph;
  final String _sourceRevision;
  final List<EventLink> _events = <EventLink>[];
  final List<RumorSeed> _rumors = <RumorSeed>[];
  final List<PowerUsageEvent> _powerEvents = <PowerUsageEvent>[];
  final List<TechnologyNode> _technologies = <TechnologyNode>[];
  final List<OwnershipEdge> _ownership = <OwnershipEdge>[];

  int get currentTick => _clock.now;
  String get sourceRevision => _sourceRevision;
  WorldClock get clock => _clock;
  TemporalMapState? get mapState => _mapState;
  RouteGraph? get graph => _graph;
  List<EventLink> get events => List<EventLink>.unmodifiable(_events);
  List<RumorSeed> get rumors => List<RumorSeed>.unmodifiable(_rumors);
  List<PowerUsageEvent> get powerEvents =>
      List<PowerUsageEvent>.unmodifiable(_powerEvents);
  List<TechnologyNode> get technologies =>
      List<TechnologyNode>.unmodifiable(_technologies);
  List<OwnershipEdge> get ownershipEdges =>
      List<OwnershipEdge>.unmodifiable(_ownership);

  int advanceTime(int ticks) => _clock.advance(ticks);

  SharedLocationResolution resolveLocation(String locationId, int tick) {
    if (locationId.isEmpty) {
      throw ArgumentError.value(locationId, 'locationId', 'cannot be empty');
    }
    if (tick < 0) {
      throw ArgumentError.value(tick, 'tick', 'cannot be negative');
    }
    final map = _mapState;
    final graph = _graph;
    var active = false;
    if (map != null) {
      try {
        final snapshot = map.snapshotAt(branchId: map.branchId, tick: tick);
        for (final loc in snapshot.locations) {
          if (loc.id == locationId) {
            active = true;
            break;
          }
        }
      } on ArgumentError {
        active = false;
      }
    }
    String? matchedRouteNodeId;
    if (graph != null) {
      try {
        final node = graph.node(locationId);
        matchedRouteNodeId = node.id;
      } on ArgumentError {
        matchedRouteNodeId = null;
      }
    }
    return SharedLocationResolution._(
      locationId: locationId,
      matchedRouteNodeId: matchedRouteNodeId,
      isActive: active || matchedRouteNodeId != null,
      sourceRevision: _sourceRevision,
    );
  }

  EventLink linkEvent({
    required String eventId,
    required int tick,
    required List<String> participants,
    EventLinkReason reason = EventLinkReason.manual,
  }) {
    final link = EventLink.validated(
      eventId: eventId,
      tick: tick,
      participants: participants,
      sourceRevision: '$_sourceRevision|event:$eventId',
      reason: reason,
    );
    _events.add(link);
    return link;
  }

  void registerRumorSeed(RumorSeed seed) {
    _rumors.add(seed);
  }

  void registerPowerEvent(PowerUsageEvent event) {
    _powerEvents.add(event);
  }

  void registerTechnology(TechnologyNode node) {
    _technologies.add(node);
  }

  void declareOwnership(List<OwnershipEdge> edges) {
    final adjacency = <String, List<String>>{};
    for (final edge in edges) {
      if (edge.ownerId.isEmpty || edge.ownedId.isEmpty) {
        throw ArgumentError.value(
          edge,
          'edge',
          'ownerId and ownedId must be non-empty',
        );
      }
      adjacency.putIfAbsent(edge.ownerId, () => <String>[]).add(edge.ownedId);
    }
    final visited = <String>{};
    final onStack = <String>{};
    final path = <String>[];

    void dfs(String node) {
      visited.add(node);
      onStack.add(node);
      path.add(node);
      for (final next in adjacency[node] ?? const <String>[]) {
        if (!visited.contains(next)) {
          dfs(next);
        } else if (onStack.contains(next)) {
          final cycleStart = path.indexOf(next);
          path.add(next);
          throw CircularOwnershipException(
            List<String>.unmodifiable(path.sublist(cycleStart)),
          );
        }
      }
      path.removeLast();
      onStack.remove(node);
    }

    for (final node in adjacency.keys) {
      if (!visited.contains(node)) {
        dfs(node);
      }
    }
    _ownership
      ..clear()
      ..addAll(edges);
  }

  IntegrationHealthReport healthCheck() {
    return IntegrationHealthReport.from(
      clock: true,
      map: _mapState != null,
      route: _graph != null,
      factions: false,
      timeline: false,
      economy: false,
      rumor: _rumors.isNotEmpty,
      power: _powerEvents.isNotEmpty,
      technology: _technologies.isNotEmpty,
      sourceRevision: _sourceRevision,
    );
  }

  PartialResult<List<String>> factions() {
    if (healthCheck().factionsReady) {
      return PartialResult<List<String>>.available(const <String>[]);
    }
    return PartialResult<List<String>>.missing(
      'factions subsystem is not registered with CrossSimulationIntegration',
    );
  }

  EventProvenance provenanceFor(String eventId) {
    final match = _events.firstWhere(
      (e) => e.eventId == eventId,
      orElse: () => throw ArgumentError.value(
        eventId,
        'eventId',
        'no event link registered for id',
      ),
    );
    return EventProvenance.fromLink(match);
  }

  NarrativeSliceReport composeNarrativeSlice({required int tick}) {
    if (tick < 0) {
      throw ArgumentError.value(tick, 'tick', 'cannot be negative');
    }
    final linkedEvents = _events
        .where((e) => e.tick == tick)
        .map((e) => e.eventId)
        .toList(growable: false);
    final linkedRumors = _rumors
        .where((r) => r.tick == tick)
        .map((r) => r.id)
        .toList(growable: false);
    final linkedPowers = _powerEvents
        .where((p) => p.tick == tick)
        .map((p) => p.id)
        .toList(growable: false);
    final linkedTech = <String>[];
    final participantSet = <String>{
      for (final e in _events.where((e) => e.tick == tick)) ...e.participants,
    };
    for (final tech in _technologies) {
      if (participantSet.contains(tech.id)) {
        linkedTech.add(tech.id);
      }
    }
    return NarrativeSliceReport._(
      tick: tick,
      linkedEvents: List<String>.unmodifiable(linkedEvents),
      linkedRumors: List<String>.unmodifiable(linkedRumors),
      linkedPowers: List<String>.unmodifiable(linkedPowers),
      linkedTechnologies: List<String>.unmodifiable(linkedTech),
      sourceRevision: _sourceRevision,
    );
  }
}
