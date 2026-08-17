import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/application/world_controller.dart';

void main() {
  group('WorldController', () {
    test('initial state has empty simulations', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(worldProvider);
      expect(state.simulations, isEmpty);
    });

    test('initial state has empty events', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final state = container.read(worldProvider);
      expect(state.events, isEmpty);
    });
  });
}
