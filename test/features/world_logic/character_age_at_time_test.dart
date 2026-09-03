/// Sprint 110.26 - Age-at-Time Calculation (Wave 2 F14 step 1).
///
/// Domain-only service that calculates a character's age (in years and in
/// detailed CalendarDate terms) at a given scene tick using the chosen
/// [CustomCalendar] from a [CalendarRegistry]. Consumes CalendarDate from
/// 110.13 and CalendarConversionService from 110.14. No persistence, no UI,
/// no DateTime.now() / global random / network.
library;

import "package:flutter_test/flutter_test.dart";
import "package:void_scriptor/features/world_logic/domain/calendar_conversion.dart";
import "package:void_scriptor/features/world_logic/domain/character_age_at_time.dart";
import "package:void_scriptor/features/world_logic/domain/custom_calendar.dart";

void main() {
  group("CharacterAgeAtTime (Sprint 110.26)", () {
    final calendar = CustomCalendar(
      months: const [
        CustomMonth(name: "Jan", daysInMonth: 30, indexInYear: 0),
        CustomMonth(name: "Feb", daysInMonth: 30, indexInYear: 1),
        CustomMonth(name: "Mar", daysInMonth: 30, indexInYear: 2),
        CustomMonth(name: "Apr", daysInMonth: 30, indexInYear: 3),
        CustomMonth(name: "May", daysInMonth: 30, indexInYear: 4),
        CustomMonth(name: "Jun", daysInMonth: 30, indexInYear: 5),
        CustomMonth(name: "Jul", daysInMonth: 30, indexInYear: 6),
        CustomMonth(name: "Aug", daysInMonth: 30, indexInYear: 7),
        CustomMonth(name: "Sep", daysInMonth: 30, indexInYear: 8),
        CustomMonth(name: "Oct", daysInMonth: 30, indexInYear: 9),
        CustomMonth(name: "Nov", daysInMonth: 30, indexInYear: 10),
        CustomMonth(name: "Dec", daysInMonth: 30, indexInYear: 11),
      ],
    );
    final registry = CalendarRegistry({"main": calendar});
    final service = CharacterAgeAtTimeService(registry: registry);

    test(
      "birth_date: resolves character birth against the chosen calendar",
      () {
        final result = service.resolveBirthDate(
          characterId: "c-001",
          birthTick: 0,
          calendarId: "main",
        );
        expect(result.calendarId, "main");
        expect(result.date.yearNumber, 1);
        expect(result.date.monthIndex, 0);
        expect(result.date.dayOfMonth, 1);
      },
    );

    test("death_date: tracks optional death date when present", () {
      final resolved = service.resolve(
        record: const CharacterLifeSpan(
          characterId: "c-002",
          birthTick: 0,
          deathTick: 360 * 60,
          unknownDates: CharacterUnknownDates.none,
        ),
        atTick: 360 * 40,
        calendarId: "main",
      );
      expect(resolved.isAliveAtScene, isTrue);
      expect(resolved.deathDate, isNotNull);
      expect(resolved.deathDate!.date.yearNumber, 61);
    });

    test(
      "calendar_conversion: uses CalendarConversionService for the date",
      () {
        final resolved = service.resolve(
          record: const CharacterLifeSpan(
            characterId: "c-003",
            birthTick: 0,
            deathTick: null,
            unknownDates: CharacterUnknownDates.none,
          ),
          atTick: 360 * 25,
          calendarId: "main",
        );
        expect(resolved.birthDate!.calendarId, "main");
        expect(resolved.sceneDate.calendarId, "main");
        expect(resolved.sceneDate.date.yearNumber, 26);
      },
    );

    test(
      "age_at_scene: returns integer years (floor of day distance / daysPerYear)",
      () {
        final resolved = service.resolve(
          record: const CharacterLifeSpan(
            characterId: "c-004",
            birthTick: 0,
            deathTick: null,
            unknownDates: CharacterUnknownDates.none,
          ),
          atTick: 360 * 25 + 100,
          calendarId: "main",
        );
        expect(resolved.ageYears, 25);
        expect(resolved.remainingDays, 100);
      },
    );

    test("unknown_date_handling: returns null age when birth is unknown", () {
      final resolved = service.resolve(
        record: const CharacterLifeSpan(
          characterId: "c-005",
          birthTick: null,
          deathTick: null,
          unknownDates: CharacterUnknownDates(
            birthUnknown: true,
            deathUnknown: false,
          ),
        ),
        atTick: 1000,
        calendarId: "main",
      );
      expect(resolved.ageYears, isNull);
      expect(resolved.remainingDays, isNull);
      expect(resolved.birthDate, isNull);
      expect(resolved.isAliveAtScene, isTrue);
      expect(resolved.explanation, contains("birth_unknown"));
    });

    test("unknown_date_handling: returns DeathUnknown sentinel when death "
        "is unknown but recorded", () {
      final resolved = service.resolve(
        record: const CharacterLifeSpan(
          characterId: "c-006",
          birthTick: 0,
          deathTick: null,
          unknownDates: CharacterUnknownDates(
            birthUnknown: false,
            deathUnknown: true,
          ),
        ),
        atTick: 360 * 50,
        calendarId: "main",
      );
      expect(resolved.deathDate, isNull);
      expect(resolved.isAliveAtScene, isTrue);
      expect(resolved.explanation, contains("death_unknown"));
    });

    test("age_at_scene: rejects scene tick before birth", () {
      expect(
        () => service.resolve(
          record: const CharacterLifeSpan(
            characterId: "c-007",
            birthTick: 100,
            deathTick: null,
            unknownDates: CharacterUnknownDates.none,
          ),
          atTick: 50,
          calendarId: "main",
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test("age_at_scene: marks dead when scene tick after death", () {
      final resolved = service.resolve(
        record: const CharacterLifeSpan(
          characterId: "c-008",
          birthTick: 0,
          deathTick: 100,
          unknownDates: CharacterUnknownDates.none,
        ),
        atTick: 200,
        calendarId: "main",
      );
      expect(resolved.isAliveAtScene, isFalse);
      expect(resolved.explanation, contains("after_death"));
    });

    test(
      "calendar_conversion: unknown calendar id propagates ArgumentError",
      () {
        expect(
          () => service.resolve(
            record: const CharacterLifeSpan(
              characterId: "c-009",
              birthTick: 0,
              deathTick: null,
              unknownDates: CharacterUnknownDates.none,
            ),
            atTick: 100,
            calendarId: "nope",
          ),
          throwsA(isA<ArgumentError>()),
        );
      },
    );
  });
}
