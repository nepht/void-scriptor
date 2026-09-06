enum LidarResult { started, unavailable, stopped }

class LidarCapability {
  const LidarCapability({
    required this.id,
    required this.minRangeMeters,
    required this.maxRangeMeters,
    required this.maxPoints,
  });

  final String id;
  final double minRangeMeters;
  final double maxRangeMeters;
  final int maxPoints;

  bool get isValid =>
      id.trim().isNotEmpty &&
      minRangeMeters >= 0 &&
      maxRangeMeters > minRangeMeters &&
      maxPoints > 0;
}

class LidarPoint {
  const LidarPoint({required this.x, required this.y, required this.z});

  final double x;
  final double y;
  final double z;
}

class LidarBounds {
  const LidarBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.minZ,
    required this.maxZ,
  });

  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final double minZ;
  final double maxZ;
}

class PointCloudFrame {
  const PointCloudFrame({required this.timestampMicros, required this.points});

  final int timestampMicros;
  final List<LidarPoint> points;

  int get pointCount => points.length;

  LidarBounds get bounds {
    if (points.isEmpty) {
      return const LidarBounds(
        minX: 0,
        maxX: 0,
        minY: 0,
        maxY: 0,
        minZ: 0,
        maxZ: 0,
      );
    }
    double minX = points.first.x;
    double maxX = points.first.x;
    double minY = points.first.y;
    double maxY = points.first.y;
    double minZ = points.first.z;
    double maxZ = points.first.z;
    for (final point in points.skip(1)) {
      if (point.x < minX) minX = point.x;
      if (point.x > maxX) maxX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.y > maxY) maxY = point.y;
      if (point.z < minZ) minZ = point.z;
      if (point.z > maxZ) maxZ = point.z;
    }
    return LidarBounds(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      minZ: minZ,
      maxZ: maxZ,
    );
  }
}

abstract interface class LidarAdapter {
  Future<LidarResult> start();
  Future<LidarResult> stop();
}

class UnavailableLidarAdapter implements LidarAdapter {
  const UnavailableLidarAdapter();

  @override
  Future<LidarResult> start() async => LidarResult.unavailable;

  @override
  Future<LidarResult> stop() async => LidarResult.stopped;
}
