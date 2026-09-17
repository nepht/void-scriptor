import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/economy_technology_civilization_integration.dart';

void main() {
  const source = CivilizationSource(revision: 'rev-112.19', reason: 'fixture');

  test('resource dependencies and production scale are evaluated together', () {
    final result = const EconomyTechnologyCivilizationIntegration().evaluate(
      resources: const [
        CivilizationResource(id: 'iron', available: 6, source: source),
      ],
      production: const CivilizationProduction(
        id: 'forge',
        outputId: 'steel',
        scale: 3,
        requiredResources: {'iron': 2},
        capacity: 2,
        source: source,
      ),
      prices: const [],
      technologies: const [],
      tradeLinks: const [],
      era: const CivilizationEra(
        id: 'era-1',
        startTick: 0,
        endTick: 10,
        source: source,
      ),
      atTick: 5,
    );

    expect(result.resourceDependenciesSatisfied, isTrue);
    expect(
      result.findings.map((f) => f.kind),
      contains(CivilizationFindingKind.productionScale),
    );
  });

  test('price effects and trade effects are deterministic at a tick', () {
    final result = const EconomyTechnologyCivilizationIntegration().evaluate(
      resources: const [],
      production: null,
      prices: const [
        CivilizationPriceEffect(
          goodId: 'grain',
          multiplier: 2,
          validFrom: 0,
          validUntil: 10,
          source: source,
        ),
      ],
      technologies: const [],
      tradeLinks: const [
        CivilizationTradeEffect(
          id: 'trade-1',
          fromFactionId: 'a',
          toFactionId: 'b',
          commodity: 'grain',
          quantity: 5,
          validFrom: 0,
          validUntil: 10,
          source: source,
        ),
      ],
      era: const CivilizationEra(
        id: 'era-1',
        startTick: 0,
        endTick: 10,
        source: source,
      ),
      atTick: 5,
    );

    expect(result.activePriceEffects.single.multiplier, 2);
    expect(result.activeTradeEffects.single.quantity, 5);
  });

  test('technology prerequisites and era boundaries produce findings', () {
    final result = const EconomyTechnologyCivilizationIntegration().evaluate(
      resources: const [],
      production: null,
      prices: const [],
      technologies: const [
        CivilizationTechnology(
          id: 'steam',
          prerequisites: ['coal'],
          discoveredAt: 8,
          source: source,
        ),
      ],
      tradeLinks: const [],
      era: const CivilizationEra(
        id: 'era-1',
        startTick: 0,
        endTick: 4,
        source: source,
      ),
      atTick: 5,
    );

    expect(
      result.findings.map((f) => f.kind),
      containsAll(<CivilizationFindingKind>[
        CivilizationFindingKind.technologyPrerequisite,
        CivilizationFindingKind.era,
      ]),
    );
  });
}
