// Sprint 110.19 - Genealogy & Inheritance Validation.
//
// Domain-only validator atop GenealogyRegistry (110.17) + GenealogyTree
// (110.18) + ValidityRange. Mendeteksi hubungan mustahil dan menghitung
// kandidat pewaris berdasarkan rule yang dapat diedit, dengan dukungan
// manual exception. Tidak ada persistence, UI, wall clock, locale, atau
// random input; perhitungan deterministic.

import "genealogy_relationship_rules.dart";

enum InheritanceIssueKind { cycle, dateConsistency, clanParentConflict }

class InheritanceIssue {
  const InheritanceIssue({
    required this.kind,
    required this.nodeIds,
    required this.reason,
  }) : assert(nodeIds.length > 0, "nodeIds tidak boleh kosong"),
       assert(reason.length > 0, "reason tidak boleh kosong");

  final InheritanceIssueKind kind;
  final List<String> nodeIds;
  final String reason;

  @override
  String toString() => "InheritanceIssue(kind: $kind, nodes: $nodeIds)";
}

class InheritanceValidationResult {
  const InheritanceValidationResult({
    required this.issues,
    required this.asOfTick,
  });

  final List<InheritanceIssue> issues;
  final int asOfTick;

  bool get isValid => issues.isEmpty;
}

class InheritanceRuleSet {
  const InheritanceRuleSet({required this.order, required this.excludes});

  final List<GenealogyRelationType> order;
  final Set<GenealogyRelationType> excludes;

  static const standard = InheritanceRuleSet(
    order: [
      GenealogyRelationType.parentChild,
      GenealogyRelationType.adoption,
      GenealogyRelationType.guardian,
    ],
    excludes: {GenealogyRelationType.partnership, GenealogyRelationType.clan},
  );
}

class GenealogyInheritanceValidator {
  const GenealogyInheritanceValidator({
    required this._relations,
    this._ruleAccess = const _DefaultRuleAccess(),
    this.ruleSet = InheritanceRuleSet.standard,
    this.manualExceptions = const <String>{},
  });

  factory GenealogyInheritanceValidator.fromRegistry(
    GenealogyRegistry registry, {
    InheritanceRuleSet ruleSet = InheritanceRuleSet.standard,
    Set<String> manualExceptions = const <String>{},
  }) {
    return GenealogyInheritanceValidator(
      relations: registry.relations,
      ruleSet: ruleSet,
      manualExceptions: manualExceptions,
    );
  }

  final Iterable<GenealogyRelation> _relations;
  final GenealogyRuleAccess _ruleAccess;
  final InheritanceRuleSet ruleSet;
  final Set<String> manualExceptions;

  InheritanceValidationResult validate({required int asOfTick}) {
    final active = _relations
        .where((r) => _ruleAccess.isActiveAt(r, asOfTick))
        .toList(growable: false);

    final issues = <InheritanceIssue>[];

    _detectCycles(active, issues);
    _detectDateInconsistency(active, issues);
    _detectClanParentConflict(active, issues);

    return InheritanceValidationResult(issues: issues, asOfTick: asOfTick);
  }

  List<String> candidatesFor(String nodeId) {
    final result = <String>[];
    final seen = <String>{};

    for (final type in ruleSet.order) {
      for (final r in _relations) {
        if (r.type != type) continue;
        if (r.toId != nodeId) continue;
        if (seen.add(r.fromId)) {
          result.add(r.fromId);
        }
      }
    }

    return List<String>.unmodifiable(result);
  }

  void _detectCycles(
    List<GenealogyRelation> active,
    List<InheritanceIssue> sink,
  ) {
    final adjacency = <String, List<String>>{};
    final nodes = <String>{};
    for (final r in active) {
      if (r.type != GenealogyRelationType.parentChild) continue;
      if (manualExceptions.contains(r.fromId) ||
          manualExceptions.contains(r.toId)) {
        continue;
      }
      adjacency.putIfAbsent(r.fromId, () => <String>[]).add(r.toId);
      nodes.add(r.fromId);
      nodes.add(r.toId);
    }
    final color = <String, int>{for (final n in nodes) n: 0};
    final stack = <String>[];

    bool dfs(String u) {
      color[u] = 1;
      stack.add(u);
      for (final v in adjacency[u] ?? const <String>[]) {
        final c = color[v] ?? 0;
        if (c == 1) {
          final idx = stack.indexOf(v);
          if (idx >= 0) {
            final cycleNodes = stack.sublist(idx);
            sink.add(
              InheritanceIssue(
                kind: InheritanceIssueKind.cycle,
                nodeIds: List<String>.unmodifiable(cycleNodes),
                reason:
                    "parent_child cycle: ${cycleNodes.join(" -> ")} -> ${cycleNodes.first}",
              ),
            );
          }
          return true;
        } else if (c == 0) {
          if (dfs(v)) return true;
        }
      }
      stack.removeLast();
      color[u] = 2;
      return false;
    }

    for (final n in nodes) {
      if ((color[n] ?? 0) == 0) {
        dfs(n);
      }
    }
  }

  void _detectDateInconsistency(
    List<GenealogyRelation> active,
    List<InheritanceIssue> sink,
  ) {
    // date consistency dicek terhadap semua relasi parent_child/adoption
    // (termasuk yang tidak aktif di asOfTick) karena ini adalah konflik
    // struktural, bukan temporal.
    for (final r in _relations) {
      if (r.type != GenealogyRelationType.parentChild &&
          r.type != GenealogyRelationType.adoption) {
        continue;
      }
      final v = r.validity;
      if (v == null) continue;
      for (final other in _relations) {
        if (other == r) continue;
        if (other.toId != r.toId) continue;
        if (other.type != GenealogyRelationType.parentChild &&
            other.type != GenealogyRelationType.adoption) {
          continue;
        }
        final cv = other.validity;
        if (cv == null) continue;
        if (v.toTick != null && cv.fromTick > v.toTick!) {
          sink.add(
            InheritanceIssue(
              kind: InheritanceIssueKind.dateConsistency,
              nodeIds: [r.fromId, r.toId],
              reason:
                  "validity ${r.fromId}->${r.toId} berakhir pada tick ${v.toTick} "
                  "sebelum ${other.fromId}->${other.toId} dimulai pada tick ${cv.fromTick}",
            ),
          );
        }
      }
    }
  }

  void _detectClanParentConflict(
    List<GenealogyRelation> active,
    List<InheritanceIssue> sink,
  ) {
    final clanOf = <String, String>{};
    for (final r in active) {
      if (r.type == GenealogyRelationType.clan) {
        clanOf[r.toId] = r.fromId;
      }
    }
    for (final r in active) {
      if (r.type != GenealogyRelationType.parentChild) continue;
      final pc = clanOf[r.fromId];
      final cc = clanOf[r.toId];
      if (pc != null && pc == cc) {
        sink.add(
          InheritanceIssue(
            kind: InheritanceIssueKind.clanParentConflict,
            nodeIds: [r.fromId, r.toId],
            reason:
                "parent ${r.fromId} dan child ${r.toId} "
                "keduanya anggota clan $pc",
          ),
        );
      }
    }
  }
}

abstract class GenealogyRuleAccess {
  const GenealogyRuleAccess();
  bool isActiveAt(GenealogyRelation relation, int asOfTick);
}

class _DefaultRuleAccess extends GenealogyRuleAccess {
  const _DefaultRuleAccess();
  @override
  bool isActiveAt(GenealogyRelation relation, int asOfTick) {
    final v = relation.validity;
    if (v == null) return true;
    return v.contains(asOfTick);
  }
}
