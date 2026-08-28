// Sprint 82 -- Step 82.81 (BAGIAN LXXXI -- Render Graph).
//
// The blueprint defines the video render graph entity as:
//
//   Create:
//     VideoRenderGraph
//
// Step 82.82 locks the eight-step pipeline order via
// , and Step 82.83 (foundation, not yet implemented)
// will add the actual node kinds.  is the graph
// container that holds nodes and enforces the blueprint ordering.
//
// This test pins the minimal contract that is verifiable from Step 82.81
// alone: the graph exists, has a stable id, supports adding a single
// node keyed by step kind, and exposes its nodes in the canonical
// pipeline order. Real node types, runtime execution and renderer
// integration are explicit follow-ups and must not be claimed here.

import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/core/render/pipeline/render_graph_example.dart";
import "package:void_scriptor/core/render/pipeline/video_render_graph.dart";

void main() {
  group("VideoRenderGraph (Step 82.81 -- BAGIAN LXXXI)", () {
    test("can be constructed with a stable id and starts empty", () {
      final graph = VideoRenderGraph(id: "g-1");
      expect(graph.id, "g-1");
      expect(graph.nodes, isEmpty);
      expect(graph.isEmpty, isTrue);
      expect(graph.length, 0);
    });

    test("addNode stores a node keyed by canonical pipeline step", () {
      final graph = VideoRenderGraph(id: "g-1");
      graph.addNode(kind: RenderGraphStepKind.sourceDecode, node: Object());
      expect(graph.length, 1);
      expect(graph.isEmpty, isFalse);
      expect(graph.nodeFor(RenderGraphStepKind.sourceDecode), isNotNull);
    });

    test("addNode rejects a duplicate step kind", () {
      final graph = VideoRenderGraph(id: "g-1");
      graph.addNode(kind: RenderGraphStepKind.color, node: Object());
      expect(
        () => graph.addNode(kind: RenderGraphStepKind.color, node: Object()),
        throwsStateError,
      );
    });

    test("removeNode drops the node for that step", () {
      final graph = VideoRenderGraph(id: "g-1");
      graph.addNode(kind: RenderGraphStepKind.outputTransform, node: Object());
      graph.removeNode(RenderGraphStepKind.outputTransform);
      expect(graph.nodeFor(RenderGraphStepKind.outputTransform), isNull);
      expect(graph.isEmpty, isTrue);
    });

    test("iteration follows the canonical pipeline order from 82.82", () {
      final graph = VideoRenderGraph(id: "g-1");
      const order = RenderGraphStepKind.values;
      for (final kind in order.reversed) {
        graph.addNode(kind: kind, node: Object());
      }
      final visited = graph.steps.toList();
      expect(visited, order);
    });
  });
}
