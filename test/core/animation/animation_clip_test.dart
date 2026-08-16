import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/animation/track/keyframe.dart';
import 'package:void_scriptor/core/animation/track/keyframe_track.dart';
import 'package:void_scriptor/core/animation/easing/easing_curve.dart';
import 'package:void_scriptor/core/animation/clip/animation_clip.dart';

void main() {
  AnimationClip makeClip() => AnimationClip(
    name: 'walk',
    durationSeconds: 2,
    tracks: [
      KeyframeTrack<double>(
        name: 'x',
        keyframes: const [
          Keyframe(time: 0, value: 0),
          Keyframe(time: 2, value: 20),
        ],
        easing: EasingCurve.linear,
        lerp: (a, b, t) => a + (b - a) * t,
      ),
    ],
  );

  test('AnimationClip exposes tracks and duration', () {
    final clip = makeClip();
    expect(clip.name, 'walk');
    expect(clip.durationSeconds, 2);
    expect(clip.tracks, hasLength(1));
  });

  test('evaluate returns pose map of sampled values', () {
    final clip = makeClip();
    final pose = clip.evaluate(1.0);
    expect(pose.keys, contains('x'));
    expect(pose['x'], closeTo(10, 1e-6));
  });

  test('wrap and clamp sampling modes', () {
    final clip = makeClip();
    // clamp: beyond duration returns last value
    expect(clip.evaluate(5, mode: SamplingMode.clamp)['x'], closeTo(20, 1e-6));
    // wrap: 2.5s wraps to 0.5s
    expect(clip.evaluate(2.5, mode: SamplingMode.wrap)['x'], closeTo(5, 1e-6));
  });
}
