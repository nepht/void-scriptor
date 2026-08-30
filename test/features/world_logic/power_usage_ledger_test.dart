import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/power_usage_ledger.dart';

void main() {
  test(
    'records a power usage event with scene, resources, consequences, and source',
    () {
      final event = PowerUsageEvent.validated(
        id: 'use-1',
        abilityId: 'blink',
        actorId: 'qowner',
        sceneId: 'scene-7',
        tick: 12,
        resourceChanges: [
          PowerResourceChange.validated(
            resource: 'stamina',
            amount: -3,
            reason: 'activation',
          ),
        ],
        consequences: [
          PowerConsequence.validated(description: 'hands tremble', severity: 4),
        ],
        source: PowerUsageSource.validated(
          revision: 'draft-2',
          reason: 'scene manuscript',
        ),
      );

      expect(event.sceneId, 'scene-7');
      expect(event.resourceChanges.single.amount, -3);
      expect(event.consequences.single.description, 'hands tremble');
      expect(event.source.revision, 'draft-2');
    },
  );

  test('ledger orders events by tick and rejects duplicate ids', () {
    final first = PowerUsageEvent.validated(
      id: 'use-1',
      abilityId: 'a',
      actorId: 'p',
      sceneId: 's',
      tick: 20,
      source: PowerUsageSource.validated(revision: 'r1', reason: 'canon'),
    );
    final second = PowerUsageEvent.validated(
      id: 'use-2',
      abilityId: 'b',
      actorId: 'p',
      sceneId: 's',
      tick: 10,
      source: PowerUsageSource.validated(revision: 'r2', reason: 'canon'),
    );
    final ledger = PowerUsageLedger.validated(events: [first, second]);

    expect(ledger.forScene('s').map((e) => e.id), ['use-2', 'use-1']);
    expect(
      () => PowerUsageLedger.validated(events: [first, first]),
      throwsArgumentError,
    );
  });

  test(
    'validated usage data rejects invalid identity, tick, and resource values',
    () {
      expect(
        () => PowerUsageEvent.validated(
          id: '',
          abilityId: 'a',
          actorId: 'p',
          sceneId: 's',
          tick: 0,
          source: PowerUsageSource.validated(revision: 'r', reason: 'x'),
        ),
        throwsArgumentError,
      );
      expect(
        () => PowerUsageEvent.validated(
          id: 'u',
          abilityId: 'a',
          actorId: 'p',
          sceneId: 's',
          tick: -1,
          source: PowerUsageSource.validated(revision: 'r', reason: 'x'),
        ),
        throwsArgumentError,
      );
      expect(
        () =>
            PowerResourceChange.validated(resource: '', amount: 1, reason: 'x'),
        throwsArgumentError,
      );
      expect(
        () => PowerConsequence.validated(description: 'x', severity: 11),
        throwsArgumentError,
      );
    },
  );
}
