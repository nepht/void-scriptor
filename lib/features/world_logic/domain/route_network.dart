/// Sprint 110.9 — Route Network & Terrain Cost.
///
/// Domain-only route network with explicit nodes, edges, terrain, season
/// multipliers, optional blocks, and provenance. No persistence, UI, hidden
/// wall clock, locale, or random input. Calculations are deterministic.
library;

/// Terrain type for a route segment.
enum Terrain {
  plain(1.0),
  forest(1.5),
  swamp(2.0),
  desert(1.8),
  mountain(2.5);

  const Terrain(this.baseMultiplier);

  /// Base movement cost multiplier for this terrain.
  final double baseMultiplier;
}

/// Season of the year for seasonal access calculations.
enum Season {
  spring(1.0),
  summer(1.0),
  autumn(1.1),
  winter(1.4);

  const Season(this.accessMultiplier);

  /// Base seasonal access multiplier.
  final double accessMultiplier;
}

/// A single point of interest on the route network.
class RouteNode {
  const RouteNode({required this.id, required this.name});

  final String id;
  final String name;
}

/// Reason a route is currently blocked.
class BlockedRoute {
  const BlockedRoute({required this.reason});

  final String reason;
}

/// Source / provenance for a route segment.
class RouteSource {
  const RouteSource({required this.revision, required this.reason});

  final String revision;
  final String reason;
}

/// Default provenance when no explicit source is supplied.
const RouteSource defaultRouteSource = RouteSource(
  revision: 'world.default',
  reason: 'default route source',
);

/// Exception raised when a calculation traverses a blocked segment.
class RouteBlockedException implements Exception {
  RouteBlockedException({required this.edgeId, required this.reason});

  final String edgeId;
  final String reason;

  @override
  String toString() => 'Route $edgeId is blocked: $reason';
}

/// A directional edge between two nodes with a known distance.
class RouteEdge {
  RouteEdge({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.distance,
    this.terrain = Terrain.plain,
    this.blocked,
    RouteSource? source,
  }) : source = source ?? defaultRouteSource {
    if (distance < 0) {
      throw ArgumentError.value(
        distance,
        'distance',
        'edge $id has negative distance',
      );
    }
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'edge id cannot be empty');
    }
    if (fromId.isEmpty) {
      throw ArgumentError.value(fromId, 'fromId', 'edge $id has empty fromId');
    }
    if (toId.isEmpty) {
      throw ArgumentError.value(toId, 'toId', 'edge $id has empty toId');
    }
  }

  final String id;
  final String fromId;
  final String toId;
  final double distance;
  final Terrain terrain;
  final BlockedRoute? blocked;
  final RouteSource source;

  RouteEdge copyWith({
    String? id,
    String? fromId,
    String? toId,
    double? distance,
    Terrain? terrain,
    BlockedRoute? blocked,
    RouteSource? source,
  }) {
    return RouteEdge(
      id: id ?? this.id,
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      distance: distance ?? this.distance,
      terrain: terrain ?? this.terrain,
      blocked: blocked ?? this.blocked,
      source: source ?? this.source,
    );
  }
}

/// Immutable route graph with explicit nodes and edges.
class RouteGraph {
  RouteGraph({
    required Map<String, RouteNode> nodes,
    required List<RouteEdge> edges,
  }) : nodes = Map.unmodifiable(nodes),
       edges = List.unmodifiable(edges) {
    if (nodes.isEmpty) {
      throw ArgumentError('route graph must declare at least one node');
    }
    for (final node in nodes.values) {
      if (node.id.isEmpty) {
        throw ArgumentError('route node id cannot be empty');
      }
    }
    for (final edge in edges) {
      if (!nodes.containsKey(edge.fromId)) {
        throw ArgumentError(
          'edge ${edge.id} references missing node ${edge.fromId}',
        );
      }
      if (!nodes.containsKey(edge.toId)) {
        throw ArgumentError(
          'edge ${edge.id} references missing node ${edge.toId}',
        );
      }
    }
    _byId = {for (final edge in edges) edge.id: edge};
    _outgoing = <String, List<RouteEdge>>{};
    for (final edge in edges) {
      _outgoing.putIfAbsent(edge.fromId, () => <RouteEdge>[]).add(edge);
    }
  }

  final Map<String, RouteNode> nodes;
  final List<RouteEdge> edges;
  late final Map<String, RouteEdge> _byId;
  late final Map<String, List<RouteEdge>> _outgoing;

  /// Returns the node with the given id or throws.
  RouteNode node(String id) {
    final value = nodes[id];
    if (value == null) {
      throw ArgumentError('node $id is not part of the graph');
    }
    return value;
  }

  /// Returns the edge with the given id or throws.
  RouteEdge edge(String id) {
    final value = _byId[id];
    if (value == null) {
      throw ArgumentError('edge $id is not part of the graph');
    }
    return value;
  }

  /// Returns outgoing edges from a node in declaration order.
  List<RouteEdge> neighbors(String nodeId) {
    return List.unmodifiable(_outgoing[nodeId] ?? const <RouteEdge>[]);
  }

  /// Computes the deterministic total cost along a sequence of segment ids.
  ///
  /// Cost = sum(distance * terrain.baseMultiplier * season.accessMultiplier).
  /// Throws [RouteBlockedException] when any segment is currently blocked.
  double totalCost({required List<String> segments, required Season season}) {
    if (segments.isEmpty) {
      throw ArgumentError('segments list cannot be empty');
    }
    var total = 0.0;
    for (final id in segments) {
      final edge = _byId[id];
      if (edge == null) {
        throw ArgumentError('edge $id is not part of the graph');
      }
      final block = edge.blocked;
      if (block != null) {
        throw RouteBlockedException(edgeId: id, reason: block.reason);
      }
      total +=
          edge.distance * edge.terrain.baseMultiplier * season.accessMultiplier;
    }
    return total;
  }
}
