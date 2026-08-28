/// Sprint 110.13 - Custom Calendar and Celestial Time (Wave 2 F5).
///
/// Domain-only calendar + celestial cycle + season derivation + deterministic
/// weather sampler. Consumes route Season from 110.9 and route WeatherCondition
/// from 110.10. No persistence, UI, hidden wall clock, locale, global random,
/// or network input.
library;

import "route_network.dart" show Season;
import "travel_mode_profiles.dart" show WeatherCondition;

/// One named month of a custom calendar.
class CustomMonth {
  const CustomMonth({
    required this.name,
    required this.daysInMonth,
    required this.indexInYear,
  });

  final String name;
  final int daysInMonth;
  final int indexInYear;

  @override
  bool operator ==(Object other) =>
      other is CustomMonth &&
      other.name == name &&
      other.daysInMonth == daysInMonth &&
      other.indexInYear == indexInYear;

  @override
  int get hashCode => Object.hash(name, daysInMonth, indexInYear);
}

/// A custom calendar built from an ordered list of named months.
class CustomCalendar {
  CustomCalendar({required List<CustomMonth> months})
    : _months = List<CustomMonth>.unmodifiable(_validate(months)),
      _byName = <String, CustomMonth>{for (final m in months) m.name: m};

  final List<CustomMonth> _months;
  final Map<String, CustomMonth> _byName;

  static List<CustomMonth> _validate(List<CustomMonth> months) {
    if (months.isEmpty) {
      throw ArgumentError("calendar must declare at least one month");
    }
    final seen = <String>{};
    for (final m in months) {
      if (m.name.isEmpty) {
        throw ArgumentError("month name cannot be empty");
      }
      if (m.daysInMonth <= 0) {
        throw ArgumentError("month has zero or negative days");
      }
      if (!seen.add(m.name)) {
        throw ArgumentError("duplicate month name");
      }
      if (m.indexInYear < 0 || m.indexInYear >= months.length) {
        throw ArgumentError("month indexInYear out of range");
      }
    }
    return months;
  }

  int get daysPerYear => _months.fold<int>(0, (acc, m) => acc + m.daysInMonth);
  int get monthsPerYear => _months.length;
  List<CustomMonth> get months => _months;

  CustomMonth? monthByName(String name) => _byName[name];

  CalendarDate dateFromTick(int tick) {
    if (tick < 0) {
      throw ArgumentError("calendar tick cannot be negative");
    }
    final yearNumber = tick ~/ daysPerYear + 1;
    var dayOfYear = tick % daysPerYear;
    for (final m in _months) {
      if (dayOfYear < m.daysInMonth) {
        return CalendarDate(
          yearNumber: yearNumber,
          monthIndex: m.indexInYear,
          monthName: m.name,
          dayOfMonth: dayOfYear + 1,
        );
      }
      dayOfYear -= m.daysInMonth;
    }
    throw StateError("unreachable tick off calendar");
  }

  int tickFromDate(CalendarDate date) {
    if (date.yearNumber <= 0) {
      throw ArgumentError("year must be positive");
    }
    var offset = 0;
    for (final m in _months) {
      if (m.indexInYear == date.monthIndex) {
        if (date.dayOfMonth < 1 || date.dayOfMonth > m.daysInMonth) {
          throw ArgumentError("dayOfMonth out of range");
        }
        return (date.yearNumber - 1) * daysPerYear +
            offset +
            (date.dayOfMonth - 1);
      }
      offset += m.daysInMonth;
    }
    throw ArgumentError("unknown monthIndex");
  }
}

/// One concrete calendar date resolved from a tick.
class CalendarDate {
  const CalendarDate({
    required this.yearNumber,
    required this.monthIndex,
    required this.monthName,
    required this.dayOfMonth,
  });

  final int yearNumber;
  final int monthIndex;
  final String monthName;
  final int dayOfMonth;
}

/// Named phases of one celestial cycle (lunar-style eight-phase default).
enum CelestialPhase {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  fullMoon,
  waningGibbous,
  lastQuarter,
  waningCrescent,
}

/// Deterministic celestial cycle of length [lengthInDays] ticks divided into
/// [phases] equal slices. Used for moon phases, tides, daylight curves, and
/// any periodic celestial signal that must be reproducible.
class CelestialCycle {
  CelestialCycle({
    required this.name,
    required this.lengthInDays,
    required this.phases,
  }) {
    if (lengthInDays <= 0) {
      throw ArgumentError("lengthInDays must be > 0");
    }
    if (phases <= 0) {
      throw ArgumentError("phases must be > 0");
    }
    if (name.isEmpty) {
      throw ArgumentError("cycle name cannot be empty");
    }
  }

  final String name;
  final int lengthInDays;
  final int phases;

  void _validate() {
    if (lengthInDays <= 0) {
      throw ArgumentError("lengthInDays must be > 0");
    }
    if (phases <= 0) {
      throw ArgumentError("phases must be > 0");
    }
    if (name.isEmpty) {
      throw ArgumentError("cycle name cannot be empty");
    }
  }

  /// Public phase index for [tick], mirroring [_phaseIndexFor].
  /// Added for Sprint 110.15 (Celestial Cycles & Seasons).
  int phaseIndexAt(int tick) {
    final mod = tick % lengthInDays;
    final normalized = mod < 0 ? mod + lengthInDays : mod;
    return (normalized * phases) ~/ lengthInDays;
  }

  int _phaseIndexFor(int tick) {
    final mod = tick % lengthInDays;
    final normalized = mod < 0 ? mod + lengthInDays : mod;
    return (normalized * phases) ~/ lengthInDays;
  }

  String phaseAt(int tick) {
    _validate();
    final index = _phaseIndexFor(tick);
    if (phases == 8) {
      return CelestialPhase.values[index].name;
    }
    return ".phase";
  }

  List<String> phaseDistribution(int start, int end) {
    if (end < start) {
      throw ArgumentError("end must be >= start");
    }
    final seen = <String>{};
    for (int t = start; t < end; t++) {
      seen.add(phaseAt(t));
    }
    return List<String>.unmodifiable(seen);
  }
}

/// Maps a CustomCalendar to one Season per month index. The map must
/// cover every month in the calendar, otherwise the constructor throws.
class SeasonalCalendar {
  SeasonalCalendar({
    required CustomCalendar calendar,
    required Map<int, Season> seasonByMonth,
  }) : calendar = calendar,
       _seasonByMonth = Map<int, Season>.unmodifiable(seasonByMonth) {
    final expected = calendar.monthsPerYear;
    if (seasonByMonth.length != expected) {
      throw ArgumentError("seasonByMonth must cover all months");
    }
    for (int i = 0; i < expected; i++) {
      if (!seasonByMonth.containsKey(i)) {
        throw ArgumentError("seasonByMonth missing month index");
      }
    }
  }

  final CustomCalendar calendar;
  final Map<int, Season> _seasonByMonth;

  Season seasonAt(int tick) {
    final date = calendar.dateFromTick(tick);
    return _seasonByMonth[date.monthIndex]!;
  }

  /// Lower-cased season name for [tick]. (Sprint 110.15 season_rules.)
  String seasonNameAt(int tick) => seasonAt(tick).name.toLowerCase();

  /// True when the season map covers every month of the calendar.
  /// (Sprint 110.15 season_rules.)
  bool get coversAllMonths {
    final expected = calendar.monthsPerYear;
    if (_seasonByMonth.length != expected) return false;
    for (int i = 0; i < expected; i++) {
      if (!_seasonByMonth.containsKey(i)) return false;
    }
    return true;
  }
}

/// Deterministic weather sample produced by a calendar-bound sampler.
class WeatherSample {
  const WeatherSample({
    required this.condition,
    required this.tick,
    required this.provenance,
  });

  final WeatherCondition condition;
  final int tick;
  final CalendarWeatherProvenance provenance;
}

/// Provenance for a WeatherSample produced by a calendar-bound sampler.
class CalendarWeatherProvenance {
  const CalendarWeatherProvenance({
    required this.origin,
    required this.sourceId,
    required this.reason,
  });

  final String origin;
  final String sourceId;
  final String reason;
}

/// Deterministic weather sampler that binds a CustomCalendar to a seed and
/// produces a WeatherCondition per tick. Same (calendar, seed, tick) always
/// yields the same condition and provenance payload.
class WeatherCalendarSampler {
  WeatherCalendarSampler({required this.calendar, required this.seed});

  final CustomCalendar calendar;
  final int seed;

  WeatherSample sampleAt(int tick) {
    if (tick < 0) {
      throw ArgumentError("tick cannot be negative");
    }
    final date = calendar.dateFromTick(tick);
    final roll = _mix(seed, tick, date.yearNumber, date.monthIndex) % 100;
    final WeatherCondition condition;
    if (roll < 60) {
      condition = WeatherCondition.clear;
    } else if (roll < 75) {
      condition = WeatherCondition.rain;
    } else if (roll < 85) {
      condition = WeatherCondition.storm;
    } else if (roll < 95) {
      condition = WeatherCondition.blizzard;
    } else {
      condition = WeatherCondition.hurricane;
    }
    final provenance = CalendarWeatherProvenance(
      origin: "calendar.weather",
      sourceId: "seed:$seed#tick:$tick",
      reason:
          "month=${date.monthName} y=${date.yearNumber} "
          "d=${date.dayOfMonth} roll=$roll",
    );
    return WeatherSample(
      condition: condition,
      tick: tick,
      provenance: provenance,
    );
  }

  static int _mix(int seed, int tick, int year, int monthIndex) {
    int h = seed & 0xFFFFFFFF;
    h = (h ^ (tick * 2654435761)) & 0xFFFFFFFF;
    h = (h ^ (year * 1597334677)) & 0xFFFFFFFF;
    h = (h ^ (monthIndex * 374761393)) & 0xFFFFFFFF;
    h = ((h << 13) | (h >> 19)) & 0xFFFFFFFF;
    h = (h * 5 + 0xe6546b64) & 0xFFFFFFFF;
    h = ((h << 17) | (h >> 15)) & 0xFFFFFFFF;
    h = (h * 0x85ebca6b) & 0xFFFFFFFF;
    h = (h ^ (h >> 16)) & 0xFFFFFFFF;
    return h & 0x7FFFFFFF;
  }
}
