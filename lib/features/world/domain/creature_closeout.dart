enum CreatureStateKind { wild, promoted }

class CreatureState {
  const CreatureState(this.id, this.kind);
  final String id;
  final CreatureStateKind kind;
}

class CreaturePromotionRules {
  const CreaturePromotionRules({required this.minUtility});
  final double minUtility;
  bool canPromote({required double utility}) => utility >= minUtility;
  CreatureState promote(String id) =>
      CreatureState(id, CreatureStateKind.promoted);
  CreatureState demote(CreatureState state) =>
      CreatureState(state.id, CreatureStateKind.wild);
}

class CreatureVisual {
  const CreatureVisual({required this.speciesId, required this.variation});
  final String speciesId;
  final double variation;
}

class CreatureVisualGenerator {
  const CreatureVisualGenerator({required this.seed});
  final int seed;
  CreatureVisual generate(String speciesId) =>
      CreatureVisual(speciesId: speciesId, variation: (seed % 100) / 100);
}

enum AnimationState { idle, pursue, flee }

class BehaviorAnimation {
  static AnimationState fromBehavior(String behavior) =>
      behavior == 'hunt' ? AnimationState.pursue : AnimationState.idle;
}

class ProceduralAnimation {
  static int frame(AnimationState state, {required int tick}) => tick.abs();
}

enum PlayerAction { harvest, observe, attack }

class WildlifeRuntime {
  WildlifeRuntime({required this.backgroundCount})
    : population = backgroundCount;
  final int backgroundCount;
  int population;
  int ticks = 0;
  void applyPlayerAction(PlayerAction action, {required double impact}) {
    if (action == PlayerAction.harvest || action == PlayerAction.attack) {
      population = (population * (1 - impact)).round();
    }
  }

  void tick({required int hours}) => ticks += hours > 0 ? 1 : 0;
}

class BiomeHabitat {
  const BiomeHabitat(
    this.biome, {
    required this.temperature,
    required this.food,
  });
  final String biome;
  final double temperature;
  final double food;
  double get suitability => ((temperature + food) / 2).clamp(0, 1);
}

class CreaturePromptPreview {
  const CreaturePromptPreview(this.prompt);
  final String prompt;
}

class CreatureDesignerAgent {
  const CreatureDesignerAgent();
  CreaturePromptPreview preview(String description) =>
      CreaturePromptPreview(description);
}

class EvolutionResult {
  const EvolutionResult({required this.generations, required this.diversity});
  final int generations;
  final double diversity;
}

class BehaviorResult {
  const BehaviorResult(this.action);
  final String action;
}

class ExperimentRunner {
  EvolutionResult evolution({required int seed, required int generations}) =>
      EvolutionResult(generations: generations, diversity: (seed % 10) / 10);
  BehaviorResult behavior(String behavior) =>
      BehaviorResult(behavior == 'hunt' ? 'pursue' : 'observe');
}

class CreatureCanonProtection {
  bool isProtected(String name) => name == 'Kokuen' || name == 'Crash Site';
}

class LineageGraph {
  final Map<String, List<String>> _parents = {};
  void link(String child, String parent) =>
      _parents.putIfAbsent(child, () => []).add(parent);
  List<String> parentsOf(String child) =>
      List.unmodifiable(_parents[child] ?? []);
}

class UpdateFrequency {
  static Duration forLod(int lod) => Duration(
    milliseconds: lod == 0
        ? 16
        : lod == 1
        ? 100
        : 500,
  );
}

class DiversityMetric {
  static double calculate(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a > b ? a : b) -
        values.reduce((a, b) => a < b ? a : b);
  }
}

class BottleneckEvent {
  static bool detect({required int population, required int threshold}) =>
      population < threshold;
}

enum Extinction { alive, extinct }

class ExtinctionState {
  static Extinction fromPopulation(int population) =>
      population <= 0 ? Extinction.extinct : Extinction.alive;
}

class LongTermSimulation {
  int ticks = 0;
  void run({required int ticks}) => this.ticks += ticks.clamp(0, 100000);
}
