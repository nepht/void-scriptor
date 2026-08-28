/// Feature flag registry for Void Scriptor v1.2 (Sprint 109, extended by
/// Sprint 110.8 with kill-switch behavior).
///
/// Canonical delivery rule (delivery_rules.feature_flag_default in
/// sprint_109.json): every new v1.2 capability ships behind a feature flag
/// that defaults to OFF. Flag names are fixed here so later steps register
/// UI/persistence wiring against stable identifiers.
///
/// Sprint 110.8 kill-switch: an emergency global disable that forces every
/// known flag back to its default OFF state in a single call. The state is
/// observable to diagnostics via [killSwitchActive]. Re-enabling any flag
/// after the kill-switch has been engaged clears the emergency state so
/// future explicit enables remain honored.
library;

/// The 13 wave-1 capability flags, canonical order follows
/// docs/planning/v1.2/feature_contracts.md (F1..F25).
const List<String> kVs12FeatureFlags = <String>[
  "vs12_lore_links",
  "vs12_contradictions",
  "vs12_voice_interview",
  "vs12_conlang",
  "vs12_focus_writing",
  "vs12_lore_graph",
  "vs12_plot_board",
  "vs12_moodboard",
  "vs12_spoiler_sharing",
  "vs12_pov",
  "vs12_pacing",
  "vs12_export",
  "vs12_quests",
];

/// In-memory registry of v1.2 feature flags.
///
/// Instances are independent; persistence of overrides is deliberately out of
/// scope for the registry itself and belongs to the step that wires settings.
final class FeatureFlagRegistry {
  final Set<String> _enabled = <String>{};
  bool _killSwitchActive = false;

  /// All known v1.2 flag names (unmodifiable view).
  List<String> get knownFlags => List<String>.unmodifiable(kVs12FeatureFlags);

  /// Currently enabled flags (unmodifiable view). Always empty while the
  /// kill-switch is engaged, regardless of historical enables.
  List<String> get enabledFlags => List<String>.unmodifiable(_enabled);

  /// True while the emergency kill-switch is engaged.
  bool get killSwitchActive => _killSwitchActive;

  /// True when every known flag is at its default OFF state.
  bool get allAtDefaults => _enabled.isEmpty;

  bool isEnabled(String flag) {
    _ensureKnown(flag);
    if (_killSwitchActive) return false;
    return _enabled.contains(flag);
  }

  void enable(String flag) {
    _ensureKnown(flag);
    // Explicit enable is treated as writer intent to leave kill-switch state.
    _killSwitchActive = false;
    _enabled.add(flag);
  }

  void disable(String flag) {
    _ensureKnown(flag);
    _enabled.remove(flag);
  }

  /// Engages the emergency kill-switch. Disables every currently enabled
  /// flag and locks the registry to all-OFF until [disengageKillSwitch] is
  /// called or any flag is explicitly re-enabled. Idempotent.
  void engageKillSwitch() {
    _killSwitchActive = true;
    _enabled.clear();
  }

  /// Clears the kill-switch without changing the per-flag enable state. After
  /// this call the registry is back to its default-OFF surface.
  void disengageKillSwitch() {
    _killSwitchActive = false;
    _enabled.clear();
  }

  /// Turns every flag back to its default OFF state without engaging the
  /// kill-switch. Useful for "reset to defaults" settings actions.
  void resetToDefaults() {
    _killSwitchActive = false;
    _enabled.clear();
  }

  void _ensureKnown(String flag) {
    if (!kVs12FeatureFlags.contains(flag)) {
      throw ArgumentError.value(flag, "flag", "Unknown v1.2 feature flag");
    }
  }
}
