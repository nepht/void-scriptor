import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/game/domain/game_project.dart';
import 'package:void_scriptor/features/game/domain/runtime.dart';
import 'package:void_scriptor/features/game/domain/level.dart';
import 'package:void_scriptor/features/game/domain/movement.dart';

void main() {
  group('GameProject', () {
    test('creates game project with genre', () {
      final p = GameProject(
        id: 'g1',
        name: 'Void Cubes',
        genre: GameGenre.actionAdventure,
        template: GameTemplate.thirdPersonAction,
      );
      expect(p.name, 'Void Cubes');
      expect(p.genre, GameGenre.actionAdventure);
      expect(p.template, GameTemplate.thirdPersonAction);
      expect(p.levels, isEmpty);
    });

    test('copyWith updates fields', () {
      final p = GameProject(
        id: 'g1',
        name: 'Before',
        genre: GameGenre.puzzle,
        template: GameTemplate.blank,
      );
      final updated = p.copyWith(name: 'After', genre: GameGenre.rpg);
      expect(updated.name, 'After');
      expect(updated.genre, GameGenre.rpg);
      expect(updated.id, 'g1');
    });
  });

  group('EntityComponent', () {
    test('component holds key-value state', () {
      const comp = EntityComponent(
        id: 'c1',
        entityId: 'e1',
        type: 'transform',
        data: {'x': 1.0, 'y': 2.0},
      );
      expect(comp.type, 'transform');
      expect(comp.data['x'], 1.0);
    });
  });

  group('Level', () {
    test('holds level metadata', () {
      const level = Level(
        id: 'l1',
        gameProjectId: 'g1',
        name: 'Prologue',
        order: 1,
      );
      expect(level.name, 'Prologue');
      expect(level.order, 1);
    });
  });

  group('PlayerController', () {
    test('exposes movement state machine states', () {
      expect(MovementState.values.map((e) => e.name), [
        'idle',
        'walking',
        'running',
        'jumping',
        'falling',
        'climbing',
        'swimming',
        'dashing',
      ]);
    });
  });
}
