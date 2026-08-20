import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/input_calibration.dart';
import 'package:void_scriptor/features/intent/domain/labs_ui_state.dart';
import 'package:void_scriptor/features/intent/domain/input_monitor.dart';
import 'package:void_scriptor/features/intent/domain/latency_monitor.dart';

void main() {
  test('calibration requires enough samples and returns normalized result', () {
    final calibration = InputCalibration(requiredSamples: 2);
    expect(calibration.complete, isFalse);
    calibration.addSample(0.2);
    calibration.addSample(0.8);
    expect(calibration.complete, isTrue);
    expect(calibration.normalized, closeTo(.5, .001));
  });

  test('Labs UI state is opt-in and input monitor does not retain payload', () {
    final ui = LabsUiState();
    expect(ui.isVisible, isFalse);
    ui.toggle();
    expect(ui.isVisible, isTrue);

    final monitor = InputMonitor();
    monitor.record(kind: 'voice', confidence: .9, payload: 'secret');
    expect(monitor.events.single.payload, isNull);
  });

  test('latency monitor reports average latency', () {
    final monitor = LatencyMonitor();
    monitor.record(const Duration(milliseconds: 10));
    monitor.record(const Duration(milliseconds: 30));
    expect(monitor.average, const Duration(milliseconds: 20));
  });
}
