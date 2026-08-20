import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/climate_weather.dart';

void main() {
  test('computes solar/night state from rotation and solar position', () {
    const planet = PlanetCycle(axialTiltDegrees: 23.5, rotationHours: 24);
    expect(planet.seasonFor(dayOfYear: 80), Season.spring);
    expect(planet.isNight(localHour: 23), isTrue);
    expect(planet.isNight(localHour: 12), isFalse);
    expect(planet.solarPosition(localHour: 12), 1);
  });

  test('maps climate zones and bounded atmospheric properties', () {
    const climate = ClimateMap();
    expect(climate.zoneAt(latitude: 0), ClimateZone.tropical);
    expect(climate.zoneAt(latitude: 70), ClimateZone.polar);
    expect(() => Atmosphere(pressure: -1, cloudCover: 0), throwsArgumentError);
  });

  test('moves fronts and flags extreme weather deterministically', () {
    final front = WeatherFront(x: 0, y: 0, speed: 2, severity: 4);
    front.advance(hours: 3);
    expect(front.x, 6);
    expect(front.isExtreme, isFalse);
    front.severity = 8;
    expect(front.isExtreme, isTrue);
  });
}
