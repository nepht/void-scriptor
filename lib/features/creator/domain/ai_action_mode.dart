/// Sprint 43 — Step 43.12 AI Action Modes.
///
/// Canonical AI interaction modes: ASK, CREATE, EDIT, ANALYZE, PLAN, REVIEW,
/// AUTOMATE. Each mode carries an example prompt for guidance.
enum AiActionMode {
  ask('ASK', 'Ask about my universe or project.'),
  create('CREATE', 'Create Qowner battle storyboard.'),
  edit('EDIT', 'Edit this scene description to be more cinematic.'),
  analyze('ANALYZE', 'Analyze this chapter for pacing issues.'),
  plan('PLAN', 'Create production plan for episode 2.'),
  review('REVIEW', 'Check this scene against canon.'),
  automate('AUTOMATE', 'Automate reference import and tagging.');

  const AiActionMode(this.label, this.example);

  final String label;
  final String example;

  static AiActionMode fromLabel(String label) {
    for (final value in values) {
      if (value.label.toLowerCase() == label.trim().toLowerCase()) {
        return value;
      }
    }
    return AiActionMode.ask;
  }
}
