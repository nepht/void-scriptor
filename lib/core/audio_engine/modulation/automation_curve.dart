import 'dart:math' as math;

enum CurveInterpolation { linear, exponential }

class CurvePoint {
  const CurvePoint({required this.time, required this.value});
  final double time;
  final double value;
}

/// Piecewise automation curve (Step 34.6).
class AutomationCurve {
  AutomationCurve({
    required List<CurvePoint> points,
    this.interpolation = CurveInterpolation.linear,
  }) : points = List.unmodifiable(points) {
    for (var i = 1; i < this.points.length; i++) {
      if (this.points[i].time < this.points[i - 1].time) {
        throw ArgumentError('points must be sorted by time');
      }
    }
  }

  final List<CurvePoint> points;
  final CurveInterpolation interpolation;

  double valueAt(double time) {
    if (points.isEmpty) return 0;
    if (time <= points.first.time) return points.first.value;
    if (time >= points.last.time) return points.last.value;

    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      if (time >= a.time && time <= b.time) {
        final span = b.time - a.time;
        final raw = span == 0 ? 0.0 : (time - a.time) / span;
        switch (interpolation) {
          case CurveInterpolation.linear:
            return a.value + (b.value - a.value) * raw;
          case CurveInterpolation.exponential:
            if (a.value <= 0 || b.value <= 0) {
              return a.value + (b.value - a.value) * raw;
            }
            final ratio = b.value / a.value;
            return a.value * math.pow(ratio, raw).toDouble();
        }
      }
    }
    return points.last.value;
  }
}
