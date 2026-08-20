enum Season { spring, summer, autumn, winter }

class PlanetCycle {
  const PlanetCycle({
    required this.axialTiltDegrees,
    required this.rotationHours,
  });
  final double axialTiltDegrees;
  final double rotationHours;

  Season seasonFor({required int dayOfYear}) {
    if (dayOfYear < 80) return Season.winter;
    if (dayOfYear < 172) return Season.spring;
    if (dayOfYear < 266) return Season.summer;
    if (dayOfYear < 355) return Season.autumn;
    return Season.winter;
  }

  bool isNight({required double localHour}) => localHour < 6 || localHour >= 18;
  int solarPosition({required double localHour}) =>
      isNight(localHour: localHour) ? 0 : 1;
}

enum ClimateZone { tropical, temperate, polar }

class ClimateMap {
  const ClimateMap();
  ClimateZone zoneAt({required double latitude}) {
    final absolute = latitude.abs();
    if (absolute >= 60) return ClimateZone.polar;
    if (absolute >= 30) return ClimateZone.temperate;
    return ClimateZone.tropical;
  }
}

class Atmosphere {
  Atmosphere({required this.pressure, required this.cloudCover}) {
    if (pressure < 0 || cloudCover < 0 || cloudCover > 1) {
      throw ArgumentError('Atmosphere values are out of bounds');
    }
  }
  final double pressure;
  final double cloudCover;
}

class WeatherFront {
  WeatherFront({
    required this.x,
    required this.y,
    required this.speed,
    required this.severity,
  });
  double x;
  double y;
  final double speed;
  int severity;
  bool get isExtreme => severity >= 7;
  void advance({required double hours}) {
    x += speed * hours;
  }
}
