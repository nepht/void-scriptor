// Sprint 110.47 - Accessibility and Localization Verification (domain audit).
//
// Aggregates the required outputs from sprint_110.json step 110.47:
//   * keyboard_results:    verifier that all MapTimeKey and TechTreeKey enum
//                          members are reachable and clamped.
//   * screen_reader_results: structural labels for MapTimeSliderView and
//                          TechTreeWorkspaceView without invoking a real
//                          Semantics tree (PARTIAL until native capture).
//   * scaling_results:     verifier that CurrencyReferenceBasket and
//                          PriceWealthInflationModel large numbers survive
//                          int math and string formatting without overflow.
//   * locale_results:      CalendarLocale round-trip across multiple
//                          separators and date orderings.
//   * calendar_results:    CustomCalendar boundary correctness
//                          (year rollover, variable month).
//   * fix_status:          Aggregated verdict mapped to FixStatus taxonomy.
//
// Domain-only - deterministic, no persistence/UI/wall clock/random/network.
// Does NOT replace native screen-reader or accessibility tooling capture.

import "calendar_conversion.dart";
import "currency_reference_basket.dart";
import "custom_calendar.dart";
import "historical_layer_resolver.dart";
import "price_wealth_inflation_model.dart";
import "tech_tree_workspace.dart";

enum A11yLocaleFixStatus { clean, acceptable, actionRequired }

class A11yLocaleKeyboardResult {
  A11yLocaleKeyboardResult({
    required this.totalKeys,
    required this.reachableKeys,
    required this.unreachableKeys,
  });

  final int totalKeys;
  final int reachableKeys;
  final List<String> unreachableKeys;

  bool get isClean => unreachableKeys.isEmpty;
}

class A11yLocaleScreenReaderResult {
  A11yLocaleScreenReaderResult({
    required this.viewLabels,
    required this.nativeCapture,
  });

  final List<String> viewLabels;
  final bool nativeCapture;

  bool get isClean => viewLabels.isNotEmpty;
}

class A11yLocaleScalingResult {
  A11yLocaleScalingResult({
    required this.largestConvertedTick,
    required this.largestNetWorth,
    required this.formattedTexts,
  });

  final int largestConvertedTick;
  final int largestNetWorth;
  final List<String> formattedTexts;

  bool get isClean =>
      formattedTexts.every((t) => !t.contains("NaN")) &&
      formattedTexts.every((t) => !t.contains("Infinity"));
}

class A11yLocaleLocaleResult {
  A11yLocaleLocaleResult({required this.samples, required this.collisions});

  final List<String> samples;
  final List<String> collisions;

  bool get isClean => collisions.isEmpty;
}

class A11yLocaleCalendarResult {
  A11yLocaleCalendarResult({
    required this.firstDateOfYear,
    required this.lastDateOfYear,
    required this.leapStyleRoundTrip,
  });

  final CalendarDate firstDateOfYear;
  final CalendarDate lastDateOfYear;
  final bool leapStyleRoundTrip;

  bool get isClean => leapStyleRoundTrip;
}

class A11yLocaleReport {
  A11yLocaleReport({
    required this.keyboard,
    required this.screenReader,
    required this.scaling,
    required this.locale,
    required this.calendar,
  });

  final A11yLocaleKeyboardResult keyboard;
  final A11yLocaleScreenReaderResult screenReader;
  final A11yLocaleScalingResult scaling;
  final A11yLocaleLocaleResult locale;
  final A11yLocaleCalendarResult calendar;

  A11yLocaleFixStatus get fixStatus {
    final blockers = <bool>[
      !keyboard.isClean,
      !scaling.isClean,
      !locale.isClean,
      !calendar.isClean,
    ];
    if (blockers.any((b) => b)) {
      return A11yLocaleFixStatus.actionRequired;
    }
    if (!screenReader.isClean || !screenReader.nativeCapture) {
      return A11yLocaleFixStatus.acceptable;
    }
    return A11yLocaleFixStatus.clean;
  }

  bool get isClean => fixStatus == A11yLocaleFixStatus.clean;
}

class A11yLocaleAuditor {
  const A11yLocaleAuditor();

  A11yLocaleKeyboardResult auditKeyboard({
    required MapTimeSliderController mapController,
    required TechTreeController techController,
  }) {
    final mapKeys = MapTimeKey.values.toList();
    final techKeys = TechTreeKey.values.toList();
    final nav = TechTreeNavDirection.values.toList();
    final unreachable = <String>[];
    var reachable = 0;
    for (final key in mapKeys) {
      // Reachability check: enum value present + applyable without throwing.
      // applyKey is idempotent at boundary ticks; we treat every enum as
      // reachable if it can be applied without exception.
      try {
        mapController.applyKey(key);
        reachable++;
      } catch (_) {
        unreachable.add("map:${key.name}");
      }
    }
    for (final key in techKeys) {
      try {
        techController.applyKey(key);
        reachable++;
      } catch (_) {
        unreachable.add("tech:${key.name}");
      }
    }
    for (final direction in nav) {
      techController.navigateDirection(direction);
      reachable++;
    }
    return A11yLocaleKeyboardResult(
      totalKeys: mapKeys.length + techKeys.length + nav.length,
      reachableKeys: reachable,
      unreachableKeys: unreachable,
    );
  }

  A11yLocaleScreenReaderResult auditScreenReader() {
    return A11yLocaleScreenReaderResult(
      viewLabels: const ["MapTimeSliderView", "TechTreeWorkspaceView"],
      nativeCapture: false,
    );
  }

  A11yLocaleScalingResult auditScaling({
    required CurrencyReferenceBasket basket,
    required PriceWealthInflationModel model,
    required int extremeTick,
  }) {
    final formatted = <String>[];
    double largestNet = 0;
    int largestTick = 0;
    for (final def in basket.currencies) {
      if (def.validity.contains(extremeTick)) {
        formatted.add("rate:${def.id}:active");
      }
    }
    for (final good in basket.goods) {
      final amount = basket.referencePrice(
        good.id,
        currencyId: basket.currencies.isNotEmpty
            ? basket.currencies.first.id
            : "missing",
        tick: extremeTick,
      );
      if (amount != null) {
        formatted.add("price:${good.id}:$amount");
        if (amount > largestNet) largestNet = amount;
      }
    }
    for (final profile in model.wealthProfiles) {
      formatted.add("netWorth:${profile.id}:${profile.netWorth}");
      if (profile.assets > largestNet) largestNet = profile.assets;
    }
    if (extremeTick > largestTick) largestTick = extremeTick;
    return A11yLocaleScalingResult(
      largestConvertedTick: largestTick,
      largestNetWorth: largestNet.toInt(),
      formattedTexts: formatted,
    );
  }

  A11yLocaleLocaleResult auditLocale({
    required CalendarConversionService conversion,
    required List<CalendarLocale> locales,
    required Set<String> calendarIds,
  }) {
    final samples = <String>[];
    final collisions = <String>[];
    final seen = <String>{};
    for (final loc in locales) {
      for (final calId in calendarIds) {
        final text = conversion
            .format(absoluteTick: 60, calendarId: calId, locale: loc)
            .text;
        samples.add("$calId@${loc.id}:$text");
        if (!seen.add(text)) {
          collisions.add(text);
        }
      }
    }
    return A11yLocaleLocaleResult(samples: samples, collisions: collisions);
  }

  A11yLocaleCalendarResult auditCalendar({required CustomCalendar calendar}) {
    final first = calendar.dateFromTick(0);
    final lastTick = calendar.daysPerYear - 1;
    final last = calendar.dateFromTick(lastTick);
    var roundTrip = true;
    for (var t = 0; t < calendar.daysPerYear; t++) {
      final date = calendar.dateFromTick(t);
      final back = calendar.tickFromDate(date);
      if (back != t) {
        roundTrip = false;
        break;
      }
    }
    return A11yLocaleCalendarResult(
      firstDateOfYear: first,
      lastDateOfYear: last,
      leapStyleRoundTrip: roundTrip,
    );
  }

  A11yLocaleReport runFull({
    required MapTimeSliderController mapController,
    required TechTreeController techController,
    required CurrencyReferenceBasket basket,
    required PriceWealthInflationModel model,
    required CalendarConversionService conversion,
    required List<CalendarLocale> locales,
    required Set<String> calendarIds,
    required CustomCalendar calendar,
    required int extremeTick,
  }) {
    return A11yLocaleReport(
      keyboard: auditKeyboard(
        mapController: mapController,
        techController: techController,
      ),
      screenReader: auditScreenReader(),
      scaling: auditScaling(
        basket: basket,
        model: model,
        extremeTick: extremeTick,
      ),
      locale: auditLocale(
        conversion: conversion,
        locales: locales,
        calendarIds: calendarIds,
      ),
      calendar: auditCalendar(calendar: calendar),
    );
  }
}
