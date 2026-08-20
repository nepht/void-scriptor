enum LabsFeature { voice, gesture, gaze, stylus, bci }

enum LabsOutcome { accepted, rejected, failed }

class LabsEvent {
  const LabsEvent({
    required this.feature,
    required this.outcome,
    this.payload,
    this.errorType,
  });
  final LabsFeature feature;
  final LabsOutcome outcome;
  final String? payload;
  final String? errorType;
}

class PrivacyAudit {
  int redactedPayloads = 0;
}

class LabsMetrics {
  int accepted = 0;
  int rejected = 0;
  int failures = 0;
}

class LabsDiagnostics {
  final events = <LabsEvent>[];
  final privacyAudit = PrivacyAudit();
  final metrics = LabsMetrics();

  void record(LabsEvent event) {
    if (event.payload != null) privacyAudit.redactedPayloads++;
    final safe = LabsEvent(
      feature: event.feature,
      outcome: event.outcome,
      errorType: event.errorType,
    );
    events.add(safe);
    switch (event.outcome) {
      case LabsOutcome.accepted:
        metrics.accepted++;
      case LabsOutcome.rejected:
        metrics.rejected++;
      case LabsOutcome.failed:
        metrics.failures++;
    }
  }

  LabsEvent guard(LabsFeature feature, void Function() action) {
    try {
      action();
      final event = LabsEvent(feature: feature, outcome: LabsOutcome.accepted);
      record(event);
      return event;
    } catch (error) {
      final event = LabsEvent(
        feature: feature,
        outcome: LabsOutcome.failed,
        errorType: error.runtimeType.toString(),
      );
      record(event);
      return event;
    }
  }
}
