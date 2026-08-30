import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/currency_reference_basket.dart';
import 'package:void_scriptor/features/world_logic/domain/price_wealth_inflation_model.dart';
import 'package:void_scriptor/features/world_logic/domain/writer_economy_calculator.dart';

void main() {
  const active = ValidityRange(fromTick: 0, untilTick: 100);

  EconomySource src(String r) =>
      EconomySource.validated(revision: 'canon-r1', reason: r);

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
      ReferenceUnit.validated(
        id: 'day',
        name: 'Day Wage',
        symbol: 'day',
        category: 'time',
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
        id: 'horse',
        name: 'Horse',
        unitId: 'item',
        prices: const [],
      ),
    ],
  );

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
        source: src('canon'),
      ),
      PriceHistoryEntry.validated(
        id: 'bread-10',
        goodId: 'bread',
        currencyId: 'crown',
        amount: 3,
        tick: 10,
        locationId: 'capital',
        source: src('canon'),
      ),
      PriceHistoryEntry.validated(
        id: 'horse-5',
        goodId: 'horse',
        currencyId: 'crown',
        amount: 50,
        tick: 5,
        locationId: 'capital',
        source: src('canon'),
      ),
    ],
    wageHistory: [
      WageHistoryEntry.validated(
        id: 'wage-laborer-0',
        occupationId: 'laborer',
        currencyId: 'crown',
        amount: 4,
        period: WagePeriod.day,
        tick: 0,
        locationId: 'capital',
        source: src('canon'),
      ),
      WageHistoryEntry.validated(
        id: 'wage-laborer-10',
        occupationId: 'laborer',
        currencyId: 'crown',
        amount: 6,
        period: WagePeriod.day,
        tick: 10,
        locationId: 'capital',
        source: src('canon'),
      ),
    ],
    wealthProfiles: [
      WealthProfile.validated(
        id: 'poor-0',
        ownerId: 'beggar',
        currencyId: 'crown',
        assets: 5,
        liabilities: 0,
        tick: 0,
        source: src('canon'),
      ),
      WealthProfile.validated(
        id: 'middle-0',
        ownerId: 'merchant',
        currencyId: 'crown',
        assets: 500,
        liabilities: 0,
        tick: 0,
        source: src('canon'),
      ),
      WealthProfile.validated(
        id: 'rich-0',
        ownerId: 'lord',
        currencyId: 'crown',
        assets: 50000,
        liabilities: 0,
        tick: 0,
        source: src('canon'),
      ),
    ],
    scarcityEvents: const [],
  );

  group('Writer Economy Calculator', () {
    test(
      'value_comparison returns canon price ratio for a story transaction',
      () {
        final calc = WriterEconomyCalculator(model: model());
        final comparison = calc.compareValue(
          goodId: 'bread',
          currencyId: 'crown',
          locationId: 'capital',
          tick: 10,
          storyPrice: 6,
        );
        expect(comparison.canonPrice, 3);
        expect(comparison.storyPrice, 6);
        expect(comparison.ratio, closeTo(2.0, 1e-9));
        expect(comparison.difference, 3);
      },
    );

    test('purchasing_power resolves how much of a basket a wealth can buy', () {
      final calc = WriterEconomyCalculator(model: model());
      final power = calc.purchasingPower(
        ownerId: 'merchant',
        tick: 0,
        goodId: 'bread',
        currencyId: 'crown',
        locationId: 'capital',
      );
      expect(power.unitsAcquirable, 250);
      expect(power.ownerNetWorth, 500);
      expect(power.goodPrice, 2);
    });

    test('loot_impact quantifies shift in owner wealth vs wealth ladder', () {
      final calc = WriterEconomyCalculator(model: model());
      final impact = calc.lootImpact(
        ownerId: 'beggar',
        tick: 0,
        lootAmount: 100,
        currencyId: 'crown',
      );
      expect(impact.previousNetWorth, 5);
      expect(impact.projectedNetWorth, 105);
      expect(impact.tierBefore, WealthTier.low);
      expect(impact.tierAfter, WealthTier.low);
      expect(impact.tierChange, isFalse);
    });

    test('loot_impact promotes owner across a wealth tier', () {
      final calc = WriterEconomyCalculator(model: model());
      final impact = calc.lootImpact(
        ownerId: 'beggar',
        tick: 0,
        lootAmount: 600,
        currencyId: 'crown',
      );
      expect(impact.tierBefore, WealthTier.low);
      expect(impact.tierAfter, WealthTier.middle);
      expect(impact.tierChange, isTrue);
    });

    test('price_warning flags transaction deviant beyond tolerance', () {
      final calc = WriterEconomyCalculator(
        model: model(),
        toleranceRatio: 1.25,
      );
      final clean = calc.compareValue(
        goodId: 'bread',
        currencyId: 'crown',
        locationId: 'capital',
        tick: 10,
        storyPrice: 3,
      );
      final cleanResult = calc.evaluatePriceWarning(comparison: clean);
      expect(cleanResult.warning, isNull);

      final off = calc.compareValue(
        goodId: 'bread',
        currencyId: 'crown',
        locationId: 'capital',
        tick: 10,
        storyPrice: 10,
      );
      final flagged = calc.evaluatePriceWarning(comparison: off);
      expect(flagged.warning, isNotNull);
      expect(flagged.warning!.kind, PriceWarningKind.extremeMarkup);
    });

    test(
      'price_warning flags deep discount below tolerance as extremeMarkdown',
      () {
        final calc = WriterEconomyCalculator(
          model: model(),
          toleranceRatio: 1.25,
        );
        final off = calc.compareValue(
          goodId: 'bread',
          currencyId: 'crown',
          locationId: 'capital',
          tick: 10,
          storyPrice: 1,
        );
        final result = calc.evaluatePriceWarning(comparison: off);
        expect(result.warning, isNotNull);
        expect(result.warning!.kind, PriceWarningKind.extremeMarkdown);
      },
    );

    test('assumption_breakdown exposes every canon source used', () {
      final calc = WriterEconomyCalculator(model: model());
      final comparison = calc.compareValue(
        goodId: 'bread',
        currencyId: 'crown',
        locationId: 'capital',
        tick: 10,
        storyPrice: 3,
      );
      final breakdown = calc.assumptionBreakdown(comparison: comparison);
      expect(breakdown.assumptions, isNotEmpty);
      for (final entry in breakdown.assumptions) {
        expect(entry.source.revision, 'canon-r1');
        expect(entry.source.reason, isNotEmpty);
      }
      expect(breakdown.assumptions.any((a) => a.kind == 'price'), isTrue);
    });

    test('value_comparison fails when canon has no price at the tick', () {
      final calc = WriterEconomyCalculator(model: model());
      expect(
        () => calc.compareValue(
          goodId: 'bread',
          currencyId: 'crown',
          locationId: 'capital',
          tick: -1,
          storyPrice: 1,
        ),
        throwsArgumentError,
      );
    });

    test('purchasing_power fails cleanly when owner has no profile', () {
      final calc = WriterEconomyCalculator(model: model());
      expect(
        () => calc.purchasingPower(
          ownerId: 'ghost',
          tick: 0,
          goodId: 'bread',
          currencyId: 'crown',
          locationId: 'capital',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
