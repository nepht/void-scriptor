enum IntentVerificationCategory {
  intent,
  multimodal,
  accessibility,
  privacy,
  safety,
  performance,
}

class VerificationResult {
  const VerificationResult._(this.passed, this.message);

  const VerificationResult.passed() : this._(true, null);

  const VerificationResult.failed(String message) : this._(false, message);

  final bool passed;
  final String? message;
}

class IntentVerificationReport {
  IntentVerificationReport({
    required Map<IntentVerificationCategory, VerificationResult> results,
    required List<String> commands,
  }) : results = Map.unmodifiable(results),
       commands = List.unmodifiable(commands);

  final Map<IntentVerificationCategory, VerificationResult> results;
  final List<String> commands;

  bool get hasCommandEvidence =>
      commands.any((command) => command.trim().isNotEmpty);

  List<IntentVerificationCategory> get missingCategories =>
      IntentVerificationCategory.values
          .where((category) => !results.containsKey(category))
          .toList(growable: false);

  List<IntentVerificationCategory> get failedCategories => results.entries
      .where((entry) => !entry.value.passed)
      .map((entry) => entry.key)
      .toList(growable: false);

  bool get isComplete =>
      missingCategories.isEmpty &&
      failedCategories.isEmpty &&
      hasCommandEvidence;
}
