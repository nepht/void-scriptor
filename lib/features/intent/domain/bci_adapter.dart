class BciSignal {
  const BciSignal({required this.intent, required this.confidence});
  final String intent;
  final double confidence;
}

enum BciRejectionReason { consentRequired, hardwareUnavailable, lowConfidence }

class BciResult {
  const BciResult({required this.accepted, this.intent, this.reason});
  final bool accepted;
  final String? intent;
  final BciRejectionReason? reason;
}

class BciAdapter {
  const BciAdapter({
    this.hardwareAvailable = false,
    this.consentGranted = false,
  });
  final bool hardwareAvailable;
  final bool consentGranted;

  BciResult interpret(BciSignal signal) {
    if (!consentGranted) {
      return const BciResult(
        accepted: false,
        reason: BciRejectionReason.consentRequired,
      );
    }
    if (!hardwareAvailable) {
      return const BciResult(
        accepted: false,
        reason: BciRejectionReason.hardwareUnavailable,
      );
    }
    if (signal.confidence < .7) {
      return const BciResult(
        accepted: false,
        reason: BciRejectionReason.lowConfidence,
      );
    }
    return BciResult(accepted: true, intent: signal.intent);
  }
}
