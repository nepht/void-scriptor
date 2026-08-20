class GazeSample {
  const GazeSample({
    required this.targetId,
    required this.confidence,
    required this.dwell,
    this.isStable = true,
  });

  final String targetId;
  final double confidence;
  final Duration dwell;
  final bool isStable;
}

class GazeResult {
  const GazeResult({required this.focusedTargetId, required this.activate});

  final String? focusedTargetId;
  final bool activate;

  bool get isFocused => focusedTargetId != null;
}

class GazeAdapter {
  const GazeAdapter({
    this.dwellDuration = const Duration(milliseconds: 500),
    this.minimumConfidence = .7,
  });

  final Duration dwellDuration;
  final double minimumConfidence;

  GazeResult evaluate(GazeSample sample) {
    final focused =
        sample.isStable &&
        sample.confidence >= minimumConfidence &&
        sample.dwell >= dwellDuration;
    return GazeResult(
      focusedTargetId: focused ? sample.targetId : null,
      activate: false,
    );
  }
}
