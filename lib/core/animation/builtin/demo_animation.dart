import '../track/keyframe.dart';
import '../track/keyframe_track.dart';
import '../easing/easing_curve.dart';
import '../clip/animation_clip.dart';

/// Built-in demo clip proving the animation pipeline end-to-end (Step 33.20).
class DemoAnimation {
  DemoAnimation._();

  static final AnimationClip bounce = AnimationClip(
    name: 'bounce',
    durationSeconds: 2,
    tracks: [
      KeyframeTrack<double>(
        name: 'scale',
        keyframes: const [
          Keyframe(time: 0, value: 1.0),
          Keyframe(time: 1, value: 1.5),
          Keyframe(time: 2, value: 1.0),
        ],
        easing: EasingCurve.easeInOut,
        lerp: (a, b, t) => a + (b - a) * t,
      ),
      KeyframeTrack<double>(
        name: 'rotation',
        keyframes: const [
          Keyframe(time: 0, value: 0.0),
          Keyframe(time: 2, value: 360.0),
        ],
        easing: EasingCurve.linear,
        lerp: (a, b, t) => a + (b - a) * t,
      ),
    ],
  );
}
