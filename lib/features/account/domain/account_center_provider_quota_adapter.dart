/// Sprint 115.17 — Provider Quota Adapters.
///
/// Raw provider usage contract. Adapters preserve provider values and expose
/// unavailable or stale data explicitly; they never synthesize quota.
library;

enum ProviderQuotaUnit {
  bytes,
  kibibytes,
  mebibytes,
  gibibytes,
  tebibytes,
  providerDefined,
}

enum ProviderQuotaStatus { fresh, stale, unavailable }

final class ProviderQuotaReading {
  ProviderQuotaReading({
    required String providerId,
    required this.usedBytes,
    required this.quotaBytes,
    required this.availableBytes,
    required this.measuredAt,
    required this.unit,
  }) : providerId = _required(providerId, 'providerId') {
    if (usedBytes < 0 || quotaBytes < 0 || availableBytes < 0) {
      throw ArgumentError('Quota values cannot be negative.');
    }
    if (quotaBytes < usedBytes || availableBytes != quotaBytes - usedBytes) {
      throw ArgumentError(
        'Quota values must satisfy quota = used + available.',
      );
    }
  }

  final String providerId;
  final int usedBytes;
  final int quotaBytes;
  final int availableBytes;
  final DateTime measuredAt;
  final ProviderQuotaUnit unit;

  static String _required(String value, String field) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) throw ArgumentError.value(value, field);
    return normalized;
  }
}

final class ProviderQuotaResult {
  const ProviderQuotaResult._({
    required this.providerId,
    required this.status,
    required this.reading,
    required this.reason,
  });

  factory ProviderQuotaResult.fromReading(
    ProviderQuotaReading reading, {
    required DateTime now,
    Duration staleAfter = const Duration(hours: 24),
  }) {
    final age = now.toUtc().difference(reading.measuredAt.toUtc());
    return ProviderQuotaResult._(
      providerId: reading.providerId,
      status: age > staleAfter
          ? ProviderQuotaStatus.stale
          : ProviderQuotaStatus.fresh,
      reading: reading,
      reason: null,
    );
  }

  factory ProviderQuotaResult.unavailable({
    required String providerId,
    required String reason,
  }) {
    final normalizedReason = reason.trim();
    if (providerId.trim().isEmpty || normalizedReason.isEmpty) {
      throw ArgumentError('Unavailable quota requires provider and reason.');
    }
    return ProviderQuotaResult._(
      providerId: _requiredProviderId(providerId),
      status: ProviderQuotaStatus.unavailable,
      reading: null,
      reason: normalizedReason,
    );
  }

  final String providerId;
  final ProviderQuotaStatus status;
  final ProviderQuotaReading? reading;
  final String? reason;

  static String _requiredProviderId(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) throw ArgumentError.value(value, 'providerId');
    return normalized;
  }
}

abstract interface class ProviderQuotaAdapter {
  ProviderQuotaResult read({required DateTime now});
}
