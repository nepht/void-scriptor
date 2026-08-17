/// Sprint 46 — Step 46.1–46.8 Simulation Core, Clock, World State.
enum SimulationMode { paused, step, play, fastForward, turbo }

class SimulationClock {
  const SimulationClock({
    required this.id,
    required this.simulationTime,
    this.speed = 1.0,
    this.mode = SimulationMode.paused,
  });

  final String id;
  final DateTime simulationTime;
  final double speed;
  final SimulationMode mode;

  SimulationClock tick(Duration wallDelta) {
    final simDelta = Duration(
      microseconds: (wallDelta.inMicroseconds * speed).round(),
    );
    return SimulationClock(
      id: id,
      simulationTime: simulationTime.add(simDelta),
      speed: speed,
      mode: SimulationMode.play,
    );
  }
}

class SimulationWorld {
  SimulationWorld({
    required this.id,
    required this.name,
    this.seed,
    bool? isDeterministic,
  }) : isDeterministic = isDeterministic ?? (seed != null);

  final String id;
  final String name;
  final int? seed;
  final bool isDeterministic;
}

class WorldState {
  const WorldState({
    required this.id,
    required this.worldId,
    required this.tick,
    this.layers = const [],
  });

  final String id;
  final String worldId;
  final int tick;
  final List<StateLayer> layers;
}

class StateLayer {
  const StateLayer({
    required this.id,
    required this.name,
    this.data = const {},
  });

  final String id;
  final String name;
  final Map<String, Object> data;
}
