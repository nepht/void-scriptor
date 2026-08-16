import 'package:vector_math/vector_math_64.dart';

/// Perspective camera with viewport projection (Step 32.4).
class Camera {
  Camera({
    required this.position,
    required this.target,
    Vector3? up,
    required this.fovYRadians,
    required this.aspect,
    required this.near,
    required this.far,
  }) : up = up ?? Vector3(0, 1, 0);

  final Vector3 position;
  final Vector3 target;
  final Vector3 up;
  final double fovYRadians;
  final double aspect;
  final double near;
  final double far;

  Matrix4 get viewMatrix => makeViewMatrix(position, target, up);

  Matrix4 get projectionMatrix =>
      makePerspectiveMatrix(fovYRadians, aspect, near, far);

  Matrix4 get viewProjectionMatrix => projectionMatrix * viewMatrix;

  /// Project a world-space point to pixel coordinates (Step 32.5).
  Vector2 project(Vector3 world, double width, double height) {
    final clip = Vector4(world.x, world.y, world.z, 1.0);
    final transformed = viewProjectionMatrix.transform(clip);
    if (transformed.w <= 0) {
      // Behind camera: return off-screen sentinel.
      return Vector2(double.nan, double.nan);
    }
    final ndc = Vector3(
      transformed.x / transformed.w,
      transformed.y / transformed.w,
      transformed.z / transformed.w,
    );
    return Vector2(
      (ndc.x * 0.5 + 0.5) * width,
      (1.0 - (ndc.y * 0.5 + 0.5)) * height,
    );
  }

  /// Frustum containment test via clip-space bounds (Step 32.6).
  bool isInsideFrustum(Vector3 world) {
    final clip = Vector4(world.x, world.y, world.z, 1.0);
    final transformed = viewProjectionMatrix.transform(clip);
    final w = transformed.w;
    if (w <= 0) return false;
    const bound = 1.0;
    return transformed.x.abs() <= bound * w.abs() &&
        transformed.y.abs() <= bound * w.abs() &&
        transformed.z.abs() <= bound * w.abs();
  }
}

/// Distance-based level-of-detail selection (Step 32.6).
class LodSelector {
  const LodSelector._();

  static int levelFor({required double distance, required List<double> radii}) {
    for (var i = 0; i < radii.length; i++) {
      if (distance <= radii[i]) return i;
    }
    return radii.length;
  }
}
