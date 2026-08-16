import '../easing/easing_curve.dart';
import 'keyframe.dart';

typedef Lerp<T> = T Function(T a, T b, double t);

/// A single animated property track (Step 33.5).
class KeyframeTrack<T> {
  KeyframeTrack({
    required this.name,
    required List<Keyframe<T>> keyframes,
    this.easing = EasingCurve.linear,
    required this.lerp,
  }) : keyframes = List.unmodifiable(keyframes) {
    for (var i = 1; i < this.keyframes.length; i++) {
      if (this.keyframes[i].time < this.keyframes[i - 1].time) {
        throw ArgumentError('keyframes must be sorted by time');
      }
    }
  }

  final String name;
  final List<Keyframe<T>> keyframes;
  final EasingCurve easing;
  final Lerp<T> lerp;

  /// Evaluate the track value at [time], clamping outside range (Step 33.5).
  T evaluate(double time) {
    if (keyframes.isEmpty) {
      throw StateError('cannot evaluate an empty track');
    }
    if (time <= keyframes.first.time) return keyframes.first.value;
    if (time >= keyframes.last.time) return keyframes.last.value;

    for (var i = 0; i < keyframes.length - 1; i++) {
      final a = keyframes[i];
      final b = keyframes[i + 1];
      if (time >= a.time && time <= b.time) {
        final span = b.time - a.time;
        final raw = span == 0 ? 0.0 : (time - a.time) / span;
        final eased = easing.apply(raw);
        return lerp(a.value, b.value, eased);
      }
    }
    return keyframes.last.value;
  }
}
