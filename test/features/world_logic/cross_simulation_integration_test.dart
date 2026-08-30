// Sprint 110.42 - Cross-Simulation Integration.
//
// Menghubungkan waktu, peta, perjalanan, tokoh, faksi, ekonomi, rumor,
// kekuatan, dan teknologi melalui contract stabil. Domain-only,
// deterministic, no persistence/UI/wall clock/locale/random/network.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/cross_simulation_integration.dart';
import 'package:void_scriptor/features/world_logic/domain/world_time_state_authority.dart';
import 'package:void_scriptor/features/world_logic/domain/temporal_map_state.dart';
import 'package:void_scriptor/features/world_logic/domain/route_network.dart';
import 'package:void_scriptor/features/world_logic/domain/rumor_propagation.dart';
import 'package:void_scriptor/features/world_logic/domain/power_usage_ledger.dart';
import 'package:void_scriptor/features/world_logic/domain/technology_node_prerequisite_model.dart';

void main() {
  group('Cross-Simulation Integration (110.42)', () {
    test(
      'shared_clock binds time, travel, events, and authority snapshots',
      () {
        final clock = WorldClock(initialTick: 100);
        final graph = RouteGraph(
          nodes: {
            'a': const RouteNode(id: 'a', name: 'A'),
            'b': const RouteNode(id: 'b', name: 'B'),
          },
          edges: [
            RouteEdge(
              id: 'a-b',
              fromId: 'a',
              toId: 'b',
              distance: 10,
              terrain: Terrain.plain,
            ),
          ],
        );
        final integration = CrossSimulationIntegration.withDefaults(
          clock: clock,
          graph: graph,
        );
        final initialTick = integration.currentTick;
        expect(initialTick, equals(100));
        integration.advanceTime(5);
        expect(integration.currentTick, equals(105));
        final revision = integration.sourceRevision;
        expect(revision, isNotEmpty);
        expect(revision, contains('clock:'));
      },
    );

    test(
      'shared_locations joins temporal map and route graph by stable id',
      () {
        final mapState = TemporalMapState(
          branchId: 'prime',
          locations: [
            TemporalLocation.validated(id: 'loc-a', name: 'A', validFrom: 0),
            TemporalLocation.validated(id: 'loc-b', name: 'B', validFrom: 0),
          ],
        );
        final graph = RouteGraph(
          nodes: {
            'loc-a': const RouteNode(id: 'loc-a', name: 'A'),
            'loc-b': const RouteNode(id: 'loc-b', name: 'B'),
          },
          edges: [
            RouteEdge(
              id: 'loc-a-loc-b',
              fromId: 'loc-a',
              toId: 'loc-b',
              distance: 10,
              terrain: Terrain.plain,
            ),
          ],
        );
        final integration = CrossSimulationIntegration.withDefaults(
          mapState: mapState,
          graph: graph,
        );
        final resolved = integration.resolveLocation('loc-b', 0);
        expect(resolved.locationId, equals('loc-b'));
        expect(resolved.matchedRouteNodeId, equals('loc-b'));
        expect(resolved.isActive, isTrue);
      },
    );

    test('event_links expose provenance chain across all subsystems', () {
      final integration = CrossSimulationIntegration.withDefaults();
      final link = integration.linkEvent(
        eventId: 'evt-1',
        tick: 5,
        participants: const ['char-1', 'faction-1'],
      );
      expect(link.eventId, equals('evt-1'));
      expect(link.tick, equals(5));
      expect(link.participants, containsAll(['char-1', 'faction-1']));
      expect(link.sourceRevision, isNotEmpty);
      final chain = integration.provenanceFor(link.eventId);
      expect(chain.tick, equals(5));
      expect(chain.eventId, equals('evt-1'));
    });

    test('no_circular_ownership rejects nested ownership cycles', () {
      final integration = CrossSimulationIntegration.withDefaults();
      expect(
        () => integration.declareOwnership(const [
          OwnershipEdge(ownerId: 'A', ownedId: 'B'),
          OwnershipEdge(ownerId: 'B', ownedId: 'C'),
          OwnershipEdge(ownerId: 'C', ownedId: 'A'),
        ]),
        throwsA(isA<CircularOwnershipException>()),
      );
    });

    test('graceful_partial_failure reports missing subsystems as partial', () {
      final integration = CrossSimulationIntegration.withDefaults();
      final report = integration.healthCheck();
      expect(report.clockReady, isTrue);
      expect(report.mapReady, isFalse);
      expect(report.routeReady, isFalse);
      expect(report.factionsReady, isFalse);
      expect(report.partial, isTrue);
      expect(report.missingSubsystems, isNotEmpty);
      final factions = integration.factions();
      expect(factions.isPartial, isTrue);
      expect(factions.reason, contains('factions'));
    });

    test('integration composes rumor, power, and technology links', () {
      final integration = CrossSimulationIntegration.withDefaults();
      integration.registerRumorSeed(
        RumorSeed.validated(
          id: 'seed-1',
          summary: 'A great fire burned in the north.',
          origin: const RumorOrigin(personId: 'char-1'),
          tick: 12,
          source: const RumorSource(revision: 'r1', reason: 'witnessed'),
        ),
      );
      integration.registerPowerEvent(
        PowerUsageEvent.validated(
          id: 'pow-1',
          abilityId: 'fireball',
          actorId: 'char-1',
          sceneId: 'scene-1',
          tick: 12,
          source: PowerUsageSource.validated(
            revision: 'r2',
            reason: 'combat log',
          ),
        ),
      );
      integration.registerTechnology(
        TechnologyNode.validated(
          id: 'tech-fire',
          name: 'Fire craft',
          tier: 1,
          source: TechnologySource.validated(revision: 'r3', reason: 'scholar'),
        ),
      );
      integration.linkEvent(
        eventId: 'scene-1',
        tick: 12,
        participants: const ['char-1', 'tech-fire'],
      );
      final report = integration.composeNarrativeSlice(tick: 12);
      expect(report.tick, equals(12));
      expect(report.linkedEvents, contains('scene-1'));
      expect(report.linkedRumors, contains('seed-1'));
      expect(report.linkedPowers, contains('pow-1'));
      expect(report.linkedTechnologies, contains('tech-fire'));
    });
  });
}
