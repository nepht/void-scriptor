import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/application/sprint_119_quota_usage_interface.dart';

void main() {
  final now = DateTime.utc(2026, 3, 1, 12);

  group('119.13 Quota & Usage Interface', () {
    test('reported values derive freshness from measurement age', () {
      QuotaValue report(Duration age) => QuotaValue.reported(
        rawValue: 1024,
        unit: QuotaUnit.bytes,
        period: QuotaPeriod.daily,
        measuredAt: now.subtract(age),
        source: QuotaSource.providerApi,
        now: now,
      );

      expect(
        report(const Duration(seconds: 30)).freshness,
        QuotaFreshness.live,
      );
      expect(
        report(const Duration(minutes: 30)).freshness,
        QuotaFreshness.recent,
      );
      expect(report(const Duration(hours: 5)).freshness, QuotaFreshness.stale);
    });

    test('future timestamps are not trusted as fresh', () {
      final value = QuotaValue.reported(
        rawValue: 5,
        unit: QuotaUnit.requests,
        period: QuotaPeriod.hourly,
        measuredAt: now.add(const Duration(hours: 1)),
        source: QuotaSource.providerApi,
        now: now,
      );

      expect(value.freshness, QuotaFreshness.unknown);
      expect(value.isUsable, isFalse);
    });

    test('stale values are not usable even when reported', () {
      final value = QuotaValue.reported(
        rawValue: 5,
        unit: QuotaUnit.requests,
        period: QuotaPeriod.hourly,
        measuredAt: now.subtract(const Duration(days: 1)),
        source: QuotaSource.cachedSnapshot,
        now: now,
      );

      expect(value.availability, QuotaAvailability.available);
      expect(value.isUsable, isFalse);
      expect(value.isExact, isTrue);
    });

    test('estimates are never exact', () {
      final estimate = QuotaValue.reported(
        rawValue: 900,
        unit: QuotaUnit.tokens,
        period: QuotaPeriod.monthly,
        measuredAt: now,
        source: QuotaSource.localEstimate,
        now: now,
        isEstimate: true,
      );

      expect(estimate.isEstimate, isTrue);
      expect(estimate.isExact, isFalse);
      expect(estimate.isUsable, isTrue);
    });

    test('unavailable values carry no raw value and are not usable', () {
      final value = QuotaValue.unavailable(source: QuotaSource.providerApi);

      expect(value.rawValue, isNull);
      expect(value.measuredAt, isNull);
      expect(value.availability, QuotaAvailability.unavailable);
      expect(value.isUsable, isFalse);
      expect(value.isExact, isFalse);
      expect(QuotaUsageInterface.validateValue(value), isEmpty);
    });

    test('inconsistent availability and raw value are rejected', () {
      final missingRaw = QuotaValue(
        rawValue: null,
        unit: QuotaUnit.bytes,
        period: QuotaPeriod.daily,
        measuredAt: now,
        freshness: QuotaFreshness.live,
        source: QuotaSource.providerApi,
        isEstimate: false,
        availability: QuotaAvailability.available,
      );
      expect(
        QuotaUsageInterface.validateValue(missingRaw),
        contains('raw_value_missing_for_available'),
      );

      final phantomRaw = QuotaValue(
        rawValue: 12,
        unit: QuotaUnit.bytes,
        period: QuotaPeriod.daily,
        measuredAt: null,
        freshness: QuotaFreshness.unknown,
        source: QuotaSource.unknown,
        isEstimate: false,
        availability: QuotaAvailability.unavailable,
      );
      expect(
        QuotaUsageInterface.validateValue(phantomRaw),
        contains('raw_value_present_for_unavailable'),
      );
    });

    test('utilization is null when not computable and exceeds 1 when over', () {
      expect(QuotaUsageInterface.utilization(used: 50, limit: 100), 0.5);
      expect(QuotaUsageInterface.utilization(used: null, limit: 100), isNull);
      expect(QuotaUsageInterface.utilization(used: 10, limit: null), isNull);
      expect(QuotaUsageInterface.utilization(used: 10, limit: 0), isNull);
      expect(QuotaUsageInterface.utilization(used: 150, limit: 100), 1.5);
      expect(QuotaUsageInterface.isExhausted(used: 150, limit: 100), isTrue);
      expect(QuotaUsageInterface.isExhausted(used: 99, limit: 100), isFalse);
      expect(QuotaUsageInterface.isExhausted(used: null, limit: 100), isFalse);
    });

    test('serialization exposes every required field', () {
      final value = QuotaValue.reported(
        rawValue: 42,
        unit: QuotaUnit.items,
        period: QuotaPeriod.billingCycle,
        measuredAt: now,
        source: QuotaSource.providerWebhook,
        now: now,
      );

      final json = value.toJson();
      expect(json.keys, containsAll(QuotaUsageInterface.requiredFields));
      expect(json['raw_value'], 42);
      expect(json['unit'], 'items');
      expect(json['period'], 'billingCycle');
      expect(json['measured_at'], '2026-03-01T12:00:00.000Z');
      expect(json['is_estimate'], isFalse);
      expect(json['availability'], 'available');
    });

    test('diagnostics redact opaque references', () {
      expect(
        QuotaUsageInterface.redact('storageref:drive:primary quota stale'),
        '[REDACTED] quota stale',
      );
    });

    test('validates the canonical manifest and rejects missing fields', () {
      expect(QuotaUsageInterface.validateCanonicalManifest(), isEmpty);

      final missing = <String, dynamic>{
        'canonical_step': '119.13',
        'unknown_field_policy': 'REJECT',
        'required_fields': <String>['raw_value'],
        'acceptance': <String, dynamic>{},
      };
      expect(
        QuotaUsageInterface.validateManifest(missing),
        containsAll(<String>[
          'field_missing:unit',
          'field_missing:freshness',
          'field_missing:availability',
          'acceptance_missing:is_estimate',
        ]),
      );
      expect(
        QuotaUsageInterface.validateManifest(<String, dynamic>{
          'canonical_step': '119.12',
          'unknown_field_policy': 'ALLOW',
        }),
        containsAll(<String>[
          'canonical_step_invalid',
          'unknown_field_policy_invalid',
        ]),
      );
    });
  });
}
