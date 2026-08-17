import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/simulation/domain/faction.dart';
import 'package:void_scriptor/features/simulation/domain/economy.dart';
import 'package:void_scriptor/features/simulation/domain/settlement.dart';

void main() {
  group('FactionState', () {
    test('holds faction influence and relation', () {
      final f = FactionState(
        id: 'f1',
        worldId: 'w1',
        name: 'Order of the Shard',
        influence: 0.7,
        goals: ['Expand territory', 'Seal the void rifts'],
      );
      expect(f.influence, 0.7);
      expect(f.goals, hasLength(2));
    });
  });

  group('GovernmentModel', () {
    test('exposes canonical government types', () {
      expect(GovernmentModel.values.map((e) => e.name), [
        'autocracy',
        'oligarchy',
        'democracy',
        'theocracy',
        'meritocracy',
        'anarchy',
      ]);
    });
  });

  group('EconomyEngine', () {
    test('computes price from supply and demand', () {
      const engine = EconomyEngine(basePrice: 10.0, supplyElasticity: 0.5);
      final price = engine.priceFor(supply: 20, demand: 10);
      expect(price, lessThan(10.0));
      expect(price, greaterThan(0));
    });

    test('scarcity raises price', () {
      const engine = EconomyEngine(basePrice: 10.0, supplyElasticity: 0.5);
      final price = engine.priceFor(supply: 5, demand: 20);
      expect(price, greaterThan(10.0));
    });
  });

  group('TradeRoute', () {
    test('computes travel time by distance and speed', () {
      const route = TradeRoute(
        id: 'r1',
        fromSettlementId: 'a',
        toSettlementId: 'b',
        distanceKm: 100,
        averageSpeedKmph: 20,
      );
      expect(route.travelHours, 5.0);
    });
  });

  group('Settlement', () {
    test('holds settlement population and districts', () {
      const city = Settlement(
        id: 'c1',
        name: 'Aethelburg',
        population: 50000,
        districts: ['Market', 'Harbor', 'Citadel'],
      );
      expect(city.name, 'Aethelburg');
      expect(city.districts, hasLength(3));
    });
  });

  group('WeatherZone', () {
    test('holds weather state', () {
      const zone = WeatherZone(
        id: 'z1',
        region: 'Northern Wastes',
        condition: WeatherCondition.blizzard,
      );
      expect(zone.condition, WeatherCondition.blizzard);
    });
  });

  group('CreaturePopulation', () {
    test('tracks population and balance', () {
      final pop = CreaturePopulation(
        id: 'p1',
        speciesId: 'sp1',
        eco: EcosystemState(id: 'e1', worldId: 'w1', balance: 0.8),
        count: 1000,
      );
      expect(pop.count, 1000);
      expect(pop.eco.balance, 0.8);
    });
  });
}
