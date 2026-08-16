import 'package:vector_math/vector_math_64.dart';

import 'renderable.dart';
import '../camera/camera.dart';

/// A single draw command emitted by the pipeline.
class DrawCommand {
  const DrawCommand({required this.renderable, required this.depth});

  final Renderable renderable;
  final double depth;
}

/// Sorted draw list with stats (Step 32.15).
class DrawList {
  DrawList({required this.commands, required this.culledCount});

  final List<DrawCommand> commands;
  final int culledCount;

  int get drawCalls => commands.length;
}

/// Cull → sort → draw pipeline (Step 32.14).
class RenderPipeline {
  const RenderPipeline();

  DrawList render({
    required Camera camera,
    required List<Renderable> renderables,
  }) {
    final visible = <DrawCommand>[];
    var culled = 0;

    for (final renderable in renderables) {
      if (!camera.isInsideFrustum(renderable.center)) {
        culled++;
        continue;
      }
      final depth = _depth(camera, renderable.center);
      visible.add(DrawCommand(renderable: renderable, depth: depth));
    }

    // Back-to-front: greater depth first.
    visible.sort((a, b) => b.depth.compareTo(a.depth));

    return DrawList(commands: visible, culledCount: culled);
  }

  double _depth(Camera camera, Vector3 point) {
    final clip = camera.viewMatrix.transform3(
      Vector3(point.x, point.y, point.z),
    );
    return clip.z.abs();
  }
}
