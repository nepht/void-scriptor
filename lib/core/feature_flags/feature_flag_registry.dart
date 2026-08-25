/// Feature flag registry for Void Scriptor v1.2 (Sprint 109).
///
/// Canonical delivery rule (`delivery_rules.feature_flag_default` in
/// sprint_109.json): every new v1.2 capability ships behind a feature flag
/// that defaults to OFF. Flag names are fixed here so later steps register
/// UI/persistence wiring against stable identifiers.
library;

/// The 13 wave-1 capability flags, canonical order follows
/// docs/planning/v1.2/feature_contracts.md (F1..F25).
const List<String> kVs12FeatureFlags = <String>[
  'vs12_lore_links',
  'vs12_contradictions',
  'vs12_voice_interview',
  'vs12_conlang',
  'vs12_focus_writing',
  'vs12_lore_graph',
  'vs12_plot_board',
  'vs12_moodboard',
  'vs12_spoiler_sharing',
  'vs12_pov',
  'vs12_pacing',
  'vs12_export',
  'vs12_quests',
];

/// In-memory registry of v1.2 feature flags.
///
/// Instances are independent; persistence of overrides is deliberately out of
/// scope for the registry itself and belongs to the step that wires settings.
final class FeatureFlagRegistry {
  final Set<String> _enabled = <String>{};

  /// All known v1.2 flag names (unmodifiable view).
  List<String> get knownFlags => List<String>.unmodifiable(kVs12FeatureFlags);

  /// True when every known flag is at its default OFF state.
  bool get allAtDefaults => _enabled.isEmpty;

  bool isEnabled(String flag) {
    _ensureKnown(flag);
    return _enabled.contains(flag);
  }

  void enable(String flag) {
    _ensureKnown(flag);
    _enabled.add(flag);
  }

  void disable(String flag) {
    _ensureKnown(flag);
    _enabled.remove(flag);
  }

  /// Turns every flag back to its default OFF state.
  void resetToDefaults() => _enabled.clear();

  void _ensureKnown(String flag) {
    if (!kVs12FeatureFlags.contains(flag)) {
      throw ArgumentError.value(flag, 'flag', 'Unknown v1.2 feature flag');
    }
  }
}
