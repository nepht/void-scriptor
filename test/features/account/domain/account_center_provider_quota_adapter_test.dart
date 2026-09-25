import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_quota_adapter.dart';

void main() {
  group('115.17 Provider Quota Adapters', () {
    test('preserves raw bytes, provider timestamp, and unit metadata', () {
      final reading = ProviderQuotaReading(
        providerId: ' Google_Drive ',
        usedBytes: 120,
        quotaBytes: 1_000,
        availableBytes: 880,
        measuredAt: DateTime.utc(2026, 9, 25, 8),
        unit: ProviderQuotaUnit.bytes,
      );

      expect(reading.providerId, 'google_drive');
      expect(reading.usedBytes, 120);
      expect(reading.quotaBytes, 1000);
      expect(reading.availableBytes, 880);
      expect(reading.measuredAt, DateTime.utc(2026, 9, 25, 8));
      expect(reading.unit, ProviderQuotaUnit.bytes);
    });

    test('marks unavailable quota instead of inventing a value', () {
      final result = ProviderQuotaResult.unavailable(
        providerId: 'drive',
        reason: 'Provider did not return quota',
      );

      expect(result.status, ProviderQuotaStatus.unavailable);
      expect(result.reading, isNull);
      expect(result.reason, 'Provider did not return quota');
    });

    test('marks stale readings using the adapter freshness policy', () {
      final adapter = FixedQuotaAdapter(
        ProviderQuotaReading(
          providerId: 'drive',
          usedBytes: 100,
          quotaBytes: 200,
          availableBytes: 100,
          measuredAt: DateTime.utc(2026, 9, 23, 23),
          unit: ProviderQuotaUnit.bytes,
        ),
      );

      final result = adapter.read(now: DateTime.utc(2026, 9, 25));

      expect(result.status, ProviderQuotaStatus.stale);
      expect(result.reading, isNotNull);
    });

    test('rejects inconsistent or negative raw values', () {
      expect(
        () => ProviderQuotaReading(
          providerId: 'drive',
          usedBytes: -1,
          quotaBytes: 100,
          availableBytes: 101,
          measuredAt: DateTime.utc(2026, 9, 25),
          unit: ProviderQuotaUnit.bytes,
        ),
        throwsArgumentError,
      );
      expect(
        () => ProviderQuotaReading(
          providerId: 'drive',
          usedBytes: 80,
          quotaBytes: 100,
          availableBytes: 10,
          measuredAt: DateTime.utc(2026, 9, 25),
          unit: ProviderQuotaUnit.bytes,
        ),
        throwsArgumentError,
      );
    });
  });
}

final class FixedQuotaAdapter implements ProviderQuotaAdapter {
  FixedQuotaAdapter(this.reading);

  final ProviderQuotaReading reading;

  @override
  ProviderQuotaResult read({required DateTime now}) =>
      ProviderQuotaResult.fromReading(reading, now: now);
}
