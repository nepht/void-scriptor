// Sprint 110.17 - Genealogy Relationship Rules.
//
// Domain-only genealogy relationship model covering parent_child, adoption,
// partnership, guardian, and clan ties with optional validity ranges. No
// persistence, UI, wall clock, locale, or random input; calculations are
// deterministic and unit-based.

enum GenealogyRelationType {
  parentChild,
  adoption,
  partnership,
  guardian,
  clan,
}

class GenealogyRelationConflict implements Exception {
  const GenealogyRelationConflict(this.message);
  final String message;
  @override
  String toString() => "GenealogyRelationConflict: $message";
}

class GenealogyInvalidRelation implements Exception {
  const GenealogyInvalidRelation(this.message);
  final String message;
  @override
  String toString() => "GenealogyInvalidRelation: $message";
}

class GenealogyCycleDetected implements Exception {
  const GenealogyCycleDetected(this.message);
  final String message;
  @override
  String toString() => "GenealogyCycleDetected: $message";
}

class ValidityRange {
  const ValidityRange({required this.fromTick, this.toTick})
    : assert(fromTick >= 0, "fromTick must be >= 0"),
      assert(
        toTick == null || toTick >= fromTick,
        "toTick must be >= fromTick when present",
      );

  final int fromTick;
  final int? toTick;

  bool contains(int tick, {bool asOfTick = false}) {
    if (tick < fromTick) return false;
    final upper = toTick;
    if (upper == null) {
      if (asOfTick) return true;
      return tick <= (1 << 30);
    }
    return tick <= upper;
  }
}

class GenealogyRelation {
  const GenealogyRelation({
    required this.type,
    required this.fromId,
    required this.toId,
    this.isBiological = false,
    this.validity,
  }) : assert(fromId.length > 0, "fromId must be non-empty"),
       assert(toId.length > 0, "toId must be non-empty");

  const GenealogyRelation.parentChild({
    required String parentId,
    required String childId,
    ValidityRange? validity,
  }) : this(
         type: GenealogyRelationType.parentChild,
         fromId: parentId,
         toId: childId,
         isBiological: true,
         validity: validity,
       );

  const GenealogyRelation.adoption({
    required String parentId,
    required String childId,
    ValidityRange? validity,
  }) : this(
         type: GenealogyRelationType.adoption,
         fromId: parentId,
         toId: childId,
         isBiological: false,
         validity: validity,
       );

  factory GenealogyRelation.partnership({
    required String leftId,
    required String rightId,
    ValidityRange? validity,
  }) {
    if (leftId == rightId) {
      throw const GenealogyInvalidRelation("partnership tidak boleh self-loop");
    }
    return GenealogyRelation(
      type: GenealogyRelationType.partnership,
      fromId: leftId,
      toId: rightId,
      isBiological: false,
      validity: validity,
    );
  }

  const GenealogyRelation.guardian({
    required String guardianId,
    required String wardId,
    ValidityRange? validity,
  }) : this(
         type: GenealogyRelationType.guardian,
         fromId: guardianId,
         toId: wardId,
         isBiological: false,
         validity: validity,
       );

  final GenealogyRelationType type;
  final String fromId;
  final String toId;
  final bool isBiological;
  final ValidityRange? validity;

  List<String> get partnerIds {
    if (type != GenealogyRelationType.partnership) {
      throw const GenealogyInvalidRelation(
        "partnerIds hanya berlaku untuk partnership",
      );
    }
    return <String>[fromId, toId];
  }

  bool isActiveAt(int tick, {bool asOfTick = false}) {
    final range = validity;
    if (range == null) return true;
    return range.contains(tick, asOfTick: asOfTick);
  }

  @override
  String toString() =>
      "GenealogyRelation($type, $fromId->$toId, bio=$isBiological)";
}

class GenealogyRegistry {
  final List<GenealogyRelation> _relations = <GenealogyRelation>[];

  void add(GenealogyRelation relation) {
    _validate(relation);
    _relations.add(relation);
  }

  void _validate(GenealogyRelation relation) {
    switch (relation.type) {
      case GenealogyRelationType.parentChild:
        _validateParentChild(relation);
        break;
      case GenealogyRelationType.adoption:
        _validateAdoption(relation);
        break;
      case GenealogyRelationType.partnership:
        if (relation.fromId == relation.toId) {
          throw const GenealogyInvalidRelation(
            "partnership tidak boleh self-loop",
          );
        }
        break;
      case GenealogyRelationType.guardian:
        if (relation.fromId == relation.toId) {
          throw const GenealogyInvalidRelation(
            "guardian tidak boleh menunjuk diri sendiri",
          );
        }
        break;
      case GenealogyRelationType.clan:
        if (relation.fromId == relation.toId) {
          throw const GenealogyInvalidRelation(
            "clan tidak boleh self-reference",
          );
        }
        break;
    }
  }

  void _validateParentChild(GenealogyRelation relation) {
    final p = relation.fromId;
    final c = relation.toId;
    if (p == c) {
      throw const GenealogyInvalidRelation(
        "parent_child tidak boleh self-loop",
      );
    }
    if (_isAncestorOf(childId: c, ancestorId: p)) {
      throw GenealogyCycleDetected(
        'parent_child $p->$c akan menciptakan siklus silsilah',
      );
    }
    for (final r in _relations) {
      if (r.type == GenealogyRelationType.adoption &&
          r.fromId == p &&
          r.toId == c) {
        throw const GenealogyRelationConflict(
          "sudah ada adoption untuk pasangan node yang sama",
        );
      }
      if (r.type == GenealogyRelationType.parentChild &&
          r.fromId == p &&
          r.toId == c) {
        throw const GenealogyRelationConflict(
          "parent_child duplikat untuk pasangan node yang sama",
        );
      }
    }
  }

  void _validateAdoption(GenealogyRelation relation) {
    final p = relation.fromId;
    final c = relation.toId;
    if (p == c) {
      throw const GenealogyInvalidRelation("adoption tidak boleh self-loop");
    }
    for (final r in _relations) {
      if (r.type == GenealogyRelationType.adoption && r.toId == c) {
        throw const GenealogyRelationConflict(
          "child sudah memiliki adoption aktif",
        );
      }
      if (r.type == GenealogyRelationType.parentChild &&
          r.fromId == p &&
          r.toId == c) {
        throw const GenealogyRelationConflict(
          "sudah ada parent_child untuk pasangan node yang sama",
        );
      }
    }
  }

  bool _isAncestorOf({required String childId, required String ancestorId}) {
    final stack = <String>[childId];
    final visited = <String>{};
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      if (current == ancestorId) return true;
      if (!visited.add(current)) continue;
      for (final r in _relations) {
        if (r.type == GenealogyRelationType.parentChild &&
            r.fromId == current) {
          stack.add(r.toId);
        }
      }
    }
    return false;
  }

  List<GenealogyRelation> relationsOf(String nodeId) {
    return _relations
        .where((r) => r.fromId == nodeId || r.toId == nodeId)
        .toList(growable: false);
  }

  List<String> clanMembers(String clanId) {
    return _relations
        .where(
          (r) => r.type == GenealogyRelationType.clan && r.fromId == clanId,
        )
        .map((r) => r.toId)
        .toList(growable: false);
  }

  List<GenealogyRelation> get relations =>
      List<GenealogyRelation>.unmodifiable(_relations);
}
