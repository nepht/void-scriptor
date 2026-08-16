import '../render_color.dart';
import '../pipeline/render_pipeline.dart';

/// A rendered framebuffer descriptor (Step 32.17).
class RenderFrame {
  RenderFrame({
    required this.width,
    required this.height,
    required this.drawList,
    List<RenderColor>? pixels,
  }) : pixels = pixels ?? const [];

  final int width;
  final int height;
  final DrawList drawList;
  final List<RenderColor> pixels;
}
