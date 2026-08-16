import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/animation/track/keyframe.dart';
import 'package:void_scriptor/core/animation/track/keyframe_track.dart';
import 'package:void_scriptor/core/animation/easing/easing_curve.dart';
import 'package:void_scriptor/core/animation/clip/animation_clip.dart';
import 'package:void_scriptor/core/animation/playback/animation_player.dart';

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

  test('player starts stopped and advances with play', () {
    final player = AnimationPlayer(clip: makeClip());
    expect(player.state, AnimationState.stopped);
    expect(player.currentTime, 0);

    player.play();
    expect(player.state, AnimationState.playing);

    player.advance(0.5);
    expect(player.currentTime, closeTo(0.5, 1e-6));
  });

  test('pause freezes time, seek jumps', () {
    final player = AnimationPlayer(clip: makeClip());
    player.play();
    player.advance(1.0);
    player.pause();
    expect(player.state, AnimationState.paused);

    player.seek(1.5);
    expect(player.currentTime, closeTo(1.5, 1e-6));
  });

  test('loop mode wraps at duration', () {
    final player = AnimationPlayer(clip: makeClip(), loopMode: LoopMode.loop);
    player.play();
    player.advance(2.5); // wraps to 0.5
    expect(player.currentTime, closeTo(0.5, 1e-6));
  });

  test('once mode stops at duration', () {
    final player = AnimationPlayer(clip: makeClip(), loopMode: LoopMode.once);
    player.play();
    player.advance(3.0);
    expect(player.state, AnimationState.stopped);
    expect(player.currentTime, closeTo(2.0, 1e-6));
  });
}
