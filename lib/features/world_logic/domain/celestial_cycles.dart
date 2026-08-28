/// Sprint 110.15 - Celestial Cycles & Seasons (Wave 2 F5).
///
/// Domain-only models for moon and multi-body cycles, season rules,
/// festival dates, and a deterministic preview window. Consumes the
/// CustomCalendar + CelestialCycle from 110.13 and SeasonalCalendar from
/// 110.13. No persistence, UI, hidden wall clock, locale, global random,
/// or network input.
library;

import "custom_calendar.dart";
import "route_network.dart" show Season;

/// A named celestial body driven by a single [CelestialCycle].
class CelestialBody {
  const CelestialBody({required this.name, required this.cycle});

  final String name;
  final CelestialCycle cycle;

  /// Phase label for [tick] (delegates to [CelestialCycle.phaseAt]).
  String phaseAt(int tick) => cycle.phaseAt(tick);

  /// Numeric phase index for [tick] (delegates to [CelestialCycle.phaseIndexAt]).
  int phaseIndexAt(int tick) => cycle.phaseIndexAt(tick);
}

/// Collection of celestial bodies, an optional seasonal calendar, and a set of
/// festivals, all anchored to a [CustomCalendar].
class CelestialSystem {
  CelestialSystem({
    required this.calendar,
    this.bodies = const <CelestialBody>[],
    this.seasonal,
    this.festivals = const <Festival>[],
  });

  final CustomCalendar calendar;
  final List<CelestialBody> bodies;
  final SeasonalCalendar? seasonal;
  final List<Festival> festivals;

  /// Returns the body registered under [name] or throws ArgumentError.
  CelestialBody body(String name) {
    for (final b in bodies) {
      if (b.name == name) return b;
    }
    throw ArgumentError("unknown celestial body: ");
  }

  /// True when every body is at phase index 0 at [tick].
  bool alignmentAt(int tick) {
    for (final b in bodies) {
      if (b.phaseIndexAt(tick) != 0) return false;
    }
    return true;
  }
}

/// Single recurring festival attached to a [FestivalMatcher].
class Festival {
  const Festival({required this.id, required this.name, required this.matcher});

  final String id;
  final String name;
  final FestivalMatcher matcher;

  bool isActiveAt(int tick, CelestialSystem system) =>
      matcher.matches(tick, system);
}

/// Strategy for deciding whether a festival fires at [tick].
abstract class FestivalMatcher {
  bool matches(int tick, CelestialSystem system);
}

/// Fires exactly on [tick] (absolute, does not repeat).
class FixedTickFestival implements FestivalMatcher {
  const FixedTickFestival(this.tick);
  final int tick;
  @override
  bool matches(int tick, CelestialSystem system) => tick == this.tick;
}

/// Fires when the named body is at the given phase index.
class LunarFestival implements FestivalMatcher {
  const LunarFestival(this.bodyName, this.phaseIndex);
  final String bodyName;
  final int phaseIndex;
  @override
  bool matches(int tick, CelestialSystem system) {
    final b = system.body(bodyName);
    return b.phaseIndexAt(tick) == phaseIndex;
  }
}

/// Fires on the same month+day each year (resolved via the system calendar).
class MonthlyFestival implements FestivalMatcher {
  const MonthlyFestival({required this.monthIndex, required this.dayOfMonth});
  final int monthIndex;
  final int dayOfMonth;
  @override
  bool matches(int tick, CelestialSystem system) {
    final d = system.calendar.dateFromTick(tick);
    return d.monthIndex == monthIndex && d.dayOfMonth == dayOfMonth;
  }
}

/// One tick of a [CyclePreview] window.
class CyclePreviewEntry {
  const CyclePreviewEntry({
    required this.tick,
    required this.date,
    required this.season,
    required this.bodyPhases,
    required this.activeFestivals,
  });

  final int tick;
  final CalendarDate date;
  final Season season;
  final Map<String, String> bodyPhases;
  final List<String> activeFestivals;
}

/// Builds a deterministic preview of celestial state for a [CelestialSystem]
/// over a half-open tick range [start, start + length).
class CyclePreview {
  const CyclePreview(this.system);
  final CelestialSystem system;

  List<CyclePreviewEntry> window(int start, int length) {
    if (length < 0) {
      throw ArgumentError("length must be >= 0");
    }
    final out = <CyclePreviewEntry>[];
    for (int i = 0; i < length; i++) {
      final t = start + i;
      final date = system.calendar.dateFromTick(t);
      final season = system.seasonal != null
          ? system.seasonal!.seasonAt(t)
          : Season.spring;
      final bodyPhases = <String, String>{
        for (final b in system.bodies) b.name: b.phaseAt(t),
      };
      final activeFestivals = <String>[
        for (final f in system.festivals)
          if (f.isActiveAt(t, system)) f.id,
      ];
      out.add(
        CyclePreviewEntry(
          tick: t,
          date: date,
          season: season,
          bodyPhases: Map<String, String>.unmodifiable(bodyPhases),
          activeFestivals: List<String>.unmodifiable(activeFestivals),
        ),
      );
    }
    return List<CyclePreviewEntry>.unmodifiable(out);
  }
}
