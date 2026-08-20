import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/creature_closeout.dart';

void main() {
  test('promotion converts state and applies explicit rules', () {
    const lifecycle = CreaturePromotionRules(minUtility: .7);
    expect(lifecycle.canPromote(utility: .8), isTrue);
    final state = lifecycle.promote('c1');
    expect(state.kind, CreatureStateKind.promoted);
    expect(lifecycle.demote(state).kind, CreatureStateKind.wild);
  });

  test(
    'visual generation and behavior animation preserve variation bounds',
    () {
      final visual = const CreatureVisualGenerator(
        seed: 12,
      ).generate('ashborn');
      expect(visual.speciesId, 'ashborn');
      expect(visual.variation, inInclusiveRange(0, 1));
      expect(BehaviorAnimation.fromBehavior('hunt'), AnimationState.pursue);
      expect(
        ProceduralAnimation.frame(AnimationState.pursue, tick: 3),
        greaterThanOrEqualTo(0),
      );
    },
  );

  test('runtime wildlife applies player consequence and ecosystem tick', () {
    final runtime = WildlifeRuntime(backgroundCount: 4);
    runtime.applyPlayerAction(PlayerAction.harvest, impact: .2);
    runtime.tick(hours: 2);
    expect(runtime.population, lessThan(4));
    expect(runtime.backgroundCount, 4);
    expect(runtime.ticks, 1);
  });

  test(
    'habitat, designer preview, experiments and protection are deterministic',
    () {
      const habitat = BiomeHabitat(
        'tropical-forest',
        temperature: .8,
        food: .9,
      );
      expect(habitat.suitability, greaterThan(.5));
      const designer = CreatureDesignerAgent();
      expect(
        designer.preview('winged ashborn').prompt,
        contains('winged ashborn'),
      );
      final evolution = ExperimentRunner().evolution(seed: 3, generations: 4);
      expect(evolution.generations, 4);
      expect(evolution.diversity, inInclusiveRange(0, 1));
      expect(ExperimentRunner().behavior('hunt').action, 'pursue');
      expect(CreatureCanonProtection().isProtected('Kokuen'), isTrue);
    },
  );

  test(
    'lineage, update frequency, metrics and long-term state are bounded',
    () {
      final lineage = LineageGraph();
      lineage.link('child', 'parent');
      expect(lineage.parentsOf('child'), contains('parent'));
      expect(UpdateFrequency.forLod(0), const Duration(milliseconds: 16));
      expect(DiversityMetric.calculate([.1, .4, .7]), closeTo(.6, .001));
      expect(BottleneckEvent.detect(population: 2, threshold: 3), isTrue);
      expect(ExtinctionState.fromPopulation(0), Extinction.extinct);
      final sim = LongTermSimulation();
      sim.run(ticks: 10);
      expect(sim.ticks, 10);
    },
  );
}
