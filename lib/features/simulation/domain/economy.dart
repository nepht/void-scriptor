/// Sprint 46 — Step 46.33–46.42 Economy, Resources, Trade.
class EconomyEngine {
  const EconomyEngine({
    required this.basePrice,
    required this.supplyElasticity,
  });

  final double basePrice;
  final double supplyElasticity;

  double priceFor({required double supply, required double demand}) {
    final ratio = demand / (supply + 1);
    return basePrice * (ratio * supplyElasticity + 0.5);
  }
}

class Goods {
  const Goods({required this.id, required this.name, required this.quantity});

  final String id;
  final String name;
  final double quantity;
}

class TradeRoute {
  const TradeRoute({
    required this.id,
    required this.fromSettlementId,
    required this.toSettlementId,
    required this.distanceKm,
    required this.averageSpeedKmph,
    this.disrupted = false,
  });

  final String id;
  final String fromSettlementId;
  final String toSettlementId;
  final int distanceKm;
  final int averageSpeedKmph;
  final bool disrupted;

  double get travelHours => distanceKm / averageSpeedKmph;
}

class ResourceState {
  const ResourceState({
    required this.id,
    required this.resourceId,
    required this.settlementId,
    required this.amount,
  });

  final String id;
  final String resourceId;
  final String settlementId;
  final double amount;

  ResourceState depleted() => ResourceState(
    id: id,
    resourceId: resourceId,
    settlementId: settlementId,
    amount: 0,
  );
}
