// Sprint 110.16 - Calendar Weather Hooks (Wave 2 F5).
//
// Binds deterministic seasonal weather (110.13) with manual overrides and
// multi-tick forecast notes so world-builders can tweak weather without
// breaking canon. Domain-only, no persistence/UI/wall clock/network.
import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/calendar_weather_hooks.dart";
import "package:void_scriptor/features/world_logic/domain/custom_calendar.dart";
import "package:void_scriptor/features/world_logic/domain/travel_mode_profiles.dart"
    show WeatherCondition;

CustomCalendar _cal() => CustomCalendar(
  months: const <CustomMonth>[
    CustomMonth(name: "Jan", daysInMonth: 30, indexInYear: 0),
    CustomMonth(name: "Feb", daysInMonth: 30, indexInYear: 1),
    CustomMonth(name: "Mar", daysInMonth: 30, indexInYear: 2),
    CustomMonth(name: "Apr", daysInMonth: 30, indexInYear: 3),
  ],
);

void main() {
  group("seasonal_weather", () {
    test("sampler returns deterministic WeatherSample for a tick", () {
      final sampler = WeatherCalendarSampler(calendar: _cal(), seed: 42);
      final hooks = CalendarWeatherHooks(sampler: sampler);
      final sample = hooks.resolveAt(0);
      expect(sample.condition, isA<WeatherCondition>());
      expect(sample.tick, 0);
      expect(sample.provenance.origin, "calendar");
    });

    test("same tick + seed yields identical condition across calls", () {
      final sampler = WeatherCalendarSampler(calendar: _cal(), seed: 7);
      final hooks = CalendarWeatherHooks(sampler: sampler);
      expect(hooks.resolveAt(15).condition, hooks.resolveAt(15).condition);
    });
  });

  group("seeded_generation", () {
    test("different seeds produce independent streams", () {
      final samplerA = WeatherCalendarSampler(calendar: _cal(), seed: 1);
      final samplerB = WeatherCalendarSampler(calendar: _cal(), seed: 2);
      final hooksA = CalendarWeatherHooks(sampler: samplerA);
      final hooksB = CalendarWeatherHooks(sampler: samplerB);
      final streamA = [
        for (var t = 0; t < 60; t++) hooksA.resolveAt(t).condition,
      ];
      final streamB = [
        for (var t = 0; t < 60; t++) hooksB.resolveAt(t).condition,
      ];
      expect(streamA, isNot(equals(streamB)));
    });
  });

  group("manual_weather", () {
    test("override beats sampler for the exact tick", () {
      final sampler = WeatherCalendarSampler(calendar: _cal(), seed: 99);
      final hooks = CalendarWeatherHooks(sampler: sampler)
        ..setOverride(
          WeatherOverride(
            tick: 12,
            condition: WeatherCondition.hurricane,
            reason: "narrator override",
          ),
        );
      final sample = hooks.resolveAt(12);
      expect(sample.condition, WeatherCondition.hurricane);
      expect(sample.provenance.origin, "manual");
      expect(sample.provenance.reason, contains("narrator"));
    });

    test("unrelated tick still uses sampler", () {
      final sampler = WeatherCalendarSampler(calendar: _cal(), seed: 99);
      final hooks = CalendarWeatherHooks(sampler: sampler)
        ..setOverride(
          WeatherOverride(
            tick: 12,
            condition: WeatherCondition.clear,
            reason: "x",
          ),
        );
      final other = hooks.resolveAt(11);
      expect(other.provenance.origin, "calendar");
    });

    test("empty reason is rejected", () {
      final sampler = WeatherCalendarSampler(calendar: _cal(), seed: 1);
      final hooks = CalendarWeatherHooks(sampler: sampler);
      expect(
        () => hooks.setOverride(
          WeatherOverride(
            tick: 0,
            condition: WeatherCondition.rain,
            reason: "",
          ),
        ),
        throwsArgumentError,
      );
    });

    test("negative tick is rejected", () {
      final sampler = WeatherCalendarSampler(calendar: _cal(), seed: 1);
      final hooks = CalendarWeatherHooks(sampler: sampler);
      expect(
        () => hooks.setOverride(
          WeatherOverride(
            tick: -1,
            condition: WeatherCondition.rain,
            reason: "bad",
          ),
        ),
        throwsArgumentError,
      );
    });
  });

  group("forecast_notes", () {
    test("window returns one entry per tick with override precedence", () {
      final sampler = WeatherCalendarSampler(calendar: _cal(), seed: 5);
      final hooks = CalendarWeatherHooks(sampler: sampler)
        ..setOverride(
          WeatherOverride(
            tick: 2,
            condition: WeatherCondition.storm,
            reason: "festival override",
          ),
        );
      final forecast = hooks.forecastWindow(start: 0, length: 4);
      expect(forecast.entries.length, 4);
      expect(forecast.entries[0].tick, 0);
      expect(forecast.entries[2].condition, WeatherCondition.storm);
      expect(forecast.entries[2].provenance.origin, "manual");
      expect(forecast.entries[2].note, contains("festival"));
    });

    test("forecast note explains sampler origin when no override", () {
      final sampler = WeatherCalendarSampler(calendar: _cal(), seed: 5);
      final hooks = CalendarWeatherHooks(sampler: sampler);
      final forecast = hooks.forecastWindow(start: 0, length: 3);
      expect(forecast.entries[0].note, contains("seed"));
      expect(forecast.entries[0].provenance.origin, "calendar");
    });

    test("zero or negative length rejected", () {
      final sampler = WeatherCalendarSampler(calendar: _cal(), seed: 1);
      final hooks = CalendarWeatherHooks(sampler: sampler);
      expect(
        () => hooks.forecastWindow(start: 0, length: 0),
        throwsArgumentError,
      );
      expect(
        () => hooks.forecastWindow(start: 0, length: -3),
        throwsArgumentError,
      );
    });
  });

  group("provenance", () {
    test("manual override carries origin=manual and recorded reason", () {
      final sampler = WeatherCalendarSampler(calendar: _cal(), seed: 3);
      final hooks = CalendarWeatherHooks(sampler: sampler)
        ..setOverride(
          WeatherOverride(
            tick: 8,
            condition: WeatherCondition.blizzard,
            reason: "ritual cold snap",
          ),
        );
      final forecast = hooks.forecastWindow(start: 8, length: 1);
      expect(forecast.entries.single.provenance.origin, "manual");
      expect(
        forecast.entries.single.provenance.reason,
        contains("ritual cold snap"),
      );
    });
  });
}
