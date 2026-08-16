import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:void_scriptor/core/render/render_color.dart';
import 'package:void_scriptor/core/render/lighting/light.dart';
import 'package:void_scriptor/core/render/lighting/lighting_profile.dart';
import 'package:void_scriptor/core/render/material/material.dart';
import 'package:void_scriptor/core/render/material/material_library.dart';

void main() {
  test('Material holds base/emission/opacity', () {
    const material = Material(
      id: 'm1',
      baseColor: RenderColor(0.8, 0.2, 0.2),
      emission: RenderColor(0.1, 0, 0),
      opacity: 0.9,
    );
    expect(material.id, 'm1');
    expect(material.baseColor.r, 0.8);
    expect(material.opacity, 0.9);
  });

  test('MaterialLibrary registers and looks up', () {
    final library = MaterialLibrary();
    const material = Material(id: 'm1', baseColor: RenderColor(1, 1, 1));
    library.register(material);
    expect(library.lookup('m1'), same(material));
    expect(library.lookup('missing'), isNull);
  });

  test('shade combines material with lighting deterministically', () {
    const material = Material(id: 'm1', baseColor: RenderColor(0.5, 0.5, 0.5));
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
    final shaded = shade(material, profile, Vector3(0, -1, 0));
    // base(0.5) * (ambient 0.2 + directional 1.0) = 0.5 * 1.2 = 0.6
    expect(shaded.r, closeTo(0.6, 1e-6));
    expect(shaded.g, closeTo(0.6, 1e-6));
  });
}
