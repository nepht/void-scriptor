import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/runtime_controls.dart';

void main() {
  test('sandbox permits only registered commands', () {
    final sandbox = IntentSandbox({'select', 'save'});
    expect(sandbox.run('select'), isTrue);
    expect(sandbox.run('delete'), isFalse);
  });

  test('interaction thread and rate control reject overload', () {
    final thread = InteractionThread();
    expect(thread.dispatch('select'), isTrue);
    thread.close();
    expect(thread.dispatch('save'), isFalse);

    final rate = InputRateControl(maxPerWindow: 2);
    expect(rate.accept(), isTrue);
    expect(rate.accept(), isTrue);
    expect(rate.accept(), isFalse);
  });

  test('battery mode reduces processing and trace records resolution', () {
    final battery = BatteryMode();
    battery.setLowPower(true);
    expect(battery.processingBudget, .5);

    final trace = ResolutionTrace();
    trace.record(input: 'voice', resolvedIntent: 'save', confidence: .8);
    expect(trace.entries.single.input, 'voice');
    expect(trace.entries.single.rawPayload, isNull);
  });
}
