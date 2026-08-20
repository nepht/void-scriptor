import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/intent_history.dart';

void main() {
  test('keeps newest intent first and strips raw payload', () {
    final history = IntentHistory(maxEntries: 3);

    history.add(
      const IntentRecord(
        intent: 'select',
        targetId: 'scene-1',
        payload: 'secret raw input',
      ),
    );
    history.add(const IntentRecord(intent: 'edit', targetId: 'scene-1'));

    expect(history.entries.first.intent, 'edit');
    expect(history.entries.last.payload, isNull);
    expect(history.entries.map((entry) => entry.targetId), [
      'scene-1',
      'scene-1',
    ]);
  });

  test('bounds history and can clear it', () {
    final history = IntentHistory(maxEntries: 2);

    history.add(const IntentRecord(intent: 'select', targetId: 'one'));
    history.add(const IntentRecord(intent: 'edit', targetId: 'two'));
    history.add(const IntentRecord(intent: 'save', targetId: 'three'));

    expect(history.entries.map((entry) => entry.targetId), ['three', 'two']);

    history.clear();
    expect(history.entries, isEmpty);
  });

  test('rejects invalid max entries', () {
    expect(() => IntentHistory(maxEntries: 0), throwsArgumentError);
  });
}
