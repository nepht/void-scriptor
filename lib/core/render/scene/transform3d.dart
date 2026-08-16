import 'package:vector_math/vector_math_64.dart';

/// 3D transform: position, rotation (quaternion), scale (Step 32.2).
class Transform3D {
  Transform3D({Vector3? position, Quaternion? rotation, Vector3? scale})
    : position = position ?? Vector3.zero(),
      rotation = rotation ?? Quaternion.identity(),
      scale = scale ?? Vector3(1, 1, 1);

  final Vector3 position;
  final Quaternion rotation;
  final Vector3 scale;

  Matrix4 get matrix => Matrix4.compose(position, rotation, scale);
}
