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
      if (result.status == ProviderQuotaStatus.unavailable || reading == null) {
        excluded.add(result.providerId);
        continue;
      }
      // 117.29: a provider that reports GiB/MiB/KiB/TiB was dropped from the
      // total entirely, so a Mega account simply vanished from the aggregate
      // and the user saw a smaller "total cloud usage" than they actually have.
      // Convert the declared unit to bytes first; only a unit this build
      // cannot convert stays excluded.
      final converted = _convertToBytes(reading);
      if (converted == null) {
        excluded.add(result.providerId);
        continue;
      }
      used += converted.usedBytes;
      quota += converted.quotaBytes;
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

/// The reading's three values expressed in bytes, or `null` when the provider
/// reported a unit this build cannot convert.
({int usedBytes, int quotaBytes, int availableBytes})? _convertToBytes(
  ProviderQuotaReading reading,
) {
  final multiplier = switch (reading.unit) {
    ProviderQuotaUnit.bytes => 1,
    ProviderQuotaUnit.kibibytes => 1024,
    ProviderQuotaUnit.mebibytes => 1024 * 1024,
    ProviderQuotaUnit.gibibytes => 1024 * 1024 * 1024,
    ProviderQuotaUnit.tebibytes => 1024 * 1024 * 1024 * 1024,
    // A provider-defined unit has no meaning this build can assert, so it
    // stays excluded rather than being guessed at.
    ProviderQuotaUnit.providerDefined => null,
  };
  if (multiplier == null) return null;
  return (
    usedBytes: reading.usedBytes * multiplier,
    quotaBytes: reading.quotaBytes * multiplier,
    availableBytes: reading.availableBytes * multiplier,
  );
}
