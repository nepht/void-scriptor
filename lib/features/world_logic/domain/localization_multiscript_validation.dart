/// Localization & Multiscript Validation (Step 113.22).
///
/// Domain-level validation of locale coverage, RTL direction, UI text
/// expansion budget, custom-calendar rendering per locale order, unit/date
/// formatting, and multiscript name integrity. Deterministic fixtures only —
/// native IME, live widget layout mirroring, and full ICU formatting are out
/// of scope (see manifest limits).
library;

import 'dart:convert';

import 'package:void_scriptor/l10n/app_localizations.dart';

import 'calendar_conversion.dart';
import 'custom_calendar.dart';

/// Text direction for a locale at domain level.
enum LocalizedTextDirection { ltr, rtl }

/// Result of locale coverage validation.
class LocaleValidationResult {
  const LocaleValidationResult({
    required this.supportedLocales,
    required this.fallbackLocale,
  });

  final List<String> supportedLocales;
  final String fallbackLocale;

  bool isSupported(String languageCode) =>
      supportedLocales.contains(languageCode);

  String fallbackFor(String languageCode) =>
      isSupported(languageCode) ? languageCode : fallbackLocale;
}

/// Result of RTL direction validation.
class RtlValidationResult {
  const RtlValidationResult({required this.rtlLocales});

  final List<String> rtlLocales;

  LocalizedTextDirection directionFor(String languageCode) =>
      rtlLocales.contains(languageCode)
      ? LocalizedTextDirection.rtl
      : LocalizedTextDirection.ltr;

  bool requiresMirroring(String languageCode) =>
      directionFor(languageCode) == LocalizedTextDirection.rtl;
}

/// Result of UI text expansion validation.
class ExpansionValidationResult {
  const ExpansionValidationResult({
    required this.factors,
    required this.budget,
    required this.longestLocale,
    required this.maxFactor,
  });

  /// Expansion factor per locale against the English baseline label.
  final Map<String, double> factors;
  final double budget;
  final String longestLocale;
  final double maxFactor;

  bool get withinBudget => maxFactor <= budget;

  double factorFor(String languageCode) => factors[languageCode] ?? 1.0;
}

/// Result of custom-calendar locale rendering and round-trip validation.
class CalendarValidationResult {
  const CalendarValidationResult({
    required this.daysPerYear,
    required this.monthCount,
    required this.sourceTick,
    required this.parsedTick,
    required this.ymdText,
    required this.dmyText,
  });

  final int daysPerYear;
  final int monthCount;
  final int sourceTick;
  final int parsedTick;
  final String ymdText;
  final String dmyText;

  bool get roundTripTick => parsedTick == sourceTick;
}

/// Result of unit conversion and locale separator validation.
class UnitValidationResult {
  const UnitValidationResult();

  static const double kmToMiFactor = 0.621371;

  static double kmToMi(double km) => km * kmToMiFactor;

  static double miToKm(double mi) => mi / kmToMiFactor;

  bool get roundTrip => (miToKm(kmToMi(100)) - 100).abs() < 0.01;

  /// Formats [value] in kilometers with locale-appropriate separators:
  /// `en` -> `1,234.5 km`, `id` -> `1.234,5 km`.
  String formatQuantity(double value, String languageCode) {
    final fixed = value.toStringAsFixed(1);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final fraction = parts.length > 1 ? parts[1] : '';
    final indonesian = languageCode == 'id';
    final decimalSeparator = indonesian ? ',' : '.';
    final thousandsSeparator = indonesian ? '.' : ',';
    final grouped = _groupThousands(intPart, thousandsSeparator);
    if (fraction.isEmpty) return '$grouped km';
    return '$grouped$decimalSeparator$fraction km';
  }

  String _groupThousands(String digits, String separator) {
    final buffer = <String>[];
    var index = digits.length;
    while (index > 3) {
      buffer.insert(0, digits.substring(index - 3, index));
      index -= 3;
    }
    buffer.insert(0, digits.substring(0, index));
    return buffer.join(separator);
  }
}

/// One multiscript name sample.
class MultiscriptSample {
  const MultiscriptSample({
    required this.script,
    required this.name,
    required this.preserved,
  });

  final String script;
  final String name;
  final bool preserved;
}

/// Result of multiscript name integrity validation.
class MultiscriptValidationResult {
  const MultiscriptValidationResult({required this.samples});

  final List<MultiscriptSample> samples;

  bool get allPreserved =>
      samples.length >= 4 && samples.every((sample) => sample.preserved);
}

/// Validator for step 113.22.
class LocalizationMultiscriptValidator {
  // 1. Locale ----------------------------------------------------------------

  LocaleValidationResult localeResults() {
    final supported = AppLocalizations.supportedLocales
        .map((locale) => locale.languageCode)
        .toList();
    return LocaleValidationResult(
      supportedLocales: supported,
      fallbackLocale: 'en',
    );
  }

  // 2. RTL -------------------------------------------------------------------

  RtlValidationResult rtlResults() =>
      const RtlValidationResult(rtlLocales: <String>['ar', 'he', 'fa']);

  // 3. Text expansion --------------------------------------------------------

  ExpansionValidationResult expansionResults() {
    const baseline = 'Create Project';
    const labels = <String, String>{
      'en': 'Create Project',
      'id': 'Buat Proyek',
      'de': 'Projekt erstellen',
      'ru': 'Создать проект',
    };
    final factors = <String, double>{
      for (final entry in labels.entries)
        entry.key: entry.value.length / baseline.length,
    };
    var maxFactor = 0.0;
    var longest = 'en';
    factors.forEach((code, factor) {
      if (factor > maxFactor) {
        maxFactor = factor;
        longest = code;
      }
    });
    return ExpansionValidationResult(
      factors: factors,
      budget: 2.0,
      longestLocale: longest,
      maxFactor: maxFactor,
    );
  }

  // 4. Calendar --------------------------------------------------------------

  CalendarValidationResult calendarResults() {
    final calendar = CustomCalendar(
      months: const <CustomMonth>[
        CustomMonth(name: 'Astra', daysInMonth: 30, indexInYear: 0),
        CustomMonth(name: 'Umbra', daysInMonth: 30, indexInYear: 1),
        CustomMonth(name: 'Nexus', daysInMonth: 30, indexInYear: 2),
        CustomMonth(name: 'Void', daysInMonth: 30, indexInYear: 3),
      ],
    );
    final service = CalendarConversionService(
      registry: CalendarRegistry(<String, CustomCalendar>{
        'validation_epoch': calendar,
      }),
    );
    const sourceTick = 42;
    final ymd = service.format(
      absoluteTick: sourceTick,
      calendarId: 'validation_epoch',
      locale: const CalendarLocale(id: 'en', separator: '-', order: 'ymd'),
    );
    final dmy = service.format(
      absoluteTick: sourceTick,
      calendarId: 'validation_epoch',
      locale: const CalendarLocale(id: 'id', separator: '.', order: 'dmy'),
    );
    final parsed = service.parse(display: ymd, calendarId: 'validation_epoch');
    return CalendarValidationResult(
      daysPerYear: calendar.daysPerYear,
      monthCount: calendar.monthsPerYear,
      sourceTick: sourceTick,
      parsedTick: parsed,
      ymdText: ymd.text,
      dmyText: dmy.text,
    );
  }

  // 5. Units -----------------------------------------------------------------

  UnitValidationResult unitResults() => const UnitValidationResult();

  // 6. Multiscript names -----------------------------------------------------

  MultiscriptValidationResult multiscriptResults() {
    const fixtures = <String, String>{
      'Cyrillic': 'Азбука Пустоты',
      'CJK': '虚空立方',
      'Arabic': 'مكعب الفراغ',
      'Devanagari': 'शून्य घन',
      'Latin': 'Void Cube',
    };
    final samples = <MultiscriptSample>[
      for (final entry in fixtures.entries)
        MultiscriptSample(
          script: entry.key,
          name: entry.value,
          preserved: _isPreserved(entry.value),
        ),
    ];
    return MultiscriptValidationResult(samples: samples);
  }

  bool isValidName(String name) =>
      name.trim().isNotEmpty && !name.contains('\uFFFD');

  bool _isPreserved(String name) {
    if (!isValidName(name)) return false;
    final roundTrip = utf8.decode(utf8.encode(name));
    return roundTrip == name && roundTrip.length == name.length;
  }
}
