/// Sprint 78 -- Step 78.82 (BAGIAN LXXIV -- Animatic Track).
///
/// Locks the canonical animatic track set as defined by the blueprint:
///
/// ```text
/// Video Track
/// Dialogue Track
/// SFX Track
/// Music Track
/// Notes Track
/// ```
///
/// This model is intentionally descriptive: it does not own clips, ordering
/// or persistence. It is the single source of truth for the five track kinds
/// that downstream animatic preview, editor and persistence layers can rely
/// on. Persistence and clip ownership for individual tracks remain separate
/// follow-ups.
library;

/// Distinct kinds of animatic tracks participating in the canonical set.
enum AnimaticTrackType {
  video('Video Track'),
  dialogue('Dialogue Track'),
  sfx('SFX Track'),
  music('Music Track'),
  notes('Notes Track');

  const AnimaticTrackType(this.label);

  /// Human-readable display label as it appears in the animatic editor.
  final String label;

  /// The single blueprint-locked canonical set in the exact order defined by
  /// BAGIAN LXXIV. Exposed as an unmodifiable list so the order cannot drift
  /// at runtime and tests can pin the order without reaching into private
  /// state.
  static const List<AnimaticTrackType> canonical = <AnimaticTrackType>[
    AnimaticTrackType.video,
    AnimaticTrackType.dialogue,
    AnimaticTrackType.sfx,
    AnimaticTrackType.music,
    AnimaticTrackType.notes,
  ];
}
