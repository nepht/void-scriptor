/// Resolved display data for the Environment workspace cards
/// (vs-hunt-20260913-environment ENV-BUG-002).
///
/// The workspace previously rendered hardcoded stub values; these classes
/// carry the persisted weather/lighting/zone/continuity profile data that is
/// seeded by CreateEnvironmentService and stored in the project database.
class EnvironmentWeatherData {
  const EnvironmentWeatherData({
    required this.condition,
    required this.intensity,
    required this.visibility,
  });

  final String condition;
  final double intensity;
  final double visibility;
}

class EnvironmentLightingData {
  const EnvironmentLightingData({
    required this.time,
    required this.keyLight,
    required this.fogDensity,
  });

  final String time;
  final String keyLight;
  final double fogDensity;
}

class EnvironmentWorkspaceData {
  const EnvironmentWorkspaceData({
    this.weather,
    this.lighting,
    this.zones = const [],
    this.continuityStateName,
  });

  final EnvironmentWeatherData? weather;
  final EnvironmentLightingData? lighting;
  final List<String> zones;
  final String? continuityStateName;
}
