import "derived_result_provenance.dart";
import "genealogy_relationship_rules.dart";

extension FactionValidityRangeOverlap on ValidityRange {
  bool overlaps(ValidityRange other) {
    final myTo = toTick;
    final otherTo = other.toTick;
    final a = fromTick;
    final b = other.fromTick;
    final aEnd = myTo ?? (1 << 30);
    final bEnd = otherTo ?? (1 << 30);
    return a <= bEnd && b <= aEnd;
  }
}

class FactionId {
  final String value;
  const FactionId(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is FactionId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => "FactionId()";
}

enum DiplomacyRelationKind {
  publicAlly,
  publicRival,
  publicNeutral,
  secretAlliance,
  secretPlot,
  perceivedAllied,
  perceivedHostile,
  perceivedNeutral,
}

class FactionRelation {
  final String id;
  final FactionId from;
  final FactionId to;
  final DiplomacyRelationKind kind;
  final ValidityRange validity;
  final double tone;
  final ResultOrigin? provenance;

  FactionRelation({
    required this.id,
    required this.from,
    required this.to,
    required this.kind,
    required this.validity,
    this.tone = 0.0,
    this.provenance,
  }) {
    if (from == to) {
      throw ArgumentError("FactionRelation self-loop not allowed: $id");
    }
  }

  factory FactionRelation.validated({
    required String id,
    required FactionId from,
    required FactionId to,
    required DiplomacyRelationKind kind,
    required ValidityRange validity,
    double tone = 0.0,
    ResultOrigin? provenance,
  }) {
    if (tone < -1.0 || tone > 1.0) {
      throw ArgumentError("tone must be in [-1, 1], got $tone");
    }
    return FactionRelation(
      id: id,
      from: from,
      to: to,
      kind: kind,
      validity: validity,
      tone: tone,
      provenance: provenance,
    );
  }
}

class FactionTreaty {
  final String id;
  final FactionId a;
  final FactionId b;
  final List<String> terms;
  final ValidityRange validity;

  const FactionTreaty({
    required this.id,
    required this.a,
    required this.b,
    required this.terms,
    required this.validity,
  });
}

class FactionConflict {
  final String id;
  final FactionId a;
  final FactionId b;
  final int severity;
  final ValidityRange validity;

  const FactionConflict({
    required this.id,
    required this.a,
    required this.b,
    required this.severity,
    required this.validity,
  });
}

class FactionTrade {
  final String id;
  final FactionId a;
  final FactionId b;
  final Map<String, num> goods;
  final ValidityRange validity;

  const FactionTrade({
    required this.id,
    required this.a,
    required this.b,
    required this.goods,
    required this.validity,
  });
}

class FactionRelationOverlap implements Exception {
  final String existingId;
  final String incomingId;
  final int conflictingFromTick;
  final int conflictingToTick;

  FactionRelationOverlap({
    required this.existingId,
    required this.incomingId,
    required this.conflictingFromTick,
    required this.conflictingToTick,
  });

  @override
  String toString() =>
      "FactionRelationOverlap($incomingId conflicts with $existingId)";
}

class FactionDiplomacyRegistry {
  final Map<String, FactionRelation> _relations = {};
  final Map<String, FactionTreaty> _treaties = {};
  final Map<String, FactionConflict> _conflicts = {};
  final Map<String, FactionTrade> _trades = {};

  List<FactionRelation> get relations => List.unmodifiable(_relations.values);

  void upsertRelation(FactionRelation relation) {
    if (relation.provenance != null) {
      _relations[relation.id] = relation;
      return;
    }
    for (final existing in _relations.values) {
      if (existing.id == relation.id) continue;
      if (existing.from != relation.from || existing.to != relation.to) {
        continue;
      }
      if (existing.kind != relation.kind) continue;
      if (existing.validity.overlaps(relation.validity)) {
        throw FactionRelationOverlap(
          existingId: existing.id,
          incomingId: relation.id,
          conflictingFromTick: relation.validity.fromTick,
          conflictingToTick: relation.validity.toTick ?? 0,
        );
      }
    }
    _relations[relation.id] = relation;
  }

  FactionRelation? relationById(String id) => _relations[id];

  void attachProvenance(String id, ResultOrigin origin) {
    final existing = _relations[id];
    if (existing == null) return;
    _relations[id] = FactionRelation.validated(
      id: existing.id,
      from: existing.from,
      to: existing.to,
      kind: existing.kind,
      validity: existing.validity,
      tone: existing.tone,
      provenance: origin,
    );
  }

  void upsertTreaty(FactionTreaty treaty) {
    if (treaty.a == treaty.b) {
      throw ArgumentError("FactionTreaty self-pair not allowed: ${treaty.id}");
    }
    _treaties[treaty.id] = treaty;
  }

  FactionTreaty? treatyById(String id) => _treaties[id];

  void upsertConflict(FactionConflict conflict) {
    if (conflict.a == conflict.b) {
      throw ArgumentError(
        "FactionConflict self-pair not allowed: ${conflict.id}",
      );
    }
    _conflicts[conflict.id] = conflict;
  }

  FactionConflict? conflictById(String id) => _conflicts[id];

  void upsertTrade(FactionTrade trade) {
    if (trade.a == trade.b) {
      throw ArgumentError("FactionTrade self-pair not allowed: ${trade.id}");
    }
    _trades[trade.id] = trade;
  }

  FactionTrade? tradeById(String id) => _trades[id];

  int get eventCount => _treaties.length + _conflicts.length + _trades.length;

  int eventsForFaction(FactionId faction) {
    var n = 0;
    for (final t in _treaties.values) {
      if (t.a == faction || t.b == faction) n++;
    }
    for (final c in _conflicts.values) {
      if (c.a == faction || c.b == faction) n++;
    }
    for (final tr in _trades.values) {
      if (tr.a == faction || tr.b == faction) n++;
    }
    return n;
  }

  List<FactionRelation> historyOf(FactionId faction) {
    final list =
        _relations.values
            .where((r) => r.from == faction || r.to == faction)
            .toList()
          ..sort((a, b) => a.validity.fromTick.compareTo(b.validity.fromTick));
    return List.unmodifiable(list);
  }
}
