import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/game/domain/combat.dart';

void main() {
  group('CombatComponent', () {
    test('holds combat stats', () {
      const comp = CombatComponent(
        entityId: 'e1',
        health: 100,
        maxHealth: 100,
        attack: 15,
        defense: 10,
      );
      expect(comp.health, 100);
      expect(comp.attack, 15);
      expect(comp.isAlive, isTrue);
    });

    test('damage reduces health after defense', () {
      const comp = CombatComponent(
        entityId: 'e1',
        health: 100,
        maxHealth: 100,
        attack: 15,
        defense: 10,
      );
      final damaged = comp.takeDamage(30);
      expect(damaged.health, 80);
    });

    test('tough defender takes less damage', () {
      const comp = CombatComponent(
        entityId: 'e1',
        health: 100,
        maxHealth: 100,
        attack: 15,
        defense: 50,
      );
      final damaged = comp.takeDamage(30);
      expect(damaged.health, 100); // fully absorbed
    });

    test('fatal damage kills', () {
      const comp = CombatComponent(
        entityId: 'e1',
        health: 100,
        maxHealth: 100,
        attack: 15,
        defense: 10,
      );
      final dead = comp.takeDamage(150);
      expect(dead.health, 0);
      expect(dead.isAlive, isFalse);
    });
  });

  group('AttackType', () {
    test('exposes attack types', () {
      expect(AttackType.values.map((e) => e.name), [
        'light',
        'heavy',
        'ranged',
        'magic',
        'special',
        'signature',
      ]);
    });
  });

  group('ComboGraph', () {
    test('validates combo chain', () {
      const graph = ComboGraph(
        comboId: 'combo1',
        sequence: ['light', 'light', 'heavy'],
      );
      expect(graph.sequence, hasLength(3));
      expect(graph.isComplete, isFalse);
    });
  });

  group('WeaponComponent', () {
    test('holds weapon stats', () {
      const weapon = WeaponComponent(
        id: 'w1',
        entityId: 'e1',
        name: 'Void Shard Blade',
        damage: 25,
        weaponType: 'sword',
      );
      expect(weapon.damage, 25);
      expect(weapon.weaponType, 'sword');
    });
  });
}
