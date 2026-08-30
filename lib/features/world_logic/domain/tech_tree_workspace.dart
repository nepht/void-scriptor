// Sprint 110.40 - Civilization Tech Tree Workspace (domain).
//
// Composes a TechnologyRegistry + TechnologyDiscoveryTimeline into a
// layout with culture / branch / time filters, focus tracking, and
// keyboard navigation surfaces. Domain-only, deterministic, no
// persistence / UI / wall clock / locale / random / network.

import "package:flutter/foundation.dart";

import "technology_node_prerequisite_model.dart";

enum TechTreeKey { advanceTier, retreatTier, jumpStart, jumpEnd }

enum TechTreeNavDirection { up, down, left, right }

class TechTreeLayoutNode {
  const TechTreeLayoutNode({
    required this.nodeId,
    required this.name,
    required this.generation,
    required this.positionInGeneration,
    required this.parentIds,
    required this.childIds,
    required this.tier,
    required this.culture,
    required this.branch,
  });
  final String nodeId;
  final String name;
  final int generation;
  final int positionInGeneration;
  final List<String> parentIds;
  final List<String> childIds;
  final int tier;
  final String? culture;
  final String branch;
}

class TechTreeLayout {
  const TechTreeLayout({required this.nodes, required this.visibleNodeIds});
  final List<TechTreeLayoutNode> nodes;
  final List<String> visibleNodeIds;

  TechTreeLayoutNode? nodeById(String id) {
    for (final n in nodes) {
      if (n.nodeId == id) return n;
    }
    return null;
  }
}

class TechTreeController extends ChangeNotifier {
  TechTreeController._({
    required TechnologyRegistry registry,
    required TechnologyDiscoveryTimeline timeline,
    // ignore: prefer_initializing_formals
  }) : _registry = registry,
       _discoveryByTech = _indexTimeline(timeline),
       _branchFilter = _defaultBranchOf(registry);

  factory TechTreeController.forRegistry({
    required TechnologyRegistry registry,
    required TechnologyDiscoveryTimeline timeline,
  }) {
    return TechTreeController._(registry: registry, timeline: timeline);
  }

  final TechnologyRegistry _registry;
  final Map<String, TechnologyDiscoveryEvent> _discoveryByTech;

  String? _cultureFilter;
  int? _atTickFilter;
  String? _branchFilter;
  String? _focusedNodeId;

  static Map<String, TechnologyDiscoveryEvent> _indexTimeline(
    TechnologyDiscoveryTimeline timeline,
  ) {
    final out = <String, TechnologyDiscoveryEvent>{};
    for (final e in timeline.events) {
      out[e.technologyId] = e;
    }
    return out;
  }

  String? get focusedNodeId => _focusedNodeId;
  String? get cultureFilter => _cultureFilter;
  int? get atTickFilter => _atTickFilter;
  String? get branchFilter => _branchFilter;

  /// All cultures present across the full registry (regardless of branch).
  List<String> get allCultures {
    final out = <String>{};
    for (final n in _registry.nodes) {
      if (n.culture != null) out.add(n.culture!);
    }
    final sorted = out.toList()..sort();
    return List<String>.unmodifiable(sorted);
  }

  /// All branches present across the full registry.
  List<String> get allBranches {
    final out = <String>{};
    for (final n in _registry.nodes) {
      out.add(n.branch);
    }
    final sorted = out.toList()..sort();
    return List<String>.unmodifiable(sorted);
  }

  void setCulture(String culture) {
    if (culture.isEmpty) {
      throw ArgumentError.value(culture, "culture", "must not be empty");
    }
    if (_cultureFilter == culture) return;
    _cultureFilter = culture;
    _focusedNodeId = null;
    notifyListeners();
  }

  void clearCulture() {
    if (_cultureFilter == null) return;
    _cultureFilter = null;
    _focusedNodeId = null;
    notifyListeners();
  }

  void setAtTick(int tick) {
    if (tick < 0) {
      throw ArgumentError.value(tick, "tick", "must be >= 0");
    }
    if (_atTickFilter == tick) return;
    _atTickFilter = tick;
    _focusedNodeId = null;
    notifyListeners();
  }

  void clearAtTick() {
    if (_atTickFilter == null) return;
    _atTickFilter = null;
    _focusedNodeId = null;
    notifyListeners();
  }

  void setBranch(String branch) {
    if (branch.isEmpty) {
      throw ArgumentError.value(branch, "branch", "must not be empty");
    }
    if (_branchFilter == branch) return;
    _branchFilter = branch;
    _focusedNodeId = null;
    notifyListeners();
  }

  void clearBranch() {
    // Restore the default branch (prime) instead of dropping the filter
    // entirely, so users have a deterministic "go back to prime" action.
    final def = _defaultBranchOf(_registry);
    if (_branchFilter == def) return;
    _branchFilter = def;
    _focusedNodeId = null;
    notifyListeners();
  }

  static String? _defaultBranchOf(TechnologyRegistry registry) {
    for (final n in registry.nodes) {
      if (n.branch == "prime") return "prime";
    }
    return null;
  }

  void focusNode(String nodeId) {
    if (_registry.nodeById(nodeId) == null) {
      throw ArgumentError.value(nodeId, "nodeId", "unknown technology");
    }
    if (_focusedNodeId == nodeId) return;
    _focusedNodeId = nodeId;
    notifyListeners();
  }

  void clearFocus() {
    if (_focusedNodeId == null) return;
    _focusedNodeId = null;
    notifyListeners();
  }

  List<String> get _allVisibleNodeIds {
    final culture = _cultureFilter;
    final tick = _atTickFilter;
    final out = <String>[];
    for (final node in _registry.nodes) {
      // When culture filter is active, it overrides branch filter so users
      // can browse a single culture across all branches.
      if (culture != null) {
        if (node.culture != culture) continue;
      } else {
        final branch = _branchFilter;
        if (branch != null && node.branch != branch) continue;
      }
      if (tick != null) {
        final ev = _discoveryByTech[node.id];
        if (ev == null || ev.tick > tick) continue;
      }
      out.add(node.id);
    }
    return out;
  }

  List<String> get _allDiscoveredNodeIds {
    final out = <String>[];
    for (final node in _registry.nodes) {
      if (_discoveryByTech.containsKey(node.id)) out.add(node.id);
    }
    return out;
  }

  TechTreeLayout get layout {
    final visibleIds = _allVisibleNodeIds;
    final byId = <String, TechnologyNode>{
      for (final n in _registry.nodes) n.id: n,
    };
    final out = <TechTreeLayoutNode>[];
    final visibleSet = visibleIds.toSet();
    final tierSorted = [...visibleIds]
      ..sort((idA, idB) {
        final ta = byId[idA]?.tier ?? 0;
        final tb = byId[idB]?.tier ?? 0;
        if (ta != tb) return ta.compareTo(tb);
        final nodeA = byId[idA];
        final nodeB = byId[idB];
        if (nodeA != null && nodeB != null) {
          if (nodeA.prerequisites.contains(idB)) return -1;
          if (nodeB.prerequisites.contains(idA)) return 1;
        }
        return idA.compareTo(idB);
      });
    final posInGen = <int, int>{};
    for (final id in tierSorted) {
      final n = byId[id]!;
      final pos = posInGen.update(n.tier, (v) => v + 1, ifAbsent: () => 0);
      final parents = <String>[
        for (final pid in n.prerequisites)
          if (visibleSet.contains(pid)) pid,
      ];
      final childIds = <String>[];
      for (final other in _registry.nodes) {
        if (other.id == n.id) continue;
        if (!visibleSet.contains(other.id)) continue;
        if (other.prerequisites.contains(n.id)) childIds.add(other.id);
      }
      out.add(
        TechTreeLayoutNode(
          nodeId: n.id,
          name: n.name,
          generation: n.tier,
          positionInGeneration: pos,
          parentIds: List<String>.unmodifiable(parents),
          childIds: List<String>.unmodifiable(childIds),
          tier: n.tier,
          culture: n.culture,
          branch: n.branch,
        ),
      );
    }
    return TechTreeLayout(
      nodes: List<TechTreeLayoutNode>.unmodifiable(out),
      visibleNodeIds: List<String>.unmodifiable(visibleIds),
    );
  }

  void applyKey(TechTreeKey key) {
    switch (key) {
      case TechTreeKey.advanceTier:
        _advanceTier();
        break;
      case TechTreeKey.retreatTier:
        _retreatTier();
        break;
      case TechTreeKey.jumpStart:
        _jumpToExtremes(start: true);
        break;
      case TechTreeKey.jumpEnd:
        _jumpToExtremes(start: false);
        break;
    }
  }

  void _advanceTier() {
    final visibleIds = layout.visibleNodeIds.toSet();
    if (visibleIds.isEmpty) return;
    final focused = _focusedNodeId;
    if (focused == null) {
      final sorted = [...visibleIds]..sort();
      focusNode(sorted.first);
      return;
    }
    final focusNode0 = _registry.nodeById(focused);
    if (focusNode0 == null) return;
    final tier = focusNode0.tier;
    String? next;
    for (final other in _registry.nodes) {
      if (!visibleIds.contains(other.id)) continue;
      if (other.tier <= tier) continue;
      if (other.prerequisites.contains(focused)) {
        next = other.id;
        break;
      }
    }
    next ??= _firstInNextTier(focused, visibleIds, tier);
    if (next != null) focusNode(next);
  }

  String? _firstInNextTier(String focused, Set<String> visibleIds, int tier) {
    String? best;
    for (final other in _registry.nodes) {
      if (!visibleIds.contains(other.id)) continue;
      if (other.tier <= tier) continue;
      if (best == null || other.id.compareTo(best) < 0) best = other.id;
    }
    return best;
  }

  void _retreatTier() {
    final focused = _focusedNodeId;
    if (focused == null) return;
    final focusNode0 = _registry.nodeById(focused);
    if (focusNode0 == null) return;
    final prereqs = focusNode0.prerequisites;
    if (prereqs.isNotEmpty) {
      focusNode(prereqs.first);
      return;
    }
    final tier = focusNode0.tier;
    if (tier <= 1) return;
    final visibleIds = layout.visibleNodeIds.toSet();
    String? best;
    for (final other in _registry.nodes) {
      if (!visibleIds.contains(other.id)) continue;
      if (other.tier >= tier) continue;
      if (best == null || other.id.compareTo(best) < 0) best = other.id;
    }
    if (best != null) focusNode(best);
  }

  void _jumpToExtremes({required bool start}) {
    final discovered = _allDiscoveredNodeIds;
    if (discovered.isEmpty) return;
    discovered.sort((a, b) {
      final ta = _discoveryByTech[a]!.tick;
      final tb = _discoveryByTech[b]!.tick;
      return ta.compareTo(tb);
    });
    focusNode(start ? discovered.first : discovered.last);
  }

  String? navigateDirection(TechTreeNavDirection direction) {
    final focused = _focusedNodeId;
    if (focused == null) return null;
    final layout0 = layout;
    final visibleIds = layout0.visibleNodeIds.toSet();
    final me = layout0.nodeById(focused);
    if (me == null) return null;
    switch (direction) {
      case TechTreeNavDirection.right:
        return _sibling(me, layout0, visibleIds, 1);
      case TechTreeNavDirection.left:
        return _sibling(me, layout0, visibleIds, -1);
      case TechTreeNavDirection.up:
      case TechTreeNavDirection.down:
        return null;
    }
  }

  String? _sibling(
    TechTreeLayoutNode me,
    TechTreeLayout layout0,
    Set<String> visibleIds,
    int delta,
  ) {
    final tierNodes = <TechTreeLayoutNode>[
      for (final n in layout0.nodes)
        if (n.generation == me.generation) n,
    ]..sort((a, b) => a.positionInGeneration.compareTo(b.positionInGeneration));
    final idx = tierNodes.indexWhere((n) => n.nodeId == me.nodeId);
    if (idx < 0) return null;
    final newIdx = idx + delta;
    if (newIdx < 0 || newIdx >= tierNodes.length) return null;
    final target = tierNodes[newIdx].nodeId;
    if (!visibleIds.contains(target)) return null;
    focusNode(target);
    return target;
  }
}
