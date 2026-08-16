/// A single keyframe at a point in time (Step 33.4).
class Keyframe<T> {
  const Keyframe({required this.time, required this.value});

  final double time;
  final T value;
}
