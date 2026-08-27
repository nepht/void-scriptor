/// Sprint 110.4 — Simulation Contract & Determinism.
library;

/// Explicit precision policy for simulation output.
class PrecisionPolicy {
  PrecisionPolicy({required this.decimalPlaces}) {
    if (decimalPlaces < 0) {
      throw ArgumentError('decimal places cannot be negative');
    }
  }

  final int decimalPlaces;

  double round(double value) {
    var factor = 1.0;
    for (var index = 0; index < decimalPlaces; index++) {
      factor *= 10;
    }
    return (value * factor).round() / factor;
  }
}

/// Named unit registry. It is immutable after construction.
class UnitRegistry {
  UnitRegistry(Map<String, String> definitions)
    : definitions = Map.unmodifiable(definitions) {
    if (definitions.isEmpty || definitions.values.any((unit) => unit.isEmpty)) {
      throw ArgumentError('unit names cannot be empty');
    }
  }

  final Map<String, String> definitions;

  String operator [](String key) => definitions[key] ?? '';
}

/// Immutable deterministic simulation input/output contract.
class SimulationContract {
  SimulationContract({
    required this.seed,
    required this.precision,
    required this.units,
  }) {
    if (seed < 0) throw ArgumentError('seed cannot be negative');
    if (units.definitions.isEmpty) {
      throw ArgumentError('at least one unit is required');
    }
  }

  final int seed;
  final PrecisionPolicy precision;
  final UnitRegistry units;

  SimulationResult run({required Map<String, double> inputs}) {
    if (inputs.isEmpty) {
      throw ArgumentError('simulation inputs cannot be empty');
    }
    for (final entry in inputs.entries) {
      if (!units.definitions.containsKey(entry.key)) {
        throw ArgumentError('input has no registered unit: ${entry.key}');
      }
      if (!entry.value.isFinite || entry.value < 0) {
        throw ArgumentError('input must be finite and non-negative');
      }
    }
    final frozenInputs = Map<String, double>.unmodifiable(inputs);
    final distance = frozenInputs['distance'];
    final duration = frozenInputs['duration'];
    final rawValue = distance != null && duration != null && duration != 0
        ? distance / duration
        : frozenInputs.values.reduce((a, b) => a + b);
    final value = precision.round(rawValue);
    final replayKey = _replayKey(frozenInputs);
    return SimulationResult(
      seed: seed,
      inputs: frozenInputs,
      units: units.definitions,
      precision: precision,
      value: value,
      replayKey: replayKey,
      explanation:
          'seed=$seed; formula=${distance != null && duration != null && duration != 0 ? 'distance/duration' : 'sum(inputs)'}; precision=${precision.decimalPlaces}; units=${units.definitions}',
    );
  }

  String _replayKey(Map<String, double> inputs) {
    final ordered = inputs.keys.toList()..sort();
    final body = ordered.map((key) => '$key=${inputs[key]}').join('|');
    return 'seed:$seed;$body;precision:${precision.decimalPlaces};units:${units.definitions}';
  }
}

/// Reproducible result with enough metadata to explain and replay it.
class SimulationResult {
  SimulationResult({
    required this.seed,
    required Map<String, double> inputs,
    required Map<String, String> units,
    required this.precision,
    required this.value,
    required this.replayKey,
    required this.explanation,
  }) : inputs = Map.unmodifiable(inputs),
       units = Map.unmodifiable(units);

  final int seed;
  final Map<String, double> inputs;
  final Map<String, String> units;
  final PrecisionPolicy precision;
  final double value;
  final String replayKey;
  final String explanation;
}
