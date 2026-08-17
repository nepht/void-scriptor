import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/simulation/domain/npc.dart';

void main() {
  group('NpcAgent', () {
    test('holds identity, needs, personality, goals', () {
      const npc = NpcAgent(
        id: 'n1',
        name: 'Elder Voss',
        simulationLevel: NpcSimulationLevel.full,
        needs: [NpcNeed(id: 'hunger', label: 'Hunger', value: 0.2)],
        personality: NpcPersonality(openness: 4, conscientiousness: 5),
        goals: [
          NpcGoal(id: 'g1', description: 'Protect the shrine', priority: 3),
        ],
      );
      expect(npc.name, 'Elder Voss');
      expect(npc.simulationLevel, NpcSimulationLevel.full);
      expect(npc.needs.first.value, 0.2);
      expect(npc.goals.first.priority, 3);
    });
  });

  group('NpcSimulationLevel', () {
    test('exposes levels in order', () {
      expect(NpcSimulationLevel.values.map((e) => e.name), [
        'static',
        'reactive',
        'routine',
        'full',
      ]);
    });
  });

  group('MemoryModel', () {
    test('decays with time', () {
      final memory = MemoryModel(
        id: 'm1',
        npcId: 'n1',
        content: 'The stranger arrived at dawn',
        strength: 1.0,
        lastAccessedAt: DateTime.utc(2026, 1, 1),
      );
      final decayed = memory.decayed(
        now: DateTime.utc(2026, 1, 8),
        halfLifeDays: 7,
      );
      expect(decayed.strength, lessThan(1.0));
      expect(decayed.strength, greaterThan(0.4));
    });
  });

  group('RelationshipState', () {
    test('tracks relationship value', () {
      const rel = RelationshipState(
        id: 'r1',
        npcId: 'n1',
        otherEntityId: 'n2',
        value: 0.8,
      );
      expect(rel.value, 0.8);
    });
  });
}
