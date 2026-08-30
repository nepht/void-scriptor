library price_wealth_inflation_model;

import 'currency_reference_basket.dart';

class EconomySource {
  const EconomySource._({required this.revision, required this.reason});

  final String revision;
  final String reason;

  factory EconomySource.validated({
    required String revision,
    required String reason,
  }) {
    _nonEmpty(revision, 'revision');
    _nonEmpty(reason, 'reason');
    return EconomySource._(revision: revision, reason: reason);
  }
}

class PriceHistoryEntry {
  const PriceHistoryEntry._({
    required this.id,
    required this.goodId,
    required this.currencyId,
    required this.amount,
    required this.tick,
    required this.locationId,
    required this.source,
  });

  final String id;
  final String goodId;
  final String currencyId;
  final double amount;
  final int tick;
  final String locationId;
  final EconomySource source;

  factory PriceHistoryEntry.validated({
    required String id,
    required String goodId,
    required String currencyId,
    required num amount,
    required int tick,
    required String locationId,
    required EconomySource source,
  }) {
    _nonEmpty(id, 'id');
    _nonEmpty(goodId, 'goodId');
    _nonEmpty(currencyId, 'currencyId');
    _positive(amount, 'amount');
    _nonNegativeTick(tick);
    _nonEmpty(locationId, 'locationId');
    _validateSource(source);
    return PriceHistoryEntry._(
      id: id,
      goodId: goodId,
      currencyId: currencyId,
      amount: amount.toDouble(),
      tick: tick,
      locationId: locationId,
      source: source,
    );
  }
}

enum WagePeriod { hour, day, week, month, year }

class WageHistoryEntry {
  const WageHistoryEntry._({
    required this.id,
    required this.occupationId,
    required this.currencyId,
    required this.amount,
    required this.period,
    required this.tick,
    required this.locationId,
    required this.source,
  });

  final String id;
  final String occupationId;
  final String currencyId;
  final double amount;
  final WagePeriod period;
  final int tick;
  final String locationId;
  final EconomySource source;

  factory WageHistoryEntry.validated({
    required String id,
    required String occupationId,
    required String currencyId,
    required num amount,
    required WagePeriod period,
    required int tick,
    required String locationId,
    required EconomySource source,
  }) {
    _nonEmpty(id, 'id');
    _nonEmpty(occupationId, 'occupationId');
    _nonEmpty(currencyId, 'currencyId');
    _positive(amount, 'amount');
    _nonNegativeTick(tick);
    _nonEmpty(locationId, 'locationId');
    _validateSource(source);
    return WageHistoryEntry._(
      id: id,
      occupationId: occupationId,
      currencyId: currencyId,
      amount: amount.toDouble(),
      period: period,
      tick: tick,
      locationId: locationId,
      source: source,
    );
  }
}

class WealthProfile {
  const WealthProfile._({
    required this.id,
    required this.ownerId,
    required this.currencyId,
    required this.assets,
    required this.liabilities,
    required this.tick,
    required this.source,
  });

  final String id;
  final String ownerId;
  final String currencyId;
  final double assets;
  final double liabilities;
  final int tick;
  final EconomySource source;

  double get netWorth => assets - liabilities;

  factory WealthProfile.validated({
    required String id,
    required String ownerId,
    required String currencyId,
    required num assets,
    required num liabilities,
    required int tick,
    required EconomySource source,
  }) {
    _nonEmpty(id, 'id');
    _nonEmpty(ownerId, 'ownerId');
    _nonEmpty(currencyId, 'currencyId');
    _nonNegative(assets, 'assets');
    _nonNegative(liabilities, 'liabilities');
    _nonNegativeTick(tick);
    _validateSource(source);
    return WealthProfile._(
      id: id,
      ownerId: ownerId,
      currencyId: currencyId,
      assets: assets.toDouble(),
      liabilities: liabilities.toDouble(),
      tick: tick,
      source: source,
    );
  }
}

class ScarcityEvent {
  const ScarcityEvent._({
    required this.id,
    required this.goodId,
    required this.locationId,
    required this.severityMultiplier,
    required this.validity,
    required this.reason,
    required this.source,
  });

  final String id;
  final String goodId;
  final String locationId;
  final double severityMultiplier;
  final ValidityRange validity;
  final String reason;
  final EconomySource source;

  factory ScarcityEvent.validated({
    required String id,
    required String goodId,
    required String locationId,
    required num severityMultiplier,
    required ValidityRange validity,
    required String reason,
    required EconomySource source,
  }) {
    _nonEmpty(id, 'id');
    _nonEmpty(goodId, 'goodId');
    _nonEmpty(locationId, 'locationId');
    _positive(severityMultiplier, 'severityMultiplier');
    _validateValidity(validity);
    _nonEmpty(reason, 'reason');
    _validateSource(source);
    return ScarcityEvent._(
      id: id,
      goodId: goodId,
      locationId: locationId,
      severityMultiplier: severityMultiplier.toDouble(),
      validity: validity,
      reason: reason,
      source: source,
    );
  }
}

class InflationComponent {
  const InflationComponent({
    required this.goodId,
    required this.basePrice,
    required this.currentPrice,
  });

  final String goodId;
  final double basePrice;
  final double currentPrice;

  double get ratio => currentPrice / basePrice;
}

class InflationIndex {
  const InflationIndex._({
    required this.currencyId,
    required this.locationId,
    required this.baseTick,
    required this.tick,
    required this.value,
    required this.components,
  });

  final String currencyId;
  final String locationId;
  final int baseTick;
  final int tick;
  final double value;
  final List<InflationComponent> components;

  double get changePercent => value - 100;
}

class PriceWealthInflationModel {
  const PriceWealthInflationModel._({
    required this.basket,
    required this.priceHistory,
    required this.wageHistory,
    required this.wealthProfiles,
    required this.scarcityEvents,
  });

  final CurrencyReferenceBasket basket;
  final List<PriceHistoryEntry> priceHistory;
  final List<WageHistoryEntry> wageHistory;
  final List<WealthProfile> wealthProfiles;
  final List<ScarcityEvent> scarcityEvents;

  factory PriceWealthInflationModel.validated({
    required CurrencyReferenceBasket basket,
    required List<PriceHistoryEntry> priceHistory,
    required List<WageHistoryEntry> wageHistory,
    required List<WealthProfile> wealthProfiles,
    required List<ScarcityEvent> scarcityEvents,
  }) {
    _uniqueIds(priceHistory.map((value) => value.id), 'price history');
    _uniqueIds(wageHistory.map((value) => value.id), 'wage history');
    _uniqueIds(wealthProfiles.map((value) => value.id), 'wealth profile');
    _uniqueIds(scarcityEvents.map((value) => value.id), 'scarcity event');

    for (final entry in priceHistory) {
      _requireGood(basket, entry.goodId);
      _requireCurrency(basket, entry.currencyId, entry.tick);
    }
    for (final entry in wageHistory) {
      _requireCurrency(basket, entry.currencyId, entry.tick);
    }
    for (final profile in wealthProfiles) {
      _requireCurrency(basket, profile.currencyId, profile.tick);
    }
    for (final event in scarcityEvents) {
      _requireGood(basket, event.goodId);
    }

    return PriceWealthInflationModel._(
      basket: basket,
      priceHistory: List.unmodifiable(priceHistory),
      wageHistory: List.unmodifiable(wageHistory),
      wealthProfiles: List.unmodifiable(wealthProfiles),
      scarcityEvents: List.unmodifiable(scarcityEvents),
    );
  }

  PriceHistoryEntry? priceAt({
    required String goodId,
    required String currencyId,
    required String locationId,
    required int tick,
  }) => _latestAt(
    priceHistory.where(
      (entry) =>
          entry.goodId == goodId &&
          entry.currencyId == currencyId &&
          entry.locationId == locationId &&
          entry.tick <= tick,
    ),
    (entry) => entry.tick,
    (entry) => entry.id,
  );

  WageHistoryEntry? wageAt({
    required String occupationId,
    required String currencyId,
    required String locationId,
    required int tick,
  }) => _latestAt(
    wageHistory.where(
      (entry) =>
          entry.occupationId == occupationId &&
          entry.currencyId == currencyId &&
          entry.locationId == locationId &&
          entry.tick <= tick,
    ),
    (entry) => entry.tick,
    (entry) => entry.id,
  );

  WealthProfile? wealthAt({required String ownerId, required int tick}) =>
      _latestAt(
        wealthProfiles.where(
          (profile) => profile.ownerId == ownerId && profile.tick <= tick,
        ),
        (profile) => profile.tick,
        (profile) => profile.id,
      );

  List<ScarcityEvent> scarcityAt({
    required String goodId,
    required String locationId,
    required int tick,
  }) {
    final matches =
        scarcityEvents
            .where(
              (event) =>
                  event.goodId == goodId &&
                  event.locationId == locationId &&
                  event.validity.contains(tick),
            )
            .toList()
          ..sort((left, right) => left.id.compareTo(right.id));
    return List.unmodifiable(matches);
  }

  InflationIndex inflationIndex({
    required String currencyId,
    required String locationId,
    required int baseTick,
    required int tick,
    required List<String> goodIds,
  }) {
    _nonEmpty(currencyId, 'currencyId');
    _nonEmpty(locationId, 'locationId');
    _nonNegativeTick(baseTick, name: 'baseTick');
    _nonNegativeTick(tick);
    if (tick < baseTick) {
      throw ArgumentError.value(tick, 'tick', 'must be >= baseTick');
    }
    if (goodIds.isEmpty) {
      throw ArgumentError.value(goodIds, 'goodIds', 'must not be empty');
    }
    _uniqueIds(goodIds, 'inflation good');

    final components = <InflationComponent>[];
    for (final goodId in goodIds) {
      _requireGood(basket, goodId);
      final base = priceAt(
        goodId: goodId,
        currencyId: currencyId,
        locationId: locationId,
        tick: baseTick,
      );
      final current = priceAt(
        goodId: goodId,
        currencyId: currencyId,
        locationId: locationId,
        tick: tick,
      );
      if (base == null || current == null) {
        throw StateError('missing price history for $goodId');
      }
      components.add(
        InflationComponent(
          goodId: goodId,
          basePrice: base.amount,
          currentPrice: current.amount,
        ),
      );
    }

    final ratioSum = components.fold<double>(
      0,
      (sum, component) => sum + component.ratio,
    );
    return InflationIndex._(
      currencyId: currencyId,
      locationId: locationId,
      baseTick: baseTick,
      tick: tick,
      value: ratioSum / components.length * 100,
      components: List.unmodifiable(components),
    );
  }
}

T? _latestAt<T>(
  Iterable<T> values,
  int Function(T value) tickOf,
  String Function(T value) idOf,
) {
  final sorted = values.toList()
    ..sort((left, right) {
      final byTick = tickOf(left).compareTo(tickOf(right));
      return byTick != 0 ? byTick : idOf(left).compareTo(idOf(right));
    });
  return sorted.isEmpty ? null : sorted.last;
}

void _requireGood(CurrencyReferenceBasket basket, String goodId) {
  if (basket.goodById(goodId) == null) {
    throw ArgumentError.value(goodId, 'goodId', 'unknown reference good');
  }
}

void _requireCurrency(
  CurrencyReferenceBasket basket,
  String currencyId,
  int tick,
) {
  if (basket.currencyAt(currencyId, tick) == null) {
    throw ArgumentError.value(
      currencyId,
      'currencyId',
      'currency is not active at tick $tick',
    );
  }
}

void _uniqueIds(Iterable<String> ids, String type) {
  final seen = <String>{};
  for (final id in ids) {
    _nonEmpty(id, '$type id');
    if (!seen.add(id)) {
      throw ArgumentError.value(id, type, 'duplicate id');
    }
  }
}

void _validateSource(EconomySource source) {
  _nonEmpty(source.revision, 'source revision');
  _nonEmpty(source.reason, 'source reason');
}

void _validateValidity(ValidityRange validity) {
  if (validity.fromTick < 0 ||
      (validity.untilTick != null && validity.untilTick! < validity.fromTick)) {
    throw ArgumentError.value(validity, 'validity', 'invalid range');
  }
}

void _nonEmpty(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, 'must be non-empty');
  }
}

void _positive(num value, String name) {
  if (!value.isFinite || value <= 0) {
    throw ArgumentError.value(value, name, 'must be finite and > 0');
  }
}

void _nonNegative(num value, String name) {
  if (!value.isFinite || value < 0) {
    throw ArgumentError.value(value, name, 'must be finite and >= 0');
  }
}

void _nonNegativeTick(int tick, {String name = 'tick'}) {
  if (tick < 0) {
    throw ArgumentError.value(tick, name, 'must be >= 0');
  }
}
