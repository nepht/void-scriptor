class ContinuityEvent {
  const ContinuityEvent({
    required this.sceneOrder,
    required this.targetAssetId,
    this.beforeState = '',
    this.afterState = '',
  });
  final int sceneOrder;
  final String targetAssetId;
  final String beforeState;
  final String afterState;
}

class ContinuityWarning {
  const ContinuityWarning({
    required this.targetAssetId,
    required this.sceneOrder,
    required this.message,
  });
  final String targetAssetId;
  final int sceneOrder;
  final String message;
}

class SceneContinuityValidator {
  static List<ContinuityWarning> validate(List<ContinuityEvent> events) {
    final warnings = <ContinuityWarning>[];
    final latest = <String, ContinuityEvent>{};
    for (final event in [
      ...events,
    ]..sort((a, b) => a.sceneOrder.compareTo(b.sceneOrder))) {
      final prior = latest[event.targetAssetId];
      if (prior != null &&
          event.beforeState.isNotEmpty &&
          prior.afterState.isNotEmpty &&
          event.beforeState != prior.afterState) {
        warnings.add(
          ContinuityWarning(
            targetAssetId: event.targetAssetId,
            sceneOrder: event.sceneOrder,
            message:
                'Expected ${event.beforeState}, previous state was ${prior.afterState}.',
          ),
        );
      }
      latest[event.targetAssetId] = event;
    }
    return warnings;
  }
}

class ResolvedSceneContext {
  const ResolvedSceneContext({
    required this.storyTitle,
    required this.sceneTitle,
    required this.durationSeconds,
    required this.characters,
    required this.environment,
    required this.beats,
  });
  final String storyTitle;
  final String sceneTitle;
  final double? durationSeconds;
  final List<String> characters;
  final String environment;
  final List<String> beats;
  String toPrompt() =>
      '''Story: $storyTitle
Scene: $sceneTitle
Duration: ${durationSeconds ?? 'unset'} seconds
Characters: ${characters.join(', ')}
Environment: $environment
Action: ${beats.join(' ')}''';
}
