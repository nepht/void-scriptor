import 'dart:math' as math;

class StylusPoint {
  const StylusPoint(this.x, this.y);
  final double x;
  final double y;
}

enum StylusIntent { none, select }

class StylusResult {
  const StylusResult({
    required this.intent,
    required this.confidence,
    required this.annotationMode,
  });
  final StylusIntent intent;
  final double confidence;
  final bool annotationMode;
}

class StylusAdapter {
  const StylusAdapter({this.minimumSize = 8});
  final double minimumSize;

  StylusResult interpret(List<StylusPoint> points) {
    if (points.length < 3) {
      return const StylusResult(
        intent: StylusIntent.none,
        confidence: 0,
        annotationMode: false,
      );
    }
    final start = points.first;
    final end = points.last;
    final width =
        points.map((point) => point.x).reduce(math.max) -
        points.map((point) => point.x).reduce(math.min);
    final height =
        points.map((point) => point.y).reduce(math.max) -
        points.map((point) => point.y).reduce(math.min);
    final distance = math.sqrt(
      math.pow(end.x - start.x, 2) + math.pow(end.y - start.y, 2),
    );
    final closed = distance <= math.max(width, height) * .25;
    final size = math.min(width, height);
    if (!closed || size < minimumSize) {
      return const StylusResult(
        intent: StylusIntent.none,
        confidence: 0,
        annotationMode: false,
      );
    }
    return const StylusResult(
      intent: StylusIntent.select,
      confidence: .85,
      annotationMode: true,
    );
  }
}
