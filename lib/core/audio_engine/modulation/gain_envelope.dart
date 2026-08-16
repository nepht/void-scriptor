/// Linear gain envelope (Step 34.4).
class GainEnvelope {
  const GainEnvelope({
    required this.initial,
    required this.target,
    required this.durationSeconds,
  });

  final double initial;
  final double target;
  final double durationSeconds;

  double valueAt(double time) {
    if (time <= 0) return initial;
    if (time >= durationSeconds) return target;
    final t = time / durationSeconds;
    return initial + (target - initial) * t;
  }
}
