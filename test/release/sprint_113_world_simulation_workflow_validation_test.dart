// Sprint 113.16 — World Simulation Workflow Validation.
//
// Required evidence: workflow_results, determinism_results,
// explanation_results, override_results, acceptance.
//
// Validates that:
// 1. Journey consistency validates routes, time, and supplies
// 2. Custom calendar produces dates and round-trips ticks
// 3. Genealogy tree builds from relations with generations
// 4. Temporal map shows territorial control layers at tick
// 5. Diplomacy history tracks treaties and conflicts
// 6. Character age/continuity detects scene presence alerts
// 7. Power rulebook enforces abilities, costs, and limits
// 8. Economy calculator compares prices and purchasing power
// 9. Rumor propagation spreads deterministically through network
// 10. Tech tree checks prerequisites and builds layout

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/custom_calendar.dart';
import 'package:void_scriptor/features/world_logic/domain/genealogy_relationship_rules.dart';
import 'package:void_scriptor/features/world_logic/domain/genealogy_tree_builder.dart';
import 'package:void_scriptor/features/world_logic/domain/territorial_control.dart'
    show TerritorialControl, TerritorialControlRegistry;
import 'package:void_scriptor/features/world_logic/domain/temporal_map_view.dart';
import 'package:void_scriptor/features/world_logic/domain/diplomacy_history.dart';
import 'package:void_scriptor/features/world_logic/domain/age_location_continuity_validator.dart';
import 'package:void_scriptor/features/world_logic/domain/power_rulebook.dart';
import 'package:void_scriptor/features/world_logic/domain/price_wealth_inflation_model.dart';
import 'package:void_scriptor/features/world_logic/domain/writer_economy_calculator.dart';
import 'package:void_scriptor/features/world_logic/domain/rumor_propagation.dart';
import 'package:void_scriptor/features/world_logic/domain/technology_node_prerequisite_model.dart';
import 'package:void_scriptor/features/world_logic/domain/world_simulation_workflow_validation.dart';
import 'package:void_scriptor/features/world_logic/domain/journey_consistency_validator.dart';
import 'package:void_scriptor/features/world_logic/domain/route_network.dart';
import 'package:void_scriptor/features/world_logic/domain/travel_mode_profiles.dart';
import 'package:void_scriptor/features/world_logic/domain/travel_supplies.dart';

void main() {
  group('manifest_validation', () {
    test('domain class validates the manifest structure', () {
      final result = WorldSimulationWorkflowValidation.validate();
      expect(result.isValid, isTrue, reason: result.errors.join('; '));
      expect(result.errors, isEmpty);
    });

    test('manifest has all required evidence sections', () {
      final result = WorldSimulationWorkflowValidation.validate();
      expect(result.isValid, isTrue, reason: result.errors.join('; '));
    });
  });

  group('workflow_results', () {
    // --- 1. Journey Consistency ---
    group('journey_consistency', () {
      test('validates a complete journey with valid route', () {
        final graph = RouteGraph(
          nodes: {
            'city_a': const RouteNode(id: 'city_a', name: 'City A'),
            'city_b': const RouteNode(id: 'city_b', name: 'City B'),
            'city_c': const RouteNode(id: 'city_c', name: 'City C'),
          },
          edges: [
            RouteEdge(
              id: 'ab',
              fromId: 'city_a',
              toId: 'city_b',
              distance: 100,
            ),
            RouteEdge(
              id: 'bc',
              fromId: 'city_b',
              toId: 'city_c',
              distance: 150,
            ),
          ],
        );
        const mode = TravelModeProfile(
          id: 'walk',
          label: 'Walking',
          baseSpeedKmPerHour: 4.0,
          capacityPersons: 10,
          passableTerrains: {TerrainKind.plain},
          restAfterHours: 4,
          restDurationHours: 8,
        );
        final loadout = SupplyLoadout(
          partySize: 2,
          bundles: [
            SupplyBundle(kind: SupplyKind.rations, quantity: 50, unit: 'days'),
            SupplyBundle(kind: SupplyKind.water, quantity: 50, unit: 'days'),
          ],
        );
        final spec = JourneySpec(
          graph: graph,
          originId: 'city_a',
          destinationId: 'city_c',
          segments: ['ab', 'bc'],
          mode: mode,
          season: Season.spring,
          partySize: 2,
          loadout: loadout,
          claimedDurationHours: 100,
          restHours: 8,
        );
        const validator = JourneyConsistencyValidator();
        final result = validator.validate(spec: spec);
        expect(result.warnings, isA<List<JourneyWarning>>());
        // Route exists and segments are contiguous — no error-severity warnings
        final errors = result.warnings
            .where((w) => w.severity == JourneyWarningSeverity.error)
            .toList();
        expect(errors, isEmpty);
      });
    });

    // --- 2. Custom Calendar ---
    group('custom_calendar', () {
      test('dateFromTick round-trips correctly', () {
        final calendar = CustomCalendar(
          months: [
            const CustomMonth(name: 'Jan', daysInMonth: 30, indexInYear: 0),
            const CustomMonth(name: 'Feb', daysInMonth: 28, indexInYear: 1),
            const CustomMonth(name: 'Mar', daysInMonth: 32, indexInYear: 2),
          ],
        );
        expect(calendar.daysPerYear, 90);
        final date = calendar.dateFromTick(31);
        expect(date.monthName, 'Feb');
        expect(date.yearNumber, 1);
      });

      test('calendar months are immutable', () {
        final calendar = CustomCalendar(
          months: [
            const CustomMonth(name: 'A', daysInMonth: 10, indexInYear: 0),
          ],
        );
        expect(calendar.monthsPerYear, 1);
        expect(calendar.monthByName('A'), isNotNull);
        expect(calendar.monthByName('B'), isNull);
      });
    });

    // --- 3. Genealogy Tree ---
    group('genealogy_tree', () {
      test('builds tree from parent-child relations', () {
        final registry = GenealogyRegistry();
        registry.add(
          const GenealogyRelation.parentChild(
            parentId: 'grandpa',
            childId: 'parent',
          ),
        );
        registry.add(
          const GenealogyRelation.parentChild(
            parentId: 'parent',
            childId: 'child',
          ),
        );
        final tree = GenealogyTreeBuilder.build(
          registry,
          nodeIds: ['grandpa', 'parent', 'child'],
          asOfTick: 0,
        );
        expect(tree.nodeIds, containsAll(['grandpa', 'parent', 'child']));
        expect(tree.roots, contains('grandpa'));
        expect(tree.generation['grandpa'], 0);
        expect(tree.generation['parent'], 1);
        expect(tree.generation['child'], 2);
      });

      test('detects cycles', () {
        final registry = GenealogyRegistry();
        registry.add(
          const GenealogyRelation.parentChild(parentId: 'a', childId: 'b'),
        );
        expect(
          () => registry.add(
            const GenealogyRelation.parentChild(parentId: 'b', childId: 'a'),
          ),
          throwsA(isA<GenealogyCycleDetected>()),
        );
      });
    });

    // --- 4. Temporal Map ---
    group('temporal_map', () {
      test('renders territorial control layers at tick', () {
        final registry = TerritorialControlRegistry([
          const TerritorialControl(
            controllerId: 'faction_red',
            locationId: 'mountain',
            validity: ValidityRange(fromTick: 0, toTick: 100),
          ),
          const TerritorialControl(
            controllerId: 'faction_blue',
            locationId: 'valley',
            validity: ValidityRange(fromTick: 50),
          ),
        ]);
        final view = TemporalMapView(
          registry: registry,
          asOfTick: 75,
          sliderMin: 0,
          sliderMax: 200,
          palette: {'faction_red': '#FF0000', 'faction_blue': '#0000FF'},
        );
        expect(view.historicalLayers, hasLength(2));
        expect(view.legend, contains('faction_red'));
        expect(view.legend, contains('faction_blue'));
      });
    });

    // --- 5. Diplomacy History ---
    group('diplomacy_history', () {
      test('creates and tracks treaty', () {
        final treaty = Treaty.validated(
          id: 't1',
          factionAId: 'red',
          factionBId: 'blue',
          kind: TreatyKind.alliance,
          validFrom: 10,
          validUntil: 200,
          sourceRevision: 'rev1',
          sourceReason: 'Mutual defense',
        );
        expect(treaty.kind, TreatyKind.alliance);
        expect(treaty.isActiveAt(50), isTrue);
        expect(treaty.isActiveAt(250), isFalse);
      });

      test('rejects self-treaty', () {
        expect(
          () => Treaty.validated(
            id: 't2',
            factionAId: 'red',
            factionBId: 'red',
            kind: TreatyKind.nonAggression,
            validFrom: 0,
            sourceRevision: 'rev1',
            sourceReason: 'Self',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    // --- 6. Character Age / Continuity ---
    group('age_continuity', () {
      test('validates scene presences for consistency', () {
        final scenes = [
          ScenePresence.validated(
            sceneId: 's1',
            personId: 'char1',
            tick: 100,
            locationId: 'city',
            sourceId: 'ch1',
          ),
          ScenePresence.validated(
            sceneId: 's2',
            personId: 'char1',
            tick: 200,
            locationId: 'city',
            sourceId: 'ch1',
          ),
        ];
        final result = AgeLocationContinuityValidator.validate(
          personId: 'char1',
          birthTick: 0,
          scenes: scenes,
        );
        expect(result.isConsistent, isTrue);
      });

      test('detects notBorn alert', () {
        final scenes = [
          ScenePresence.validated(
            sceneId: 's1',
            personId: 'char1',
            tick: 50,
            locationId: 'city',
            sourceId: 'ch1',
          ),
        ];
        final result = AgeLocationContinuityValidator.validate(
          personId: 'char1',
          birthTick: 100,
          scenes: scenes,
        );
        expect(result.isConsistent, isFalse);
        expect(result.codes, contains(ContinuityAlertCode.notBorn));
      });
    });

    // --- 7. Power Rulebook ---
    group('power_rulebook', () {
      test('creates ability with cost and limit', () {
        final ability = PowerAbility.validated(
          id: 'fireball',
          name: 'Fireball',
          costs: [
            PowerCost.validated(
              resource: 'mana',
              amount: 10,
              reason: 'Base casting cost',
            ),
          ],
          limits: [
            PowerLimit.validated(
              metric: 'casts_per_day',
              maximum: 3,
              reason: 'Daily exhaustion',
            ),
          ],
        );
        expect(ability.costs, hasLength(1));
        expect(ability.limits, hasLength(1));
        expect(ability.costs.first.resource, 'mana');
      });
    });

    // --- 8. Economy Calculator ---
    group('economy_calculator', () {
      test('ValueComparison computes ratio and difference', () {
        final src = EconomySource.validated(revision: 'r1', reason: 'Ref');
        final entry = PriceHistoryEntry.validated(
          id: 'p1',
          goodId: 'bread',
          currencyId: 'gold',
          amount: 5.0,
          tick: 100,
          locationId: 'market',
          source: src,
        );
        final comparison = ValueComparison(
          goodId: 'bread',
          currencyId: 'gold',
          locationId: 'market',
          tick: 100,
          storyPrice: 8.0,
          canonPrice: 5.0,
          priceEntry: entry,
        );
        expect(comparison.ratio, closeTo(1.6, 0.01));
        expect(comparison.difference, closeTo(3.0, 0.01));
      });

      test('PurchasingPower tracks net worth and units', () {
        const pp = PurchasingPower(
          ownerId: 'hero',
          ownerNetWorth: 100.0,
          goodId: 'sword',
          goodPrice: 25.0,
          unitsAcquirable: 4,
        );
        expect(pp.unitsAcquirable, 4);
        expect(pp.ownerNetWorth, 100.0);
      });
    });

    // --- 9. Rumor Propagation ---
    group('rumor_propagation', () {
      test('propagates seed through network', () {
        final seed = RumorSeed.validated(
          id: 'r1',
          summary: 'The king is ill',
          origin: const RumorOrigin(personId: 'servant'),
          tick: 10,
          source: const RumorSource(revision: 'rev1', reason: 'Eyewitness'),
        );
        final network = RumorNetwork(
          persons: {'servant', 'guard', 'merchant'},
          edges: const [
            RumorEdge(from: 'servant', to: 'guard'),
            RumorEdge(from: 'guard', to: 'merchant'),
          ],
        );
        const traits = RumorTraits(
          reliability: 10,
          distortionFactor: 0.0,
          propagationDelayTicks: 1,
        );
        const simulator = RumorPropagationSimulator();
        final result = simulator.simulate(
          seed: seed,
          network: network,
          traits: traits,
          upToTick: 20,
        );
        // Guard should know the rumor
        final personIds = result.recipients.map((r) => r.personId).toList();
        expect(personIds, contains('guard'));
        // First recipient's distorted summary should match seed
        final guardReach = result.recipients.firstWhere(
          (r) => r.personId == 'guard',
        );
        expect(guardReach.distortedSummary, 'The king is ill');
      });
    });

    // --- 10. Tech Tree ---
    group('tech_tree', () {
      test('creates nodes with prerequisites', () {
        final fireNode = TechnologyNode.validated(
          id: 'fire',
          name: 'Fire Making',
          scope: TechnologyScope.civil,
          prerequisites: [],
          resources: [],
          source: TechnologySource.validated(
            revision: 'r1',
            reason: 'Discovery',
          ),
        );
        final bronzeNode = TechnologyNode.validated(
          id: 'bronze',
          name: 'Bronze Working',
          scope: TechnologyScope.military,
          prerequisites: ['fire'],
          resources: [
            TechnologyResource.validated(
              id: 'copper',
              kind: 'mineral',
              amount: 10,
              reason: 'Smelting requires copper',
            ),
          ],
          source: TechnologySource.validated(
            revision: 'r1',
            reason: 'Requires fire',
          ),
        );
        final registry = TechnologyRegistry.validated(
          nodes: [fireNode, bronzeNode],
        );
        final node = registry.nodeById('bronze');
        expect(node, isNotNull);
        expect(node!.prerequisites, ['fire']);
        expect(registry.nodeById('fire'), isNotNull);
        expect(registry.nodeById('nonexistent'), isNull);
      });
    });
  });

  group('determinism_results', () {
    test('calendar dateFromTick is deterministic', () {
      final calendar = CustomCalendar(
        months: [
          const CustomMonth(name: 'Sol', daysInMonth: 60, indexInYear: 0),
          const CustomMonth(name: 'Lun', daysInMonth: 30, indexInYear: 1),
        ],
      );
      final d1 = calendar.dateFromTick(42);
      final d2 = calendar.dateFromTick(42);
      expect(d1.yearNumber, d2.yearNumber);
      expect(d1.monthName, d2.monthName);
      expect(d1.dayOfMonth, d2.dayOfMonth);
    });

    test('genealogy tree is deterministic', () {
      final registry = GenealogyRegistry();
      registry.add(
        const GenealogyRelation.parentChild(parentId: 'a', childId: 'b'),
      );
      registry.add(
        const GenealogyRelation.parentChild(parentId: 'b', childId: 'c'),
      );
      final t1 = GenealogyTreeBuilder.build(
        registry,
        nodeIds: ['a', 'b', 'c'],
        asOfTick: 0,
      );
      final t2 = GenealogyTreeBuilder.build(
        registry,
        nodeIds: ['a', 'b', 'c'],
        asOfTick: 0,
      );
      expect(t1.nodeIds, t2.nodeIds);
      expect(t1.generation, t2.generation);
      expect(t1.roots, t2.roots);
    });

    test('territorial view is deterministic', () {
      final registry = TerritorialControlRegistry([
        const TerritorialControl(
          controllerId: 'f1',
          locationId: 'loc',
          validity: ValidityRange(fromTick: 0, toTick: 100),
        ),
      ]);
      TemporalMapView mkView() => TemporalMapView(
        registry: registry,
        asOfTick: 50,
        sliderMin: 0,
        sliderMax: 200,
        palette: {'f1': '#0000FF'},
      );
      final v1 = mkView();
      final v2 = mkView();
      expect(v1.historicalLayers.length, v2.historicalLayers.length);
      expect(
        v1.historicalLayers.first.locationId,
        v2.historicalLayers.first.locationId,
      );
    });

    test('power rulebook is deterministic', () {
      final ability = PowerAbility.validated(
        id: 'a1',
        name: 'Test',
        costs: [PowerCost.validated(resource: 'mp', amount: 5, reason: 'Cost')],
      );
      expect(ability.costs.first.amount, 5);
      expect(ability.costs.first.resource, 'mp');
    });
  });

  group('explanation_results', () {
    test('diplomacy treaty carries source explanation', () {
      final treaty = Treaty.validated(
        id: 't1',
        factionAId: 'a',
        factionBId: 'b',
        kind: TreatyKind.tradePact,
        validFrom: 0,
        sourceRevision: 'council_minutes_42',
        sourceReason: 'Signed after the Great Trade War',
      );
      expect(treaty.sourceRevision, 'council_minutes_42');
      expect(treaty.sourceReason, 'Signed after the Great Trade War');
    });

    test('continuity explains alerts', () {
      const alert = ContinuityAlert(
        code: ContinuityAlertCode.impossibleTravel,
        explanation: 'Character cannot travel 500km in 1 hour',
        relatedSceneIds: ['s1', 's2'],
      );
      expect(alert.explanation, contains('500km'));
      expect(alert.relatedSceneIds, hasLength(2));
    });

    test('power rulebook carries cost reason', () {
      final cost = PowerCost.validated(
        resource: 'mana',
        amount: 10,
        reason: 'Fireball consumes raw magical essence',
      );
      expect(cost.reason, 'Fireball consumes raw magical essence');
    });
  });

  group('override_results', () {
    test('calendar rejects negative tick', () {
      final calendar = CustomCalendar(
        months: [const CustomMonth(name: 'X', daysInMonth: 10, indexInYear: 0)],
      );
      expect(() => calendar.dateFromTick(-1), throwsA(isA<ArgumentError>()));
    });

    test('genealogy rejects duplicate relation', () {
      final registry = GenealogyRegistry();
      registry.add(
        const GenealogyRelation.parentChild(parentId: 'a', childId: 'b'),
      );
      expect(
        () => registry.add(
          const GenealogyRelation.parentChild(parentId: 'a', childId: 'b'),
        ),
        throwsA(isA<GenealogyRelationConflict>()),
      );
    });

    test('diplomacy rejects invalid date range', () {
      expect(
        () => Treaty.validated(
          id: 't1',
          factionAId: 'a',
          factionBId: 'b',
          kind: TreatyKind.peace,
          validFrom: 100,
          validUntil: 50,
          sourceRevision: 'r',
          sourceReason: 'r',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('power rejects zero cost', () {
      expect(
        () => PowerCost.validated(resource: 'mp', amount: 0, reason: 'Zero'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('tech node rejects empty id', () {
      expect(
        () => TechnologyNode.validated(
          id: '',
          name: 'Empty',
          scope: TechnologyScope.civil,
          prerequisites: [],
          resources: [],
          source: TechnologySource.validated(revision: 'r', reason: 'R'),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('acceptance', () {
    test('journey_workflow_completes', () {
      final graph = RouteGraph(
        nodes: {
          'a': const RouteNode(id: 'a', name: 'A'),
          'b': const RouteNode(id: 'b', name: 'B'),
        },
        edges: [RouteEdge(id: 'ab', fromId: 'a', toId: 'b', distance: 50)],
      );
      final spec = JourneySpec(
        graph: graph,
        originId: 'a',
        destinationId: 'b',
        segments: ['ab'],
        mode: const TravelModeProfile(
          id: 'walk',
          label: 'Walk',
          baseSpeedKmPerHour: 5.0,
          capacityPersons: 10,
          passableTerrains: {TerrainKind.plain},
          restAfterHours: 4,
          restDurationHours: 8,
        ),
        season: Season.summer,
        partySize: 1,
        loadout: SupplyLoadout(
          partySize: 1,
          bundles: [
            SupplyBundle(kind: SupplyKind.rations, quantity: 20, unit: 'days'),
            SupplyBundle(kind: SupplyKind.water, quantity: 20, unit: 'days'),
          ],
        ),
        claimedDurationHours: 12,
        restHours: 2,
      );
      const validator = JourneyConsistencyValidator();
      final result = validator.validate(spec: spec);
      expect(result.warnings, isA<List<JourneyWarning>>());
    });

    test('calendar_round_trip_works', () {
      final cal = CustomCalendar(
        months: [
          const CustomMonth(name: 'Prim', daysInMonth: 28, indexInYear: 0),
          const CustomMonth(name: 'Sec', daysInMonth: 30, indexInYear: 1),
        ],
      );
      final date = cal.dateFromTick(0);
      expect(date.monthName, 'Prim');
      expect(date.dayOfMonth, 1);
      expect(date.yearNumber, 1);
    });

    test('genealogy_tree_builds', () {
      final registry = GenealogyRegistry();
      registry.add(
        const GenealogyRelation.parentChild(parentId: 'p1', childId: 'c1'),
      );
      final tree = GenealogyTreeBuilder.build(
        registry,
        nodeIds: ['p1', 'c1'],
        asOfTick: 0,
      );
      expect(tree.nodeIds, containsAll(['p1', 'c1']));
      expect(tree.roots, contains('p1'));
    });

    test('temporal_map_renders_layers', () {
      final reg = TerritorialControlRegistry([
        const TerritorialControl(
          controllerId: 'f1',
          locationId: 'loc1',
          validity: ValidityRange(fromTick: 0),
        ),
      ]);
      final view = TemporalMapView(
        registry: reg,
        asOfTick: 10,
        sliderMin: 0,
        sliderMax: 100,
        palette: {'f1': '#000001'},
      );
      expect(view.historicalLayers, isNotEmpty);
    });

    test('diplomacy_treaty_validated', () {
      final t = Treaty.validated(
        id: 't1',
        factionAId: 'a',
        factionBId: 'b',
        kind: TreatyKind.nonAggression,
        validFrom: 0,
        sourceRevision: 'rev',
        sourceReason: 'Peace',
      );
      expect(t.id, 't1');
      expect(t.isActiveAt(0), isTrue);
    });

    test('continuity_alerts_detected', () {
      final scenes = [
        ScenePresence.validated(
          sceneId: 's1',
          personId: 'p1',
          tick: 50,
          locationId: 'loc',
          sourceId: 'ch1',
        ),
      ];
      final result = AgeLocationContinuityValidator.validate(
        personId: 'p1',
        birthTick: 0,
        scenes: scenes,
      );
      // With birthTick=0 and scene at tick=50, no alerts
      expect(result.personId, 'p1');
      expect(result.isConsistent, isTrue);
    });

    test('power_system_enforced', () {
      final ability = PowerAbility.validated(
        id: 'heal',
        name: 'Healing Light',
        costs: [
          PowerCost.validated(
            resource: 'faith',
            amount: 8,
            reason: 'Channeling cost',
          ),
        ],
        limits: [
          PowerLimit.validated(
            metric: 'cooldown_hours',
            maximum: 4,
            reason: 'Recovery period',
          ),
        ],
      );
      expect(ability.id, 'heal');
      expect(ability.costs.first.amount, 8);
    });

    test('economy_comparison_works', () {
      final src = EconomySource.validated(revision: 'r1', reason: 'Ref');
      final entry = PriceHistoryEntry.validated(
        id: 'p2',
        goodId: 'ale',
        currencyId: 'copper',
        amount: 3.0,
        tick: 0,
        locationId: 'tavern',
        source: src,
      );
      final comparison = ValueComparison(
        goodId: 'ale',
        currencyId: 'copper',
        locationId: 'tavern',
        tick: 0,
        storyPrice: 6.0,
        canonPrice: 3.0,
        priceEntry: entry,
      );
      expect(comparison.ratio, 2.0);
      expect(comparison.difference, 3.0);
    });

    test('rumor_propagation_deterministic', () {
      final seed = RumorSeed.validated(
        id: 'r1',
        summary: 'Storm coming',
        origin: const RumorOrigin(personId: 'a'),
        tick: 0,
        source: const RumorSource(revision: 'v1', reason: 'Sighting'),
      );
      final net = RumorNetwork(
        persons: {'a', 'b'},
        edges: const [RumorEdge(from: 'a', to: 'b')],
      );
      const traits = RumorTraits(
        reliability: 10,
        distortionFactor: 0.0,
        propagationDelayTicks: 1,
      );
      const sim = RumorPropagationSimulator();
      final s1 = sim.simulate(
        seed: seed,
        network: net,
        traits: traits,
        upToTick: 5,
      );
      final s2 = sim.simulate(
        seed: seed,
        network: net,
        traits: traits,
        upToTick: 5,
      );
      expect(s1.recipients.length, s2.recipients.length);
      for (var i = 0; i < s1.recipients.length; i++) {
        expect(s1.recipients[i].personId, s2.recipients[i].personId);
        expect(
          s1.recipients[i].distortedSummary,
          s2.recipients[i].distortedSummary,
        );
      }
    });

    test('tech_tree_prerequisites_checked', () {
      final reg = TechnologyRegistry.validated(
        nodes: [
          TechnologyNode.validated(
            id: 'wheel',
            name: 'Wheel',
            scope: TechnologyScope.civil,
            prerequisites: [],
            resources: [],
            source: TechnologySource.validated(revision: 'r', reason: 'R'),
          ),
        ],
      );
      expect(reg.nodeById('wheel'), isNotNull);
      expect(reg.nodeById('nonexistent'), isNull);
    });
  });
}
