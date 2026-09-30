/// Sprint 115.18 — Cloud Storage Aggregation.
///
/// Aggregates only compatible provider-reported byte readings. Missing,
/// provider-defined, or stale values remain explicit in the result.
library;

import 'account_center_provider_quota_adapter.dart';

enum CloudStorageAggregationStatus { complete, partial, stale, unavailable }

final class CloudStorageAggregation {
  CloudStorageAggregation._({
    required this.status,
    required this.usedBytes,
    required this.quotaBytes,
    required this.availableBytes,
    required Iterable<String> includedProviderIds,
    required Iterable<String> excludedProviderIds,
    required this.lastUpdated,
  }) : includedProviderIds = List<String>.unmodifiable(includedProviderIds),
       excludedProviderIds = List<String>.unmodifiable(excludedProviderIds);

  factory CloudStorageAggregation.from(Iterable<ProviderQuotaResult> results) {
    var used = 0;
    var quota = 0;
    DateTime? lastUpdated;
    var hasStale = false;
    final included = <String>[];
    final excluded = <String>[];

    for (final result in results) {
      final reading = result.reading;
      if (result.status == ProviderQuotaStatus.unavailable ||
          reading == null ||
          reading.unit != ProviderQuotaUnit.bytes) {
        excluded.add(result.providerId);
        continue;
      }
      used += reading.usedBytes;
      quota += reading.quotaBytes;
      included.add(reading.providerId);
      if (result.status == ProviderQuotaStatus.stale) hasStale = true;
      // A total is only as current as its newest member. Reducing with
      // `isBefore` kept the *oldest* reading and dated the aggregate to a
      // measurement no included account produced. 115.18's own `last_updated`
      // acceptance means the newest one.
      if (lastUpdated == null || reading.measuredAt.isAfter(lastUpdated)) {
        lastUpdated = reading.measuredAt;
      }
    }

    final hasExcluded = excluded.isNotEmpty;
    final status = included.isEmpty
        ? CloudStorageAggregationStatus.unavailable
        : hasStale
        ? CloudStorageAggregationStatus.stale
        : hasExcluded
        ? CloudStorageAggregationStatus.partial
        : CloudStorageAggregationStatus.complete;
    return CloudStorageAggregation._(
      status: status,
      usedBytes: included.isEmpty ? null : used,
      quotaBytes: included.isEmpty ? null : quota,
      availableBytes: included.isEmpty ? null : quota - used,
      includedProviderIds: included,
      excludedProviderIds: excluded,
      lastUpdated: lastUpdated,
    );
  }

  final CloudStorageAggregationStatus status;
  final int? usedBytes;
  final int? quotaBytes;
  final int? availableBytes;
  final List<String> includedProviderIds;
  final List<String> excludedProviderIds;
  final DateTime? lastUpdated;

  bool get isStale => status == CloudStorageAggregationStatus.stale;
}
