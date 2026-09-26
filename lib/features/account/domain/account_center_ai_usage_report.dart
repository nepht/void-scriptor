/// Sprint 115.40 — AI Usage Chart & Detail Table.
///
/// The trend surface behind the Account & Cloud Center usage panel: a chart of
/// usage over time, a textual summary of the same numbers, and a detail table of
/// the records that produced them.
///
/// The product spec forbids the three easy lies here
/// (`ai_usage_contract.rules`), so the contract encodes them structurally:
///
/// * `Separate application credits from provider billing.` — credits never
///   enter a cost total, and a credit balance is either API-backed or reported
///   as unavailable, never as zero.
/// * `Mark estimated costs clearly.` — every cost cell and every total carries
///   `Estimated` or `Reported` from the record's own flag, and a total that
///   mixes the two is an estimate, not an exact number.
/// * `Do not include prompt or creative content in usage analytics.` —
///   [AiUsageRow.publicFields] is a closed set; there is no field a prompt
///   could ride along in.
///
/// A chart is not a table: quantities are grouped by usage type **and** unit so
/// tokens are never added to images, a period with no record is a gap rather
/// than a zero, and a series whose maximum is zero is declared unrenderable
/// instead of dividing by it. Every bar carries a text alternative, so the
/// trend survives without pixels.
///
/// Freshness is derived from each record's own `measured_at` against an
/// injected clock, never the wall clock at render time. A timestamp in the
/// future is flagged, not counted as fresh forever, and a stale or expired row
/// is never presented as current.
///
/// No provider request, invoice, or balance read happens here, the
/// product-spec billing contract stays `PLANNED_NOT_VERIFIED`, reference mock
/// values cannot be produced, and public-trust signing, hosted CI, telemetry,
/// hardware, adoption, and publication stay `DEFERRED-EXTERNAL`.
library;

import 'dart:collection';

import 'account_center_ai_usage_credits_cost_view.dart';

/// How current a record is relative to the injected clock.
enum AiUsageFreshness {
  live,
  stale,
  expired,

  /// `measured_at` is later than the reference clock. A record that claims to
  /// be measured in the future is a data defect, not a fresh reading.
  futureTimestamped,
}

/// Why a report shows nothing.
enum AiUsageEmptyReason {
  /// The account has no usage records at all.
  noData,

  /// Records exist, but the filter excluded every one of them.
  filteredOut,
}

/// A billing period usable as a filter bound.
///
/// Validated through a factory so an out-of-range month is refused in every
/// build mode; a const constructor's `assert` disappears in release.
final class AiUsagePeriodBound {
  factory AiUsagePeriodBound(int year, int month) {
    if (month < 1 || month > 12) {
      throw ArgumentError.value(month, 'month', 'must be 1..12');
    }
    return AiUsagePeriodBound._(year, month);
  }

  const AiUsagePeriodBound._(this.year, this.month);

  final int year;
  final int month;

  int get ordinal => year * 12 + (month - 1);

  int compareTo(AiUsagePeriodBound other) => ordinal.compareTo(other.ordinal);

  @override
  bool operator ==(Object other) =>
      other is AiUsagePeriodBound && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';
}

/// The windows that decide [AiUsageFreshness].
///
/// Validated in a factory rather than an initializer so a caller cannot build
/// a policy with a negative window or a stale threshold that outlives the
/// expiry threshold.
final class AiUsageFreshnessPolicy {
  factory AiUsageFreshnessPolicy({
    Duration staleAfter = const Duration(hours: 48),
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
    return AiUsageFreshnessPolicy._(staleAfter, expiresAfter);
  }

  const AiUsageFreshnessPolicy._(this.staleAfter, this.expiresAfter);

  final Duration staleAfter;
  final Duration expiresAfter;

  AiUsageFreshness classify({
    required DateTime measuredAt,
    required DateTime now,
  }) {
    final age = now.toUtc().difference(measuredAt.toUtc());
    if (age.isNegative) return AiUsageFreshness.futureTimestamped;
    if (age > expiresAfter) return AiUsageFreshness.expired;
    if (age > staleAfter) return AiUsageFreshness.stale;
    return AiUsageFreshness.live;
  }
}

/// Narrows the report. Every criterion is optional; an absent criterion keeps
/// everything.
///
/// A value the data does not contain is not a filter that happens to match
/// nothing — it is an unknown value, and the report says so.
final class AiUsageFilter {
  factory AiUsageFilter({
    Set<String> providerIds = const <String>{},
    Set<String> modelIds = const <String>{},
    Set<AiUsageType> usageTypes = const <AiUsageType>{},
    AiUsagePeriodBound? periodFrom,
    AiUsagePeriodBound? periodTo,
    bool includeEstimates = true,
  }) {
    if (periodFrom != null &&
        periodTo != null &&
        periodFrom.compareTo(periodTo) > 0) {
      throw ArgumentError(
        'periodFrom (${periodFrom.toString()}) must not be later than '
        'periodTo (${periodTo.toString()})',
      );
    }
    return AiUsageFilter._(
      providerIds: _normalized(providerIds),
      modelIds: _normalized(modelIds),
      usageTypes: usageTypes.toSet(),
      periodFrom: periodFrom,
      periodTo: periodTo,
      includeEstimates: includeEstimates,
    );
  }

  /// Keeps every record.
  factory AiUsageFilter.all() => AiUsageFilter();

  const AiUsageFilter._({
    required this.providerIds,
    required this.modelIds,
    required this.usageTypes,
    required this.periodFrom,
    required this.periodTo,
    required this.includeEstimates,
  });

  final Set<String> providerIds;
  final Set<String> modelIds;
  final Set<AiUsageType> usageTypes;
  final AiUsagePeriodBound? periodFrom;
  final AiUsagePeriodBound? periodTo;

  /// When `false`, records flagged `is_estimate` are excluded.
  final bool includeEstimates;

  bool matches(ProviderUsageRecord record) {
    if (providerIds.isNotEmpty && !providerIds.contains(record.providerId)) {
      return false;
    }
    if (modelIds.isNotEmpty && !modelIds.contains(record.modelId)) {
      return false;
    }
    if (usageTypes.isNotEmpty && !usageTypes.contains(record.usageType)) {
      return false;
    }
    if (!includeEstimates && record.isEstimate) return false;
    final bound = AiUsagePeriodBound(
      record.billingPeriod.year,
      record.billingPeriod.month,
    );
    final from = periodFrom;
    final to = periodTo;
    if (from != null && bound.compareTo(from) < 0) return false;
    if (to != null && bound.compareTo(to) > 0) return false;
    return true;
  }

  /// Filter values that match nothing in the supplied data.
  ///
  /// Reported instead of silently producing an empty chart, because a typo in a
  /// provider id and a genuinely empty account look identical otherwise.
  List<String> unknownValuesAgainst(Iterable<ProviderUsageRecord> records) {
    final data = records.toList(growable: false);
    final unknown = <String>[];
    for (final id in providerIds) {
      if (!data.any((record) => record.providerId == id)) unknown.add(id);
    }
    for (final id in modelIds) {
      if (!data.any((record) => record.modelId == id)) unknown.add(id);
    }
    for (final type in usageTypes) {
      if (!data.any((record) => record.usageType == type)) {
        unknown.add(type.wireName);
      }
    }
    unknown.sort();
    return UnmodifiableListView(unknown);
  }
}

Set<String> _normalized(Set<String> values) {
  final out = <String>{};
  for (final value in values) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) out.add(trimmed);
  }
  return Set<String>.unmodifiable(out);
}

/// Identifies one chart series: a usage type *and* its unit.
final class AiUsageSeriesKey {
  const AiUsageSeriesKey(this.usageType, this.unit);

  final AiUsageType usageType;
  final String unit;

  @override
  bool operator ==(Object other) =>
      other is AiUsageSeriesKey &&
      other.usageType == usageType &&
      other.unit == unit;

  @override
  int get hashCode => Object.hash(usageType, unit);

  @override
  String toString() => '${usageType.wireName}/$unit';
}

extension _AiUsageTypeWire on AiUsageType {
  String get wireName => switch (this) {
    AiUsageType.tokens => 'tokens',
    AiUsageType.images => 'images',
    AiUsageType.audioSeconds => 'audio_seconds',
    AiUsageType.videoSeconds => 'video_seconds',
    AiUsageType.requests => 'requests',
  };
}

/// One column of the chart.
final class AiUsageBar {
  const AiUsageBar._({
    required this.period,
    required this.unit,
    required this.quantity,
    required this.recordCount,
    required this.cost,
    required this.currency,
  });

  final BillingPeriod period;

  /// The series unit, carried on the bar so the text alternative is complete
  /// without a back-reference to the series.
  final String unit;

  /// `null` when no record exists for this period: a gap is not a zero.
  final double? quantity;

  final int recordCount;

  /// The cost for this period, `null` when unknown or mixed-currency.
  final double? cost;

  /// The currency [cost] is denominated in, `null` when [cost] is `null`.
  final String? currency;

  bool get hasData => quantity != null;

  /// Readable without the chart. Always non-blank.
  String get textAlternative {
    if (!hasData) return '${period.label}: no data in $unit';
    final amount = cost;
    final code = currency;
    final costPart = amount == null || code == null
        ? ' (cost unavailable)'
        : ' (${_formatAmount(amount)} $code)';
    return '${period.label}: ${_formatAmount(quantity!)} $unit$costPart';
  }
}

/// All columns of one series.
final class AiUsageChartSeries {
  AiUsageChartSeries._({
    required this.key,
    required this.periods,
    required this._buckets,
  }) {
    bars = List<AiUsageBar>.unmodifiable(
      periods.map((period) {
        // Keyed by period label, not by BillingPeriod identity: BillingPeriod
        // has no value equality, so an identity lookup silently misses every
        // bucket and turns every real measurement into a gap.
        final bucket = _buckets[period.label];
        return AiUsageBar._(
          period: period,
          unit: key.unit,
          quantity: bucket?.quantity,
          recordCount: bucket?.recordCount ?? 0,
          cost: bucket?.cost,
          currency: bucket?.cost == null ? null : bucket?.currency,
        );
      }),
    );
    maxQuantity = bars.fold<double>(0, (acc, bar) {
      final value = bar.quantity;
      return value != null && value > acc ? value : acc;
    });
  }

  final AiUsageSeriesKey key;
  final List<BillingPeriod> periods;

  /// Keyed by `BillingPeriod.label`.
  final Map<String, _SeriesBucket> _buckets;

  late final List<AiUsageBar> bars;
  late final double maxQuantity;

  String get unit => key.unit;

  /// A series whose maximum is zero cannot be scaled; the UI must say so
  /// instead of dividing by it.
  bool get isRenderable => maxQuantity > 0;

  /// The share of the series maximum a bar reaches, `null` when unrenderable.
  double? fractionOf(AiUsageBar bar) {
    if (!isRenderable || !bar.hasData) return null;
    return bar.quantity! / maxQuantity;
  }

  String get textAlternative {
    final known = bars.where((bar) => bar.hasData).length;
    final buffer = StringBuffer(
      '${key.usageType.wireName} in $unit: $known of ${bars.length} '
      'periods with data',
    );
    if (isRenderable) {
      buffer.write(', peak ${_formatAmount(maxQuantity)} $unit');
    } else {
      buffer.write(', nothing to plot (every recorded quantity is zero)');
    }
    return buffer.toString();
  }
}

class _SeriesBucket {
  double quantity = 0;
  int recordCount = 0;
  double? cost;
  String? currency;
  bool costUnusable = false;

  /// A period cost is only shown when every contributing record carries a cost
  /// in the same currency. A missing or mixed contribution makes the period
  /// cost unavailable rather than a partial sum that looks exact.
  void addCost(double? amount, String? code) {
    if (amount == null || code == null) {
      costUnusable = true;
      return;
    }
    if (costUnusable) return;
    if (currency == null) {
      currency = code;
      cost = amount;
      return;
    }
    if (currency != code) {
      costUnusable = true;
      cost = null;
      return;
    }
    cost = cost! + amount;
  }
}

/// The chart itself.
final class AiUsageChart {
  const AiUsageChart._({
    required this.series,
    required this.periods,
    required this.maxSpanMonths,
  });

  final List<AiUsageChartSeries> series;

  /// Every period on the shared axis, ascending and gap-free.
  final List<BillingPeriod> periods;

  final int maxSpanMonths;

  bool get hasRenderableSeries => series.any((s) => s.isRenderable);
}

/// One row of the detail table.
final class AiUsageRow {
  const AiUsageRow._({
    required this.providerId,
    required this.modelId,
    required this.usageType,
    required this.unit,
    required this.quantity,
    required this.period,
    required this.measuredAt,
    required this.costAmount,
    required this.costCurrency,
    required this.source,
    required this.freshness,
    required this.isEstimate,
  });

  /// The closed set of fields a row may publish.
  ///
  /// There is deliberately no prompt, content, or free-text field: usage
  /// analytics must never be able to carry creative content.
  static const publicFields = <String>{
    'provider_id',
    'model_id',
    'usage_type',
    'unit',
    'quantity',
    'billing_period',
    'measured_at',
    'cost_amount',
    'cost_currency',
    'cost_label',
    'source',
    'freshness',
    'is_estimate',
  };

  final String providerId;
  final String modelId;
  final AiUsageType usageType;
  final String unit;
  final double quantity;
  final BillingPeriod period;
  final DateTime measuredAt;
  final double? costAmount;
  final String? costCurrency;
  final AiUsageSource source;
  final AiUsageFreshness freshness;
  final bool isEstimate;

  bool get isCurrent => freshness == AiUsageFreshness.live;

  /// `Estimated`, `Reported`, or `Cost unavailable` — never a bare number and
  /// never a zero standing in for an unknown cost.
  String get costLabel {
    if (costAmount == null) return 'Cost unavailable';
    return isEstimate ? 'Estimated' : 'Reported';
  }

  String get costText {
    final amount = costAmount;
    final currency = costCurrency;
    if (amount == null || currency == null) return 'Cost unavailable';
    return '$costLabel ${_formatAmount(amount)} $currency';
  }

  Map<String, Object?> toPublicJson() => <String, Object?>{
    'provider_id': providerId,
    'model_id': modelId,
    'usage_type': usageType.wireName,
    'unit': unit,
    'quantity': quantity,
    'billing_period': period.label,
    'measured_at': measuredAt.toIso8601String(),
    'cost_amount': costAmount,
    'cost_currency': costCurrency,
    'cost_label': costLabel,
    'source': source.wireName,
    'freshness': freshness.name,
    'is_estimate': isEstimate,
  };
}

extension _AiUsageSourceWire on AiUsageSource {
  String get wireName => switch (this) {
    AiUsageSource.providerApi => 'provider_api',
    AiUsageSource.localLog => 'local_log',
    AiUsageSource.userDeclared => 'user_declared',
  };
}

/// A cost total for one currency bucket.
final class AiUsageCostTotal {
  const AiUsageCostTotal._({
    required this.currency,
    required this.subtotal,
    required this.recordCount,
    required this.recordsMissingCost,
    required this.isEstimate,
    required this.reason,
  });

  final String currency;

  /// `null` when at least one record in scope has no cost: summing the rest
  /// would be a precise-looking number built from incomplete data.
  final double? subtotal;

  final int recordCount;

  /// Surviving records in the report that carry no cost at all.
  final int recordsMissingCost;

  final bool isEstimate;

  /// Non-blank whenever [subtotal] is `null`.
  final String? reason;

  String get label {
    if (subtotal == null) return 'Incomplete';
    return isEstimate ? 'Estimated' : 'Reported';
  }
}

/// A quantity total for one usage type and unit.
final class AiUsageQuantityTotal {
  const AiUsageQuantityTotal({
    required this.key,
    required this.quantity,
    required this.recordCount,
  });

  final AiUsageSeriesKey key;
  final double quantity;
  final int recordCount;
}

final class AccountCenterAiUsageReport {
  AccountCenterAiUsageReport._({
    required this.chart,
    required this.rows,
    required this.costTotals,
    required this.quantityTotals,
    required this.freshnessCounts,
    required this.textSummary,
    required this.unknownFilterValues,
    required this.hiddenRecordCount,
    required this.totalRecordCount,
    required this.emptyReason,
    required this.suggestedAction,
    required this.freshnessLabel,
    required this.lastUpdatedAt,
    required this.applicationCreditsRemaining,
  });

  /// Product-spec `billing_contract.status`; this step never claims a live
  /// billing integration.
  static const String billingContractStatus = 'PLANNED_NOT_VERIFIED';

  /// `reference_mock_values.production_use_allowed`.
  static const bool referenceMockValuesAllowed = false;

  /// Signing, hosted CI, telemetry, hardware, adoption, and publication.
  static const String externalGateStatus = 'DEFERRED-EXTERNAL';

  static const canonicalAcceptance = <String>[
    'chart',
    'text_summary',
    'data_table',
    'filters',
    'freshness',
    'estimate_label',
    'empty_state',
  ];

  static const canonicalSprintPath =
      'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/sprint_115.json';
  static const canonicalSprintSha256 =
      'c8d5166aa151fc691606540c84887ee407a574947444ae2520e5f1c7222c6aba';

  /// A trend wider than this is a data defect, not a trend.
  static const int maxChartSpanMonths = 24;

  static const String noCostReason =
      'Cost unavailable for at least one record in this period';

  /// Builds the report from the underlying metadata-only usage view.
  factory AccountCenterAiUsageReport.build({
    required AccountCenterAiUsageCreditsCostView view,
    AiUsageFilter? filter,
    DateTime? now,
    AiUsageFreshnessPolicy? freshness,
  }) {
    final effectiveFilter = filter ?? AiUsageFilter.all();
    final policy = freshness ?? AiUsageFreshnessPolicy();
    final clock = (now ?? DateTime.now()).toUtc();

    final all = view.providerUsage;
    final unknownValues = effectiveFilter.unknownValuesAgainst(all);
    final kept = all.where(effectiveFilter.matches).toList(growable: false);

    final rows = List<AiUsageRow>.unmodifiable(
      kept
          .map(
            (record) => _rowOf(
              record,
              policy.classify(measuredAt: record.measuredAt, now: clock),
            ),
          )
          .toList(growable: false),
    );

    final periods = _axisPeriods(kept);
    final chart = AiUsageChart._(
      series: _series(kept, periods),
      periods: List<BillingPeriod>.unmodifiable(periods),
      maxSpanMonths: maxChartSpanMonths,
    );

    final missingCostCount = rows.where((row) => row.costAmount == null).length;
    final costTotals = _costTotals(rows, missingCostCount);
    final quantityTotals = _quantityTotals(rows);
    final freshnessCounts = _freshnessCounts(rows);
    final lastUpdatedAt = rows.isEmpty
        ? null
        : rows
              .map((row) => row.measuredAt)
              .reduce((a, b) => a.isAfter(b) ? a : b);

    return AccountCenterAiUsageReport._(
      chart: chart,
      rows: rows,
      costTotals: List<AiUsageCostTotal>.unmodifiable(costTotals),
      quantityTotals: List<AiUsageQuantityTotal>.unmodifiable(quantityTotals),
      freshnessCounts: Map<AiUsageFreshness, int>.unmodifiable(freshnessCounts),
      textSummary: _summary(
        rows: rows,
        costTotals: costTotals,
        freshnessCounts: freshnessCounts,
        hidden: all.length - kept.length,
        total: all.length,
        unknownValues: unknownValues,
        creditsRemaining: view.applicationCredits.remaining,
      ),
      unknownFilterValues: List<String>.unmodifiable(unknownValues),
      hiddenRecordCount: all.length - kept.length,
      totalRecordCount: all.length,
      emptyReason: rows.isEmpty
          ? (all.isEmpty
                ? AiUsageEmptyReason.noData
                : AiUsageEmptyReason.filteredOut)
          : null,
      suggestedAction: _suggestedAction(
        rows: rows,
        emptyReason: rows.isEmpty
            ? (all.isEmpty
                  ? AiUsageEmptyReason.noData
                  : AiUsageEmptyReason.filteredOut)
            : null,
      ),
      freshnessLabel: _freshnessLabel(freshnessCounts),
      lastUpdatedAt: lastUpdatedAt,
      applicationCreditsRemaining: view.applicationCredits.remaining,
    );
  }

  final AiUsageChart chart;
  final List<AiUsageRow> rows;
  final List<AiUsageCostTotal> costTotals;
  final List<AiUsageQuantityTotal> quantityTotals;
  final Map<AiUsageFreshness, int> freshnessCounts;

  /// Always non-blank, including in the empty state.
  final String textSummary;

  /// Filter values that matched nothing in the source data.
  final List<String> unknownFilterValues;

  final int hiddenRecordCount;
  final int totalRecordCount;

  /// `null` when the report is not empty.
  final AiUsageEmptyReason? emptyReason;

  final String suggestedAction;

  /// Non-blank description of the freshness mix.
  final String freshnessLabel;

  /// The most recent `measured_at` in the report, `null` when empty.
  final DateTime? lastUpdatedAt;

  /// Application credits, kept out of every provider cost total.
  final double? applicationCreditsRemaining;

  bool get isEmpty => rows.isEmpty;

  bool get filtersAreNarrowing => hiddenRecordCount > 0;

  AiUsageChartSeries? seriesFor(AiUsageSeriesKey key) {
    for (final series in chart.series) {
      if (series.key == key) return series;
    }
    return null;
  }

  /// True only when every total is complete, single-currency, and reported
  /// rather than estimated.
  bool get costIsExact {
    if (costTotals.isEmpty) return false;
    for (final total in costTotals) {
      if (total.subtotal == null) return false;
      if (total.isEstimate) return false;
    }
    return true;
  }

  /// True only when every row is live. A report with a stale, expired, or
  /// future-dated row is not current, whatever the chart shows.
  bool get costIsCurrent {
    if (rows.isEmpty) return false;
    return rows.every((row) => row.isCurrent);
  }

  /// The product-spec `ui_states` entry this report represents.
  String get uiState {
    if (isEmpty) return 'EMPTY';
    if (costIsCurrent && costTotals.every((total) => total.subtotal != null)) {
      return 'CONNECTED';
    }
    return 'PARTIAL_DATA';
  }
}

AiUsageRow _rowOf(ProviderUsageRecord record, AiUsageFreshness freshness) {
  return AiUsageRow._(
    providerId: record.providerId,
    modelId: record.modelId,
    usageType: record.usageType,
    unit: record.unit,
    quantity: record.quantity,
    period: record.billingPeriod,
    measuredAt: record.measuredAt,
    costAmount: record.estimatedCost,
    costCurrency: record.currency,
    source: record.source,
    freshness: freshness,
    isEstimate: record.isEstimate,
  );
}

/// The shared, gap-free period axis, or a [StateError] when the data spans
/// further than a chart can honestly show.
List<BillingPeriod> _axisPeriods(List<ProviderUsageRecord> records) {
  if (records.isEmpty) return const <BillingPeriod>[];
  var min = records.first.billingPeriod;
  var max = records.first.billingPeriod;
  for (final record in records) {
    if (record.billingPeriod.year < min.year ||
        (record.billingPeriod.year == min.year &&
            record.billingPeriod.month < min.month)) {
      min = record.billingPeriod;
    }
    if (record.billingPeriod.year > max.year ||
        (record.billingPeriod.year == max.year &&
            record.billingPeriod.month > max.month)) {
      max = record.billingPeriod;
    }
  }
  final span = (max.year - min.year) * 12 + (max.month - min.month) + 1;
  if (span > AccountCenterAiUsageReport.maxChartSpanMonths) {
    throw StateError(
      'Usage data spans $span billing periods '
      '(${min.label} to ${max.label}); a chart is limited to '
      '${AccountCenterAiUsageReport.maxChartSpanMonths}. Filter the data first.',
    );
  }
  return <BillingPeriod>[
    for (int index = 0; index < span; index++)
      BillingPeriod.month(
        year: min.year + (min.month - 1 + index) ~/ 12,
        month: (min.month - 1 + index) % 12 + 1,
      ),
  ];
}

List<AiUsageChartSeries> _series(
  List<ProviderUsageRecord> records,
  List<BillingPeriod> periods,
) {
  final keys = <AiUsageSeriesKey>[];
  final buckets = <AiUsageSeriesKey, Map<String, _SeriesBucket>>{};
  for (final record in records) {
    final key = AiUsageSeriesKey(record.usageType, record.unit);
    if (!buckets.containsKey(key)) {
      keys.add(key);
      buckets[key] = <String, _SeriesBucket>{};
    }
    final perKey = buckets[key]!;
    final bucket = perKey.putIfAbsent(
      record.billingPeriod.label,
      _SeriesBucket.new,
    );
    bucket.quantity += record.quantity;
    bucket.recordCount += 1;
    bucket.addCost(record.estimatedCost, record.currency);
  }
  return List<AiUsageChartSeries>.unmodifiable(
    keys.map(
      (key) => AiUsageChartSeries._(
        key: key,
        periods: periods,
        buckets: buckets[key]!,
      ),
    ),
  );
}

List<AiUsageCostTotal> _costTotals(
  List<AiUsageRow> rows,
  int recordsMissingCost,
) {
  final byCurrency = <String, _CostBucket>{};
  for (final row in rows) {
    final amount = row.costAmount;
    final currency = row.costCurrency;
    if (amount == null || currency == null) continue;
    final bucket = byCurrency.putIfAbsent(currency, _CostBucket.new);
    bucket.subtotal += amount;
    bucket.recordCount += 1;
    if (row.isEstimate) bucket.hasEstimate = true;
  }
  return <AiUsageCostTotal>[
    for (final entry in byCurrency.entries)
      AiUsageCostTotal._(
        currency: entry.key,
        subtotal: recordsMissingCost == 0 ? entry.value.subtotal : null,
        recordCount: entry.value.recordCount,
        recordsMissingCost: recordsMissingCost,
        isEstimate: entry.value.hasEstimate,
        reason: recordsMissingCost == 0
            ? null
            : AccountCenterAiUsageReport.noCostReason,
      ),
  ];
}

class _CostBucket {
  double subtotal = 0;
  int recordCount = 0;
  bool hasEstimate = false;
}

List<AiUsageQuantityTotal> _quantityTotals(List<AiUsageRow> rows) {
  final byKey = <AiUsageSeriesKey, _QuantityBucket>{};
  for (final row in rows) {
    final key = AiUsageSeriesKey(row.usageType, row.unit);
    final bucket = byKey.putIfAbsent(key, _QuantityBucket.new);
    bucket.quantity += row.quantity;
    bucket.recordCount += 1;
  }
  return <AiUsageQuantityTotal>[
    for (final entry in byKey.entries)
      AiUsageQuantityTotal(
        key: entry.key,
        quantity: entry.value.quantity,
        recordCount: entry.value.recordCount,
      ),
  ];
}

class _QuantityBucket {
  double quantity = 0;
  int recordCount = 0;
}

Map<AiUsageFreshness, int> _freshnessCounts(List<AiUsageRow> rows) {
  final counts = <AiUsageFreshness, int>{};
  for (final row in rows) {
    counts.update(row.freshness, (value) => value + 1, ifAbsent: () => 1);
  }
  return counts;
}

String _freshnessLabel(Map<AiUsageFreshness, int> counts) {
  if (counts.isEmpty) return 'No usage records';
  final parts = <String>[
    for (final entry in counts.entries)
      '${entry.value} ${entry.key.name.replaceAllMapped(RegExp('[A-Z]'), (match) => ' ${match[0]!.toLowerCase()}')}',
  ]..sort();
  return 'Freshness: ${parts.join(', ')}';
}

String _summary({
  required List<AiUsageRow> rows,
  required List<AiUsageCostTotal> costTotals,
  required Map<AiUsageFreshness, int> freshnessCounts,
  required int hidden,
  required int total,
  required List<String> unknownValues,
  required double? creditsRemaining,
}) {
  if (rows.isEmpty) {
    final buffer = StringBuffer('No AI usage to show.');
    if (hidden > 0) {
      buffer.write(' $hidden of $total record(s) were excluded by the filter.');
    } else {
      buffer.write(' No usage records have been reported yet.');
    }
    if (unknownValues.isNotEmpty) {
      buffer.write(' Unknown filter value(s): ${unknownValues.join(', ')}.');
    }
    buffer.write(' Application credits: ${_creditsText(creditsRemaining)}.');
    return buffer.toString();
  }

  final buffer = StringBuffer(
    'AI usage: ${rows.length} record(s) across '
    '${_distinctPeriods(rows)} period(s).',
  );
  if (hidden > 0) {
    buffer.write(' Filter hid $hidden of $total record(s).');
  }
  if (unknownValues.isNotEmpty) {
    buffer.write(' Unknown filter value(s): ${unknownValues.join(', ')}.');
  }
  for (final total1 in costTotals) {
    final subtotal = total1.subtotal;
    buffer.write(
      subtotal == null
          ? ' ${total1.label} cost for ${total1.currency} is unavailable.'
          : ' ${total1.label} cost: ${_formatAmount(subtotal)} ${total1.currency}.',
    );
  }
  if (costTotals.isEmpty) {
    buffer.write(' Cost unavailable.');
  }
  buffer.write(' ${_freshnessLabel(freshnessCounts)}.');
  buffer.write(' Application credits: ${_creditsText(creditsRemaining)}.');
  return buffer.toString();
}

String _suggestedAction({
  required List<AiUsageRow> rows,
  required AiUsageEmptyReason? emptyReason,
}) {
  if (emptyReason == AiUsageEmptyReason.noData) {
    return 'Usage appears here once a provider reports a metering record.';
  }
  if (emptyReason == AiUsageEmptyReason.filteredOut) {
    return 'Widen or clear the filter to see the excluded records.';
  }
  if (rows.any((row) => row.freshness == AiUsageFreshness.expired)) {
    return 'Reconnect the provider: some records are older than the freshness window.';
  }
  if (rows.any((row) => !row.isCurrent)) {
    return 'Refresh usage to bring stale records back to current.';
  }
  return 'No action required.';
}

int _distinctPeriods(List<AiUsageRow> rows) {
  final labels = <String>{};
  for (final row in rows) {
    labels.add(row.period.label);
  }
  return labels.length;
}

String _creditsText(double? remaining) =>
    remaining == null ? 'unavailable' : _formatAmount(remaining);

/// Formats a quantity or cost without inventing precision.
///
/// A whole number prints without a decimal tail so `12` does not become
/// `12.0000`; a fractional value keeps at most four decimals and drops the
/// trailing zeros. Non-finite input is reported, never rendered as a number.
String _formatAmount(double value) {
  if (!value.isFinite) return 'unavailable';
  if (value == value.roundToDouble() && value.abs() < 1e15) {
    return value.toStringAsFixed(0);
  }
  var text = value.toStringAsFixed(4);
  text = text.replaceFirst(RegExp(r'0+$'), '');
  text = text.replaceFirst(RegExp(r'\.$'), '');
  return text;
}
