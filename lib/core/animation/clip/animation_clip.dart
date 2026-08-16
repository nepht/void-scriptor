import '../track/keyframe_track.dart';

enum SamplingMode { clamp, wrap, pingPong }

/// A named animation composed of tracks (Step 33.7).
class AnimationClip {
  AnimationClip({
    required this.name,
    required this.durationSeconds,
    required List<KeyframeTrack> tracks,
  }) : tracks = List.unmodifiable(tracks) {
    if (durationSeconds < 0) {
      throw ArgumentError.value(durationSeconds, 'durationSeconds', 'negative');
    }
  }

  final String name;
  final double durationSeconds;
  final List<KeyframeTrack> tracks;

  /// Sample all tracks at [time] into a pose map (Step 33.8).
  Map<String, Object> evaluate(
    double time, {
    SamplingMode mode = SamplingMode.clamp,
  }) {
    final t = _resolveTime(time, mode);
    final pose = <String, Object>{};
    for (final track in tracks) {
      pose[track.name] = track.evaluate(t);
    }
    return pose;
  }

  double _resolveTime(double time, SamplingMode mode) {
    if (durationSeconds <= 0) return 0;
    switch (mode) {
      case SamplingMode.clamp:
        return time.clamp(0.0, durationSeconds).toDouble();
      case SamplingMode.wrap:
        return time % durationSeconds;
      case SamplingMode.pingPong:
        final period = durationSeconds * 2;
        final m = time % period;
        return m <= durationSeconds ? m : period - m;
    }
  }
}
