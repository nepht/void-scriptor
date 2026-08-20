import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/creature_survival.dart';

void main() {
  test('migration triggers and food web consumption respect capacity', () {
    expect(MigrationPolicy.shouldMigrate(temperature: 5, food: .2), isTrue);
    final web = FoodWeb(capacity: 10);
    web.consume('grass', 4);
    expect(web.remainingCapacity, 6);
    expect(web.canConsume(7), isFalse);
  });

  test('disturbance recovers and disease uses bounded parameters', () {
    final habitat = HabitatHealth(1);
    habitat.disturb(DisturbanceType.fire, severity: .6);
    expect(habitat.value, .4);
    habitat.recover(rate: .3);
    expect(habitat.value, .7);
    const disease = Disease(transmission: .8, mortality: .2);
    expect(disease.risk(contactRate: .5), closeTo(.4, .001));
  });

  test(
    'synthetic life, combat, injury, promotion, demotion and LOD are bounded',
    () {
      const synthetic = SyntheticLife(SyntheticGenome({'core': .9}));
      expect(synthetic.evolve(generation: 2).generation, 2);
      final combat = SurvivalCombat.resolve(attacker: 8, defender: 4);
      expect(combat.winner, 'attacker');
      expect(InjuryState.fromDamage(7), Injury.severe);
      final history = LifeHistory();
      history.promote('c1');
      expect(history.statusOf('c1'), LifeStatus.promoted);
      history.demote('c1');
      expect(history.statusOf('c1'), LifeStatus.wild);
      expect(CreatureLod.level(distanceMeters: 800), 3);
    },
  );
}
