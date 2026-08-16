import 'dart:math' as math;

/// Easing curve functions (Step 33.1).
enum EasingCurve {
  linear,
  easeIn,
  easeOut,
  easeInOut;

  double apply(double t) {
    final x = t.clamp(0.0, 1.0).toDouble();
    return switch (this) {
      linear => x,
      easeIn => x * x,
      easeOut => 1 - (1 - x) * (1 - x),
      easeInOut => x < 0.5 ? 2 * x * x : 1 - math.pow(-2 * x + 2, 2) / 2,
    };
  }
}
