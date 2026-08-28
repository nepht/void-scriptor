// Sprint 110.16 - Calendar Weather Hooks (Wave 2 F5).
library;

import "custom_calendar.dart";
import "route_network.dart" show Season;
import "travel_mode_profiles.dart" show WeatherCondition;

class WeatherNote {
  const WeatherNote({
    required this.tick,
    required this.dateLabel,
    required this.condition,
    required this.note,
  });
  final int tick;
  final String dateLabel;
  final WeatherCondition condition;
  final String note;
}

class WeatherForecast {
  const WeatherForecast({required this.notes, required this.provenance});
  final List<WeatherNote> notes;
  final CalendarWeatherProvenance provenance;
}

class SeasonalDistribution {
  const SeasonalDistribution({
    this.clearWeight = 0,
    this.rainWeight = 0,
    this.stormWeight = 0,
    this.blizzardWeight = 0,
    this.hurricaneWeight = 0,
  });
  final int clearWeight;
  final int rainWeight;
  final int stormWeight;
  final int blizzardWeight;
  final int hurricaneWeight;
  int get totalWeight =>
      clearWeight + rainWeight + stormWeight + blizzardWeight + hurricaneWeight;
  WeatherCondition pickFromRoll(int roll) {
    int cursor = 0;
    if (cursor + clearWeight > roll) return WeatherCondition.clear;
    cursor += clearWeight;
    if (cursor + rainWeight > roll) return WeatherCondition.rain;
    cursor += rainWeight;
    if (cursor + stormWeight > roll) return WeatherCondition.storm;
    cursor += stormWeight;
    if (cursor + blizzardWeight > roll) return WeatherCondition.blizzard;
    return WeatherCondition.hurricane;
  }
}

class SeasonalDistributions {
  const SeasonalDistributions._();
  static const SeasonalDistribution winter = SeasonalDistribution(
    clearWeight: 25,
    rainWeight: 10,
    stormWeight: 25,
    blizzardWeight: 35,
    hurricaneWeight: 5,
  );
  static const SeasonalDistribution spring = SeasonalDistribution(
    clearWeight: 35,
    rainWeight: 45,
    stormWeight: 15,
    blizzardWeight: 0,
    hurricaneWeight: 5,
  );
  static const SeasonalDistribution summer = SeasonalDistribution(
    clearWeight: 60,
    rainWeight: 20,
    stormWeight: 12,
    blizzardWeight: 0,
    hurricaneWeight: 8,
  );
  static const SeasonalDistribution autumn = SeasonalDistribution(
    clearWeight: 30,
    rainWeight: 40,
    stormWeight: 25,
    blizzardWeight: 2,
    hurricaneWeight: 3,
  );
  static SeasonalDistribution forSeason(Season s) {
    switch (s) {
      case Season.winter:
        return winter;
      case Season.spring:
        return spring;
      case Season.summer:
        return summer;
      case Season.autumn:
        return autumn;
    }
  }
}

class CalendarWeatherHooks {
  CalendarWeatherHooks({
    required this.calendar,
    required this.seasons,
    required this.seed,
    this.manualOverrides = const <int, WeatherCondition>{},
  });
  final CustomCalendar calendar;
  final SeasonalCalendar seasons;
  final int seed;
  final Map<int, WeatherCondition> manualOverrides;

  WeatherSample weatherAt(int tick) {
    if (tick < 0) throw ArgumentError("tick cannot be negative");
    final override = manualOverrides[tick];
    if (override != null) {
      return WeatherSample(
        condition: override,
        tick: tick,
        provenance: CalendarWeatherProvenance(
          origin: "manual",
          sourceId: "seed:$seed#tick:$tick",
          reason: "manual override tick=$tick",
        ),
      );
    }
    final date = calendar.dateFromTick(tick);
    final season = seasons.seasonAt(tick);
    final distribution = SeasonalDistributions.forSeason(season);
    final mix = _mix(seed, tick, date.yearNumber, date.monthIndex, season);
    final roll = mix % distribution.totalWeight;
    final condition = distribution.pickFromRoll(roll);
    return WeatherSample(
      condition: condition,
      tick: tick,
      provenance: CalendarWeatherProvenance(
        origin: "calendar.weather",
        sourceId: "seed:$seed#tick:$tick",
        reason:
            "season=${season.name} month=${date.monthName} y=${date.yearNumber} d=${date.dayOfMonth} roll=$roll",
      ),
    );
  }

  WeatherForecast forecast({required int start, required int length}) {
    if (start < 0) throw ArgumentError("start cannot be negative");
    if (length <= 0) throw ArgumentError("length must be positive");
    final notes = <WeatherNote>[];
    for (var i = 0; i < length; i++) {
      final t = start + i;
      final sample = weatherAt(t);
      final date = calendar.dateFromTick(t);
      final dateLabel =
          "${date.monthName} d${date.dayOfMonth} y${date.yearNumber}";
      final note = "$dateLabel: ${sample.condition.name}";
      notes.add(
        WeatherNote(
          tick: t,
          dateLabel: dateLabel,
          condition: sample.condition,
          note: note,
        ),
      );
    }
    final end = start + length - 1;
    return WeatherForecast(
      notes: List<WeatherNote>.unmodifiable(notes),
      provenance: CalendarWeatherProvenance(
        origin: "calendar.weather",
        sourceId: "seed:$seed#span:$start..$end",
        reason: "forecast length=$length from tick=$start",
      ),
    );
  }

  static int _mix(int seed, int tick, int year, int monthIndex, Season season) {
    int h = seed & 0xFFFFFFFF;
    h = ((h ^ (tick * 2654435761)) & 0xFFFFFFFF);
    h = ((h ^ (year * 40503)) & 0xFFFFFFFF);
    h = ((h ^ (monthIndex * 2246822519)) & 0xFFFFFFFF);
    h = ((h ^ (season.index * 1442695040)) & 0xFFFFFFFF);
    h = ((h ^ (h >> 16)) & 0xFFFFFFFF);
    h = ((h * 2246822519) & 0xFFFFFFFF);
    h = ((h ^ (h >> 13)) & 0xFFFFFFFF);
    h = ((h * 3266489917) & 0xFFFFFFFF);
    h = ((h ^ (h >> 16)) & 0xFFFFFFFF);
    return h;
  }
}
