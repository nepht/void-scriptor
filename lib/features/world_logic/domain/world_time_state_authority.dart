/// Sprint 110.3 — World Time & State Authority.
///
/// Domain-only authority for explicit world time, calendar conversion,
/// immutable state snapshots, isolated branches, and provenance.
/// No persistence, UI, hidden wall clock, locale, or random input.
library;

/// Explicit integer world tick. One tick is defined by the caller.
class WorldClock {
  WorldClock({int initialTick = 0}) : _tick = _requireNonNegative(initialTick);

  int _tick;

  static int _requireNonNegative(int value) {
    if (value < 0) throw ArgumentError('world tick cannot be negative');
    return value;
  }

  int get now => _tick;

  /// Advances by an explicit non-negative number of ticks.
  int advance(int ticks) {
    _requireNonNegative(ticks);
    _tick += ticks;
    return _tick;
  }
}

/// Calendar date produced from a world tick.
class WorldDate {
  const WorldDate({required this.year, required this.month, required this.day});

  final int year;
  final int month;
  final int day;

  @override
  bool operator ==(Object other) =>
      other is WorldDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);
}

/// Deterministic fixed-length calendar adapter.
class FixedCalendar {
  FixedCalendar({required this.daysPerYear, required this.daysPerMonth}) {
    if (daysPerYear <= 0 ||
        daysPerMonth <= 0 ||
        daysPerYear % daysPerMonth != 0) {
      throw ArgumentError('calendar dimensions must divide evenly');
    }
  }

  final int daysPerYear;
  final int daysPerMonth;

  int get monthsPerYear => daysPerYear ~/ daysPerMonth;

  /// Converts zero-based ticks into a one-based calendar date.
  WorldDate fromTick(int tick) {
    if (tick < 0) throw ArgumentError('calendar tick cannot be negative');
    final year = tick ~/ daysPerYear + 1;
    final dayOfYear = tick % daysPerYear;
    final month = dayOfYear ~/ daysPerMonth + 1;
    final day = dayOfYear % daysPerMonth + 1;
    return WorldDate(year: year, month: month, day: day);
  }
}

/// Origin and explanation for a derived or manually-created state.
class StateProvenance {
  const StateProvenance({
    required this.origin,
    this.sourceId = '',
    this.sourceRevision = '',
    this.reason = '',
  });

  final String origin;
  final String sourceId;
  final String sourceRevision;
  final String reason;
}

/// Immutable state at one world tick and branch.
class WorldStateSnapshot {
  WorldStateSnapshot({
    required this.tick,
    required this.branchId,
    required this.label,
    required Map<String, String> values,
    required this.provenance,
  }) : values = Map.unmodifiable(values);

  final int tick;
  final String branchId;
  final String label;
  final Map<String, String> values;
  final StateProvenance provenance;
}

/// Single source of truth for explicit world time and derived state.
class WorldStateAuthority {
  WorldStateAuthority({required this.clock}) {
    _branchValues['main'] = <String, String>{};
  }

  final WorldClock clock;
  final Map<String, Map<String, String>> _branchValues =
      <String, Map<String, String>>{};
  String _selectedBranch = 'main';

  String get selectedBranch => _selectedBranch;

  /// Creates an empty isolated branch; duplicate IDs are rejected.
  void createBranch({required String id}) {
    if (id.isEmpty) throw ArgumentError('branch id cannot be empty');
    if (_branchValues.containsKey(id)) {
      throw StateError('branch already exists: $id');
    }
    _branchValues[id] = Map<String, String>.of(_branchValues[_selectedBranch]!);
  }

  /// Selects an existing branch explicitly.
  void selectBranch(String id) {
    if (!_branchValues.containsKey(id)) {
      throw StateError('unknown branch: $id');
    }
    _selectedBranch = id;
  }

  /// Sets a value only in the selected branch.
  void setState({required String key, required String value}) {
    if (key.isEmpty) throw ArgumentError('state key cannot be empty');
    _branchValues[_selectedBranch]![key] = value;
  }

  /// Captures a detached snapshot. Default provenance is simulation.
  WorldStateSnapshot snapshot({
    required String label,
    StateProvenance provenance = const StateProvenance(origin: 'simulation'),
  }) {
    return WorldStateSnapshot(
      tick: clock.now,
      branchId: _selectedBranch,
      label: label,
      values: _branchValues[_selectedBranch]!,
      provenance: provenance,
    );
  }
}
