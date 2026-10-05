library;

class ValidityRange {
  const ValidityRange({required this.fromTick, this.untilTick});

  final int fromTick;
  final int? untilTick;

  factory ValidityRange.validated({required int fromTick, int? untilTick}) {
    if (fromTick < 0) {
      throw ArgumentError.value(fromTick, 'fromTick', 'must be >= 0');
    }
    if (untilTick != null && untilTick < fromTick) {
      throw ArgumentError.value(untilTick, 'untilTick', 'must be >= fromTick');
    }
    return ValidityRange(fromTick: fromTick, untilTick: untilTick);
  }

  bool contains(int tick) =>
      tick >= fromTick && (untilTick == null || tick <= untilTick!);
}

class CurrencyDefinition {
  const CurrencyDefinition._({
    required this.id,
    required this.name,
    required this.symbol,
    required this.validity,
  });

  final String id;
  final String name;
  final String symbol;
  final ValidityRange validity;

  factory CurrencyDefinition.validated({
    required String id,
    required String name,
    required String symbol,
    required ValidityRange validity,
  }) {
    _nonEmpty(id, 'id');
    _nonEmpty(name, 'name');
    _nonEmpty(symbol, 'symbol');
    _validateRange(validity);
    return CurrencyDefinition._(
      id: id,
      name: name,
      symbol: symbol,
      validity: validity,
    );
  }
}

class CurrencyDenomination {
  const CurrencyDenomination._({
    required this.id,
    required this.currencyId,
    required this.name,
    required this.value,
    required this.validity,
  });

  final String id;
  final String currencyId;
  final String name;
  final double value;
  final ValidityRange validity;

  factory CurrencyDenomination.validated({
    required String id,
    required String currencyId,
    required String name,
    required num value,
    required ValidityRange validity,
  }) {
    _nonEmpty(id, 'id');
    _nonEmpty(currencyId, 'currencyId');
    _nonEmpty(name, 'name');
    _positive(value, 'value');
    _validateRange(validity);
    return CurrencyDenomination._(
      id: id,
      currencyId: currencyId,
      name: name,
      value: value.toDouble(),
      validity: validity,
    );
  }
}

class CurrencyExchangeRate {
  const CurrencyExchangeRate._({
    required this.fromCurrencyId,
    required this.toCurrencyId,
    required this.rate,
    required this.validity,
  });

  final String fromCurrencyId;
  final String toCurrencyId;
  final double rate;
  final ValidityRange validity;

  factory CurrencyExchangeRate.validated({
    required String fromCurrencyId,
    required String toCurrencyId,
    required num rate,
    required ValidityRange validity,
  }) {
    _nonEmpty(fromCurrencyId, 'fromCurrencyId');
    _nonEmpty(toCurrencyId, 'toCurrencyId');
    if (fromCurrencyId == toCurrencyId) {
      throw ArgumentError('exchange currencies must differ');
    }
    _positive(rate, 'rate');
    _validateRange(validity);
    return CurrencyExchangeRate._(
      fromCurrencyId: fromCurrencyId,
      toCurrencyId: toCurrencyId,
      rate: rate.toDouble(),
      validity: validity,
    );
  }
}

class ReferenceUnit {
  const ReferenceUnit._({
    required this.id,
    required this.name,
    required this.symbol,
    required this.category,
  });

  final String id;
  final String name;
  final String symbol;
  final String category;

  factory ReferenceUnit.validated({
    required String id,
    required String name,
    required String symbol,
    required String category,
  }) {
    _nonEmpty(id, 'id');
    _nonEmpty(name, 'name');
    _nonEmpty(symbol, 'symbol');
    _nonEmpty(category, 'category');
    return ReferenceUnit._(
      id: id,
      name: name,
      symbol: symbol,
      category: category,
    );
  }
}

class ReferenceGoodPrice {
  const ReferenceGoodPrice._({
    required this.currencyId,
    required this.amount,
    required this.validity,
  });

  final String currencyId;
  final double amount;
  final ValidityRange validity;

  factory ReferenceGoodPrice.validated({
    required String currencyId,
    required num amount,
    required ValidityRange validity,
  }) {
    _nonEmpty(currencyId, 'currencyId');
    _positive(amount, 'amount');
    _validateRange(validity);
    return ReferenceGoodPrice._(
      currencyId: currencyId,
      amount: amount.toDouble(),
      validity: validity,
    );
  }
}

class ReferenceGood {
  const ReferenceGood._({
    required this.id,
    required this.name,
    required this.unitId,
    required this.prices,
  });

  final String id;
  final String name;
  final String unitId;
  final List<ReferenceGoodPrice> prices;

  factory ReferenceGood.validated({
    required String id,
    required String name,
    required String unitId,
    required List<ReferenceGoodPrice> prices,
  }) {
    _nonEmpty(id, 'id');
    _nonEmpty(name, 'name');
    _nonEmpty(unitId, 'unitId');
    return ReferenceGood._(
      id: id,
      name: name,
      unitId: unitId,
      prices: List.unmodifiable(prices),
    );
  }
}

class CurrencyReferenceBasket {
  const CurrencyReferenceBasket._({
    required this.currencies,
    required this.denominations,
    required this.exchangeRates,
    required this.units,
    required this.goods,
  });

  final List<CurrencyDefinition> currencies;
  final List<CurrencyDenomination> denominations;
  final List<CurrencyExchangeRate> exchangeRates;
  final List<ReferenceUnit> units;
  final List<ReferenceGood> goods;

  factory CurrencyReferenceBasket.validated({
    required List<CurrencyDefinition> currencies,
    required List<CurrencyDenomination> denominations,
    required List<CurrencyExchangeRate> exchangeRates,
    required List<ReferenceUnit> units,
    required List<ReferenceGood> goods,
  }) {
    final currencyIds = _uniqueIds(
      currencies.map((value) => value.id),
      'currency',
    );
    _uniqueIds(denominations.map((value) => value.id), 'denomination');
    final unitIds = _uniqueIds(units.map((value) => value.id), 'unit');
    _uniqueIds(goods.map((value) => value.id), 'good');

    for (final denomination in denominations) {
      _requireReference(currencyIds, denomination.currencyId, 'currency');
    }
    for (final rate in exchangeRates) {
      _requireReference(currencyIds, rate.fromCurrencyId, 'from currency');
      _requireReference(currencyIds, rate.toCurrencyId, 'to currency');
    }
    for (final good in goods) {
      _requireReference(unitIds, good.unitId, 'unit');
      for (final price in good.prices) {
        _requireReference(currencyIds, price.currencyId, 'price currency');
      }
    }

    return CurrencyReferenceBasket._(
      currencies: List.unmodifiable(currencies),
      denominations: List.unmodifiable(denominations),
      exchangeRates: List.unmodifiable(exchangeRates),
      units: List.unmodifiable(units),
      goods: List.unmodifiable(goods),
    );
  }

  CurrencyDefinition? currencyAt(String id, int tick) {
    for (final currency in currencies) {
      if (currency.id == id && currency.validity.contains(tick)) {
        return currency;
      }
    }
    return null;
  }

  List<CurrencyDenomination> denominationsFor(String currencyId, int tick) =>
      List.unmodifiable(
        denominations.where(
          (value) =>
              value.currencyId == currencyId && value.validity.contains(tick),
        ),
      );

  double convert({
    required num amount,
    required String from,
    required String to,
    required int tick,
  }) {
    if (!amount.isFinite || amount < 0) {
      throw ArgumentError.value(amount, 'amount', 'must be finite and >= 0');
    }
    if (currencyAt(from, tick) == null || currencyAt(to, tick) == null) {
      throw StateError('currency is not active at tick $tick');
    }
    if (from == to) return amount.toDouble();
    for (final rate in exchangeRates) {
      if (rate.fromCurrencyId == from &&
          rate.toCurrencyId == to &&
          rate.validity.contains(tick)) {
        return amount * rate.rate;
      }
    }
    throw StateError('no exchange rate for $from -> $to at tick $tick');
  }

  ReferenceUnit? unitById(String id) {
    for (final unit in units) {
      if (unit.id == id) return unit;
    }
    return null;
  }

  ReferenceGood? goodById(String id) {
    for (final good in goods) {
      if (good.id == id) return good;
    }
    return null;
  }

  double? referencePrice(
    String goodId, {
    required String currencyId,
    required int tick,
  }) {
    if (currencyAt(currencyId, tick) == null) return null;
    final good = goodById(goodId);
    if (good == null) return null;
    for (final price in good.prices) {
      if (price.currencyId == currencyId && price.validity.contains(tick)) {
        return price.amount;
      }
    }
    return null;
  }
}

Set<String> _uniqueIds(Iterable<String> ids, String type) {
  final result = <String>{};
  for (final id in ids) {
    _nonEmpty(id, '$type id');
    if (!result.add(id)) {
      throw ArgumentError.value(id, type, 'duplicate id');
    }
  }
  return result;
}

void _requireReference(Set<String> ids, String id, String type) {
  if (!ids.contains(id)) {
    throw ArgumentError.value(id, type, 'unknown reference');
  }
}

void _validateRange(ValidityRange range) {
  if (range.fromTick < 0 ||
      (range.untilTick != null && range.untilTick! < range.fromTick)) {
    throw ArgumentError('invalid validity range');
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
