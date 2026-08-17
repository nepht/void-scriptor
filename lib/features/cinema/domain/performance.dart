/// Sprint 48 — Step 48.19–48.26 Performance Tracks, Facial Rig.
class PerformanceCurve {
  const PerformanceCurve({required this.id, required this.points});

  final String id;
  final Map<double, double> points;

  double sample(double t) {
    final sorted = points.keys.toList()..sort();
    if (t <= sorted.first) return points[sorted.first]!;
    if (t >= sorted.last) return points[sorted.last]!;
    for (var i = 0; i < sorted.length - 1; i++) {
      final t0 = sorted[i];
      final t1 = sorted[i + 1];
      if (t >= t0 && t <= t1) {
        final v0 = points[t0]!;
        final v1 = points[t1]!;
        if (t1 == t0) return v0;
        final fraction = (t - t0) / (t1 - t0);
        return v0 + (v1 - v0) * fraction;
      }
    }
    return points[sorted.last]!;
  }
}

class FacialRig {
  const FacialRig({
    required this.id,
    required this.characterId,
    this.microExpressions = const [],
  });

  final String id;
  final String characterId;
  final List<MicroExpression> microExpressions;
}

class MicroExpression {
  const MicroExpression({
    required this.id,
    required this.name,
    required this.durationMs,
  });

  final String id;
  final String name;
  final int durationMs;
}
