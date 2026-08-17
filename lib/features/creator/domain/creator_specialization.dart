/// Sprint 43 — Step 43.4 Creator Specialization.
///
/// Canonical creator specialization categories. A creator may have several
/// specializations (multi-select); the enum is order-stable so the canonical
/// list is deterministic.
enum CreatorSpecialization {
  characterArtist('Character Artist'),
  conceptArtist('Concept Artist'),
  illustrator('Illustrator'),
  writer('Writer'),
  animator('Animator'),
  filmmaker('Filmmaker'),
  gameCreator('Game Creator'),
  environmentArtist('Environment Artist'),
  vfxArtist('VFX Artist'),
  soundDesigner('Sound Designer'),
  aiCreator('AI Creator'),
  developer('Developer'),
  multiDisciplinary('Multi-disciplinary Creator');

  const CreatorSpecialization(this.label);

  final String label;

  /// Parses a label case-insensitively; unknown labels fall back to
  /// [CreatorSpecialization.multiDisciplinary].
  static CreatorSpecialization fromLabel(String label) {
    final normalized = label.trim().toLowerCase();
    for (final value in values) {
      if (value.label.toLowerCase() == normalized) {
        return value;
      }
    }
    return CreatorSpecialization.multiDisciplinary;
  }
}
