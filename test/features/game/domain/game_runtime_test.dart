import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/game/domain/hud.dart';
import 'package:void_scriptor/features/game/domain/physics.dart';
import 'package:void_scriptor/features/game/domain/network.dart';
import 'package:void_scriptor/features/game/domain/debug.dart';

void main() {
  group('SaveSlot', () {
    test('holds save slot info', () {
      final slot = SaveSlot(
        id: 's1',
        gameProjectId: 'g1',
        slotNumber: 1,
        savedAt: DateTime.utc(2026, 1, 1),
      );
      expect(slot.slotNumber, 1);
      expect(slot.compatible, isTrue);
    });
  });

  group('HudLayout', () {
    test('exposes canonical HUD elements', () {
      expect(HudElement.values.map((e) => e.name), [
        'healthBar',
        'manaBar',
        'staminaBar',
        'minimap',
        'questTracker',
        'inventoryBar',
        'dialogueBox',
        'bossBar',
      ]);
    });
  });

  group('GameplayPhysics', () {
    test('applies gravity', () {
      const phys = GameplayPhysics(gravity: -9.8, maxFallSpeed: 50.0);
      final updated = phys.applyGravity(velocity: 0, deltaSeconds: 1);
      expect(updated, closeTo(-9.8, 0.01));
    });
  });

  group('NetworkMode', () {
    test('exposes multiplayer modes', () {
      expect(NetworkMode.values.map((e) => e.name), [
        'offline',
        'coop',
        'versus',
        'massive',
      ]);
    });
  });

  group('PerformanceBudget', () {
    test('checks budget health', () {
      const budget = PerformanceBudget(frameTimeMs: 16.7, memoryMb: 400);
      expect(budget.frameTimeMs, 16.7);
      expect(budget.isHealthy, isTrue);
    });

    test('flags unhealthy budgets', () {
      const budget = PerformanceBudget(frameTimeMs: 40.0, memoryMb: 1200);
      expect(budget.isHealthy, isFalse);
    });
  });
}
