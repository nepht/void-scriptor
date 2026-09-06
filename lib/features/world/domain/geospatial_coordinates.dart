import 'dart:math' as math;

class GeoCoordinate {
  const GeoCoordinate({
    required this.latitude,
    required this.longitude,
    required this.altitudeMeters,
  });

  final double latitude;
  final double longitude;
  final double altitudeMeters;

  bool get isValid =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  double get normalizedLongitude {
    var value = longitude % 360;
    if (value > 180) value -= 360;
    if (value < -180) value += 360;
    return value;
  }

  GeoCoordinate copyWith({
    double? latitude,
    double? longitude,
    double? altitudeMeters,
  }) => GeoCoordinate(
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    altitudeMeters: altitudeMeters ?? this.altitudeMeters,
  );

  double distanceTo(GeoCoordinate other) {
    const earthRadiusMeters = 6371000.0;
    final lat1 = latitude * math.pi / 180;
    final lat2 = other.latitude * math.pi / 180;
    final dLat = (other.latitude - latitude) * math.pi / 180;
    final dLon = (other.longitude - longitude) * math.pi / 180;
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLon / 2), 2);
    final horizontal =
        earthRadiusMeters * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final vertical = other.altitudeMeters - altitudeMeters;
    return math.sqrt(horizontal * horizontal + vertical * vertical);
  }
}
