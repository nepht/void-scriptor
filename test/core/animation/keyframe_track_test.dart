import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/animation/track/keyframe.dart';
import 'package:void_scriptor/core/animation/track/keyframe_track.dart';
import 'package:void_scriptor/core/animation/easing/easing_curve.dart';

void main() {
  test('Keyframe holds time and value', () {
    const key = Keyframe<double>(time: 1.0, value: 42.0);
    expect(key.time, 1.0);
    expect(key.value, 42.0);
  });

  test('KeyframeTrack evaluates scalar between keyframes', () {
    final track = KeyframeTrack<double>(
      name: 'x',
      keyframes: const [
        Keyframe(time: 0, value: 0),
        Keyframe(time: 1, value: 10),
      ],
      easing: EasingCurve.linear,
      lerp: (a, b, t) => a + (b - a) * t,
    );
    expect(track.evaluate(0), closeTo(0, 1e-6));
    expect(track.evaluate(0.5), closeTo(5, 1e-6));
    expect(track.evaluate(1), closeTo(10, 1e-6));
  });

  test('KeyframeTrack clamps outside range', () {
    final track = KeyframeTrack<double>(
      name: 'x',
      keyframes: const [
        Keyframe(time: 0, value: 0),
        Keyframe(time: 1, value: 10),
      ],
      easing: EasingCurve.linear,
      lerp: (a, b, t) => a + (b - a) * t,
    );
    expect(track.evaluate(-1), closeTo(0, 1e-6));
    expect(track.evaluate(2), closeTo(10, 1e-6));
  });

  test('KeyframeTrack validates sorted unique times', () {
    expect(
      () => KeyframeTrack<double>(
        name: 'x',
        keyframes: const [
          Keyframe(time: 1, value: 10),
          Keyframe(time: 0, value: 0),
        ],
        easing: EasingCurve.linear,
        lerp: (a, b, t) => a + (b - a) * t,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
