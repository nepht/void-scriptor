import 'dart:math' as math;
import 'dart:typed_data';

/// Rolling-window RMS meter (Step 34.8).
class RmsMeter {
  const RmsMeter();

  double compute(Float32List samples) {
    if (samples.isEmpty) return 0;
    var sumSquares = 0.0;
    for (final s in samples) {
      sumSquares += s * s;
    }
    return math.sqrt(sumSquares / samples.length);
  }
}
