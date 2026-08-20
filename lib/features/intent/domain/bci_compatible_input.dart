class BciSignal {
  const BciSignal({
    required this.command,
    required this.confidence,
    required this.consentGranted,
    required this.hardwareAvailable,
  });

  final String command;
  final double confidence;
  final bool consentGranted;
  final bool hardwareAvailable;
}

class BciIntent {
  const BciIntent({required this.command, required this.confidence});

  final String command;
  final double confidence;

  @override
  bool operator ==(Object other) =>
      other is BciIntent &&
      other.command == command &&
      other.confidence == confidence;

  @override
  int get hashCode => Object.hash(command, confidence);
}

class BciCompatibleInput {
  const BciCompatibleInput({this.minimumConfidence = .7});

  final double minimumConfidence;

  BciIntent? normalize(BciSignal signal) {
    if (!signal.consentGranted || !signal.hardwareAvailable) return null;
    if (signal.command.trim().isEmpty ||
        signal.confidence < minimumConfidence) {
      return null;
    }
    return BciIntent(command: signal.command, confidence: signal.confidence);
  }
}
