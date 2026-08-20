import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/input_safety_api.dart';

void main() {
  test('blocks accidental action until a deliberate trigger is confirmed', () {
    final safety = InputSafetyPolicy();
    expect(safety.allow('save', confidence: .8, deliberate: false), isFalse);
    expect(safety.allow('save', confidence: .8, deliberate: true), isTrue);
  });

  test('uses per-action confidence thresholds', () {
    final safety = InputSafetyPolicy(thresholds: {'delete': .95});
    expect(safety.allow('delete', confidence: .9, deliberate: true), isFalse);
    expect(
      safety.allow(
        'delete',
        confidence: .95,
        deliberate: true,
        confirmed: true,
      ),
      isTrue,
    );
  });

  test('cancel gesture cancels pending input and capability is explicit', () {
    final safety = InputSafetyPolicy();
    safety.beginPending('save');
    expect(safety.cancel(CancelGesture.escape), isTrue);
    expect(safety.pendingCommand, isNull);
    expect(DeviceCapability.touch.supports('tap'), isTrue);
    expect(DeviceCapability.bci.supports('tap'), isFalse);
  });
}
