import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/creature_population.dart';

void main() {
  for (final routes in [0, -1]) {
    test('predator pressure rejects escapeRoutes $routes', () {
      expect(
        () => PredatorPressure.response(preyAlert: .8, escapeRoutes: routes),
        throwsA(
          isA<ArgumentError>().having((e) => e.name, 'name', 'escapeRoutes'),
        ),
      );
    });
  }

  for (final alert in [double.nan, double.infinity, double.negativeInfinity]) {
    test('predator pressure rejects non-finite preyAlert $alert', () {
      expect(
        () => PredatorPressure.response(preyAlert: alert, escapeRoutes: 2),
        throwsA(
          isA<ArgumentError>().having((e) => e.name, 'name', 'preyAlert'),
        ),
      );
    });
  }

  test('predator pressure preserves finite response and clamping', () {
    expect(PredatorPressure.response(preyAlert: 0, escapeRoutes: 1), 1);
    expect(PredatorPressure.response(preyAlert: .2, escapeRoutes: 2), .7);
    expect(PredatorPressure.response(preyAlert: -2, escapeRoutes: 2), 0);
    expect(PredatorPressure.response(preyAlert: 2, escapeRoutes: 2), 1);
  });

  test('groups move with bounded boid separation and leadership', () {
    final group = CreatureGroup(id: 'g1', type: GroupType.herd);
    group.add('a');
    group.add('b');
    group.setLeader('a');
    expect(group.leader, 'a');
    expect(group.movement(separation: 2, cohesion: 3), 5);
    expect(group.lod(distanceMeters: 1000), 2);
  });

  test('territory conflict and predator prey response are explicit', () {
    const conflict = TerritoryConflict('north', 'south');
    expect(conflict.resolve(defenderStrength: 3, attackerStrength: 5), 'south');
    expect(
      PredatorPressure.response(preyAlert: .8, escapeRoutes: 2),
      greaterThan(.3),
    );
    expect(
      HuntingStrategy.choose(preyDistance: 2, energy: .9),
      HuntAction.pursue,
    );
  });

  test(
    'reproduction inherits traits with bounded safe mutation and fitness',
    () {
      const parentA = ReproductiveGenome({'speed': .4, 'vision': .8});
      const parentB = ReproductiveGenome({'speed': .6, 'vision': .6});
      final child = Reproduction.offspring(
        parentA,
        parentB,
        mutation: .1,
        seed: 2,
      );
      expect(child.traits['speed'], inInclusiveRange(.4, .6));
      expect(child.traits['vision'], inInclusiveRange(.6, .8));
      expect(MutationSafety.isSafe(child), isTrue);
      expect(Fitness.score(child, environment: {'speed': .8}), greaterThan(0));
    },
  );

  test('population evolution remains opt-in and canon requires approval', () {
    final pool = GenomePool([parentGenome]);
    pool.evolutionTick(seed: 4);
    expect(pool.diversity, greaterThanOrEqualTo(0));
    expect(pool.divergenceThreshold(0.2), isTrue);
    expect(CanonApproval().approve('species-x'), isTrue);
  });
}

const parentGenome = ReproductiveGenome({'speed': .5});
