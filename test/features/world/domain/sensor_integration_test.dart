import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/sensor_integration.dart';

void main() {
  test('sensor hub reports available modalities deterministically', () {
    const hub = SensorHub(
      modalities: [SensorModality.camera, SensorModality.depth],
    );

    expect(hub.isValid, isTrue);
    expect(hub.supports(SensorModality.camera), isTrue);
    expect(hub.supports(SensorModality.lidar), isFalse);
  });

  test('empty sensor hub is an explicit unavailable boundary', () {
    const hub = SensorHub(modalities: []);
    expect(hub.isAvailable, isFalse);
  });
}
