import 'package:vector_math/vector_math_64.dart';

import '../render_color.dart';

/// Light types (Step 32.7).
sealed class Light {
  const Light({required this.color, required this.intensity});

  final RenderColor color;
  final double intensity;
}

class AmbientLight extends Light {
  const AmbientLight({required super.color, required super.intensity});
}

class DirectionalLight extends Light {
  const DirectionalLight({
    required this.direction,
    required super.color,
    required super.intensity,
  });

  final Vector3 direction;
}

class PointLight extends Light {
  const PointLight({
    required this.position,
    required super.color,
    required super.intensity,
    this.range = 10,
  });

  final Vector3 position;
  final double range;
}
