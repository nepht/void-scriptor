class IntentSandbox {
  IntentSandbox(Set<String> commands) : _commands = Set.unmodifiable(commands);
  final Set<String> _commands;
  bool run(String command) => _commands.contains(command);
}

class InteractionThread {
  bool _open = true;
  bool dispatch(String command) => _open && command.trim().isNotEmpty;
  void close() => _open = false;
}

class InputRateControl {
  InputRateControl({required this.maxPerWindow}) : _accepted = 0;
  final int maxPerWindow;
  int _accepted;
  bool accept() {
    if (_accepted >= maxPerWindow) return false;
    _accepted++;
    return true;
  }
}

class BatteryMode {
  bool _lowPower = false;
  void setLowPower(bool value) => _lowPower = value;
  double get processingBudget => _lowPower ? .5 : 1;
}

class ResolutionTraceEntry {
  const ResolutionTraceEntry({
    required this.input,
    required this.resolvedIntent,
    required this.confidence,
    this.rawPayload,
  });
  final String input;
  final String resolvedIntent;
  final double confidence;
  final String? rawPayload;
}

class ResolutionTrace {
  final List<ResolutionTraceEntry> _entries = [];
  List<ResolutionTraceEntry> get entries => List.unmodifiable(_entries);
  void record({
    required String input,
    required String resolvedIntent,
    required double confidence,
    String? rawPayload,
  }) {
    _entries.add(
      ResolutionTraceEntry(
        input: input,
        resolvedIntent: resolvedIntent,
        confidence: confidence,
      ),
    );
  }
}
