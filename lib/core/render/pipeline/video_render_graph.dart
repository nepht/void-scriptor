/// Sprint 82 -- Step 82.81 (BAGIAN LXXXI -- Render Graph).
///
/// The blueprint defines the video render graph entity as:
///
///   Create:
///     VideoRenderGraph
///
///  is the minimal container for the advanced video
/// render graph. It carries a stable id, holds a single node per
/// canonical pipeline step defined in Step 82.82 (),
/// and exposes the nodes in the blueprint-locked pipeline order.
///
/// This class is intentionally descriptive and dependency-free: it does
/// not own clip data, runtime execution, codec negotiation, or renderer
/// integration. Those are explicit follow-ups (Step 82.83 foundation for
/// the actual node kinds, plus later playback / render / export slices).
/// The same boundary applies to the rest of the Sprint 82 audit, which
/// keeps the advanced video editor runtime marked as  until
/// it has its own persistence / service / UI tests.
library;

import "render_graph_example.dart";

/// Container for the canonical eight-step video render graph defined by
/// the blueprint. A graph holds at most one node per pipeline step; the
/// order in which nodes are exposed is the canonical order from
/// [RenderGraphExample].
class VideoRenderGraph {
  /// Creates an empty graph with the given stable [id]. The id is required
  /// so downstream consumers (preview, persistence, diagnostics) can refer
  /// to a specific graph without relying on object identity.
  VideoRenderGraph({required this.id});

  /// Stable identifier for this graph instance. Two graphs with the same
  /// id are still distinct objects; the id is opaque to this class and is
  /// not used for equality or hashing.
  final String id;

  final Map<RenderGraphStepKind, Object> _nodes =
      <RenderGraphStepKind, Object>{};

  /// Read-only view of the currently attached nodes, keyed by pipeline
  /// step. Iteration order is insertion order, not canonical pipeline
  /// order; use [steps] for the blueprint-locked ordering.
  Map<RenderGraphStepKind, Object> get nodes => Map.unmodifiable(_nodes);

  /// Number of attached nodes.
  int get length => _nodes.length;

  /// Whether the graph currently has no nodes attached.
  bool get isEmpty => _nodes.isEmpty;

  /// Returns the node attached to the given [kind], or  when no
  /// node has been attached for that step yet.
  Object? nodeFor(RenderGraphStepKind kind) => _nodes[kind];

  /// Attaches [node] to the canonical [kind] slot. Throws [StateError] if
  /// a node is already attached for that step; callers must remove the
  /// existing node first via [removeNode]. The graph never silently
  /// overwrites a blueprint slot, so accidental re-binding always fails
  /// loudly.
  void addNode({required RenderGraphStepKind kind, required Object node}) {
    if (_nodes.containsKey(kind)) {
      throw StateError(
        "VideoRenderGraph() already has a node for step ; "
        "call removeNode first.",
      );
    }
    _nodes[kind] = node;
  }

  /// Removes the node attached to [kind], if any. No-op when the slot is
  /// already empty so callers can clear a graph without checking state.
  void removeNode(RenderGraphStepKind kind) {
    _nodes.remove(kind);
  }

  /// The attached steps in the canonical pipeline order defined by
  /// [RenderGraphExample]. Steps without a node are skipped, so a freshly
  /// created graph returns an empty list. Insertion order does not affect
  /// the iteration; the blueprint order is always honored.
  Iterable<RenderGraphStepKind> get steps =>
      RenderGraphExample.canonical.steps.where(_nodes.containsKey);
}
