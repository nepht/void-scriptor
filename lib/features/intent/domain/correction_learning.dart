class IntentCorrection {
  const IntentCorrection({
    required this.context,
    required this.predictedCommand,
    required this.correctedCommand,
    this.rawPayload,
  });

  final String context;
  final String predictedCommand;
  final String correctedCommand;
  final String? rawPayload;

  IntentCorrection get redacted => IntentCorrection(
    context: context,
    predictedCommand: predictedCommand,
    correctedCommand: correctedCommand,
  );
}

class CorrectionLearner {
  CorrectionLearner({required this.maxCorrections}) {
    if (maxCorrections < 1) {
      throw ArgumentError.value(maxCorrections, 'maxCorrections');
    }
  }

  final int maxCorrections;
  final List<IntentCorrection> _corrections = [];

  List<IntentCorrection> get corrections => List.unmodifiable(_corrections);

  void record(IntentCorrection correction) {
    _corrections.insert(0, correction.redacted);
    if (_corrections.length > maxCorrections) {
      _corrections.removeRange(maxCorrections, _corrections.length);
    }
  }

  String correct(String context, String predictedCommand) {
    for (final correction in _corrections) {
      if (correction.context == context &&
          correction.predictedCommand == predictedCommand) {
        return correction.correctedCommand;
      }
    }
    return predictedCommand;
  }
}
