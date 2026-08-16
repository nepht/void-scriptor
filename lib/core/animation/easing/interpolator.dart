import 'package:vector_math/vector_math_64.dart';

import '../../render/render_color.dart';

/// Linear interpolation helpers (Step 33.2–33.3).
class Interpolator {
  const Interpolator._();

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;

  static Vector3 lerpVector3(Vector3 a, Vector3 b, double t) => Vector3(
    lerpDouble(a.x, b.x, t),
    lerpDouble(a.y, b.y, t),
    lerpDouble(a.z, b.z, t),
  );

  static RenderColor lerpColor(RenderColor a, RenderColor b, double t) =>
      RenderColor(
        lerpDouble(a.r, b.r, t),
        lerpDouble(a.g, b.g, t),
        lerpDouble(a.b, b.b, t),
        lerpDouble(a.a, b.a, t),
      );
}
