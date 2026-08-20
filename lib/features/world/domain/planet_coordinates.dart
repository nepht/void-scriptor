enum PlanetType { terrestrial, gasGiant, ice, ocean }

class PlanetProfile {
  const PlanetProfile({required this.type, required this.radiusMeters});
  final PlanetType type;
  final double radiusMeters;
}

class Planet {
  Planet({
    required this.id,
    required this.name,
    required PlanetType type,
    required double radiusMeters,
  }) : profile = PlanetProfile(type: type, radiusMeters: radiusMeters);

  final String id;
  final String name;
  final PlanetProfile profile;

  PlanetCoordinate coordinateAt({
    required double latitude,
    required double longitude,
  }) {
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError.value(latitude, 'latitude');
    }
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError.value(longitude, 'longitude');
    }
    return PlanetCoordinate(latitude: latitude, longitude: longitude);
  }
}

class PlanetCoordinate {
  const PlanetCoordinate({required this.latitude, required this.longitude});
  final double latitude;
  final double longitude;
}

class LocalCoordinate {
  const LocalCoordinate({required this.x, required this.y});
  final double x;
  final double y;
}

class FloatingOrigin {
  const FloatingOrigin({required this.latitude, required this.longitude});
  final double latitude;
  final double longitude;

  LocalCoordinate toLocal(
    PlanetCoordinate coordinate, {
    required double metersPerDegree,
  }) {
    return LocalCoordinate(
      x: (coordinate.longitude - longitude) * metersPerDegree,
      y: (coordinate.latitude - latitude) * metersPerDegree,
    );
  }

  bool canShiftTo(
    PlanetCoordinate coordinate, {
    required double maxDistanceMeters,
    double metersPerDegree = 100000,
  }) {
    final local = toLocal(coordinate, metersPerDegree: metersPerDegree);
    return (local.x * local.x + local.y * local.y) <=
        maxDistanceMeters * maxDistanceMeters;
  }
}
