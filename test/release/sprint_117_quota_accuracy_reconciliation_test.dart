/// 117.29 — Quota Accuracy Reconciliation.
///
/// Mengukur tujuh bukti kanonik `117.29` (`api_match`, `local_scan_match`,
/// `timestamp`, `unit_conversion`, `rounding`, `no_mock`, `unavailable_state`)
/// sebagai kondisi TERUKUR terhadap mekanisme yang benar-benar di-ship —
/// adapter quota, agregasi cloud, kartu storage, dan laporan distribusi —
/// bukan terhadap deklarasi.
///
/// Tiap cek menurunkan statusnya dari predikat yang diukur pada seam aslinya:
/// kalau nilai yang di-ship berbeda dari nilai yang diklaim, ceknya jadi
/// `violation` dan gate gagal. Tidak ada cek yang menulis `pass` tanpa
/// predikat terukur.
///
/// Tidak ada wall clock: seluruh umur dihitung dari jam injeksi
/// `2026-10-01T12:00Z`.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_cloud_storage_aggregation.dart';
import 'package:void_scriptor/features/account/domain/account_center_localization_formatting.dart';
import 'package:void_scriptor/features/account/domain/account_center_provider_quota_adapter.dart';
import 'package:void_scriptor/features/account/domain/account_center_right_rail_summary.dart';
import 'package:void_scriptor/features/account/domain/account_center_storage_distribution_report.dart';
import 'package:void_scriptor/features/account/domain/account_center_storage_usage_card.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_quota_accuracy_reconciliation.dart';

/// Jam injeksi tunggal; tidak ada `DateTime.now()` di seluruh drill ini.
final DateTime kNow = DateTime.utc(2026, 10, 1, 12);

const String kManifestPath =
    'docs/evidence/sprint-117-29-manifest-20261001.json';

const int kKib = 1024;
const int kMib = 1024 * kKib;
const int kGib = 1024 * kMib;

void main() {
  test('117.29 seven canonical acceptance areas reconcile with shipped seams', () {
    final checks = <Sprint117QuotaAccuracyCheck>[];

    // ---------------------------------------------------------------- api_match
    final apiReading = ProviderQuotaReading(
      providerId: 'OneDrive',
      usedBytes: 12_345_678_901,
      quotaBytes: 100_000_000_000,
      availableBytes: 87_654_321_099,
      measuredAt: kNow,
      unit: ProviderQuotaUnit.bytes,
    );
    final apiCard = StorageUsageCardData.fromBytes(
      providerId: 'OneDrive',
      accountLabel: 'writer@live',
      usedBytes: apiReading.usedBytes,
      quotaBytes: apiReading.quotaBytes,
      measuredAt: apiReading.measuredAt,
      now: kNow,
    );
    final secondReading = ProviderQuotaReading(
      providerId: 'dropbox',
      usedBytes: 500,
      quotaBytes: 900,
      availableBytes: 400,
      measuredAt: kNow,
      unit: ProviderQuotaUnit.bytes,
    );
    final pairAggregate = CloudStorageAggregation.from(<ProviderQuotaResult>[
      ProviderQuotaResult.fromReading(apiReading, now: kNow),
      ProviderQuotaResult.fromReading(secondReading, now: kNow),
    ]);
    checks.add(
      _measure(
        area: 'api_match',
        check: 'provider_bytes_reach_surface_unmodified',
        declared:
            'A provider byte reading reaches the card unmodified: no '
            'rescaling, no refill, no default.',
        observed:
            'reading ${apiReading.usedBytes}/${apiReading.quotaBytes} -> '
            'card ${apiCard.usedBytes}/${apiCard.quotaBytes}',
        holds:
            apiCard.usedBytes == apiReading.usedBytes &&
            apiCard.quotaBytes == apiReading.quotaBytes,
      ),
    );
    checks.add(
      _measure(
        area: 'api_match',
        check: 'aggregate_total_is_the_sum_of_the_readings_it_included',
        declared:
            'The aggregate total equals the sum of the readings it '
            'included, never an independent estimate.',
        observed:
            'status=${pairAggregate.status}, '
            'used=${pairAggregate.usedBytes}, quota=${pairAggregate.quotaBytes}'
            ', available=${pairAggregate.availableBytes}',
        holds:
            pairAggregate.status == CloudStorageAggregationStatus.complete &&
            pairAggregate.usedBytes ==
                apiReading.usedBytes + secondReading.usedBytes &&
            pairAggregate.quotaBytes ==
                apiReading.quotaBytes + secondReading.quotaBytes &&
            pairAggregate.availableBytes ==
                apiReading.availableBytes + secondReading.availableBytes,
      ),
    );

    // ------------------------------------------------------- local_scan_match
    final localReport = AccountCenterStorageDistributionReport.build(
      records: <StorageDistributionRecord>[
        StorageDistributionRecord(
          scope: StorageDistributionScope.local,
          category: StorageCategoryRef.canonical(StorageCategoryKind.projects),
          bytes: 4_096,
          measuredAt: kNow,
          source: StorageRecordSource.localScan,
        ),
        StorageDistributionRecord(
          scope: StorageDistributionScope.remote,
          category: StorageCategoryRef.canonical(StorageCategoryKind.assets),
          bytes: 1_048_576,
          measuredAt: kNow,
          source: StorageRecordSource.providerApi,
          accountId: 'live-account',
          providerId: 'dropbox',
        ),
      ],
      now: kNow,
    );
    checks.add(
      _measure(
        area: 'local_scan_match',
        check: 'local_scan_bytes_enter_the_distribution_total',
        declared:
            'Bytes a local scan measured enter the distribution total '
            'at their measured value.',
        observed:
            'localScan 4096 + providerApi 1048576 -> '
            'chart.totalBytes=${localReport.chart.totalBytes}',
        holds: localReport.chart.totalBytes == 4_096 + 1_048_576,
      ),
    );
    checks.add(
      _measure(
        area: 'local_scan_match',
        check: 'local_scan_cannot_be_reported_under_the_remote_scope',
        declared:
            'A local scan never produces a remote-scope record; the '
            'constructor refuses it instead of relabelling it.',
        observed:
            'localScan reported as remote is '
            '${_rejectsLocalScanAsRemote() ? 'refused' : 'ACCEPTED'}',
        holds: _rejectsLocalScanAsRemote(),
      ),
    );

    // ------------------------------------------------------------- timestamp
    final futureStamp = kNow.add(const Duration(hours: 5));
    final futureResult = ProviderQuotaResult.fromReading(
      ProviderQuotaReading(
        providerId: 'googledrive',
        usedBytes: 10,
        quotaBytes: 100,
        availableBytes: 90,
        measuredAt: futureStamp,
        unit: ProviderQuotaUnit.bytes,
      ),
      now: kNow,
    );
    final futureCard = StorageUsageCardData.fromBytes(
      providerId: 'googledrive',
      accountLabel: 'writer@live',
      usedBytes: 10,
      quotaBytes: 100,
      measuredAt: futureStamp,
      now: kNow,
    );
    final futureRow = StorageDistributionFreshnessPolicy().classify(
      measuredAt: futureStamp,
      now: kNow,
    );
    final staleResult = ProviderQuotaResult.fromReading(
      ProviderQuotaReading(
        providerId: 'googledrive',
        usedBytes: 10,
        quotaBytes: 100,
        availableBytes: 90,
        measuredAt: kNow.subtract(const Duration(hours: 48)),
        unit: ProviderQuotaUnit.bytes,
      ),
      now: kNow,
    );
    checks.add(
      _measure(
        area: 'timestamp',
        check: 'a_future_dated_provider_reading_is_never_live_data',
        declared:
            'A reading stamped after the injected clock cannot be live '
            'data; it is refused rather than reported as fresh.',
        observed: 'measuredAt now+5h -> status=${futureResult.status}',
        holds: futureResult.status != ProviderQuotaStatus.fresh,
      ),
    );
    checks.add(
      _measure(
        area: 'timestamp',
        check: 'every_seam_agrees_on_the_same_future_stamp',
        declared:
            'All shipped seams classify one future stamp the same way, '
            'so two surfaces cannot disagree about what is live.',
        observed:
            'provider=${futureResult.status}, '
            'card=${futureCard.freshness}, row=$futureRow',
        holds: _agreesOnFutureStamp(
          providerStatus: futureResult.status,
          cardFreshness: futureCard.freshness,
          rowFreshness: futureRow,
        ),
      ),
    );
    checks.add(
      _measure(
        area: 'timestamp',
        check: 'a_reading_past_the_stale_window_reads_stale',
        declared:
            'A reading older than the stale window is marked stale, not '
            'fresh.',
        observed:
            'measuredAt now-48h, staleAfter 24h -> '
            'status=${staleResult.status}',
        holds: staleResult.status == ProviderQuotaStatus.stale,
      ),
    );

    // ------------------------------------------------------- unit_conversion
    final gibResult = ProviderQuotaResult.fromReading(
      ProviderQuotaReading(
        providerId: 'mega',
        usedBytes: 3,
        quotaBytes: 20,
        availableBytes: 17,
        measuredAt: kNow,
        unit: ProviderQuotaUnit.gibibytes,
      ),
      now: kNow,
    );
    final mixedAggregate = CloudStorageAggregation.from(<ProviderQuotaResult>[
      gibResult,
      ProviderQuotaResult.fromReading(
        ProviderQuotaReading(
          providerId: 'dropbox',
          usedBytes: 1_000,
          quotaBytes: 2_000,
          availableBytes: 1_000,
          measuredAt: kNow,
          unit: ProviderQuotaUnit.bytes,
        ),
        now: kNow,
      ),
    ]);
    checks.add(
      _measure(
        area: 'unit_conversion',
        check: 'a_binary_provider_unit_is_converted_not_dropped',
        declared:
            'A provider-reported binary unit is converted to bytes '
            'before the total is folded, and the raw reading itself keeps the '
            'value the provider reported; the account is never silently '
            'excluded from its own total.',
        observed:
            'mega raw ${gibResult.reading!.usedBytes}/'
            '${gibResult.reading!.quotaBytes} (${gibResult.reading!.unit.name})'
            '; aggregate used=${mixedAggregate.usedBytes} '
            'quota=${mixedAggregate.quotaBytes} '
            'available=${mixedAggregate.availableBytes} '
            'included=${mixedAggregate.includedProviderIds} '
            'excluded=${mixedAggregate.excludedProviderIds}',
        holds:
            mixedAggregate.includedProviderIds.contains('mega') &&
            !mixedAggregate.excludedProviderIds.contains('mega') &&
            mixedAggregate.usedBytes == 3 * kGib + 1_000 &&
            mixedAggregate.quotaBytes == 20 * kGib + 2_000 &&
            mixedAggregate.availableBytes == 17 * kGib + 1_000 &&
            mixedAggregate.status == CloudStorageAggregationStatus.complete,
      ),
    );
    final providerDefined = _providerDefinedOutcome();
    checks.add(
      _measure(
        area: 'unit_conversion',
        check: 'a_unit_this_build_cannot_convert_stays_excluded',
        declared:
            'A provider-defined unit stays excluded and visible instead '
            'of being guessed at.',
        observed: 'providerDefined -> $providerDefined',
        holds:
            providerDefined.contains('excluded=[vendor]') &&
            providerDefined.contains('included=[]'),
      ),
    );

    // --------------------------------------------------------------- rounding
    final justUnder = StorageUsageCardData.fromBytes(
      providerId: 'onedrive',
      accountLabel: 'writer@live',
      usedBytes: 999_999,
      quotaBytes: 1_000_000,
      measuredAt: kNow,
      now: kNow,
    );
    final underLabel = AccountCenterLocalizationFormatting.storageUnits(
      999_999,
    );
    final renderedBytes = _renderedByteCount(underLabel);
    final ceiling = _unitCeiling(999_999);
    checks.add(
      _measure(
        area: 'rounding',
        check: 'a_size_never_rounds_up_into_the_next_unit',
        declared:
            'A value below a unit boundary keeps that unit: it may be '
            'rounded inside the unit, but never up to the next one, where '
            '`1000 KB` would read as the 1 MB it is not.',
        observed:
            'raw 999999 B rendered as "$underLabel"'
            '${renderedBytes == null ? ' (unparseable)' : ' = $renderedBytes B'}'
            '${ceiling == null ? '' : ', unit ceiling $ceiling B'}',
        holds:
            renderedBytes != null && ceiling != null && renderedBytes < ceiling,
      ),
    );
    checks.add(
      _measure(
        area: 'rounding',
        check: 'the_card_prints_one_unit_rule_not_two',
        declared:
            'One card renders used/available/quota through one unit '
            'rule, so a reader can reconcile the numbers printed on it.',
        observed: 'card: "${justUnder.accessibleProgress}"',
        holds:
            justUnder.accessibleProgress ==
            '${AccountCenterLocalizationFormatting.sharePercent(999_999, 1_000_000)}'
                '% used, '
                '${AccountCenterLocalizationFormatting.storageUnits(1)} '
                'available of '
                '${AccountCenterLocalizationFormatting.storageUnits(1_000_000)}',
      ),
    );

    // ---------------------------------------------------------------- no_mock
    final mixedSourceReport = AccountCenterStorageDistributionReport.build(
      records: <StorageDistributionRecord>[
        StorageDistributionRecord(
          scope: StorageDistributionScope.local,
          category: StorageCategoryRef.canonical(StorageCategoryKind.projects),
          bytes: 5_000,
          measuredAt: kNow,
          source: StorageRecordSource.localScan,
        ),
        StorageDistributionRecord(
          scope: StorageDistributionScope.local,
          category: StorageCategoryRef.canonical(StorageCategoryKind.other),
          bytes: 999_999_999,
          measuredAt: kNow,
          source: StorageRecordSource.userDeclared,
        ),
      ],
      now: kNow,
    );
    final unverifiedRow = mixedSourceReport.rows.firstWhere(
      (r) => r.isUnverified,
    );
    checks.add(
      _measure(
        area: 'no_mock',
        check: 'a_user_typed_value_is_flagged_not_passed_off_as_measured',
        declared:
            'A user-declared value keeps its own source label and makes '
            'the total non-exact; it never reports as measured data.',
        observed:
            'sourceLabel="${unverifiedRow.sourceLabel}", '
            'totalIsExact=${mixedSourceReport.totalIsExact}, '
            'uiState=${mixedSourceReport.uiState}',
        holds:
            unverifiedRow.sourceLabel == 'User declared' &&
            !mixedSourceReport.totalIsExact &&
            mixedSourceReport.uiState != 'CONNECTED',
      ),
    );
    checks.add(
      _measure(
        area: 'no_mock',
        check: 'the_report_declares_no_production_mock_and_reads_no_provider',
        declared:
            'The distribution report declares reference mock values '
            'unusable in production and performs no provider read itself.',
        observed:
            'referenceMockValuesAllowed='
            '${AccountCenterStorageDistributionReport.referenceMockValuesAllowed}, '
            'performsProviderRead='
            '${AccountCenterStorageDistributionReport.performsProviderRead}',
        holds:
            !AccountCenterStorageDistributionReport
                .referenceMockValuesAllowed &&
            !AccountCenterStorageDistributionReport.performsProviderRead,
      ),
    );

    // ------------------------------------------------------- unavailable_state
    final noReadable = CloudStorageAggregation.from(<ProviderQuotaResult>[
      ProviderQuotaResult.fromReading(
        ProviderQuotaReading(
          providerId: 'googledrive',
          usedBytes: 1,
          quotaBytes: 2,
          availableBytes: 1,
          measuredAt: kNow,
          unit: ProviderQuotaUnit.providerDefined,
        ),
        now: kNow,
      ),
    ]);
    checks.add(
      _measure(
        area: 'unavailable_state',
        check: 'no_readable_reading_reports_unavailable_not_zero',
        declared:
            'With no readable provider reading the aggregate reports '
            'unavailable with null totals, never zero bytes.',
        observed:
            'status=${noReadable.status}, used=${noReadable.usedBytes}, '
            'quota=${noReadable.quotaBytes}',
        holds:
            noReadable.status == CloudStorageAggregationStatus.unavailable &&
            noReadable.usedBytes == null &&
            noReadable.quotaBytes == null,
      ),
    );
    final omittedQuota = StorageUsageCardData.unknownQuota(
      providerId: 'p',
      accountLabel: 'a',
      usedBytes: 10,
      measuredAt: kNow,
      now: kNow,
    );
    final railLabel = _rightRailUnavailableLabel();
    checks.add(
      _measure(
        area: 'unavailable_state',
        check: 'an_omitted_quota_reads_unavailable_not_zero',
        declared:
            'A provider that omits its quota reads "Quota unavailable" '
            'on every surface, never a zero-byte quota.',
        observed: 'card="${omittedQuota.quotaLabel}", rail="$railLabel"',
        holds:
            omittedQuota.quotaLabel == 'Quota unavailable' &&
            railLabel.contains('unavailable'),
      ),
    );

    final result = Sprint117QuotaAccuracyValidation.evaluate(checks);

    expect(
      result.violationCodes,
      isEmpty,
      reason: 'Quota accuracy violations:\n${result.violationCodes.join('\n')}',
    );
    expect(
      result.failures,
      isEmpty,
      reason: 'Structural failures:\n${result.failures.join('\n')}',
    );
    expect(
      result.pass,
      isTrue,
      reason: 'Quota accuracy gate did not pass: ${result.summary}',
    );

    _writeManifestIfRequested(result);
  });

  test('117.29 gate is fail-closed when an area has no check', () {
    final empty = Sprint117QuotaAccuracyValidation.evaluate(
      const <Sprint117QuotaAccuracyCheck>[],
    );
    expect(empty.pass, isFalse);
    expect(empty.failures, contains('no_checks'));

    // One area only: the other six must be reported missing, not silently pass.
    final single =
        Sprint117QuotaAccuracyValidation.evaluate(<Sprint117QuotaAccuracyCheck>[
          Sprint117QuotaAccuracyCheck.pass_(
            area: 'rounding',
            check: 'only_one',
            declared: 'declared',
            observed: 'observed',
          ),
        ]);
    expect(single.pass, isFalse);
    expect(single.failures, contains('missing_area:api_match'));
    expect(single.failures, contains('missing_area:no_mock'));
    expect(single.failures, isNot(contains('missing_area:rounding')));
  });
}

/// Builds the check from a predicate measured against the shipped seam.
Sprint117QuotaAccuracyCheck _measure({
  required String area,
  required String check,
  required String declared,
  required String observed,
  required bool holds,
}) => holds
    ? Sprint117QuotaAccuracyCheck.pass_(
        area: area,
        check: check,
        declared: declared,
        observed: observed,
      )
    : Sprint117QuotaAccuracyCheck.violation(
        area: area,
        check: check,
        declared: declared,
        observed: observed,
      );

/// The byte count a decimal size label states, or `null` when the label is not
/// a parseable size. Parsed from the text the user is shown, so the comparison
/// is against what the UI states rather than against intent.
int? _renderedByteCount(String label) {
  final match = RegExp(
    r'^(\d+(?:\.\d+)?) (B|KB|MB|GB|TB)$',
  ).firstMatch(label.trim());
  if (match == null) return null;
  final multiplier = switch (match.group(2)) {
    'B' => 1,
    'KB' => 1000,
    'MB' => 1000 * 1000,
    'GB' => 1000 * 1000 * 1000,
    _ => 1000 * 1000 * 1000 * 1000,
  };
  return (double.parse(match.group(1)!) * multiplier).round();
}

/// The multiplier of the unit a byte value of [bytes] belongs to, per the
/// same decimal thresholds the formatter uses.
int? _unitCeiling(int bytes) {
  const steps = <int>[
    1,
    1000,
    1000 * 1000,
    1000 * 1000 * 1000,
    1000 * 1000 * 1000 * 1000,
  ];
  for (final ceiling in steps) {
    if (bytes < ceiling) return ceiling;
  }
  return null;
}

/// Whether a local scan reported under the remote scope is refused.
bool _rejectsLocalScanAsRemote() {
  try {
    StorageDistributionRecord(
      scope: StorageDistributionScope.remote,
      category: StorageCategoryRef.canonical(StorageCategoryKind.projects),
      bytes: 1,
      measuredAt: kNow,
      source: StorageRecordSource.localScan,
      accountId: 'live-account',
    );
    return false;
  } on ArgumentError {
    return true;
  }
}

/// Whether every seam reaches the same verdict about one future stamp.
bool _agreesOnFutureStamp({
  required ProviderQuotaStatus providerStatus,
  required StorageUsageFreshness cardFreshness,
  required StorageDistributionFreshness rowFreshness,
}) {
  final verdicts = <bool>[
    providerStatus != ProviderQuotaStatus.fresh,
    cardFreshness != StorageUsageFreshness.fresh,
    rowFreshness != StorageDistributionFreshness.live,
  ];
  return verdicts.toSet().length == 1;
}

/// The measured outcome for a unit this build cannot convert.
String _providerDefinedOutcome() {
  final result = ProviderQuotaResult.fromReading(
    ProviderQuotaReading(
      providerId: 'vendor',
      usedBytes: 1,
      quotaBytes: 2,
      availableBytes: 1,
      measuredAt: kNow,
      unit: ProviderQuotaUnit.providerDefined,
    ),
    now: kNow,
  );
  final aggregate = CloudStorageAggregation.from(<ProviderQuotaResult>[result]);
  return 'status=${result.status}, included=${aggregate.includedProviderIds}, '
      'excluded=${aggregate.excludedProviderIds}';
}

/// The right-rail label when nothing could be read.
String _rightRailUnavailableLabel() => RightRailStorageLine.from(
  CloudStorageAggregation.from(const <ProviderQuotaResult>[]),
).label;

void _writeManifestIfRequested(Sprint117QuotaAccuracyValidationResult result) {
  if (Platform.environment['SPRINT_117_29_MANIFEST'] != '1') return;
  final manifest = <String, Object?>{
    'canonical_step': '117.29',
    'document_role': 'SPRINT_117_29_QUOTA_ACCURACY_RECONCILIATION_EVIDENCE',
    'required_areas': Sprint117QuotaAccuracyValidation.requiredAreas.toList(),
    'surfaces': Sprint117QuotaAccuracyValidation.surfaceLabels,
    'verdict': result.pass
        ? 'QUOTA_ACCURACY_RECONCILED_LOCAL'
        : 'QUOTA_ACCURACY_RECONCILIATION_FAILED',
    'pass': result.pass,
    'failures': result.failures,
    'open_items': result.openItems,
    'violation_codes': result.violationCodes,
    'checks': result.checks.map((c) => c.toJson()).toList(),
  };
  File(kManifestPath).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
    flush: true,
  );
}
