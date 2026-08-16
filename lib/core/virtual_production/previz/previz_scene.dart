import '../../render/pipeline/renderable.dart';
import '../../render/pipeline/render_pipeline.dart';
import '../../render/camera/camera.dart';

/// Previz scene: renderables + camera → draw list (Step 35.4–35.6).
class PrevizScene {
  const PrevizScene({
    required this.renderables,
    required this.camera,
    this.pipeline = const RenderPipeline(),
  });

  final List<Renderable> renderables;
  final Camera camera;
  final RenderPipeline pipeline;

  DrawList evaluate(double timeSeconds) =>
      pipeline.render(camera: camera, renderables: renderables);

  bool get hasCoverage => renderables.isNotEmpty;
}
