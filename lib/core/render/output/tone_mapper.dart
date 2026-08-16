import '../render_color.dart';

/// Exposure tone mapping with clamp (Step 32.18).
class ToneMapper {
  const ToneMapper({this.exposure = 1.0});

  final double exposure;

  RenderColor apply(RenderColor color) {
    double clamp01(double v) => v.clamp(0.0, 1.0).toDouble();
    return RenderColor(
      clamp01(color.r * exposure),
      clamp01(color.g * exposure),
      clamp01(color.b * exposure),
      color.a,
    );
  }
}
