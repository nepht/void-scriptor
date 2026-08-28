/// Sprint 82 -- Step 82.82 (BAGIAN LXXXII -- Render Graph Example).
///
/// Defines the canonical eight-step render graph pipeline order for an
/// advanced video editing session. The order is fixed by the blueprint:
///
///   Source Decode -> Time Remap -> Transform -> Mask -> Effects -> Color
///   -> Composite -> Output Transform
///
/// This model is intentionally descriptive: the actual node implementation
/// (DecodeNode, TimeNode, etc.) is owned by Step 82.83, while this example
/// simply locks the wiring/ordering so downstream graph traversals, preview
/// panels and editors can rely on a single source of truth.
library;

/// Distinct kinds of nodes participating in the canonical render graph.
enum RenderGraphStepKind {
  sourceDecode,
  timeRemap,
  transform,
  mask,
  effects,
  color,
  composite,
  outputTransform,
}

/// Reference render graph wiring as described in BAGIAN LXXXII.
class RenderGraphExample {
  const RenderGraphExample();

  /// The single blueprint-locked canonical example.
  static const RenderGraphExample canonical = RenderGraphExample();

  /// The eight pipeline steps in the exact order defined by the blueprint.
  static const List<RenderGraphStepKind> _canonicalSteps = [
    RenderGraphStepKind.sourceDecode,
    RenderGraphStepKind.timeRemap,
    RenderGraphStepKind.transform,
    RenderGraphStepKind.mask,
    RenderGraphStepKind.effects,
    RenderGraphStepKind.color,
    RenderGraphStepKind.composite,
    RenderGraphStepKind.outputTransform,
  ];

  /// Pipeline order. The list is intentionally unmodifiable; downstream code
  /// must not mutate blueprint ordering.
  List<RenderGraphStepKind> get steps => List.unmodifiable(_canonicalSteps);
}
