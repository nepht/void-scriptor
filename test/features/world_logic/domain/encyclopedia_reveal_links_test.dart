// Sprint 111.28 - Reveal & Foreshadowing Links (RED first).
//
// Covers the six canonical acceptance keys: clue_links, prophecies,
// symbols, reveal_points, story_links, spoiler_preview. RevealPoint,
// SpoilerLevel and SpoilerPolicy are reused from 111.8, never duplicated.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_reveal_links.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_spoiler_accessibility.dart';

ClueLink clue(
  String id, {
  ClueKind kind = ClueKind.physicalTrace,
  String storyLink = 'ch1:s2',
  String? targetFactId,
  String? description,
}) => ClueLink.validated(
  clueId: id,
  kind: kind,
  storyLink: storyLink,
  description: description ?? 'clue $id',
  targetFactId: targetFactId,
);

Prophecy prophecy(
  String id, {
  ProphecyAmbiguity ambiguity = ProphecyAmbiguity.veiled,
  String? fulfillmentRevealId,
  String? utterer,
  String? timeMarker,
}) => Prophecy.validated(
  prophecyId: id,
  text: 'prophecy $id will come true',
  ambiguity: ambiguity,
  fulfillmentRevealId: fulfillmentRevealId,
  utterer: utterer,
  timeMarker: timeMarker,
);

ForeshadowSymbol symbol(
  String id, {
  String? name,
  List<String> appearances = const ['ch1:s2'],
  String? meaning,
  SymbolReach reach = SymbolReach.cultural,
}) => ForeshadowSymbol.validated(
  symbolId: id,
  name: name ?? 'symbol $id',
  appearances: appearances,
  meaning: meaning,
  reach: reach,
);

RevealPoint reveal(
  String id, {
  int tick = 10,
  SpoilerLevel level = SpoilerLevel.major,
  String storyLink = 'ch5:s1',
}) => RevealPoint.validated(
  revealId: id,
  storyLink: storyLink,
  tick: tick,
  level: level,
);

RevealLinkRecord record(
  String id, {
  List<ClueLink> clues = const [],
  List<Prophecy> prophecies = const [],
  List<ForeshadowSymbol> symbols = const [],
  List<RevealPoint> reveals = const [],
  String factId = 'fact-x',
  String hiddenFact = 'the butler did it',
}) => RevealLinkRecord.validated(
  recordId: id,
  factId: factId,
  hiddenFact: hiddenFact,
  clueLinks: clues,
  prophecies: prophecies,
  symbols: symbols,
  revealPoints: reveals,
);

void main() {
  group('ClueKind', () {
    test('has the seven canonical clue families with labels', () {
      expect(ClueKind.values.length, 7);
      for (final kind in ClueKind.values) {
        expect(kind.label, isNotEmpty);
      }
      expect(ClueKind.physicalTrace.label, isA<String>());
    });
  });

  group('ClueLink.validated', () {
    test('keeps trimmed non-empty values', () {
      final link = ClueLink.validated(
        clueId: ' c1 ',
        kind: ClueKind.testimony,
        storyLink: ' ch2:s1 ',
        description: ' a witness lied ',
        targetFactId: ' fact-x ',
      );
      expect(link.clueId, 'c1');
      expect(link.storyLink, 'ch2:s1');
      expect(link.description, 'a witness lied');
      expect(link.targetFactId, 'fact-x');
      expect(link.kind, ClueKind.testimony);
    });

    test('targetFactId is nullable', () {
      expect(clue('c1').targetFactId, isNull);
    });

    test('rejects empty clueId', () {
      expect(
        () => ClueLink.validated(
          clueId: ' ',
          kind: ClueKind.other,
          storyLink: 'ch1',
          description: 'd',
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty storyLink', () {
      expect(
        () => ClueLink.validated(
          clueId: 'c1',
          kind: ClueKind.other,
          storyLink: '  ',
          description: 'd',
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty description', () {
      expect(
        () => ClueLink.validated(
          clueId: 'c1',
          kind: ClueKind.other,
          storyLink: 'ch1',
          description: ' ',
        ),
        throwsArgumentError,
      );
    });

    test('rejects whitespace targetFactId', () {
      expect(() => clue('c1', targetFactId: '   '), throwsArgumentError);
    });
  });

  group('ProphecyAmbiguity', () {
    test('weight ladder is strictly increasing', () {
      for (var i = 1; i < ProphecyAmbiguity.values.length; i++) {
        expect(
          ProphecyAmbiguity.values[i].weight,
          greaterThan(ProphecyAmbiguity.values[i - 1].weight),
        );
      }
    });

    test('every ambiguity has a label', () {
      for (final a in ProphecyAmbiguity.values) {
        expect(a.label, isNotEmpty);
      }
    });
  });

  group('Prophecy.validated', () {
    test('keeps trimmed values and optional fields', () {
      final p = Prophecy.validated(
        prophecyId: ' p1 ',
        text: ' the crown breaks twice ',
        ambiguity: ProphecyAmbiguity.cryptic,
        utterer: ' oracle ',
        timeMarker: ' era-3 ',
        fulfillmentRevealId: ' r1 ',
      );
      expect(p.prophecyId, 'p1');
      expect(p.text, 'the crown breaks twice');
      expect(p.ambiguity, ProphecyAmbiguity.cryptic);
      expect(p.utterer, 'oracle');
      expect(p.timeMarker, 'era-3');
      expect(p.fulfillmentRevealId, 'r1');
    });

    test('defaults are literal ambiguity with null optionals', () {
      final p = Prophecy.validated(prophecyId: 'p1', text: 'text');
      expect(p.ambiguity, ProphecyAmbiguity.literal);
      expect(p.utterer, isNull);
      expect(p.timeMarker, isNull);
      expect(p.fulfillmentRevealId, isNull);
    });

    test('rejects empty prophecyId', () {
      expect(
        () => Prophecy.validated(prophecyId: ' ', text: 't'),
        throwsArgumentError,
      );
    });

    test('rejects empty text', () {
      expect(
        () => Prophecy.validated(prophecyId: 'p1', text: '  '),
        throwsArgumentError,
      );
    });

    test('rejects whitespace-only optional fields', () {
      expect(() => prophecy('p1', utterer: '  '), throwsArgumentError);
      expect(() => prophecy('p1', timeMarker: '  '), throwsArgumentError);
      expect(
        () => prophecy('p1', fulfillmentRevealId: '  '),
        throwsArgumentError,
      );
    });

    test('isFulfilled reflects the fulfillment target', () {
      expect(prophecy('p1').isFulfilled, isFalse);
      expect(prophecy('p1', fulfillmentRevealId: 'r1').isFulfilled, isTrue);
    });
  });

  group('SymbolReach', () {
    test('has the three canonical reaches with labels', () {
      expect(SymbolReach.values.length, 3);
      for (final r in SymbolReach.values) {
        expect(r.label, isNotEmpty);
      }
    });
  });

  group('ForeshadowSymbol.validated', () {
    test('keeps trimmed name/meaning and dedupes trimmed appearances', () {
      final s = ForeshadowSymbol.validated(
        symbolId: ' s1 ',
        name: ' the hollow cube ',
        appearances: ['ch1:s2', ' ch1:s2 ', 'ch3:s1'],
        meaning: ' loss ',
      );
      expect(s.symbolId, 's1');
      expect(s.name, 'the hollow cube');
      expect(s.meaning, 'loss');
      expect(s.appearances, ['ch1:s2', 'ch3:s1']);
    });

    test('appearances may be empty (defined but unused)', () {
      final s = symbol('s1', appearances: const []);
      expect(s.appearances, isEmpty);
      expect(s.appearsIn('ch1:s2'), isFalse);
    });

    test('appearsIn is trim-tolerant', () {
      final s = symbol('s1');
      expect(s.appearsIn(' ch1:s2 '), isTrue);
      expect(s.appearsIn('ch9'), isFalse);
    });

    test('rejects empty symbolId or name', () {
      expect(
        () => ForeshadowSymbol.validated(
          symbolId: ' ',
          name: 'n',
          appearances: const [],
        ),
        throwsArgumentError,
      );
      expect(
        () => ForeshadowSymbol.validated(
          symbolId: 's1',
          name: ' ',
          appearances: const [],
        ),
        throwsArgumentError,
      );
    });

    test('rejects empty appearance entries', () {
      expect(
        () => symbol('s1', appearances: const ['ch1', ' ']),
        throwsArgumentError,
      );
    });
  });

  group('RevealLinkRecord.validated', () {
    test('rejects empty recordId, factId, or hiddenFact', () {
      expect(() => record(' ', clues: const []), throwsArgumentError);
      expect(() => record('r1', factId: ' '), throwsArgumentError);
      expect(() => record('r1', hiddenFact: '  '), throwsArgumentError);
    });

    test('guards duplicate ids within each collection', () {
      expect(
        () => record('r1', clues: [clue('c1'), clue('c1')]),
        throwsArgumentError,
      );
      expect(
        () => record('r1', prophecies: [prophecy('p1'), prophecy('p1')]),
        throwsArgumentError,
      );
      expect(
        () => record('r1', symbols: [symbol('s1'), symbol('s1')]),
        throwsArgumentError,
      );
      expect(
        () => record('r1', reveals: [reveal('r1'), reveal('r1')]),
        throwsArgumentError,
      );
    });

    test('rejects clue targetFactId pointing at another fact', () {
      expect(
        () => record('r1', clues: [clue('c1', targetFactId: 'other')]),
        throwsArgumentError,
      );
      expect(
        () => record('r1', clues: [clue('c1', targetFactId: 'fact-x')]),
        isNot(throwsA(anything)),
      );
    });

    test('rejects prophecy fulfillment outside registered reveals', () {
      expect(
        () => record(
          'r1',
          prophecies: [prophecy('p1', fulfillmentRevealId: 'ghost')],
        ),
        throwsArgumentError,
      );
      expect(
        () => record(
          'r1',
          reveals: [reveal('rv1')],
          prophecies: [prophecy('p1', fulfillmentRevealId: 'rv1')],
        ),
        isNot(throwsA(anything)),
      );
    });

    test('collections are immutable with counts', () {
      final r = record(
        'r1',
        clues: [
          clue('c1'),
          clue('c2', storyLink: 'ch3:s1'),
        ],
        prophecies: [prophecy('p1')],
        symbols: [symbol('s1')],
        reveals: [reveal('rv1')],
      );
      expect(r.clueCount, 2);
      expect(r.prophecyCount, 1);
      expect(r.symbolCount, 1);
      expect(r.revealCount, 1);
      expect(() => r.clueLinks.add(clue('c9')), throwsUnsupportedError);
    });

    test('cluesOfKind is deterministic sorted by clueId', () {
      final r = record(
        'r1',
        clues: [
          clue('c2', kind: ClueKind.omen),
          clue('c1', kind: ClueKind.omen),
          clue('c3', kind: ClueKind.testimony),
        ],
      );
      expect(r.cluesOfKind(ClueKind.omen).map((c) => c.clueId), ['c1', 'c2']);
      expect(r.cluesOfKind(ClueKind.dream), isEmpty);
    });

    test('cluesForStoryLink is trim-tolerant', () {
      final r = record(
        'r1',
        clues: [
          clue('c1', storyLink: 'ch1:s2'),
          clue('c2', storyLink: 'ch9'),
        ],
      );
      expect(r.cluesForStoryLink(' ch1:s2 ').map((c) => c.clueId), ['c1']);
    });

    test('propheciesUnfulfilled excludes bound fulfillments', () {
      final r = record(
        'r1',
        reveals: [reveal('rv1')],
        prophecies: [
          prophecy('p2'),
          prophecy('p1', fulfillmentRevealId: 'rv1'),
        ],
      );
      expect(r.propheciesUnfulfilled().map((p) => p.prophecyId), ['p2']);
    });

    test('propheciesAtAmbiguityAtLeast uses the weight ladder', () {
      final r = record(
        'r1',
        prophecies: [
          prophecy('p1', ambiguity: ProphecyAmbiguity.literal),
          prophecy('p2', ambiguity: ProphecyAmbiguity.paradoxical),
        ],
      );
      expect(
        r.propheciesAtAmbiguityAtLeast(ProphecyAmbiguity.cryptic).length,
        1,
      );
      expect(
        r.propheciesAtAmbiguityAtLeast(ProphecyAmbiguity.literal).length,
        2,
      );
    });

    test('symbolsAppearingIn is deterministic sorted', () {
      final r = record(
        'r1',
        symbols: [
          symbol('s2', appearances: const ['ch4']),
          symbol('s1', appearances: const ['ch4', 'ch1:s2']),
        ],
      );
      expect(r.symbolsAppearingIn('ch4').map((s) => s.symbolId), ['s1', 's2']);
    });

    test('linkedStoryLinks unions clues, symbols, and reveals sorted', () {
      final r = record(
        'r1',
        clues: [
          clue('c1', storyLink: 'ch1:s2'),
          clue('c2', storyLink: 'ch7'),
        ],
        symbols: [
          symbol('s1', appearances: const ['ch3', 'ch7']),
        ],
        reveals: [reveal('rv1', storyLink: 'ch5:s1')],
      );
      expect(r.linkedStoryLinks, ['ch1:s2', 'ch3', 'ch5:s1', 'ch7']);
      expect(() => r.linkedStoryLinks.add('x'), throwsUnsupportedError);
    });

    test('reveal ladder helpers: sorted pending, revealed, first tick', () {
      final r = record(
        'r1',
        reveals: [
          reveal('rv2', tick: 5),
          reveal('rv1', tick: 20),
          reveal('rv3', tick: 12),
        ],
      );
      expect(r.pendingRevealPoints.map((p) => p.revealId), [
        'rv2',
        'rv3',
        'rv1',
      ]);
      expect(r.pendingRevealCount, 3);
      expect(r.revealedCount, 0);
      expect(r.firstPendingRevealTick, 5);
      final revealed = r.withRevealMarked('rv2');
      expect(revealed.pendingRevealCount, 2);
      expect(revealed.revealedCount, 1);
      expect(revealed.firstPendingRevealTick, 12);
      expect(revealed.revealFor('rv2')!.revealed, isTrue);
      // original untouched
      expect(r.pendingRevealCount, 3);
    });

    test('withRevealMarked rejects unknown reveal ids', () {
      final r = record('r1', reveals: [reveal('rv1')]);
      expect(() => r.withRevealMarked('ghost'), throwsArgumentError);
    });

    test('firstPendingRevealTick is null without reveals', () {
      expect(record('r1').firstPendingRevealTick, isNull);
    });

    test('isFullyForeshadowed needs at least one clue and one reveal', () {
      expect(record('r1').isFullyForeshadowed, isFalse);
      expect(record('r1', clues: [clue('c1')]).isFullyForeshadowed, isFalse);
      expect(
        record('r1', reveals: [reveal('rv1')]).isFullyForeshadowed,
        isFalse,
      );
      expect(
        record(
          'r1',
          clues: [clue('c1')],
          reveals: [reveal('rv1')],
        ).isFullyForeshadowed,
        isTrue,
      );
    });

    test('revealFor and clueFor are trim-tolerant lookups', () {
      final r = record('r1', clues: [clue('c1')], reveals: [reveal('rv1')]);
      expect(r.clueFor(' c1 ')!.kind, ClueKind.physicalTrace);
      expect(r.clueFor('ghost'), isNull);
      expect(r.revealFor('rv1')!.tick, 10);
      expect(r.revealFor('nope'), isNull);
    });
  });

  group('spoiler_preview', () {
    test('masked preview never leaks the hidden fact', () {
      final r = record('r1', reveals: [reveal('rv1')]);
      final policy = SpoilerPolicy(defaultLevel: SpoilerLevel.safe);
      final preview = r.spoilerPreview(policy);
      expect(preview, contains('TERSEMBUNYI'));
      expect(preview.contains(r.hiddenFact), isFalse);
    });

    test('ending-level audience sees the raw fact for this record key', () {
      final r = record('r1');
      final policy = SpoilerPolicy(defaultLevel: SpoilerLevel.ending);
      expect(r.spoilerPreview(policy), r.hiddenFact);
    });

    test('per-record override keyed by factId beats the default', () {
      final r = record('r1');
      final policy = SpoilerPolicy(
        defaultLevel: SpoilerLevel.safe,
        overrides: {'fact-x': SpoilerLevel.ending},
      );
      expect(r.spoilerPreview(policy), r.hiddenFact);
    });

    test('revealPreview classifies pending points against the policy', () {
      final r = record('r1', reveals: [reveal('rv1')]);
      final strict = SpoilerPolicy(defaultLevel: SpoilerLevel.safe);
      final loose = SpoilerPolicy(defaultLevel: SpoilerLevel.major);
      expect(r.revealPreview(strict, 'rv1'), 'MASKED');
      expect(r.revealPreview(loose, 'rv1'), 'VISIBLE');
      final shown = r.withRevealMarked('rv1');
      expect(shown.revealPreview(strict, 'rv1'), 'REVEALED');
    });

    test('revealPreview rejects unknown reveal ids', () {
      final r = record('r1', reveals: [reveal('rv1')]);
      expect(
        () => r.revealPreview(SpoilerPolicy(), 'ghost'),
        throwsArgumentError,
      );
    });
  });

  group('ForeshadowQuery', () {
    test('empty query matches nothing and describes itself', () {
      final q = ForeshadowQuery();
      expect(q.isEmpty, isTrue);
      expect(q.describe(), isNotEmpty);
    });

    test('kind filter matches records holding that clue kind', () {
      final a = record('a', clues: [clue('c1', kind: ClueKind.omen)]);
      final b = record('b', clues: [clue('c2', kind: ClueKind.testimony)]);
      final q = ForeshadowQuery(kind: ClueKind.omen);
      expect(q.matches(a), isTrue);
      expect(q.matches(b), isFalse);
    });

    test('storyLink filter uses the linked union', () {
      final a = record(
        'a',
        symbols: [
          symbol('s1', appearances: const ['ch8']),
        ],
      );
      final q = ForeshadowQuery(storyLink: ' ch8 ');
      expect(q.matches(a), isTrue);
      expect(ForeshadowQuery(storyLink: 'ch2').matches(a), isFalse);
    });

    test('minAmbiguity filter matches via prophecy ladder', () {
      final a = record(
        'a',
        prophecies: [prophecy('p1', ambiguity: ProphecyAmbiguity.paradoxical)],
      );
      final b = record(
        'b',
        prophecies: [prophecy('p2', ambiguity: ProphecyAmbiguity.literal)],
      );
      final q = ForeshadowQuery(minAmbiguity: ProphecyAmbiguity.cryptic);
      expect(q.matches(a), isTrue);
      expect(q.matches(b), isFalse);
    });

    test('pendingOnly filter', () {
      final a = record('a', reveals: [reveal('rv1')]);
      final q = ForeshadowQuery(pendingOnly: true);
      expect(q.matches(a), isTrue);
      expect(q.matches(record('b')), isFalse);
      expect(a.withRevealMarked('rv1'), isNot(isNull));
      expect(q.matches(a.withRevealMarked('rv1')), isFalse);
    });

    test('rejects whitespace storyLink', () {
      expect(() => ForeshadowQuery(storyLink: '  '), throwsArgumentError);
    });
  });

  group('ForeshadowCatalog', () {
    test('empty catalog', () {
      final c = ForeshadowCatalog.empty();
      expect(c.recordIds, isEmpty);
      expect(c.totalClueCount, 0);
      expect(c.recordFor('x'), isNull);
    });

    test('withRecords guards duplicate recordId and sorts', () {
      expect(
        () => ForeshadowCatalog.withRecords([record('a'), record('a')]),
        throwsArgumentError,
      );
      final c = ForeshadowCatalog.withRecords([record('b'), record('a')]);
      expect(c.recordIds, ['a', 'b']);
    });

    test('aggregate counts across records', () {
      final c = ForeshadowCatalog.withRecords([
        record('a', clues: [clue('c1')], reveals: [reveal('rv1')]),
        record(
          'b',
          clues: [clue('c2'), clue('c3')],
          prophecies: [prophecy('p1')],
          symbols: [symbol('s1')],
        ),
      ]);
      expect(c.totalClueCount, 3);
      expect(c.totalProphecyCount, 1);
      expect(c.totalSymbolCount, 1);
      expect(c.totalPendingRevealCount, 1);
    });

    test('recordIdsWithUnboundProphecy sorted', () {
      final c = ForeshadowCatalog.withRecords([
        record('a', prophecies: [prophecy('p1')]),
        record(
          'b',
          reveals: [reveal('rv1')],
          prophecies: [prophecy('p2', fulfillmentRevealId: 'rv1')],
        ),
      ]);
      expect(c.recordIdsWithUnboundProphecy, ['a']);
    });

    test('recordIdsForStoryLink spans all link families', () {
      final c = ForeshadowCatalog.withRecords([
        record('a', clues: [clue('c1', storyLink: 'ch1:s2')]),
        record('b', reveals: [reveal('rv1', storyLink: 'ch1:s2')]),
        record('c'),
      ]);
      expect(c.recordIdsForStoryLink('ch1:s2'), ['a', 'b']);
    });

    test('query returns deterministic subset', () {
      final c = ForeshadowCatalog.withRecords([
        record('b', clues: [clue('c2', kind: ClueKind.omen)]),
        record('a', clues: [clue('c1', kind: ClueKind.omen)]),
        record('z', clues: [clue('c3', kind: ClueKind.testimony)]),
      ]);
      final hits = c.query(ForeshadowQuery(kind: ClueKind.omen));
      expect(hits.map((r) => r.recordId), ['a', 'b']);
    });

    test('records view is immutable', () {
      final c = ForeshadowCatalog.withRecords([record('a')]);
      expect(() => c.records.add(record('b')), throwsUnsupportedError);
    });
  });
}
