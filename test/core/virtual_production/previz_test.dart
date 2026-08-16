import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:void_scriptor/core/render/pipeline/renderable.dart';
import 'package:void_scriptor/core/render/camera/camera.dart';
import 'package:void_scriptor/core/render/material/material.dart';
import 'package:void_scriptor/core/render/render_color.dart';
import 'package:void_scriptor/core/virtual_production/previz/previz_scene.dart';

void main() {
  test('PrevizScene renders draw list via pipeline', () {
    final scene = PrevizScene(
      renderables: [
        Renderable(
          id: 'actor',
          center: Vector3(0, 0, 0),
          radius: 1,
          material: const Material(id: 'm', baseColor: RenderColor(1, 1, 1)),
        ),
      ],
      camera: Camera(
        position: Vector3(0, 0, 10),
        target: Vector3(0, 0, 0),
        fovYRadians: 1.0,
        aspect: 1.5,
        near: 0.1,
        far: 100,
      ),
    );
    final drawList = scene.evaluate(0);
    expect(drawList.drawCalls, 1);
  });

  test('PrevizScene reports coverage', () {
    final scene = PrevizScene(
      renderables: const [],
      camera: Camera(
        position: Vector3(0, 0, 10),
        target: Vector3(0, 0, 0),
        fovYRadians: 1.0,
        aspect: 1.5,
        near: 0.1,
        far: 100,
      ),
    );
    expect(scene.evaluate(0).drawCalls, 0);
    expect(scene.hasCoverage, isFalse);
  });
}
