class Settlement {
  Settlement({required this.id, required this.name, required this.suitability});
  final String id;
  final String name;
  final double suitability;
  int population = 0;
  bool grow({required int population}) {
    if (suitability <= 0 || population < 0) return false;
    this.population += population;
    return true;
  }
}

enum CityStyle { volcanic, coastal, desert, forest }

class Landmark {
  const Landmark({
    required this.id,
    required this.name,
    required this.preserved,
  });
  final String id;
  final String name;
  final bool preserved;
}

class City {
  City.fromSettlement(Settlement settlement, {required this.style})
    : name = settlement.name,
      population = settlement.population,
      landmarks = [];
  final String name;
  final CityStyle style;
  int population;
  final List<Landmark> landmarks;
  void addLandmark(Landmark landmark) => landmarks.add(landmark);
}

enum RoadType { dirt, paved, rail }

class Road {
  const Road({
    required this.id,
    required this.from,
    required this.to,
    required this.type,
    required this.cost,
  });
  final String id;
  final String from;
  final String to;
  final RoadType type;
  final int cost;
}

class RoadNetwork {
  final List<Road> _roads = [];
  void add(Road road) => _roads.add(road);
  Road? cheapest(String from, String to) {
    final matches = _roads
        .where((road) => road.from == from && road.to == to)
        .toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) => a.cost.compareTo(b.cost));
    return matches.first;
  }
}

class TransportSimulation {
  const TransportSimulation(this.network);
  final RoadNetwork network;
  int? routeCost(String from, String to) => network.cheapest(from, to)?.cost;
}

class PopulationDensity {
  final Map<String, int> _values = {};
  void set(String region, int value) => _values[region] = value;
  int at(String region) => _values[region] ?? 0;
  void migrate(String from, String to, int amount) {
    if (amount < 0 || at(from) < amount) {
      throw ArgumentError('Invalid migration');
    }
    _values[from] = at(from) - amount;
    _values[to] = at(to) + amount;
  }
}

class Territory {
  Territory(this.id, {required this._owner}) : history = [];
  final String id;
  String _owner;
  String get owner => _owner;
  final List<String> history;
  void changeOwner(String nextOwner) {
    history.add('$_owner -> $nextOwner');
    _owner = nextOwner;
  }
}

enum ChunkState { unloaded, loading, active }

class StreamingUnit {
  StreamingUnit(this.id) : state = ChunkState.unloaded, lod = 3;
  final String id;
  ChunkState state;
  int lod;
  void update({required double distanceMeters, required double radiusMeters}) {
    if (distanceMeters > radiusMeters) {
      state = ChunkState.unloaded;
      lod = 3;
    } else {
      state = ChunkState.active;
      lod = ObjectLod.forDistance(distanceMeters);
    }
  }
}

class ObjectLod {
  static int forDistance(double distanceMeters) {
    if (distanceMeters < 50) return 0;
    if (distanceMeters < 150) return 1;
    if (distanceMeters < 500) return 2;
    return 3;
  }
}

class SeamlessZoom {
  static int level({required double scale}) {
    if (scale >= .5) return 0;
    if (scale >= .1) return 1;
    if (scale >= .02) return 2;
    return 3;
  }
}
