/// Sprint 115.26 — AI Usage, Credits & Cost View.
///
/// Metadata-only view contract. It keeps application credits and provider
/// metering separate, exposes unavailable balances explicitly, and never stores
/// prompt or creative content.
library;

import 'dart:collection';

enum AiUsageType { tokens, images, audioSeconds, videoSeconds, requests }

enum AiUsageSource { providerApi, localLog, userDeclared }

final class BillingPeriod {
  const BillingPeriod._({required this.year, required this.month});

  factory BillingPeriod.month({required int year, required int month}) {
    if (year < 1) throw ArgumentError.value(year, 'year');
    if (month < 1 || month > 12) throw ArgumentError.value(month, 'month');
    return BillingPeriod._(year: year, month: month);
  }

  final int year;
  final int month;

  String get label => '$year-${month.toString().padLeft(2, '0')}';
}

final class ApplicationCreditBalance {
  const ApplicationCreditBalance._({
    required this.remaining,
    required this.measuredAt,
  });

  factory ApplicationCreditBalance.available({
    required double remaining,
    required DateTime measuredAt,
  }) {
    if (!remaining.isFinite || remaining < 0) {
      throw ArgumentError.value(remaining, 'remaining');
    }
    return ApplicationCreditBalance._(
      remaining: remaining,
      measuredAt: measuredAt.toUtc(),
    );
  }

  factory ApplicationCreditBalance.unavailable() =>
      const ApplicationCreditBalance._(remaining: null, measuredAt: null);

  final double? remaining;
  final DateTime? measuredAt;

  bool get isAvailable => remaining != null;
}

final class ProviderBalance {
  ProviderBalance._({
    required this.providerId,
    required this.amount,
    required this.currency,
    required this.measuredAt,
  });

  factory ProviderBalance.available({
    required String providerId,
    required double amount,
    required String currency,
    required DateTime measuredAt,
  }) {
    if (!amount.isFinite || amount < 0) {
      throw ArgumentError.value(amount, 'amount');
    }
    return ProviderBalance._(
      providerId: _required(providerId, 'providerId'),
      amount: amount,
      currency: _currency(currency),
      measuredAt: measuredAt.toUtc(),
    );
  }

  factory ProviderBalance.unavailable({required String providerId}) =>
      ProviderBalance._(
        providerId: _required(providerId, 'providerId'),
        amount: null,
        currency: null,
        measuredAt: null,
      );

  final String providerId;
  final double? amount;
  final String? currency;
  final DateTime? measuredAt;

  bool get isAvailable => amount != null;
}

final class ProviderUsageRecord {
  ProviderUsageRecord({
    required String providerId,
    required String modelId,
    required this.usageType,
    required this.quantity,
    required String unit,
    required this.estimatedCost,
    required String? currency,
    required this.billingPeriod,
    required DateTime measuredAt,
    required this.source,
    required this.isEstimate,
  }) : providerId = _required(providerId, 'providerId'),
       modelId = _required(modelId, 'modelId'),
       unit = _required(unit, 'unit'),
       currency = _optionalCurrency(currency),
       measuredAt = measuredAt.toUtc() {
    if (!quantity.isFinite || quantity < 0) {
      throw ArgumentError.value(quantity, 'quantity');
    }
    final cost = estimatedCost;
    if (cost != null && (!cost.isFinite || cost < 0)) {
      throw ArgumentError.value(cost, 'estimatedCost');
    }
    if ((cost == null) != (this.currency == null)) {
      throw ArgumentError(
        'estimatedCost and currency must either both be present or both absent.',
      );
    }
  }

  static const publicFields = <String>{
    'provider_id',
    'model_id',
    'usage_type',
    'quantity',
    'unit',
    'estimated_cost',
    'currency',
    'billing_period',
    'measured_at',
    'source',
    'is_estimate',
  };

  final String providerId;
  final String modelId;
  final AiUsageType usageType;
  final double quantity;
  final String unit;
  final double? estimatedCost;
  final String? currency;
  final BillingPeriod billingPeriod;
  final DateTime measuredAt;
  final AiUsageSource source;
  final bool isEstimate;

  String get costLabel => isEstimate ? 'Estimated' : 'Reported';
}

final class AccountCenterAiUsageCreditsCostView {
  AccountCenterAiUsageCreditsCostView({
    required this.applicationCredits,
    Iterable<ProviderUsageRecord> providerUsage = const [],
    Iterable<ProviderBalance> providerBalances = const [],
  }) : providerUsage = UnmodifiableListView(
         providerUsage.toList(growable: false),
       ),
       providerBalances = UnmodifiableListView(
         providerBalances.toList(growable: false),
       );

  final ApplicationCreditBalance applicationCredits;
  final List<ProviderUsageRecord> providerUsage;
  final List<ProviderBalance> providerBalances;
}

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, field);
  return normalized;
}

String _currency(String value) => _required(value, 'currency').toUpperCase();

String? _optionalCurrency(String? value) =>
    value == null ? null : _currency(value);
