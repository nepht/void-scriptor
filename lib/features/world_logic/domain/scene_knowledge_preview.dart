// Scene Knowledge & Rumor Preview - Sprint 110.38.
//
// Domain-only resolver combining RumorPropagationSimulator (110.37)
// with CharacterLocationTimeline (110.27) for in-scene awareness.
//
// Acceptance canonical: knowledge_query, arrival_time, source_chain,
// confidence, writer_preview.
//
// Domain-only, deterministic, no persistence/UI/wall clock/random/net.

import 'character_location_history.dart';
import 'rumor_propagation.dart';

class SceneKnowledgeView {
  const SceneKnowledgeView({
    required this.personId,
    required this.knowsFact,
    required this.arrivalTick,
    required this.confidence,
    required this.sourceChain,
    required this.reason,
    required this.isInScene,
    required this.locationId,
  });
  final String personId;
  final bool knowsFact;
  final int arrivalTick;
  final double confidence;
  final List<String> sourceChain;
  final String reason;
  final bool isInScene;
  final String? locationId;
}

class SceneKnowledgePreview {
  const SceneKnowledgePreview({
    required this.factId,
    required this.sceneTick,
    required this.entries,
  });
  final String factId;
  final int sceneTick;
  final List<SceneKnowledgeView> entries;
}

class SceneKnowledgeReport {
  const SceneKnowledgeReport({
    required this.factId,
    required this.sceneTick,
    required this.knowledge,
  });
  final String factId;
  final int sceneTick;
  final List<SceneKnowledgeView> knowledge;
}

class SceneKnowledgeResolver {
  SceneKnowledgeResolver({
    required List<RumorSeed> seeds,
    required this._simulator,
    required List<CharacterLocationTimeline> timelines,
    this._networkOverride,
    RumorTraits? traitsOverride,
    int confidenceFloor = 0,
  }) : _seeds = List<RumorSeed>.unmodifiable(seeds),
       _timelinesByPerson = _indexTimelines(timelines),
       _traits = traitsOverride ?? const RumorTraits(reliability: 10),
       _confidenceFloor = confidenceFloor.clamp(0, 1).toDouble();

  final List<RumorSeed> _seeds;
  final RumorPropagationSimulator _simulator;
  final Map<String, CharacterLocationTimeline> _timelinesByPerson;
  final RumorNetwork? _networkOverride;
  final RumorTraits _traits;
  final double _confidenceFloor;

  static Map<String, CharacterLocationTimeline> _indexTimelines(
    List<CharacterLocationTimeline> timelines,
  ) {
    final map = <String, CharacterLocationTimeline>{};
    for (final t in timelines) {
      map[t.personId] = t;
    }
    return Map<String, CharacterLocationTimeline>.unmodifiable(map);
  }

  RumorSeed? _seedFor(String factId) {
    for (final s in _seeds) {
      if (s.id == factId) return s;
    }
    return null;
  }

  SceneKnowledgeReport whoKnows({
    required String factId,
    required int sceneTick,
    String? sceneLocationId,
  }) {
    if (sceneTick < 0) {
      throw ArgumentError.value(sceneTick, 'sceneTick', 'must be >= 0');
    }
    final seed = _seedFor(factId);
    if (seed == null) {
      throw ArgumentError.value(factId, 'factId', 'unknown fact id');
    }

    final network = _networkOverride ?? _buildDefaultNetwork(seed);
    final result = _simulator.simulate(
      seed: seed,
      network: network,
      traits: _traits,
      upToTick: sceneTick,
    );

    final knowledge = <SceneKnowledgeView>[];

    final originId = seed.origin.personId;
    if (originId != null && originId.isNotEmpty) {
      final knows = seed.tick <= sceneTick;
      final originReason = knows
          ? "origin of fact ${seed.id} at tick ${seed.tick}"
          : "origin fact ${seed.id} not yet occurring at tick $sceneTick";
      knowledge.add(
        _buildView(
          seed: seed,
          personId: originId,
          arrivalTick: knows ? seed.tick : -1,
          confidence: knows ? 1.0 : 0.0,
          sourceChain: <String>[seed.source.revision],
          sceneTick: sceneTick,
          sceneLocationId: sceneLocationId,
          knowsFact: knows,
          reasonOverride: originReason,
        ),
      );
    }

    for (final reach in result.recipients) {
      final knows = reach.arrivalTick <= sceneTick;
      final reason = knows
          ? "knows fact ${seed.id} arriving at tick ${reach.arrivalTick}"
          : "not yet propagated; expected at tick ${reach.arrivalTick} > sceneTick $sceneTick";
      knowledge.add(
        _buildView(
          seed: seed,
          personId: reach.personId,
          arrivalTick: knows ? reach.arrivalTick : -1,
          confidence: reach.confidence,
          sourceChain: <String>[seed.source.revision, ...reach.sourceChain],
          sceneTick: sceneTick,
          sceneLocationId: sceneLocationId,
          knowsFact: knows,
          reasonOverride: reason,
        ),
      );
    }

    knowledge.sort((a, b) {
      final c = a.personId.compareTo(b.personId);
      if (c != 0) return c;
      return a.arrivalTick.compareTo(b.arrivalTick);
    });

    return SceneKnowledgeReport(
      factId: factId,
      sceneTick: sceneTick,
      knowledge: List<SceneKnowledgeView>.unmodifiable(knowledge),
    );
  }

  SceneKnowledgePreview writerPreview({
    required String factId,
    required int sceneTick,
    String? sceneLocationId,
  }) {
    final report = whoKnows(
      factId: factId,
      sceneTick: sceneTick,
      sceneLocationId: sceneLocationId,
    );

    final knowers = report.knowledge.where((k) => k.knowsFact).toList()
      ..sort((a, b) {
        final c = a.arrivalTick.compareTo(b.arrivalTick);
        if (c != 0) return c;
        return a.personId.compareTo(b.personId);
      });

    return SceneKnowledgePreview(
      factId: factId,
      sceneTick: sceneTick,
      entries: List<SceneKnowledgeView>.unmodifiable(knowers),
    );
  }

  SceneKnowledgeView _buildView({
    required RumorSeed seed,
    required String personId,
    required int arrivalTick,
    required double confidence,
    required List<String> sourceChain,
    required int sceneTick,
    required String? sceneLocationId,
    required bool knowsFact,
    required String reasonOverride,
  }) {
    final confidenceClamped = confidence.clamp(0.0, 1.0).toDouble();
    var reason = reasonOverride;
    if (knowsFact && confidenceClamped < _confidenceFloor) {
      reason =
          "$reason (confidence ${confidenceClamped.toStringAsFixed(3)} below floor)";
    }

    String? locId;
    var isInScene = false;
    if (sceneLocationId != null) {
      final timeline = _timelinesByPerson[personId];
      if (timeline != null) {
        final res = timeline.resolveAt(sceneTick);
        if (res.isKnown && res.locationId == sceneLocationId) {
          isInScene = true;
          locId = res.locationId;
          reason = "$reason; in scene";
        }
      }
      if (!isInScene) {
        reason = "$reason; not in scene";
      }
    }

    return SceneKnowledgeView(
      personId: personId,
      knowsFact: knowsFact,
      arrivalTick: arrivalTick,
      confidence: confidenceClamped,
      sourceChain: List<String>.unmodifiable(sourceChain),
      reason: reason,
      isInScene: isInScene,
      locationId: locId,
    );
  }

  RumorNetwork _buildDefaultNetwork(RumorSeed seed) {
    final persons = <String>{};
    final origin = seed.origin.personId;
    if (origin != null && origin.isNotEmpty) {
      persons.add(origin);
    }
    persons.addAll(_timelinesByPerson.keys);
    return RumorNetwork(persons: persons, edges: const <RumorEdge>[]);
  }
}
