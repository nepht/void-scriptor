class Species {
  const Species({required this.id, required this.name});
  final String id;
  final String name;
}

class SpeciesRegistry {
  const SpeciesRegistry(this.species);
  final List<Species> species;
  factory SpeciesRegistry.defaults() =>
      const SpeciesRegistry([Species(id: 'ashborn', name: 'Ashborn')]);
  Species? byId(String id) =>
      species.where((item) => item.id == id).firstOrNull;
}

class Genome {
  const Genome(this.traits);
  final Map<String, double> traits;
  Map<String, double> phenotype({required double environmentalHeat}) => {
    for (final entry in traits.entries)
      entry.key: entry.key == 'heatResistance'
          ? entry.value.clamp(0, 1)
          : entry.value,
  };
}

class AgeStage {
  const AgeStage(this.id, this.start, this.end);
  final String id;
  final int start;
  final int end;
}

class LifeCycle {
  const LifeCycle({required this.stages});
  final List<AgeStage> stages;
  AgeStage stageAt(int age) => stages.lastWhere(
    (stage) => age >= stage.start && age <= stage.end,
    orElse: () => stages.last,
  );
  double growthAt(int age) =>
      age <= stages.last.end ? age / stages.last.end : 1;
}

class NeedsState {
  NeedsState(this.values);
  final Map<String, double> values;
  String priority() =>
      values.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

class Perception {
  const Perception({required this.range, required this.occluded});
  final double range;
  final bool occluded;
  bool canSee({required double distance}) => !occluded && distance <= range;
}

class CreatureMemory {
  final Map<String, double> _strengths = {};
  void remember(String route, {required double strength}) =>
      _strengths[route] = strength.clamp(0, 1);
  double strengthOf(String route) => _strengths[route] ?? 0;
}

class Personality {
  const Personality({required this.curiosity, required this.aggression});
  final double curiosity;
  final double aggression;
  double get variationScore => curiosity - aggression;
}

class UtilityGoal {
  static double score({required double need, required double distance}) =>
      need / distance;
}
