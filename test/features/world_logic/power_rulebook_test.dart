import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/power_rulebook.dart';

void main() {
  test('rulebook stores abilities and their prerequisites', () {
    final ability = PowerAbility.validated(
      id: 'blink',
      name: 'Blink',
      prerequisites: [
        PowerPrerequisite.validated(
          id: 'focus',
          description: 'must maintain focus',
        ),
      ],
    );
    final book = PowerRulebook.validated(abilities: [ability]);

    expect(book.abilityById('blink'), same(ability));
    expect(book.abilityById('missing'), isNull);
    expect(ability.prerequisites.single.description, 'must maintain focus');
  });

  test('ability records costs, limits, side effects, and counters', () {
    final ability = PowerAbility.validated(
      id: 'overcharge',
      name: 'Overcharge',
      costs: [
        PowerCost.validated(
          resource: 'stamina',
          amount: 3,
          reason: 'physical strain',
        ),
      ],
      limits: [
        PowerLimit.validated(
          metric: 'uses_per_day',
          maximum: 2,
          reason: 'recovery required',
        ),
      ],
      sideEffects: [
        PowerSideEffect.validated(description: 'temporary tremor', severity: 4),
      ],
      counters: [
        PowerCounter.validated(
          description: 'interrupt concentration',
          effectiveness: 0.8,
        ),
      ],
    );
    final book = PowerRulebook.validated(abilities: [ability]);

    final stored = book.abilityById('overcharge')!;
    expect(stored.costs.single.amount, 3);
    expect(stored.limits.single.maximum, 2);
    expect(stored.sideEffects.single.severity, 4);
    expect(stored.counters.single.effectiveness, 0.8);
  });

  test('rulebook rejects duplicate abilities and invalid power values', () {
    expect(
      () => PowerRulebook.validated(
        abilities: [
          PowerAbility.validated(id: 'same', name: 'One'),
          PowerAbility.validated(id: 'same', name: 'Two'),
        ],
      ),
      throwsArgumentError,
    );
    expect(
      () => PowerCost.validated(resource: 'stamina', amount: 0, reason: 'none'),
      throwsArgumentError,
    );
    expect(
      () => PowerSideEffect.validated(description: 'bad', severity: 11),
      throwsArgumentError,
    );
    expect(
      () => PowerCounter.validated(description: 'bad', effectiveness: -0.1),
      throwsArgumentError,
    );
  });
}
