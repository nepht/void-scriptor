enum Sprint116AiUsageCostState { pass, fail, blocked }

enum Sprint116AiFreshness { fresh, stale, unavailable }

final class Sprint116AiUsageCostRecord {
  Sprint116AiUsageCostRecord({
    required this.providerId,
    required this.usageUnits,
    required this.providerCost,
    required this.currency,
    required this.isEstimate,
    required this.measuredAt,
  });

  final String providerId;
  final double usageUnits;
  final double? providerCost;
  final String? currency;
  final bool isEstimate;
  final DateTime measuredAt;
}

final class Sprint116AiUsageCostReport {
  const Sprint116AiUsageCostReport({
    required this.state,
    required this.invalidReasons,
    required this.totalUsageUnits,
    required this.providerCost,
    required this.applicationCreditsRemaining,
    required this.applicationCreditsAvailable,
    required this.costLabel,
    required this.currency,
    required this.freshness,
    required this.budgetAlert,
  });

  final Sprint116AiUsageCostState state;
  final List<String> invalidReasons;
  final double totalUsageUnits;
  final double? providerCost;
  final double? applicationCreditsRemaining;
  final bool applicationCreditsAvailable;
  final String costLabel;
  final String? currency;
  final Sprint116AiFreshness freshness;
  final bool budgetAlert;
}

abstract final class Sprint116AiUsageCostContract {
  static const String canonicalStep = '116.27';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_116_ai_usage_cost_reconciliation.json';
  static const String externalGates = 'DEFERRED-EXTERNAL';
  static const List<String> acceptance = <String>[
    'usage_units',
    'app_credit_separation',
    'provider_cost',
    'estimated_label',
    'currency',
    'freshness',
    'budget_alert',
  ];
}

final class Sprint116AiUsageCostReconciliation {
  Sprint116AiUsageCostReport evaluate({
    required List<Sprint116AiUsageCostRecord> records,
    required double? applicationCreditsRemaining,
    required DateTime now,
    required double budget,
  }) {
    final invalid = <String>[];
    if (records.isEmpty) invalid.add('records');
    if (!budget.isFinite || budget < 0) invalid.add('budget');

    final currencies = <String>{};
    var units = 0.0;
    var cost = 0.0;
    var hasCost = false;
    var estimate = false;
    var oldest = now.toUtc();
    for (final record in records) {
      if (record.providerId.trim().isEmpty) invalid.add('provider_id');
      if (!record.usageUnits.isFinite || record.usageUnits < 0) {
        invalid.add('usage_units');
      } else {
        units += record.usageUnits;
      }
      if (record.providerCost != null) {
        if (!record.providerCost!.isFinite || record.providerCost! < 0) {
          invalid.add('provider_cost');
        } else {
          cost += record.providerCost!;
          hasCost = true;
        }
      }
      if (record.currency != null)
        currencies.add(record.currency!.trim().toUpperCase());
      if (record.providerCost != null && record.currency == null)
        invalid.add('currency');
      estimate = estimate || record.isEstimate;
      final measured = record.measuredAt.toUtc();
      if (measured.isBefore(oldest)) oldest = measured;
    }
    if (currencies.length > 1) invalid.add('currency');
    final age = now.toUtc().difference(oldest);
    final freshness = records.isEmpty
        ? Sprint116AiFreshness.unavailable
        : age > const Duration(days: 7)
        ? Sprint116AiFreshness.stale
        : Sprint116AiFreshness.fresh;
    final state = invalid.isEmpty
        ? Sprint116AiUsageCostState.pass
        : Sprint116AiUsageCostState.fail;
    return Sprint116AiUsageCostReport(
      state: state,
      invalidReasons: List.unmodifiable(invalid.toSet()),
      totalUsageUnits: units,
      providerCost: hasCost ? cost : null,
      applicationCreditsRemaining: applicationCreditsRemaining,
      applicationCreditsAvailable: applicationCreditsRemaining != null,
      costLabel: !hasCost
          ? 'Unavailable'
          : estimate
          ? 'Estimated'
          : 'Reported',
      currency: currencies.length == 1 ? currencies.single : null,
      freshness: freshness,
      budgetAlert: hasCost && cost > budget,
    );
  }
}
