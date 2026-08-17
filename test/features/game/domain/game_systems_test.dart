import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/game/domain/abilities.dart';
import 'package:void_scriptor/features/game/domain/enemy_ai.dart';
import 'package:void_scriptor/features/game/domain/quests.dart';
import 'package:void_scriptor/features/game/domain/inventory.dart';

void main() {
  group('Ability', () {
    test('holds ability definition', () {
      const ability = Ability(
        id: 'a1',
        name: 'Void Slash',
        category: AbilityCategory.offensive,
        cooldownMs: 5000,
      );
      expect(ability.name, 'Void Slash');
      expect(ability.cooldownMs, 5000);
    });
  });

  group('EnemyAI', () {
    test('exposes AI states', () {
      expect(EnemyAiState.values.map((e) => e.name), [
        'idle',
        'patrol',
        'chase',
        'attack',
        'flee',
        'stunned',
        'dead',
      ]);
    });

    test('holds perception range', () {
      const ai = EnemyAI(
        id: 'ai1',
        entityId: 'e1',
        visionRange: 30.0,
        hearingRange: 15.0,
      );
      expect(ai.visionRange, 30.0);
      expect(ai.hearingRange, 15.0);
    });
  });

  group('Quest', () {
    test('holds quest definition', () {
      const q = Quest(id: 'q1', title: 'Seal the Rift', type: QuestType.main);
      expect(q.title, 'Seal the Rift');
      expect(q.type, QuestType.main);
      expect(q.status, QuestStatus.notStarted);
    });

    test('advances quest status', () {
      const q = Quest(id: 'q1', title: 'Seal the Rift', type: QuestType.side);
      final started = q.start();
      expect(started.status, QuestStatus.inProgress);
    });
  });

  group('Inventory', () {
    test('adds and removes items', () {
      const inv = Inventory(
        id: 'inv1',
        entityId: 'e1',
        items: [InventoryItem(id: 'i1', name: 'Potion', quantity: 2)],
      );
      expect(inv.items.first.quantity, 2);
      expect(inv.totalCount, 2);
    });
  });

  group('SkillTree', () {
    test('unlocks skills', () {
      const tree = SkillTree(
        id: 'st1',
        skillNodes: {'slash': const SkillNode(id: 'slash', name: 'Slash')},
        unlockedNodeIds: [],
      );
      final updated = tree.unlock('slash');
      expect(updated.unlockedNodeIds, ['slash']);
    });
  });
}
