enum IntentInputKind {
  voice,
  gesture,
  gaze,
  stylus,
  touch,
  keyboard,
  context,
  bci,
}

enum CreativeIntent { create, navigate, edit, preview, save, unknown }

class IntentSignal {
  const IntentSignal({
    required this.kind,
    required this.value,
    this.confidence = 1,
    this.timestamp = 0,
  });

  final IntentInputKind kind;
  final String value;
  final double confidence;
  final int timestamp;
}

class IntentConsent {
  const IntentConsent({
    this.voice = false,
    this.gesture = false,
    this.gaze = false,
    this.stylus = true,
    this.touch = true,
    this.keyboard = true,
    this.context = false,
    this.bci = false,
  });

  final bool voice;
  final bool gesture;
  final bool gaze;
  final bool stylus;
  final bool touch;
  final bool keyboard;
  final bool context;
  final bool bci;

  bool allows(IntentInputKind kind) => switch (kind) {
    IntentInputKind.voice => voice,
    IntentInputKind.gesture => gesture,
    IntentInputKind.gaze => gaze,
    IntentInputKind.stylus => stylus,
    IntentInputKind.touch => touch,
    IntentInputKind.keyboard => keyboard,
    IntentInputKind.context => context,
    IntentInputKind.bci => bci,
  };
}

class CreativeIntentResult {
  const CreativeIntentResult({
    required this.intent,
    required this.confidence,
    required this.sourceKinds,
    required this.command,
  });

  final CreativeIntent intent;
  final double confidence;
  final Set<IntentInputKind> sourceKinds;
  final String? command;
}

abstract interface class IntentCommandRegistry {
  bool canExecute(String command);
}

class IntentEngine {
  const IntentEngine({this.minimumConfidence = .55});

  final double minimumConfidence;

  CreativeIntentResult resolve({
    required Iterable<IntentSignal> signals,
    required IntentConsent consent,
    IntentCommandRegistry? commands,
  }) {
    final accepted = signals
        .where((signal) => consent.allows(signal.kind))
        .where((signal) => signal.value.trim().isNotEmpty)
        .toList(growable: false);
    final candidates = <CreativeIntent, double>{};
    for (final signal in accepted) {
      final intent = _classify(signal.value);
      if (intent == CreativeIntent.unknown) continue;
      candidates[intent] = (candidates[intent] ?? 0) + signal.confidence;
    }
    if (candidates.isEmpty) return _unknown(accepted);
    final winner = candidates.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    final confidence = (winner.value / accepted.length).clamp(0.0, 1.0);
    if (confidence < minimumConfidence) return _unknown(accepted);
    final command = _commandFor(winner.key, accepted, commands);
    return CreativeIntentResult(
      intent: winner.key,
      confidence: confidence,
      sourceKinds: accepted.map((signal) => signal.kind).toSet(),
      command: command,
    );
  }

  CreativeIntent _classify(String raw) {
    final value = raw.toLowerCase();
    if (value.contains('buat') || value.contains('create')) {
      return CreativeIntent.create;
    }
    if (value.contains('buka') || value.contains('navigate')) {
      return CreativeIntent.navigate;
    }
    if (value.contains('ubah') || value.contains('edit')) {
      return CreativeIntent.edit;
    }
    if (value.contains('preview') || value.contains('pratinjau')) {
      return CreativeIntent.preview;
    }
    if (value.contains('simpan') || value.contains('save')) {
      return CreativeIntent.save;
    }
    return CreativeIntent.unknown;
  }

  String? _commandFor(
    CreativeIntent intent,
    List<IntentSignal> signals,
    IntentCommandRegistry? commands,
  ) {
    if (commands == null) return null;
    final command = switch (intent) {
      CreativeIntent.create => 'project.create',
      CreativeIntent.navigate => 'workspace.navigate',
      CreativeIntent.edit => 'editor.edit',
      CreativeIntent.preview => 'preview.open',
      CreativeIntent.save => 'project.save',
      CreativeIntent.unknown => null,
    };
    return command != null && commands.canExecute(command) ? command : null;
  }

  CreativeIntentResult _unknown(List<IntentSignal> accepted) =>
      CreativeIntentResult(
        intent: CreativeIntent.unknown,
        confidence: 0,
        sourceKinds: accepted.map((signal) => signal.kind).toSet(),
        command: null,
      );
}

abstract interface class BciSignalAdapter {
  Stream<IntentSignal> get signals;
}

class ConsentCommandRegistry implements IntentCommandRegistry {
  const ConsentCommandRegistry(this.allowedCommands);

  final Set<String> allowedCommands;

  @override
  bool canExecute(String command) => allowedCommands.contains(command);
}

const intentEngine = IntentEngine();
const bciIsExperimental = true;
const intentEngineVersion = '0.51-experimental';
