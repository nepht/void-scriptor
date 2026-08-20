import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/creature_ecology.dart';

void main() {
  test('species registry and genome produce bounded phenotype', () {
    final registry = SpeciesRegistry.defaults();
    final species = registry.byId('ashborn');
    expect(species, isNotNull);
    const genome = Genome({'height': .8, 'heatResistance': 1.2});
    final phenotype = genome.phenotype(environmentalHeat: .5);
    expect(phenotype['height'], .8);
    expect(phenotype['heatResistance'], 1);
  });

  test('life cycle follows age stages and growth curve', () {
    const cycle = LifeCycle(
      stages: [AgeStage('young', 0, 10), AgeStage('adult', 11, 80)],
    );
    expect(cycle.stageAt(5).id, 'young');
    expect(cycle.stageAt(30).id, 'adult');
    expect(cycle.growthAt(5), greaterThan(0));
  });

  test(
    'needs, perception, memory, personality and utility are deterministic',
    () {
      final needs = NeedsState({'hunger': 0.8, 'safety': 0.2});
      expect(needs.priority(), 'hunger');
      const perception = Perception(range: 10, occluded: false);
      expect(perception.canSee(distance: 8), isTrue);
      final memory = CreatureMemory();
      memory.remember('river', strength: .9);
      expect(memory.strengthOf('river'), .9);
      const personality = Personality(curiosity: .8, aggression: .2);
      expect(personality.variationScore, closeTo(.6, .001));
      expect(UtilityGoal.score(need: .8, distance: 2), closeTo(.4, .001));
    },
  );
}
