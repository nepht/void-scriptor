/// 115.49 — Localization & Formatting contract.
///
/// One source of truth for how Account & Cloud Center renders numbers, dates,
/// percentages, currency, tax, provider names, and direction-sensitive text.
/// Before this step the feature carried four private byte formatters (two of
/// them binary under a decimal `GB` label), four percent/amount paths, and no
/// date, relative-time, currency, tax, or direction helper at all — exactly
/// the surface `required_evidence` for step 115.49 asks to validate.
///
/// Deliberately free of `intl`/ICU: the app does not depend on the package, so
/// every rule here is deterministic and testable without a locale data import.
/// Locale-complete formatting (Intl/ICU calendars, native RTL mirroring
/// certification, IME) stays DEFERRED-EXTERNAL in the step manifest.
library;

import 'dart:ui' show TextDirection;

/// One bucket of step 115.49 evidence.
///
/// [localResult] is a free string so a bucket can honestly report `PASS`,
/// `GAP`, or `DEFERRED` instead of being coerced into a boolean.
final class AccountCenterLocalizationEvidence {
  const AccountCenterLocalizationEvidence({
    required this.localResult,
    required this.note,
  });

  final String localResult;
  final String note;

  Map<String, Object?> toPublicJson() => <String, Object?>{
    'local_result': localResult,
    'note': note,
  };
}

/// The validated evidence set for step 115.49.
///
/// Fail-closed: a bucket outside the canonical set is rejected, a missing
/// canonical bucket makes [buildReport] throw, and [isPass] only turns true
/// when every bucket reports `PASS`.
final class AccountCenterLocalizationReport {
  AccountCenterLocalizationReport._(this.evidence);

  final Map<String, AccountCenterLocalizationEvidence> evidence;

  bool get isPass => AccountCenterLocalizationFormatting.requiredEvidence.every(
    (key) => evidence[key]!.localResult == 'PASS',
  );

  Map<String, Object?> toPublicJson() => <String, Object?>{
    for (final entry in evidence.entries) entry.key: entry.value.localResult,
  };
}

abstract final class AccountCenterLocalizationFormatting {
  /// `required_evidence` for canonical step 115.49, in spec order.
  static const List<String> requiredEvidence = <String>[
    'text_expansion',
    'rtl',
    'dates',
    'relative_time',
    'storage_units',
    'percentages',
    'currencies',
    'tax',
  ];

  /// Validates an evidence map against [requiredEvidence].
  ///
  /// Throws [ArgumentError] for an unknown bucket and [StateError] when a
  /// canonical bucket is missing, so a report can never claim completeness by
  /// quietly dropping a bucket.
  static AccountCenterLocalizationReport buildReport(
    Map<String, AccountCenterLocalizationEvidence> evidence,
  ) {
    for (final key in evidence.keys) {
      if (!requiredEvidence.contains(key)) {
        throw ArgumentError.value(
          key,
          'evidence',
          'Bucket outside the canonical required_evidence of step 115.49.',
        );
      }
    }
    final missing = requiredEvidence
        .where((key) => !evidence.containsKey(key))
        .toList(growable: false);
    if (missing.isNotEmpty) {
      throw StateError(
        'Missing required evidence bucket(s): ${missing.join(', ')}.',
      );
    }
    return AccountCenterLocalizationReport._(Map.unmodifiable(evidence));
  }

  // ------------------------------------------------------------------
  // storage_units
  // ------------------------------------------------------------------

  static const int kilobyte = 1000;
  static const int megabyte = 1000 * kilobyte;
  static const int gigabyte = 1000 * megabyte;
  static const int terabyte = 1000 * gigabyte;

  /// Formats a byte count in decimal units.
  ///
  /// Decimal, not binary: the product spec's
  /// `storage_usage_contract.display_rules` ask for GB/TB by default, and a
  /// binary value under a `GB` label is a rounding lie the user cannot see.
  /// Negative input reports `unavailable` rather than a fabricated size.
  static String storageUnits(int bytes) {
    if (bytes < 0) return 'unavailable';
    if (bytes < kilobyte) return '$bytes B';
    if (bytes < megabyte) return '${_trim(bytes / kilobyte, kilobyte)} KB';
    if (bytes < gigabyte) return '${_trim(bytes / megabyte, megabyte)} MB';
    if (bytes < terabyte) return '${_trim(bytes / gigabyte, gigabyte)} GB';
    return '${_trim(bytes / terabyte, terabyte)} TB';
  }

  /// Trailing zeros are dropped so `1.50 GB` prints `1.5 GB` and `1.00 GB`
  /// prints `1 GB` — precision is never invented, never padded.
  ///
  /// 117.29: rounding to two decimals can carry a value out of its own unit
  /// — `999999` bytes is `999.999 KB`, which formats to `1000 KB`, i.e. the
  /// `1 MB` the value is not. When the rounded figure reaches the [ceiling]
  /// of the unit, the value is truncated to two decimals instead, so the
  /// printed statement stays inside the unit the formatter chose. An in-unit
  /// value still rounds normally: `4096` prints `4.1 KB`.
  static String _trim(double value, int ceiling) {
    var rounded = double.parse(value.toStringAsFixed(2));
    if (rounded >= ceiling) {
      rounded = (value * 100).floorToDouble() / 100;
    }
    var text = rounded.toStringAsFixed(2);
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
    return text;
  }

  // ------------------------------------------------------------------
  // percentages
  // ------------------------------------------------------------------

  /// Share of [part] in [total] as a whole percentage, fail-closed.
  static int sharePercent(num part, num total) {
    if (total <= 0) {
      throw ArgumentError.value(
        total,
        'total',
        'A share needs a positive total.',
      );
    }
    if (part < 0) {
      throw ArgumentError.value(part, 'part', 'A share cannot be negative.');
    }
    if (part > total) {
      throw ArgumentError.value(
        part,
        'part',
        'A share cannot exceed the total it belongs to.',
      );
    }
    final share = part.toDouble() / total.toDouble();
    if (!share.isFinite) {
      throw ArgumentError('Non-finite share.');
    }
    return (share * 100).round();
  }

  /// Whole-percentage label inside `0..100`.
  static String percentLabel(int percent) {
    if (percent < 0 || percent > 100) {
      throw ArgumentError.value(
        percent,
        'percent',
        'A percentage label must be within 0..100.',
      );
    }
    return '$percent%';
  }

  /// Thousands-grouped integer, the grouping convention the chrome renders.
  static String groupedInteger(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }

  // ------------------------------------------------------------------
  // currencies
  // ------------------------------------------------------------------

  /// Two-decimal money string; non-finite input reports `unavailable`.
  static String formatMoney(double amount) {
    if (!amount.isFinite) return 'unavailable';
    return amount.toStringAsFixed(2);
  }

  /// Amount formatting that never invents precision: a whole number prints
  /// whole, a fractional value keeps at most four decimals without a trailing
  /// zero tail.
  static String formatAmount(double amount) {
    if (!amount.isFinite) return 'unavailable';
    if (amount == amount.roundToDouble() && amount.abs() < 1e15) {
      return amount.toStringAsFixed(0);
    }
    var text = amount.toStringAsFixed(4);
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
    return text;
  }

  /// Accepts a three-letter alphabetic code and returns it trimmed, keeping
  /// the caller's case so an existing display never changes meaning.
  static String normalizeCurrencyCode(String currencyCode) {
    final normalized = currencyCode.trim();
    if (normalized.length != 3 || normalized.contains(RegExp('[^A-Za-z]'))) {
      throw ArgumentError.value(
        currencyCode,
        'currencyCode',
        'ISO 4217 three-letter code required.',
      );
    }
    return normalized;
  }

  /// A currency string always carries an explicit code — a bare symbol is an
  /// unlabelled currency claim.
  static String formatCurrency({
    required double amount,
    required String currencyCode,
  }) => '${formatAmount(amount)} ${normalizeCurrencyCode(currencyCode)}';

  // ------------------------------------------------------------------
  // dates & relative_time
  // ------------------------------------------------------------------

  /// `yyyy-MM-dd` in UTC. Local input is converted, never reinterpreted.
  static String utcDate(DateTime moment) {
    final value = moment.toUtc();
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  /// Deterministic English relative time from an injected clock.
  ///
  /// Beyond six days the label falls back to the absolute UTC date so old
  /// timestamps stay comparable instead of growing an ever-larger day count.
  /// A future timestamp is rejected: rendering it backwards would misstate
  /// freshness.
  static String relativeTime({
    required DateTime now,
    required DateTime moment,
  }) {
    final delta = now.toUtc().difference(moment.toUtc());
    if (delta.isNegative) {
      throw ArgumentError.value(
        moment,
        'moment',
        'A future timestamp cannot be rendered as past relative time.',
      );
    }
    if (delta.inSeconds < 60) return 'just now';
    if (delta.inMinutes < 60) {
      final minutes = delta.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    }
    if (delta.inHours < 24) {
      final hours = delta.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    }
    if (delta.inDays < 7) {
      final days = delta.inDays;
      return '$days day${days == 1 ? '' : 's'} ago';
    }
    return 'on ${utcDate(moment)}';
  }

  // ------------------------------------------------------------------
  // rtl
  // ------------------------------------------------------------------

  /// Languages written right-to-left, matched on the language subtag so
  /// `ar-SA`, `he_IL`, and `ckb` all resolve without a full locale parser.
  static const Set<String> _rightToLeftLanguages = <String>{
    'ar',
    'ckb',
    'dv',
    'fa',
    'he',
    'iw',
    'ps',
    'sd',
    'ur',
    'yi',
  };

  static TextDirection textDirectionFor(String localeTag) {
    final normalized = localeTag.trim().toLowerCase();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        localeTag,
        'localeTag',
        'A locale tag is required to resolve text direction.',
      );
    }
    final language = normalized.split(RegExp(r'[-_]')).first;
    return _rightToLeftLanguages.contains(language)
        ? TextDirection.rtl
        : TextDirection.ltr;
  }

  // ------------------------------------------------------------------
  // tax
  // ------------------------------------------------------------------

  /// Turns the canonical `Invoice.taxInformation` tokens into readable text.
  ///
  /// The invoice keeps wire tokens (`not_applicable`, `unavailable`) in its
  /// public JSON; a UI must not print those verbatim. Anything else must look
  /// like a `<label> NN.NN% (<region>)` tax line, otherwise the value is
  /// rejected instead of rendered as free text.
  static String taxDisplay(String taxInformation) {
    final value = taxInformation.trim();
    if (value.isEmpty) {
      throw ArgumentError.value(
        taxInformation,
        'taxInformation',
        'Tax text is required.',
      );
    }
    if (value == 'not_applicable') return 'Not applicable';
    if (value == 'unavailable') return 'Tax unavailable';
    if (!RegExp(r'\d+\.\d{2}%').hasMatch(value)) {
      throw ArgumentError.value(
        taxInformation,
        'taxInformation',
        'Expected a canonical tax token or a "<label> NN.NN% (<region>)" line.',
      );
    }
    return value;
  }

  // ------------------------------------------------------------------
  // provider names
  // ------------------------------------------------------------------

  /// Trims and collapses internal whitespace so a display name renders the
  /// same whether it came from a manifest, a registry, or JSON.
  static String providerDisplayName(String raw) {
    final normalized = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        raw,
        'displayName',
        'A provider display name requires non-empty text.',
      );
    }
    return normalized;
  }

  // ------------------------------------------------------------------
  // text_expansion
  // ------------------------------------------------------------------

  /// Characters that locale formatters emit and that break line breaking.
  ///
  /// No-break spaces (including the narrow U+202F many locale number
  /// formatters insert), zero-width space, word joiner, and non-breaking hyphen
  /// all keep a label glued together, so an expanded translation overflows
  /// instead of wrapping. The chrome must never render them.
  static const List<String> _nonWrappableCharacters = <String>[
    '\u00A0', // no-break space
    '\u202F', // narrow no-break space
    '\u2007', // figure space
    '\u2011', // non-breaking hyphen
    '\u2060', // word joiner
    '\u200B', // zero-width space
  ];

  /// Returns [value] unchanged when it is wrappable, throws otherwise.
  static String requireWrappable(String value, {String field = 'value'}) {
    if (value.isEmpty) {
      throw ArgumentError.value(value, field, 'Text must not be empty.');
    }
    for (final marker in _nonWrappableCharacters) {
      if (value.contains(marker)) {
        final code = marker.runes.first.toRadixString(16).toUpperCase();
        throw ArgumentError.value(
          value,
          field,
          'Non-wrappable character U+$code breaks text expansion.',
        );
      }
    }
    return value;
  }
}
