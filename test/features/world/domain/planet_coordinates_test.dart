import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/planet_coordinates.dart';

void main() {
  for (final latitude in [
    -91.0,
    91.0,
    double.nan,
    double.infinity,
    double.negativeInfinity,
  ]) {
    test('floating origin rejects latitude $latitude', () {
      expect(
        () => FloatingOrigin(latitude: latitude, longitude: 0),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'latitude')),
      );
    });
  }

  for (final longitude in [
    -181.0,
    181.0,
    double.nan,
    double.infinity,
    double.negativeInfinity,
  ]) {
    test('floating origin rejects longitude $longitude', () {
      expect(
        () => FloatingOrigin(latitude: 0, longitude: longitude),
        throwsA(
          isA<ArgumentError>().having((e) => e.name, 'name', 'longitude'),
        ),
      );
    });
  }

  test('floating origin accepts inclusive coordinate boundaries', () {
    for (final latitude in [-90.0, 0.0, 90.0]) {
      for (final longitude in [-180.0, 0.0, 180.0]) {
        final origin = FloatingOrigin(latitude: latitude, longitude: longitude);
        final local = origin.toLocal(
          PlanetCoordinate(latitude: latitude, longitude: longitude),
          metersPerDegree: 100000,
        );
        expect(local.x, 0);
        expect(local.y, 0);
      }
    }
  });

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
      final origin = FloatingOrigin(latitude: 10, longitude: 20);
      const coordinate = PlanetCoordinate(latitude: 10.001, longitude: 20.002);
      final local = origin.toLocal(coordinate, metersPerDegree: 100000);
      expect(local.x, closeTo(200, .001));
      expect(local.y, closeTo(100, .001));
      expect(origin.canShiftTo(coordinate, maxDistanceMeters: 500), isTrue);
    },
  );

  test('rejects unsafe origin shifts beyond the configured distance', () {
    final origin = FloatingOrigin(latitude: 0, longitude: 0);
    const target = PlanetCoordinate(latitude: 1, longitude: 1);
    expect(origin.canShiftTo(target, maxDistanceMeters: 1000), isFalse);
  });
}
