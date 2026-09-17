import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/faction_diplomacy.dart';
import 'package:void_scriptor/features/world_logic/domain/faction_diplomacy_rumor_integration.dart';
import 'package:void_scriptor/features/world_logic/domain/faction_relationship_matrix.dart';
import 'package:void_scriptor/features/world_logic/domain/rumor_propagation.dart';

void main() {
  group('Sprint 112.18 Faction, Diplomacy & Rumor Integration', () {
    final diplomacy = FactionDiplomacyEntry.validated(
      id: 'pact-1',
      fromFactionId: 'north',
      toFactionId: 'south',
      publicKind: FactionRelationKind.neutral,
      publicIntensity: 1,
      secretKind: FactionRelationKind.ally,
      secretIntensity: 9,
      validFrom: 10,
      validUntil: 30,
      secretKnownBy: const ['north', 'spymaster'],
      sourceRevision: 'rev-1',
      sourceReason: 'sealed treaty',
    );

    final scenario = FactionDiplomacyRumorScenario(
      diplomacy: [diplomacy],
      events: const [
        FactionDiplomacyEvent(
          id: 'event-1',
          factionId: 'south',
          tick: 20,
          description: 'the treaty is announced',
        ),
      ],
      knowledgeByFaction: const {
        'north': {'event-1'},
        'south': {'event-1'},
      },
      rumorSeed: const RumorSeed(
        id: 'rumor-1',
        summary: 'the north has an ally',
        origin: RumorOrigin(personId: 'scout', factionId: 'north'),
        tick: 20,
        source: RumorSource(revision: 'rev-1', reason: 'scout report'),
      ),
      rumorNetwork: RumorNetwork(
        persons: const {'scout', 'merchant', 'captain'},
        edges: const [
          RumorEdge(from: 'scout', to: 'merchant'),
          RumorEdge(from: 'merchant', to: 'captain'),
        ],
      ),
    );

    test(
      'diplomacy_at_time and secret_clearance expose only permitted stance',
      () {
        final result = const FactionDiplomacyRumorIntegration().evaluate(
          scenario,
          atTick: 20,
          observerId: 'south',
        );
        expect(result.activeDiplomacy.single.id, 'pact-1');
        expect(result.visibleStance('south')?.kind, FactionRelationKind.ally);
        expect(
          result.visibleStance('outsider')?.kind,
          FactionRelationKind.neutral,
        );
        expect(result.canObserverSeeSecret('outsider'), isFalse);
      },
    );

    test(
      'event_driven_change selects events at or before the evaluation tick',
      () {
        final result = const FactionDiplomacyRumorIntegration().evaluate(
          scenario,
          atTick: 20,
          observerId: 'outsider',
        );
        expect(result.eventsAtOrBeforeTick, hasLength(1));
        expect(result.eventsAtOrBeforeTick.single.id, 'event-1');
      },
    );

    test('rumor_spread returns deterministic downstream reaches', () {
      final result = const FactionDiplomacyRumorIntegration().evaluate(
        scenario,
        atTick: 22,
        observerId: 'outsider',
      );
      expect(result.rumor.recipients.map((reach) => reach.personId), [
        'merchant',
        'captain',
      ]);
    });

    test('faction_knowledge is scoped to the requested faction', () {
      final result = const FactionDiplomacyRumorIntegration().evaluate(
        scenario,
        atTick: 20,
        observerId: 'south',
      );
      expect(result.knownEventIds, {'event-1'});
      expect(result.knowledgeFor('unknown'), isEmpty);
    });
  });
}
