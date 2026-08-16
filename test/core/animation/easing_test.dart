import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:void_scriptor/core/animation/easing/easing_curve.dart';
import 'package:void_scriptor/core/animation/easing/interpolator.dart';
import 'package:void_scriptor/core/render/render_color.dart';

void main() {
  test('EasingCurve.linear is identity', () {
    expect(EasingCurve.linear.apply(0.5), closeTo(0.5, 1e-6));
  });

  test('EasingCurve.easeIn/out endpoints', () {
    expect(EasingCurve.easeIn.apply(0), closeTo(0, 1e-6));
    expect(EasingCurve.easeIn.apply(1), closeTo(1, 1e-6));
    expect(EasingCurve.easeOut.apply(0), closeTo(0, 1e-6));
    expect(EasingCurve.easeOut.apply(1), closeTo(1, 1e-6));
    expect(EasingCurve.easeInOut.apply(0), closeTo(0, 1e-6));
    expect(EasingCurve.easeInOut.apply(1), closeTo(1, 1e-6));
  });

  test('Interpolator scalar lerp', () {
    expect(Interpolator.lerpDouble(0, 10, 0.5), closeTo(5, 1e-6));
  });

  test('Interpolator vector lerp', () {
    final a = Vector3(0, 0, 0);
    final b = Vector3(10, 10, 10);
    final mid = Interpolator.lerpVector3(a, b, 0.5);
    expect(mid.x, closeTo(5, 1e-6));
    expect(mid.y, closeTo(5, 1e-6));
    expect(mid.z, closeTo(5, 1e-6));
  });

  test('Interpolator color lerp', () {
    const a = RenderColor(0, 0, 0);
    const b = RenderColor(1, 1, 1);
    final mid = Interpolator.lerpColor(a, b, 0.5);
    expect(mid.r, closeTo(0.5, 1e-6));
    expect(mid.g, closeTo(0.5, 1e-6));
    expect(mid.b, closeTo(0.5, 1e-6));
  });
}
