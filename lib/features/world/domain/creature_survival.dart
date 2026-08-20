class MigrationPolicy {
  static bool shouldMigrate({
    required double temperature,
    required double food,
  }) => temperature < 10 || food < .3;
}

class FoodWeb {
  FoodWeb({required this.capacity});
  final int capacity;
  int consumed = 0;
  void consume(String resource, int amount) {
    consumed = (consumed + amount).clamp(0, capacity);
  }

  int get remainingCapacity => capacity - consumed;
  bool canConsume(int amount) => amount <= remainingCapacity;
}

enum DisturbanceType { fire, flood, drought }

class HabitatHealth {
  HabitatHealth(this.value);
  double value;
  void disturb(DisturbanceType type, {required double severity}) {
    value = (value - severity).clamp(0, 1);
  }

  void recover({required double rate}) => value = (value + rate).clamp(0, 1);
}

class Disease {
  const Disease({required this.transmission, required this.mortality});
  final double transmission;
  final double mortality;
  double risk({required double contactRate}) => transmission * contactRate;
}

class SyntheticGenome {
  const SyntheticGenome(this.traits);
  final Map<String, double> traits;
}

class SyntheticLife {
  const SyntheticLife(this.genome, {this.generation = 0});
  final SyntheticGenome genome;
  final int generation;
  SyntheticLife evolve({required int generation}) =>
      SyntheticLife(genome, generation: generation);
}

class CombatOutcome {
  const CombatOutcome(this.winner);
  final String winner;
}

class SurvivalCombat {
  static CombatOutcome resolve({
    required int attacker,
    required int defender,
  }) => CombatOutcome(attacker >= defender ? 'attacker' : 'defender');
}

enum Injury { none, minor, severe }

class InjuryState {
  static Injury fromDamage(int damage) {
    if (damage >= 7) return Injury.severe;
    if (damage > 0) return Injury.minor;
    return Injury.none;
  }
}

enum LifeStatus { wild, promoted }

class LifeHistory {
  final Map<String, LifeStatus> _statuses = {};
  void promote(String id) => _statuses[id] = LifeStatus.promoted;
  void demote(String id) => _statuses[id] = LifeStatus.wild;
  LifeStatus statusOf(String id) => _statuses[id] ?? LifeStatus.wild;
}

class CreatureLod {
  static int level({required double distanceMeters}) {
    if (distanceMeters < 50) return 0;
    if (distanceMeters < 200) return 1;
    if (distanceMeters < 500) return 2;
    return 3;
  }
}
