enum EnvironmentType {
  city,
  building,
  room,
  landscape,
  mountain,
  desert,
  forest,
  ocean,
  space,
  dimensional,
  custom;

  String get value => name;

  static EnvironmentType? fromValue(String value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

enum TimeOfDayPreset {
  dawn,
  morning,
  noon,
  afternoon,
  goldenHour,
  sunset,
  blueHour,
  night,
  midnight,
  anomaly;

  String get value => name;
}

enum WeatherPreset {
  clear,
  cloudy,
  rain,
  storm,
  fog,
  snow,
  dust,
  magicalStorm,
  voidStorm;

  String get value => name;
}
