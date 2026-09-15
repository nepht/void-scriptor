// Sprint 111.37 — Unified Encyclopedia Search (domain-only).
//
// Acceptance canonical: cross_domain_search, filters, facets,
// permission_filter, keyboard_navigation, saved_search.
//
// Konsumsi TANPA duplikasi tipe:
//  - EncyclopediaRecord/EncyclopediaDomain/CanonStatus 111.6
//    (shared_encyclopedia_schema.dart)
//  - ValidityRange 111.5 (encyclopedia_scope.dart) utk filter waktu
//  - SpoilerPolicy/SpoilerLevel 111.8 + KeyboardShortcut/
//    KeyboardNavigationMap 111.8 utk permission_filter dan
//    keyboard_navigation
//
// Domain-only: deterministik, tanpa persistence/UI/wall-clock/random/
// network. saved_search = registry in-memory + kontrak JSON (D-SCHEMA-01
// tetap OPEN; belum ada tabel Drift).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_scope.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_spoiler_accessibility.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_unified_search.dart';
import 'package:void_scriptor/features/world_logic/domain/shared_encyclopedia_schema.dart';

EncyclopediaRecord rec(
  String id,
  EncyclopediaDomain domain,
  String title, {
  String? category,
  CanonStatus canon = CanonStatus.canon,
  List<String> regions = const [],
}) {
  return EncyclopediaRecord.validated(
    recordId: id,
    domain: domain,
    title: title,
    taxonomyCategoryId: category,
    canonStatus: canon,
    scopeLocations: regions,
  );
}

EncyclopediaSearchDocument doc(
  String id,
  EncyclopediaDomain domain,
  String title, {
  List<String> aliases = const [],
  String? category,
  List<String> cultures = const [],
  List<String> regions = const [],
  CanonStatus canon = CanonStatus.canon,
  ValidityRange? validity,
  SpoilerLevel spoiler = SpoilerLevel.safe,
}) {
  return EncyclopediaSearchDocument.validated(
    record: rec(
      id,
      domain,
      title,
      category: category,
      canon: canon,
      regions: regions,
    ),
    aliases: aliases,
    cultureIds: cultures,
    validity: validity,
    spoilerLevel: spoiler,
  );
}

final _kSampleIndex = EncyclopediaSearchIndex.withDocuments([
  doc(
    'h01',
    EncyclopediaDomain.herbology,
    'Void Fern',
    aliases: ['shadowleaf'],
    category: 'plants',
    cultures: ['pole-culture'],
    regions: ['north'],
  ),
  doc(
    'b01',
    EncyclopediaDomain.bestiary,
    'Void Cube',
    aliases: ['the cube'],
    category: 'creatures',
    cultures: ['void-sect'],
  ),
  doc(
    'a01',
    EncyclopediaDomain.artifacts,
    'Cube of Ending',
    category: 'relics',
    canon: CanonStatus.myth,
    spoiler: SpoilerLevel.ending,
  ),
  doc(
    'm01',
    EncyclopediaDomain.mythTheology,
    'Void Prophecy',
    aliases: ['ending prophecy'],
    category: 'myths',
    spoiler: SpoilerLevel.major,
    validity: ValidityRange.validated(validFrom: 10, validUntil: 50),
  ),
  doc(
    'i01',
    EncyclopediaDomain.idioms,
    'Speak the Void',
    aliases: ['void saying'],
    category: 'sayings',
    cultures: ['pole-culture'],
  ),
  doc(
    'n01',
    EncyclopediaDomain.names,
    'Voidborn',
    aliases: ['void name'],
    category: 'names',
    regions: ['south'],
  ),
]);

void main() {
  group('EncyclopediaSearchDocument 111.6/111.5/111.8 consumption', () {
    test('validated menormalkan alias/culture dan mewarisi field record', () {
      final d = doc(
        ' x1 ',
        EncyclopediaDomain.herbology,
        '  Thistle Root  ',
        aliases: ['  Mudblood  ', 'mudb'],
        cultures: [' marsh '],
        regions: ['fen', ' fen '],
      );
      expect(d.recordId, 'x1');
      expect(d.title, 'Thistle Root');
      expect(d.domain, EncyclopediaDomain.herbology);
      expect(d.aliases, ['mudblood', 'mudb']);
      expect(d.cultureIds, ['marsh']);
      expect(d.regionIds, ['fen']);
      expect(d.spoilerLevel, SpoilerLevel.safe);
      expect(d.validity, isNull);
    });

    test('title/recordId kosong dan alias whitespace-only ditolak', () {
      expect(
        () => doc('  ', EncyclopediaDomain.herbology, 'Ok'),
        throwsArgumentError,
      );
      expect(
        () => doc('ok', EncyclopediaDomain.herbology, '   '),
        throwsArgumentError,
      );
      expect(
        () => doc('ok', EncyclopediaDomain.herbology, 'Ok', aliases: ['   ']),
        throwsArgumentError,
      );
      expect(
        () =>
            doc('ok', EncyclopediaDomain.herbology, 'Ok', cultures: ['', ' ']),
        throwsArgumentError,
      );
    });

    test('toJson/fromJson byte-identik dan equality struktural', () {
      final d = doc(
        'k9',
        EncyclopediaDomain.names,
        'Kesh of the Pole',
        aliases: ['icekesh'],
        category: 'dynastic',
        cultures: ['pole-culture'],
        regions: ['north'],
        canon: CanonStatus.rumor,
        validity: ValidityRange.validated(validFrom: 3),
        spoiler: SpoilerLevel.mild,
      );
      final json = d.toJson();
      expect(jsonEncode(json), jsonEncode(d.toJson()));
      final back = EncyclopediaSearchDocument.fromJson(json);
      expect(jsonEncode(back.toJson()), jsonEncode(json));
      expect(back, d);
    });

    test('fromJson menolak domain/canon/spoiler/tick tak sah', () {
      final base = doc('k9', EncyclopediaDomain.names, 'Kesh').toJson();
      expect(
        () => EncyclopediaSearchDocument.fromJson({
          ...base,
          'domainId': 'nonsense',
        }),
        throwsArgumentError,
      );
      expect(
        () => EncyclopediaSearchDocument.fromJson({
          ...base,
          'canonStatus': 'bogus',
        }),
        throwsArgumentError,
      );
      expect(
        () => EncyclopediaSearchDocument.fromJson({
          ...base,
          'spoilerLevel': 'nope',
        }),
        throwsArgumentError,
      );
      expect(
        () => EncyclopediaSearchDocument.fromJson({
          ...base,
          'validity': {'validFrom': 5, 'validUntil': 4},
        }),
        throwsArgumentError,
      );
    });
  });

  group('EncyclopediaSearchIndex + cross_domain_search', () {
    test('register menolak recordId duplikat dan snapshot immutable urut', () {
      final index = EncyclopediaSearchIndex.empty();
      index.register(doc('z1', EncyclopediaDomain.herbology, 'Zee'));
      expect(
        () => index.register(doc('z1', EncyclopediaDomain.bestiary, 'Dup')),
        throwsStateError,
      );
      index.register(doc('a2', EncyclopediaDomain.bestiary, 'Aye'));
      expect(index.count, 2);
      expect(index.recordIds, ['a2', 'z1']);
      expect(() => index.documents.clear(), throwsUnsupportedError);
    });

    test('withDocuments menolak id duplikat lintas domain', () {
      expect(
        () => EncyclopediaSearchIndex.withDocuments([
          doc('d1', EncyclopediaDomain.herbology, 'One'),
          doc('d1', EncyclopediaDomain.artifacts, 'Two'),
        ]),
        throwsStateError,
      );
    });

    test(
      'teks kosong = semua dokumen lolos, urut recordId asc deterministik',
      () {
        final report = _kSampleIndex.search(EncyclopediaSearchQuery());
        expect(report.totalMatches, 6);
        final ids = (report.hits.map((h) => h.recordId)).toList()..sort();
        expect(ids, ['a01', 'b01', 'h01', 'i01', 'm01', 'n01']);
        expect(report.hits.every((h) => h.score == 0), isTrue);
      },
    );

    test('satu query teks menembus SEMUA domain sekaligus (cross_domain)', () {
      final report = _kSampleIndex.search(
        EncyclopediaSearchQuery(text: 'void'),
      );
      final ids = report.hits.map((h) => h.recordId).toSet();
      expect(ids, containsAll(<String>['h01', 'b01', 'm01', 'i01', 'n01']));
      expect(
        ids.contains('a01'),
        isFalse,
        reason: 'Cube of Ending tidak memuat token "void"',
      );
      final domains = report.hits.map((h) => h.document.domain).toSet();
      expect(domains.length, greaterThanOrEqualTo(4));
    });

    test('ranking deterministik: exact > prefix > contains; skor gabungan', () {
      final report = _kSampleIndex.search(
        EncyclopediaSearchQuery(text: 'void cube'),
      );
      // OR-semantics default: "Void Cube" cocok kedua token (skor tertinggi),
      // "Cube of Ending" hanya "cube", "Void Fern" hanya "void".
      final ids = report.hits.map((h) => h.recordId).toList();
      expect(ids.first, 'b01');
      expect(report.hits.first.score, greaterThan(report.hits[1].score));
      expect(ids, containsAll(<String>['a01', 'h01']));
      // determinisme byte-identik antar panggilan
      final again = _kSampleIndex.search(
        EncyclopediaSearchQuery(text: 'void cube'),
      );
      expect(jsonEncode(again.toJson()), jsonEncode(report.toJson()));
    });

    test('requireAllTerms = AND ketat — token tak cocok = nol hasil', () {
      final report = _kSampleIndex.search(
        EncyclopediaSearchQuery(text: 'void zzzmissing', requireAllTerms: true),
      );
      expect(report.hits, isEmpty);
      expect(report.totalMatches, 0);
      expect(report.truncated, isFalse);
      final two = _kSampleIndex.search(
        EncyclopediaSearchQuery(text: 'void cube', requireAllTerms: true),
      );
      expect(two.hits.single.recordId, 'b01');
    });

    test('teks toleran kasus/whitespace berlebih', () {
      final a = _kSampleIndex.search(
        EncyclopediaSearchQuery(text: '  VOID   FERN ', requireAllTerms: true),
      );
      final b = _kSampleIndex.search(
        EncyclopediaSearchQuery(text: 'void fern', requireAllTerms: true),
      );
      expect(jsonEncode(a.toJson()), jsonEncode(b.toJson()));
      expect(a.hits.single.recordId, 'h01');
    });

    test('limit memangkas hits tetapi totalMatches tetap penuh', () {
      final report = _kSampleIndex.search(
        EncyclopediaSearchQuery(text: 'void', limit: 2),
      );
      expect(report.hits.length, 2);
      expect(report.totalMatches, 5);
      expect(report.truncated, isTrue);
      // facet dihitung dari SEMUA match ter izin, bukan hanya hits
      expect(report.facets.totalCount, 5);
    });

    test('limit divalidasi 1..512', () {
      expect(
        () => EncyclopediaSearchQuery(text: 'x', limit: 0),
        throwsArgumentError,
      );
      expect(
        () => EncyclopediaSearchQuery(text: 'x', limit: 513),
        throwsArgumentError,
      );
    });
  });

  group('filters (AND, set kosong = tanpa pembatasan)', () {
    test('filter domain', () {
      final report = _kSampleIndex.search(
        EncyclopediaSearchQuery(
          domains: {EncyclopediaDomain.herbology, EncyclopediaDomain.names},
        ),
      );
      final ids = report.hits.map((h) => h.recordId).toList()..sort();
      expect(ids, ['h01', 'n01']);
    });

    test('filter category, culture, region, canon', () {
      expect(
        _kSampleIndex
            .search(EncyclopediaSearchQuery(categoryIds: {'myths'}))
            .hits
            .single
            .recordId,
        'm01',
      );
      expect(
        _kSampleIndex
            .search(EncyclopediaSearchQuery(cultureIds: {'pole-culture'}))
            .hits
            .map((h) => h.recordId),
        ['h01', 'i01'],
      );
      expect(
        _kSampleIndex
            .search(EncyclopediaSearchQuery(regionIds: {'north'}))
            .hits
            .map((h) => h.recordId),
        ['h01'],
      );
      expect(
        _kSampleIndex
            .search(EncyclopediaSearchQuery(canonStatuses: {CanonStatus.myth}))
            .hits
            .map((h) => h.recordId),
        ['a01'],
      );
    });

    test('filter waktu atTick memakai ValidityRange 111.5 inklusif', () {
      final inside = _kSampleIndex.search(
        EncyclopediaSearchQuery(text: 'void', atTick: 10),
      );
      expect(
        inside.hits.map((h) => h.recordId).contains('m01'),
        isTrue,
        reason: 'validFrom=10 inklusif',
      );
      final outside = _kSampleIndex.search(
        EncyclopediaSearchQuery(text: 'void', atTick: 51),
      );
      expect(
        outside.hits.map((h) => h.recordId).contains('m01'),
        isFalse,
        reason: 'validUntil=50; 51 di luar jendela',
      );
      // dokumen tanpa validity tetap lolos
      expect(outside.hits.map((h) => h.recordId).contains('h01'), isTrue);
    });

    test('filter kosong = isEmpty true dan tidak membatasi', () {
      final q = EncyclopediaSearchQuery();
      expect(q.isEmpty, isTrue);
      expect(q.hasFilters, isFalse);
      expect(EncyclopediaSearchQuery(text: '   ').isEmpty, isTrue);
    });

    test('AND lintas filter; idk tak kenal menghasilkan nol hasil', () {
      final report = _kSampleIndex.search(
        EncyclopediaSearchQuery(
          text: 'void',
          domains: {EncyclopediaDomain.idioms},
          cultureIds: {'pole-culture'},
        ),
      );
      expect(report.hits.single.recordId, 'i01');
      expect(
        _kSampleIndex
            .search(EncyclopediaSearchQuery(cultureIds: {'nope'}))
            .hits,
        isEmpty,
      );
    });

    test(
      'query id toleran whitespace/kasus; entri blank-after-trim ditolak',
      () {
        final q = EncyclopediaSearchQuery(categoryIds: {'  Myths  '});
        expect(q.categoryIds, {'myths'});
        expect(
          () => EncyclopediaSearchQuery(regionIds: {'   '}),
          throwsArgumentError,
        );
      },
    );

    test('atTick negatif ditolak', () {
      expect(() => EncyclopediaSearchQuery(atTick: -1), throwsArgumentError);
    });
  });

  group('facets', () {
    test('facet dihitung dari hasil terfilter query (bukan index penuh)', () {
      final facets = _kSampleIndex
          .search(EncyclopediaSearchQuery(text: 'void'))
          .facets;
      expect(facets.totalCount, 5);
      expect(facets.byDomain['idioms'], 1);
      expect(facets.byDomain['herbology'], 1);
      expect(facets.byCategory['sayings'], 1);
      expect(facets.byCanon['canon'], 5);
      expect(facets.byCulture['pole-culture'], 2);
      expect(facets.byRegion['north'], 1);
    });

    test('kategori null masuk bucket uncategorized', () {
      final idx = EncyclopediaSearchIndex.withDocuments([
        doc('u1', EncyclopediaDomain.mythTheology, 'Uncat Myth'),
      ]);
      final facets = idx.search(EncyclopediaSearchQuery()).facets;
      expect(facets.byCategory['uncategorized'], 1);
    });

    test('peta facet sorted key dan immutable; JSON roundtrip', () {
      final facets = _kSampleIndex
          .search(EncyclopediaSearchQuery(text: 'void'))
          .facets;
      expect(
        facets.byDomain.keys.toList(),
        facets.byDomain.keys.toList()..sort(),
      );
      expect(() => facets.byDomain['x'] = 1, throwsUnsupportedError);
      final back = EncyclopediaSearchFacets.fromJson(facets.toJson());
      expect(jsonEncode(back.toJson()), jsonEncode(facets.toJson()));
      expect(back.totalCount, facets.totalCount);
    });

    test('facet kosong saat nol hasil; describe menyebut total 0', () {
      final facets = _kSampleIndex
          .search(EncyclopediaSearchQuery(text: 'qqqzzz'))
          .facets;
      expect(facets.isEmpty, isTrue);
      expect(facets.describe(), contains('0'));
    });
  });

  group('permission_filter', () {
    test('default izin = semua lolos termasuk spoiler ending', () {
      final report = _kSampleIndex.search(
        EncyclopediaSearchQuery(text: 'cube'),
        permission: EncyclopediaPermissionFilter.allowAll(),
      );
      expect(report.hits.map((h) => h.recordId), contains('a01'));
    });

    test('SpoilerPolicy menyembunyikan dokumen di atas ambang audience', () {
      final permission = EncyclopediaPermissionFilter(
        spoilerPolicy: SpoilerPolicy(defaultLevel: SpoilerLevel.mild),
      );
      final report = _kSampleIndex.search(
        EncyclopediaSearchQuery(),
        permission: permission,
      );
      expect(report.totalMatches, 4); // a01(ending), m01(major) tersembunyi
      final ids = report.hits.map((h) => h.recordId).toSet();
      expect(ids, isNot(contains('a01')));
      expect(ids, isNot(contains('m01')));
    });

    test('override per-record menang atas default', () {
      final permission = EncyclopediaPermissionFilter(
        spoilerPolicy: SpoilerPolicy(
          defaultLevel: SpoilerLevel.safe,
          overrides: {'a01': SpoilerLevel.ending},
        ),
      );
      final report = _kSampleIndex.search(
        EncyclopediaSearchQuery(text: 'cube'),
        permission: permission,
      );
      expect(
        report.hits.map((h) => h.recordId).toSet(),
        containsAll(<String>['a01', 'b01']),
      );
      expect(report.hits.map((h) => h.recordId).contains('m01'), isFalse);
    });

    test(
      'dokumen tersembunyi tak bocor lewat facet maupun exact-name search',
      () {
        final permission = EncyclopediaPermissionFilter(
          spoilerPolicy: SpoilerPolicy(defaultLevel: SpoilerLevel.safe),
        );
        final report = _kSampleIndex.search(
          EncyclopediaSearchQuery(text: 'prophecy'),
          permission: permission,
        );
        expect(report.hits, isEmpty);
        expect(report.facets.totalCount, 0);
        expect(report.facets.byCanon.containsKey('canon'), isFalse);
      },
    );

    test('allowlist canon membatasi tanpa mengubah filter query', () {
      final permission = EncyclopediaPermissionFilter(
        spoilerPolicy: SpoilerPolicy(),
        allowedCanonStatuses: {CanonStatus.canon},
      );
      final report = _kSampleIndex.search(
        EncyclopediaSearchQuery(text: 'cube'),
        permission: permission,
      );
      expect(report.hits.map((h) => h.recordId), ['b01']);
    });

    test(
      'permission filter toJSON-describe deterministik; default = allow all',
      () {
        final p = EncyclopediaPermissionFilter(
          spoilerPolicy: SpoilerPolicy(defaultLevel: SpoilerLevel.major),
          allowedCanonStatuses: {CanonStatus.canon, CanonStatus.myth},
        );
        expect(p.permitsCanon(CanonStatus.rumor), isFalse);
        expect(p.permitsCanon(CanonStatus.canon), isTrue);
        expect(jsonEncode(p.toJson()), jsonEncode(p.toJson()));
        final back = EncyclopediaPermissionFilter.fromJson(p.toJson());
        expect(jsonEncode(back.toJson()), jsonEncode(p.toJson()));
        expect(EncyclopediaPermissionFilter.allowAll().describe(), isNotEmpty);
      },
    );

    test('fromJson permission menolak level/status bogus', () {
      final p = EncyclopediaPermissionFilter(
        spoilerPolicy: SpoilerPolicy(),
        allowedCanonStatuses: {CanonStatus.canon},
      ).toJson();
      expect(
        () => EncyclopediaPermissionFilter.fromJson({
          ...p,
          'defaultSpoiler': 'wat',
        }),
        throwsArgumentError,
      );
      expect(
        () => EncyclopediaPermissionFilter.fromJson({
          ...p,
          'allowedCanonStatuses': ['wat'],
        }),
        throwsArgumentError,
      );
    });
  });

  group('keyboard_navigation', () {
    test('peta standar memuat keempat aksi tanpa konflik', () {
      final map = EncyclopediaKeyboardNavigation.standardMap();
      expect(
        map.bindingFor(EncyclopediaKeyboardNavigation.actionFirst),
        isNotNull,
      );
      expect(
        map.bindingFor(EncyclopediaKeyboardNavigation.actionPrevious),
        isNotNull,
      );
      expect(
        map.bindingFor(EncyclopediaKeyboardNavigation.actionNext),
        isNotNull,
      );
      expect(
        map.bindingFor(EncyclopediaKeyboardNavigation.actionLast),
        isNotNull,
      );
    });

    test('aksi tak dikenal ditolak', () {
      final nav = EncyclopediaKeyboardNavigation(
        map: EncyclopediaKeyboardNavigation.standardMap(),
      );
      expect(
        () => nav.selectedIndexFor('nope', resultCount: 3, selectedIndex: 0),
        throwsArgumentError,
      );
    });

    test('first/previous/next/last dengan clamp tanpa wrap', () {
      final nav = EncyclopediaKeyboardNavigation(
        map: EncyclopediaKeyboardNavigation.standardMap(),
      );
      const first = EncyclopediaKeyboardNavigation.actionFirst;
      const prev = EncyclopediaKeyboardNavigation.actionPrevious;
      const next = EncyclopediaKeyboardNavigation.actionNext;
      const last = EncyclopediaKeyboardNavigation.actionLast;
      expect(nav.selectedIndexFor(last, resultCount: 5, selectedIndex: 1), 4);
      expect(
        nav.selectedIndexFor(next, resultCount: 5, selectedIndex: 4),
        4,
        reason: 'clamp di akhir, tanpa wrap',
      );
      expect(nav.selectedIndexFor(first, resultCount: 5, selectedIndex: 3), 0);
      expect(
        nav.selectedIndexFor(prev, resultCount: 5, selectedIndex: 0),
        0,
        reason: 'clamp di awal, tanpa wrap',
      );
      expect(nav.selectedIndexFor(prev, resultCount: 5, selectedIndex: 3), 2);
    });

    test('hasil kosong = seleksi null; selectedIndex negatif ditolak', () {
      final nav = EncyclopediaKeyboardNavigation(
        map: EncyclopediaKeyboardNavigation.standardMap(),
      );
      expect(
        nav.selectedIndexFor(
          EncyclopediaKeyboardNavigation.actionNext,
          resultCount: 0,
          selectedIndex: 0,
        ),
        isNull,
      );
      expect(
        () => nav.selectedIndexFor(
          EncyclopediaKeyboardNavigation.actionFirst,
          resultCount: 3,
          selectedIndex: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => nav.selectedIndexFor(
          EncyclopediaKeyboardNavigation.actionFirst,
          resultCount: 3,
          selectedIndex: 9,
        ),
        throwsArgumentError,
      );
    });

    test('peta custom dengan binding konflik tetap menolak (111.8 guard)', () {
      final map = KeyboardNavigationMap()
          .add(
            const KeyboardShortcut(
              action: EncyclopediaKeyboardNavigation.actionFirst,
              key: 'Home',
            ),
          )
          .add(
            const KeyboardShortcut(
              action: EncyclopediaKeyboardNavigation.actionLast,
              key: 'End',
            ),
          );
      final nav = EncyclopediaKeyboardNavigation(map: map);
      // hanya two aksi terdaftar; dua lainnya harus ditolak eksplisit
      expect(
        () => nav.selectedIndexFor(
          EncyclopediaKeyboardNavigation.actionNext,
          resultCount: 3,
          selectedIndex: 0,
        ),
        throwsStateError,
      );
      expect(
        nav.selectedIndexFor(
          EncyclopediaKeyboardNavigation.actionFirst,
          resultCount: 3,
          selectedIndex: 1,
        ),
        0,
      );
    });
  });

  group('saved_search', () {
    test('SavedEncyclopediaSearch.validated menolak id/label kosong', () {
      expect(
        () => SavedEncyclopediaSearch.validated(
          searchId: ' ',
          label: 'Void',
          query: EncyclopediaSearchQuery(),
        ),
        throwsArgumentError,
      );
      expect(
        () => SavedEncyclopediaSearch.validated(
          searchId: 's1',
          label: '  ',
          query: EncyclopediaSearchQuery(),
        ),
        throwsArgumentError,
      );
    });

    test('registry add/remove dengan guard unik id', () {
      final registry = SavedSearchRegistry.empty();
      registry.add(
        SavedEncyclopediaSearch.validated(
          searchId: 'b2',
          label: 'B cube',
          query: EncyclopediaSearchQuery(text: 'cube'),
        ),
      );
      registry.add(
        SavedEncyclopediaSearch.validated(
          searchId: 'a1',
          label: 'All names',
          query: EncyclopediaSearchQuery(domains: {EncyclopediaDomain.names}),
        ),
      );
      expect(
        () => registry.add(
          SavedEncyclopediaSearch.validated(
            searchId: 'a1',
            label: 'dup',
            query: EncyclopediaSearchQuery(),
          ),
        ),
        throwsStateError,
      );
      expect(registry.entries.map((s) => s.searchId), ['a1', 'b2']);
      expect(registry.remove('b2'), isTrue);
      expect(registry.remove('b2'), isFalse);
      expect(registry.count, 1);
      expect(registry.entryFor('missing'), isNull);
    });

    test('saved search yang dijalankan mengembalikan hasil query aslinya', () {
      final registry = SavedSearchRegistry.withEntries([
        SavedEncyclopediaSearch.validated(
          searchId: 's1',
          label: 'Void things',
          query: EncyclopediaSearchQuery(text: 'void'),
        ),
      ]);
      final saved = registry.entryFor('s1')!;
      final report = _kSampleIndex.search(saved.query);
      expect(report.totalMatches, 5);
    });

    test('JSON roundtrip byte-identik untuk query + registry', () {
      final query = EncyclopediaSearchQuery(
        text: 'void',
        domains: {EncyclopediaDomain.herbology, EncyclopediaDomain.names},
        categoryIds: {'myths'},
        cultureIds: {'pole-culture'},
        regionIds: {'north'},
        canonStatuses: {CanonStatus.canon, CanonStatus.myth},
        atTick: 12,
        limit: 7,
      );
      final qj = query.toJson();
      expect(jsonEncode(qj), jsonEncode(query.toJson()));
      expect(
        jsonEncode(EncyclopediaSearchQuery.fromJson(qj).toJson()),
        jsonEncode(qj),
      );
      final registry = SavedSearchRegistry.withEntries([
        SavedEncyclopediaSearch.validated(
          searchId: 's1',
          label: 'One',
          query: query,
        ),
      ]);
      final rj = registry.toJson();
      expect(jsonEncode(rj), jsonEncode(registry.toJson()));
      final back = SavedSearchRegistry.fromJson(rj);
      expect(jsonEncode(back.toJson()), jsonEncode(rj));
      expect(back.entryFor('s1')!.query, query);
    });

    test('query dariJson menolak domain/canon/limit/tick bogus', () {
      final base = EncyclopediaSearchQuery(text: 'x').toJson();
      expect(
        () => EncyclopediaSearchQuery.fromJson({
          ...base,
          'domains': ['nonsense'],
        }),
        throwsArgumentError,
      );
      expect(
        () => EncyclopediaSearchQuery.fromJson({
          ...base,
          'canonStatuses': ['bogus'],
        }),
        throwsArgumentError,
      );
      expect(
        () => EncyclopediaSearchQuery.fromJson({...base, 'limit': 0}),
        throwsArgumentError,
      );
      expect(
        () => EncyclopediaSearchQuery.fromJson({...base, 'atTick': -5}),
        throwsArgumentError,
      );
    });

    test('registry fromJson menolak duplikat dan field kosong', () {
      expect(
        () => SavedSearchRegistry.fromJson({
          'entries': [
            SavedEncyclopediaSearch.validated(
              searchId: 's',
              label: 'A',
              query: EncyclopediaSearchQuery(),
            ).toJson(),
            SavedEncyclopediaSearch.validated(
              searchId: 's',
              label: 'B',
              query: EncyclopediaSearchQuery(),
            ).toJson(),
          ],
        }),
        throwsStateError,
      );
      expect(
        () => SavedSearchRegistry.fromJson({
          'entries': [
            {
              'searchId': '',
              'label': 'x',
              'query': EncyclopediaSearchQuery().toJson(),
            },
          ],
        }),
        throwsArgumentError,
      );
    });
  });

  group('report & no-mutation contract', () {
    test('search tidak memutasi index (JSON sebelum/sesudah identik)', () {
      final index = EncyclopediaSearchIndex.withDocuments([
        doc(
          'p1',
          EncyclopediaDomain.artifacts,
          'Pole Star',
          category: 'relics',
        ),
        doc(
          'p2',
          EncyclopediaDomain.bestiary,
          'Pole Bear',
          cultures: ['pole-culture'],
        ),
      ]);
      final before = jsonEncode(index.toJson());
      index.search(EncyclopediaSearchQuery(text: 'pole'));
      index.search(
        EncyclopediaSearchQuery(domains: {EncyclopediaDomain.artifacts}),
      );
      expect(jsonEncode(index.toJson()), before);
    });

    test('report hits immutable dan describe menyebut total + truncated', () {
      final report = _kSampleIndex.search(
        EncyclopediaSearchQuery(text: 'void', limit: 2),
        permission: EncyclopediaPermissionFilter(
          spoilerPolicy: SpoilerPolicy(defaultLevel: SpoilerLevel.mild),
        ),
      );
      expect(() => report.hits.clear(), throwsUnsupportedError);
      expect(report.describe(), contains('truncated'));
      expect(report.describe(), contains('2'));
      // m01 (major) tersembunyi -> h01,b01,i01,n01 -> limit 2 truncated
      expect(report.totalMatches, 4);
      expect(report.hits.length, 2);
    });

    test('hit mengekspos recordId, score, document; equality struktural', () {
      final report = _kSampleIndex.search(
        EncyclopediaSearchQuery(text: 'Void Fern', requireAllTerms: true),
      );
      final hit = report.hits.single;
      expect(hit.recordId, 'h01');
      expect(hit.score, greaterThan(0));
      expect(hit.document.recordId, 'h01');
      final other = report.hits.single;
      expect(other, hit);
      expect(jsonEncode(hit.toJson()), jsonEncode(other.toJson()));
    });
  });
}
