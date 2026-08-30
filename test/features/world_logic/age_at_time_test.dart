// Sprint 110.26 - Age-at-Time Calculation (Wave 2 F6).
//
// Domain-only calculator that resolves the age of a character/person at a
// given scene tick using a calendar-aware tick arithmetic derived from the
// CalendarConversionService (110.14). Pure, deterministic, no persistence, UI,
// locale, network, wall clock, or random input.

library;

import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/age_at_time.dart";
import "package:void_scriptor/features/world_logic/domain/calendar_conversion.dart";
import "package:void_scriptor/features/world_logic/domain/custom_calendar.dart";

void main() {
  group("age_at_scene", () {
    // 90-day year (3 months x 30 days) keeps the arithmetic compact.
    final calendar = CustomCalendar(
      months: const [
        CustomMonth(name: "Jan", daysInMonth: 30, indexInYear: 0),
        CustomMonth(name: "Feb", daysInMonth: 30, indexInYear: 1),
        CustomMonth(name: "Mar", daysInMonth: 30, indexInYear: 2),
      ],
    );
    final registry = CalendarRegistry({"compact": calendar});
    final service = CalendarConversionService(registry: registry);

    test("returns full years elapsed between birth and scene tick", () {
      final calc = AgeCalculator(calendarId: "compact", conversion: service);
      // Birth at year 2 (tick 90 = day 1 of year 2). Scene at year 7 day 1 (tick 540).
      final result = calc.computeAt(
        personId: "p1",
        sceneTick: 540,
        birthTick: 90,
      );

      expect(result.isKnown, isTrue);
      expect(result.years, 5);
      expect(result.months, 0);
      expect(result.days, 0);
      expect(result.calendarText, isNotEmpty);
    });

    test("includes month/day remainder alongside full years", () {
      final calc = AgeCalculator(calendarId: "compact", conversion: service);
      // Birth tick 0 (year 1 day 1). Scene tick 90 + 45 = 135 = year 2 day 46.
      // Year diff = 1, month diff = 1, day diff = 45. So 1 year, 1 month, 45 days.
      final result = calc.computeAt(
        personId: "p2",
        sceneTick: 135,
        birthTick: 0,
      );

      expect(result.isKnown, isTrue);
      expect(result.years, 1);
      expect(result.months, 1);
      expect(result.days, 15);
    });

    test("borrows days across month boundary when day diff negative", () {
      final calc = AgeCalculator(calendarId: "compact", conversion: service);
      // Birth year 1 day 20 (tick 19). Scene year 2 day 5 (tick 90 + 4 = 94).
      // Day diff = 5 - 20 = -15, so borrow 30 days from previous month.
      // Expected: 0 years, 11 months, 15 days.
      final result = calc.computeAt(
        personId: "p2b",
        sceneTick: 94,
        birthTick: 19,
      );

      expect(result.years, 0);
      expect(result.months, 11);
      expect(result.days, 15);
    });

    test("death tick marks the result as deceased after the death tick", () {
      final calc = AgeCalculator(calendarId: "compact", conversion: service);
      final late = calc.computeAt(
        personId: "p3",
        sceneTick: 270 + 200,
        birthTick: 0,
        deathTick: 270,
      );

      expect(late.isKnown, isTrue);
      expect(late.years, 5);
      expect(late.isDeceased, isTrue);
    });

    test("death tick exactly at scene tick is also deceased", () {
      final calc = AgeCalculator(calendarId: "compact", conversion: service);
      final exact = calc.computeAt(
        personId: "p3b",
        sceneTick: 270,
        birthTick: 0,
        deathTick: 270,
      );

      expect(exact.isDeceased, isTrue);
    });

    test("scene tick before death remains alive", () {
      final calc = AgeCalculator(calendarId: "compact", conversion: service);
      final alive = calc.computeAt(
        personId: "p3c",
        sceneTick: 269,
        birthTick: 0,
        deathTick: 270,
      );

      expect(alive.isDeceased, isFalse);
    });

    test("unknown birth date reports unknown result with reason", () {
      final calc = AgeCalculator(calendarId: "compact", conversion: service);
      final result = calc.computeAt(personId: "ghost", sceneTick: 123);

      expect(result.isKnown, isFalse);
      expect(result.reason, isNotNull);
      expect(result.reason, contains("birth"));
    });

    test("scene tick before birth tick is invalid", () {
      final calc = AgeCalculator(calendarId: "compact", conversion: service);
      expect(
        () => calc.computeAt(personId: "p4", sceneTick: 100, birthTick: 1000),
        throwsA(isA<ArgumentError>()),
      );
    });

    test("negative birth tick is invalid", () {
      final calc = AgeCalculator(calendarId: "compact", conversion: service);
      expect(
        () => calc.computeAt(personId: "p4b", sceneTick: 0, birthTick: -1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test("death before birth is invalid", () {
      final calc = AgeCalculator(calendarId: "compact", conversion: service);
      expect(
        () => calc.computeAt(
          personId: "p4c",
          sceneTick: 200,
          birthTick: 100,
          deathTick: 50,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test("unknown calendar id throws ArgumentError", () {
      final calc = AgeCalculator(calendarId: "unknown", conversion: service);
      expect(
        () => calc.computeAt(personId: "p5", sceneTick: 100, birthTick: 0),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
