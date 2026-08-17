import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/game/application/game_controller.dart';

void main() {
  group('GameController', () {
    test('initial state has no active level', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(gameProvider);
      expect(state.activeLevel, isNull);
    });

    test('selectLevel updates active level', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(gameProvider.notifier).selectLevel('level_01');
      final state = container.read(gameProvider);
      expect(state.activeLevel, 'level_01');
    });
  });
}
