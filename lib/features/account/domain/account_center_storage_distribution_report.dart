/// Sprint 115.41 — Storage Distribution Chart & Table.
///
/// The distribution surface behind the Account & Cloud Center storage panel: a
/// chart of where the bytes are, a detail table of the readings that produced
/// them, and a drill-down per scope/category pair.
///
/// The product spec's `storage_usage_contract.display_rules` forbid the two
/// easy lies here, so the contract encodes them structurally:
///
/// * `Separate remote cloud total from local storage total.` — a slice is keyed
///   by scope **and** category, so a local and a remote category of the same
///   name never merge, and a total that adds them together is only published
///   with an explicit `Local + remote combined` label and a warning. A
///   single-scope report publishes no combined total at all.
/// * `Do not sum accounts with stale or unavailable data into a precise total
///   without warning.` — a total containing a stale, expired, future-dated, or
///   unmeasured record is `Approximate` with a reason, never `Reported`.
///
/// A chart is not a table: every slice carries a text alternative so the
/// distribution survives without pixels, a zero total is declared unrenderable
/// instead of divided by, and a category label this build does not know is
/// preserved verbatim — never folded into `other`, which would make an
/// unrecognised folder look like a real one.
///
/// Sizes are formatted in decimal GB/TB per the spec's display rule, and a
/// provider-reported unit that differs from the display unit is shown as a note
/// rather than silently converted. A quota the provider omitted reads
/// `Quota unavailable`, never a zero.
///
/// Freshness is derived from each record's own `measured_at` against an
/// injected clock, never the wall clock at render time.
///
/// No provider request, local scan, or quota read happens here, reference mock
/// values cannot be produced, and public-trust signing, hosted CI, telemetry,
/// hardware, adoption, and publication stay `DEFERRED-EXTERNAL`.
library;

import 'dart:collection';

/// Where a set of bytes lives.
enum StorageDistributionScope {
  /// Bytes on this device.
  local,

  /// Bytes held by a connected provider account.
  remote,
}

/// The categories a distribution can be broken down by.
///
/// Mirrors the local storage summary's category vocabulary plus `unrecognized`,
/// which is the only bucket an unknown label may occupy — and only while keeping
/// its own name.
enum StorageCategoryKind {
  projects,
  assets,
  models,
  archive,
  cache,
  temp,
  backups,
  other,

  /// A label this build does not recognise. Never merged into [other].
  unrecognized,
}

/// Where a single reading came from.
///
/// Mirrors the spec's `storage_usage_contract.data_sources`; a reading that was
/// not produced by a provider API must not be presented as one.
enum StorageRecordSource {
  providerApi,
  localScan,
  userDeclared,

  /// No reading could be obtained. The size is unknown, not zero.
  unavailable,
}

extension _StorageSourceWire on StorageRecordSource {
  String get wireName => switch (this) {
    StorageRecordSource.providerApi => 'provider_api',
    StorageRecordSource.localScan => 'local_scan',
    StorageRecordSource.userDeclared => 'user_declared',
    StorageRecordSource.unavailable => 'unavailable',
  };

  String get label => switch (this) {
    StorageRecordSource.providerApi => 'Provider API',
    StorageRecordSource.localScan => 'Local scan',
    StorageRecordSource.userDeclared => 'User declared',
    StorageRecordSource.unavailable => 'Unavailable',
  };
}

/// How current a record is relative to the injected clock.
enum StorageDistributionFreshness {
  live,
  stale,
  expired,

  /// `measured_at` is later than the reference clock. A record that claims to
  /// be measured in the future is a data defect, not a fresh reading.
  futureTimestamped,
}

/// Why a report shows nothing.
enum StorageDistributionEmptyReason {
  /// No storage records were supplied at all.
  noData,

  /// Records exist, but the filter excluded every one of them.
  filteredOut,
}

/// A category, either a canonical one or a label this build did not recognise.
///
/// Validated through a factory so a blank label is refused in every build mode;
/// a const constructor's `assert` disappears in release.
final class StorageCategoryRef {
  factory StorageCategoryRef.canonical(StorageCategoryKind kind) {
    if (kind == StorageCategoryKind.unrecognized) {
      throw ArgumentError.value(
        kind,
        'kind',
        'Use StorageCategoryRef.unrecognized(label) for an unknown category',
      );
    }
    return StorageCategoryRef._(kind, _canonicalLabel(kind), true);
  }

  factory StorageCategoryRef.unrecognized(String label) {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(label, 'label', 'must not be blank');
    }
    return StorageCategoryRef._(
      StorageCategoryKind.unrecognized,
      trimmed,
      false,
    );
  }

  const StorageCategoryRef._(this.kind, this.label, this.isCanonical);

  final StorageCategoryKind kind;

  /// The verbatim label. An unrecognised category keeps its own name.
  final String label;

  final bool isCanonical;

  /// The stable identity used to group and to address a drill-down.
  String get key => isCanonical ? kind.name : 'unrecognized';

  /// The heading a drill-down for this category carries.
  ///
  /// An unrecognised category is headed as such — never as one of its raw
  /// labels, which would present a folder name as a category of the product.
  String get drillDownLabel =>
      isCanonical ? label : _canonicalLabel(StorageCategoryKind.unrecognized);

  @override
  bool operator ==(Object other) =>
      other is StorageCategoryRef && other.key == key && other.label == label;

  @override
  int get hashCode => Object.hash(key, label);

  @override
  String toString() => '$key/$label';
}

String _canonicalLabel(StorageCategoryKind kind) => switch (kind) {
  StorageCategoryKind.projects => 'Projects',
  StorageCategoryKind.assets => 'Assets',
  StorageCategoryKind.models => 'Models',
  StorageCategoryKind.archive => 'Archive',
  StorageCategoryKind.cache => 'Cache',
  StorageCategoryKind.temp => 'Temp',
  StorageCategoryKind.backups => 'Backups',
  StorageCategoryKind.other => 'Other',
  StorageCategoryKind.unrecognized => 'Unrecognised categories',
};

/// The windows that decide [StorageDistributionFreshness].
///
/// Validated in a factory rather than an initializer so a caller cannot build
/// a policy with a negative window or a stale threshold that outlives the
/// expiry threshold.
final class StorageDistributionFreshnessPolicy {
  factory StorageDistributionFreshnessPolicy({
    Duration staleAfter = const Duration(hours: 24),
    Duration expiresAfter = const Duration(days: 7),
  }) {
    if (staleAfter <= Duration.zero) {
      throw ArgumentError.value(staleAfter, 'staleAfter', 'must be positive');
    }
    if (expiresAfter <= staleAfter) {
      throw ArgumentError.value(
        expiresAfter,
        'expiresAfter',
        'must be later than staleAfter (${staleAfter.inMinutes} minutes)',
      );
    }
    return StorageDistributionFreshnessPolicy._(staleAfter, expiresAfter);
  }

  const StorageDistributionFreshnessPolicy._(
    this.staleAfter,
    this.expiresAfter,
  );

  final Duration staleAfter;
  final Duration expiresAfter;

  StorageDistributionFreshness classify({
    required DateTime measuredAt,
    required DateTime now,
  }) {
    final age = now.toUtc().difference(measuredAt.toUtc());
    if (age.isNegative) return StorageDistributionFreshness.futureTimestamped;
    if (age > expiresAfter) return StorageDistributionFreshness.expired;
    if (age > staleAfter) return StorageDistributionFreshness.stale;
    return StorageDistributionFreshness.live;
  }
}

/// Narrows the report by scope.
///
/// Scopes are named rather than enum-typed on purpose: a value the data does not
/// contain must be reportable as an unknown name, and an enum cannot hold one.
final class StorageScopeFilter {
  factory StorageScopeFilter({Set<String> scopeNames = const <String>{}}) {
    final normalized = <String>{};
    final unknown = <String>[];
    for (final raw in scopeNames) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      normalized.add(trimmed);
      if (_scopeFromName(trimmed) == null) unknown.add(trimmed);
    }
    return StorageScopeFilter._(
      Set.unmodifiable(normalized),
      Set.unmodifiable(unknown),
    );
  }

  /// Keeps every scope.
  factory StorageScopeFilter.all() => StorageScopeFilter();

  /// Device bytes only.
  factory StorageScopeFilter.localOnly() =>
      StorageScopeFilter(scopeNames: {'local'});

  /// Provider bytes only.
  factory StorageScopeFilter.remoteOnly() =>
      StorageScopeFilter(scopeNames: {'remote'});

  const StorageScopeFilter._(this.scopeNames, this.unknownScopeNames);

  /// Wire names, not enum values, so a typo survives to be reported.
  final Set<String> scopeNames;

  /// Names in [scopeNames] that no scope can satisfy.
  final Set<String> unknownScopeNames;

  bool matches(StorageDistributionRecord record) =>
      scopeNames.isEmpty || scopeNames.contains(record.scope.wireName);

  /// Filter values that match nothing in the supplied data.
  ///
  /// Reported instead of silently producing an empty chart, because a typo and
  /// a genuinely empty account look identical otherwise.
  List<String> unknownValuesAgainst(
    Iterable<StorageDistributionRecord> records,
  ) {
    final data = records.toList(growable: false);
    final unknown = <String>[];
    for (final name in scopeNames) {
      if (_scopeFromName(name) == null) {
        unknown.add(name);
        continue;
      }
      if (!data.any((record) => record.scope.wireName == name)) {
        unknown.add(name);
      }
    }
    unknown.sort();
    return UnmodifiableListView(unknown);
  }
}

StorageDistributionScope? _scopeFromName(String name) {
  for (final scope in StorageDistributionScope.values) {
    if (scope.wireName == name) return scope;
  }
  return null;
}

/// Public so a test or a UI row can name the scope without re-deriving it.
extension StorageDistributionScopeWire on StorageDistributionScope {
  String get wireName => switch (this) {
    StorageDistributionScope.local => 'local',
    StorageDistributionScope.remote => 'remote',
  };

  String get label => switch (this) {
    StorageDistributionScope.local => 'Local storage',
    StorageDistributionScope.remote => 'Remote storage',
  };
}

/// One measured reading of a category in one scope.
///
/// A remote record carries the account it came from; a local record has no
/// account, because local bytes are not owned by a provider.
final class StorageDistributionRecord {
  StorageDistributionRecord({
    required this.scope,
    required this.category,
    required this.bytes,
    required DateTime measuredAt,
    required this.source,
    this.accountId,
    this.providerId,
    this.quotaBytes,
    this.providerReportedUnit,
  }) : measuredAt = measuredAt.toUtc() {
    if (bytes < 0) {
      throw ArgumentError.value(bytes, 'bytes', 'must not be negative');
    }
    final quota = quotaBytes;
    if (quota != null && quota < 0) {
      throw ArgumentError.value(quota, 'quotaBytes', 'must not be negative');
    }
    if (scope == StorageDistributionScope.remote &&
        (accountId?.trim().isEmpty ?? true)) {
      throw ArgumentError.value(
        accountId,
        'accountId',
        'a remote record must name the account it was read from',
      );
    }
    if (source == StorageRecordSource.providerApi &&
        scope != StorageDistributionScope.remote) {
      throw ArgumentError.value(
        source,
        'source',
        'only a remote record can come from a provider API',
      );
    }
    if (source == StorageRecordSource.localScan &&
        scope != StorageDistributionScope.local) {
      throw ArgumentError.value(
        source,
        'source',
        'only a local record can come from a local scan',
      );
    }
  }

  final StorageDistributionScope scope;
  final StorageCategoryRef category;
  final int bytes;
  final DateTime measuredAt;
  final StorageRecordSource source;

  /// Required for a remote record, `null` for a local one.
  final String? accountId;

  final String? providerId;

  /// `null` when the provider did not report a quota. Never defaulted to zero.
  final int? quotaBytes;

  /// The unit the provider itself used, when it differs from the display unit.
  final String? providerReportedUnit;

  /// An [StorageRecordSource.unavailable] reading has no measured size, and
  /// its `bytes` is a placeholder rather than a measurement.
  bool get isMeasured => source != StorageRecordSource.unavailable;

  /// `true` when a value is present that a user typed rather than a system that
  /// measured or reported it.
  bool get isUnverified =>
      source == StorageRecordSource.userDeclared ||
      source == StorageRecordSource.unavailable;
}

/// One wedge of the distribution.
final class StorageDistributionSlice {
  StorageDistributionSlice._({
    required this.scope,
    required this.category,
    required this.bytes,
    required this.recordCount,
    required List<String> unrecognizedLabels,
    required List<StorageDistributionRow> rows,
  }) : unrecognizedLabels = List<String>.unmodifiable(unrecognizedLabels),
       rows = List<StorageDistributionRow>.unmodifiable(rows),
       totalBytes = 0;

  final StorageDistributionScope scope;
  final StorageCategoryRef category;
  final int bytes;
  final int recordCount;

  /// Raw labels behind an [StorageCategoryKind.unrecognized] slice.
  final List<String> unrecognizedLabels;

  /// The rows that produced this slice. Never crosses the scope boundary.
  final List<StorageDistributionRow> rows;

  /// Set by the chart once the whole distribution is known.
  int totalBytes = 0;

  /// The share of the distribution this wedge reaches, `null` when the
  /// distribution is empty and nothing can be scaled.
  double? get shareOfTotal {
    if (totalBytes <= 0) return null;
    return bytes / totalBytes;
  }

  int? get percentOfTotal {
    final share = shareOfTotal;
    return share == null ? null : (share * 100).round();
  }

  /// Readable without the chart. Always non-blank.
  String get textAlternative {
    final buffer = StringBuffer(
      '${category.label} on ${scope.label.toLowerCase()}: '
      '${_formatBytes(bytes)} of ${_formatBytes(totalBytes)}',
    );
    final percent = percentOfTotal;
    if (percent != null) buffer.write(' ($percent%)');
    buffer.write(' from $recordCount record(s)');
    if (unrecognizedLabels.isNotEmpty) {
      buffer.write(' — unrecognised as ${unrecognizedLabels.join(', ')}');
    }
    return buffer.toString();
  }
}

/// The distribution itself.
final class StorageDistributionChart {
  StorageDistributionChart._({
    required List<StorageDistributionSlice> slices,
    required this.recordCount,
  }) : slices = List<StorageDistributionSlice>.unmodifiable(slices) {
    totalBytes = this.slices.fold<int>(0, (sum, slice) => sum + slice.bytes);
    for (final slice in this.slices) {
      slice.totalBytes = totalBytes;
    }
  }

  final List<StorageDistributionSlice> slices;

  /// Records behind the chart, including any in a slice that read as zero.
  final int recordCount;

  late final int totalBytes;

  /// An empty distribution cannot be scaled; the UI must say so instead of
  /// dividing by it.
  bool get isRenderable => totalBytes > 0;

  bool get hasUnrecognizedCategory => slices.any(
    (slice) => slice.category.kind == StorageCategoryKind.unrecognized,
  );

  String get textAlternative {
    if (slices.isEmpty) return 'Storage distribution: no data to show.';
    if (!isRenderable) {
      return 'Storage distribution: ${slices.length} categor'
          '${slices.length == 1 ? 'y' : 'ies'} recorded, nothing to plot '
          '(every recorded size is zero).';
    }
    final parts = <String>[
      for (final slice in slices)
        '${slice.category.label} ${slice.percentOfTotal}% (${_formatBytes(slice.bytes)})',
    ];
    final suffix = hasUnrecognizedCategory
        ? ' Includes categories this build does not recognise.'
        : '';
    return 'Storage distribution: ${slices.length} categor'
        '${slices.length == 1 ? 'y' : 'ies'}, ${_formatBytes(totalBytes)} total — '
        '${parts.join('; ')}.$suffix';
  }
}

/// One row of the detail table.
final class StorageDistributionRow {
  StorageDistributionRow._({
    required this.scope,
    required this.category,
    required this.bytes,
    required this.measuredAt,
    required this.source,
    required this.freshness,
    required this.accountId,
    required this.providerId,
    required this.quotaBytes,
    required this.providerReportedUnit,
  });

  /// The closed set of fields a row may publish.
  ///
  /// There is deliberately no prompt, content, or free-text field: a storage
  /// distribution must never be able to carry file names or creative content.
  static const publicFields = <String>{
    'scope',
    'category_key',
    'category_label',
    'category_is_canonical',
    'bytes',
    'size_label',
    'display_unit',
    'measured_at',
    'source',
    'source_label',
    'freshness',
    'is_measured',
    'account_id',
    'provider_id',
    'quota_bytes',
    'quota_label',
    'percent_of_quota',
    'provider_reported_unit',
  };

  final StorageDistributionScope scope;
  final StorageCategoryRef category;
  final int bytes;
  final DateTime measuredAt;
  final StorageRecordSource source;
  final StorageDistributionFreshness freshness;
  final String? accountId;
  final String? providerId;
  final int? quotaBytes;
  final String? providerReportedUnit;

  /// An unmeasured reading has no size; the `bytes` field carries no meaning.
  bool get isMeasured => source != StorageRecordSource.unavailable;

  bool get isCurrent => freshness == StorageDistributionFreshness.live;

  /// `true` when the value is a user-declared or missing reading rather than a
  /// measurement a system produced.
  bool get isUnverified =>
      source == StorageRecordSource.userDeclared ||
      source == StorageRecordSource.unavailable;

  /// The unit the size is displayed in, from the spec's decimal-GB/TB rule.
  String get displayUnit {
    if (!isMeasured) return '';
    if (bytes >= _terabyte) return 'TB';
    if (bytes >= _gigabyte) return 'GB';
    if (bytes >= _megabyte) return 'MB';
    if (bytes >= _kilobyte) return 'KB';
    return 'B';
  }

  /// A human-readable size, or `Size unavailable` for an unmeasured reading.
  ///
  /// The unit is already part of [_formatBytes]; appending [displayUnit] again
  /// would print `1.5 GB GB`.
  String get sizeLabel {
    if (!isMeasured) return 'Size unavailable';
    return _formatBytes(bytes);
  }

  String get sourceLabel => source.label;

  /// `Quota unavailable` rather than a zero when the provider omitted it.
  String get quotaLabel {
    final quota = quotaBytes;
    if (quota == null) return 'Quota unavailable';
    if (quota < bytes) return 'Quota below reported use (inconsistent)';
    return _formatBytes(quota);
  }

  /// The share of the quota this reading uses, `null` when no quota was
  /// reported. Never `0` standing in for an unknown quota.
  int? get percentOfQuota {
    final quota = quotaBytes;
    if (quota == null || quota <= 0 || !isMeasured) return null;
    return (bytes / quota * 100).round();
  }

  String get usedLabel {
    final percent = percentOfQuota;
    final quotaPart = percent == null
        ? 'Quota unavailable'
        : '$percent% of ${_formatBytes(quotaBytes!)} quota';
    if (!isMeasured) return 'Size unavailable; $quotaPart';
    return '${_formatBytes(bytes)} used; $quotaPart';
  }

  /// Non-null only when the provider's own unit differs from the display unit.
  String? get providerUnitNote {
    final reported = providerReportedUnit?.trim();
    if (reported == null || reported.isEmpty) return null;
    if (!isMeasured) return null;
    if (reported.toUpperCase() == displayUnit.toUpperCase()) return null;
    return 'Provider reports $reported; displayed in decimal $displayUnit.';
  }

  Map<String, Object?> toPublicJson() => <String, Object?>{
    'scope': scope.wireName,
    'category_key': category.key,
    'category_label': category.label,
    'category_is_canonical': category.isCanonical,
    'bytes': isMeasured ? bytes : null,
    'size_label': sizeLabel,
    'display_unit': displayUnit,
    'measured_at': measuredAt.toIso8601String(),
    'source': source.wireName,
    'source_label': sourceLabel,
    'freshness': freshness.name,
    'is_measured': isMeasured,
    'account_id': accountId,
    'provider_id': providerId,
    'quota_bytes': quotaBytes,
    'quota_label': quotaLabel,
    'percent_of_quota': percentOfQuota,
    'provider_reported_unit': providerReportedUnit,
  };
}

/// The rows behind one slice, reachable from the chart.
final class StorageDistributionDrillDown {
  const StorageDistributionDrillDown._({
    required this.targetId,
    required this.label,
    required this.scope,
    required this.category,
    required this.rows,
    required this.recordCount,
    required this.unrecognizedLabels,
    required this.reason,
  });

  /// `'local/projects'` or `'remote/unrecognized'`.
  final String targetId;
  final String label;
  final StorageDistributionScope scope;
  final StorageCategoryRef category;
  final List<StorageDistributionRow> rows;
  final int recordCount;
  final List<String> unrecognizedLabels;

  /// Why this drill-down is unavailable, `null` when it is.
  final String? reason;

  bool get isAvailable => reason == null;

  /// Readable without the table. Always non-blank.
  String get textAlternative {
    if (!isAvailable) return '$label: unavailable — $reason';
    final total = rows.fold<int>(
      0,
      (sum, row) => sum + (row.isMeasured ? row.bytes : 0),
    );
    final buffer = StringBuffer(
      '$label: $recordCount record(s), ${_formatBytes(total)} total',
    );
    if (unrecognizedLabels.isNotEmpty) {
      buffer.write(', unrecognised as ${unrecognizedLabels.join(', ')}');
    }
    return buffer.toString();
  }
}

final class AccountCenterStorageDistributionReport {
  AccountCenterStorageDistributionReport._({
    required this.chart,
    required this.rows,
    required this.drillDowns,
    required this.unavailableDrillDowns,
    required this.freshnessCounts,
    required this.textSummary,
    required this.unknownFilterValues,
    required this.hiddenRecordCount,
    required this.totalRecordCount,
    required this.emptyReason,
    required this.warnings,
    required this.totalLabel,
    required this.totalReason,
    required this.freshnessLabel,
    required this.lastUpdatedAt,
    required this.mergedBytes,
    required this.mergedLabel,
    required this.localFreeBytes,
  });

  /// `reference_mock_values.production_use_allowed`.
  static const bool referenceMockValuesAllowed = false;

  /// Signing, hosted CI, telemetry, hardware, adoption, and publication.
  static const String externalGateStatus = 'DEFERRED-EXTERNAL';

  /// This step consumes metadata; it performs no provider read or local scan.
  static const String storageContractStatus = 'METADATA_ONLY_NO_PROVIDER_READ';

  /// No scan, quota fetch, or provider call happens inside this report.
  static const bool performsProviderRead = false;

  static const canonicalAcceptance = <String>[
    'category_chart',
    'data_table',
    'remote_local_filter',
    'unknown_category',
    'freshness',
    'drill_down',
  ];

  static const canonicalSprintPath =
      'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/sprint_115.json';
  static const canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';

  static const String mergedTotalWarning =
      'Local and remote storage are combined in one total; they are not the '
      'same pool of bytes.';

  static const String freeSpaceWarning =
      'Free device space is shown next to the used total and is never added '
      'to it.';

  static const String combinedLabel = 'Local + remote combined';

  /// Builds the report from the underlying metadata-only readings.
  factory AccountCenterStorageDistributionReport.build({
    required Iterable<StorageDistributionRecord> records,
    StorageScopeFilter? filter,
    DateTime? now,
    StorageDistributionFreshnessPolicy? freshness,
    int? localFreeBytes,
  }) {
    final effectiveFilter = filter ?? StorageScopeFilter.all();
    final policy = freshness ?? StorageDistributionFreshnessPolicy();
    final clock = (now ?? DateTime.now()).toUtc();

    if (localFreeBytes != null && localFreeBytes < 0) {
      throw ArgumentError.value(localFreeBytes, 'localFreeBytes');
    }

    final all = records.toList(growable: false);
    final unknownValues = effectiveFilter.unknownValuesAgainst(all);
    final kept = all.where(effectiveFilter.matches).toList(growable: false);

    final rows = List<StorageDistributionRow>.unmodifiable(
      kept
          .map(
            (record) => _rowOf(
              record,
              policy.classify(measuredAt: record.measuredAt, now: clock),
            ),
          )
          .toList(growable: false)
        ..sort(_compareRows),
    );

    // Classified but unfiltered, so a drill-down the filter removed can still
    // be described instead of silently vanishing from the surface.
    final allRows = List<StorageDistributionRow>.unmodifiable(
      all
          .map(
            (record) => _rowOf(
              record,
              policy.classify(measuredAt: record.measuredAt, now: clock),
            ),
          )
          .toList(growable: false),
    );

    final chart = StorageDistributionChart._(
      slices: _slices(rows),
      recordCount: rows.length,
    );

    final freshnessCounts = _freshnessCounts(rows);
    final scopes = <StorageDistributionScope>{
      for (final row in rows) row.scope,
    };
    final spansBothScopes = scopes.length > 1;
    final mergedTotal = spansBothScopes ? chart.totalBytes : null;

    final lastUpdatedAt = rows.isEmpty
        ? null
        : rows
              .map((row) => row.measuredAt)
              .reduce((a, b) => a.isAfter(b) ? a : b);

    final notCurrent = rows.where((row) => !row.isCurrent).length;
    final unmeasured = rows.where((row) => !row.isMeasured).length;
    final unverified = rows.where((row) => row.isUnverified).length;
    final totalIsExact = rows.isNotEmpty && notCurrent == 0 && unmeasured == 0;

    return AccountCenterStorageDistributionReport._(
      chart: chart,
      rows: rows,
      drillDowns: List<StorageDistributionDrillDown>.unmodifiable(
        _drillDowns(allRows: allRows, rows: rows),
      ),
      unavailableDrillDowns: List<StorageDistributionDrillDown>.unmodifiable(
        _drillDowns(
          allRows: allRows,
          rows: rows,
        ).where((entry) => !entry.isAvailable),
      ),
      freshnessCounts: Map<StorageDistributionFreshness, int>.unmodifiable(
        freshnessCounts,
      ),
      textSummary: _summary(
        rows: rows,
        chart: chart,
        hidden: all.length - kept.length,
        total: all.length,
        unknownValues: unknownValues,
        freshnessCounts: freshnessCounts,
        mergedTotal: mergedTotal,
        mergedLabel: spansBothScopes ? combinedLabel : null,
        localFreeBytes: localFreeBytes,
      ),
      unknownFilterValues: List<String>.unmodifiable(unknownValues),
      hiddenRecordCount: all.length - kept.length,
      totalRecordCount: all.length,
      emptyReason: rows.isEmpty
          ? (all.isEmpty
                ? StorageDistributionEmptyReason.noData
                : StorageDistributionEmptyReason.filteredOut)
          : null,
      warnings: _warnings(
        rows: rows,
        spansBothScopes: spansBothScopes,
        notCurrent: notCurrent,
        unmeasured: unmeasured,
        unverified: unverified,
        localFreeBytes: localFreeBytes,
      ),
      totalLabel: rows.isEmpty
          ? 'No data'
          : totalIsExact
          ? 'Reported'
          : 'Approximate',
      totalReason: _totalReason(
        rows: rows,
        notCurrent: notCurrent,
        unmeasured: unmeasured,
      ),
      freshnessLabel: _freshnessLabel(freshnessCounts),
      lastUpdatedAt: lastUpdatedAt,
      mergedBytes: mergedTotal,
      mergedLabel: spansBothScopes ? combinedLabel : null,
      localFreeBytes: localFreeBytes,
    );
  }

  final StorageDistributionChart chart;
  final List<StorageDistributionRow> rows;

  /// One entry per scope/category pair present in the filtered report.
  final List<StorageDistributionDrillDown> drillDowns;

  /// Pairs that exist in the source data but the filter removed.
  final List<StorageDistributionDrillDown> unavailableDrillDowns;

  final Map<StorageDistributionFreshness, int> freshnessCounts;

  /// Always non-blank, including in the empty state.
  final String textSummary;

  /// Filter values that matched nothing in the source data.
  final List<String> unknownFilterValues;

  final int hiddenRecordCount;
  final int totalRecordCount;

  /// `null` when the report is not empty.
  final StorageDistributionEmptyReason? emptyReason;

  /// Non-empty whenever something about this total needs a caveat.
  final List<String> warnings;

  /// `Reported`, `Approximate`, or `No data`.
  final String totalLabel;

  /// Non-null whenever [totalLabel] is not `Reported`.
  final String? totalReason;

  final String freshnessLabel;

  /// The most recent `measured_at` in the report, `null` when empty.
  final DateTime? lastUpdatedAt;

  /// A total that adds local and remote bytes, `null` unless the report spans
  /// both scopes. Publishing it for a single scope would be a lie.
  final int? mergedBytes;

  /// Always accompanies [mergedBytes].
  final String? mergedLabel;

  /// Free space on this device. Shown beside the used total, never inside it.
  final int? localFreeBytes;

  bool get isEmpty => rows.isEmpty;

  bool get filtersAreNarrowing => hiddenRecordCount > 0;

  bool get isRenderable => chart.isRenderable;

  bool get isCurrent => rows.isNotEmpty && rows.every((row) => row.isCurrent);

  /// True only when every record is measured, current, and provider-verified.
  bool get totalIsExact =>
      rows.isNotEmpty &&
      rows.every((row) => row.isMeasured && row.isCurrent && !row.isUnverified);

  int get unrecognizedCategoryCount => chart.slices
      .where((slice) => !slice.category.isCanonical)
      .fold<int>(0, (sum, slice) => sum + slice.unrecognizedLabels.length);

  String? get localFreeLabel => localFreeBytes == null
      ? null
      : '${_formatBytes(localFreeBytes!)} free on this device';

  /// The drill-down for a `'<scope>/<category key>'` target, `null` when the
  /// filter removed it.
  ///
  /// An unavailable entry lives in [unavailableDrillDowns]; a UI that asked for
  /// a slice and got an empty shell back would show a category with no rows.
  StorageDistributionDrillDown? drillDownFor(String targetId) {
    for (final entry in drillDowns) {
      if (entry.targetId == targetId && entry.isAvailable) return entry;
    }
    return null;
  }

  /// The product-spec `ui_states` entry this report represents.
  String get uiState {
    if (isEmpty) return 'EMPTY';
    if (isCurrent && totalIsExact) return 'CONNECTED';
    return 'PARTIAL_DATA';
  }
}

StorageDistributionRow _rowOf(
  StorageDistributionRecord record,
  StorageDistributionFreshness freshness,
) => StorageDistributionRow._(
  scope: record.scope,
  category: record.category,
  bytes: record.bytes,
  measuredAt: record.measuredAt,
  source: record.source,
  freshness: freshness,
  accountId: record.accountId,
  providerId: record.providerId,
  quotaBytes: record.quotaBytes,
  providerReportedUnit: record.providerReportedUnit,
);

int _compareRows(StorageDistributionRow a, StorageDistributionRow b) {
  final byScope = a.scope.index.compareTo(b.scope.index);
  if (byScope != 0) return byScope;
  final byCategory = a.category.key.compareTo(b.category.key);
  if (byCategory != 0) return byCategory;
  final byAccount = (a.accountId ?? '').compareTo(b.accountId ?? '');
  if (byAccount != 0) return byAccount;
  return a.measuredAt.compareTo(b.measuredAt);
}

List<StorageDistributionSlice> _slices(List<StorageDistributionRow> rows) {
  final ordered = <String, _SliceBucket>{};
  for (final row in rows) {
    final id = '${row.scope.wireName}/${row.category.key}';
    ordered.putIfAbsent(id, _SliceBucket.new).add(row);
  }
  // Largest slice first so the chart leads with what matters, canonical
  // categories before the unrecognised bucket, and ties broken by the stable
  // `scope/key` id so two runs of the same data draw the same picture.
  final ids = ordered.keys.toList(growable: false)
    ..sort((a, b) {
      final aBytes = ordered[a]!.bytes;
      final bBytes = ordered[b]!.bytes;
      if (aBytes != bBytes) return bBytes.compareTo(aBytes);
      final aUnknown = a.endsWith('/unrecognized') ? 1 : 0;
      final bUnknown = b.endsWith('/unrecognized') ? 1 : 0;
      if (aUnknown != bUnknown) return aUnknown - bUnknown;
      return a.compareTo(b);
    });
  return <StorageDistributionSlice>[
    for (final id in ids)
      ordered[id]!.toSlice(scopeOf(id), categoryOf(ordered[id]!.rows)),
  ];
}

StorageDistributionScope scopeOf(String sliceId) =>
    sliceId.startsWith('remote/')
    ? StorageDistributionScope.remote
    : StorageDistributionScope.local;

StorageCategoryRef categoryOf(List<StorageDistributionRow> rows) =>
    rows.first.category;

class _SliceBucket {
  int bytes = 0;
  int recordCount = 0;
  final Set<String> labels = <String>{};
  final List<StorageDistributionRow> rows = <StorageDistributionRow>[];

  void add(StorageDistributionRow row) {
    if (row.isMeasured) bytes += row.bytes;
    recordCount += 1;
    if (!row.category.isCanonical) labels.add(row.category.label);
    rows.add(row);
  }

  StorageDistributionSlice toSlice(
    StorageDistributionScope scope,
    StorageCategoryRef category,
  ) => StorageDistributionSlice._(
    scope: scope,
    category: category,
    bytes: bytes,
    recordCount: recordCount,
    unrecognizedLabels: (labels.toList(growable: false)..sort()),
    rows: rows,
  );
}

List<StorageDistributionDrillDown> _drillDowns({
  required List<StorageDistributionRow> allRows,
  required List<StorageDistributionRow> rows,
}) {
  final inScope = <String, List<StorageDistributionRow>>{};
  for (final row in rows) {
    inScope
        .putIfAbsent('${row.scope.wireName}/${row.category.key}', () => [])
        .add(row);
  }
  final sourceIds = <String>{};
  for (final row in allRows) {
    sourceIds.add('${row.scope.wireName}/${row.category.key}');
  }

  return <StorageDistributionDrillDown>[
    for (final id in sourceIds)
      () {
        final bucket = inScope[id];
        if (bucket != null) {
          return StorageDistributionDrillDown._(
            targetId: id,
            label:
                '${bucket.first.category.drillDownLabel} on '
                '${bucket.first.scope.label.toLowerCase()}',
            scope: bucket.first.scope,
            category: bucket.first.category,
            rows: List<StorageDistributionRow>.unmodifiable(bucket),
            recordCount: bucket.length,
            unrecognizedLabels: List<String>.unmodifiable(
              <String>{
                for (final row in bucket)
                  if (!row.category.isCanonical) row.category.label,
              }.toList(growable: false)..sort(),
            ),
            reason: null,
          );
        }
        final hidden = allRows
            .where((row) => '${row.scope.wireName}/${row.category.key}' == id)
            .toList(growable: false);
        final first = hidden.first;
        return StorageDistributionDrillDown._(
          targetId: id,
          label:
              '${first.category.drillDownLabel} on '
              '${first.scope.label.toLowerCase()}',
          scope: first.scope,
          category: first.category,
          rows: const <StorageDistributionRow>[],
          recordCount: 0,
          unrecognizedLabels: const <String>[],
          reason:
              'Excluded by the current filter '
              '(${hidden.length} record(s) hidden).',
        );
      }(),
  ];
}

Map<StorageDistributionFreshness, int> _freshnessCounts(
  List<StorageDistributionRow> rows,
) {
  final counts = <StorageDistributionFreshness, int>{};
  for (final row in rows) {
    counts.update(row.freshness, (value) => value + 1, ifAbsent: () => 1);
  }
  return counts;
}

String _freshnessLabel(Map<StorageDistributionFreshness, int> counts) {
  if (counts.isEmpty) return 'No storage records';
  final parts = <String>[
    for (final entry in counts.entries)
      '${entry.value} ${_humanize(entry.key.name)}',
  ]..sort();
  return 'Freshness: ${parts.join(', ')}';
}

String _humanize(String value) => value.replaceAllMapped(
  RegExp('[A-Z]'),
  (match) => ' ${match[0]!.toLowerCase()}',
);

String _summary({
  required List<StorageDistributionRow> rows,
  required StorageDistributionChart chart,
  required int hidden,
  required int total,
  required List<String> unknownValues,
  required Map<StorageDistributionFreshness, int> freshnessCounts,
  required int? mergedTotal,
  required String? mergedLabel,
  required int? localFreeBytes,
}) {
  if (rows.isEmpty) {
    final buffer = StringBuffer('No storage distribution to show.');
    if (hidden > 0) {
      buffer.write(' $hidden of $total record(s) were excluded by the filter.');
    } else {
      buffer.write(' No storage records have been reported yet.');
    }
    if (unknownValues.isNotEmpty) {
      buffer.write(' Unknown filter value(s): ${unknownValues.join(', ')}.');
    }
    if (localFreeBytes != null) {
      buffer.write(' Free device space: ${_formatBytes(localFreeBytes)}.');
    }
    return buffer.toString();
  }

  final label = mergedLabel ?? rows.first.scope.label;
  final buffer = StringBuffer(
    'Storage distribution: ${rows.length} record(s), '
    '${_formatBytes(chart.totalBytes)} in total'
    '${mergedTotal == null ? '' : ' (${mergedLabel!.toLowerCase()})'}.',
  );
  buffer.write(
    ' $label chart has ${chart.slices.length} categor'
    '${chart.slices.length == 1 ? 'y' : 'ies'}.',
  );
  if (hidden > 0) {
    buffer.write(' Filter hid $hidden of $total record(s).');
  }
  if (unknownValues.isNotEmpty) {
    buffer.write(' Unknown filter value(s): ${unknownValues.join(', ')}.');
  }
  final unrecognized = chart.slices
      .where((slice) => !slice.category.isCanonical)
      .fold<int>(0, (sum, slice) => sum + slice.unrecognizedLabels.length);
  if (unrecognized > 0) {
    buffer.write(
      ' $unrecognized unrecognised categor'
      '${unrecognized == 1 ? 'y is' : 'ies are'} not classified by this build.',
    );
  }
  if (localFreeBytes != null) {
    buffer.write(' Free device space: ${_formatBytes(localFreeBytes)}.');
  }
  buffer.write(' ${_freshnessLabel(freshnessCounts)}.');
  return buffer.toString();
}

List<String> _warnings({
  required List<StorageDistributionRow> rows,
  required bool spansBothScopes,
  required int notCurrent,
  required int unmeasured,
  required int unverified,
  required int? localFreeBytes,
}) {
  final warnings = <String>[];
  if (spansBothScopes) {
    warnings.add(AccountCenterStorageDistributionReport.mergedTotalWarning);
  }
  if (localFreeBytes != null) {
    warnings.add(AccountCenterStorageDistributionReport.freeSpaceWarning);
  }
  if (notCurrent > 0) {
    warnings.add(
      '$notCurrent of ${rows.length} record(s) are not current; the total is '
      'approximate.',
    );
  }
  if (unmeasured > 0) {
    warnings.add(
      '$unmeasured record(s) report Size unavailable; their bytes are not '
      'counted in the total.',
    );
  }
  if (unverified > 0) {
    warnings.add(
      '$unverified record(s) are user-declared or unavailable; the total is '
      'approximate.',
    );
  }
  if (rows.any((row) => row.providerUnitNote != null)) {
    warnings.add(
      'A provider reported a unit other than the display unit; the note is '
      'shown on the row.',
    );
  }
  return List<String>.unmodifiable(warnings);
}

String? _totalReason({
  required List<StorageDistributionRow> rows,
  required int notCurrent,
  required int unmeasured,
}) {
  if (rows.isEmpty) return 'No storage records in scope.';
  final reasons = <String>[
    if (notCurrent > 0) '$notCurrent record(s) are not current',
    if (unmeasured > 0) '$unmeasured record(s) have no measured size',
  ];
  if (reasons.isEmpty) return null;
  return '${reasons.join('; ')}.';
}

const int _kilobyte = 1000;
const int _megabyte = 1000 * _kilobyte;
const int _gigabyte = 1000 * _megabyte;
const int _terabyte = 1000 * _gigabyte;

/// Formats a byte count in decimal units, per the product-spec display rule.
///
/// Decimal, not binary: the spec asks for GB/TB by default, and a binary unit
/// shown under a `GB` label is a rounding lie the user cannot see.
String _formatBytes(int bytes) {
  if (bytes < 0) return 'unavailable';
  if (bytes < _kilobyte) return '$bytes B';
  if (bytes < _megabyte) return '${_trim(bytes / _kilobyte)} KB';
  if (bytes < _gigabyte) return '${_trim(bytes / _megabyte)} MB';
  if (bytes < _terabyte) return '${_trim(bytes / _gigabyte)} GB';
  return '${_trim(bytes / _terabyte)} TB';
}

String _trim(double value) {
  var text = value.toStringAsFixed(2);
  text = text.replaceFirst(RegExp(r'0+$'), '');
  text = text.replaceFirst(RegExp(r'\.$'), '');
  return text;
}
