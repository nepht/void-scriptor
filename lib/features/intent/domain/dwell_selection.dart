class DwellSample {
  const DwellSample({
    required this.targetId,
    required this.confidence,
    required this.stableFor,
    this.isStable = true,
  });

  final String targetId;
  final double confidence;
  final Duration stableFor;
  final bool isStable;
}

class DwellSelectionResult {
  const DwellSelectionResult({
    required this.selectedTargetId,
    required this.shouldActivate,
  });

  final String? selectedTargetId;
  final bool shouldActivate;
}

class DwellSelector {
  const DwellSelector({
    this.dwellDuration = const Duration(milliseconds: 500),
    this.minimumConfidence = .7,
  });

  final Duration dwellDuration;
  final double minimumConfidence;

  DwellSelectionResult evaluate(DwellSample sample) {
    final canSelect =
        sample.isStable &&
        sample.confidence >= minimumConfidence &&
        sample.stableFor >= dwellDuration;
    return DwellSelectionResult(
      selectedTargetId: canSelect ? sample.targetId : null,
      shouldActivate: canSelect,
    );
  }
}
