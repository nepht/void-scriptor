/// Sprint 110.26 - Age-at-Time Calculation (Wave 2 F14 step 1).
///
/// Domain-only service that resolves a character birth/death/scene dates
/// against a chosen [CustomCalendar] and computes integer years + remaining
/// days at a given scene tick. Consumes [CalendarDate] (110.13) and
/// [CalendarConversionService] (110.14). No persistence, UI, wall clock,
/// locale, global random, or network input.
library;

import "calendar_conversion.dart";
import "custom_calendar.dart";

class CharacterLifeSpan {
  const CharacterLifeSpan({
    required this.characterId,
    required this.birthTick,
    required this.deathTick,
    required this.unknownDates,
  });

  final String characterId;
  final int? birthTick;
  final int? deathTick;
  final CharacterUnknownDates unknownDates;
}

class CharacterUnknownDates {
  const CharacterUnknownDates({
    required this.birthUnknown,
    required this.deathUnknown,
  });

  final bool birthUnknown;
  final bool deathUnknown;

  static const CharacterUnknownDates none = CharacterUnknownDates(
    birthUnknown: false,
    deathUnknown: false,
  );
}

class CharacterDateResolution {
  const CharacterDateResolution({
    required this.characterId,
    required this.tick,
    required this.calendarId,
    required this.date,
  });

  final String characterId;
  final int tick;
  final String calendarId;
  final CalendarDate date;
}

class AgeAtTimeResult {
  const AgeAtTimeResult({
    required this.characterId,
    required this.atTick,
    required this.calendarId,
    required this.birthDate,
    required this.sceneDate,
    required this.deathDate,
    required this.ageYears,
    required this.remainingDays,
    required this.isAliveAtScene,
    required this.explanation,
  });

  final String characterId;
  final int atTick;
  final String calendarId;
  final CharacterDateResolution? birthDate;
  final CharacterDateResolution sceneDate;
  final CharacterDateResolution? deathDate;
  final int? ageYears;
  final int? remainingDays;
  final bool isAliveAtScene;

  final String explanation;
}

class CharacterAgeAtTimeService {
  CharacterAgeAtTimeService({
    required CalendarRegistry registry,
    CalendarConversionService? conversion,
  }) : _registry = registry,
       _conversion =
           conversion ?? CalendarConversionService(registry: registry);

  final CalendarRegistry _registry;
  final CalendarConversionService _conversion;

  int _daysPerYearFor(String calendarId) =>
      _registry.resolve(calendarId).daysPerYear;

  CharacterDateResolution resolveBirthDate({
    required String characterId,
    required int? birthTick,
    required String calendarId,
  }) {
    if (birthTick == null) {
      throw ArgumentError("birthTick is null but caller requested a date");
    }
    final display = _conversion.format(
      absoluteTick: birthTick,
      calendarId: calendarId,
    );
    return CharacterDateResolution(
      characterId: characterId,
      tick: birthTick,
      calendarId: calendarId,
      date: display.date,
    );
  }

  AgeAtTimeResult resolve({
    required CharacterLifeSpan record,
    required int atTick,
    required String calendarId,
  }) {
    if (atTick < 0) {
      throw ArgumentError("atTick cannot be negative");
    }
    if (record.birthTick == null && !record.unknownDates.birthUnknown) {
      throw ArgumentError(
        "birthTick null and birthUnknown false for "
        "$record.characterId",
      );
    }
    final explanations = <String>[];

    CharacterDateResolution? birth;
    if (record.birthTick != null) {
      birth = resolveBirthDate(
        characterId: record.characterId,
        birthTick: record.birthTick,
        calendarId: calendarId,
      );
      if (atTick < record.birthTick!) {
        throw ArgumentError(
          "scene tick $atTick before birth "
          "$record.birthTick for $record.characterId",
        );
      }
    } else {
      explanations.add("birth_unknown");
    }

    final sceneDisplay = _conversion.format(
      absoluteTick: atTick,
      calendarId: calendarId,
    );
    final sceneResolution = CharacterDateResolution(
      characterId: record.characterId,
      tick: atTick,
      calendarId: calendarId,
      date: sceneDisplay.date,
    );

    CharacterDateResolution? death;
    var isAlive = true;
    if (record.deathTick != null) {
      death = CharacterDateResolution(
        characterId: record.characterId,
        tick: record.deathTick!,
        calendarId: calendarId,
        date: _conversion
            .format(absoluteTick: record.deathTick!, calendarId: calendarId)
            .date,
      );
      if (atTick > record.deathTick!) {
        isAlive = false;
        explanations.add("after_death");
      }
    } else if (record.unknownDates.deathUnknown) {
      explanations.add("death_unknown");
    }

    int? years;
    int? remaining;
    if (birth != null) {
      final delta = atTick - record.birthTick!;
      // Use the calendar year number so the result respects the active
      // calendar (360/365/etc.) instead of a hard-coded 365.
      years = sceneResolution.date.yearNumber - birth.date.yearNumber;
      remaining = delta % _daysPerYearFor(calendarId);
    }

    return AgeAtTimeResult(
      characterId: record.characterId,
      atTick: atTick,
      calendarId: calendarId,
      birthDate: birth,
      sceneDate: sceneResolution,
      deathDate: death,
      ageYears: years,
      remainingDays: remaining,
      isAliveAtScene: isAlive,
      explanation: explanations.join(","),
    );
  }
}
