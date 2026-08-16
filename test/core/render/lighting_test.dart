import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:void_scriptor/core/render/render_color.dart';
import 'package:void_scriptor/core/render/lighting/light.dart';
import 'package:void_scriptor/core/render/lighting/lighting_profile.dart';

void main() {
  test('DirectionalLight has direction and color', () {
    final light = DirectionalLight(
      direction: Vector3(0, -1, 0),
      color: const RenderColor(1, 1, 1),
      intensity: 1.5,
    );
    expect(light.direction.y, -1);
    expect(light.color.r, 1);
    expect(light.intensity, 1.5);
  });

  test('LightingProfile aggregates lights and computes contribution', () {
    final profile = LightingProfile(
      lights: [
        const AmbientLight(color: RenderColor(0.2, 0.2, 0.2), intensity: 1.0),
        DirectionalLight(
          direction: Vector3(0, -1, 0),
          color: const RenderColor(1, 1, 1),
          intensity: 1.0,
        ),
      ],
    );
    final ambient = profile.ambientContribution();
    expect(ambient.r, closeTo(0.2, 1e-6));
    final dir = profile.directionalContribution(Vector3(0, -1, 0));
    expect(dir.r, closeTo(1.0, 1e-6));
  });

  test('LightingProfile.fromEnvironmentRow maps DB row fields', () {
    final profile = LightingProfile.fromEnvironmentRow(
      keyLight: '{"intensity":1.0}',
      fillLight: '{"intensity":0.5}',
      rimLight: '{"intensity":0.7}',
      environmentLight: '',
      fogDensity: 0.1,
      bloomIntensity: 0.8,
    );
    expect(profile.fogDensity, 0.1);
    expect(profile.bloomIntensity, 0.8);
    expect(profile.lights.length, greaterThanOrEqualTo(1));
  });
}
