/// Close-prompt decision model (Step 26.93).
///
/// When a user closes a project while a persistent job (e.g. export) is still
/// running, the app must not tear down resources under it. This model carries
/// the decision the UI presents: keep the project open, or cancel and close.
enum BackgroundJobKind { export, backup, import, other }

class ClosePromptResult {
  const ClosePromptResult._({
    required this.needsDecision,
    this.activeLabel,
    this.activeJobType,
  });

  const ClosePromptResult.none()
    : this._(needsDecision: false, activeLabel: null, activeJobType: null);

  const ClosePromptResult.running({
    required String activeLabel,
    required BackgroundJobKind activeJobType,
  }) : this._(
         needsDecision: true,
         activeLabel: activeLabel,
         activeJobType: activeJobType,
       );

  final bool needsDecision;
  final String? activeLabel;
  final BackgroundJobKind? activeJobType;

  List<String> get options => ['Keep Project Open', 'Cancel & Close'];
}
