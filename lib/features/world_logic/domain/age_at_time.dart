// Sprint 110.26 - Age-at-Time Calculation (Wave 2 F6).
//
// Domain-only calculator that resolves the age of a character or person at a
// given scene tick using calendar-aware tick arithmetic derived from the
// [CalendarConversionService] introduced in 110.14. Pure, deterministic, no
// persistence, UI, locale, network, wall clock, or random input.

library;

import "calendar_conversion.dart";

/// Result of an age-at-time query.
///
/// When [isKnown] is false, [reason] explains why and the numeric fields are
/// meaningless. Otherwise the decomposition follows the calendar units used
/// by the requested calendar, and [calendarText] contains the rendered scene
/// date for display.
class AgeResult {
  const AgeResult({
    required this.isKnown,
    required this.years,
    required this.months,
    required this.days,
    required this.calendarText,
    required this.isDeceased,
    this.reason,
  });

  final bool isKnown;
  final int years;
  final int months;
  final int days;
  final String calendarText;
  final bool isDeceased;
  final String? reason;

  factory AgeResult.unknown(String reason) => AgeResult(
    isKnown: false,
    years: 0,
    months: 0,
    days: 0,
    calendarText: "",
    isDeceased: false,
    reason: reason,
  );
}

/// Pure age calculator. The caller owns the [CalendarConversionService]
/// instance and supplies the calendar id; the calculator performs the
/// tick-to-unit arithmetic on top of it.
class AgeCalculator {
  const AgeCalculator({required this.calendarId, required this.conversion});

  final String calendarId;
  final CalendarConversionService conversion;

  /// Computes the age for [personId] at [sceneTick]. [birthTick] is the
  /// canonical absolute tick of birth; [deathTick] caps the age and marks
  /// the result as deceased when the scene tick is at or past it. A null
  /// [birthTick] yields an [AgeResult.unknown] with an explanatory reason.
  AgeResult computeAt({
    required String personId,
    required int sceneTick,
    int? birthTick,
    int? deathTick,
  }) {
    if (sceneTick < 0) {
      throw ArgumentError.value(
        sceneTick,
        "sceneTick",
        "sceneTick cannot be negative",
      );
    }
    if (birthTick == null) {
      return AgeResult.unknown("unknown birth date for $personId");
    }
    if (birthTick < 0) {
      throw ArgumentError.value(
        birthTick,
        "birthTick",
        "birthTick cannot be negative",
      );
    }
    if (sceneTick < birthTick) {
      throw ArgumentError(
        "sceneTick $sceneTick precedes birth $birthTick for $personId",
      );
    }
    if (deathTick != null && deathTick < birthTick) {
      throw ArgumentError(
        "deathTick $deathTick precedes birth $birthTick for $personId",
      );
    }

    final isDeceased = deathTick != null && sceneTick >= deathTick;

    // Render the scene date so callers can display "Born on ..., aged X".
    final sceneDisplay = conversion.format(
      absoluteTick: sceneTick,
      calendarId: calendarId,
    );
    final birthDisplay = conversion.format(
      absoluteTick: birthTick,
      calendarId: calendarId,
    );

    var years = sceneDisplay.date.yearNumber - birthDisplay.date.yearNumber;
    var months = sceneDisplay.date.monthIndex - birthDisplay.date.monthIndex;
    var days = sceneDisplay.date.dayOfMonth - birthDisplay.date.dayOfMonth;

    if (days < 0) {
      months -= 1;
      final prevMonthLength = conversion.daysInPreviousMonth(
        calendarId,
        sceneDisplay.date,
      );
      days += prevMonthLength.toInt();
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }

    return AgeResult(
      isKnown: true,
      years: years,
      months: months,
      days: days,
      calendarText: sceneDisplay.text,
      isDeceased: isDeceased,
    );
  }
}
