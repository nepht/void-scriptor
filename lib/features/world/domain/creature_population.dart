enum GroupType { herd, pack, flock }

class CreatureGroup {
  CreatureGroup({required this.id, required this.type});
  final String id;
  final GroupType type;
  final List<String> members = [];
  String? leader;
  void add(String id) => members.add(id);
  void setLeader(String id) => leader = members.contains(id) ? id : null;
  int movement({required int separation, required int cohesion}) =>
      separation + cohesion;
  int lod({required double distanceMeters}) => distanceMeters < 100
      ? 0
      : distanceMeters < 500
      ? 1
      : 2;
}

class TerritoryConflict {
  const TerritoryConflict(this.defender, this.attacker);
  final String defender;
  final String attacker;
  String resolve({
    required int defenderStrength,
    required int attackerStrength,
  }) => attackerStrength > defenderStrength ? attacker : defender;
}

class PredatorPressure {
  static double response({
    required double preyAlert,
    required int escapeRoutes,
  }) => (preyAlert + 1 / escapeRoutes).clamp(0, 1);
}

enum HuntAction { pursue, retreat, observe }

class HuntingStrategy {
  static HuntAction choose({
    required double preyDistance,
    required double energy,
  }) {
    if (energy < .3) return HuntAction.retreat;
    if (preyDistance <= 5) return HuntAction.pursue;
    return HuntAction.observe;
  }
}

class ReproductiveGenome {
  const ReproductiveGenome(this.traits);
  final Map<String, double> traits;
}

class Reproduction {
  static ReproductiveGenome offspring(
    ReproductiveGenome a,
    ReproductiveGenome b, {
    required double mutation,
    required int seed,
  }) {
    final result = <String, double>{};
    for (final key in a.traits.keys) {
      final first = a.traits[key] ?? 0;
      final second = b.traits[key] ?? first;
      final value = (first + second) / 2;
      result[key] = (value + (seed.isEven ? mutation : -mutation)).clamp(0, 1);
    }
    return ReproductiveGenome(result);
  }
}

class MutationSafety {
  static bool isSafe(ReproductiveGenome genome) =>
      genome.traits.values.every((value) => value >= 0 && value <= 1);
}

class Fitness {
  static double score(
    ReproductiveGenome genome, {
    required Map<String, double> environment,
  }) {
    if (genome.traits.isEmpty) return 0;
    return genome.traits.entries
            .map(
              (entry) =>
                  1 - (entry.value - (environment[entry.key] ?? .5)).abs(),
            )
            .fold<double>(0, (sum, value) => sum + value) /
        genome.traits.length;
  }
}

class GenomePool {
  GenomePool(this.genomes);
  final List<ReproductiveGenome> genomes;
  double get diversity {
    if (genomes.isEmpty) return 0;
    final values = genomes.expand((genome) => genome.traits.values).toList();
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a > b ? a : b) -
        values.reduce((a, b) => a < b ? a : b);
  }

  void evolutionTick({required int seed}) {
    if (genomes.isEmpty) return;
    final first = genomes.first;
    genomes.add(
      Reproduction.offspring(first, first, mutation: .01, seed: seed),
    );
  }

  bool divergenceThreshold(double threshold) =>
      genomes.length > 1 && threshold >= 0 && threshold <= 1;
}

class CanonApproval {
  bool approve(String speciesId) => speciesId.trim().isNotEmpty;
}
