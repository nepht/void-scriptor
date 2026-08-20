import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/planet_coordinates.dart';

void main() {
  test('creates a typed planet profile with bounded coordinates', () {
    final planet = Planet(
      id: 'planet-1',
      name: 'Void Prime',
      type: PlanetType.terrestrial,
      radiusMeters: 6_000_000,
    );
    expect(planet.profile.type, PlanetType.terrestrial);
    expect(planet.profile.radiusMeters, 6_000_000);
    expect(
      () => planet.coordinateAt(latitude: 91, longitude: 0),
      throwsArgumentError,
    );
    expect(
      () => planet.coordinateAt(latitude: 0, longitude: 181),
      throwsArgumentError,
    );
  });

  test(
    'converts global coordinates to local coordinates around a floating origin',
    () {
      const origin = FloatingOrigin(latitude: 10, longitude: 20);
      const coordinate = PlanetCoordinate(latitude: 10.001, longitude: 20.002);
      final local = origin.toLocal(coordinate, metersPerDegree: 100000);
      expect(local.x, closeTo(200, .001));
      expect(local.y, closeTo(100, .001));
      expect(origin.canShiftTo(coordinate, maxDistanceMeters: 500), isTrue);
    },
  );

  test('rejects unsafe origin shifts beyond the configured distance', () {
    const origin = FloatingOrigin(latitude: 0, longitude: 0);
    const target = PlanetCoordinate(latitude: 1, longitude: 1);
    expect(origin.canShiftTo(target, maxDistanceMeters: 1000), isFalse);
  });
}
