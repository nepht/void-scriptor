/// Sprint 43 — Step 43.10 AI Context Layers.
///
/// Context is layered from global down to the current selection so prompts
/// stay bounded: never dump the whole creator data into every request.
enum AiContextLayer {
  creatorPreferences,
  currentProject,
  currentUniverse,
  currentCharacter,
  currentSelection;

  /// Layers ordered from most specific (selection) to most global
  /// (creator preferences). Prompts should include the narrowest layers
  /// first and only widen when needed.
  static List<AiContextLayer> valuesByProximity() => [
    AiContextLayer.currentSelection,
    AiContextLayer.currentCharacter,
    AiContextLayer.currentUniverse,
    AiContextLayer.currentProject,
    AiContextLayer.creatorPreferences,
  ];
}
