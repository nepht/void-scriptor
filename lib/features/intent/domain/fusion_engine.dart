class FusionSignal {
  const FusionSignal({
    required this.source,
    required this.intent,
    required this.confidence,
    required this.timestamp,
  });
  final String source;
  final String intent;
  final double confidence;
  final int timestamp;
}

class FusionResult {
  const FusionResult({
    required this.intent,
    required this.sources,
    required this.confidence,
  });
  final String? intent;
  final Set<String> sources;
  final double confidence;
  bool get isActionable => intent != null && confidence >= .7;
}

class FusionEngine {
  const FusionEngine({
    this.window = const Duration(milliseconds: 300),
    this.minimumConfidence = .55,
  });
  final Duration window;
  final double minimumConfidence;

  FusionResult fuse(List<FusionSignal> signals) {
    if (signals.isEmpty) {
      return const FusionResult(intent: null, sources: {}, confidence: 0);
    }
    final anchor = signals.first.timestamp;
    final eligible = signals
        .where(
          (signal) =>
              (signal.timestamp - anchor).abs() <= window.inMilliseconds &&
              signal.confidence >= minimumConfidence,
        )
        .toList();
    if (eligible.length < 2) {
      return const FusionResult(intent: null, sources: {}, confidence: 0);
    }
    eligible.sort((a, b) => b.confidence.compareTo(a.confidence));
    final confidence = eligible
        .map((signal) => signal.confidence)
        .reduce((a, b) => a > b ? a : b);
    return FusionResult(
      intent: eligible.first.intent,
      sources: eligible.map((signal) => signal.source).toSet(),
      confidence: confidence,
    );
  }
}
