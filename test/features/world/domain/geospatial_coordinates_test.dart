import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/geospatial_coordinates.dart';

void main() {
  test('coordinates validate bounds and normalize longitude', () {
    const coordinate = GeoCoordinate(
      latitude: 91,
      longitude: 540,
      altitudeMeters: 12,
    );

    expect(coordinate.isValid, isFalse);
    expect(coordinate.normalizedLongitude, 180);
    expect(coordinate.copyWith(latitude: 45, longitude: -180).isValid, isTrue);
  });

  test('distance is deterministic and zero for identical coordinates', () {
    const coordinate = GeoCoordinate(
      latitude: 0,
      longitude: 0,
      altitudeMeters: 0,
    );
    expect(coordinate.distanceTo(coordinate), 0);
  });
}
