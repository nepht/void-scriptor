/// Sprint 46 — Step 46.43–46.52 Settlements, Infrastructure, Weather.
class Settlement {
  const Settlement({
    required this.id,
    required this.name,
    required this.population,
    this.districts = const [],
    this.infrastructure = const [],
  });

  final String id;
  final String name;
  final int population;
  final List<String> districts;
  final List<Infrastructure> infrastructure;
}

class Infrastructure {
  const Infrastructure({
    required this.id,
    required this.name,
    this.health = 1.0,
    this.failed = false,
  });

  final String id;
  final String name;
  final double health;
  final bool failed;
}

enum WeatherCondition {
  clear,
  cloudy,
  rain,
  storm,
  snow,
  blizzard,
  fog,
  heatwave,
}

class WeatherZone {
  const WeatherZone({
    required this.id,
    required this.region,
    required this.condition,
  });

  final String id;
  final String region;
  final WeatherCondition condition;
}

/// Step 46.53–46.55 Ecosystem.
class EcosystemState {
  const EcosystemState({
    required this.id,
    required this.worldId,
    required this.balance,
  });

  final String id;
  final String worldId;
  final double balance;
}

class CreaturePopulation {
  const CreaturePopulation({
    required this.id,
    required this.speciesId,
    required this.eco,
    required this.count,
  });

  final String id;
  final String speciesId;
  final EcosystemState eco;
  final int count;
}
