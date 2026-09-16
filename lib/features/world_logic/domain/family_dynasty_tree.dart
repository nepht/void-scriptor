// Sprint 110.18 - Interactive Family & Dynasty Tree.
//
// Domain-only contract for laying out a parent/child genealogy graph,
// focusing on a single person, collapsing/expanding subtrees, and
// keyboard navigation between nodes. Adds a large-tree fallback so the
// UI can pivot to a summary view when the tree grows past a threshold.
// Pure Dart, deterministic, no persistence/UI/locale/network/wall clock/random.

import 'package:void_scriptor/features/world_logic/domain/genealogy_relationships.dart';

enum TreeNavDirection { up, down, left, right }

class FamilyTreeNode {
  const FamilyTreeNode({
    required this.nodeId,
    required this.generation,
    required this.positionInGeneration,
    required this.parentIds,
    required this.childIds,
  });
  final String nodeId;
  final int generation;
  final int positionInGeneration;
  final List<String> parentIds;
  final List<String> childIds;
}

class FamilyTreeEdge {
  const FamilyTreeEdge({
    required this.fromId,
    required this.toId,
    required this.kind,
    this.validFrom = 0,
    this.validUntil,
  });
  final String fromId;
  final String toId;
  final GenealogyRelationKind kind;
  final int validFrom;
  final int? validUntil;
}

class FamilyTreeLayout {
  const FamilyTreeLayout({
    required this.graph,
    required this.nodes,
    required this.edges,
    this.atTick,
  });
  final GenealogyGraph graph;
  final List<FamilyTreeNode> nodes;
  final List<FamilyTreeEdge> edges;
  final int? atTick;

  List<FamilyTreeNode> nodesAtGeneration(int g) =>
      nodes.where((n) => n.generation == g).toList(growable: false);
}

class FamilyTreeFocus {
  const FamilyTreeFocus({
    required this.personId,
    required this.ancestorIds,
    required this.descendantIds,
  });
  final String personId;
  final List<String> ancestorIds;
  final List<String> descendantIds;
}

class CollapsedTreeState {
  CollapsedTreeState._({
    required this.allNodeIds,
    required this.collapsedRootIds,
    required this.hiddenNodeIds,
    required this.childMap,
  });

  factory CollapsedTreeState({
    required List<String> allNodeIds,
    required List<String> collapsedRootIds,
    required Set<String> hiddenNodeIds,
    Map<String, List<String>> childMap = const {},
  }) {
    return CollapsedTreeState._(
      allNodeIds: List.unmodifiable(allNodeIds),
      collapsedRootIds: List.unmodifiable(collapsedRootIds),
      hiddenNodeIds: List.unmodifiable(hiddenNodeIds),
      childMap: childMap,
    );
  }

  final List<String> allNodeIds;
  final List<String> collapsedRootIds;
  final List<String> hiddenNodeIds;
  final Map<String, List<String>> childMap;

  List<String> get visibleNodeIds {
    final hidden = hiddenNodeIds.toSet();
    return allNodeIds
        .where((id) => !hidden.contains(id))
        .toList(growable: false);
  }

  CollapsedTreeState withCollapsed(String rootId) {
    if (!allNodeIds.contains(rootId)) {
      throw ArgumentError.value(rootId, 'rootId', 'unknown node');
    }
    final newCollapsed = List<String>.from(collapsedRootIds);
    if (!newCollapsed.contains(rootId)) newCollapsed.add(rootId);
    final newHidden = <String>{
      ...hiddenNodeIds,
      ..._descendantClosure([rootId], childMap),
    };
    return CollapsedTreeState(
      allNodeIds: allNodeIds,
      collapsedRootIds: newCollapsed,
      hiddenNodeIds: newHidden,
      childMap: childMap,
    );
  }

  CollapsedTreeState withExpanded(String rootId) {
    // Expand membuka seluruh subtree rootId, jadi akar collapse di DALAM
    // subtree itu tidak lagi berlaku collapsed (invarian: akar collapsed =>
    // turunannya hidden; setelah expand, turunannya visible).
    final subtree = _descendantClosure([rootId], childMap).toSet();
    final newCollapsed = collapsedRootIds
        .where((id) => id != rootId && !subtree.contains(id))
        .toList();
    final hidden = <String>{...hiddenNodeIds}..remove(rootId);
    for (final d in _descendantClosure([rootId], childMap)) {
      hidden.remove(d);
    }
    return CollapsedTreeState(
      allNodeIds: allNodeIds,
      collapsedRootIds: newCollapsed,
      hiddenNodeIds: hidden,
      childMap: childMap,
    );
  }
}

CollapsedTreeState collapseBranch({
  required GenealogyGraph graph,
  required String rootId,
}) {
  if (!graph.nodes.containsKey(rootId)) {
    throw ArgumentError.value(rootId, 'rootId', 'unknown node');
  }
  final childMap = _buildChildMap(graph, null);
  final state = CollapsedTreeState(
    allNodeIds: graph.nodes.keys.toList(growable: false),
    collapsedRootIds: const [],
    hiddenNodeIds: const <String>{},
    childMap: childMap,
  );
  return state.withCollapsed(rootId);
}

CollapsedTreeState expandBranch({
  required CollapsedTreeState collapsed,
  required String rootId,
}) {
  return collapsed.withExpanded(rootId);
}

// Variant that re-adds descendants under `rootId` using the supplied child
// map. Use this when you have the graph at hand and want the exact
// restoration behavior tested by family_dynasty_tree_test.dart.
Set<String> _descendantClosure(
  List<String> roots,
  Map<String, List<String>> childMap,
) {
  final out = <String>{};
  final stack = List<String>.from(roots);
  while (stack.isNotEmpty) {
    final cur = stack.removeLast();
    for (final c in childMap[cur] ?? const <String>[]) {
      if (out.add(c)) stack.add(c);
    }
  }
  return out;
}

Map<String, List<String>> _buildChildMap(GenealogyGraph graph, int? atTick) {
  final map = <String, List<String>>{};
  for (final n in graph.nodes.keys) {
    map[n] = graph.childrenOf(n, atTick: atTick);
  }
  return Map.unmodifiable(map);
}

class BuildSummary {
  const BuildSummary({
    required this.totalNodes,
    required this.totalEdges,
    required this.generationCount,
  });
  final int totalNodes;
  final int totalEdges;
  final int generationCount;
}

class BuildTreeResult {
  const BuildTreeResult({
    required this.layout,
    required this.summary,
    required this.usedFallback,
    required this.fallbackReason,
  });
  final FamilyTreeLayout? layout;
  final BuildSummary summary;
  final bool usedFallback;
  final String fallbackReason;
}

FamilyTreeFocus focusOnPerson({
  required GenealogyGraph graph,
  required String personId,
}) {
  if (!graph.nodes.containsKey(personId)) {
    throw ArgumentError.value(personId, 'personId', 'unknown node');
  }
  final ancestors = <String>{};
  final stack = <String>[personId];
  while (stack.isNotEmpty) {
    final cur = stack.removeLast();
    for (final p in graph.parentsOf(cur)) {
      if (ancestors.add(p)) stack.add(p);
    }
  }
  final descendants = <String>{};
  final dstack = <String>[personId];
  while (dstack.isNotEmpty) {
    final cur = dstack.removeLast();
    for (final c in graph.childrenOf(cur)) {
      if (descendants.add(c)) dstack.add(c);
    }
  }
  return FamilyTreeFocus(
    personId: personId,
    ancestorIds: ancestors.toList(growable: false)..sort(),
    descendantIds: descendants.toList(growable: false)..sort(),
  );
}

String? navigateKey({
  required GenealogyGraph graph,
  required String personId,
  required TreeNavDirection direction,
}) {
  if (!graph.nodes.containsKey(personId)) {
    throw ArgumentError.value(personId, 'personId', 'unknown node');
  }
  switch (direction) {
    case TreeNavDirection.up:
      final parents = graph.parentsOf(personId);
      if (parents.isEmpty) return null;
      parents.sort();
      return parents.first;
    case TreeNavDirection.down:
      final children = graph.childrenOf(personId);
      if (children.isEmpty) return null;
      children.sort();
      return children.first;
    case TreeNavDirection.left:
    case TreeNavDirection.right:
      // Walk among nodes at the same generation (deterministic sorted order).
      final sameGen =
          graph.nodes.keys
              .where(
                (id) =>
                    _generationOf(graph, id) == _generationOf(graph, personId),
              )
              .toList()
            ..sort();
      if (sameGen.length < 2) return null;
      final idx = sameGen.indexOf(personId);
      if (idx == -1) return null;
      if (direction == TreeNavDirection.left) {
        if (idx == 0) return null;
        return sameGen[idx - 1];
      } else {
        if (idx == sameGen.length - 1) return null;
        return sameGen[idx + 1];
      }
  }
}

int _generationOf(GenealogyGraph graph, String nodeId) {
  // Use the layout pass to compute generation; recompute via simple walk.
  // Generation = longest path from any root (node with no parents).
  final memo = <String, int>{};
  int gen(String id) {
    if (memo.containsKey(id)) return memo[id]!;
    final parents = graph.parentsOf(id);
    if (parents.isEmpty) {
      memo[id] = 0;
      return 0;
    }
    final parentGens = parents.map(gen).toList();
    final maxParent = parentGens.fold<int>(0, (a, b) => a > b ? a : b);
    final g = maxParent + 1;
    memo[id] = g;
    return g;
  }

  return gen(nodeId);
}

List<FamilyTreeEdge> _activeEdgesOf(GenealogyGraph graph, int? atTick) {
  // GenealogyGraph does not expose its raw edge list publicly, so we
  // approximate the active parent-child edges by querying parentsOf per
  // node at the requested tick. Adoption edges are treated as parent
  // edges in the tree (same ancestor role) so they collapse into the same
  // parent-child edge family for layout purposes.
  final result = <FamilyTreeEdge>[];
  for (final n in graph.nodes.keys) {
    final parents = graph.parentsOf(n, atTick: atTick);
    for (final p in parents) {
      result.add(
        FamilyTreeEdge(
          fromId: p,
          toId: n,
          kind: GenealogyRelationKind.parentChild,
        ),
      );
    }
  }
  return result;
}

FamilyTreeLayout computeTreeLayout({
  required GenealogyGraph graph,
  int? atTick,
}) {
  if (graph.nodes.isEmpty) {
    throw ArgumentError('cannot layout an empty genealogy graph');
  }
  final childMap = _buildChildMap(graph, atTick);
  final activeEdges = _activeEdgesOf(graph, atTick);
  final parentsOf = <String, Set<String>>{};
  for (final n in graph.nodes.keys) {
    parentsOf[n] = <String>{};
  }
  for (final e in activeEdges) {
    if (e.kind != GenealogyRelationKind.parentChild) continue;
    if (!parentsOf.containsKey(e.toId)) continue;
    parentsOf[e.toId]!.add(e.fromId);
  }
  final generation = <String, int>{};
  for (final n in graph.nodes.keys) {
    generation[n] = 0;
  }
  final queue = <String>[];
  for (final n in graph.nodes.keys) {
    if (parentsOf[n]!.isEmpty) {
      queue.add(n);
      generation[n] = 0;
    }
  }
  var head = 0;
  while (head < queue.length) {
    final cur = queue[head++];
    for (final c in childMap[cur] ?? const <String>[]) {
      if (parentsOf[c]!.isEmpty) continue;
      final proposed = generation[cur]! + 1;
      if (proposed > (generation[c] ?? 0)) generation[c] = proposed;
      if (!queue.contains(c)) queue.add(c);
    }
  }
  final byGen = <int, List<String>>{};
  for (final entry in generation.entries) {
    byGen.putIfAbsent(entry.value, () => <String>[]).add(entry.key);
  }
  final out = <FamilyTreeNode>[];
  for (final g in byGen.keys.toList()..sort()) {
    final list = byGen[g]!..sort();
    for (var i = 0; i < list.length; i++) {
      final id = list[i];
      final parents = parentsOf[id]!.toList()..sort();
      final children = (childMap[id] ?? const <String>[])..sort();
      out.add(
        FamilyTreeNode(
          nodeId: id,
          generation: g,
          positionInGeneration: i,
          parentIds: parents,
          childIds: children,
        ),
      );
    }
  }
  return FamilyTreeLayout(
    graph: graph,
    nodes: List.unmodifiable(out),
    edges: List.unmodifiable(activeEdges),
    atTick: atTick,
  );
}

BuildTreeResult buildTreeLayout({
  required GenealogyGraph graph,
  int threshold = 250,
}) {
  final summary = BuildSummary(
    totalNodes: graph.nodes.length,
    totalEdges: _activeEdgesOf(graph, null).length,
    generationCount: 0,
  );
  if (graph.nodes.length > threshold) {
    return BuildTreeResult(
      layout: null,
      summary: summary,
      usedFallback: true,
      fallbackReason:
          'node count ${graph.nodes.length} exceeds threshold $threshold',
    );
  }
  if (graph.nodes.isEmpty) {
    return BuildTreeResult(
      layout: null,
      summary: summary,
      usedFallback: false,
      fallbackReason: '',
    );
  }
  final layout = computeTreeLayout(graph: graph);
  final genCount =
      layout.nodes
          .map((n) => n.generation)
          .fold<int>(0, (a, b) => a > b ? a : b) +
      1;
  return BuildTreeResult(
    layout: layout,
    summary: BuildSummary(
      totalNodes: summary.totalNodes,
      totalEdges: summary.totalEdges,
      generationCount: genCount,
    ),
    usedFallback: false,
    fallbackReason: '',
  );
}
