import '../camera/camera.dart';
import '../pipeline/renderable.dart';
import '../pipeline/render_pipeline.dart';
import 'render_frame.dart';
import 'tone_mapper.dart';

/// Executes a render pass: scene + camera → frame (Step 32.16).
class RenderPass {
  const RenderPass({
    this.pipeline = const RenderPipeline(),
    this.tonemapper = const ToneMapper(),
  });

  final RenderPipeline pipeline;
  final ToneMapper tonemapper;

  RenderFrame render({
    required Camera camera,
    required List<Renderable> renderables,
    required int width,
    required int height,
  }) {
    final drawList = pipeline.render(camera: camera, renderables: renderables);
    return RenderFrame(width: width, height: height, drawList: drawList);
  }
}
