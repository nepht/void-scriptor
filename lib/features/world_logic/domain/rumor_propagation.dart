// Rumor Propagation Simulation - Sprint 110.37.
// Domain-only deterministic simulator that spreads a seed rumor through a
// directed person network with explicit latency, reliability, and distortion.
// Replayable: identical inputs yield identical outputs (no random, no clock).

import 'dart:math' as math;

class RumorSource {
  final String revision;
  final String reason;
  const RumorSource({required this.revision, required this.reason});
}

class RumorOrigin {
  final String? locationId;
  final String? personId;
  final String? factionId;
  const RumorOrigin({this.locationId, this.personId, this.factionId});

  bool get hasAny =>
      (locationId != null && locationId!.isNotEmpty) ||
      (personId != null && personId!.isNotEmpty) ||
      (factionId != null && factionId!.isNotEmpty);

  String get primaryId => personId ?? locationId ?? factionId ?? '';
}

class RumorSeed {
  final String id;
  final String summary;
  final RumorOrigin origin;
  final int tick;
  final RumorSource source;

  const RumorSeed({
    required this.id,
    required this.summary,
    required this.origin,
    required this.tick,
    required this.source,
  });

  factory RumorSeed.validated({
    required String id,
    required String summary,
    required RumorOrigin origin,
    required int tick,
    required RumorSource source,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'RumorSeed id must be non-empty');
    }
    if (summary.isEmpty) {
      throw ArgumentError.value(
        summary,
        'summary',
        'RumorSeed summary must be non-empty',
      );
    }
    if (!origin.hasAny) {
      throw ArgumentError.value(
        origin,
        'origin',
        'RumorSeed origin must specify at least one id',
      );
    }
    if (tick < 0) {
      throw ArgumentError.value(tick, 'tick', 'RumorSeed tick must be >= 0');
    }
    if (source.revision.isEmpty || source.reason.isEmpty) {
      throw ArgumentError.value(
        source,
        'source',
        'RumorSource revision and reason must be non-empty',
      );
    }
    return RumorSeed(
      id: id,
      summary: summary,
      origin: origin,
      tick: tick,
      source: source,
    );
  }
}

class RumorTraits {
  final int reliability; // [0,10]; 10 = perfect
  final double distortionFactor; // [0,1]; per-hop distortion added
  final int propagationDelayTicks; // >=0
  const RumorTraits({
    this.reliability = 10,
    this.distortionFactor = 0,
    this.propagationDelayTicks = 1,
  });
}

class RumorEdge {
  final String from;
  final String to;
  const RumorEdge({required this.from, required this.to});
}

class RumorNetwork {
  final Set<String> persons;
  final List<RumorEdge> edges;
  RumorNetwork({required this.persons, required this.edges}) {
    for (final p in persons) {
      if (p.isEmpty) {
        throw ArgumentError.value(p, 'persons', 'person id must be non-empty');
      }
    }
    for (final e in edges) {
      if (!persons.contains(e.from)) {
        throw ArgumentError.value(
          e.from,
          'edges',
          'edge from references unknown person',
        );
      }
      if (!persons.contains(e.to)) {
        throw ArgumentError.value(
          e.to,
          'edges',
          'edge to references unknown person',
        );
      }
      if (e.from == e.to) {
        throw ArgumentError.value(e, 'edges', 'self-loop edge not allowed');
      }
    }
  }
}

class RumorReach {
  final String personId;
  final int arrivalTick;
  final double confidence;
  final double distortion;
  final String distortedSummary;
  final List<String> sourceChain;
  const RumorReach({
    required this.personId,
    required this.arrivalTick,
    required this.confidence,
    required this.distortion,
    required this.distortedSummary,
    required this.sourceChain,
  });
}

class RumorResult {
  final List<RumorReach> recipients;
  const RumorResult({required this.recipients});
}

class RumorPropagationSimulator {
  const RumorPropagationSimulator();

  RumorResult simulate({
    required RumorSeed seed,
    required RumorNetwork network,
    required RumorTraits traits,
    required int upToTick,
  }) {
    if (upToTick < seed.tick) {
      return const RumorResult(recipients: <RumorReach>[]);
    }
    // Validate reliability/distortionFactor ranges.
    final reliability = traits.reliability.clamp(0, 10);
    final distortionFactor = traits.distortionFactor.clamp(0.0, 1.0);
    final delay = math.max(0, traits.propagationDelayTicks);

    // Build adjacency lists (deterministic: sort by to-id for stable ordering).
    final outgoing = <String, List<String>>{};
    for (final p in network.persons) {
      outgoing[p] = <String>[];
    }
    for (final e in network.edges) {
      outgoing[e.from]!.add(e.to);
    }
    for (final list in outgoing.values) {
      list.sort();
    }

    // Determine the starting node(s). Prefer the person on the origin; if no
    // person is set, fall back to broadcasting from the first person in the
    // network as a deterministic degenerate case.
    final originId =
        seed.origin.personId ??
        (network.persons.isNotEmpty
            ? (network.persons.toList()..sort()).first
            : null);
    if (originId == null || !network.persons.contains(originId)) {
      return const RumorResult(recipients: <RumorReach>[]);
    }

    // BFS (deterministic): front is a list, processed in insertion order.
    final reaches = <String, RumorReach>{};
    final queue = <_QNode>[
      _QNode(
        personId: originId,
        arrivalTick: seed.tick,
        confidence: 1.0,
        distortion: 0.0,
        distortedSummary: seed.summary,
        chain: <String>[seed.id],
      ),
    ];

    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      // Skip if already reached via a shorter path.
      final existing = reaches[cur.personId];
      if (existing != null && existing.arrivalTick <= cur.arrivalTick) {
        continue;
      }
      reaches[cur.personId] = RumorReach(
        personId: cur.personId,
        arrivalTick: cur.arrivalTick,
        confidence: cur.confidence,
        distortion: cur.distortion,
        distortedSummary: cur.distortedSummary,
        sourceChain: List<String>.unmodifiable(cur.chain),
      );
      // Spread along outgoing edges.
      for (final nextId in outgoing[cur.personId]!) {
        final newTick = cur.arrivalTick + delay;
        if (newTick > upToTick) {
          continue;
        }
        final newConfidence = (cur.confidence * (reliability / 10.0)).clamp(
          0.0,
          1.0,
        );
        final newDistortion = math.min(1.0, cur.distortion + distortionFactor);
        final newSummary = _distortText(cur.distortedSummary, newDistortion);
        // Extend source chain with a stable per-hop rumor id derived from
        // incoming + outgoing node ids (deterministic, replayable).
        final hopId = '${cur.chain.last}>$nextId';
        queue.add(
          _QNode(
            personId: nextId,
            arrivalTick: newTick,
            confidence: newConfidence,
            distortion: newDistortion,
            distortedSummary: newSummary,
            chain: <String>[...cur.chain, hopId],
          ),
        );
      }
    }

    // Drop origin from final recipients (only downstream persons are reported).
    reaches.remove(originId);
    final recipients = reaches.values.toList()
      ..sort((a, b) {
        final c = a.arrivalTick.compareTo(b.arrivalTick);
        if (c != 0) return c;
        return a.personId.compareTo(b.personId);
      });
    return RumorResult(recipients: List<RumorReach>.unmodifiable(recipients));
  }

  // Deterministic distortion: append a marker per hop so the summary diverges
  // visibly without using random. Real textual mutation is out of scope; the
  // invariant is that distortion=0 keeps the summary verbatim.
  String _distortText(String text, double distortion) {
    if (distortion <= 0) return text;
    final hops = (distortion * 10).round();
    return '$text [x$hops]';
  }
}

class _QNode {
  final String personId;
  final int arrivalTick;
  final double confidence;
  final double distortion;
  final String distortedSummary;
  final List<String> chain;
  _QNode({
    required this.personId,
    required this.arrivalTick,
    required this.confidence,
    required this.distortion,
    required this.distortedSummary,
    required this.chain,
  });
}
