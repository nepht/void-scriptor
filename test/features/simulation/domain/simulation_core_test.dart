import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/simulation/domain/simulation_core.dart';

void main() {
  group('SimulationMode', () {
    test('exposes simulation modes', () {
      expect(SimulationMode.values.map((e) => e.name), [
        'paused',
        'step',
        'play',
        'fastForward',
        'turbo',
      ]);
    });
  });

  group('SimulationClock', () {
    test('tracks elapsed simulation time', () {
      final clock = SimulationClock(
        id: 'c1',
        simulationTime: DateTime.utc(2026, 1, 1),
        speed: 1.0,
      );
      expect(clock.speed, 1.0);
      expect(clock.mode, SimulationMode.paused);
    });

    test('advances by tick duration', () {
      final clock = SimulationClock(
        id: 'c1',
        simulationTime: DateTime.utc(2026, 1, 1),
        speed: 2.0,
      );
      final advanced = clock.tick(const Duration(hours: 1));
      expect(advanced.simulationTime, DateTime.utc(2026, 1, 1, 2));
      expect(advanced.mode, SimulationMode.play);
    });
  });

  group('WorldState', () {
    test('holds layered world state', () {
      const state = WorldState(
        id: 'w1',
        worldId: 'world1',
        tick: 100,
        layers: [
          StateLayer(id: 'l1', name: 'population', data: {'count': 500}),
          StateLayer(id: 'l2', name: 'weather', data: {'condition': 'rain'}),
        ],
      );
      expect(state.tick, 100);
      expect(state.layers.length, 2);
      expect(state.layers.first.data['count'], 500);
    });
  });

  group('SimulationWorld', () {
    test('creates with deterministic seed', () {
      final world = SimulationWorld(id: 'w1', name: 'Qowner Prime', seed: 42);
      expect(world.seed, 42);
      expect(world.isDeterministic, isTrue);
    });
  });
}
