/// Sprint 115.19 — Storage Usage Cards.
///
/// Presentation-ready metadata for a provider storage card. Unknown quota and
/// stale readings stay explicit; this type does not claim live connectivity.
library;

enum StorageUsageCardIcon { cloud, hardDrive, archive }

enum StorageUsageFreshness { fresh, stale, unknown }

final class StorageUsageCardData {
  StorageUsageCardData._({
    required this.providerId,
    required this.accountLabel,
    required this.icon,
    required this.usedBytes,
    required this.quotaBytes,
    required this.measuredAt,
    required this.freshness,
  });

  factory StorageUsageCardData.fromBytes({
    required String providerId,
    required String accountLabel,
    required int usedBytes,
    required int quotaBytes,
    required DateTime measuredAt,
    required DateTime now,
    StorageUsageCardIcon icon = StorageUsageCardIcon.cloud,
    Duration staleAfter = const Duration(hours: 24),
  }) {
    _validateBytes(usedBytes, quotaBytes);
    return StorageUsageCardData._(
      providerId: _required(providerId, 'providerId'),
      accountLabel: _required(accountLabel, 'accountLabel'),
      icon: icon,
      usedBytes: usedBytes,
      quotaBytes: quotaBytes,
      measuredAt: measuredAt,
      freshness: _freshness(now, measuredAt, staleAfter),
    );
  }

  factory StorageUsageCardData.unknownQuota({
    required String providerId,
    required String accountLabel,
    required int usedBytes,
    required DateTime measuredAt,
    required DateTime now,
    StorageUsageCardIcon icon = StorageUsageCardIcon.cloud,
  }) {
    if (usedBytes < 0) {
      throw ArgumentError.value(usedBytes, 'usedBytes');
    }
    return StorageUsageCardData._(
      providerId: _required(providerId, 'providerId'),
      accountLabel: _required(accountLabel, 'accountLabel'),
      icon: icon,
      usedBytes: usedBytes,
      quotaBytes: null,
      measuredAt: measuredAt,
      freshness: _freshness(now, measuredAt, const Duration(hours: 24)),
    );
  }

  final String providerId;
  final String accountLabel;
  final StorageUsageCardIcon icon;
  final int usedBytes;
  final int? quotaBytes;
  final DateTime measuredAt;
  final StorageUsageFreshness freshness;

  double? get percentage => quotaBytes == null ? null : usedBytes / quotaBytes!;

  String get quotaLabel =>
      quotaBytes == null ? 'Quota unavailable' : _formatBytes(quotaBytes!);

  String get statusLabel => switch (freshness) {
    StorageUsageFreshness.fresh => 'Fresh',
    StorageUsageFreshness.stale => 'Stale',
    StorageUsageFreshness.unknown => 'Unknown freshness',
  };

  String get accessibleProgress {
    final quota = quotaBytes;
    if (quota == null) {
      return '${_formatBytes(usedBytes)} used; quota unavailable';
    }
    final percent = (percentage! * 100).round();
    return '$percent% used, ${_formatBytes(quota - usedBytes)} available of ${_formatBytes(quota)}';
  }

  static StorageUsageFreshness _freshness(
    DateTime now,
    DateTime measuredAt,
    Duration staleAfter,
  ) {
    final age = now.toUtc().difference(measuredAt.toUtc());
    if (age.isNegative) return StorageUsageFreshness.unknown;
    return age > staleAfter
        ? StorageUsageFreshness.stale
        : StorageUsageFreshness.fresh;
  }

  static void _validateBytes(int used, int quota) {
    if (used < 0 || quota < 0 || quota < used) {
      throw ArgumentError('Storage bytes must satisfy 0 <= used <= quota.');
    }
  }

  static String _required(String value, String field) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, field);
    }
    return normalized;
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
