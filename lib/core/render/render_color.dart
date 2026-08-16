/// RGBA color with double channels (const-friendly, Step 32.10 helper).
class RenderColor {
  const RenderColor(this.r, this.g, this.b, [this.a = 1.0]);

  final double r;
  final double g;
  final double b;
  final double a;

  RenderColor operator +(RenderColor other) =>
      RenderColor(r + other.r, g + other.g, b + other.b, (a + other.a) / 2);

  RenderColor scale(double factor) =>
      RenderColor(r * factor, g * factor, b * factor, a);

  @override
  String toString() => 'RenderColor($r,$g,$b,$a)';
}
