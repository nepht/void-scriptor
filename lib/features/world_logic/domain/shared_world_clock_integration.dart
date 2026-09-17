import 'custom_calendar.dart';
import 'route_network.dart' show Season;
import 'world_time_state_authority.dart';

/// A bounded or open historical era on the canonical absolute tick line.
class WorldEra {
  const WorldEra({required this.id, required this.startTick, this.endTick})
    : assert(id != ''),
      assert(startTick >= 0),
      assert(endTick == null || endTick >= startTick);

  final String id;
  final int startTick;
  final int? endTick;

  bool contains(int tick) =>
      tick >= startTick && (endTick == null || tick <= endTick!);
}

/// Shared domain boundary for the calendar, timeline, era, season, and branch.
///
/// All derived values are resolved from one explicit absolute tick. It does
/// not read wall-clock time and does not persist project data.
class SharedWorldClockIntegration {
  SharedWorldClockIntegration({
    required this.calendar,
    required Map<int, Season> seasons,
    required List<WorldEra> eras,
    int initialTick = 0,
  }) : _clock = WorldClock(initialTick: initialTick),
       _seasons = Map<int, Season>.unmodifiable(seasons),
       _eras = List<WorldEra>.unmodifiable(eras) {
    if (_eras.isEmpty) throw ArgumentError('at least one era is required');
    if (!_seasons.keys.every(
      (key) => key >= 0 && key < calendar.monthsPerYear,
    )) {
      throw ArgumentError('season month index is outside the calendar');
    }
  }

  final CustomCalendar calendar;
  final WorldClock _clock;
  final Map<int, Season> _seasons;
  final List<WorldEra> _eras;
  String _branchId = 'main';
  final Set<String> _branches = <String>{'main'};

  int get now => _clock.now;
  String get branchId => _branchId;
  CalendarDate get date => calendar.dateFromTick(now);
  Season get season {
    final value = _seasons[date.monthIndex];
    if (value == null) {
      throw StateError('no season configured for month ${date.monthIndex}');
    }
    return value;
  }

  WorldEra get era {
    for (final candidate in _eras) {
      if (candidate.contains(now)) return candidate;
    }
    throw StateError('no era configured for tick $now');
  }

  int advance(int ticks) => _clock.advance(ticks);

  int tickFromDate(CalendarDate value) => calendar.tickFromDate(value);

  void createBranch(String id) {
    final normalized = id.trim();
    if (normalized.isEmpty) throw ArgumentError('branch id cannot be empty');
    if (!_branches.add(normalized)) {
      throw StateError('branch already exists: $normalized');
    }
  }

  void selectBranch(String id) {
    if (!_branches.contains(id)) throw StateError('unknown branch: $id');
    _branchId = id;
  }

  WorldStateSnapshot snapshot() => WorldStateSnapshot(
    tick: now,
    branchId: branchId,
    label: 'shared-world-clock',
    values: <String, String>{
      'calendar': date.monthName,
      'season': season.name,
      'era': era.id,
    },
    provenance: const StateProvenance(
      origin: 'shared-world-clock',
      reason: 'derived from one absolute tick',
    ),
  );
}
