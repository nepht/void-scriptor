import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/lidar_adapter.dart';

void main() {
  test('LiDAR capability and point cloud metadata remain bounded', () {
    const capability = LidarCapability(
      id: 'lidar.default',
      minRangeMeters: .2,
      maxRangeMeters: 5,
      maxPoints: 1000,
    );
    const cloud = PointCloudFrame(
      timestampMicros: 10,
      points: [LidarPoint(x: 0, y: 0, z: 1), LidarPoint(x: 1, y: 0, z: 2)],
    );

    expect(capability.isValid, isTrue);
    expect(cloud.pointCount, 2);
    expect(cloud.bounds.maxZ, 2);
  });

  test(
    'unavailable LiDAR adapter reports external hardware boundary',
    () async {
      const adapter = UnavailableLidarAdapter();

      expect(await adapter.start(), LidarResult.unavailable);
      expect(await adapter.stop(), LidarResult.stopped);
    },
  );
}
