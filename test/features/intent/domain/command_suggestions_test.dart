import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/command_suggestions.dart';
import 'package:void_scriptor/features/intent/domain/next_action_prediction.dart';

void main() {
  test('suggests save after editing the selected target', () {
    final suggestions = CommandSuggestionEngine().suggest(const [
      IntentHistoryEntry(intent: 'select', targetId: 'scene-1'),
      IntentHistoryEntry(intent: 'edit', targetId: 'scene-1'),
    ]);

    expect(suggestions, const [
      CommandSuggestion(command: 'save', targetId: 'scene-1'),
    ]);
  });

  test('suggestions are safe and never executable automatically', () {
    final suggestions = CommandSuggestionEngine().suggest(const [
      IntentHistoryEntry(intent: 'select', targetId: 'scene-1'),
    ]);

    expect(suggestions.single.command, 'edit');
    expect(suggestions.single.requiresConfirmation, isFalse);
  });

  test('does not suggest destructive commands', () {
    final suggestions = CommandSuggestionEngine().suggest(const [
      IntentHistoryEntry(intent: 'select', targetId: 'scene-1'),
      IntentHistoryEntry(intent: 'delete', targetId: 'scene-1'),
    ]);

    expect(suggestions, isEmpty);
  });
}
