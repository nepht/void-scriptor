// ignore_for_file: prefer_const_constructors
// Sprint 110.16 - Calendar Weather Hooks (Wave 2 F5).
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/calendar_weather_hooks.dart";
import "package:void_scriptor/features/world_logic/domain/custom_calendar.dart";
import "package:void_scriptor/features/world_logic/domain/route_network.dart"
    show Season;
import "package:void_scriptor/features/world_logic/domain/travel_mode_profiles.dart"
    show WeatherCondition;

CustomCalendar _calendar() {
  return CustomCalendar(
    months: const [
      CustomMonth(name: "Frost", daysInMonth: 30, indexInYear: 0),
      CustomMonth(name: "Thaw", daysInMonth: 30, indexInYear: 1),
      CustomMonth(name: "Bloom", daysInMonth: 30, indexInYear: 2),
      CustomMonth(name: "Sun", daysInMonth: 30, indexInYear: 3),
      CustomMonth(name: "Harvest", daysInMonth: 30, indexInYear: 4),
      CustomMonth(name: "Ember", daysInMonth: 30, indexInYear: 5),
    ],
  );
}

SeasonalCalendar _seasonMap(CustomCalendar cal) {
  return SeasonalCalendar(
    calendar: cal,
    seasonByMonth: const {
      0: Season.winter,
      1: Season.winter,
      2: Season.spring,
      3: Season.summer,
      4: Season.autumn,
      5: Season.autumn,
    },
  );
}

void main() {
  group("seasonal_weather", () {
    test("winter distributes blizzard and storm more than summer", () {
      final hooks = CalendarWeatherHooks(
        calendar: _calendar(),
        seasons: _seasonMap(_calendar()),
        seed: 42,
      );
      var winterCount = 0, winterCold = 0, summerCount = 0, summerClear = 0;
      for (var t = 0; t < 240; t++) {
        final s = hooks.weatherAt(t);
        final month = _calendar().dateFromTick(t).monthIndex;
        if (month == 0 || month == 1) {
          winterCount++;
          if (s.condition == WeatherCondition.blizzard ||
              s.condition == WeatherCondition.storm) {
            winterCold++;
          }
        }
        if (month == 3) {
          summerCount++;
          if (s.condition == WeatherCondition.clear) summerClear++;
        }
      }
      expect(winterCount, greaterThan(0));
      expect(summerCount, greaterThan(0));
      expect(winterCold / winterCount, greaterThan(0.30));
      expect(summerClear / summerCount, greaterThan(0.50));
    });

    test("spring and autumn favor rain over storm", () {
      final hooks = CalendarWeatherHooks(
        calendar: _calendar(),
        seasons: _seasonMap(_calendar()),
        seed: 7,
      );
      var rainCount = 0, stormCount = 0;
      for (var t = 0; t < 240; t++) {
        final s = hooks.weatherAt(t);
        final month = _calendar().dateFromTick(t).monthIndex;
        if (month == 2 || month == 4 || month == 5) {
          if (s.condition == WeatherCondition.rain) rainCount++;
          if (s.condition == WeatherCondition.storm) stormCount++;
        }
      }
      expect(rainCount, greaterThan(stormCount));
    });
  });

  group("seeded_generation", () {
    test("same seed yields identical sequence across hooks", () {
      final a = CalendarWeatherHooks(
        calendar: _calendar(),
        seasons: _seasonMap(_calendar()),
        seed: 99,
      );
      final b = CalendarWeatherHooks(
        calendar: _calendar(),
        seasons: _seasonMap(_calendar()),
        seed: 99,
      );
      for (var t = 0; t < 30; t++) {
        expect(a.weatherAt(t).condition, b.weatherAt(t).condition);
      }
    });

    test("different seeds diverge for the same tick", () {
      final a = CalendarWeatherHooks(
        calendar: _calendar(),
        seasons: _seasonMap(_calendar()),
        seed: 1,
      );
      final b = CalendarWeatherHooks(
        calendar: _calendar(),
        seasons: _seasonMap(_calendar()),
        seed: 2,
      );
      var diffs = 0;
      for (var t = 0; t < 60; t++) {
        if (a.weatherAt(t).condition != b.weatherAt(t).condition) diffs++;
      }
      expect(diffs, greaterThan(0));
    });
  });

  group("manual_weather", () {
    test("manual override returns the override condition for that tick", () {
      final hooks = CalendarWeatherHooks(
        calendar: _calendar(),
        seasons: _seasonMap(_calendar()),
        seed: 1,
        manualOverrides: const {12: WeatherCondition.hurricane},
      );
      final s = hooks.weatherAt(12);
      expect(s.condition, WeatherCondition.hurricane);
      expect(s.provenance.origin, "manual");
      expect(s.provenance.reason, contains("tick=12"));
    });

    test("manual override does not change other ticks", () {
      final hooks = CalendarWeatherHooks(
        calendar: _calendar(),
        seasons: _seasonMap(_calendar()),
        seed: 1,
        manualOverrides: const {12: WeatherCondition.hurricane},
      );
      final s = hooks.weatherAt(13);
      expect(s.condition, isNot(WeatherCondition.hurricane));
    });

    test("manual override wins regardless of seasonal sample", () {
      final hooks = CalendarWeatherHooks(
        calendar: _calendar(),
        seasons: _seasonMap(_calendar()),
        seed: 1,
        manualOverrides: const {7: WeatherCondition.hurricane},
      );
      final s = hooks.weatherAt(7);
      expect(s.condition, WeatherCondition.hurricane);
      expect(s.provenance.origin, "manual");
    });
  });

  group("forecast_notes", () {
    test("produces one note per tick with date and condition", () {
      final hooks = CalendarWeatherHooks(
        calendar: _calendar(),
        seasons: _seasonMap(_calendar()),
        seed: 1,
      );
      final forecast = hooks.forecast(start: 0, length: 5);
      expect(forecast.notes.length, 5);
      for (final n in forecast.notes) {
        expect(n.tick, greaterThanOrEqualTo(0));
        expect(n.dateLabel, isNotEmpty);
        expect(n.note, isNotEmpty);
        expect(n.note, contains(n.dateLabel));
      }
    });

    test("forecast provenance aggregates origin and span", () {
      final hooks = CalendarWeatherHooks(
        calendar: _calendar(),
        seasons: _seasonMap(_calendar()),
        seed: 1,
      );
      final forecast = hooks.forecast(start: 10, length: 3);
      expect(forecast.provenance.origin, "calendar.weather");
      expect(forecast.provenance.sourceId, contains("seed:1"));
      expect(forecast.provenance.sourceId, contains("span:10..12"));
    });

    test("forecast notes reflect manual overrides", () {
      final hooks = CalendarWeatherHooks(
        calendar: _calendar(),
        seasons: _seasonMap(_calendar()),
        seed: 1,
        manualOverrides: const {2: WeatherCondition.hurricane},
      );
      final forecast = hooks.forecast(start: 0, length: 3);
      final n2 = forecast.notes.firstWhere((n) => n.tick == 2);
      expect(n2.note, contains("hurricane"));
    });
  });

  group("provenance", () {
    test("seasonal sample carries seed+season+roll provenance", () {
      final hooks = CalendarWeatherHooks(
        calendar: _calendar(),
        seasons: _seasonMap(_calendar()),
        seed: 5,
      );
      final s = hooks.weatherAt(35);
      expect(s.provenance.origin, "calendar.weather");
      expect(s.provenance.sourceId, contains("seed:5"));
      expect(s.provenance.sourceId, contains("tick:35"));
      expect(s.provenance.reason, contains("season="));
    });
  });
}
