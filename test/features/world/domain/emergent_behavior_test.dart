import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/emergent_behavior.dart';

void main() {
  test(
    'local interactions produce a deterministic cascade of group actions',
    () {
      const engine = EmergentBehaviorEngine();
      const agents = [
        EmergentAgent(id: 'scout', energy: .9, alertness: .8),
        EmergentAgent(id: 'forager', energy: .7, alertness: .2),
        EmergentAgent(id: 'guardian', energy: .8, alertness: .7),
      ];

      final result = engine.step(
        agents: agents,
        signals: const [
          EmergentSignal(sourceId: 'scout', kind: EmergentSignalKind.alert),
          EmergentSignal(
            sourceId: 'forager',
            kind: EmergentSignalKind.resource,
          ),
        ],
      );

      expect(result.actions.map((action) => action.kind), [
        EmergentActionKind.flee,
        EmergentActionKind.gather,
        EmergentActionKind.guard,
      ]);
      expect(
        result.nextAgents.every(
          (agent) => agent.energy >= 0 && agent.energy <= 1,
        ),
        isTrue,
      );
      expect(result.trace, [
        'scout:alert',
        'forager:resource',
        'guardian:guard',
      ]);
    },
  );

  test('cascade is bounded and preserves deterministic ordering', () {
    const engine = EmergentBehaviorEngine(maxActionsPerStep: 2);
    final result = engine.step(
      agents: const [
        EmergentAgent(id: 'a', energy: .5, alertness: .5),
        EmergentAgent(id: 'b', energy: .5, alertness: .5),
        EmergentAgent(id: 'c', energy: .5, alertness: .5),
      ],
      signals: const [
        EmergentSignal(sourceId: 'a', kind: EmergentSignalKind.resource),
        EmergentSignal(sourceId: 'b', kind: EmergentSignalKind.resource),
        EmergentSignal(sourceId: 'c', kind: EmergentSignalKind.resource),
      ],
    );

    expect(result.actions, hasLength(2));
    expect(result.trace, ['a:resource', 'b:resource']);
  });
}
