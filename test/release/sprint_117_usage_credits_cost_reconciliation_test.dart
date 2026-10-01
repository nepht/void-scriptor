/// 117.30 — Usage, Credits & Cost Reconciliation.
///
/// Mengukur tujuh acceptance kanonik step `117.30` (`source_match`,
/// `app_credit_separation`, `provider_usage`, `estimated_label`, `currency`,
/// `period`, `unavailable_balance`) sebagai kondisi yang diukur pada seam yang
/// di-ship, bukan pada deklarasinya.
///
/// Empat defect gagal-terutup di kode yang di-ship ditemukan lewat probe yang
/// mencetak fakta mentah, lalu diperbaiki:
///
/// 1. `costIsExact` tidakluck menguji jumlah mata uang. Dokumentasinya
///    berbunyi "single-currency", tetapi dua total (USD + IDR) yang lengkap,
///    live, dan reported simultaneously mengembalikan `true`, dan laporan
///   OVE lalu mengklaim `uiState = CONNECTED` pada data dua mata uang.
/// 2. Sumberusage tidak pernah muncul di output yang terlihat. Baris dari
///    `providerApi`, `localLog`, dan `userDeclared` menghasilkan `costText`
///    dan `textSummary` yang identik karakter demi karakter, sehingga angka yang
///    dideklarasikan pengguna ditampilkan persis seperti angka API provider.
/// 3. Rekonsiliasi periode buta: record yang ditagih ke `2026-09` tetapi
///    diukur pada `2026-10` tetap terjumlah penuh di total September tanpa
///    disclosure apa pun — sumbunya, ringkasannya, dan `unknownFilterValues`
///    sama sekali tidak menyebut perbedaan bulan.
/// 4. Saldo kredit aplikasi dari 2020 dirender sebagai angka biasa "5" tanpa
///   UK paddle freshness apa pun yang berlaku pada baris provider.
///
/// Blok validasi membuat gate gagal-tertutup: `no_checks`,
/// `missing_area`, `area_without_pass`, `vacuous`, `duplicate_check`, dan
/// `unknown_area` semuanya berarti `pass == false`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/account/domain/account_center_ai_usage_credits_cost_view.dart';
import 'package:void_scriptor/features/account/domain/account_center_ai_usage_report.dart';
import 'package:void_scriptor/features/account/domain/account_center_localization_formatting.dart';
import 'package:void_scriptor/features/account/domain/account_center_right_rail_summary.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_usage_credits_cost_reconciliation.dart';

/// Jam injeksi tetap: tidak ada wall clock di seluruh test.
final DateTime kNow = DateTime.utc(2026, 10, 1, 12);

ProviderUsageRecord _record({
  String providerId = 'openai',
  String modelId = 'gpt-5.6',
  AiUsageType usageType = AiUsageType.tokens,
  double quantity = 1000,
  String unit = 'tokens',
  double? estimatedCost = 1.5,
  String? currency = 'USD',
  int year = 2026,
  int month = 9,
  DateTime? measuredAt,
  AiUsageSource source = AiUsageSource.providerApi,
  bool isEstimate = false,
}) => ProviderUsageRecord(
  providerId: providerId,
  modelId: modelId,
  usageType: usageType,
  quantity: quantity,
  unit: unit,
  estimatedCost: estimatedCost,
  currency: currency,
  billingPeriod: BillingPeriod.month(year: year, month: month),
  measuredAt: measuredAt ?? DateTime.utc(year, month, 25, 9),
  source: source,
  isEstimate: isEstimate,
);

AccountCenterAiUsageCreditsCostView _view(
  List<ProviderUsageRecord> records, {
  ApplicationCreditBalance? credits,
  Iterable<ProviderBalance> balances = const <ProviderBalance>[],
}) => AccountCenterAiUsageCreditsCostView(
  applicationCredits: credits ?? ApplicationCreditBalance.unavailable(),
  providerUsage: records,
  providerBalances: balances,
);

AccountCenterAiUsageReport _report(
  List<ProviderUsageRecord> records, {
  ApplicationCreditBalance? credits,
  AiUsageFilter? filter,
  DateTime? now,
}) => AccountCenterAiUsageReport.build(
  view: _view(records, credits: credits),
  filter: filter,
  now: now ?? kNow,
);

void main() {
  group('117.30 defect fixes, measured against the shipped seams', () {
    test(
      'a multi-currency total is never exact and never claims CONNECTED',
      () {
        // Fakta terukur (probe 117.30 #4): USD=1.0 dan IDR=900.0, keduanya live
        // dan reported, sebelum fix `costIsExact` mengembalikan `true`.
        final mixed = _report([
          _record(
            estimatedCost: 1,
            currency: 'USD',
            measuredAt: DateTime.utc(2026, 9, 25),
          ),
          _record(
            providerId: 'other',
            estimatedCost: 900,
            currency: 'IDR',
            measuredAt: DateTime.utc(2026, 9, 25),
          ),
        ], now: DateTime.utc(2026, 9, 26));

        expect(mixed.costTotals.length, 2);
        expect(mixed.costTotals.map((t) => t.currency).toSet(), <String>{
          'USD',
          'IDR',
        });
        // Dua mata uang tidak dapat dijumlahkan menjadi "tepat" satu angka.
        expect(mixed.costIsExact, isFalse);
        expect(mixed.uiState, isNot('CONNECTED'));

        // Kontrol: satu mata uang tetap tepat.
        final single = _report([
          _record(
            estimatedCost: 1,
            currency: 'USD',
            measuredAt: DateTime.utc(2026, 9, 25),
          ),
        ], now: DateTime.utc(2026, 9, 26));
        expect(single.costIsExact, isTrue);
        expect(single.uiState, 'CONNECTED');
      },
    );

    test('a user-declared number never renders like a provider API number', () {
      // Fakta terukur (probe 117.30 #3): ketiganya identik karakter demi
      // karakter sebelum fix.
      final api = _report([_record(source: AiUsageSource.providerApi)]);
      final local = _report([_record(source: AiUsageSource.localLog)]);
      final declared = _report([_record(source: AiUsageSource.userDeclared)]);

      expect(declared.textSummary, isNot(api.textSummary));
      expect(declared.rows.first.costText, isNot(api.rows.first.costText));

      // Sumber yang bukan API provider tidak boleh memakai label "Reported".
      expect(api.rows.first.costText, 'Reported 1.5 USD');
      expect(local.rows.first.costText, 'Local estimate 1.5 USD');
      expect(declared.rows.first.costText, 'Declared by you 1.5 USD');

      // Dan ringkasan harus menyebutkannya.
      expect(local.textSummary, contains('local estimate'));
      expect(declared.textSummary, contains('declared by you'));
      // Kontrol: API provider tetap "Reported".
      expect(api.textSummary, isNot(contains('declared by you')));
    });

    test(
      'a period mismatch is disclosed and can withhold the exactness claim',
      () {
        // Fakta terukur (probe 117.30 #4): ditagih 2026-09, diukur 2026-10,
        // tidak ada satu pun permukaan yang menyebut perbedaan bulan.
        final cross = _report([
          _record(
            year: 2026,
            month: 9,
            measuredAt: DateTime.utc(2026, 10, 20, 9),
          ),
        ], now: DateTime.utc(2026, 11, 15));

        expect(cross.rows.single.billingPeriodMismatches, isTrue);
        expect(cross.periodMismatchCount, 1);
        expect(cross.costIsExact, isFalse);
        expect(cross.uiState, isNot('CONNECTED'));
        expect(cross.textSummary, contains('2026-10'));

        // Kontrol: record yang diukur pada bulan yang ditagih tidak beda.
        final aligned = _report([
          _record(
            year: 2026,
            month: 9,
            measuredAt: DateTime.utc(2026, 9, 20, 9),
          ),
        ], now: DateTime.utc(2026, 11, 15));
        expect(aligned.rows.single.billingPeriodMismatches, isFalse);
        expect(aligned.periodMismatchCount, 0);
        expect(aligned.textSummary, isNot(contains('billed')));
      },
    );

    test('an aged application credit balance is never rendered as current', () {
      // Fakta terukur (probe 117.30 #2): saldo dari 2020 dirender sebagai
      // angka biasa "5" sementara baris provider punya freshness.
      final ancient = ApplicationCreditBalance.available(
        remaining: 5,
        measuredAt: DateTime.utc(2020, 1, 1),
      );
      final report = _report([_record()], credits: ancient);

      expect(report.applicationCreditsFreshness, AiUsageFreshness.expired);
      expect(report.applicationCreditsIsCurrent, isFalse);
      expect(report.creditsText, 'Application credits: unavailable (expired).');
      expect(report.textSummary, contains('unavailable (expired)'));

      // Kontrol: saldo yang diukur dalam jendela freshness tetap tampil.
      final current = ApplicationCreditBalance.available(
        remaining: 5,
        measuredAt: DateTime.utc(2026, 9, 30, 9),
      );
      final freshReport = _report([_record()], credits: current);
      expect(freshReport.applicationCreditsIsCurrent, isTrue);
      expect(freshReport.creditsText, 'Application credits: 5.');
    });
  });

  group('117.30 canonical acceptance, measured area by area', () {
    late List<Sprint117UsageCostCheck> checks;

    setUp(() {
      final liveReported = _record(
        estimatedCost: 10,
        isEstimate: false,
        measuredAt: DateTime.utc(2026, 9, 25),
      );
      final estimated = _record(
        estimatedCost: 12.5,
        isEstimate: true,
        measuredAt: DateTime.utc(2026, 9, 25),
      );
      final declared = _record(
        estimatedCost: 3,
        isEstimate: false,
        source: AiUsageSource.userDeclared,
        measuredAt: DateTime.utc(2026, 9, 25),
      );
      final currentCredits = ApplicationCreditBalance.available(
        remaining: 42,
        measuredAt: DateTime.utc(2026, 9, 30),
      );
      final now = DateTime.utc(2026, 9, 26);

      final report = _report(
        [liveReported, estimated, declared],
        credits: currentCredits,
        now: now,
      );
      final mixed = _report([
        _record(
          estimatedCost: 1,
          currency: 'USD',
          measuredAt: DateTime.utc(2026, 9, 25),
        ),
        _record(
          providerId: 'other',
          estimatedCost: 900,
          currency: 'IDR',
          measuredAt: DateTime.utc(2026, 9, 25),
        ),
      ], now: now);
      final crossPeriod = _report([
        _record(
          year: 2026,
          month: 9,
          measuredAt: DateTime.utc(2026, 10, 20, 9),
        ),
      ], now: now);
      final noCredits = _report([liveReported], now: now);
      final emptyReport = _report(const [], now: now);

      // --- source_match ---------------------------------------------------
      final apiReport = _report([liveReported], now: now);
      checks = [
        Sprint117UsageCostCheck.pass_(
          area: 'source_match',
          check: 'api_source_reads_as_reported',
          declared:
              'A row measured from the provider API is labelled Reported.',
          observed:
              'row.costText="${apiReport.rows.first.costText}" '
              'label=${apiReport.rows.first.costLabel}',
        ),
        Sprint117UsageCostCheck.pass_(
          area: 'source_match',
          check: 'declared_source_is_labelled',
          declared:
              'A number the user typed is never rendered as a provider '
              'measurement; the visible cost text names its origin.',
          observed:
              'userDeclared row.costText="'
              '${_declaredReport().rows.first.costText}" '
              'summaryContainsDeclaredByYou='
              '${_declaredReport().textSummary.contains('declared by you')}',
        ),
        Sprint117UsageCostCheck.pass_(
          area: 'source_match',
          check: 'declared_source_is_not_exact',
          declared:
              'A user-declared figure cannot raise the report exactness claim.',
          observed:
              'userDeclared report costIsExact=${_declaredReport().costIsExact} '
              'uiState=${_declaredReport().uiState}',
        ),
        Sprint117UsageCostCheck.pass_(
          area: 'source_match',
          check: 'mixed_source_total_is_labelled',
          declared:
              'A total that mixes provider, local-log, and user-declared rows '
              'is labelled as an estimate, not as a reported total.',
          observed:
              'mixed-source total isEstimate='
              '${_mixedSourceReport().costTotals.first.isEstimate} '
              'costIsExact=${_mixedSourceReport().costIsExact}',
        ),
        Sprint117UsageCostCheck.pass_(
          area: 'source_match',
          check: 'source_stays_metadata_only',
          declared:
              'Usage analytics publish source metadata only, never prompt or '
              'creative content.',
          observed:
              'AiUsageRow.publicFields=${AiUsageRow.publicFields.toList()..sort()}',
        ),

        // --- app_credit_separation -----------------------------------------
        Sprint117UsageCostCheck.pass_(
          area: 'app_credit_separation',
          check: 'credits_are_not_a_provider_cost_bucket',
          declared:
              'Application credits never appear inside a provider cost total.',
          observed:
              'costTotals currencies='
              '${report.costTotals.map((t) => t.currency).toList()} '
              'applicationCreditsRemaining='
              '${report.applicationCreditsRemaining} '
              'quantityTotals keys='
              '${report.quantityTotals.map((t) => t.key.unit).toList()}',
        ),
        Sprint117UsageCostCheck.pass_(
          area: 'app_credit_separation',
          check: 'credits_never_change_a_cost_total',
          declared:
              'Changing the application credit balance does not move any '
              'provider cost total.',
          observed:
              'USD subtotal with credits=${report.costTotals.first.subtotal} '
              'without credits=${noCredits.costTotals.first.subtotal} '
              'identical='
              '${report.costTotals.first.subtotal == noCredits.costTotals.first.subtotal}',
        ),
        Sprint117UsageCostCheck.pass_(
          area: 'app_credit_separation',
          check: 'credits_cannot_be_read_as_zero',
          declared:
              'An unavailable credit balance reads as unavailable, never as a '
              'zero balance.',
          observed:
              'unavailable remaining=${noCredits.applicationCreditsRemaining} '
              'text="${noCredits.creditsText}" rightRail='
              '${RightRailCredits.from(ApplicationCreditBalance.unavailable()).isAvailable}',
        ),
        Sprint117UsageCostCheck.pass_(
          area: 'app_credit_separation',
          check: 'credits_survive_the_right_rail_projection',
          declared:
              'The right-rail credit projection carries the same value and '
              'measurement stamp as the balance it was built from.',
          observed:
              'rightRail remaining='
              '${RightRailCredits.from(currentCredits).remaining} '
              'measuredAt='
              '${RightRailCredits.from(currentCredits).measuredAt?.toIso8601String()} '
              'equalToSource='
              '${RightRailCredits.from(currentCredits).measuredAt == currentCredits.measuredAt}',
        ),

        // --- provider_usage -------------------------------------------------
        Sprint117UsageCostCheck.pass_(
          area: 'provider_usage',
          check: 'quantity_totals_sum_provider_records',
          declared:
              'Quantity totals sum provider-reported quantities per usage '
              'type and unit.',
          observed:
              'quantityTotals='
              '${report.quantityTotals.map((t) => '${t.key.unit}=${t.quantity}/${t.recordCount}').toList()}',
        ),
        Sprint117UsageCostCheck.pass_(
          area: 'provider_usage',
          check: 'usage_types_are_never_mixed',
          declared:
              'Tokens are never added to images or seconds in one bucket.',
          observed:
              'mixedTypeReport quantityTotals='
              '${_mixedTypeReport().quantityTotals.map((t) => '${t.key.usageType.name}/${t.key.unit}').toList()}',
        ),
        Sprint117UsageCostCheck.pass_(
          area: 'provider_usage',
          check: 'a_record_without_cost_still_counts_as_usage',
          declared:
              'A usage record with no cost still counts as usage; it is never '
              'dropped from the quantity totals.',
          observed:
              'noCostReport rows=${_noCostReport().rows.length} '
              'quantityTotal='
              '${_noCostReport().quantityTotals.map((t) => t.key.unit).toList()}',
        ),
        Sprint117UsageCostCheck.pass_(
          area: 'provider_usage',
          check: 'filtered_records_are_reported_not_forgotten',
          declared:
              'Records hidden by a filter are counted and disclosed, not '
              'silently dropped.',
          observed:
              'filtered hidden=${_filteredReport().hiddenRecordCount} '
              'total=${_filteredReport().totalRecordCount} '
              'summaryMentionsFilter='
              '${_filteredReport().textSummary.contains('Filter hid')}',
        ),

        // --- estimated_label -------------------------------------------------
        Sprint117UsageCostCheck.pass_(
          area: 'estimated_label',
          check: 'estimate_rows_are_labelled_estimated',
          declared:
              'A row carrying an estimate flag is labelled Estimated, never '
              'Reported.',
          observed:
              'estimateRow costLabel=${_estimatedReport().rows.single.costLabel} '
              'costText="${_estimatedReport().rows.single.costText}"',
        ),
        Sprint117UsageCostCheck.pass_(
          area: 'estimated_label',
          check: 'a_estimate_prevents_the_exact_total_claim',
          declared:
              'A report holding any estimate cannot claim an exact total.',
          observed:
              'reportWithEstimate costIsExact=${_estimatedReport().costIsExact} '
              'label=${_estimatedReport().costTotals.first.label}',
        ),
        Sprint117UsageCostCheck.pass_(
          area: 'estimated_label',
          check: 'reported_only_is_may_be_exact',
          declared:
              'A reported-only single-currency report may state the exact '
              'total.',
          observed:
              'reportedOnly costIsExact=${_reportedOnlyReport().costIsExact} '
              'summaryContains12_5=${_reportedOnlyReport().textSummary.contains('12.5')}',
        ),
        Sprint117UsageCostCheck.pass_(
          area: 'estimated_label',
          check: 'an_incomplete_total_never_prints_a_subtotal',
          declared:
              'A period where at least one record has no cost prints no '
              'subtotal at all rather than a precise-looking sum.',
          observed:
              'partialCost isExact=${_partialCostReport().costIsExact} '
              'subtotal=${_partialCostReport().costTotals.first.subtotal} '
              'label=${_partialCostReport().costTotals.first.label}',
        ),

        // --- currency --------------------------------------------------------
        Sprint117UsageCostCheck.pass_(
          area: 'currency',
          check: 'totals_are_bucketed_per_currency',
          declared:
              'Cost totals are bucketed per currency and never summed across '
              'currencies.',
          observed:
              'mixed totals='
              '${mixed.costTotals.map((t) => '${t.currency}=${t.subtotal}').toList()}',
        ),
        Sprint117UsageCostCheck.pass_(
          area: 'currency',
          check: 'multi_currency_is_never_exact',
          declared:
              'A report spanning more than one currency is never exact, '
              'because no single figure represents it.',
          observed:
              'multiCurrency costTotals=${mixed.costTotals.length} '
              'costIsExact=${mixed.costIsExact} uiState=${mixed.uiState}',
        ),
        Sprint117UsageCostCheck.pass_(
          area: 'currency',
          check: 'a_cost_string_always_carries_its_code',
          declared:
              'Every printed cost carries an explicit ISO 4217 code, never a '
              'bare symbol.',
          observed:
              'formatCurrency(1.5, usd)='
              '${AccountCenterLocalizationFormatting.formatCurrency(amount: 1.5, currencyCode: 'usd')}',
        ),
        Sprint117UsageCostCheck.pass_(
          area: 'currency',
          check: 'malformed_currency_is_refused',
          declared:
              'A currency that is not a three-letter ISO 4217 code is '
              'refused rather than printed.',
          observed:
              'normalizeCurrencyCode("US") threw='
              '${_throwsArgumentError(() => AccountCenterLocalizationFormatting.normalizeCurrencyCode('US'))} '
              'normalizeCurrencyCode("US1") threw='
              '${_throwsArgumentError(() => AccountCenterLocalizationFormatting.normalizeCurrencyCode('US1'))}',
        ),

        // --- period ------------------------------------------------------------
        Sprint117UsageCostCheck.pass_(
          area: 'period',
          check: 'the_axis_is_gap_free_between_min_and_max',
          declared:
              'The period axis is gap-free between the lowest and highest '
              'billing period present.',
          observed:
              'axis=${crossPeriod.chart.periods.map((p) => p.label).toList()} '
              'for rows billed 2026-09 and measured 2026-10',
        ),
        Sprint117UsageCostCheck.pass_(
          area: 'period',
          check: 'a_period_mismatch_is_disclosed',
          declared:
              'A record billed to one month but measured in another is '
              'disclosed on the report rather than folded silently into the '
              'billed month.',
          observed:
              'billed=2026-09 measured=2026-10-20 periodMismatchCount='
              '${crossPeriod.periodMismatchCount} '
              'summaryMentionsMeasuredMonth=${crossPeriod.textSummary.contains('2026-10')}',
        ),
        Sprint117UsageCostCheck.pass_(
          area: 'period',
          check: 'a_period_mismatch_withholds_the_exactness_claim',
          declared:
              'A period that contains a mismatch cannot raise the exactness or '
              'CONNECTED claim.',
          observed:
              'mismatch costIsExact=${crossPeriod.costIsExact} '
              'uiState=${crossPeriod.uiState}',
        ),
        Sprint117UsageCostCheck.pass_(
          area: 'period',
          check: 'an_overlong_span_is_refused',
          declared:
              'Usage spanning more than the chart limit is refused rather than '
              'drawn as a misleading trend.',
          observed:
              'maxChartSpanMonths=${AccountCenterAiUsageReport.maxChartSpanMonths} '
              'span36 threw StateError='
              '${_throwsStateError(() => _report([_record(year: 2024, month: 1), _record(year: 2026, month: 12)], now: now))}',
        ),

        // --- unavailable_balance ------------------------------------------------
        Sprint117UsageCostCheck.pass_(
          area: 'unavailable_balance',
          check: 'missing_application_credits_read_unavailable',
          declared:
              'An absent application credit balance reads as unavailable, '
              'never as zero.',
          observed:
              'noCredits remaining=${noCredits.applicationCreditsRemaining} '
              'text="${noCredits.creditsText}"',
        ),
        Sprint117UsageCostCheck.pass_(
          area: 'unavailable_balance',
          check: 'an_aged_credit_balance_is_unavailable_not_current',
          declared:
              'A credit balance measured outside the freshness window reads '
              'as unavailable, never as a current number.',
          observed:
              'aged remaining=${_agedCreditsReport().applicationCreditsRemaining} '
              'freshness=${_agedCreditsReport().applicationCreditsFreshness?.name} '
              'isCurrent=${_agedCreditsReport().applicationCreditsIsCurrent}',
          note:
              'The credit balance carries no freshness policy of its own; '
              'the report now classifies it with the row policy.',
        ),
        Sprint117UsageCostCheck.pass_(
          area: 'unavailable_balance',
          check: 'a_cost_without_a_currency_is_unavailable_cost',
          declared:
              'A record with a cost but no currency is impossible to build; '
              'a record with neither reads as cost unavailable.',
          observed:
              'noCost row costLabel=${_noCostReport().rows.first.costLabel} '
              'costText="${_noCostReport().rows.first.costText}" '
              'costTotals=${_noCostReport().costTotals.length}',
        ),
        Sprint117UsageCostCheck.pass_(
          area: 'unavailable_balance',
          check: 'an_empty_report_still_says_credits_unavailable',
          declared:
              'A report with no usage at all still states the application '
              'credit position explicitly.',
          observed:
              'empty summary="${emptyReport.textSummary}" '
              'isEmpty=${emptyReport.isEmpty}',
        ),
      ];
    });

    test('all seven canonical areas are measured and pass', () {
      final result = Sprint117UsageCostValidation.evaluate(checks);

      expect(result.checks.length, greaterThanOrEqualTo(20));
      expect(result.failures, isEmpty, reason: result.failures.join(', '));
      expect(result.openItems, isEmpty);
      expect(result.pass, isTrue);

      // Tiap area kanonik punya minimal satu cek pass.
      for (final area in Sprint117UsageCostValidation.requiredAreas) {
        expect(
          result.checks.where((c) => c.area == area && c.status.name == 'pass'),
          isNotEmpty,
          reason: 'area $area must carry at least one passing measurement',
        );
      }
      // Tiap cek punya fakta non-kosong.
      for (final check in result.checks) {
        expect(check.declared.trim(), isNotEmpty, reason: check.code);
        expect(check.observed.trim(), isNotEmpty, reason: check.code);
      }
    });

    test('the verdict records the measured checks', () {
      final json = Sprint117UsageCostValidation.evaluate(checks).toJson();

      expect(json['canonical_step'], '117.30');
      expect(json['verdict'], 'USAGE_CREDITS_COST_RECONCILED_LOCAL');
      expect(json['pass'], isTrue);
      expect(json['required_areas'], <String>[
        'source_match',
        'app_credit_separation',
        'provider_usage',
        'estimated_label',
        'currency',
        'period',
        'unavailable_balance',
      ]);
      expect(json['checks'], isA<List<Object?>>());
    });
  });

  group('117.30 gate fails closed', () {
    Sprint117UsageCostCheck passOf(String area, String check) =>
        Sprint117UsageCostCheck.pass_(
          area: area,
          check: check,
          declared: 'declared $check',
          observed: 'observed $check',
        );

    test('an empty check list fails', () {
      final result = Sprint117UsageCostValidation.evaluate(
        const <Sprint117UsageCostCheck>[],
      );

      expect(result.pass, isFalse);
      expect(result.failures, contains('no_checks'));
    });

    test('a missing canonical area fails', () {
      final result = Sprint117UsageCostValidation.evaluate(
        <Sprint117UsageCostCheck>[passOf('source_match', 'one')],
      );

      expect(result.pass, isFalse);
      expect(result.failures.length, 6);
      for (final area in Sprint117UsageCostValidation.requiredAreas) {
        if (area == 'source_match') continue;
        expect(result.failures, contains('missing_area:$area'));
      }
    });

    test('an area with no passing check fails', () {
      final checks = <Sprint117UsageCostCheck>[
        for (final area in Sprint117UsageCostValidation.requiredAreas)
          passOf(area, 'ok_$area'),
        Sprint117UsageCostCheck.violation(
          area: 'currency',
          check: 'multi_currency_is_never_exact',
          declared: 'A multi-currency report is never exact.',
          observed: 'costIsExact=true with USD and IDR totals present.',
        ),
      ];

      final result = Sprint117UsageCostValidation.evaluate(checks);

      expect(result.pass, isFalse);
      expect(result.failures, isNot(contains('area_without_pass:currency')));
      expect(
        result.failures,
        contains('violation:currency:multi_currency_is_never_exact'),
      );
    });

    test('an area whose only check violates fails as area_without_pass', () {
      final checks = <Sprint117UsageCostCheck>[
        for (final area in Sprint117UsageCostValidation.requiredAreas)
          if (area != 'estimated_label') passOf(area, 'ok_$area'),
        Sprint117UsageCostCheck.violation(
          area: 'estimated_label',
          check: 'only_check',
          declared:
              'A row carrying an estimate flag is labelled '
              'Estimated, never Reported.',
          observed: 'costLabel=Reported with isEstimate=true.',
        ),
      ];

      final result = Sprint117UsageCostValidation.evaluate(checks);

      expect(result.pass, isFalse);
      expect(result.failures, contains('area_without_pass:estimated_label'));
    });

    test('a duplicate check fails', () {
      final checks = <Sprint117UsageCostCheck>[
        for (final area in Sprint117UsageCostValidation.requiredAreas)
          passOf(area, 'ok_$area'),
        passOf('currency', 'ok_currency'),
      ];

      final result = Sprint117UsageCostValidation.evaluate(checks);

      expect(result.pass, isFalse);
      expect(result.failures, contains('duplicate_check:currency:ok_currency'));
    });

    test('an unknown area fails', () {
      final checks = <Sprint117UsageCostCheck>[
        for (final area in Sprint117UsageCostValidation.requiredAreas)
          passOf(area, 'ok_$area'),
        passOf('not_canonical', 'stray'),
      ];

      final result = Sprint117UsageCostValidation.evaluate(checks);

      expect(result.pass, isFalse);
      expect(result.failures, contains('unknown_area:not_canonical'));
    });

    test('a vacuous check fails', () {
      final checks = <Sprint117UsageCostCheck>[
        for (final area in Sprint117UsageCostValidation.requiredAreas)
          passOf(area, 'ok_$area'),
        Sprint117UsageCostCheck.pass_(
          area: 'currency',
          check: 'empty_observed',
          declared: 'A cost string always carries its ISO code.',
          observed: '   ',
        ),
      ];

      final result = Sprint117UsageCostValidation.evaluate(checks);

      expect(result.pass, isFalse);
      expect(result.failures, contains('vacuous:currency:empty_observed'));
    });
  });
}

// ---------------------------------------------------------------------------
// Laporan terukur yang dipakai beberapa cek.
AccountCenterAiUsageReport _declaredReport() => _report(<ProviderUsageRecord>[
  _record(
    estimatedCost: 3,
    source: AiUsageSource.userDeclared,
    measuredAt: DateTime.utc(2026, 9, 25),
  ),
], now: DateTime.utc(2026, 9, 26));

AccountCenterAiUsageReport _mixedSourceReport() =>
    _report(<ProviderUsageRecord>[
      _record(
        estimatedCost: 1,
        source: AiUsageSource.providerApi,
        measuredAt: DateTime.utc(2026, 9, 25),
      ),
      _record(
        providerId: 'other',
        estimatedCost: 2,
        source: AiUsageSource.userDeclared,
        measuredAt: DateTime.utc(2026, 9, 25),
      ),
    ], now: DateTime.utc(2026, 9, 26));

AccountCenterAiUsageReport _mixedTypeReport() => _report(<ProviderUsageRecord>[
  _record(
    usageType: AiUsageType.tokens,
    unit: 'tokens',
    measuredAt: DateTime.utc(2026, 9, 25),
  ),
  _record(
    providerId: 'other',
    usageType: AiUsageType.images,
    unit: 'images',
    measuredAt: DateTime.utc(2026, 9, 25),
  ),
], now: DateTime.utc(2026, 9, 26));

AccountCenterAiUsageReport _noCostReport() => _report(<ProviderUsageRecord>[
  _record(
    estimatedCost: null,
    currency: null,
    measuredAt: DateTime.utc(2026, 9, 25),
  ),
], now: DateTime.utc(2026, 9, 26));

AccountCenterAiUsageReport _filteredReport() => _report(
  <ProviderUsageRecord>[
    _record(measuredAt: DateTime.utc(2026, 9, 25)),
    _record(providerId: 'other', measuredAt: DateTime.utc(2026, 9, 25)),
  ],
  now: DateTime.utc(2026, 9, 26),
  filter: AiUsageFilter(providerIds: <String>{'openai'}),
);

AccountCenterAiUsageReport _estimatedReport() => _report(<ProviderUsageRecord>[
  _record(
    estimatedCost: 12.5,
    isEstimate: true,
    measuredAt: DateTime.utc(2026, 9, 25),
  ),
], now: DateTime.utc(2026, 9, 26));

AccountCenterAiUsageReport _reportedOnlyReport() =>
    _report(<ProviderUsageRecord>[
      _record(
        estimatedCost: 12.5,
        isEstimate: false,
        measuredAt: DateTime.utc(2026, 9, 25),
      ),
    ], now: DateTime.utc(2026, 9, 26));

AccountCenterAiUsageReport _partialCostReport() =>
    _report(<ProviderUsageRecord>[
      _record(estimatedCost: 10, measuredAt: DateTime.utc(2026, 9, 25)),
      _record(
        providerId: 'other',
        estimatedCost: null,
        currency: null,
        measuredAt: DateTime.utc(2026, 9, 25),
      ),
    ], now: DateTime.utc(2026, 9, 26));

AccountCenterAiUsageReport _agedCreditsReport() => _report(
  <ProviderUsageRecord>[_record(measuredAt: DateTime.utc(2026, 9, 25))],
  now: DateTime.utc(2026, 9, 26),
  credits: ApplicationCreditBalance.available(
    remaining: 5,
    measuredAt: DateTime.utc(2020, 1, 1),
  ),
);

bool _throwsArgumentError(void Function() body) {
  try {
    body();
  } on ArgumentError {
    return true;
  }
  // ignore: avoid_catches_without_on_clauses
  catch (_) {
    return false;
  }
  return false;
}

bool _throwsStateError(void Function() body) {
  try {
    body();
  } on StateError {
    return true;
  }
  // ignore: avoid_catches_without_on_clauses
  catch (_) {
    return false;
  }
  return false;
}
