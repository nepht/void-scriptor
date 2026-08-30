// Sprint 110.17 - Genealogy Relationship Rules.
//
// Domain-only contract for biological, adoptive, partnership, guardian,
// clan, and dynasty relations. Every edge carries a validity range so the
// graph can be queried at a specific world tick. No persistence, UI,
// locale, network, wall clock, or random input.

library;

enum GenealogyRelationKind {
  parentChild,
  adoption,
  partnership,
  guardian,
  clan,
}

class GenealogyNode {
  const GenealogyNode({required this.id, required this.name});
  final String id;
  final String name;
}

class GenealogyRelation {
  const GenealogyRelation({
    required this.id,
    required this.kind,
    required this.fromId,
    required this.toId,
    required this.validFrom,
    this.validUntil,
    this.note = "",
  });

  factory GenealogyRelation.validated({
    required String id,
    required GenealogyRelationKind kind,
    required String fromId,
    required String toId,
    required int validFrom,
    int? validUntil,
    String note = "",
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, "id", "id cannot be empty");
    }
    if (validFrom < 0) {
      throw ArgumentError.value(
        validFrom,
        "validFrom",
        "validFrom cannot be negative",
      );
    }
    if (validUntil != null && validUntil < validFrom) {
      throw ArgumentError(
        "validUntil ($validUntil) cannot be less than validFrom ($validFrom)",
      );
    }
    return GenealogyRelation(
      id: id,
      kind: kind,
      fromId: fromId,
      toId: toId,
      validFrom: validFrom,
      validUntil: validUntil,
      note: note,
    );
  }

  final String id;
  final GenealogyRelationKind kind;
  final String fromId;
  final String toId;
  final int validFrom;
  final int? validUntil;
  final String note;
}

class GenealogyGraph {
  GenealogyGraph({
    required Map<String, GenealogyNode> nodes,
    required List<GenealogyRelation> edges,
  }) : nodes = Map.unmodifiable(nodes),
       _edges = List.unmodifiable(edges) {
    final ids = nodes.keys.toSet();
    for (final e in _edges) {
      if (e.validFrom < 0) {
        throw ArgumentError("validFrom cannot be negative: ${e.id}");
      }
      if (e.validUntil != null && e.validUntil! < e.validFrom) {
        throw ArgumentError(
          "validUntil cannot be less than validFrom: ${e.id}",
        );
      }
    }
    for (final e in _edges) {
      if (e.kind == GenealogyRelationKind.clan) {
        if (!ids.contains(e.fromId)) {
          throw ArgumentError(
            "relation references unknown member node: ${e.id}",
          );
        }
      } else {
        if (!ids.contains(e.fromId) || !ids.contains(e.toId)) {
          throw ArgumentError("relation references unknown node: ${e.id}");
        }
      }
      if (e.fromId == e.toId) {
        throw ArgumentError("self-loop not allowed: ${e.id}");
      }
    }
  }

  final Map<String, GenealogyNode> nodes;
  final List<GenealogyRelation> _edges;

  /// Unmodifiable view of all edges in insertion order. Sprint 110.19 adds
  /// this getter so the inheritance validator can iterate the edge set
  /// without exposing the mutable internal list.
  List<GenealogyRelation> get edges =>
      List<GenealogyRelation>.unmodifiable(_edges);

  bool _isActive(GenealogyRelation e, int tick) {
    if (tick < e.validFrom) return false;
    if (e.validUntil != null && tick > e.validUntil!) return false;
    return true;
  }

  List<GenealogyRelation> _edgesOfKind(
    GenealogyRelationKind kind, {
    int? atTick,
  }) {
    return _edges
        .where((e) {
          if (e.kind != kind) return false;
          if (atTick != null && !_isActive(e, atTick)) return false;
          return true;
        })
        .toList(growable: false);
  }

  List<String> parentsOf(String nodeId, {int? atTick}) {
    final pc = _edgesOfKind(
      GenealogyRelationKind.parentChild,
      atTick: atTick,
    ).where((e) => e.toId == nodeId).map((e) => e.fromId);
    final ad = _edgesOfKind(
      GenealogyRelationKind.adoption,
      atTick: atTick,
    ).where((e) => e.toId == nodeId).map((e) => e.fromId);
    return {...pc, ...ad}.toList(growable: false);
  }

  List<String> childrenOf(String nodeId, {int? atTick}) {
    final pc = _edgesOfKind(
      GenealogyRelationKind.parentChild,
      atTick: atTick,
    ).where((e) => e.fromId == nodeId).map((e) => e.toId);
    final ad = _edgesOfKind(
      GenealogyRelationKind.adoption,
      atTick: atTick,
    ).where((e) => e.fromId == nodeId).map((e) => e.toId);
    return {...pc, ...ad}.toList(growable: false);
  }

  List<String> adoptiveParentsOf(String nodeId, {int? atTick}) {
    return _edgesOfKind(GenealogyRelationKind.adoption, atTick: atTick)
        .where((e) => e.toId == nodeId)
        .map((e) => e.fromId)
        .toList(growable: false);
  }

  List<String> partnersOf(String nodeId, {int? atTick}) {
    final list = <String>[];
    for (final e in _edgesOfKind(
      GenealogyRelationKind.partnership,
      atTick: atTick,
    )) {
      if (e.fromId == nodeId) list.add(e.toId);
      if (e.toId == nodeId) list.add(e.fromId);
    }
    return list;
  }

  String? guardianOf(String nodeId, {int? atTick}) {
    for (final e in _edgesOfKind(
      GenealogyRelationKind.guardian,
      atTick: atTick,
    )) {
      if (e.toId == nodeId) return e.fromId;
    }
    return null;
  }

  List<String> wardsOf(String nodeId, {int? atTick}) {
    return _edgesOfKind(GenealogyRelationKind.guardian, atTick: atTick)
        .where((e) => e.fromId == nodeId)
        .map((e) => e.toId)
        .toList(growable: false);
  }

  List<String> membersOfClan(String clanId, {int? atTick}) {
    return _edgesOfKind(GenealogyRelationKind.clan, atTick: atTick)
        .where((e) => e.toId == clanId)
        .map((e) => e.fromId)
        .toList(growable: false);
  }

  List<String> clansOf(String nodeId, {int? atTick}) {
    return _edgesOfKind(GenealogyRelationKind.clan, atTick: atTick)
        .where((e) => e.fromId == nodeId)
        .map((e) => e.toId)
        .toList(growable: false);
  }
}
