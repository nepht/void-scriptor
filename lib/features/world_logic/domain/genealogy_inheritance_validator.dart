// Sprint 110.19 - Genealogy & Inheritance Validation.
//
// Domain-only contract for detecting impossible biological/adoptive
// relations (cycle detection, lifespan consistency), running configurable
// inheritance rules against a focal person, and letting writers annotate
// manual exceptions that suppress or document known findings. Pure Dart,
// deterministic, no persistence/UI/locale/wall clock/random/network.
library;

import "package:void_scriptor/features/world_logic/domain/genealogy_relationships.dart";

enum Gender { male, female, nonBinary, unknown }

class GenderAssignment {
  const GenderAssignment({required this.gender, this.note = ""});
  final Gender gender;
  final String note;
}

class LifeSpan {
  const LifeSpan({
    required this.id,
    required this.birthTick,
    this.deathTick,
    this.note = "",
  });

  factory LifeSpan.validated({
    required String id,
    required int birthTick,
    int? deathTick,
    String note = "",
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, "id", "id cannot be empty");
    }
    if (birthTick < 0) {
      throw ArgumentError.value(
        birthTick,
        "birthTick",
        "birthTick cannot be negative",
      );
    }
    if (deathTick != null && deathTick < birthTick) {
      throw ArgumentError(
        "deathTick ($deathTick) cannot be less than birthTick ($birthTick)",
      );
    }
    return LifeSpan(
      id: id,
      birthTick: birthTick,
      deathTick: deathTick,
      note: note,
    );
  }

  final String id;
  final int birthTick;
  final int? deathTick;
  final String note;
}

enum GenealogyAnomalyCode {
  cycle,
  parentYoungerThanChild,
  childBornAfterParentDeath,
  unknownLifespan,
  partnerIsSelf,
  parentIsSelf,
}

class GenealogyAnomaly {
  const GenealogyAnomaly({
    required this.code,
    required this.nodeIds,
    required this.edgeIds,
    required this.message,
  });
  final GenealogyAnomalyCode code;
  final List<String> nodeIds;
  final List<String> edgeIds;
  final String message;
}

enum InheritanceRuleKind {
  eldestChild,
  eldestMaleChild,
  eldestFemaleChild,
  lastWill,
  adoptedExcluded,
  partnershipGranted,
  custom,
}

class InheritancePolicy {
  const InheritancePolicy({
    required this.rule,
    this.priority = 100,
    this.note = "",
  });
  final InheritanceRuleKind rule;
  final int priority;
  final String note;
}

enum ManualExceptionKind { suppressCycle, annotate }

class ManualException {
  const ManualException({
    required this.kind,
    required this.reason,
    required this.edgeIds,
    this.nodeIds = const <String>[],
  });

  factory ManualException.validated({
    required ManualExceptionKind kind,
    required String reason,
    required List<String> edgeIds,
    List<String> nodeIds = const <String>[],
  }) {
    if (reason.trim().isEmpty) {
      throw ArgumentError.value(reason, "reason", "reason cannot be empty");
    }
    return ManualException(
      kind: kind,
      reason: reason,
      edgeIds: edgeIds,
      nodeIds: nodeIds,
    );
  }

  final ManualExceptionKind kind;
  final String reason;
  final List<String> edgeIds;
  final List<String> nodeIds;
}

class InheritanceCandidate {
  const InheritanceCandidate({
    required this.nodeId,
    required this.rank,
    required this.justification,
    required this.birthTick,
    required this.ruleKind,
  });
  final String nodeId;
  final int rank;
  final String justification;
  final int birthTick;
  final InheritanceRuleKind ruleKind;
}

class AppliedException {
  const AppliedException({
    required this.kind,
    required this.reason,
    required this.edgeIds,
  });
  final ManualExceptionKind kind;
  final String reason;
  final List<String> edgeIds;
}

class GenealogyValidationOptions {
  const GenealogyValidationOptions({
    this.strictMissingLifespan = false,
    this.includePartnershipAnomalies = true,
  });
  final bool strictMissingLifespan;
  final bool includePartnershipAnomalies;
}

class GenealogyValidationReport {
  const GenealogyValidationReport({
    required this.anomalies,
    required this.candidates,
    required this.exceptionsApplied,
    required this.focalId,
  });
  final List<GenealogyAnomaly> anomalies;
  final List<InheritanceCandidate> candidates;
  final List<AppliedException> exceptionsApplied;
  final String? focalId;
}

class GenealogyInheritanceValidator {
  const GenealogyInheritanceValidator();

  static const List<InheritancePolicy> _defaultPolicies = <InheritancePolicy>[
    InheritancePolicy(rule: InheritanceRuleKind.eldestChild, priority: 0),
  ];

  GenealogyValidationReport validate({
    required GenealogyGraph graph,
    Map<String, LifeSpan> lifespans = const <String, LifeSpan>{},
    String? focalId,
    int? atTick,
    Map<String, GenderAssignment> genders = const <String, GenderAssignment>{},
    List<InheritancePolicy> policies = _defaultPolicies,
    GenealogyValidationOptions options = const GenealogyValidationOptions(),
    List<ManualException> manualExceptions = const <ManualException>[],
  }) {
    _validateLifespans(lifespans);

    final anomalies = <GenealogyAnomaly>[];
    _collectCycles(graph, anomalies);
    _collectDateAnomalies(graph, lifespans, anomalies, options);

    final appliedExceptions = _applyExceptions(anomalies, manualExceptions);

    final candidates = <InheritanceCandidate>[];
    if (focalId != null && graph.nodes.containsKey(focalId)) {
      candidates.addAll(
        _rankCandidates(
          graph: graph,
          focalId: focalId,
          lifespans: lifespans,
          genders: genders,
          policies: policies,
        ),
      );
    }

    return GenealogyValidationReport(
      anomalies: anomalies,
      candidates: candidates,
      exceptionsApplied: appliedExceptions,
      focalId: focalId,
    );
  }

  void _validateLifespans(Map<String, LifeSpan> lifespans) {
    for (final entry in lifespans.entries) {
      final ls = entry.value;
      if (ls.birthTick < 0) {
        throw ArgumentError.value(
          ls.birthTick,
          "birthTick[${ls.id}]",
          "birthTick cannot be negative",
        );
      }
      if (ls.deathTick != null && ls.deathTick! < ls.birthTick) {
        throw ArgumentError(
          "deathTick (${ls.deathTick}) cannot be less than birthTick (${ls.birthTick}) for ${ls.id}",
        );
      }
    }
  }

  void _collectCycles(GenealogyGraph graph, List<GenealogyAnomaly> sink) {
    final adjacency = <String, List<String>>{};
    final edgeByPair = <String, String>{};
    final edgesByKind = _edgesOfKinds(graph, const {
      GenealogyRelationKind.parentChild,
      GenealogyRelationKind.adoption,
    });
    for (final e in edgesByKind) {
      final key = "${e.fromId}->${e.toId}";
      adjacency.putIfAbsent(e.fromId, () => <String>[]).add(e.toId);
      edgeByPair[key] = e.id;
    }

    final visited = <String>{};
    final onStack = <String>{};
    final cycles = <List<String>>{};

    void dfs(String node, List<String> path) {
      if (onStack.contains(node)) {
        final cycleStart = path.indexOf(node);
        if (cycleStart >= 0) {
          final cycle = path.sublist(cycleStart)..add(node);
          final normalized = _normalizeCycle(cycle);
          cycles.add(normalized);
        }
        return;
      }
      if (visited.contains(node)) return;
      visited.add(node);
      onStack.add(node);
      path.add(node);
      for (final next in adjacency[node] ?? const <String>[]) {
        dfs(next, path);
      }
      path.removeLast();
      onStack.remove(node);
    }

    for (final node in graph.nodes.keys) {
      dfs(node, <String>[]);
    }

    for (final cycle in cycles) {
      final edgeIds = <String>[];
      for (var i = 0; i < cycle.length - 1; i++) {
        final key = "${cycle[i]}->${cycle[i + 1]}";
        final id = edgeByPair[key];
        if (id != null) edgeIds.add(id);
      }
      sink.add(
        GenealogyAnomaly(
          code: GenealogyAnomalyCode.cycle,
          nodeIds: cycle.sublist(0, cycle.length - 1),
          edgeIds: edgeIds,
          message:
              "transitive cycle across parentChild + adoption: ${cycle.join(", ")}",
        ),
      );
    }
  }

  List<String> _normalizeCycle(List<String> cycle) {
    final core = cycle.sublist(0, cycle.length - 1);
    if (core.isEmpty) return core;
    var minIdx = 0;
    for (var i = 1; i < core.length; i++) {
      if (core[i].compareTo(core[minIdx]) < 0) minIdx = i;
    }
    final rotated = <String>[
      ...core.sublist(minIdx),
      ...core.sublist(0, minIdx),
    ];
    rotated.add(rotated.first);
    return rotated;
  }

  List<GenealogyRelation> _edgesOfKinds(
    GenealogyGraph graph,
    Set<GenealogyRelationKind> kinds,
  ) {
    final edges = <GenealogyRelation>[];
    for (final e in _allEdges(graph)) {
      if (kinds.contains(e.kind)) edges.add(e);
    }
    return edges;
  }

  Iterable<GenealogyRelation> _allEdges(GenealogyGraph graph) {
    return graph.edges;
  }

  void _collectDateAnomalies(
    GenealogyGraph graph,
    Map<String, LifeSpan> lifespans,
    List<GenealogyAnomaly> sink,
    GenealogyValidationOptions options,
  ) {
    final pcAndAdopt = _edgesOfKinds(graph, const {
      GenealogyRelationKind.parentChild,
      GenealogyRelationKind.adoption,
    });
    for (final e in pcAndAdopt) {
      final parent = lifespans[e.fromId];
      final child = lifespans[e.toId];
      if (parent == null || child == null) {
        if (options.strictMissingLifespan) {
          final missing = <String>[];
          if (parent == null && graph.nodes.containsKey(e.fromId)) {
            missing.add(e.fromId);
          }
          if (child == null && graph.nodes.containsKey(e.toId)) {
            missing.add(e.toId);
          }
          if (missing.isNotEmpty) {
            sink.add(
              GenealogyAnomaly(
                code: GenealogyAnomalyCode.unknownLifespan,
                nodeIds: missing,
                edgeIds: <String>[e.id],
                message: "lifespan missing for edge ${e.id}: $missing",
              ),
            );
          }
        }
        continue;
      }
      if (parent.birthTick > child.birthTick) {
        sink.add(
          GenealogyAnomaly(
            code: GenealogyAnomalyCode.parentYoungerThanChild,
            nodeIds: <String>[e.fromId, e.toId],
            edgeIds: <String>[e.id],
            message:
                "parent ${e.fromId} (birth ${parent.birthTick}) is younger than child ${e.toId} (birth ${child.birthTick})",
          ),
        );
      }
      if (parent.deathTick != null && parent.deathTick! < child.birthTick) {
        sink.add(
          GenealogyAnomaly(
            code: GenealogyAnomalyCode.childBornAfterParentDeath,
            nodeIds: <String>[e.fromId, e.toId],
            edgeIds: <String>[e.id],
            message:
                "child ${e.toId} born after parent ${e.fromId} died (${child.birthTick} > ${parent.deathTick})",
          ),
        );
      }
    }
  }

  List<AppliedException> _applyExceptions(
    List<GenealogyAnomaly> anomalies,
    List<ManualException> exceptions,
  ) {
    final applied = <AppliedException>[];
    if (exceptions.isEmpty) return applied;

    final validExceptions = <ManualException>[];
    for (final ex in exceptions) {
      validExceptions.add(
        ManualException.validated(
          kind: ex.kind,
          reason: ex.reason,
          edgeIds: ex.edgeIds,
          nodeIds: ex.nodeIds,
        ),
      );
      applied.add(
        AppliedException(
          kind: ex.kind,
          reason: ex.reason,
          edgeIds: List<String>.unmodifiable(ex.edgeIds),
        ),
      );
    }

    final removeIndexes = <int>{};
    for (final ex in validExceptions) {
      if (ex.kind != ManualExceptionKind.suppressCycle) continue;
      for (var i = 0; i < anomalies.length; i++) {
        final a = anomalies[i];
        if (a.code != GenealogyAnomalyCode.cycle) continue;
        if (a.edgeIds.isEmpty) continue;
        final overlap = a.edgeIds.toSet().intersection(ex.edgeIds.toSet());
        if (overlap.isNotEmpty && a.edgeIds.length <= ex.edgeIds.length) {
          removeIndexes.add(i);
        }
      }
    }
    if (removeIndexes.isNotEmpty) {
      final kept = <GenealogyAnomaly>[];
      for (var i = 0; i < anomalies.length; i++) {
        if (!removeIndexes.contains(i)) kept.add(anomalies[i]);
      }
      anomalies
        ..clear()
        ..addAll(kept);
    }
    return applied;
  }

  List<InheritanceCandidate> _rankCandidates({
    required GenealogyGraph graph,
    required String focalId,
    required Map<String, LifeSpan> lifespans,
    required Map<String, GenderAssignment> genders,
    required List<InheritancePolicy> policies,
  }) {
    final orderedPolicies = <InheritancePolicy>[...policies]
      ..sort((a, b) => a.priority.compareTo(b.priority));

    final biological = <String>[];
    final adopted = <String>[];
    for (final e in graph.edges) {
      if (e.fromId != focalId) continue;
      if (e.kind == GenealogyRelationKind.parentChild) {
        biological.add(e.toId);
      } else if (e.kind == GenealogyRelationKind.adoption) {
        adopted.add(e.toId);
      }
    }

    final childrenPool = biological.isNotEmpty ? biological : adopted;

    final candidates = <InheritanceCandidate>[];
    for (final policy in orderedPolicies) {
      final filtered = _filterByRule(
        childrenPool,
        adopted,
        genders,
        policy.rule,
      );
      final ordered = _orderByRule(filtered, lifespans, policy.rule);
      for (var i = 0; i < ordered.length; i++) {
        final id = ordered[i];
        candidates.add(
          InheritanceCandidate(
            nodeId: id,
            rank: candidates.length + 1,
            justification: _justify(policy.rule, id, lifespans),
            birthTick: lifespans[id]?.birthTick ?? 0,
            ruleKind: policy.rule,
          ),
        );
      }
    }
    return candidates;
  }

  List<String> _filterByRule(
    List<String> pool,
    List<String> adopted,
    Map<String, GenderAssignment> genders,
    InheritanceRuleKind rule,
  ) {
    switch (rule) {
      case InheritanceRuleKind.eldestMaleChild:
        return pool
            .where((id) => genders[id]?.gender == Gender.male)
            .toList(growable: false);
      case InheritanceRuleKind.eldestFemaleChild:
        return pool
            .where((id) => genders[id]?.gender == Gender.female)
            .toList(growable: false);
      case InheritanceRuleKind.eldestChild:
      case InheritanceRuleKind.lastWill:
        return List<String>.unmodifiable(pool);
      case InheritanceRuleKind.adoptedExcluded:
        return pool
            .where((id) => !adopted.contains(id))
            .toList(growable: false);
      case InheritanceRuleKind.partnershipGranted:
      case InheritanceRuleKind.custom:
        return List<String>.unmodifiable(pool);
    }
  }

  List<String> _orderByRule(
    List<String> ids,
    Map<String, LifeSpan> lifespans,
    InheritanceRuleKind rule,
  ) {
    final copy = <String>[...ids];
    copy.sort((a, b) {
      final la = lifespans[a]?.birthTick ?? 0;
      final lb = lifespans[b]?.birthTick ?? 0;
      return la.compareTo(lb);
    });
    return copy;
  }

  String _justify(
    InheritanceRuleKind rule,
    String id,
    Map<String, LifeSpan> lifespans,
  ) {
    final birth = lifespans[id]?.birthTick;
    final tag = switch (rule) {
      InheritanceRuleKind.eldestChild => "eldest_child",
      InheritanceRuleKind.eldestMaleChild => "eldest_male_child",
      InheritanceRuleKind.eldestFemaleChild => "eldest_female_child",
      InheritanceRuleKind.lastWill => "last_will",
      InheritanceRuleKind.adoptedExcluded => "adopted_excluded",
      InheritanceRuleKind.partnershipGranted => "partnership_granted",
      InheritanceRuleKind.custom => "custom",
    };
    return birth == null ? tag : "$tag@$birth";
  }
}
