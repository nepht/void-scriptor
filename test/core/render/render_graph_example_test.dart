// Sprint 82 -- Step 82.82 (BAGIAN LXXXII -- Render Graph Example).
// Source: full_sprint_sources/SPRINT_082.md, line ~1233.
// Reference pipeline order:
//   Source Decode -> Time Remap -> Transform -> Mask -> Effects -> Color ->
//   Composite -> Output Transform
// This test pins that ordering as the canonical RenderGraphExample contract.

import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/core/render/pipeline/render_graph_example.dart";

void main() {
  group("RenderGraphExample (Step 82.82 -- BAGIAN LXXXII)", () {
    test("exposes eight canonical steps in the exact blueprint order", () {
      const example = RenderGraphExample.canonical;

      expect(example.steps, const [
        RenderGraphStepKind.sourceDecode,
        RenderGraphStepKind.timeRemap,
        RenderGraphStepKind.transform,
        RenderGraphStepKind.mask,
        RenderGraphStepKind.effects,
        RenderGraphStepKind.color,
        RenderGraphStepKind.composite,
        RenderGraphStepKind.outputTransform,
      ]);
    });

    test("default constructor returns the canonical ordering", () {
      const example = RenderGraphExample();
      expect(example.steps.length, 8);
      expect(example.steps.first, RenderGraphStepKind.sourceDecode);
      expect(example.steps.last, RenderGraphStepKind.outputTransform);
    });

    test("downstream consumer can iterate the pipeline in order", () {
      const example = RenderGraphExample.canonical;
      final visited = <RenderGraphStepKind>[];
      for (final step in example.steps) {
        visited.add(step);
      }
      expect(visited, example.steps);
    });
  });
}
