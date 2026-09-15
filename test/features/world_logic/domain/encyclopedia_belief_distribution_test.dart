// Sprint 111.27 - Belief Distribution & Historical Change (RED first).
//
// Covers the six canonical acceptance keys: regional_distribution,
// time_ranges, conversion_events, reforms, persecution, syncretism.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_belief_distribution.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_myth.dart';

BeliefTimeRange range(String id, {String? to, int? seq}) =>
    BeliefTimeRange.validated(
      rangeId: id,
      fromMarker: 'era-${id.trim()}',
      toMarker: to,
      sequence: seq,
    );

RegionalDistribution entry(
  String region,
  String rangeId, {
  int adherents = 100,
  int? population,
  List<String> groups = const [],
  GroupStance stance = GroupStance.devout,
}) => RegionalDistribution.validated(
  regionId: region,
  timeRangeId: rangeId,
  adherents: adherents,
  population: population,
  groupIds: groups,
  stance: stance,
);

ConversionEvent conversion(
  String id, {
  String from = 'faith-old',
  String to = 'faith-new',
  ConversionMechanism mechanism = ConversionMechanism.missionary,
  String? timeRangeId,
  List<String> groups = const [],
}) => ConversionEvent.validated(
  conversionId: id,
  name: 'conv-$id',
  fromFaithId: from,
  toFaithId: to,
  mechanism: mechanism,
  timeRangeId: timeRangeId,
  groupIds: groups,
);

ReformEvent reform(
  String id, {
  ReformKind kind = ReformKind.doctrinal,
  String? institutionId,
  List<String> doctrines = const [],
  String? timeRangeId,
}) => ReformEvent.validated(
  reformId: id,
  name: 'ref-$id',
  kind: kind,
  institutionId: institutionId,
  doctrineIds: doctrines,
  timeRangeId: timeRangeId,
);

PersecutionEvent persecution(
  String id, {
  PersecutionSeverity severity = PersecutionSeverity.discrimination,
  String target = 'faith-new',
  String? timeRangeId,
  int? victims,
}) => PersecutionEvent.validated(
  persecutionId: id,
  name: 'per-$id',
  perpetrator: 'empire-x',
  targetFaithId: target,
  severity: severity,
  timeRangeId: timeRangeId,
  estimatedVictims: victims,
);

SyncretismEvent syncretism(
  String id, {
  List<String> sources = const ['faith-a', 'faith-b'],
  String result = 'faith-c',
  List<String> elements = const [],
  String? timeRangeId,
}) => SyncretismEvent.validated(
  syncretismId: id,
  name: 'syn-$id',
  sourceFaithIds: sources,
  resultingFaithId: result,
  sharedElements: elements,
  timeRangeId: timeRangeId,
);

BeliefDistributionRecord record({
  String id = 'dist-1',
  List<BeliefTimeRange> ranges = const [],
  List<RegionalDistribution> entries = const [],
  List<ConversionEvent> conversions = const [],
  List<ReformEvent> reforms = const [],
  List<PersecutionEvent> persecutions = const [],
  List<SyncretismEvent> syncretisms = const [],
}) => BeliefDistributionRecord.validated(
  distributionId: id,
  theologyId: 'theo-1',
  timeRanges: ranges,
  regionalDistributions: entries,
  conversions: conversions,
  reforms: reforms,
  persecutions: persecutions,
  syncretisms: syncretisms,
);

void main() {
  group('BeliefTimeRange (time_ranges)', () {
    test('validates trimmed ids and markers', () {
      final r = range(' tr-1 ', to: ' year-900 ');
      expect(r.rangeId, 'tr-1');
      expect(r.fromMarker, 'era-tr-1');
      expect(r.toMarker, 'year-900');
      expect(r.isOngoing, isFalse);
    });

    test('null toMarker means ongoing', () {
      expect(range('tr-2').isOngoing, isTrue);
    });

    test('rejects blank rangeId, fromMarker, and empty toMarker', () {
      expect(
        () => BeliefTimeRange.validated(rangeId: ' ', fromMarker: 'a'),
        throwsArgumentError,
      );
      expect(
        () => BeliefTimeRange.validated(rangeId: 'x', fromMarker: '  '),
        throwsArgumentError,
      );
      expect(
        () => BeliefTimeRange.validated(
          rangeId: 'x',
          fromMarker: 'a',
          toMarker: '   ',
        ),
        throwsArgumentError,
      );
    });

    test('compare orders by sequence, nulls last, then id', () {
      final a = range('a', seq: 1);
      final b = range('b', seq: 2);
      final un = range('un');
      expect(BeliefTimeRange.compare(a, b), lessThan(0));
      expect(BeliefTimeRange.compare(b, a), greaterThan(0));
      expect(BeliefTimeRange.compare(a, un), lessThan(0));
      expect(BeliefTimeRange.compare(un, range('aa')), greaterThan(0));
      expect(BeliefTimeRange.compare(a, a), 0);
    });

    test('describe names the span and ongoing state', () {
      expect(range('tr-3', to: 'end').describe(), contains('era-tr-3'));
      expect(range('tr-3', to: 'end').describe(), contains('end'));
      expect(range('tr-4').describe(), contains('ongoing'));
    });
  });

  group('RegionalDistribution (regional_distribution)', () {
    test('trims fields and keeps stance label', () {
      final e = entry(' r-1 ', 'tr-1', stance: GroupStance.syncretic);
      expect(e.regionId, 'r-1');
      expect(e.timeRangeId, 'tr-1');
      expect(e.stance, GroupStance.syncretic);
      expect(e.stanceLabel, 'Syncretic');
      expect(entry('r', 'tr').population, isNull);
    });

    test('share computed only when population given and positive', () {
      expect(entry('r', 'tr', adherents: 30, population: 100).share, 0.3);
      expect(entry('r', 'tr', adherents: 10).share, isNull);
      expect(entry('r', 'tr', adherents: 0, population: 0).share, isNull);
    });

    test('group ids are sorted immutable and deduplicated-checked', () {
      final e = entry('r', 'tr', groups: ['g2', 'g1']);
      expect(e.groupIds, ['g1', 'g2']);
      expect(() => entry('r', 'tr', groups: ['g1', 'g1']), throwsArgumentError);
    });

    test('rejects negative adherents or population', () {
      expect(() => entry('r', 'tr', adherents: -1), throwsArgumentError);
      expect(
        () => entry('r', 'tr', adherents: 5, population: -2),
        throwsArgumentError,
      );
    });

    test('population smaller than adherents is rejected', () {
      expect(
        () => entry('r', 'tr', adherents: 90, population: 10),
        throwsArgumentError,
      );
    });
  });

  group('ConversionEvent (conversion_events)', () {
    test('involves matches either side after trim', () {
      final c = conversion('cv-1', timeRangeId: 'tr-1');
      expect(c.involves(' faith-old '), isTrue);
      expect(c.involves('faith-new'), isTrue);
      expect(c.involves('faith-z'), isFalse);
      expect(c.mechanismLabel, 'Missionary');
    });

    test('self-conversion is rejected', () {
      expect(
        () => conversion('cv-2', from: 'same', to: 'same'),
        throwsArgumentError,
      );
    });

    test('duplicate group ids rejected', () {
      expect(() => conversion('cv-3', groups: ['g', 'g']), throwsArgumentError);
    });
  });

  group('ReformEvent (reforms)', () {
    test('touchesDoctrine is trim-tolerant; doctrineIds sorted', () {
      final rf = reform('rf-1', doctrines: ['d2', 'd1']);
      expect(rf.doctrineIds, ['d1', 'd2']);
      expect(rf.touchesDoctrine(' d2 '), isTrue);
      expect(rf.touchesDoctrine('d9'), isFalse);
      expect(rf.kindLabel, 'Doctrinal');
    });

    test('duplicate doctrine ids rejected', () {
      expect(() => reform('rf-2', doctrines: ['d', 'd']), throwsArgumentError);
    });
  });

  group('PersecutionEvent (persecution)', () {
    test('severity ladder weights strictly increase', () {
      expect(PersecutionSeverity.discrimination.weight, 1);
      expect(PersecutionSeverity.execution.weight, 4);
      for (var i = 1; i < PersecutionSeverity.values.length; i++) {
        expect(
          PersecutionSeverity.values[i].weight,
          greaterThan(PersecutionSeverity.values[i - 1].weight),
        );
      }
      expect(
        PersecutionSeverity.execution.atLeast(
          PersecutionSeverity.propertySeizure,
        ),
        isTrue,
      );
      expect(
        PersecutionSeverity.discrimination.atLeast(
          PersecutionSeverity.execution,
        ),
        isFalse,
      );
    });

    test('validates required fields and victim count', () {
      final p = persecution('pe-1', victims: 12);
      expect(p.estimatedVictims, 12);
      expect(p.perpetrator, 'empire-x');
      expect(() => persecution('pe-2', victims: -5), throwsArgumentError);
      expect(
        () => PersecutionEvent.validated(
          persecutionId: 'pe-3',
          name: 'n',
          perpetrator: '  ',
          targetFaithId: 'f',
        ),
        throwsArgumentError,
      );
    });
  });

  group('SyncretismEvent (syncretism)', () {
    test('needs at least two sources', () {
      expect(() => syncretism('sy-1', sources: ['only']), throwsArgumentError);
    });

    test('result must not be one of the sources', () {
      expect(
        () => syncretism('sy-2', sources: ['a', 'b'], result: 'b'),
        throwsArgumentError,
      );
    });

    test('duplicate sources and elements rejected', () {
      expect(
        () => syncretism('sy-3', sources: ['a', 'a']),
        throwsArgumentError,
      );
      expect(
        () => syncretism('sy-4', elements: ['e', ' e ']),
        throwsArgumentError,
      );
    });

    test('involves matches sources and result', () {
      final s = syncretism('sy-5', sources: ['a', 'b'], result: 'c');
      expect(s.involves('a'), isTrue);
      expect(s.involves(' c '), isTrue);
      expect(s.involves('z'), isFalse);
      expect(s.sourceFaithIds, ['a', 'b']);
    });
  });

  group('BeliefDistributionRecord integrity', () {
    test('accepts a coherent full record', () {
      final r = record(
        ranges: [
          range('tr-1'),
          range('tr-2', to: 'end', seq: 0),
        ],
        entries: [entry('north', 'tr-1'), entry('south', 'tr-2')],
        conversions: [conversion('cv-1', timeRangeId: 'tr-2')],
        reforms: [reform('rf-1', timeRangeId: 'tr-1')],
        persecutions: [persecution('pe-1')],
        syncretisms: [syncretism('sy-1', timeRangeId: 'tr-2')],
      );
      expect(r.timeRangeCount, 2);
      expect(r.regionEntryCount, 2);
      expect(r.conversionCount, 1);
      expect(r.reformCount, 1);
      expect(r.persecutionCount, 1);
      expect(r.syncretismCount, 1);
      expect(r.totalEventCount, 4);
    });

    test('duplicate ids inside a collection rejected', () {
      expect(
        () => record(ranges: [range('dup'), range('dup')]),
        throwsArgumentError,
      );
      expect(
        () => record(
          ranges: [range('tr-1')],
          entries: [entry('r', 'tr-1'), entry('r', 'tr-1')],
        ),
        throwsArgumentError,
      );
    });

    test('same region in different ranges is allowed', () {
      final r = record(
        ranges: [range('tr-1'), range('tr-2')],
        entries: [entry('north', 'tr-1'), entry('north', 'tr-2')],
      );
      expect(r.regionEntryCount, 2);
      expect(r.entriesForRegion('north').length, 2);
    });

    test('events referencing unknown time range rejected', () {
      expect(
        () => record(conversions: [conversion('cv', timeRangeId: 'ghost')]),
        throwsArgumentError,
      );
      expect(
        () => record(reforms: [reform('rf', timeRangeId: 'ghost')]),
        throwsArgumentError,
      );
      expect(
        () => record(persecutions: [persecution('pe', timeRangeId: 'ghost')]),
        throwsArgumentError,
      );
      expect(
        () => record(syncretisms: [syncretism('sy', timeRangeId: 'ghost')]),
        throwsArgumentError,
      );
      expect(() => record(entries: [entry('r', 'ghost')]), throwsArgumentError);
    });

    test('region entries require a declared range even when empty list', () {
      expect(() => record(entries: [entry('r', 'tr-1')]), throwsArgumentError);
    });

    test('distributionId and theologyId required', () {
      expect(
        () => BeliefDistributionRecord.validated(
          distributionId: ' ',
          theologyId: 't',
        ),
        throwsArgumentError,
      );
      expect(
        () => BeliefDistributionRecord.validated(
          distributionId: 'd',
          theologyId: '',
        ),
        throwsArgumentError,
      );
    });
  });

  group('BeliefDistributionRecord derived indexes', () {
    final r = record(
      ranges: [
        range('tr-a', to: 'close-a', seq: 2),
        range('tr-b', to: 'close-b', seq: 1),
        range('tr-c'),
      ],
      entries: [
        entry('north', 'tr-a', adherents: 60, population: 200),
        entry('south', 'tr-b', adherents: 90, population: 100),
        entry('east', 'tr-c', adherents: 10),
      ],
      conversions: [
        conversion('cv-1', mechanism: ConversionMechanism.trade),
        conversion('cv-2', mechanism: ConversionMechanism.trade),
        conversion(
          'cv-3',
          from: 'faith-c',
          to: 'faith-new',
          mechanism: ConversionMechanism.decree,
        ),
      ],
      reforms: [reform('rf-1', institutionId: 'inst-1')],
      persecutions: [
        persecution('pe-1', severity: PersecutionSeverity.imprisonment),
        persecution('pe-2', severity: PersecutionSeverity.discrimination),
      ],
      syncretisms: [
        syncretism('sy-1', sources: ['faith-a', 'faith-b']),
      ],
    );

    test('sorted id getters are immutable', () {
      expect(r.timeRangeIds, ['tr-a', 'tr-b', 'tr-c']);
      expect(r.regionIds, ['east', 'north', 'south']);
      expect(
        r.faithIdsMentioned,
        containsAll(<String>['faith-old', 'faith-new', 'faith-c']),
      );
      expect(r.faithIdsMentioned, r.faithIdsMentioned.toList()..sort());
    });

    test('adherent aggregation and dominant region', () {
      expect(r.totalAdherents, 160);
      expect(r.dominantRegion, 'south');
      expect(r.averageShare, closeTo((0.3 + 0.9) / 2, 1e-12));
    });

    test('dominant region ties break on regionId ascending', () {
      final tie = record(
        ranges: [range('tr-1')],
        entries: [
          entry('zeta', 'tr-1', adherents: 50),
          entry('alpha', 'tr-1', adherents: 50),
        ],
      );
      expect(tie.dominantRegion, 'alpha');
    });

    test('dominantRegion and averageShare null on empty record', () {
      final empty = record();
      expect(empty.dominantRegion, isNull);
      expect(empty.averageShare, isNull);
      expect(empty.totalAdherents, 0);
    });

    test('entriesForRegion and entriesForTimeRange filter', () {
      expect(r.entriesForRegion('north').single.timeRangeId, 'tr-a');
      expect(r.entriesForRegion('nope'), isEmpty);
      expect(r.entriesForTimeRange('tr-b').single.regionId, 'south');
    });

    test('ongoingRangeIds and sortedTimeRanges', () {
      expect(r.ongoingRangeIds, ['tr-c']);
      expect(r.sortedTimeRanges.map((e) => e.rangeId).toList(), [
        'tr-b',
        'tr-a',
        'tr-c',
      ]);
    });

    test('conversionsWithMechanism filters', () {
      expect(r.conversionsWithMechanism(ConversionMechanism.trade).length, 2);
      expect(
        r.conversionsWithMechanism(ConversionMechanism.conquest).isEmpty,
        isTrue,
      );
    });

    test('reformIdsForInstitution and persecutionsAtLeast', () {
      expect(r.reformIdsForInstitution('inst-1'), ['rf-1']);
      expect(r.reformIdsForInstitution('inst-9'), isEmpty);
      expect(
        r
            .persecutionsAtLeast(PersecutionSeverity.imprisonment)
            .single
            .persecutionId,
        'pe-1',
      );
      expect(r.maxPersecutionSeverity, PersecutionSeverity.imprisonment);
    });

    test('syncretismsInvolvingFaith covers sources and result', () {
      expect(
        r.syncretismsInvolvingFaith('faith-a').single.syncretismId,
        'sy-1',
      );
      expect(r.syncretismsInvolvingFaith('faith-z'), isEmpty);
    });

    test('timeRangeFor trims lookup', () {
      expect(r.timeRangeFor(' tr-b ')?.sequence, 1);
      expect(r.timeRangeFor('missing'), isNull);
    });
  });

  group('BeliefDistributionQuery', () {
    final r = record(
      ranges: [range('tr-1')],
      entries: [entry('north', 'tr-1')],
      conversions: [conversion('cv-1', mechanism: ConversionMechanism.trade)],
      reforms: [reform('rf-1', kind: ReformKind.liturgical)],
      persecutions: [
        persecution('pe-1', severity: PersecutionSeverity.execution),
      ],
      syncretisms: [syncretism('sy-1', result: 'merged')],
    );

    test('empty query matches everything and describes itself', () {
      const q = BeliefDistributionQuery();
      expect(q.isEmpty, isTrue);
      expect(q.matches(r), isTrue);
      expect(q.describe(), 'BeliefDistributionQuery(no filters)');
    });

    test('regionId, mechanism, reformKind, minSeverity, faithId', () {
      expect(
        const BeliefDistributionQuery(regionId: 'north').matches(r),
        isTrue,
      );
      expect(
        const BeliefDistributionQuery(regionId: 'south').matches(r),
        isFalse,
      );
      expect(
        const BeliefDistributionQuery(
          mechanism: ConversionMechanism.trade,
        ).matches(r),
        isTrue,
      );
      expect(
        const BeliefDistributionQuery(
          mechanism: ConversionMechanism.decree,
        ).matches(r),
        isFalse,
      );
      expect(
        const BeliefDistributionQuery(
          reformKind: ReformKind.liturgical,
        ).matches(r),
        isTrue,
      );
      expect(
        const BeliefDistributionQuery(
          minSeverity: PersecutionSeverity.execution,
        ).matches(r),
        isTrue,
      );
      expect(
        const BeliefDistributionQuery(faithId: 'merged').matches(r),
        isTrue,
      );
      expect(
        const BeliefDistributionQuery(faithId: 'nope').matches(r),
        isFalse,
      );
    });

    test('describe lists active filters', () {
      const q = BeliefDistributionQuery(
        regionId: 'north',
        mechanism: ConversionMechanism.trade,
      );
      expect(q.describe(), contains('region: north'));
      expect(q.describe(), contains('mechanism: Trade'));
    });
  });

  group('BeliefDistributionCatalog', () {
    final north = record(
      id: 'dist-n',
      ranges: [range('tr-1')],
      entries: [entry('north', 'tr-1')],
      persecutions: [
        persecution('pe-1', severity: PersecutionSeverity.execution),
      ],
    );
    final south = record(
      id: 'dist-s',
      ranges: [range('tr-2')],
      entries: [
        entry('south', 'tr-2', groups: ['g1']),
      ],
      conversions: [conversion('cv-9', to: 'unique-faith')],
    );
    final catalog = BeliefDistributionCatalog.withRecords([north, south]);

    test('empty catalog', () {
      final e = BeliefDistributionCatalog.empty();
      expect(e.records, isEmpty);
      expect(e.distributionIds, isEmpty);
      expect(e.totalRegionEntryCount, 0);
      expect(e.totalEventCount, 0);
    });

    test('withRecords sorts by distributionId and rejects duplicates', () {
      expect(catalog.distributionIds, ['dist-n', 'dist-s']);
      expect(
        () => BeliefDistributionCatalog.withRecords([north, north]),
        throwsArgumentError,
      );
    });

    test('recordFor trims and misses return null', () {
      expect(catalog.recordFor(' dist-n ')?.distributionId, 'dist-n');
      expect(catalog.recordFor('ghost'), isNull);
    });

    test('aggregates counts across records', () {
      expect(catalog.totalRegionEntryCount, 2);
      expect(catalog.totalEventCount, 2);
    });

    test('reverse indexes by region, faith, and severity', () {
      expect(catalog.distributionIdsForRegion('north'), ['dist-n']);
      expect(catalog.distributionIdsMentioningFaith('unique-faith'), [
        'dist-s',
      ]);
      expect(
        catalog.distributionIdsWithPersecutionAtLeast(
          PersecutionSeverity.imprisonment,
        ),
        ['dist-n'],
      );
      expect(
        catalog.distributionIdsWithPersecutionAtLeast(
          PersecutionSeverity.discrimination,
        ),
        ['dist-n'],
      );
    });

    test('query returns sorted subset', () {
      final hits = catalog.query(
        const BeliefDistributionQuery(regionId: 'south'),
      );
      expect(hits.single.distributionId, 'dist-s');
      expect(catalog.query(const BeliefDistributionQuery()).length, 2);
    });
  });
}
