import '../clip/animation_clip.dart';

enum AnimationState { playing, paused, stopped }

enum LoopMode { once, loop, pingPong }

/// Playback state machine (Step 33.10–33.12).
class AnimationPlayer {
  AnimationPlayer({required this.clip, this.loopMode = LoopMode.once});

  final AnimationClip clip;
  final LoopMode loopMode;

  AnimationState _state = AnimationState.stopped;
  double _time = 0;

  AnimationState get state => _state;
  double get currentTime => _time;

  void play() => _state = AnimationState.playing;

  void pause() {
    if (_state == AnimationState.playing) {
      _state = AnimationState.paused;
    }
  }

  void stop() {
    _state = AnimationState.stopped;
    _time = 0;
  }

  void seek(double time) {
    _time = time.clamp(0.0, clip.durationSeconds).toDouble();
  }

  void advance(double deltaSeconds) {
    if (_state != AnimationState.playing) return;
    _time += deltaSeconds;
    switch (loopMode) {
      case LoopMode.once:
        if (_time >= clip.durationSeconds) {
          _time = clip.durationSeconds;
          _state = AnimationState.stopped;
        }
      case LoopMode.loop:
        if (clip.durationSeconds > 0) {
          _time %= clip.durationSeconds;
        }
      case LoopMode.pingPong:
        if (clip.durationSeconds > 0) {
          final period = clip.durationSeconds * 2;
          final m = _time % period;
          _time = m <= clip.durationSeconds ? m : period - m;
        }
    }
  }

  Map<String, Object> get currentPose => clip.evaluate(_time);
}
