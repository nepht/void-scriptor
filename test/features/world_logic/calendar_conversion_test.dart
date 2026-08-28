// Sprint 110.14 - Calendar Conversion & Display (Wave 2 F5).
library;

import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/calendar_conversion.dart";
import "package:void_scriptor/features/world_logic/domain/custom_calendar.dart";

void main() {
  group("absolute_time and calendar_date", () {
    final cal = CustomCalendar(
      months: const [
        CustomMonth(name: "Jan", daysInMonth: 31, indexInYear: 0),
        CustomMonth(name: "Feb", daysInMonth: 28, indexInYear: 1),
        CustomMonth(name: "Mar", daysInMonth: 31, indexInYear: 2),
      ],
    );
    final registry = CalendarRegistry({"gregorian_sim": cal});

    test("converts tick 0 to first day of year 1", () {
      final svc = CalendarConversionService(registry: registry);
      final display = svc.format(absoluteTick: 0, calendarId: "gregorian_sim");
      expect(display.calendarId, "gregorian_sim");
      expect(display.date.yearNumber, 1);
      expect(display.date.monthIndex, 0);
      expect(display.date.monthName, "Jan");
      expect(display.date.dayOfMonth, 1);
    });

    test("converts tick 31 to Feb 1", () {
      final svc = CalendarConversionService(registry: registry);
      final display = svc.format(absoluteTick: 31, calendarId: "gregorian_sim");
      expect(display.date.monthName, "Feb");
      expect(display.date.dayOfMonth, 1);
    });
  });

  group("round_trip", () {
    test("formatted date parses back to the same tick", () {
      final cal = CustomCalendar(
        months: const [
          CustomMonth(name: "Alpha", daysInMonth: 30, indexInYear: 0),
          CustomMonth(name: "Beta", daysInMonth: 30, indexInYear: 1),
          CustomMonth(name: "Gamma", daysInMonth: 30, indexInYear: 2),
        ],
      );
      final registry = CalendarRegistry({"world": cal});
      final svc = CalendarConversionService(registry: registry);
      for (final tick in [0, 1, 30, 31, 59, 60, 89, 365, 730, 12345]) {
        final display = svc.format(absoluteTick: tick, calendarId: "world");
        final parsed = svc.parse(display: display, calendarId: "world");
        expect(parsed, tick, reason: "tick= round-trip mismatch");
      }
    });
  });

  group("multiple_calendars", () {
    test("registry holds independent calendars with different layouts", () {
      final g = CustomCalendar(
        months: const [
          CustomMonth(name: "Jan", daysInMonth: 31, indexInYear: 0),
          CustomMonth(name: "Feb", daysInMonth: 28, indexInYear: 1),
        ],
      );
      final w = CustomCalendar(
        months: const [
          CustomMonth(name: "First", daysInMonth: 10, indexInYear: 0),
          CustomMonth(name: "Second", daysInMonth: 10, indexInYear: 1),
          CustomMonth(name: "Third", daysInMonth: 10, indexInYear: 2),
          CustomMonth(name: "Fourth", daysInMonth: 10, indexInYear: 3),
        ],
      );
      final registry = CalendarRegistry({"g": g, "w": w});
      final svc = CalendarConversionService(registry: registry);
      expect(registry.calendars, {"g", "w"});
      final gd = svc.format(absoluteTick: 31, calendarId: "g");
      final wd = svc.format(absoluteTick: 31, calendarId: "w");
      expect(gd.date.monthName, "Feb");
      expect(gd.date.dayOfMonth, 1);
      expect(wd.date.monthName, "Fourth");
      expect(wd.date.dayOfMonth, 2);
    });

    test("unknown calendar id raises ArgumentError", () {
      final registry = CalendarRegistry({});
      final svc = CalendarConversionService(registry: registry);
      expect(
        () => svc.format(absoluteTick: 0, calendarId: "missing"),
        throwsArgumentError,
      );
    });
  });

  group("locale_format", () {
    test("explicit locale changes display string but not date fields", () {
      final cal = CustomCalendar(
        months: const [
          CustomMonth(name: "Jan", daysInMonth: 31, indexInYear: 0),
          CustomMonth(name: "Feb", daysInMonth: 28, indexInYear: 1),
        ],
      );
      final registry = CalendarRegistry({"c": cal});
      final svc = CalendarConversionService(registry: registry);
      // tick 31 -> Feb 1 year 1
      final ymd = svc.format(
        absoluteTick: 31,
        calendarId: "c",
        locale: const CalendarLocale(id: "en", separator: "-", order: "ymd"),
      );
      final dmy = svc.format(
        absoluteTick: 31,
        calendarId: "c",
        locale: const CalendarLocale(id: "de", separator: ".", order: "dmy"),
      );
      final mdy = svc.format(
        absoluteTick: 31,
        calendarId: "c",
        locale: const CalendarLocale(id: "us", separator: "/", order: "mdy"),
      );
      expect(ymd.text, "1-1-1");
      expect(dmy.text, "1.1.1");
      expect(mdy.text, "1/1/1");
      // date fields invariant
      expect(ymd.date.yearNumber, 1);
      expect(ymd.date.monthIndex, 1);
      expect(ymd.date.dayOfMonth, 1);
    });

    test("default locale is explicit and stable", () {
      final cal = CustomCalendar(
        months: const [
          CustomMonth(name: "Jan", daysInMonth: 31, indexInYear: 0),
        ],
      );
      final registry = CalendarRegistry({"c": cal});
      final svc = CalendarConversionService(registry: registry);
      final a = svc.format(absoluteTick: 0, calendarId: "c");
      final b = svc.format(absoluteTick: 0, calendarId: "c");
      expect(a.text, b.text);
      expect(a.locale.id, isNotEmpty);
    });
  });

  group("absolute epoch", () {
    test("epoch offset shifts the displayed date deterministically", () {
      final cal = CustomCalendar(
        months: const [
          CustomMonth(name: "Jan", daysInMonth: 31, indexInYear: 0),
          CustomMonth(name: "Feb", daysInMonth: 28, indexInYear: 1),
        ],
      );
      final registry = CalendarRegistry({"c": cal});
      final svcA = CalendarConversionService(
        registry: registry,
        epoch: const CalendarEpoch(ticksAtEpoch: 0),
      );
      final svcB = CalendarConversionService(
        registry: registry,
        epoch: const CalendarEpoch(ticksAtEpoch: 31),
      );
      final a = svcA.format(absoluteTick: 31, calendarId: "c");
      final b = svcB.format(absoluteTick: 31, calendarId: "c");
      expect(a.date.monthName, "Feb");
      expect(a.date.dayOfMonth, 1);
      expect(b.date.monthName, "Jan");
      expect(b.date.dayOfMonth, 1);
    });
  });
}

// The service accepts a mutable registry, so its constructor cannot be const.
// ignore_for_file: prefer_const_constructors
