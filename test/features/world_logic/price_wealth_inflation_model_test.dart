import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/currency_reference_basket.dart';
import 'package:void_scriptor/features/world_logic/domain/price_wealth_inflation_model.dart';

void main() {
  const active = ValidityRange(fromTick: 0, untilTick: 100);

  CurrencyReferenceBasket basket() => CurrencyReferenceBasket.validated(
    currencies: [
      CurrencyDefinition.validated(
        id: 'crown',
        name: 'Crown',
        symbol: 'CR',
        validity: active,
      ),
    ],
    denominations: const [],
    exchangeRates: const [],
    units: [
      ReferenceUnit.validated(
        id: 'item',
        name: 'Item',
        symbol: 'item',
        category: 'count',
      ),
    ],
    goods: [
      ReferenceGood.validated(
        id: 'bread',
        name: 'Bread',
        unitId: 'item',
        prices: const [],
      ),
      ReferenceGood.validated(
        id: 'oil',
        name: 'Lamp Oil',
        unitId: 'item',
        prices: const [],
      ),
    ],
  );

  EconomySource source(String reason) =>
      EconomySource.validated(revision: 'canon-r1', reason: reason);

  PriceWealthInflationModel model() => PriceWealthInflationModel.validated(
    basket: basket(),
    priceHistory: [
      PriceHistoryEntry.validated(
        id: 'bread-0',
        goodId: 'bread',
        currencyId: 'crown',
        amount: 2,
        tick: 0,
        locationId: 'capital',
        source: source('market ledger'),
      ),
      PriceHistoryEntry.validated(
        id: 'bread-10',
        goodId: 'bread',
        currencyId: 'crown',
        amount: 3,
        tick: 10,
        locationId: 'capital',
        source: source('market ledger'),
      ),
      PriceHistoryEntry.validated(
        id: 'oil-0',
        goodId: 'oil',
        currencyId: 'crown',
        amount: 4,
        tick: 0,
        locationId: 'capital',
        source: source('merchant book'),
      ),
      PriceHistoryEntry.validated(
        id: 'oil-10',
        goodId: 'oil',
        currencyId: 'crown',
        amount: 8,
        tick: 10,
        locationId: 'capital',
        source: source('merchant book'),
      ),
    ],
    wageHistory: [
      WageHistoryEntry.validated(
        id: 'scribe-8',
        occupationId: 'scribe',
        currencyId: 'crown',
        amount: 12,
        period: WagePeriod.day,
        tick: 8,
        locationId: 'capital',
        source: source('guild payroll'),
      ),
    ],
    wealthProfiles: [
      WealthProfile.validated(
        id: 'mira-5',
        ownerId: 'mira',
        currencyId: 'crown',
        assets: 100,
        liabilities: 25,
        tick: 5,
        source: source('estate inventory'),
      ),
    ],
    scarcityEvents: [
      ScarcityEvent.validated(
        id: 'bread-shortage',
        goodId: 'bread',
        locationId: 'capital',
        severityMultiplier: 1.8,
        validity: const ValidityRange(fromTick: 7, untilTick: 12),
        reason: 'harvest failure',
        source: source('harvest report'),
      ),
    ],
  );

  test('price history resolves latest price by good, place, and tick', () {
    final entry = model().priceAt(
      goodId: 'bread',
      currencyId: 'crown',
      locationId: 'capital',
      tick: 9,
    );

    expect(entry?.id, 'bread-0');
    expect(entry?.amount, 2);
    expect(entry?.source.reason, 'market ledger');
  });

  test('wage history resolves an occupation wage at a selected tick', () {
    final entry = model().wageAt(
      occupationId: 'scribe',
      currencyId: 'crown',
      locationId: 'capital',
      tick: 10,
    );

    expect(entry?.amount, 12);
    expect(entry?.period, WagePeriod.day);
  });

  test('wealth profiles expose assets, liabilities, and net worth', () {
    final profile = model().wealthAt(ownerId: 'mira', tick: 6);

    expect(profile?.assets, 100);
    expect(profile?.liabilities, 25);
    expect(profile?.netWorth, 75);
  });

  test('scarcity events are time- and location-aware', () {
    final events = model().scarcityAt(
      goodId: 'bread',
      locationId: 'capital',
      tick: 10,
    );

    expect(events.single.id, 'bread-shortage');
    expect(events.single.severityMultiplier, 1.8);
    expect(
      model().scarcityAt(goodId: 'bread', locationId: 'capital', tick: 20),
      isEmpty,
    );
  });

  test('inflation index compares a deterministic reference basket', () {
    final index = model().inflationIndex(
      currencyId: 'crown',
      locationId: 'capital',
      baseTick: 0,
      tick: 10,
      goodIds: const ['bread', 'oil'],
    );

    expect(index.value, 175);
    expect(index.changePercent, 75);
    expect(index.components.map((value) => value.goodId), ['bread', 'oil']);
  });

  test('validation rejects unknown references and invalid numeric values', () {
    expect(
      () => PriceHistoryEntry.validated(
        id: 'bad',
        goodId: 'bread',
        currencyId: 'crown',
        amount: 0,
        tick: 0,
        locationId: 'capital',
        source: source('invalid record'),
      ),
      throwsArgumentError,
    );
    expect(
      () => PriceWealthInflationModel.validated(
        basket: basket(),
        priceHistory: [
          PriceHistoryEntry.validated(
            id: 'missing',
            goodId: 'unknown-good',
            currencyId: 'crown',
            amount: 2,
            tick: 0,
            locationId: 'capital',
            source: source('invalid reference'),
          ),
        ],
        wageHistory: const [],
        wealthProfiles: const [],
        scarcityEvents: const [],
      ),
      throwsArgumentError,
    );
  });
}
