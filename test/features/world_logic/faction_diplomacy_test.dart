import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/faction_diplomacy.dart';
import 'package:void_scriptor/features/world_logic/domain/faction_relationship_matrix.dart';

void main() {
  group('110.24 FactionDiplomacy', () {
    test('public_stance: declared public kind and intensity exposed', () {
      final entry = FactionDiplomacyEntry.validated(
        id: 'd1',
        fromFactionId: 'A',
        toFactionId: 'B',
        publicKind: FactionRelationKind.neutral,
        publicIntensity: 2.0,
        secretKind: FactionRelationKind.ally,
        secretIntensity: 8.0,
        validFrom: 0,
        validUntil: null,
        secretKnownBy: const [],
        sourceRevision: 'r1',
        sourceReason: 'overt peace',
      );
      final stance = entry.publicStance(forFaction: 'A');
      expect(stance.kind, FactionRelationKind.neutral);
      expect(stance.intensity, 2.0);
      expect(stance.reason, 'overt peace');
    });

    test('secret_stance: actual secret kind differs from public', () {
      final entry = FactionDiplomacyEntry.validated(
        id: 'd2',
        fromFactionId: 'A',
        toFactionId: 'B',
        publicKind: FactionRelationKind.rival,
        publicIntensity: 7.0,
        secretKind: FactionRelationKind.ally,
        secretIntensity: 9.0,
        validFrom: 0,
        validUntil: null,
        secretKnownBy: const ['A'],
        sourceRevision: 'r2',
        sourceReason: 'covert pact',
      );
      final secret = entry.secretStance();
      expect(secret, isNotNull);
      expect(secret!.kind, FactionRelationKind.ally);
      expect(secret.intensity, 9.0);
      expect(secret.reason, 'covert pact');
    });

    test('perceived_stance: observer perception differs from actual', () {
      final entry = FactionDiplomacyEntry.validated(
        id: 'd3',
        fromFactionId: 'A',
        toFactionId: 'B',
        publicKind: FactionRelationKind.neutral,
        publicIntensity: 0.0,
        secretKind: FactionRelationKind.enemy,
        secretIntensity: 9.0,
        validFrom: 0,
        validUntil: null,
        secretKnownBy: const ['A'],
        perceivedBy: const {
          'C': DiplomacyStance(
            kind: FactionRelationKind.ally,
            intensity: 6.0,
            reason: 'rumor of friendship',
          ),
        },
        sourceRevision: 'r3',
        sourceReason: 'misperception',
      );
      expect(
        entry.perceivedStance(forObserver: 'C')?.kind,
        FactionRelationKind.ally,
      );
      expect(
        entry.perceivedStance(forObserver: 'A')?.kind,
        FactionRelationKind.enemy,
      );
      // Observer without knowledge + no explicit perception falls back to public.
      expect(
        entry.perceivedStance(forObserver: 'D')?.kind,
        FactionRelationKind.neutral,
      );
    });

    test('knowledge_access: only authorized observers see secret', () {
      final entry = FactionDiplomacyEntry.validated(
        id: 'd4',
        fromFactionId: 'A',
        toFactionId: 'B',
        publicKind: FactionRelationKind.neutral,
        publicIntensity: 0.0,
        secretKind: FactionRelationKind.ally,
        secretIntensity: 8.0,
        validFrom: 0,
        validUntil: null,
        secretKnownBy: const ['A', 'spy'],
        sourceRevision: 'r4',
        sourceReason: 'classified pact',
      );
      expect(entry.canObserverSeeSecret('A'), isTrue);
      expect(entry.canObserverSeeSecret('spy'), isTrue);
      expect(entry.canObserverSeeSecret('C'), isFalse);
    });

    test(
      'spoiler_integration: spoiler guard hides future secrets from reader',
      () {
        final entry = FactionDiplomacyEntry.validated(
          id: 'd5',
          fromFactionId: 'A',
          toFactionId: 'B',
          publicKind: FactionRelationKind.neutral,
          publicIntensity: 0.0,
          secretKind: FactionRelationKind.ally,
          secretIntensity: 7.0,
          validFrom: 100, // secret pact begins at tick 100
          validUntil: null,
          secretKnownBy: const ['A'],
          sourceRevision: 'r5',
          sourceReason: 'hidden pact',
        );

        // Reader at tick 50: before secret reveal, entry inactive -> nothing visible.
        final reader = DiplomacyView.reader(tick: 50);
        expect(reader.visibleStances([entry], forObserver: 'C'), isEmpty);

        // Reader at tick 150: public stance is active, but secret still hidden.
        final readerLater = DiplomacyView.reader(tick: 150);
        final publicOnly = readerLater.visibleStances([
          entry,
        ], forObserver: 'C');
        expect(publicOnly, hasLength(1));
        expect(
          publicOnly.first.publicStance(forFaction: 'C').kind,
          FactionRelationKind.neutral,
        );
        // Crucially, perceived from reader view must fall back to public.
        expect(
          publicOnly.first
              .perceivedStance(
                forObserver: 'C',
                perspective: DiplomacyPerspective.reader,
              )
              ?.kind,
          FactionRelationKind.neutral,
        );

        // Writer view always sees the entry.
        final writer = DiplomacyView.writer();
        expect(writer.visibleStances([entry], forObserver: 'C'), hasLength(1));
      },
    );

    test('validated factory: rejects invalid intensity and ranges', () {
      expect(
        () => FactionDiplomacyEntry.validated(
          id: 'bad',
          fromFactionId: 'A',
          toFactionId: 'B',
          publicKind: FactionRelationKind.neutral,
          publicIntensity: -1.0, // invalid
          secretKind: FactionRelationKind.ally,
          secretIntensity: 5.0,
          validFrom: 0,
          validUntil: null,
          secretKnownBy: const [],
          sourceRevision: 'r',
          sourceReason: 'bad',
        ),
        throwsArgumentError,
      );
      expect(
        () => FactionDiplomacyEntry.validated(
          id: 'bad2',
          fromFactionId: 'A',
          toFactionId: 'B',
          publicKind: FactionRelationKind.neutral,
          publicIntensity: 0.0,
          secretKind: FactionRelationKind.ally,
          secretIntensity: 5.0,
          validFrom: 50,
          validUntil: 10, // validUntil < validFrom
          secretKnownBy: const [],
          sourceRevision: 'r',
          sourceReason: 'bad',
        ),
        throwsArgumentError,
      );
    });
  });
}
