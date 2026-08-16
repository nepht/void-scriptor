import 'package:vector_math/vector_math_64.dart';

import '../material/material.dart';

/// A drawable object with a bounding sphere (Step 32.13).
class Renderable {
  const Renderable({
    required this.id,
    required this.center,
    required this.radius,
    required this.material,
  });

  final String id;
  final Vector3 center;
  final double radius;
  final Material material;
}
