/// Sprint 115.35 — Billing Account & Cost Summary.
///
/// Local metadata-only separation of `billing_identity`, `currency`,
/// `tax`, `billing_cycle`, `charges`, `credits`, `estimated_label`,
/// and `status`. Live billing/checkout, payment-provider redirects,
/// invoice documents, and provider metering stay injected/external
/// (`DEFERRED-EXTERNAL`); the product-spec billing contract remains
/// [AccountCenterBillingSummary.billingContractStatus] and no mock
/// credit or provider balance ever reaches production state.
library;

import 'dart:collection';

import 'package:void_scriptor/features/account/domain/account_center_subscription_entitlement_model.dart'
    show PlanBillingCycle;

/// Explicit billing status vocabulary — `unknown` is an answer, never a
/// guess.
enum BillingStatus {
  active,
  trialing,
  pastDue,
  unpaid,
  paused,
  cancelled,
  unknown,
}

/// Status of a single posted charge. Estimates are not charges; they live
/// in [BillingEstimate] with their own explicit label.
enum BillingChargeStatus { pending, paid, failed, refunded, voided }

/// Tax treatment for the billing account. `unavailable` keeps both the
/// rate and the region null instead of fabricating a zero.
enum TaxStatus { applies, doesNotApply, unavailable }

/// Who is billed. Identity fields are trimmed and never blank.
final class BillingIdentity {
  BillingIdentity({
    required String billingId,
    required String displayName,
    String? contactEmail,
  }) : billingId = _required(billingId, 'billingId'),
       displayName = _required(displayName, 'displayName'),
       contactEmail = _optional(contactEmail, 'contactEmail');

  final String billingId;
  final String displayName;

  /// `null` means explicitly unavailable — never a guessed address.
  final String? contactEmail;
}

/// Tax state with a percentage rate in `0..100`.
final class BillingTax {
  BillingTax({required this.status, this.rate, String? regionCode})
    : regionCode = _optional(regionCode, 'regionCode') {
    if (rate != null && (!rate!.isFinite || rate! < 0 || rate! > 100)) {
      throw ArgumentError.value(
        rate,
        'rate',
        'Must be finite and within 0..100.',
      );
    }
    if (status == TaxStatus.applies) {
      if (rate == null) {
        throw ArgumentError('A tax that applies requires rate.');
      }
      if (regionCode == null) {
        throw ArgumentError('A tax that applies requires regionCode.');
      }
    }
    if (status == TaxStatus.doesNotApply && rate != null) {
      throw ArgumentError('A tax that does not apply carries no rate.');
    }
    if (status == TaxStatus.unavailable &&
        (rate != null || regionCode != null)) {
      throw ArgumentError(
        'An unavailable tax state carries no rate or region.',
      );
    }
  }

  final TaxStatus status;

  /// `null` means explicitly unavailable — never a fabricated zero.
  final double? rate;
  final String? regionCode;
}

/// Billing cycle tied to a bounded UTC period. The `none` cycle (free
/// plan) carries no period at all.
final class BillingCycleInfo {
  BillingCycleInfo({required this.cycle, this.periodStart, this.periodEnd}) {
    if (periodStart != null) {
      _requireUtc(periodStart!, 'periodStart');
    }
    if (periodEnd != null) {
      _requireUtc(periodEnd!, 'periodEnd');
    }
    if (cycle == PlanBillingCycle.none) {
      if (periodStart != null || periodEnd != null) {
        throw ArgumentError('A none billing cycle carries no period.');
      }
      return;
    }
    if (periodStart == null || periodEnd == null) {
      throw ArgumentError(
        'A paid billing cycle requires periodStart and periodEnd.',
      );
    }
    if (!periodEnd!.isAfter(periodStart!)) {
      throw ArgumentError.value(
        periodEnd,
        'periodEnd',
        'Must be after periodStart.',
      );
    }
  }

  final PlanBillingCycle cycle;
  final DateTime? periodStart;
  final DateTime? periodEnd;
}

/// A single posted charge. Posted charges are final — estimates are never
/// charges (see [BillingEstimate]).
final class BillingCharge {
  BillingCharge({
    required String chargeId,
    required String description,
    required double amount,
    required String currency,
    required this.status,
    required this.issuedAt,
  }) : chargeId = _required(chargeId, 'chargeId'),
       description = _required(description, 'description'),
       amount = _amount(amount),
       currency = _currency(currency) {
    _requireUtc(issuedAt, 'issuedAt');
  }

  final String chargeId;
  final String description;
  final double amount;

  /// Normalized ISO 4217 code; must match the summary currency.
  final String currency;
  final BillingChargeStatus status;
  final DateTime issuedAt;
}

/// An explicitly labeled estimate. The label is mandatory so an estimated
/// amount can never be shown as a final one.
final class BillingEstimate {
  BillingEstimate({
    required double amount,
    required String currency,
    required String label,
    this.generatedAt,
  }) : amount = _amount(amount),
       currency = _currency(currency),
       label = _required(label, 'label') {
    if (generatedAt != null) {
      _requireUtc(generatedAt!, 'generatedAt');
    }
  }

  /// Estimates always identify themselves as estimates.
  bool get isEstimate => true;

  final double amount;
  final String currency;

  /// Explicit human label (for example "Estimated next invoice").
  final String label;
  final DateTime? generatedAt;
}

/// Application credit balance — separate from provider usage and provider
/// billing (product-spec rule). `amount == null` means explicitly
/// unavailable, never a fabricated zero.
final class CreditBalance {
  CreditBalance({required String currency, this.amount, this.asOf})
    : currency = _currency(currency) {
    if (amount != null && (!amount!.isFinite || amount! < 0)) {
      throw ArgumentError.value(amount, 'amount', 'Must be finite and >= 0.');
    }
    if (asOf != null) {
      _requireUtc(asOf!, 'asOf');
    }
    if (amount == null && asOf != null) {
      throw ArgumentError('An unavailable credit balance carries no asOf.');
    }
    if (amount != null && asOf == null) {
      throw ArgumentError('A known credit balance requires asOf.');
    }
  }

  final String currency;
  final double? amount;
  final DateTime? asOf;
}

/// Billing status with timestamped delinquency claims.
final class BillingStatusInfo {
  BillingStatusInfo({required this.status, this.asOf, String? reason})
    : reason = _optional(reason, 'reason') {
    if (asOf != null) {
      _requireUtc(asOf!, 'asOf');
    }
    if ((status == BillingStatus.pastDue || status == BillingStatus.unpaid) &&
        asOf == null) {
      throw ArgumentError('A ${status.name} claim requires asOf.');
    }
    if (status == BillingStatus.active && reason != null) {
      throw ArgumentError('An active billing status carries no reason.');
    }
  }

  final BillingStatus status;
  final DateTime? asOf;
  final String? reason;
}

/// Aggregate contract for the Billing tab: identity, currency, tax, cycle,
/// charges, credits, an optional labeled estimate, and status.
final class AccountCenterBillingSummary {
  /// Product-spec `billing_contract.status` — this step never claims a
  /// verified live billing integration.
  static const String billingContractStatus = 'PLANNED_NOT_VERIFIED';

  AccountCenterBillingSummary({
    required this.identity,
    required String currency,
    required this.tax,
    required this.cycle,
    required Iterable<BillingCharge> charges,
    required this.credits,
    this.estimate,
    required this.status,
  }) : currency = _currency(currency),
       _charges = List<BillingCharge>.of(charges) {
    _requireUnique(
      _charges.map((charge) => charge.chargeId),
      'charge.chargeId',
    );
    for (final charge in _charges) {
      // `this.currency` is required: a bare `currency` in a constructor body
      // resolves to the raw parameter, not the normalized field.
      if (charge.currency != this.currency) {
        throw ArgumentError.value(
          charge.chargeId,
          'charges',
          'Currency must match the billing summary currency.',
        );
      }
    }
    if (credits.currency != this.currency) {
      throw ArgumentError.value(
        credits.currency,
        'credits',
        'Currency must match the billing summary currency.',
      );
    }
    if (estimate != null && estimate!.currency != this.currency) {
      throw ArgumentError.value(
        estimate!.currency,
        'estimate',
        'Currency must match the billing summary currency.',
      );
    }
  }

  final BillingIdentity identity;

  /// Normalized ISO 4217 code shared by every amount in this summary.
  final String currency;
  final BillingTax tax;
  final BillingCycleInfo cycle;
  final CreditBalance credits;

  /// `null` means no estimate is available — never a fabricated zero.
  final BillingEstimate? estimate;
  final BillingStatusInfo status;
  final List<BillingCharge> _charges;

  List<BillingCharge> get charges => UnmodifiableListView(_charges);

  /// Nominal total of charges that are still owed or settled; voided
  /// charges are excluded because they were never owed. Summed in minor
  /// units (2 decimals) so binary floating point never leaks a
  /// `19.990000000000002` display artifact.
  double get chargesTotal {
    var minorUnits = 0;
    for (final charge in _charges) {
      if (charge.status == BillingChargeStatus.voided) continue;
      minorUnits += (charge.amount * 100).round();
    }
    return minorUnits / 100;
  }
}

double _amount(double value) {
  if (!value.isFinite || value < 0) {
    throw ArgumentError.value(value, 'amount', 'Must be finite and >= 0.');
  }
  return value;
}

String _currency(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.length != 3 || normalized.contains(RegExp('[^a-z]'))) {
    throw ArgumentError.value(value, 'currency', 'ISO 4217 code required.');
  }
  return normalized;
}

void _requireUtc(DateTime value, String field) {
  if (!value.isUtc) {
    throw ArgumentError.value(value, field, 'Must be UTC.');
  }
}

String _required(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) throw ArgumentError.value(value, field);
  return normalized;
}

String? _optional(String? value, String field) {
  if (value == null) return null;
  return _required(value, field);
}

void _requireUnique(Iterable<String> values, String field) {
  final seen = <String>{};
  for (final value in values) {
    if (!seen.add(value)) {
      throw ArgumentError.value(value, field, 'Must be unique.');
    }
  }
}
