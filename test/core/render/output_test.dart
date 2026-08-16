import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:void_scriptor/core/render/render_color.dart';
import 'package:void_scriptor/core/render/material/material.dart';
import 'package:void_scriptor/core/render/pipeline/renderable.dart';
import 'package:void_scriptor/core/render/pipeline/render_pipeline.dart';
import 'package:void_scriptor/core/render/camera/camera.dart';
import 'package:void_scriptor/core/render/output/render_pass.dart';
import 'package:void_scriptor/core/render/output/render_frame.dart';
import 'package:void_scriptor/core/render/output/tone_mapper.dart';

void main() {
  Camera camera() => Camera(
    position: Vector3(0, 0, 5),
    target: Vector3(0, 0, 0),
    fovYRadians: 1.0,
    aspect: 16 / 9,
    near: 0.1,
    far: 100,
  );

  test('RenderPass produces a RenderFrame with stats', () {
    const pass = RenderPass();
    final frame = pass.render(
      camera: camera(),
      renderables: [
        Renderable(
          id: 'a',
          center: Vector3(0, 0, 0),
          radius: 1,
          material: const Material(id: 'm', baseColor: RenderColor(1, 1, 1)),
        ),
      ],
      width: 320,
      height: 180,
    );
    expect(frame.width, 320);
    expect(frame.height, 180);
    expect(frame.drawList.drawCalls, 1);
  });

  test('RenderFrame descriptor exposes dimensions and pixel buffer', () {
    final frame = RenderFrame(
      width: 2,
      height: 2,
      drawList: DrawList(commands: const [], culledCount: 0),
      pixels: [
        const RenderColor(1, 0, 0),
        const RenderColor(0, 1, 0),
        const RenderColor(0, 0, 1),
        const RenderColor(1, 1, 1),
      ],
    );
    expect(frame.pixels, hasLength(4));
    expect(frame.pixels.first.r, 1);
  });

  test('ToneMapper applies exposure', () {
    const mapper = ToneMapper(exposure: 2.0);
    const color = RenderColor(0.25, 0.5, 1.0);
    final mapped = mapper.apply(color);
    expect(mapped.r, closeTo(0.5, 1e-6));
    expect(mapped.g, closeTo(1.0, 1e-6));
    expect(mapped.b, closeTo(1.0, 1e-6)); // clamped to 1.0
  });
}
