library;

import 'price_wealth_inflation_model.dart';

/// Coarse wealth bracket for narrative loot-impact analysis.
/// Order is significant: low < middle < high < legendary.
enum WealthTier { low, middle, high, legendary }

/// Severity of deviation between story transaction price and canon price.
enum PriceWarningKind { extremeMarkup, extremeMarkdown, severeUnknown }

/// One canonical assumption captured for explainability.
class AssumptionEntry {
  const AssumptionEntry({
    required this.kind,
    required this.label,
    required this.source,
  });

  final String kind;
  final String label;
  final EconomySource source;
}

/// A consolidated explainability bundle attached to a query.
class AssumptionBreakdown {
  const AssumptionBreakdown({required this.assumptions});

  final List<AssumptionEntry> assumptions;
}

/// Result of  for a single story transaction.
class ValueComparison {
  const ValueComparison({
    required this.goodId,
    required this.currencyId,
    required this.locationId,
    required this.tick,
    required this.storyPrice,
    required this.canonPrice,
    required this.priceEntry,
  });

  final String goodId;
  final String currencyId;
  final String locationId;
  final int tick;
  final double storyPrice;
  final double canonPrice;
  final PriceHistoryEntry priceEntry;

  double get ratio => storyPrice / canonPrice;
  double get difference => storyPrice - canonPrice;
}

/// Result of  query: how many units of a good a
/// given owner can buy with their canon net worth at the tick.
class PurchasingPower {
  const PurchasingPower({
    required this.ownerId,
    required this.ownerNetWorth,
    required this.goodId,
    required this.goodPrice,
    required this.unitsAcquirable,
  });

  final String ownerId;
  final double ownerNetWorth;
  final String goodId;
  final double goodPrice;
  final int unitsAcquirable;
}

/// Result of a loot-impact analysis (before / after wealth tiers).
class LootImpact {
  const LootImpact({
    required this.ownerId,
    required this.previousNetWorth,
    required this.projectedNetWorth,
    required this.lootAmount,
    required this.tierBefore,
    required this.tierAfter,
  });

  final String ownerId;
  final double previousNetWorth;
  final double projectedNetWorth;
  final double lootAmount;
  final WealthTier tierBefore;
  final WealthTier tierAfter;

  bool get tierChange => tierBefore != tierAfter;
}

/// Optional warning attached to a transaction when the price deviation
/// falls outside the configured tolerance ratio.
class PriceWarning {
  const PriceWarning({required this.kind, required this.message});

  final PriceWarningKind kind;
  final String message;
}

class PriceWarningResult {
  const PriceWarningResult({this.warning});

  final PriceWarning? warning;
}

/// Public writer-facing economy calculator. Domain-only, deterministic,
/// no persistence / no UI / no wall clock / no random / no network.
/// Consumes the [PriceWealthInflationModel] from sprint 110.34.
class WriterEconomyCalculator {
  const WriterEconomyCalculator({
    required this.model,
    this.toleranceRatio = 1.5,
  }) : assert(toleranceRatio >= 1.0);

  final PriceWealthInflationModel model;

  /// Maximum story-vs-canon ratio before a [PriceWarning] is raised.
  /// 1.5 (default) means story prices above 1.5x or below 1/1.5 of
  /// canon trigger the warning.
  final double toleranceRatio;

  /// Compare a story price against the canon price at the tick.
  ValueComparison compareValue({
    required String goodId,
    required String currencyId,
    required String locationId,
    required int tick,
    required num storyPrice,
  }) {
    _requireNonEmpty(goodId, 'goodId');
    _requireNonEmpty(currencyId, 'currencyId');
    _requireNonEmpty(locationId, 'locationId');
    if (tick < 0) {
      throw ArgumentError.value(tick, 'tick', 'must be >= 0');
    }
    if (!storyPrice.isFinite || storyPrice < 0) {
      throw ArgumentError.value(
        storyPrice,
        'storyPrice',
        'must be finite and >= 0',
      );
    }
    final entry = model.priceAt(
      goodId: goodId,
      currencyId: currencyId,
      locationId: locationId,
      tick: tick,
    );
    if (entry == null) {
      throw StateError('no canon price for $goodId at tick $tick');
    }
    return ValueComparison(
      goodId: goodId,
      currencyId: currencyId,
      locationId: locationId,
      tick: tick,
      storyPrice: storyPrice.toDouble(),
      canonPrice: entry.amount,
      priceEntry: entry,
    );
  }

  /// Resolve how many units of a good the owner can buy with their
  /// canon net worth at the tick.
  PurchasingPower purchasingPower({
    required String ownerId,
    required int tick,
    required String goodId,
    required String currencyId,
    required String locationId,
  }) {
    _requireNonEmpty(ownerId, 'ownerId');
    _requireNonEmpty(goodId, 'goodId');
    _requireNonEmpty(currencyId, 'currencyId');
    _requireNonEmpty(locationId, 'locationId');
    if (tick < 0) {
      throw ArgumentError.value(tick, 'tick', 'must be >= 0');
    }
    final profile = model.wealthAt(ownerId: ownerId, tick: tick);
    if (profile == null) {
      throw StateError('no wealth profile for $ownerId at tick $tick');
    }
    final price = model.priceAt(
      goodId: goodId,
      currencyId: currencyId,
      locationId: locationId,
      tick: tick,
    );
    if (price == null) {
      throw StateError('no canon price for $goodId');
    }
    final units = price.amount <= 0
        ? 0
        : (profile.netWorth / price.amount).floor();
    return PurchasingPower(
      ownerId: ownerId,
      ownerNetWorth: profile.netWorth,
      goodId: goodId,
      goodPrice: price.amount,
      unitsAcquirable: units,
    );
  }

  /// Quantify how a loot amount shifts the owner across the wealth ladder.
  LootImpact lootImpact({
    required String ownerId,
    required int tick,
    required num lootAmount,
    required String currencyId,
  }) {
    _requireNonEmpty(ownerId, 'ownerId');
    _requireNonEmpty(currencyId, 'currencyId');
    if (tick < 0) {
      throw ArgumentError.value(tick, 'tick', 'must be >= 0');
    }
    if (!lootAmount.isFinite || lootAmount < 0) {
      throw ArgumentError.value(
        lootAmount,
        'lootAmount',
        'must be finite and >= 0',
      );
    }
    final profile = model.wealthAt(ownerId: ownerId, tick: tick);
    if (profile == null) {
      throw StateError('no wealth profile for $ownerId at tick $tick');
    }
    final projected = profile.netWorth + lootAmount.toDouble();
    final before = _tierFor(profile.netWorth);
    final after = _tierFor(projected);
    return LootImpact(
      ownerId: ownerId,
      previousNetWorth: profile.netWorth,
      projectedNetWorth: projected,
      lootAmount: lootAmount.toDouble(),
      tierBefore: before,
      tierAfter: after,
    );
  }

  /// Evaluate whether a transaction price deviation falls outside the
  /// tolerance. Returns a [PriceWarningResult] with an optional warning.
  PriceWarningResult evaluatePriceWarning({
    required ValueComparison comparison,
  }) {
    final canon = comparison.canonPrice;
    final story = comparison.storyPrice;
    if (canon <= 0) {
      return const PriceWarningResult();
    }
    final ratio = story / canon;
    if (ratio >= toleranceRatio) {
      return PriceWarningResult(
        warning: PriceWarning(
          kind: PriceWarningKind.extremeMarkup,
          message: 'story price $story exceeds ${toleranceRatio}x canon $canon',
        ),
      );
    }
    if (ratio <= 1 / toleranceRatio) {
      return PriceWarningResult(
        warning: PriceWarning(
          kind: PriceWarningKind.extremeMarkdown,
          message:
              'story price $story below ${1 / toleranceRatio}x canon $canon',
        ),
      );
    }
    return const PriceWarningResult();
  }

  /// Expose every canonical assumption used to answer the comparison.
  /// Currently: the price-entry provenance used by [compareValue].
  AssumptionBreakdown assumptionBreakdown({
    required ValueComparison comparison,
  }) {
    final entry = comparison.priceEntry;
    return AssumptionBreakdown(
      assumptions: [
        AssumptionEntry(
          kind: 'price',
          label: 'price history for ${entry.goodId} at tick ${entry.tick}',
          source: entry.source,
        ),
      ],
    );
  }

  /// Bucket [value] into a coarse narrative tier.
  WealthTier _tierFor(double value) {
    if (value < 500) return WealthTier.low;
    if (value < 10000) return WealthTier.middle;
    if (value < 100000) return WealthTier.high;
    return WealthTier.legendary;
  }
}

void _requireNonEmpty(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'must be non-empty');
  }
}
