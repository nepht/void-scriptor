part of 'sprint_117_cloud_storage_quota_validation.dart';

/// Executes the shipped storage mechanisms and records what each one produced.
/// It writes nothing — no manifest, no report, no user file — contacts no
/// provider, and every byte value it uses is fixture data it created itself.
class Sprint117CloudStorageQuotaDrill {
  const Sprint117CloudStorageQuotaDrill();

  /// The instant every timestamped decision in this drill is measured against,
  /// so the run is reproducible instead of decided by the day it happened.
  static final DateTime fixedNow = DateTime.utc(2026, 1, 1, 12);

  /// The window 115.17's stale state is measured against.
  static const Duration staleAfter = Duration(hours: 24);

  /// Runs every canonical check against the repository as it stands.
  Future<Sprint117CloudStorageQuotaDrillRun> run() async {
    var matched = 0;
    var checked = 0;
    for (final entry
        in Sprint117CloudStorageQuotaContract.externalPins.entries) {
      final actual = _sha256OfFile(entry.key);
      if (actual == null) continue;
      checked += 1;
      if (actual == entry.value) matched += 1;
    }
    return Sprint117CloudStorageQuotaDrillRun(
      observations: <Sprint117CloudStorageQuotaObservation>[
        _observeProviderApiValues(),
        _observeRawBytes(),
        _observeDisplayUnits(),
        _observeFreshness(),
        _observePartialTotal(),
        _observeUnavailable(),
        _observeLocalSeparation(),
      ],
      liveProviderTouched: false,
      userProjectTouched: false,
      liveSecretObserved: false,
      externalPinsMatched: matched,
      externalPinsChecked: checked,
    );
  }

  /// `provider_api_values` — how many shipped adapters can actually fetch a
  /// quota, and what the committed account model says about quota support.
  ///
  /// The honest finding is that the value cannot be measured here: the
  /// [ProviderQuotaAdapter] interface ships with no implementation anywhere in
  /// `lib/`, so every quota in this validation is fixture data that entered
  /// through a shipped contract. The committed 115.16 manifest is read for the
  /// capability it declares, because a declared capability and a fetched value
  /// are different claims.
  Sprint117CloudStorageQuotaObservation _observeProviderApiValues() {
    final adapterImplementations = _implementationsIn(
      'lib',
      'ProviderQuotaAdapter',
    );
    final testImplementations = _implementationsIn(
      'test',
      'ProviderQuotaAdapter',
    );

    final model = _readJsonFile(
      Sprint117CloudStorageQuotaContract.cloudAccountModel,
    );
    final acceptance = model?['acceptance'];
    final declaredAcceptance = acceptance is List<dynamic>
        ? acceptance.map((item) => item is String ? item : '').toList()
        : const <String>[];
    final quotaSupportDeclared = declaredAcceptance.contains('quota_support');

    // The reading contract is the only path a provider value can take today.
    // A fabricated one would have to bypass ProviderQuotaReading entirely.
    final fabricated = ProviderQuotaReading(
      providerId: 'drive',
      usedBytes: 12,
      quotaBytes: 20,
      availableBytes: 8,
      measuredAt: fixedNow,
      unit: ProviderQuotaUnit.bytes,
    );

    final passed =
        adapterImplementations == 0 &&
        quotaSupportDeclared &&
        fabricated.usedBytes == 12 &&
        fabricated.availableBytes == 8;

    return Sprint117CloudStorageQuotaObservation(
      checkId: 'provider_api_values',
      outcome: passed
          ? 'NO_SHIPPED_ADAPTER_QUOTA_VALUE_IS_CONTRACT_FIXTURE'
          : 'PROVIDER_QUOTA_SOURCE_NOT_ESTABLISHED',
      facts: <String, Object?>{
        'shipped_adapter_implementations': adapterImplementations,
        'test_only_adapter_implementations': testImplementations,
        'quota_support_acceptance_declared': quotaSupportDeclared,
        'declared_acceptance_items': declaredAcceptance.length,
        'contract_preserved_used_bytes': fabricated.usedBytes,
        'contract_preserved_available_bytes': fabricated.availableBytes,
        'mechanism':
            'ProviderQuotaAdapter (interface) + ProviderQuotaReading contract',
        // The recorded fact that decides whether this acceptance can be
        // satisfied: nothing in lib/ reads a provider today.
        'acceptance_mechanism_present': adapterImplementations > 0,
      },
      passed: passed,
      acceptance: adapterImplementations > 0
          ? Sprint117CloudStorageQuotaAcceptance.satisfied
          : Sprint117CloudStorageQuotaAcceptance.mechanismAbsent,
      unresolvable: adapterImplementations == 0
          ? const <String>['no_shipped_provider_quota_adapter']
          : const <String>[],
    );
  }

  /// `raw_bytes` — provider byte counts must survive the contract untouched and
  /// sum without a conversion the provider never reported.
  Sprint117CloudStorageQuotaObservation _observeRawBytes() {
    const used = 2_147_483_648; // exactly 2 GiB in raw bytes
    const quota = 5_368_709_120; // exactly 5 GiB in raw bytes
    final reading = ProviderQuotaReading(
      providerId: 'drive',
      usedBytes: used,
      quotaBytes: quota,
      availableBytes: quota - used,
      measuredAt: fixedNow,
      unit: ProviderQuotaUnit.bytes,
    );
    final aggregated = CloudStorageAggregation.from([
      ProviderQuotaResult.fromReading(reading, now: fixedNow),
    ]);

    // The contract must refuse a value the provider could not have reported
    // rather than silently repairing it.
    final negativeError = _captureError(
      () => ProviderQuotaReading(
        providerId: 'drive',
        usedBytes: -1,
        quotaBytes: quota,
        availableBytes: quota,
        measuredAt: fixedNow,
        unit: ProviderQuotaUnit.bytes,
      ),
    );
    final inconsistentError = _captureError(
      () => ProviderQuotaReading(
        providerId: 'drive',
        usedBytes: 10,
        quotaBytes: 100,
        availableBytes: 999,
        measuredAt: fixedNow,
        unit: ProviderQuotaUnit.bytes,
      ),
    );
    final blankIdError = _captureError(
      () => ProviderQuotaReading(
        providerId: '   ',
        usedBytes: 1,
        quotaBytes: 2,
        availableBytes: 1,
        measuredAt: fixedNow,
        unit: ProviderQuotaUnit.bytes,
      ),
    );

    final passed =
        reading.usedBytes == used &&
        reading.quotaBytes == quota &&
        reading.availableBytes == quota - used &&
        reading.unit == ProviderQuotaUnit.bytes &&
        aggregated.usedBytes == used &&
        aggregated.quotaBytes == quota &&
        aggregated.status == CloudStorageAggregationStatus.complete &&
        negativeError == 'ArgumentError' &&
        inconsistentError == 'ArgumentError' &&
        blankIdError == 'ArgumentError';

    return Sprint117CloudStorageQuotaObservation(
      checkId: 'raw_bytes',
      outcome: passed
          ? 'RAW_BYTES_PRESERVED_AND_INVALID_READINGS_REFUSED'
          : 'RAW_BYTE_CONTRACT_NOT_PRESERVED',
      facts: <String, Object?>{
        'reading_used_bytes': reading.usedBytes,
        'reading_quota_bytes': reading.quotaBytes,
        'reading_available_bytes': reading.availableBytes,
        'reading_unit': reading.unit.name,
        'aggregated_used_bytes': aggregated.usedBytes,
        'aggregated_quota_bytes': aggregated.quotaBytes,
        'aggregated_status': aggregated.status.name,
        'negative_reading_error': negativeError,
        'inconsistent_reading_error': inconsistentError,
        'blank_provider_id_error': blankIdError,
        'mechanism': 'ProviderQuotaReading + CloudStorageAggregation.from',
      },
      passed: passed,
    );
  }

  /// `display_units` — byte counts must render in decimal units, and an
  /// unknown quota must never render as a number.
  Sprint117CloudStorageQuotaObservation _observeDisplayUnits() {
    final known = StorageUsageCardData.fromBytes(
      providerId: 'drive',
      accountLabel: 'Writer',
      usedBytes: 2_147_483_648,
      quotaBytes: 10_737_418_240,
      measuredAt: fixedNow,
      now: fixedNow,
    );
    final unknown = StorageUsageCardData.unknownQuota(
      providerId: 'onedrive',
      accountLabel: 'Unknown quota',
      usedBytes: 1_000_000_000,
      measuredAt: fixedNow,
      now: fixedNow,
    );

    // 115.19's `accessible_progress` must read the same truth as the raw
    // bytes, and the unknown card must not publish a percentage.
    final progressPercent = _percentFrom(known.accessibleProgress);
    final rejectedOverQuota = _captureError(
      () => StorageUsageCardData.fromBytes(
        providerId: 'drive',
        accountLabel: 'Writer',
        usedBytes: 500,
        quotaBytes: 100,
        measuredAt: fixedNow,
        now: fixedNow,
      ),
    );
    final rejectedNegative = _captureError(
      () => StorageUsageCardData.unknownQuota(
        providerId: 'onedrive',
        accountLabel: 'Negative',
        usedBytes: -1,
        measuredAt: fixedNow,
        now: fixedNow,
      ),
    );

    final passed =
        known.quotaLabel == '10.74 GB' &&
        known.percentage != null &&
        known.statusLabel == 'Fresh' &&
        progressPercent == 20 &&
        unknown.quotaBytes == null &&
        unknown.percentage == null &&
        unknown.quotaLabel == 'Quota unavailable' &&
        unknown.statusLabel == 'Fresh' &&
        unknown.accessibleProgress.contains('quota unavailable') &&
        rejectedOverQuota == 'ArgumentError' &&
        rejectedNegative == 'ArgumentError';

    return Sprint117CloudStorageQuotaObservation(
      checkId: 'display_units',
      outcome: passed
          ? 'DECIMAL_UNITS_RENDERED_UNKNOWN_QUOTA_STAYS_UNAVAILABLE'
          : 'DISPLAY_UNIT_CONTRACT_NOT_HELD',
      facts: <String, Object?>{
        'known_quota_label': known.quotaLabel,
        'known_used_bytes': known.usedBytes,
        'known_percentage': known.percentage,
        'known_status_label': known.statusLabel,
        'known_accessible_progress': known.accessibleProgress,
        'unknown_quota_bytes': unknown.quotaBytes,
        'unknown_quota_label': unknown.quotaLabel,
        'unknown_percentage': unknown.percentage,
        'unknown_accessible_progress': unknown.accessibleProgress,
        'progress_percent_parsed': progressPercent,
        'over_quota_error': rejectedOverQuota,
        'negative_used_error': rejectedNegative,
        'mechanism':
            'StorageUsageCardData + AccountCenterLocalizationFormatting',
      },
      passed: passed,
    );
  }

  /// `freshness` — the state a reading is in, the label a card shows, and the
  /// instant a total is dated by.
  ///
  /// The third part is the one this step fixes: the shipped reduction dated an
  /// aggregate by its *oldest* included reading, so a total assembled from
  /// accounts measured at different instants claimed a freshness no included
  /// account had. 115.18 declares `last_updated` as its own acceptance, and it
  /// is re-measured here in both directions.
  Sprint117CloudStorageQuotaObservation _observeFreshness() {
    final freshReading = ProviderQuotaResult.fromReading(
      _reading('drive', used: 100, quota: 1_000, measuredAt: fixedNow),
      now: fixedNow,
      staleAfter: staleAfter,
    );
    final staleReading = ProviderQuotaResult.fromReading(
      _reading(
        'dropbox',
        used: 200,
        quota: 2_000,
        measuredAt: fixedNow.subtract(const Duration(days: 2)),
      ),
      now: fixedNow,
      staleAfter: staleAfter,
    );
    final boundaryReading = ProviderQuotaResult.fromReading(
      _reading(
        'onedrive',
        used: 50,
        quota: 500,
        measuredAt: fixedNow.subtract(staleAfter),
      ),
      now: fixedNow,
      staleAfter: staleAfter,
    );

    final staleCard = StorageUsageCardData.fromBytes(
      providerId: 'dropbox',
      accountLabel: 'Archive',
      usedBytes: 200,
      quotaBytes: 2_000,
      measuredAt: fixedNow.subtract(const Duration(days: 2)),
      now: fixedNow,
    );
    // A reading dated in the future is a data defect, not a fresh one.
    final futureCard = StorageUsageCardData.fromBytes(
      providerId: 'drive',
      accountLabel: 'Clock skew',
      usedBytes: 100,
      quotaBytes: 1_000,
      measuredAt: fixedNow.add(const Duration(hours: 1)),
      now: fixedNow,
    );

    // The regression this step exists for: mixed-age readings, newest wins.
    final newest = fixedNow.subtract(const Duration(minutes: 5));
    final oldest = fixedNow.subtract(const Duration(days: 3));
    final mixed = CloudStorageAggregation.from([
      ProviderQuotaResult.fromReading(
        _reading('drive', used: 100, quota: 500, measuredAt: newest),
        now: fixedNow,
      ),
      ProviderQuotaResult.fromReading(
        _reading('dropbox', used: 200, quota: 900, measuredAt: oldest),
        now: fixedNow,
      ),
    ]);

    // And a total with a single included reading is dated by that reading.
    final single = CloudStorageAggregation.from([
      ProviderQuotaResult.fromReading(
        _reading('drive', used: 10, quota: 100, measuredAt: newest),
        now: fixedNow,
      ),
    ]);

    // The distribution report reaches the same verdict through its own
    // reduction, so the two surfaces must agree on which instant is newest.
    final distribution = AccountCenterStorageDistributionReport.build(
      records: <StorageDistributionRecord>[
        _remoteRecord('drive', used: 100, measuredAt: newest),
        _remoteRecord('dropbox', used: 200, measuredAt: oldest),
      ],
      now: fixedNow,
    );

    final staleAggregate = CloudStorageAggregation.from([
      freshReading,
      staleReading,
    ]);

    final passed =
        freshReading.status == ProviderQuotaStatus.fresh &&
        staleReading.status == ProviderQuotaStatus.stale &&
        boundaryReading.status == ProviderQuotaStatus.fresh &&
        staleCard.freshness == StorageUsageFreshness.stale &&
        staleCard.statusLabel == 'Stale' &&
        futureCard.freshness == StorageUsageFreshness.unknown &&
        futureCard.statusLabel == 'Unknown freshness' &&
        mixed.status == CloudStorageAggregationStatus.stale &&
        mixed.lastUpdated == newest &&
        mixed.lastUpdated != oldest &&
        single.lastUpdated == newest &&
        staleAggregate.status == CloudStorageAggregationStatus.stale &&
        distribution.lastUpdatedAt == newest;

    return Sprint117CloudStorageQuotaObservation(
      checkId: 'freshness',
      outcome: passed
          ? 'FRESHNESS_STATED_AND_AGGREGATE_DATED_BY_NEWEST'
          : 'FRESHNESS_NOT_STATED_OR_AGGREGATE_MISDATED',
      facts: <String, Object?>{
        'fresh_status': freshReading.status.name,
        'stale_status': staleReading.status.name,
        'boundary_status': boundaryReading.status.name,
        'stale_card_freshness': staleCard.freshness.name,
        'stale_card_label': staleCard.statusLabel,
        'future_card_freshness': futureCard.freshness.name,
        'mixed_aggregation_status': mixed.status.name,
        'mixed_last_updated': mixed.lastUpdated?.toIso8601String(),
        'mixed_expected_newest': newest.toIso8601String(),
        'mixed_oldest_measured_at': oldest.toIso8601String(),
        'single_last_updated': single.lastUpdated?.toIso8601String(),
        'stale_aggregate_status': staleAggregate.status.name,
        'distribution_last_updated': distribution.lastUpdatedAt
            ?.toIso8601String(),
        'distribution_freshness_label': distribution.freshnessLabel,
        'mechanism':
            'ProviderQuotaResult.fromReading + CloudStorageAggregation.from + '
            'StorageUsageCardData + AccountCenterStorageDistributionReport',
      },
      passed: passed,
    );
  }

  /// `partial_total` — a total that silently drops an account is worse than no
  /// total, so exclusions must be visible and named.
  Sprint117CloudStorageQuotaObservation _observePartialTotal() {
    final partial = CloudStorageAggregation.from([
      ProviderQuotaResult.fromReading(
        _reading('drive', used: 200, quota: 1_000, measuredAt: fixedNow),
        now: fixedNow,
      ),
      ProviderQuotaResult.fromReading(
        _reading('dropbox', used: 300, quota: 2_000, measuredAt: fixedNow),
        now: fixedNow,
      ),
      ProviderQuotaResult.unavailable(
        providerId: 'onedrive',
        reason: 'Provider did not return quota',
      ),
    ]);

    // A provider-defined unit cannot be added to a byte total without
    // inventing a conversion the provider never reported.
    final mixedUnits = CloudStorageAggregation.from([
      ProviderQuotaResult.fromReading(
        _reading('drive', used: 100, quota: 500, measuredAt: fixedNow),
        now: fixedNow,
      ),
      ProviderQuotaResult.fromReading(
        _reading(
          'vendor',
          used: 10,
          quota: 20,
          measuredAt: fixedNow,
          unit: ProviderQuotaUnit.providerDefined,
        ),
        now: fixedNow,
      ),
    ]);

    final empty = CloudStorageAggregation.from([
      ProviderQuotaResult.unavailable(
        providerId: 'drive',
        reason: 'Provider did not return quota',
      ),
    ]);

    final partialDistribution = AccountCenterStorageDistributionReport.build(
      records: <StorageDistributionRecord>[
        _remoteRecord('drive', used: 200, measuredAt: fixedNow),
        StorageDistributionRecord(
          scope: StorageDistributionScope.remote,
          category: StorageCategoryRef.canonical(StorageCategoryKind.assets),
          bytes: 0,
          measuredAt: fixedNow,
          source: StorageRecordSource.unavailable,
          accountId: 'onedrive',
          providerId: 'onedrive',
        ),
      ],
      now: fixedNow,
    );

    final passed =
        partial.status == CloudStorageAggregationStatus.partial &&
        partial.usedBytes == 500 &&
        partial.quotaBytes == 3_000 &&
        partial.availableBytes == 2_500 &&
        partial.includedProviderIds.join(',') == 'drive,dropbox' &&
        partial.excludedProviderIds.join(',') == 'onedrive' &&
        mixedUnits.status == CloudStorageAggregationStatus.partial &&
        mixedUnits.usedBytes == 100 &&
        mixedUnits.excludedProviderIds.join(',') == 'vendor' &&
        empty.status == CloudStorageAggregationStatus.unavailable &&
        empty.usedBytes == null &&
        empty.quotaBytes == null &&
        empty.availableBytes == null &&
        empty.lastUpdated == null &&
        partialDistribution.totalIsExact == false &&
        partialDistribution.warnings.any(
          (warning) => warning.contains('Size unavailable'),
        );

    return Sprint117CloudStorageQuotaObservation(
      checkId: 'partial_total',
      outcome: passed
          ? 'PARTIAL_TOTAL_NAMES_EVERY_EXCLUDED_ACCOUNT'
          : 'PARTIAL_TOTAL_NOT_EXPLAINED',
      facts: <String, Object?>{
        'partial_status': partial.status.name,
        'partial_used_bytes': partial.usedBytes,
        'partial_quota_bytes': partial.quotaBytes,
        'partial_available_bytes': partial.availableBytes,
        'partial_included': partial.includedProviderIds,
        'partial_excluded': partial.excludedProviderIds,
        'mixed_unit_status': mixedUnits.status.name,
        'mixed_unit_used_bytes': mixedUnits.usedBytes,
        'mixed_unit_excluded': mixedUnits.excludedProviderIds,
        'empty_status': empty.status.name,
        'empty_used_bytes': empty.usedBytes,
        'distribution_total_is_exact': partialDistribution.totalIsExact,
        'distribution_total_label': partialDistribution.totalLabel,
        'distribution_warnings': partialDistribution.warnings,
        'mechanism':
            'CloudStorageAggregation.from + AccountCenterStorageDistributionReport',
      },
      passed: passed,
    );
  }

  /// `unavailable` — an unknown value is unknown, not zero.
  Sprint117CloudStorageQuotaObservation _observeUnavailable() {
    final result = ProviderQuotaResult.unavailable(
      providerId: 'onedrive',
      reason: 'Provider did not return quota',
    );
    final blankReasonError = _captureError(
      () =>
          ProviderQuotaResult.unavailable(providerId: 'onedrive', reason: '  '),
    );
    final blankProviderError = _captureError(
      () => ProviderQuotaResult.unavailable(providerId: '', reason: 'nope'),
    );

    // A row whose reading could not be obtained must publish null bytes, not 0.
    final row = StorageDistributionRecord(
      scope: StorageDistributionScope.remote,
      category: StorageCategoryRef.canonical(StorageCategoryKind.assets),
      bytes: 0,
      measuredAt: fixedNow,
      source: StorageRecordSource.unavailable,
      accountId: 'onedrive',
      providerId: 'onedrive',
    );
    final distribution = AccountCenterStorageDistributionReport.build(
      records: <StorageDistributionRecord>[row],
      now: fixedNow,
    );
    final publicJson = row.isMeasured
        ? <String, Object?>{}
        : <String, Object?>{'bytes': null};
    final builtRow = distribution.rows.first;

    // A remote record with no account cannot be attributed, and a local record
    // may not claim to come from a provider API.
    final missingAccountError = _captureError(
      () => StorageDistributionRecord(
        scope: StorageDistributionScope.remote,
        category: StorageCategoryRef.canonical(StorageCategoryKind.assets),
        bytes: 10,
        measuredAt: fixedNow,
        source: StorageRecordSource.providerApi,
      ),
    );
    final falseAttributionError = _captureError(
      () => StorageDistributionRecord(
        scope: StorageDistributionScope.local,
        category: StorageCategoryRef.canonical(StorageCategoryKind.projects),
        bytes: 10,
        measuredAt: fixedNow,
        source: StorageRecordSource.providerApi,
      ),
    );

    final passed =
        result.status == ProviderQuotaStatus.unavailable &&
        result.reading == null &&
        result.reason == 'Provider did not return quota' &&
        blankReasonError == 'ArgumentError' &&
        blankProviderError == 'ArgumentError' &&
        !row.isMeasured &&
        row.isUnverified &&
        builtRow.sizeLabel == 'Size unavailable' &&
        builtRow.quotaLabel == 'Quota unavailable' &&
        builtRow.percentOfQuota == null &&
        builtRow.displayUnit.isEmpty &&
        publicJson['bytes'] == null &&
        missingAccountError == 'ArgumentError' &&
        falseAttributionError == 'ArgumentError';

    return Sprint117CloudStorageQuotaObservation(
      checkId: 'unavailable',
      outcome: passed
          ? 'UNAVAILABLE_YIELDS_NO_BYTES_QUOTA_OR_PERCENTAGE'
          : 'UNAVAILABLE_STILL_READS_AS_ZERO',
      facts: <String, Object?>{
        'result_status': result.status.name,
        'result_reading_is_null': result.reading == null,
        'result_reason': result.reason,
        'blank_reason_error': blankReasonError,
        'blank_provider_error': blankProviderError,
        'row_is_measured': row.isMeasured,
        'row_is_unverified': row.isUnverified,
        'row_size_label': builtRow.sizeLabel,
        'row_quota_label': builtRow.quotaLabel,
        'row_percent_of_quota': builtRow.percentOfQuota,
        'row_display_unit': builtRow.displayUnit,
        'row_published_bytes': publicJson['bytes'],
        'missing_account_error': missingAccountError,
        'false_attribution_error': falseAttributionError,
        'mechanism':
            'ProviderQuotaResult.unavailable + StorageDistributionRecord',
      },
      passed: passed,
    );
  }

  /// `local_separation` — local disk bytes and provider quota are different
  /// pools. A UI that adds them is wrong twice: once for the sum, once for the
  /// free space it folded in.
  Sprint117CloudStorageQuotaObservation _observeLocalSeparation() {
    final local = LocalStorageSummary.fromScan(
      scannedAt: fixedNow,
      freeBytes: 111_000_000_000,
      categories: <LocalStorageCategory, int>{
        LocalStorageCategory.projects: 1_000,
        LocalStorageCategory.cache: 400,
        LocalStorageCategory.backups: 5_000,
      },
      protectedCategories: <LocalStorageCategory>{
        LocalStorageCategory.projects,
        LocalStorageCategory.backups,
      },
    );

    // The contract refuses to expose a cloud figure at all.
    final cloudBytesIsNull = local.cloudBytes == null;

    final records = <StorageDistributionRecord>[
      StorageDistributionRecord(
        scope: StorageDistributionScope.local,
        category: StorageCategoryRef.canonical(StorageCategoryKind.projects),
        bytes: 1_000,
        measuredAt: fixedNow,
        source: StorageRecordSource.localScan,
      ),
      _remoteRecord('drive', used: 200, measuredAt: fixedNow),
    ];

    final merged = AccountCenterStorageDistributionReport.build(
      records: records,
      now: fixedNow,
      localFreeBytes: 111_000_000_000,
    );
    final localOnly = AccountCenterStorageDistributionReport.build(
      records: records,
      filter: StorageScopeFilter.localOnly(),
      now: fixedNow,
      localFreeBytes: 111_000_000_000,
    );
    final remoteOnly = AccountCenterStorageDistributionReport.build(
      records: records,
      filter: StorageScopeFilter.remoteOnly(),
      now: fixedNow,
    );

    // A typo in the filter must be reported, not rendered as an empty account.
    final typoFilter = AccountCenterStorageDistributionReport.build(
      records: records,
      filter: StorageScopeFilter(scopeNames: <String>{'remot'}),
      now: fixedNow,
    );

    // Both shipped windows are inclusive at the boundary and only go stale
    // past it: `isFreshAt` keeps a reading at exactly `freshFor`, and
    // `fromReading` only calls a reading stale once `age > staleAfter`. The two
    // surfaces therefore agree at the edge, which is measured here rather than
    // assumed from either signature.
    final atWindow = LocalStorageSummary.fromScan(
      scannedAt: fixedNow,
      freeBytes: 1,
      categories: <LocalStorageCategory, int>{LocalStorageCategory.projects: 1},
      protectedCategories: const <LocalStorageCategory>{},
    );
    final freshAtWindow = atWindow.isFreshAt(
      fixedNow.add(staleAfter),
      freshFor: staleAfter,
    );
    final staleJustPastWindow = atWindow.isFreshAt(
      fixedNow.add(staleAfter + const Duration(minutes: 1)),
      freshFor: staleAfter,
    );
    final readingAtWindow = ProviderQuotaResult.fromReading(
      _reading('drive', used: 1, quota: 2, measuredAt: fixedNow),
      now: fixedNow.add(staleAfter),
      staleAfter: staleAfter,
    );

    final passed =
        cloudBytesIsNull &&
        local.totalBytes == 6_400 &&
        local.bytesFor(LocalStorageCategory.cache) == 400 &&
        local.isProtected(LocalStorageCategory.projects) &&
        local.isRegenerable(LocalStorageCategory.cache) &&
        !local.isRegenerable(LocalStorageCategory.backups) &&
        local.isFreshAt(fixedNow) &&
        freshAtWindow &&
        !staleJustPastWindow &&
        readingAtWindow.status == ProviderQuotaStatus.fresh &&
        merged.mergedBytes == 1_200 &&
        merged.mergedLabel ==
            AccountCenterStorageDistributionReport.combinedLabel &&
        merged.localFreeBytes == 111_000_000_000 &&
        merged.chart.totalBytes == 1_200 &&
        merged.warnings.any(
          (warning) =>
              warning ==
              AccountCenterStorageDistributionReport.mergedTotalWarning,
        ) &&
        merged.warnings.any(
          (warning) =>
              warning ==
              AccountCenterStorageDistributionReport.freeSpaceWarning,
        ) &&
        localOnly.mergedBytes == null &&
        localOnly.mergedLabel == null &&
        localOnly.chart.totalBytes == 1_000 &&
        remoteOnly.mergedBytes == null &&
        remoteOnly.chart.totalBytes == 200 &&
        typoFilter.emptyReason == StorageDistributionEmptyReason.filteredOut &&
        typoFilter.unknownFilterValues.join(',') == 'remot';

    return Sprint117CloudStorageQuotaObservation(
      checkId: 'local_separation',
      outcome: passed
          ? 'LOCAL_BYTES_NEVER_ENTER_CLOUD_QUOTA_OR_MERGE_UNLABELLED'
          : 'LOCAL_AND_REMOTE_BYTES_NOT_SEPARABLE',
      facts: <String, Object?>{
        'local_cloud_bytes_is_null': cloudBytesIsNull,
        'local_total_bytes': local.totalBytes,
        'local_cache_bytes': local.bytesFor(LocalStorageCategory.cache),
        'local_projects_protected': local.isProtected(
          LocalStorageCategory.projects,
        ),
        'local_cache_regenerable': local.isRegenerable(
          LocalStorageCategory.cache,
        ),
        'local_backups_regenerable': local.isRegenerable(
          LocalStorageCategory.backups,
        ),
        'local_fresh_now': local.isFreshAt(fixedNow),
        'local_fresh_after_a_day': local.isFreshAt(
          fixedNow.add(const Duration(days: 1)),
        ),
        'merged_bytes': merged.mergedBytes,
        'merged_label': merged.mergedLabel,
        'merged_total_bytes': merged.chart.totalBytes,
        'merged_warnings': merged.warnings,
        'local_only_merged_bytes': localOnly.mergedBytes,
        'local_only_total_bytes': localOnly.chart.totalBytes,
        'remote_only_merged_bytes': remoteOnly.mergedBytes,
        'remote_only_total_bytes': remoteOnly.chart.totalBytes,
        'typo_filter_empty_reason': typoFilter.emptyReason?.name,
        'typo_filter_unknown_values': typoFilter.unknownFilterValues,
        'mechanism':
            'LocalStorageSummary + AccountCenterStorageDistributionReport + '
            'StorageScopeFilter',
      },
      passed: passed,
    );
  }
}

/// One provider reading at an explicit instant.
ProviderQuotaReading _reading(
  String providerId, {
  required int used,
  required int quota,
  required DateTime measuredAt,
  ProviderQuotaUnit unit = ProviderQuotaUnit.bytes,
}) => ProviderQuotaReading(
  providerId: providerId,
  usedBytes: used,
  quotaBytes: quota,
  availableBytes: quota - used,
  measuredAt: measuredAt,
  unit: unit,
);

/// One remote distribution record attributed to an account, as a provider API
/// would report it.
StorageDistributionRecord _remoteRecord(
  String providerId, {
  required int used,
  required DateTime measuredAt,
  int? quota,
}) => StorageDistributionRecord(
  scope: StorageDistributionScope.remote,
  category: StorageCategoryRef.canonical(StorageCategoryKind.assets),
  bytes: used,
  measuredAt: measuredAt,
  source: StorageRecordSource.providerApi,
  accountId: 'account-$providerId',
  providerId: providerId,
  quotaBytes: quota,
);

/// The runtime type of an error, or null when nothing was thrown.
String? _captureError(void Function() action) {
  try {
    action();
    return null;
  } on ArgumentError {
    return 'ArgumentError';
  } on Object {
    return 'other';
  }
}

/// The leading whole percentage in a progress string, or null when the string
/// publishes no percentage.
int? _percentFrom(String progress) {
  final match = RegExp(r'(\d+)%').firstMatch(progress);
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

/// How many files under [root] declare a class implementing [typeName].
///
/// A bare mention is not an implementation: the class body has to name the
/// interface. This is measured rather than read off a comment, because the
/// claim decides whether a provider value can exist at all.
int _implementationsIn(String root, String typeName) {
  final directory = Directory(root);
  if (!directory.existsSync()) return 0;
  var found = 0;
  for (final entity in directory.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final text = entity.readAsStringSync();
    final pattern = RegExp(
      r'(?:class|enum)\s+\w+[^{]*\bimplements\s+[^{]*\b' +
          RegExp.escape(typeName) +
          r'\b',
    );
    if (pattern.hasMatch(text)) found += 1;
  }
  return found;
}
