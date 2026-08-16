import 'package:vector_math/vector_math_64.dart';

import '../render_color.dart';
import '../lighting/lighting_profile.dart';

/// Material surface properties (Step 32.10).
class Material {
  const Material({
    required this.id,
    required this.baseColor,
    this.emission = const RenderColor(0, 0, 0),
    this.opacity = 1.0,
    this.roughness = 0.5,
    this.textureRef,
  });

  final String id;
  final RenderColor baseColor;
  final RenderColor emission;
  final double opacity;
  final double roughness;
  final String? textureRef;
}

/// Shade a material under a lighting profile (Step 32.12).
RenderColor shade(Material material, LightingProfile profile, Vector3 normal) {
  final ambient = profile.ambientContribution();
  final directional = profile.directionalContribution(normal);
  final lit = RenderColor(
    ambient.r + directional.r,
    ambient.g + directional.g,
    ambient.b + directional.b,
  );
  final base = material.baseColor;
  return RenderColor(
    base.r * lit.r + material.emission.r,
    base.g * lit.g + material.emission.g,
    base.b * lit.b + material.emission.b,
    material.opacity,
  );
}
