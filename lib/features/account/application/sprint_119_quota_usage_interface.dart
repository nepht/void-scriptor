/// Local, fail-closed quota and usage interface contract for roadmap step
/// 119.13.
///
/// This file defines raw usage values with explicit units, periods,
/// measurement instants, derived freshness, named sources, estimate flags, and
/// explicit availability states. It does not poll a live provider, reconcile
/// billing, or claim that an estimate is exact.
library;

import 'dart:convert';
import 'dart:io';

/// Closed unit enum for reported usage values.
enum QuotaUnit {
  bytes,
  requests,
  tokens,
  seconds,
  items,
  currencyMinorUnits,
  unknown,
}

/// Reporting window a value belongs to.
enum QuotaPeriod { instant, hourly, daily, monthly, billingCycle, unknown }

/// Derived freshness of a measurement.
enum QuotaFreshness { live, recent, stale, unknown }

/// Where a value came from, so cached and estimated data is never mistaken for
/// a live reading.
enum QuotaSource {
  providerApi,
  providerWebhook,
  localEstimate,
  cachedSnapshot,
  unknown,
}

/// Explicit availability of a value.
enum QuotaAvailability { available, unavailable, notReported, unsupported }

/// A single raw quota or usage value.
///
/// Exactly one shape is valid: an available value carries a raw value and a
/// measurement instant, while an unavailable value carries neither.
/// [QuotaUsageInterface.validateValue] reports any other combination.
final class QuotaValue {
  const QuotaValue({
    required this.rawValue,
    required this.unit,
    required this.period,
    required this.measuredAt,
    required this.freshness,
    required this.source,
    required this.isEstimate,
    required this.availability,
  });

  /// A provider- or cache-reported value with derived freshness.
  factory QuotaValue.reported({
    required double rawValue,
    required QuotaUnit unit,
    required QuotaPeriod period,
    required DateTime measuredAt,
    required QuotaSource source,
    required DateTime now,
    bool isEstimate = false,
  }) => QuotaValue(
    rawValue: rawValue,
    unit: unit,
    period: period,
    measuredAt: measuredAt.toUtc(),
    freshness: QuotaUsageInterface.classifyFreshness(
      measuredAt: measuredAt,
      now: now,
    ),
    source: source,
    isEstimate: isEstimate,
    availability: QuotaAvailability.available,
  );

  /// A value that could not be read, carrying no raw value or instant.
  factory QuotaValue.unavailable({
    required QuotaSource source,
    QuotaAvailability availability = QuotaAvailability.unavailable,
  }) => QuotaValue(
    rawValue: null,
    unit: QuotaUnit.unknown,
    period: QuotaPeriod.unknown,
    measuredAt: null,
    freshness: QuotaFreshness.unknown,
    source: source,
    isEstimate: false,
    availability: availability,
  );

  final double? rawValue;
  final QuotaUnit unit;
  final QuotaPeriod period;
  final DateTime? measuredAt;
  final QuotaFreshness freshness;
  final QuotaSource source;

  /// Estimates are flagged and must never be treated as exact.
  final bool isEstimate;

  final QuotaAvailability availability;

  /// True only for an available, non-estimated, present value.
  bool get isExact =>
      availability == QuotaAvailability.available &&
      rawValue != null &&
      !isEstimate;

  /// True only when the value can be acted on: available, present, and neither
  /// stale nor of unknown freshness.
  bool get isUsable =>
      availability == QuotaAvailability.available &&
      rawValue != null &&
      freshness != QuotaFreshness.stale &&
      freshness != QuotaFreshness.unknown;

  Map<String, Object?> toJson() => <String, Object?>{
    'raw_value': rawValue,
    'unit': unit.name,
    'period': period.name,
    'measured_at': measuredAt?.toUtc().toIso8601String(),
    'freshness': freshness.name,
    'source': source.name,
    'is_estimate': isEstimate,
    'availability': availability.name,
  };
}

/// Manifest validation and fail-closed helpers for the 119.13 contract.
abstract final class QuotaUsageInterface {
  static const String canonicalStep = '119.13';
  static const String manifestPath =
      'docs/planning/v1.3/sprint_119_quota_usage_interface.json';

  static const List<String> requiredFields = <String>[
    'raw_value',
    'unit',
    'period',
    'measured_at',
    'freshness',
    'source',
    'is_estimate',
    'availability',
  ];

  static const List<String> requiredAcceptance = requiredFields;

  /// Local freshness policy constants, not provider guarantees.
  static const Duration liveWindow = Duration(minutes: 1);
  static const Duration recentWindow = Duration(hours: 1);

  static final RegExp _opaqueReference = RegExp(
    r'\b(?:storageref|jobref|credref):[a-z][a-z0-9._-]{2,63}:[a-z0-9._-]{1,63}',
  );

  /// Derives freshness from measurement age.
  ///
  /// A measurement dated in the future is never treated as fresh; it is
  /// [QuotaFreshness.unknown] so callers fail closed instead of trusting a
  /// bad clock.
  static QuotaFreshness classifyFreshness({
    required DateTime measuredAt,
    required DateTime now,
  }) {
    final age = now.toUtc().difference(measuredAt.toUtc());
    if (age.isNegative) return QuotaFreshness.unknown;
    if (age <= liveWindow) return QuotaFreshness.live;
    if (age <= recentWindow) return QuotaFreshness.recent;
    return QuotaFreshness.stale;
  }

  /// Reports inconsistent value shapes. An empty list means consistent.
  static List<String> validateValue(QuotaValue value) {
    final diagnostics = <String>[];
    final isAvailable = value.availability == QuotaAvailability.available;
    if (isAvailable && value.rawValue == null) {
      diagnostics.add('raw_value_missing_for_available');
    }
    if (isAvailable && value.measuredAt == null) {
      diagnostics.add('measured_at_missing_for_available');
    }
    if (!isAvailable && value.rawValue != null) {
      diagnostics.add('raw_value_present_for_unavailable');
    }
    return diagnostics;
  }

  /// Fraction of a limit consumed, or `null` when it cannot be computed.
  ///
  /// The result is deliberately not clamped: a value above `1.0` is the signal
  /// that the limit was exceeded.
  static double? utilization({required double? used, required double? limit}) {
    if (used == null || limit == null) return null;
    if (!limit.isFinite || limit <= 0) return null;
    if (!used.isFinite) return null;
    return used / limit;
  }

  static bool isExhausted({required double? used, required double? limit}) {
    final ratio = utilization(used: used, limit: limit);
    return ratio != null && ratio >= 1.0;
  }

  /// Redacts opaque references from diagnostics.
  static String redact(String message) =>
      message.replaceAll(_opaqueReference, '[REDACTED]');

  static List<String> validateManifest(Map<String, dynamic> manifest) {
    final diagnostics = <String>[];
    if (manifest['canonical_step'] != canonicalStep) {
      diagnostics.add('canonical_step_invalid');
    }
    if (manifest['unknown_field_policy'] != 'REJECT') {
      diagnostics.add('unknown_field_policy_invalid');
    }

    final declared = manifest['required_fields'];
    final declaredSet = declared is List
        ? declared.whereType<String>().toSet()
        : <String>{};
    for (final field in requiredFields) {
      if (!declaredSet.contains(field)) {
        diagnostics.add('field_missing:$field');
      }
    }

    final acceptance = manifest['acceptance'];
    if (acceptance is! Map<String, dynamic>) {
      for (final key in requiredAcceptance) {
        diagnostics.add('acceptance_missing:$key');
      }
      return diagnostics;
    }
    for (final key in requiredAcceptance) {
      if (!acceptance.containsKey(key)) {
        diagnostics.add('acceptance_missing:$key');
      }
    }
    return diagnostics;
  }

  static List<String> validateCanonicalManifest() {
    final file = File(manifestPath);
    if (!file.existsSync()) return <String>['manifest_missing'];
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic>
          ? validateManifest(decoded)
          : <String>['manifest_root_invalid'];
    } on Object {
      return <String>['manifest_unreadable'];
    }
  }
}
