/// Sprint 115.20 — Local Storage Summary.
///
/// Local disk accounting is intentionally separate from cloud quota readings.
/// The summary contains only scan observations and never fabricates provider data.
library;

enum LocalStorageCategory {
  projects,
  assets,
  models,
  archive,
  cache,
  temp,
  backups,
  other,
}

final class LocalStorageSummary {
  LocalStorageSummary._({
    required DateTime scannedAt,
    required this.freeBytes,
    required Map<LocalStorageCategory, int> categories,
    required Set<LocalStorageCategory> protectedCategories,
  }) : scannedAt = scannedAt.toUtc(),
       _bytesByCategory = Map.unmodifiable(categories),
       _protectedCategories = Set.unmodifiable(protectedCategories);

  factory LocalStorageSummary.fromScan({
    required DateTime scannedAt,
    required int freeBytes,
    required Map<LocalStorageCategory, int> categories,
    required Set<LocalStorageCategory> protectedCategories,
    Duration freshFor = const Duration(hours: 24),
  }) {
    if (freeBytes < 0) throw ArgumentError.value(freeBytes, 'freeBytes');
    if (freshFor.isNegative) throw ArgumentError.value(freshFor, 'freshFor');
    for (final entry in categories.entries) {
      if (entry.value < 0) {
        throw ArgumentError.value(entry.value, 'categories[${entry.key}]');
      }
    }
    return LocalStorageSummary._(
      scannedAt: scannedAt,
      freeBytes: freeBytes,
      categories: categories,
      protectedCategories: protectedCategories,
    );
  }

  final DateTime scannedAt;
  final int freeBytes;
  final Map<LocalStorageCategory, int> _bytesByCategory;
  final Set<LocalStorageCategory> _protectedCategories;

  /// Cloud bytes are deliberately absent: local and remote storage are not
  /// combined by this contract.
  int? get cloudBytes => null;

  int get totalBytes =>
      _bytesByCategory.values.fold(0, (sum, value) => sum + value);

  int bytesFor(LocalStorageCategory category) =>
      _bytesByCategory[category] ?? 0;

  bool isProtected(LocalStorageCategory category) =>
      _protectedCategories.contains(category);

  bool isRegenerable(LocalStorageCategory category) =>
      category == LocalStorageCategory.cache ||
      category == LocalStorageCategory.temp;

  bool isFreshAt(
    DateTime now, {
    Duration freshFor = const Duration(hours: 24),
  }) {
    if (freshFor.isNegative) return false;
    final age = now.toUtc().difference(scannedAt);
    return !age.isNegative && age <= freshFor;
  }
}
