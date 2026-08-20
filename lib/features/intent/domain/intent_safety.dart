class SafetyRequest {
  const SafetyRequest({required this.intent, this.confirmed = false});
  final String intent;
  final bool confirmed;
}

class SafetyResult {
  const SafetyResult({
    required this.isDestructive,
    required this.requiresConfirmation,
    required this.isAllowed,
    required this.isUndo,
  });
  final bool isDestructive;
  final bool requiresConfirmation;
  final bool isAllowed;
  final bool isUndo;
}

class IntentSafety {
  const IntentSafety();

  SafetyResult evaluate(SafetyRequest request) {
    final intent = request.intent.toLowerCase();
    final destructive = const {'delete', 'remove', 'destroy'}.contains(intent);
    final undo = intent == 'undo';
    return SafetyResult(
      isDestructive: destructive,
      requiresConfirmation: destructive,
      isAllowed: !destructive || request.confirmed,
      isUndo: undo,
    );
  }
}
