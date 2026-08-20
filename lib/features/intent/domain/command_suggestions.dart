import 'next_action_prediction.dart';

class CommandSuggestion {
  const CommandSuggestion({
    required this.command,
    required this.targetId,
    this.requiresConfirmation = false,
  });

  final String command;
  final String targetId;
  final bool requiresConfirmation;

  @override
  bool operator ==(Object other) =>
      other is CommandSuggestion &&
      other.command == command &&
      other.targetId == targetId &&
      other.requiresConfirmation == requiresConfirmation;

  @override
  int get hashCode => Object.hash(command, targetId, requiresConfirmation);
}

class CommandSuggestionEngine {
  List<CommandSuggestion> suggest(List<IntentHistoryEntry> history) {
    if (history.isEmpty) return const [];

    final latest = history.last;
    if (latest.intent == 'delete' || latest.intent == 'remove') {
      return const [];
    }

    if (latest.intent == 'edit') {
      return [CommandSuggestion(command: 'save', targetId: latest.targetId)];
    }

    if (latest.intent == 'select') {
      return [CommandSuggestion(command: 'edit', targetId: latest.targetId)];
    }

    return const [];
  }
}
