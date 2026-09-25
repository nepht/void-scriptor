import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_cloud_storage_aggregation.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_quota_adapter.dart';

void main() {
  group('115.18 Cloud Storage Aggregation', () {
    test(
      'aggregates compatible remote bytes and excludes unavailable accounts',
      () {
        final aggregation = CloudStorageAggregation.from([
          ProviderQuotaResult.fromReading(
            _reading('drive', used: 200, quota: 1_000),
            now: _now,
          ),
          ProviderQuotaResult.fromReading(
            _reading('dropbox', used: 300, quota: 2_000),
            now: _now,
          ),
          ProviderQuotaResult.unavailable(
            providerId: 'onedrive',
            reason: 'Quota was not returned',
          ),
        ]);

        expect(aggregation.usedBytes, 500);
        expect(aggregation.quotaBytes, 3_000);
        expect(aggregation.availableBytes, 2_500);
        expect(aggregation.includedProviderIds, ['drive', 'dropbox']);
        expect(aggregation.excludedProviderIds, ['onedrive']);
        expect(aggregation.status, CloudStorageAggregationStatus.partial);
        expect(aggregation.lastUpdated, _now);
      },
    );

    test('marks aggregation stale when an included reading is stale', () {
      final aggregation = CloudStorageAggregation.from([
        ProviderQuotaResult.fromReading(
          _reading(
            'drive',
            used: 100,
            quota: 500,
            measuredAt: _now.subtract(const Duration(days: 2)),
          ),
          now: _now,
        ),
        ProviderQuotaResult.fromReading(
          _reading('dropbox', used: 50, quota: 200),
          now: _now,
        ),
      ]);

      expect(aggregation.status, CloudStorageAggregationStatus.stale);
      expect(aggregation.isStale, isTrue);
      expect(aggregation.usedBytes, 150);
    });

    test('does not combine provider-defined units with byte totals', () {
      final aggregation = CloudStorageAggregation.from([
        ProviderQuotaResult.fromReading(
          _reading('drive', used: 100, quota: 500),
          now: _now,
        ),
        ProviderQuotaResult.fromReading(
          _reading(
            'provider-units',
            used: 10,
            quota: 20,
            unit: ProviderQuotaUnit.providerDefined,
          ),
          now: _now,
        ),
      ]);

      expect(aggregation.usedBytes, 100);
      expect(aggregation.quotaBytes, 500);
      expect(aggregation.excludedProviderIds, ['provider-units']);
      expect(aggregation.status, CloudStorageAggregationStatus.partial);
    });

    test('reports unavailable when no compatible reading exists', () {
      final aggregation = CloudStorageAggregation.from([
        ProviderQuotaResult.unavailable(
          providerId: 'drive',
          reason: 'Provider did not return quota',
        ),
      ]);

      expect(aggregation.status, CloudStorageAggregationStatus.unavailable);
      expect(aggregation.usedBytes, isNull);
      expect(aggregation.quotaBytes, isNull);
      expect(aggregation.lastUpdated, isNull);
    });
  });
}

final _now = DateTime.utc(2026, 9, 25, 8);

ProviderQuotaReading _reading(
  String providerId, {
  required int used,
  required int quota,
  DateTime? measuredAt,
  ProviderQuotaUnit unit = ProviderQuotaUnit.bytes,
}) => ProviderQuotaReading(
  providerId: providerId,
  usedBytes: used,
  quotaBytes: quota,
  availableBytes: quota - used,
  measuredAt: measuredAt ?? _now,
  unit: unit,
);
