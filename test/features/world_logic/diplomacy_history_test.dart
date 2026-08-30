// Sprint 110.25 - Treaty, Conflict & Diplomacy History
// Domain-only contract linking diplomacy changes with treaties, wars,
// trade links, and story events. No persistence, UI, locale, network,
// wall clock, or random input.

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/diplomacy_history.dart';

void main() {
  group('DiplomacyHistory - treaties', () {
    test(
      'treaty carries two faction ids, kind, validity range, and source',
      () {
        final treaty = Treaty.validated(
          id: 'tr-1',
          factionAId: 'faction-a',
          factionBId: 'faction-b',
          kind: TreatyKind.nonAggression,
          validFrom: 10,
          validUntil: 100,
          sourceRevision: 'rev-1',
          sourceReason: 'post-war peace',
        );
        expect(treaty.factionAId, 'faction-a');
        expect(treaty.factionBId, 'faction-b');
        expect(treaty.kind, TreatyKind.nonAggression);
        expect(treaty.isActiveAt(10), isTrue);
        expect(treaty.isActiveAt(100), isTrue);
        expect(treaty.isActiveAt(9), isFalse);
        expect(treaty.isActiveAt(101), isFalse);
        expect(treaty.sourceRevision, 'rev-1');
      },
    );
  });

  group('DiplomacyHistory - conflicts', () {
    test('conflict carries id, participants, kind, validity, source', () {
      final war = Conflict.validated(
        id: 'war-1',
        sideAFactionId: 'a',
        sideBFactionId: 'b',
        kind: ConflictKind.war,
        validFrom: 0,
        validUntil: 50,
        sourceRevision: 'rev-w',
        sourceReason: 'border dispute',
      );
      expect(war.kind, ConflictKind.war);
      expect(war.isActiveAt(25), isTrue);
      expect(war.isActiveAt(60), isFalse);
    });
  });

  group('DiplomacyHistory - trade_links', () {
    test('trade link stores commodity, rate, validity and source', () {
      final link = TradeLink.validated(
        id: 'tl-1',
        fromFactionId: 'a',
        toFactionId: 'b',
        commodity: 'grain',
        rate: 50,
        validFrom: 0,
        validUntil: 100,
        sourceRevision: 'rev',
        sourceReason: 'grain corridor',
      );
      expect(link.commodity, 'grain');
      expect(link.rate, 50);
      expect(link.isActiveAt(50), isTrue);
      expect(link.isActiveAt(150), isFalse);
    });
  });

  group('DiplomacyHistory - change_events', () {
    test('change event links a tick to a treaty', () {
      final ev = DiplomacyChangeEvent.validated(
        id: 'ev-1',
        tick: 25,
        treatyId: 'tr-1',
        summary: 'alliance signed',
        sourceRevision: 'rev',
        sourceReason: 'peace summit',
      );
      expect(ev.tick, 25);
      expect(ev.treatyId, 'tr-1');
      expect(ev.summary, 'alliance signed');
    });
  });

  group('DiplomacyHistory - timeline_view', () {
    test('timeline view sorts events ascending by tick', () {
      final history = DiplomacyHistory.validated(
        treaties: [
          Treaty.validated(
            id: 'tr-1',
            factionAId: 'a',
            factionBId: 'b',
            kind: TreatyKind.alliance,
            validFrom: 0,
            validUntil: 100,
            sourceRevision: 'rev',
            sourceReason: 'r',
          ),
        ],
        conflicts: const [],
        tradeLinks: const [],
        changeEvents: [
          DiplomacyChangeEvent.validated(
            id: 'ev-2',
            tick: 50,
            treatyId: 'tr-1',
            summary: 'second',
            sourceRevision: 'rev',
            sourceReason: 'r',
          ),
          DiplomacyChangeEvent.validated(
            id: 'ev-1',
            tick: 10,
            treatyId: 'tr-1',
            summary: 'first',
            sourceRevision: 'rev',
            sourceReason: 'r',
          ),
        ],
      );
      final view = DiplomacyTimelineView.of(
        history: history,
        fromTick: 0,
        toTick: 100,
      );
      expect(view.entries.length, 2);
      expect(view.entries.first.summary, 'first');
      expect(view.entries.last.summary, 'second');
    });

    test('timeline view filters by tick range', () {
      final history = DiplomacyHistory.validated(
        treaties: const [],
        conflicts: const [],
        tradeLinks: const [],
        changeEvents: [
          DiplomacyChangeEvent.validated(
            id: 'ev-1',
            tick: 5,
            treatyId: 't',
            summary: 'before',
            sourceRevision: 'r',
            sourceReason: 'r',
          ),
          DiplomacyChangeEvent.validated(
            id: 'ev-2',
            tick: 50,
            treatyId: 't',
            summary: 'inside',
            sourceRevision: 'r',
            sourceReason: 'r',
          ),
        ],
      );
      final view = DiplomacyTimelineView.of(
        history: history,
        fromTick: 10,
        toTick: 100,
      );
      expect(view.entries.length, 1);
      expect(view.entries.first.summary, 'inside');
    });
  });
}
