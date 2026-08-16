import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/audio_engine/modulation/gain_envelope.dart';
import 'package:void_scriptor/core/audio_engine/modulation/lfo.dart';
import 'package:void_scriptor/core/audio_engine/modulation/automation_curve.dart';

void main() {
  test('GainEnvelope linear ramp', () {
    final env = GainEnvelope(initial: 0, target: 1, durationSeconds: 1);
    expect(env.valueAt(0), closeTo(0, 1e-6));
    expect(env.valueAt(0.5), closeTo(0.5, 1e-6));
    expect(env.valueAt(1), closeTo(1, 1e-6));
    expect(env.valueAt(2), closeTo(1, 1e-6)); // holds target
  });

  test('LFO sine oscillates around center', () {
    const lfo = LFO(rateHz: 1, depth: 1, center: 0, shape: LfoShape.sine);
    expect(lfo.valueAt(0), closeTo(0, 1e-6));
    expect(lfo.valueAt(0.25), closeTo(1, 1e-6));
    expect(lfo.valueAt(0.5), closeTo(0, 1e-6));
    expect(lfo.valueAt(0.75), closeTo(-1, 1e-6));
  });

  test('LFO square flips sign', () {
    const lfo = LFO(rateHz: 1, depth: 1, center: 0, shape: LfoShape.square);
    expect(lfo.valueAt(0.1), closeTo(1, 1e-6));
    expect(lfo.valueAt(0.6), closeTo(-1, 1e-6));
  });

  test('AutomationCurve linear segments', () {
    final curve = AutomationCurve(
      points: const [
        CurvePoint(time: 0, value: 0),
        CurvePoint(time: 1, value: 10),
        CurvePoint(time: 2, value: 0),
      ],
      interpolation: CurveInterpolation.linear,
    );
    expect(curve.valueAt(0.5), closeTo(5, 1e-6));
    expect(curve.valueAt(1.5), closeTo(5, 1e-6));
    expect(curve.valueAt(0), closeTo(0, 1e-6));
    expect(curve.valueAt(2), closeTo(0, 1e-6));
  });
}
