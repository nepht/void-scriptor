import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/bci_adapter.dart';

void main() {
  test('requires consent before accepting BCI signal', () {
    const adapter = BciAdapter(hardwareAvailable: true);
    final result = adapter.interpret(
      const BciSignal(intent: 'focus', confidence: .95),
    );

    expect(result.accepted, isFalse);
    expect(result.reason, BciRejectionReason.consentRequired);
  });

  test('accepts a safe BCI signal with consent and hardware', () {
    const adapter = BciAdapter(hardwareAvailable: true, consentGranted: true);
    final result = adapter.interpret(
      const BciSignal(intent: 'focus', confidence: .95),
    );

    expect(result.accepted, isTrue);
    expect(result.intent, 'focus');
  });

  test('rejects BCI when hardware is unavailable', () {
    const adapter = BciAdapter(consentGranted: true);
    final result = adapter.interpret(
      const BciSignal(intent: 'focus', confidence: .95),
    );

    expect(result.accepted, isFalse);
    expect(result.reason, BciRejectionReason.hardwareUnavailable);
  });
}
