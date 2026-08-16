/// Room-scale transform with bounds (Step 41.9).
class RoomScaleTransform {
  const RoomScaleTransform({
    required this.originX,
    required this.originY,
    required this.originZ,
    required this.width,
    required this.height,
    required this.depth,
  });

  final double originX;
  final double originY;
  final double originZ;
  final double width;
  final double height;
  final double depth;

  bool inBounds(double x, double y, double z) {
    return x >= originX &&
        x <= originX + width &&
        y >= originY &&
        y <= originY + height &&
        z >= originZ &&
        z <= originZ + depth;
  }
}
