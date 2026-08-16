import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:void_scriptor/core/render/render_color.dart';
import 'package:void_scriptor/core/render/material/material.dart';
import 'package:void_scriptor/core/render/pipeline/renderable.dart';
import 'package:void_scriptor/core/render/pipeline/render_pipeline.dart';
import 'package:void_scriptor/core/render/camera/camera.dart';

void main() {
  Camera camera() => Camera(
    position: Vector3(0, 0, 5),
    target: Vector3(0, 0, 0),
    fovYRadians: 1.0,
    aspect: 16 / 9,
    near: 0.1,
    far: 100,
  );

  Renderable makeRenderable(String id, Vector3 position, double radius) =>
      Renderable(
        id: id,
        center: position,
        radius: radius,
        material: Material(id: 'm', baseColor: const RenderColor(1, 1, 1)),
      );

  test('Renderable exposes bounds and material', () {
    final r = makeRenderable('a', Vector3(0, 0, 0), 1.0);
    expect(r.id, 'a');
    expect(r.radius, 1.0);
    expect(r.material.id, 'm');
  });

  test('RenderPipeline culls off-screen and sorts by depth', () {
    final pipeline = RenderPipeline();
    final inFrustum = makeRenderable('in', Vector3(0, 0, 0), 1.0);
    final behind = makeRenderable('behind', Vector3(0, 0, 50), 1.0);

    final drawList = pipeline.render(
      camera: camera(),
      renderables: [inFrustum, behind],
    );

    expect(drawList.culledCount, 1); // behind camera
    expect(drawList.drawCalls, 1);
    expect(drawList.commands.single.renderable.id, 'in');
  });

  test('RenderPipeline sorts back-to-front by depth', () {
    final pipeline = RenderPipeline();
    final near = makeRenderable('near', Vector3(0, 0, -1), 1.0);
    final far = makeRenderable('far', Vector3(0, 0, -3), 1.0);

    final drawList = pipeline.render(
      camera: camera(),
      renderables: [far, near],
    );
    expect(drawList.commands.first.renderable.id, 'far');
    expect(drawList.commands.last.renderable.id, 'near');
  });
}
