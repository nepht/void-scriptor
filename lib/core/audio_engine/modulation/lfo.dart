import 'dart:math' as math;

enum LfoShape { sine, square, triangle }

/// Low-frequency oscillator (Step 34.5).
class LFO {
  const LFO({
    required this.rateHz,
    required this.depth,
    required this.center,
    this.shape = LfoShape.sine,
  });

  final double rateHz;
  final double depth;
  final double center;
  final LfoShape shape;

  double valueAt(double time) {
    final phase = (time * rateHz) % 1.0;
    final wave = switch (shape) {
      LfoShape.sine => math.sin(phase * 2 * math.pi),
      LfoShape.square => phase < 0.5 ? 1.0 : -1.0,
      LfoShape.triangle => phase < 0.5 ? 4 * phase - 1 : 3 - 4 * phase,
    };
    return center + depth * wave;
  }
}
