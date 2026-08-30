import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/currency_reference_basket.dart';

void main() {
  const active = ValidityRange(fromTick: 0, untilTick: 100);

  CurrencyDefinition crown() => CurrencyDefinition.validated(
    id: 'crown',
    name: 'Crown',
    symbol: 'CR',
    validity: active,
  );

  CurrencyDefinition mark() => CurrencyDefinition.validated(
    id: 'mark',
    name: 'Mark',
    symbol: 'MK',
    validity: active,
  );

  CurrencyReferenceBasket basket() => CurrencyReferenceBasket.validated(
    currencies: [crown(), mark()],
    denominations: [
      CurrencyDenomination.validated(
        id: 'silver-crown',
        currencyId: 'crown',
        name: 'Silver Crown',
        value: 0.1,
        validity: active,
      ),
    ],
    exchangeRates: [
      CurrencyExchangeRate.validated(
        fromCurrencyId: 'crown',
        toCurrencyId: 'mark',
        rate: 2,
        validity: active,
      ),
    ],
    units: [
      ReferenceUnit.validated(
        id: 'loaf',
        name: 'Loaf',
        symbol: 'loaf',
        category: 'food',
      ),
    ],
    goods: [
      ReferenceGood.validated(
        id: 'bread',
        name: 'Bread',
        unitId: 'loaf',
        prices: [
          ReferenceGoodPrice.validated(
            currencyId: 'crown',
            amount: 0.5,
            validity: active,
          ),
        ],
      ),
    ],
  );

  test('currencies resolve only inside their validity range', () {
    final value = basket();

    expect(value.currencyAt('crown', 20)?.symbol, 'CR');
    expect(value.currencyAt('crown', 101), isNull);
  });

  test('denominations preserve positive value and currency ownership', () {
    final values = basket().denominationsFor('crown', 10);

    expect(values.single.id, 'silver-crown');
    expect(values.single.value, 0.1);
    expect(values.single.currencyId, 'crown');
  });

  test('exchange rates convert deterministically at a selected tick', () {
    expect(basket().convert(amount: 3, from: 'crown', to: 'mark', tick: 8), 6);
  });

  test('units are available to reference goods', () {
    final value = basket();

    expect(value.unitById('loaf')?.category, 'food');
    expect(value.goodById('bread')?.unitId, 'loaf');
  });

  test('reference goods expose a time-aware price basket', () {
    final value = basket();

    expect(value.referencePrice('bread', currencyId: 'crown', tick: 50), 0.5);
    expect(
      value.referencePrice('bread', currencyId: 'crown', tick: 101),
      isNull,
    );
  });

  test('validation rejects invalid ranges, values, and missing references', () {
    expect(
      () => ValidityRange.validated(fromTick: 5, untilTick: 4),
      throwsArgumentError,
    );
    expect(
      () => CurrencyDenomination.validated(
        id: 'bad',
        currencyId: 'crown',
        name: 'Bad',
        value: 0,
        validity: active,
      ),
      throwsArgumentError,
    );
    expect(
      () => CurrencyReferenceBasket.validated(
        currencies: [crown()],
        denominations: const [],
        exchangeRates: const [],
        units: const [],
        goods: [
          ReferenceGood.validated(
            id: 'bread',
            name: 'Bread',
            unitId: 'missing-unit',
            prices: const [],
          ),
        ],
      ),
      throwsArgumentError,
    );
  });
}
