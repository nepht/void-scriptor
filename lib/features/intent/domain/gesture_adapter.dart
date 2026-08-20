import 'dart:math' as math;

class GesturePoint {
  const GesturePoint(this.x, this.y);
  final double x;
  final double y;
}

enum GestureType { none, swipeLeft, swipeRight, swipeUp, swipeDown }

class GestureResult {
  const GestureResult({
    required this.type,
    required this.confidence,
    required this.minimumConfidence,
  });
  final GestureType type;
  final double confidence;
  final double minimumConfidence;
  bool get isActionable =>
      type != GestureType.none && confidence >= minimumConfidence;
}

class GestureAdapter {
  const GestureAdapter({this.deadZone = 12, this.minimumConfidence = .55});

  final double deadZone;
  final double minimumConfidence;

  GestureResult recognize(List<GesturePoint> points) {
    if (points.length < 2) {
      return const GestureResult(
        type: GestureType.none,
        confidence: 0,
        minimumConfidence: 0.55,
      );
    }
    final start = points.first;
    final end = points.last;
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance <= deadZone) {
      return const GestureResult(
        type: GestureType.none,
        confidence: 0,
        minimumConfidence: 0.55,
      );
    }
    final horizontal = dx.abs() >= dy.abs();
    final type = horizontal
        ? (dx >= 0 ? GestureType.swipeRight : GestureType.swipeLeft)
        : (dy >= 0 ? GestureType.swipeDown : GestureType.swipeUp);
    final confidence = (distance / (deadZone * 6)).clamp(0.0, 1.0);
    return GestureResult(
      type: type,
      confidence: confidence,
      minimumConfidence: minimumConfidence,
    );
  }
}
