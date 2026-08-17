/// Sprint 48 — Step 48.36–48.40 Environment Timeline, Time-of-Day, Weather, Lighting.
class EnvironmentTimeline {
  const EnvironmentTimeline({
    required this.id,
    required this.cinematicId,
    required this.timeOfDay,
    this.lightingPreset,
  });

  final String id;
  final String cinematicId;
  final String timeOfDay;
  final String? lightingPreset;
}

class WeatherTrack {
  const WeatherTrack({
    required this.id,
    required this.environmentTimelineId,
    required this.condition,
  });

  final String id;
  final String environmentTimelineId;
  final String condition;
}

class CinematicLightingTrack {
  const CinematicLightingTrack({
    required this.id,
    required this.environmentTimelineId,
    required this.preset,
  });

  final String id;
  final String environmentTimelineId;
  final String preset;
}

class LightingPreset {
  const LightingPreset({
    required this.id,
    required this.name,
    required this.intensity,
    this.colorTemperature = 5600,
  });

  final String id;
  final String name;
  final double intensity;
  final int colorTemperature;
}
