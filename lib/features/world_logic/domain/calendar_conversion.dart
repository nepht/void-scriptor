/// Sprint 110.14 - Calendar Conversion & Display (Wave 2 F5).
///
/// Domain-only service that converts an absolute tick (canonical time) into a
/// [CalendarDate] using a chosen [CustomCalendar] from a [CalendarRegistry]
/// and renders it through an explicit [CalendarLocale]. Pure, deterministic,
/// no persistence, no UI, no DateTime.now() / global random / network.
library;

import "custom_calendar.dart";

/// One immutable, named locale used to render a [CalendarDate] as text.
/// [order] is one of "ymd" | "dmy" | "mdy".
class CalendarLocale {
  const CalendarLocale({
    required this.id,
    required this.separator,
    required this.order,
  }) : assert(
         order == "ymd" || order == "dmy" || order == "mdy",
         "order must be ymd/dmy/mdy",
       );

  final String id;
  final String separator;
  final String order;

  static const CalendarLocale defaultLocale = CalendarLocale(
    id: "en",
    separator: "-",
    order: "ymd",
  );
}

/// Origin shift applied to absolute ticks before resolving a date.
class CalendarEpoch {
  const CalendarEpoch({required this.ticksAtEpoch});
  final int ticksAtEpoch;
}

/// Registry of named [CustomCalendar]s.
class CalendarRegistry {
  CalendarRegistry(Map<String, CustomCalendar> calendars)
    : _calendars = Map<String, CustomCalendar>.unmodifiable(calendars);

  final Map<String, CustomCalendar> _calendars;

  Set<String> get calendars => _calendars.keys.toSet();

  CustomCalendar resolve(String id) {
    final c = _calendars[id];
    if (c == null) {
      throw ArgumentError('unknown calendar id: $id');
    }
    return c;
  }
}

/// The result of formatting an absolute tick against a chosen calendar.
class CalendarDisplay {
  const CalendarDisplay({
    required this.calendarId,
    required this.date,
    required this.locale,
    required this.text,
  });

  final String calendarId;
  final CalendarDate date;
  final CalendarLocale locale;
  final String text;
}

/// Domain service for converting an absolute tick to a calendar date and
/// rendering it in a given locale. Round-trip safe.
class CalendarConversionService {
  CalendarConversionService({
    required this._registry,
    this._epoch = const CalendarEpoch(ticksAtEpoch: 0),
    this._defaultLocale = CalendarLocale.defaultLocale,
  });

  final CalendarRegistry _registry;
  final CalendarEpoch _epoch;
  final CalendarLocale _defaultLocale;

  CalendarDisplay format({
    required int absoluteTick,
    required String calendarId,
    CalendarLocale? locale,
  }) {
    if (absoluteTick < 0) {
      throw ArgumentError('absoluteTick cannot be negative');
    }
    final cal = _registry.resolve(calendarId);
    final shifted = absoluteTick - _epoch.ticksAtEpoch;
    if (shifted < 0) {
      throw ArgumentError('absoluteTick before epoch');
    }
    final date = cal.dateFromTick(shifted);
    final loc = locale ?? _defaultLocale;
    return CalendarDisplay(
      calendarId: calendarId,
      date: date,
      locale: loc,
      text: _render(date, loc),
    );
  }

  int parse({required CalendarDisplay display, required String calendarId}) {
    final cal = _registry.resolve(calendarId);
    final tick = cal.tickFromDate(display.date);
    return tick + _epoch.ticksAtEpoch;
  }

  String _render(CalendarDate date, CalendarLocale loc) {
    final y = date.yearNumber.toString();
    final m = date.monthIndex.toString();
    final d = date.dayOfMonth.toString();
    switch (loc.order) {
      case "ymd":
        return '$y${loc.separator}$m${loc.separator}$d';
      case "dmy":
        return '$d${loc.separator}$m${loc.separator}$y';
      case "mdy":
        return '$m${loc.separator}$d${loc.separator}$y';
      default:
        throw StateError('unreachable order: ${loc.order}');
    }
  }

  /// Returns the number of days in the calendar month that comes immediately
  /// before the month referenced by [date]. Exposed for downstream services
  /// (Sprint 110.26 age calculation) that need to borrow days across month
  /// boundaries while remaining calendar-faithful.
  int daysInPreviousMonth(String calendarId, CalendarDate date) {
    final cal = _registry.resolve(calendarId);
    final monthIndex = date.monthIndex;
    final prev = monthIndex == 0 ? cal.monthsPerYear - 1 : monthIndex - 1;
    return cal.months[prev].daysInMonth;
  }
}
