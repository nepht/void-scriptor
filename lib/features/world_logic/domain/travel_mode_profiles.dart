/// Sprint 110.10 - Travel Mode Profiles.
library;

enum TerrainKind { plain, forest, mountain, desert, swamp, ocean, river }

enum WeatherCondition { clear, rain, storm, blizzard, hurricane }

class WeatherImpact {
  const WeatherImpact({
    required this.condition,
    required this.speedMultiplier,
    required this.explanation,
    this.refuses = false,
  });

  final WeatherCondition condition;
  final double speedMultiplier;
  final String explanation;
  final bool refuses;
}

const String atDelim = "@";

class TravelModeProfile {
  const TravelModeProfile({
    required this.id,
    required this.label,
    required this.baseSpeedKmPerHour,
    required this.capacityPersons,
    required this.passableTerrains,
    required this.restAfterHours,
    required this.restDurationHours,
  });

  final String id;
  final String label;
  final double baseSpeedKmPerHour;
  final int capacityPersons;
  final Set<TerrainKind> passableTerrains;
  final int restAfterHours;
  final int restDurationHours;

  static void _validate(TravelModeProfile p) {
    if (p.id.isEmpty) {
      throw ArgumentError("travel mode id cannot be empty");
    }
    if (p.label.isEmpty) {
      throw ArgumentError("travel mode label cannot be empty");
    }
    if (p.baseSpeedKmPerHour <= 0) {
      throw ArgumentError("travel mode ${p.id} base speed must be > 0");
    }
    if (p.capacityPersons <= 0) {
      throw ArgumentError("travel mode ${p.id} capacity must be > 0");
    }
    if (p.restAfterHours < 0) {
      throw ArgumentError(
        "travel mode ${p.id} restAfterHours must be >= 0",
      );
    }
    if (p.restDurationHours < 0) {
      throw ArgumentError(
        "travel mode ${p.id} restDurationHours must be >= 0",
      );
    }
    if (p.passableTerrains.isEmpty) {
      throw ArgumentError(
        "travel mode ${p.id} must declare at least one passable terrain",
      );
    }
  }

  TravelModeProfile validated() {
    _validate(this);
    return this;
  }

  bool canTraverse(TerrainKind terrain) => passableTerrains.contains(terrain);

  TravelModeProfile applyWeather(WeatherCondition condition) {
    final impact = _weatherImpactFor(condition);
    if (impact.refuses) {
      throw TravelModeWeatherRefused(
        modeId: id,
        condition: condition,
        reason: impact.explanation,
      );
    }
    if (impact.speedMultiplier == 1.0) {
      return this;
    }
    return TravelModeProfile(
      id: id + atDelim + condition.name,
      label: label,
      baseSpeedKmPerHour: baseSpeedKmPerHour * impact.speedMultiplier,
      capacityPersons: capacityPersons,
      passableTerrains: passableTerrains,
      restAfterHours: restAfterHours,
      restDurationHours: restDurationHours,
    );
  }

  WeatherImpact _weatherImpactFor(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.clear:
        return const WeatherImpact(
          condition: WeatherCondition.clear,
          speedMultiplier: 1.0,
          explanation: "",
        );
      case WeatherCondition.rain:
        return WeatherImpact(
          condition: WeatherCondition.rain,
          speedMultiplier: 0.85,
          explanation: "rain slows travel on $label",
        );
      case WeatherCondition.storm:
        return WeatherImpact(
          condition: WeatherCondition.storm,
          speedMultiplier: 0.6,
          explanation: "storm: travel on $label is hazardous",
        );
      case WeatherCondition.blizzard:
        return WeatherImpact(
          condition: WeatherCondition.blizzard,
          speedMultiplier: 0.4,
          explanation: "blizzard: travel on $label is severely slowed",
        );
      case WeatherCondition.hurricane:
        return const WeatherImpact(
          condition: WeatherCondition.hurricane,
          speedMultiplier: 0,
          explanation: "hurricane: travel forbidden",
          refuses: true,
        );
    }
  }
}

String modifierExplanation(TravelModeProfile profile) {
  if (!profile.id.contains(atDelim)) return "";
  final parts = profile.id.split(atDelim);
  if (parts.length < 2) return "";
  final tail = parts.last;
  if (tail == WeatherCondition.clear.name) return "";
  return "weather=$tail";
}

class TravelModeIncompatibleTerrain implements Exception {
  TravelModeIncompatibleTerrain({required this.modeId, required this.terrain});
  final String modeId;
  final TerrainKind terrain;
  @override
  String toString() =>
      "TravelModeIncompatibleTerrain(mode=$modeId, terrain=${terrain.name})";
}

class TravelModeWeatherRefused implements Exception {
  TravelModeWeatherRefused({
    required this.modeId,
    required this.condition,
    required this.reason,
  });
  final String modeId;
  final WeatherCondition condition;
  final String reason;
  @override
  String toString() =>
      "TravelModeWeatherRefused(mode=$modeId, condition=${condition.name}, reason=$reason)";
}

extension TravelModeTerrainGuard on TravelModeProfile {
  void requireTerrain(TerrainKind terrain) {
    if (!canTraverse(terrain)) {
      throw TravelModeIncompatibleTerrain(modeId: id, terrain: terrain);
    }
  }
}

class TravelModes {
  const TravelModes._();

  static const TravelModeProfile walk = TravelModeProfile(
    id: "walk",
    label: "On Foot",
    baseSpeedKmPerHour: 4.5,
    capacityPersons: 1,
    passableTerrains: {
      TerrainKind.plain,
      TerrainKind.forest,

      TerrainKind.desert,
      TerrainKind.swamp,
    },
    restAfterHours: 6,
    restDurationHours: 8,
  );

  static const TravelModeProfile mount = TravelModeProfile(
    id: "mount",
    label: "Mount / Horse",
    baseSpeedKmPerHour: 12,
    capacityPersons: 2,
    passableTerrains: {
      TerrainKind.plain,
      TerrainKind.forest,
      TerrainKind.mountain,
      TerrainKind.desert,
    },
    restAfterHours: 8,
    restDurationHours: 6,
  );

  static const TravelModeProfile vehicle = TravelModeProfile(
    id: "vehicle",
    label: "Carriage / Cart",
    baseSpeedKmPerHour: 8,
    capacityPersons: 6,
    passableTerrains: {
      TerrainKind.plain,
      TerrainKind.forest,
      TerrainKind.desert,
    },
    restAfterHours: 5,
    restDurationHours: 2,
  );

  static const TravelModeProfile ship = TravelModeProfile(
    id: "ship",
    label: "Ship / Boat",
    baseSpeedKmPerHour: 14,
    capacityPersons: 20,
    passableTerrains: {TerrainKind.ocean, TerrainKind.river},
    restAfterHours: 12,
    restDurationHours: 4,
  );

  static const List<TravelModeProfile> builtIn = <TravelModeProfile>[
    walk,
    mount,
    vehicle,
    ship,
  ];
}

class TravelModeRegistry {
  TravelModeRegistry._(Map<String, TravelModeProfile> profiles)
    : _profiles = Map.unmodifiable(profiles);

  final Map<String, TravelModeProfile> _profiles;

  static final TravelModeRegistry builtIn =
      TravelModeRegistry._(<String, TravelModeProfile>{
        TravelModes.walk.id: TravelModes.walk,
        TravelModes.mount.id: TravelModes.mount,
        TravelModes.vehicle.id: TravelModes.vehicle,
        TravelModes.ship.id: TravelModes.ship,
      });

  TravelModeProfile profile(String id) {
    final value = _profiles[id];
    if (value == null) {
      throw ArgumentError("unknown travel mode $id");
    }
    return value;
  }

  List<TravelModeProfile> get profiles => List.unmodifiable(_profiles.values);

  TravelModeRegistry withProfile(TravelModeProfile profile) {
    final next = Map<String, TravelModeProfile>.from(_profiles);
    next[profile.id] = profile;
    return TravelModeRegistry._(next);
  }
}
