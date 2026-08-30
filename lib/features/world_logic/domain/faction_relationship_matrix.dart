// Sprint 110.23 - Faction Relationship Matrix.
//
// Domain-only contract for directed faction-to-faction relations with
// relationship type, intensity, validity ranges, and a per-tick matrix
// view. No persistence, UI, locale, network, wall clock, or random input.

library;

enum FactionRelationKind { ally, rival, enemy, neutral, vassal, overlord }

class FactionNode {
  const FactionNode({required this.id, required this.name});
  final String id;
  final String name;
}

class FactionRelationship {
  const FactionRelationship({
    required this.id,
    required this.kind,
    required this.fromId,
    required this.toId,
    required this.intensity,
    required this.validFrom,
    this.validUntil,
    this.note = '',
  });

  factory FactionRelationship.validated({
    required String id,
    required FactionRelationKind kind,
    required String fromId,
    required String toId,
    required int intensity,
    required int validFrom,
    int? validUntil,
    String note = '',
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'id cannot be empty');
    }
    if (fromId.isEmpty) {
      throw ArgumentError.value(fromId, 'fromId', 'fromId cannot be empty');
    }
    if (toId.isEmpty) {
      throw ArgumentError.value(toId, 'toId', 'toId cannot be empty');
    }
    if (fromId == toId) {
      throw ArgumentError('Self-relation is not allowed (fromId == toId)');
    }
    if (intensity < 0 || intensity > 10) {
      throw ArgumentError.value(
        intensity,
        'intensity',
        'intensity must be within [0, 10]',
      );
    }
    if (validFrom < 0) {
      throw ArgumentError.value(
        validFrom,
        'validFrom',
        'validFrom cannot be negative',
      );
    }
    if (validUntil != null && validUntil < validFrom) {
      throw ArgumentError(
        'validUntil ($validUntil) cannot be less than validFrom ($validFrom)',
      );
    }
    return FactionRelationship(
      id: id,
      kind: kind,
      fromId: fromId,
      toId: toId,
      intensity: intensity,
      validFrom: validFrom,
      validUntil: validUntil,
      note: note,
    );
  }

  final String id;
  final FactionRelationKind kind;
  final String fromId;
  final String toId;
  final int intensity;
  final int validFrom;
  final int? validUntil;
  final String note;

  bool isActiveAt(int tick) {
    if (tick < validFrom) return false;
    if (validUntil != null && tick > validUntil!) return false;
    return true;
  }
}

class FactionRelationshipMatrix {
  FactionRelationshipMatrix({
    required List<FactionNode> nodes,
    required List<FactionRelationship> edges,
  }) : _nodes = Map.unmodifiable({for (final n in nodes) n.id: n}),
       _edges = List.unmodifiable(edges) {
    final ids = _nodes.keys.toSet();
    for (final e in _edges) {
      if (e.validFrom < 0) {
        throw ArgumentError('validFrom cannot be negative: ${e.id}');
      }
      if (e.validUntil != null && e.validUntil! < e.validFrom) {
        throw ArgumentError(
          'validUntil (${e.validUntil}) cannot be less than '
          'validFrom (${e.validFrom}) for edge ${e.id}',
        );
      }
      if (!ids.contains(e.fromId)) {
        throw ArgumentError(
          'Edge ${e.id} references unknown fromId ${e.fromId}',
        );
      }
      if (!ids.contains(e.toId)) {
        throw ArgumentError('Edge ${e.id} references unknown toId ${e.toId}');
      }
    }
  }

  final Map<String, FactionNode> _nodes;
  final List<FactionRelationship> _edges;

  Map<String, FactionNode> get nodes => _nodes;
  List<FactionRelationship> get edges => _edges;

  List<FactionRelationship> relationsBetween(String fromId, String toId) {
    return _edges
        .where((e) => e.fromId == fromId && e.toId == toId)
        .toList(growable: false);
  }

  FactionRelationshipMatrixSnapshot snapshotAt(int tick) {
    final active = _edges
        .where((e) => e.isActiveAt(tick))
        .toList(growable: false);
    return FactionRelationshipMatrixSnapshot._(
      nodes: _nodes,
      relations: active,
    );
  }
}

class FactionRelationshipMatrixSnapshot {
  const FactionRelationshipMatrixSnapshot._({
    required this.nodes,
    required this.relations,
  });

  final Map<String, FactionNode> nodes;
  final List<FactionRelationship> relations;

  List<String> get factionIds => nodes.keys.toList(growable: false);

  FactionNode? nodeById(String id) => nodes[id];
}
