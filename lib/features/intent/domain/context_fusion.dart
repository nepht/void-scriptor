class ContextualSignal {
  const ContextualSignal({
    required this.source,
    required this.intent,
    required this.confidence,
  });
  final String source;
  final String intent;
  final double confidence;
}

class IntentContextHint {
  const IntentContextHint({required this.activeMode});
  final String activeMode;
}

class ContextFusionResult {
  const ContextFusionResult({
    required this.intent,
    required this.hasConflict,
    required this.requiresConfirmation,
    required this.priority,
  });
  final String? intent;
  final bool hasConflict;
  final bool requiresConfirmation;
  final int priority;
}

class ContextFusionEngine {
  const ContextFusionEngine({this.minimumConfidence = .55});
  final double minimumConfidence;

  ContextFusionResult resolve(
    List<ContextualSignal> signals,
    IntentContextHint context,
  ) {
    final eligible = signals
        .where((signal) => signal.confidence >= minimumConfidence)
        .toList();
    final intents = eligible.map<String>((signal) => signal.intent).toSet();
    if (eligible.isEmpty) {
      return const ContextFusionResult(
        intent: null,
        hasConflict: false,
        requiresConfirmation: false,
        priority: 0,
      );
    }
    final conflict = intents.length > 1;
    String? selected;
    if (context.activeMode == 'review' && intents.contains('select')) {
      selected = 'select';
    } else if (context.activeMode == 'writing' && intents.contains('edit')) {
      selected = 'edit';
    } else {
      selected = eligible
          .reduce((a, b) => _priority(a.intent) >= _priority(b.intent) ? a : b)
          .intent;
    }
    return ContextFusionResult(
      intent: selected,
      hasConflict: conflict,
      requiresConfirmation: conflict,
      priority: _priority(selected),
    );
  }

  int _priority(String? intent) => switch (intent) {
    'select' => 1,
    'edit' => 2,
    'delete' => 3,
    _ => 0,
  };
}
