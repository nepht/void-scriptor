/// Sprint 115.16 — Cloud Storage Account Model.
///
/// Metadata-only account model. It records declared capability and scope
/// support without claiming provider connectivity, quota values, or live sync.
library;

enum CloudStorageCapability { storage, sync, backup }

enum CloudStorageRootScope { account, workspace }

enum CloudStorageSupport { supported, unsupported, unknown }

enum CloudStorageFreshness { fresh, stale, unknown, invalid }

final class CloudStorageAccount {
  CloudStorageAccount({
    required String accountId,
    required String providerId,
    required String displayName,
    required Iterable<CloudStorageCapability> capabilities,
    required this.rootScope,
    required this.quotaSupport,
    required this.syncSupport,
    required this.backupSupport,
    required this.freshness,
  }) : accountId = _required(accountId, 'accountId'),
       providerId = _required(providerId, 'providerId').toLowerCase(),
       displayName = _required(displayName, 'displayName'),
       capabilities = _normalizeCapabilities(capabilities) {
    if (freshness == CloudStorageFreshness.invalid) {
      throw ArgumentError.value(freshness, 'freshness');
    }
  }

  final String accountId;
  final String providerId;
  final String displayName;
  final Set<CloudStorageCapability> capabilities;
  final CloudStorageRootScope rootScope;
  final CloudStorageSupport quotaSupport;
  final CloudStorageSupport syncSupport;
  final CloudStorageSupport backupSupport;
  final CloudStorageFreshness freshness;

  static String _required(String value, String field) {
    final normalized = value.trim();
    if (normalized.isEmpty) throw ArgumentError.value(value, field);
    return normalized;
  }

  static Set<CloudStorageCapability> _normalizeCapabilities(
    Iterable<CloudStorageCapability> values,
  ) {
    final normalized = Set<CloudStorageCapability>.unmodifiable(values);
    if (normalized.isEmpty) {
      throw ArgumentError.value(values, 'capabilities');
    }
    return normalized;
  }
}
