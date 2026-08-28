/// Sprint 78 -- Step 78.81 (BAGIAN LXXIII -- Animatic Definition).
///
/// Locks the canonical animatic definition formula as defined by the
/// blueprint:
///
/// ```text
/// Storyboard Images
/// +
/// Timing
/// +
/// Camera simulation foundation
/// +
/// Temporary Audio
/// =
/// ANIMATIC
/// ```
///
/// This model is intentionally descriptive: it does not own clips, ordering
/// or persistence. It is the single source of truth for the four required
/// animatic components that downstream animatic preview, editor and
/// persistence layers can rely on. Actual media assembly, timing math and
/// camera simulation remain separate follow-ups (see BAGIAN LXXIV onward).
library;

/// Distinct animatic components participating in the canonical definition.
enum AnimaticComponent {
  storyboardImages("Storyboard Images"),
  timing("Timing"),
  cameraSimulationFoundation("Camera simulation foundation"),
  temporaryAudio("Temporary Audio");

  const AnimaticComponent(this.label);

  /// Human-readable display label as it appears in the animatic editor.
  final String label;

  /// The single blueprint-locked canonical set in the exact order defined by
  /// BAGIAN LXXIII. Exposed as an unmodifiable list so the order cannot drift
  /// at runtime and tests can pin the order without reaching into private
  /// state.
  static const List<AnimaticComponent> canonical = <AnimaticComponent>[
    AnimaticComponent.storyboardImages,
    AnimaticComponent.timing,
    AnimaticComponent.cameraSimulationFoundation,
    AnimaticComponent.temporaryAudio,
  ];
}

/// Reference animatic definition wiring as described in BAGIAN LXXIII.
class AnimaticDefinition {
  const AnimaticDefinition(this.components);

  /// Ordered list of animatic components this definition describes.
  final List<AnimaticComponent> components;

  /// Canonical blueprint concatenation used for display and verification.
  static const String formula =
      "Storyboard Images + Timing + Camera simulation foundation + Temporary Audio = ANIMATIC";

  /// Default animatic definition that mirrors the blueprint exactly.
  static const AnimaticDefinition canonical = AnimaticDefinition(
    AnimaticComponent.canonical,
  );
}
