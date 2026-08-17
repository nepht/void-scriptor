/// Sprint 44 — Step 44.36 License Engine, 44.37 License Model, 44.38 Entitlement System.
class ProductLicense {
  const ProductLicense({
    required this.id,
    required this.productId,
    required this.creatorId,
    required this.licenseType,
    required this.validUntil,
    this.entitlements = const [],
  });

  final String id;
  final String productId;
  final String creatorId;
  final LicenseType licenseType;
  final DateTime validUntil;
  final List<Entitlement> entitlements;
}

enum LicenseType { perpetual, subscription, trial, community }

class Entitlement {
  const Entitlement({
    required this.feature,
    required this.limit,
    this.used = 0,
  });

  final String feature;
  final int limit;
  final int used;
}

/// Step 44.39 Purchase System.
class PurchaseRecord {
  const PurchaseRecord({
    required this.id,
    required this.creatorId,
    required this.productId,
    required this.price,
    required this.currency,
    this.paymentProvider,
    this.paymentSessionId,
  });

  final String id;
  final String creatorId;
  final String productId;
  final double price;
  final String currency;
  final String? paymentProvider;
  final String? paymentSessionId;
}

/// Step 44.40 Creator Revenue, 44.41 Revenue Sharing, 44.42 Creator Payout.
class CreatorRevenue {
  const CreatorRevenue({
    required this.creatorId,
    required this.totalEarnings,
    required this.totalPayout,
    this.lastPayoutAt,
  });

  final String creatorId;
  final double totalEarnings;
  final double totalPayout;
  final DateTime? lastPayoutAt;
}

/// Step 44.43 Free Products, 44.44 Trials.
class FreeProduct {
  const FreeProduct({
    required this.productId,
    required this.limit,
    this.conversionRate = 0.0,
  });

  final String productId;
  final int limit;
  final double conversionRate;
}

class TrialSubscription {
  const TrialSubscription({
    required this.productId,
    required this.creatorId,
    required this.days,
    this.converted = false,
  });

  final String productId;
  final String creatorId;
  final int days;
  final bool converted;
}
