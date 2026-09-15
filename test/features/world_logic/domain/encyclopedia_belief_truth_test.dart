// Sprint 111.25 - Public Belief vs Historical Truth.
//
// RED contract test: separates the narrative the public believes, the
// per-group variants, the canon historical truth behind them, a bounded
// confidence, the spoiler policy that keeps secrets unrevealed, and the
// source links that back the truth claim.
//
// Domain-only: no persistence, UI, locale, network, wall clock, or random.

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_belief_truth.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_myth.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_spoiler_accessibility.dart';

void main() {
  group('TruthConfidenceBand', () {
    test('bandFor maps the documented thresholds deterministically', () {
      expect(TruthConfidenceBand.bandFor(0.0), TruthConfidenceBand.unattested);
      expect(TruthConfidenceBand.bandFor(0.19), TruthConfidenceBand.unattested);
      expect(TruthConfidenceBand.bandFor(0.2), TruthConfidenceBand.rumorLike);
      expect(TruthConfidenceBand.bandFor(0.49), TruthConfidenceBand.rumorLike);
      expect(TruthConfidenceBand.bandFor(0.5), TruthConfidenceBand.supported);
      expect(TruthConfidenceBand.bandFor(0.79), TruthConfidenceBand.supported);
      expect(TruthConfidenceBand.bandFor(0.8), TruthConfidenceBand.attested);
      expect(TruthConfidenceBand.bandFor(0.99), TruthConfidenceBand.attested);
      expect(TruthConfidenceBand.bandFor(1.0), TruthConfidenceBand.certain);
    });

    test('bands expose stable labels', () {
      expect(TruthConfidenceBand.values.map((b) => b.label), [
        'Unattested',
        'Rumor-like',
        'Supported',
        'Attested',
        'Certain',
      ]);
    });
  });

  group('BeliefSourceLink', () {
    test('validated trims sourceId and keeps optional note', () {
      final link = BeliefSourceLink.validated(
        sourceId: ' src-1 ',
        kind: 'chronicle',
        note: ' copied 14:2 ',
      );
      expect(link.sourceId, 'src-1');
      expect(link.kind, 'chronicle');
      expect(link.note, 'copied 14:2');
    });

    test('rejects empty sourceId, kind, and blank-only note', () {
      expect(
        () => BeliefSourceLink.validated(sourceId: '  ', kind: 'chronicle'),
        throwsArgumentError,
      );
      expect(
        () => BeliefSourceLink.validated(sourceId: 's', kind: '  '),
        throwsArgumentError,
      );
      expect(
        () => BeliefSourceLink.validated(
          sourceId: 's',
          kind: 'chronicle',
          note: '   ',
        ),
        throwsArgumentError,
      );
    });
  });

  group('PublicNarrative', () {
    test('validated requires non-empty text and defaults to safe level', () {
      final n = PublicNarrative.validated(
        narrativeId: 'pn-1',
        text: 'The Void Cube was a gift from the star ancestors.',
      );
      expect(n.narrativeId, 'pn-1');
      expect(n.spoilerLevel, SpoilerLevel.safe);
    });

    test('rejects empty narrativeId or text', () {
      expect(
        () => PublicNarrative.validated(narrativeId: '', text: 'x'),
        throwsArgumentError,
      );
      expect(
        () => PublicNarrative.validated(narrativeId: 'pn', text: '   '),
        throwsArgumentError,
      );
    });
  });

  group('GroupBeliefVariant', () {
    test('validated trims fields and defaults stance to devout', () {
      final v = GroupBeliefVariant.validated(
        groupId: ' g-iron ',
        text: 'The Cube punishes oath-breakers.',
      );
      expect(v.groupId, 'g-iron');
      expect(v.stance, GroupStance.devout);
      expect(v.text, 'The Cube punishes oath-breakers.');
    });

    test('rejects empty groupId or text', () {
      expect(
        () => GroupBeliefVariant.validated(groupId: ' ', text: 'x'),
        throwsArgumentError,
      );
      expect(
        () => GroupBeliefVariant.validated(groupId: 'g', text: ' '),
        throwsArgumentError,
      );
    });
  });

  group('HistoricalTruthClaim', () {
    test('validated clamps nothing: confidence must be within [0, 1]', () {
      expect(
        () => HistoricalTruthClaim.validated(
          truthId: 't-1',
          statement: 'The Cube is a fallen terraforming seed.',
          confidence: 1.01,
        ),
        throwsArgumentError,
      );
      expect(
        () => HistoricalTruthClaim.validated(
          truthId: 't-1',
          statement: 'x',
          confidence: -0.01,
        ),
        throwsArgumentError,
      );
    });

    test('validated trims fields and exposes confidenceBand', () {
      final t = HistoricalTruthClaim.validated(
        truthId: ' t-2 ',
        statement: ' The rite was invented by the Second Dynasty. ',
        confidence: 0.8,
      );
      expect(t.truthId, 't-2');
      expect(t.statement, 'The rite was invented by the Second Dynasty.');
      expect(t.confidenceBand, TruthConfidenceBand.attested);
    });

    test('rejects empty truthId or statement', () {
      expect(
        () => HistoricalTruthClaim.validated(
          truthId: '',
          statement: 'x',
          confidence: 0.5,
        ),
        throwsArgumentError,
      );
      expect(
        () => HistoricalTruthClaim.validated(
          truthId: 't',
          statement: '  ',
          confidence: 0.5,
        ),
        throwsArgumentError,
      );
    });
  });

  group('BeliefTruthRecord', () {
    HistoricalTruthClaim truth({String id = 't-1', double c = 0.9}) =>
        HistoricalTruthClaim.validated(
          truthId: id,
          statement: 'The Cube is a fallen terraforming seed.',
          confidence: c,
        );

    test('validated rejects empty mythId and empty public narrative', () {
      expect(
        () => BeliefTruthRecord.validated(
          mythId: '  ',
          publicNarrative: PublicNarrative.validated(
            narrativeId: 'pn',
            text: 'believers say x',
          ),
        ),
        throwsArgumentError,
      );
      expect(
        () => BeliefTruthRecord.validated(mythId: 'm-1', publicNarrative: null),
        throwsArgumentError,
      );
    });

    test('validated guards duplicate narrativeId, groupId, and truthId', () {
      expect(
        () => BeliefTruthRecord.validated(
          mythId: 'm-1',
          publicNarrative: PublicNarrative.validated(
            narrativeId: 'pn-1',
            text: 'a',
          ),
          groupVariants: [
            GroupBeliefVariant.validated(groupId: 'g-1', text: 'b'),
            GroupBeliefVariant.validated(groupId: 'g-1', text: 'c'),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => BeliefTruthRecord.validated(
          mythId: 'm-1',
          publicNarrative: PublicNarrative.validated(
            narrativeId: 'pn-1',
            text: 'a',
          ),
          truths: [
            truth(id: 't-1'),
            truth(id: 't-1', c: 0.4),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('exposes immutable sorted collections and counts', () {
      final r = BeliefTruthRecord.validated(
        mythId: 'm-1',
        publicNarrative: PublicNarrative.validated(
          narrativeId: 'pn-1',
          text: 'The Cube is a divine gift.',
        ),
        groupVariants: [
          GroupBeliefVariant.validated(
            groupId: 'g-iron',
            text: 'It punishes oath-breakers.',
          ),
          GroupBeliefVariant.validated(
            groupId: 'g-dawn',
            text: 'It guides dreamers.',
          ),
        ],
        truths: [
          truth(id: 't-b', c: 0.3),
          truth(id: 't-a', c: 0.9),
        ],
        spoilerLevel: SpoilerLevel.major,
      );
      expect(r.variantCount, 2);
      expect(r.truthCount, 2);
      expect(r.groupIds, ['g-dawn', 'g-iron']);
      expect(r.truthIds, ['t-a', 't-b']);
      expect(() => r.groupIds.add('x'), throwsUnsupportedError);
      expect(r.spoilerLevel, SpoilerLevel.major);
    });

    test('averageConfidence is deterministic over truth claims', () {
      final r = BeliefTruthRecord.validated(
        mythId: 'm-1',
        publicNarrative: PublicNarrative.validated(
          narrativeId: 'pn-1',
          text: 'a',
        ),
        truths: [
          truth(id: 't-1', c: 0.2),
          truth(id: 't-2', c: 0.9),
        ],
      );
      expect(r.averageConfidence, closeTo(0.55, 1e-12));
    });

    test('strongestTruth picks highest confidence, tie-break truthId asc', () {
      final r = BeliefTruthRecord.validated(
        mythId: 'm-1',
        publicNarrative: PublicNarrative.validated(
          narrativeId: 'pn-1',
          text: 'a',
        ),
        truths: [
          truth(id: 't-z', c: 0.9),
          truth(id: 't-a', c: 0.9),
          truth(id: 't-m', c: 0.4),
        ],
      );
      expect(r.strongestTruth!.truthId, 't-a');
    });

    test('groupVariantFor returns trimmed match and null when absent', () {
      final r = BeliefTruthRecord.validated(
        mythId: 'm-1',
        publicNarrative: PublicNarrative.validated(
          narrativeId: 'pn-1',
          text: 'a',
        ),
        groupVariants: [
          GroupBeliefVariant.validated(groupId: 'g-iron', text: 'b'),
        ],
      );
      expect(r.groupVariantFor('g-iron'), isNotNull);
      expect(r.groupVariantFor('g-none'), isNull);
    });

    test(
      'isTruthSafeFor honours per-record overrides over the policy default',
      () {
        final r = BeliefTruthRecord.validated(
          mythId: 'm-1',
          publicNarrative: PublicNarrative.validated(
            narrativeId: 'pn-1',
            text: 'a',
          ),
          spoilerLevel: SpoilerLevel.ending,
        );
        final policy = SpoilerPolicy(defaultLevel: SpoilerLevel.safe);
        expect(r.isTruthSafeFor(policy), isFalse);
        final overridden = SpoilerPolicy(
          defaultLevel: SpoilerLevel.safe,
          overrides: {'m-1': SpoilerLevel.ending},
        );
        expect(r.isTruthSafeFor(overridden), isTrue);
      },
    );

    test('sourceLinks are immutable and guarded for duplicate sourceId', () {
      expect(
        () => BeliefTruthRecord.validated(
          mythId: 'm-1',
          publicNarrative: PublicNarrative.validated(
            narrativeId: 'pn-1',
            text: 'a',
          ),
          sourceLinks: [
            BeliefSourceLink.validated(sourceId: 's-1', kind: 'chronicle'),
            BeliefSourceLink.validated(sourceId: 's-1', kind: 'oral'),
          ],
        ),
        throwsArgumentError,
      );
      final r = BeliefTruthRecord.validated(
        mythId: 'm-1',
        publicNarrative: PublicNarrative.validated(
          narrativeId: 'pn-1',
          text: 'a',
        ),
        sourceLinks: [
          BeliefSourceLink.validated(sourceId: 's-2', kind: 'chronicle'),
          BeliefSourceLink.validated(sourceId: 's-1', kind: 'oral'),
        ],
      );
      expect(r.sourceIds, ['s-1', 's-2']);
      expect(() => r.sourceIds.add('s-3'), throwsUnsupportedError);
    });
  });

  group('BeliefTruthCatalog', () {
    BeliefTruthRecord record(
      String mythId, {
      SpoilerLevel spoiler = SpoilerLevel.safe,
      double confidence = 0.9,
      List<String> groups = const [],
    }) {
      return BeliefTruthRecord.validated(
        mythId: mythId,
        publicNarrative: PublicNarrative.validated(
          narrativeId: 'pn-$mythId',
          text: 'public $mythId',
        ),
        groupVariants: [
          for (final g in groups)
            GroupBeliefVariant.validated(groupId: g, text: 'v-$g'),
        ],
        truths: [
          HistoricalTruthClaim.validated(
            truthId: 't-$mythId',
            statement: 'truth $mythId',
            confidence: confidence,
          ),
        ],
        spoilerLevel: spoiler,
      );
    }

    test('empty catalog has no records', () {
      final c = BeliefTruthCatalog.empty();
      expect(c.records, isEmpty);
      expect(c.mythIds, isEmpty);
    });

    test('withRecords guards duplicate mythId and sorts records', () {
      expect(
        () => BeliefTruthCatalog.withRecords([record('m-1'), record('m-1')]),
        throwsArgumentError,
      );
      final c = BeliefTruthCatalog.withRecords([record('m-z'), record('m-a')]);
      expect(c.mythIds, ['m-a', 'm-z']);
      expect(() => c.records.add(record('m-x')), throwsUnsupportedError);
    });

    test('recordFor returns match or null', () {
      final c = BeliefTruthCatalog.withRecords([record('m-1')]);
      expect(c.recordFor('m-1'), isNotNull);
      expect(c.recordFor('nope'), isNull);
    });

    test('secretsPendingReveal lists records above audience threshold', () {
      final c = BeliefTruthCatalog.withRecords([
        record('m-safe', spoiler: SpoilerLevel.safe),
        record('m-major', spoiler: SpoilerLevel.major),
        record('m-end', spoiler: SpoilerLevel.ending),
      ]);
      final policy = SpoilerPolicy(defaultLevel: SpoilerLevel.mild);
      expect(c.secretsPendingReveal(policy), ['m-end', 'm-major']);
    });

    test('recordsByConfidenceBand filters deterministically', () {
      final c = BeliefTruthCatalog.withRecords([
        record('m-1', confidence: 1.0),
        record('m-2', confidence: 0.6),
        record('m-3', confidence: 1.0),
      ]);
      expect(c.mythIdsWithBand(TruthConfidenceBand.certain), ['m-1', 'm-3']);
      expect(c.mythIdsWithBand(TruthConfidenceBand.supported), ['m-2']);
    });

    test('groupsHoldingVariant finds myth ids per group sorted asc', () {
      final c = BeliefTruthCatalog.withRecords([
        record('m-2', groups: ['g-iron']),
        record('m-1', groups: ['g-dawn', 'g-iron']),
        record('m-3', groups: ['g-dawn']),
      ]);
      expect(c.mythIdsForGroup('g-iron'), ['m-1', 'm-2']);
      expect(c.mythIdsForGroup('g-dawn'), ['m-1', 'm-3']);
      expect(c.mythIdsForGroup('g-none'), isEmpty);
    });

    test('meanConfidence is null for empty catalog and stable otherwise', () {
      expect(BeliefTruthCatalog.empty().meanConfidence, isNull);
      final c = BeliefTruthCatalog.withRecords([
        record('m-1', confidence: 0.2),
        record('m-2', confidence: 0.9),
      ]);
      expect(c.meanConfidence, closeTo(0.55, 1e-12));
    });
  });
}
