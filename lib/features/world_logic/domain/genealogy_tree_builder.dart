// Sprint 110.18 - Genealogy Tree Builder (Family/Dynasty View).
//
// Domain-only tree builder atop GenealogyRegistry (110.17). Mengubah
// daftar relasi menjadi struktur siap-query: roots, generations, ancestors,
// descendants, dan dynasty clusters. Semua kalkulasi time-aware (asOfTick)
// dan deterministic; tidak ada persistence/UI/wall clock/locale/random.
import "genealogy_relationship_rules.dart";

class GenealogyInheritanceIssueKind {
  const GenealogyInheritanceIssueKind._(this.name);
  final String name;
  static const cycle = GenealogyInheritanceIssueKind._("cycle");
  static const clanParentConflict = GenealogyInheritanceIssueKind._(
    "clanParentConflict",
  );

  @override
  String toString() => "GenealogyInheritanceIssueKind()";
}

class GenealogyInheritanceIssue {
  const GenealogyInheritanceIssue({
    required this.kind,
    required this.nodeIds,
    required this.reason,
  }) : assert(nodeIds.length > 0, "nodeIds tidak boleh kosong"),
       assert(reason.length > 0, "reason tidak boleh kosong");

  final GenealogyInheritanceIssueKind kind;
  final List<String> nodeIds;
  final String reason;

  @override
  String toString() => "GenealogyInheritanceIssue(, nodes=, reason=)";
}

class DynastyCluster {
  const DynastyCluster({required this.id, required this.members});
  final String id;
  final List<String> members;
}

class GenealogyTree {
  const GenealogyTree({
    required this.nodeIds,
    required this.roots,
    required this.generation,
    required this.parentChildren,
    required this.adoptions,
    required this.partnerships,
    required this.clans,
    required this.asOfTick,
  });

  final List<String> nodeIds;
  final List<String> roots;
  final Map<String, int> generation;
  final List<GenealogyRelation> parentChildren;
  final List<GenealogyRelation> adoptions;
  final List<GenealogyRelation> partnerships;
  final List<GenealogyRelation> clans;
  final int asOfTick;

  int generationOf(String nodeId) {
    final depth = generation[nodeId];
    if (depth == null) {
      throw StateError("node  tidak ada di tree");
    }
    return depth;
  }

  /// Ancestor (parent_child + adoption) diurutkan dari immediate ke atas.
  List<String> ancestorsOf(String nodeId) {
    final ancestors = <String>[];
    final visited = <String>{nodeId};
    var frontier = <String>[nodeId];
    while (frontier.isNotEmpty) {
      final next = <String>[];
      for (final id in frontier) {
        for (final r in parentChildren) {
          if (r.toId == id && r.isActiveAt(asOfTick) && visited.add(r.fromId)) {
            ancestors.add(r.fromId);
            next.add(r.fromId);
          }
        }
        for (final r in adoptions) {
          if (r.toId == id && r.isActiveAt(asOfTick) && visited.add(r.fromId)) {
            ancestors.add(r.fromId);
            next.add(r.fromId);
          }
        }
      }
      frontier = next;
    }
    return ancestors;
  }

  /// Ancestor + jenis relasi (parent_child vs adoption).
  Map<String, GenealogyRelationType> ancestorsWithKind(String nodeId) {
    final result = <String, GenealogyRelationType>{};
    final visited = <String>{nodeId};
    var frontier = <String>[nodeId];
    while (frontier.isNotEmpty) {
      final next = <String>[];
      for (final id in frontier) {
        for (final r in parentChildren) {
          if (r.toId == id && r.isActiveAt(asOfTick) && visited.add(r.fromId)) {
            result[r.fromId] = GenealogyRelationType.parentChild;
            next.add(r.fromId);
          }
        }
        for (final r in adoptions) {
          if (r.toId == id && r.isActiveAt(asOfTick) && visited.add(r.fromId)) {
            result[r.fromId] = GenealogyRelationType.adoption;
            next.add(r.fromId);
          }
        }
      }
      frontier = next;
    }
    return result;
  }

  /// Descendant (parent_child + adoption) dalam urutan BFS.
  List<String> descendantsOf(String nodeId) {
    final result = <String>[];
    final visited = <String>{nodeId};
    var frontier = <String>[nodeId];
    while (frontier.isNotEmpty) {
      final next = <String>[];
      for (final id in frontier) {
        for (final r in parentChildren) {
          if (r.fromId == id && r.isActiveAt(asOfTick) && visited.add(r.toId)) {
            result.add(r.toId);
            next.add(r.toId);
          }
        }
        for (final r in adoptions) {
          if (r.fromId == id && r.isActiveAt(asOfTick) && visited.add(r.toId)) {
            result.add(r.toId);
            next.add(r.toId);
          }
        }
      }
      frontier = next;
    }
    return result;
  }

  /// Klaster dynasty: union-find atas node yang terhubung oleh
  /// parent_child, adoption, atau partnership.
  List<DynastyCluster> dynastyClusters() {
    final parent = <String, String>{for (final id in nodeIds) id: id};
    String find(String x) {
      var p = parent[x]!;
      while (p != parent[p]) {
        parent[p] = parent[parent[p]]!;
        p = parent[p]!;
      }
      return p;
    }

    void union(String a, String b) {
      final ra = find(a);
      final rb = find(b);
      if (ra != rb) parent[ra] = rb;
    }

    for (final r in parentChildren) {
      if (r.isActiveAt(asOfTick)) union(r.fromId, r.toId);
    }
    for (final r in adoptions) {
      if (r.isActiveAt(asOfTick)) union(r.fromId, r.toId);
    }
    for (final r in partnerships) {
      if (r.isActiveAt(asOfTick)) union(r.fromId, r.toId);
    }

    final groups = <String, List<String>>{};
    for (final id in nodeIds) {
      final root = find(id);
      groups.putIfAbsent(root, () => <String>[]).add(id);
    }
    final result = <DynastyCluster>[];
    var idx = 0;
    for (final members in groups.values) {
      idx++;
      result.add(
        DynastyCluster(id: "cluster_$idx", members: List.unmodifiable(members)),
      );
    }
    return result;
  }

  /// Validasi inheritance: cycle parent_child (implisit via DFS) dan
  /// kepala-klan-yang-juga-parent konflik.
  List<GenealogyInheritanceIssue> validateInheritance() {
    final issues = <GenealogyInheritanceIssue>[];

    final activePc = parentChildren
        .where((r) => r.isActiveAt(asOfTick))
        .toList(growable: false);
    final adjacency = <String, List<String>>{};
    for (final r in activePc) {
      adjacency.putIfAbsent(r.fromId, () => <String>[]).add(r.toId);
    }
    final color = <String, int>{};
    for (final id in nodeIds) {
      color.putIfAbsent(id, () => 0);
    }
    final cycleStack = <String>[];

    bool dfs(String u) {
      color[u] = 1;
      cycleStack.add(u);
      for (final v in adjacency[u] ?? const <String>[]) {
        final c = color[v] ?? 0;
        if (c == 1) {
          final idx = cycleStack.indexOf(v);
          final nodes = cycleStack.sublist(idx);
          issues.add(
            GenealogyInheritanceIssue(
              kind: GenealogyInheritanceIssueKind.cycle,
              nodeIds: List<String>.unmodifiable(nodes),
              reason: "parent_child cycle terdeteksi: ${nodes.join(" -> ")}",
            ),
          );
          return true;
        } else if (c == 0) {
          if (dfs(v)) return true;
        }
      }
      color[u] = 2;
      cycleStack.removeLast();
      return false;
    }

    for (final id in nodeIds) {
      if ((color[id] ?? 0) == 0) {
        if (dfs(id)) break;
      }
    }

    // 2) Clan-parent conflict: parent_child di mana parent dan child berada
    // di clanNode yang sama.
    if (clans.isNotEmpty) {
      final clanOf = <String, List<String>>{};
      for (final r in clans) {
        if (r.isActiveAt(asOfTick)) {
          clanOf.putIfAbsent(r.fromId, () => <String>[]).add(r.toId);
        }
      }
      for (final r in activePc) {
        final childClans = clanOf.entries
            .where((e) => e.value.contains(r.toId))
            .map((e) => e.key)
            .toList();
        final parentClans = clanOf.entries
            .where((e) => e.value.contains(r.fromId))
            .map((e) => e.key)
            .toList();
        for (final clan in childClans) {
          if (parentClans.contains(clan)) {
            issues.add(
              GenealogyInheritanceIssue(
                kind: GenealogyInheritanceIssueKind.clanParentConflict,
                nodeIds: <String>[r.fromId, r.toId],
                reason:
                    "parent ${r.fromId} dan child ${r.toId} sama-sama anggota klan $clan",
              ),
            );
          }
        }
      }
    }

    return issues;
  }
}

class GenealogyTreeBuilder {
  const GenealogyTreeBuilder._();

  /// Bangun tree dari registry + daftar nodeIds + asOfTick.
  /// Filter relasi yang aktif pada asOfTick untuk semua kalkulasi.
  static GenealogyTree build(
    GenealogyRegistry registry, {
    required List<String> nodeIds,
    required int asOfTick,
    List<String> clanNodes = const <String>[],
  }) {
    final all = registry.relations;
    final nodeSet = nodeIds.toSet();
    final parentChildren = <GenealogyRelation>[];
    final adoptions = <GenealogyRelation>[];
    final partnerships = <GenealogyRelation>[];
    final clans = <GenealogyRelation>[];
    for (final r in all) {
      if (!r.isActiveAt(asOfTick)) continue;
      // clan relations reference clanId as fromId, not a node. The toId is
      // the member. We accept clan relations whose member is in nodeIds, and
      // whose clanId (fromId) is either in nodeIds or accepted via clanNodes.
      if (r.type == GenealogyRelationType.clan) {
        if (!nodeSet.contains(r.toId)) continue;
      } else {
        if (!nodeSet.contains(r.fromId) || !nodeSet.contains(r.toId)) continue;
      }
      switch (r.type) {
        case GenealogyRelationType.parentChild:
          parentChildren.add(r);
          break;
        case GenealogyRelationType.adoption:
          adoptions.add(r);
          break;
        case GenealogyRelationType.partnership:
          partnerships.add(r);
          break;
        case GenealogyRelationType.clan:
          if (clanNodes.isEmpty || clanNodes.contains(r.fromId)) {
            clans.add(r);
          }
          break;
        case GenealogyRelationType.guardian:
          // Guardian tidak membentuk garis keturunan; diabaikan untuk view.
          break;
      }
    }

    final hasParent = <String>{};
    for (final r in parentChildren) {
      hasParent.add(r.toId);
    }
    final roots = nodeIds
        .where((id) => !hasParent.contains(id))
        .toList(growable: false);

    final generation = <String, int>{};
    for (final id in nodeIds) {
      generation[id] = -1;
    }
    final queue = <String>[];
    for (final r in roots) {
      generation[r] = 0;
      queue.add(r);
    }
    var head = 0;
    while (head < queue.length) {
      final u = queue[head++];
      final depth = generation[u]!;
      for (final r in parentChildren) {
        if (r.fromId == u) {
          final child = r.toId;
          if ((generation[child] ?? -1) == -1) {
            generation[child] = depth + 1;
            queue.add(child);
          }
        }
      }
      for (final r in adoptions) {
        if (r.fromId == u) {
          final child = r.toId;
          if ((generation[child] ?? -1) == -1) {
            generation[child] = depth + 1;
            queue.add(child);
          }
        }
      }
    }
    for (final id in nodeIds) {
      if ((generation[id] ?? -1) == -1) {
        generation[id] = 0;
      }
    }

    return GenealogyTree(
      nodeIds: List<String>.unmodifiable(nodeIds),
      roots: List<String>.unmodifiable(roots),
      generation: Map<String, int>.unmodifiable(generation),
      parentChildren: List<GenealogyRelation>.unmodifiable(parentChildren),
      adoptions: List<GenealogyRelation>.unmodifiable(adoptions),
      partnerships: List<GenealogyRelation>.unmodifiable(partnerships),
      clans: List<GenealogyRelation>.unmodifiable(clans),
      asOfTick: asOfTick,
    );
  }

  /// Versi bypass-registry untuk test yang membutuhkan relasi tanpa
  /// melewati validasi 110.17 (mis. deteksi cycle implisit).
  static GenealogyTree fromRelations(
    List<GenealogyRelation> relations, {
    required List<String> nodeIds,
    required int asOfTick,
  }) {
    final parentChildren = <GenealogyRelation>[];
    final adoptions = <GenealogyRelation>[];
    final partnerships = <GenealogyRelation>[];
    final clans = <GenealogyRelation>[];
    for (final r in relations) {
      if (!r.isActiveAt(asOfTick)) continue;
      switch (r.type) {
        case GenealogyRelationType.parentChild:
          parentChildren.add(r);
          break;
        case GenealogyRelationType.adoption:
          adoptions.add(r);
          break;
        case GenealogyRelationType.partnership:
          partnerships.add(r);
          break;
        case GenealogyRelationType.clan:
          clans.add(r);
          break;
        case GenealogyRelationType.guardian:
          break;
      }
    }

    final hasParent = <String>{};
    for (final r in parentChildren) {
      hasParent.add(r.toId);
    }
    final roots = nodeIds
        .where((id) => !hasParent.contains(id))
        .toList(growable: false);

    final generation = <String, int>{};
    final queue = <String>[];
    for (final r in roots) {
      generation[r] = 0;
      queue.add(r);
    }
    var head = 0;
    while (head < queue.length) {
      final u = queue[head++];
      final depth = generation[u]!;
      for (final r in parentChildren) {
        if (r.fromId == u) {
          final child = r.toId;
          if ((generation[child] ?? -1) == -1) {
            generation[child] = depth + 1;
            queue.add(child);
          }
        }
      }
      for (final r in adoptions) {
        if (r.fromId == u) {
          final child = r.toId;
          if ((generation[child] ?? -1) == -1) {
            generation[child] = depth + 1;
            queue.add(child);
          }
        }
      }
    }
    for (final id in nodeIds) {
      if ((generation[id] ?? -1) == -1) {
        generation[id] = 0;
      }
    }

    return GenealogyTree(
      nodeIds: List<String>.unmodifiable(nodeIds),
      roots: List<String>.unmodifiable(roots),
      generation: Map<String, int>.unmodifiable(generation),
      parentChildren: List<GenealogyRelation>.unmodifiable(parentChildren),
      adoptions: List<GenealogyRelation>.unmodifiable(adoptions),
      partnerships: List<GenealogyRelation>.unmodifiable(partnerships),
      clans: List<GenealogyRelation>.unmodifiable(clans),
      asOfTick: asOfTick,
    );
  }
}
