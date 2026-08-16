import 'dart:convert';

import 'package:vector_math/vector_math_64.dart';

import '../render_color.dart';
import 'light.dart';

/// Aggregates lights and computes contributions (Step 32.8).
class LightingProfile {
  LightingProfile({
    List<Light>? lights,
    this.fogDensity = 0,
    this.bloomIntensity = 0,
  }) : lights = lights ?? const [];

  final List<Light> lights;
  final double fogDensity;
  final double bloomIntensity;

  RenderColor ambientContribution() {
    var r = 0.0, g = 0.0, b = 0.0;
    for (final light in lights) {
      if (light is AmbientLight) {
        r += light.color.r * light.intensity;
        g += light.color.g * light.intensity;
        b += light.color.b * light.intensity;
      }
    }
    return RenderColor(r, g, b);
  }

  RenderColor directionalContribution(Vector3 normal) {
    var r = 0.0, g = 0.0, b = 0.0;
    for (final light in lights) {
      if (light is DirectionalLight) {
        final lambert = normal
            .normalized()
            .dot(light.direction.normalized())
            .clamp(0.0, 1.0);
        final factor = lambert.toDouble();
        r += light.color.r * light.intensity * factor;
        g += light.color.g * light.intensity * factor;
        b += light.color.b * light.intensity * factor;
      }
    }
    return RenderColor(r, g, b);
  }

  /// Map from `EnvironmentLightingProfiles` DB row (Step 32.9).
  factory LightingProfile.fromEnvironmentRow({
    required String keyLight,
    required String fillLight,
    required String rimLight,
    required String environmentLight,
    required double fogDensity,
    required double bloomIntensity,
  }) {
    final lights = <Light>[];
    _addJsonLights(lights, keyLight);
    _addJsonLights(lights, fillLight);
    _addJsonLights(lights, rimLight);
    _addJsonLights(lights, environmentLight);
    return LightingProfile(
      lights: lights,
      fogDensity: fogDensity,
      bloomIntensity: bloomIntensity,
    );
  }

  static void _addJsonLights(List<Light> out, String json) {
    if (json.trim().isEmpty) return;
    try {
      final map = jsonDecode(json);
      if (map is! Map) return;
      final intensity = (map['intensity'] as num?)?.toDouble() ?? 1.0;
      final color = map['color'];
      final c = color is List
          ? RenderColor(
              (color[0] as num).toDouble(),
              (color[1] as num).toDouble(),
              (color[2] as num).toDouble(),
            )
          : const RenderColor(1, 1, 1);
      out.add(
        DirectionalLight(
          direction: Vector3(0, -1, 0),
          color: c,
          intensity: intensity,
        ),
      );
    } on FormatException {
      // Ignore malformed light JSON.
    }
  }
}
