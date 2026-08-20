class IntentExplanation {
  const IntentExplanation({
    required this.intent,
    required this.reason,
    required this.confidence,
    this.rawPayload,
  });

  final String intent;
  final String reason;
  final double confidence;
  final String? rawPayload;
}

class IntentResolutionExplainer {
  final List<IntentExplanation> _entries = [];

  List<IntentExplanation> get entries => List.unmodifiable(_entries);

  void record({
    required String intent,
    required String source,
    required double confidence,
    String? rawPayload,
  }) {
    _entries.add(
      IntentExplanation(
        intent: intent,
        reason: 'Resolved by $source',
        confidence: confidence,
      ),
    );
  }
}

class NaturalMacroRegistry {
  final Map<String, List<String>> _macros = {};

  void record(String name, List<String> commands) {
    if (name.trim().isEmpty || commands.isEmpty) return;
    _macros[name] = List.unmodifiable(commands);
  }

  List<String> expand(String name) => _macros[name] ?? const [];
}

class IntentAgentPolicy {
  const IntentAgentPolicy();

  bool shouldUseAi({required bool deterministic}) => !deterministic;

  bool migrateVersion(String from, String to) =>
      from.trim().isNotEmpty && to.trim().isNotEmpty && from != to;
}
