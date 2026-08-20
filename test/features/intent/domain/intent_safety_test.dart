import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/intent_safety.dart';

void main() {
  test('requires confirmation for destructive intent', () {
    const safety = IntentSafety();
    final result = safety.evaluate(const SafetyRequest(intent: 'delete'));

    expect(result.isDestructive, isTrue);
    expect(result.requiresConfirmation, isTrue);
    expect(result.isAllowed, isFalse);
  });

  test('allows destructive intent only after explicit confirmation', () {
    const safety = IntentSafety();
    final result = safety.evaluate(
      const SafetyRequest(intent: 'delete', confirmed: true),
    );

    expect(result.isAllowed, isTrue);
  });

  test('undo is a safe non-destructive intent', () {
    const safety = IntentSafety();
    final result = safety.evaluate(const SafetyRequest(intent: 'undo'));

    expect(result.isDestructive, isFalse);
    expect(result.isUndo, isTrue);
    expect(result.isAllowed, isTrue);
  });
}
