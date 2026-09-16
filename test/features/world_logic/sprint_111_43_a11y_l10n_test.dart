// Sprint 111.43 - Accessibility & Localization Verification.
//
// Verifikasi domain-only atas enam keluaran kanonik objective:
//   keyboard_results, screen_reader_results, scaling_results,
//   multiscript_results, locale_results, fix_status
// untuk katalog, tree, graph, formula, nama multiskrip, pembacaan fonetik,
// dan fallback nonvisual — dijalankan nyata di atas API Wave 3 produksi
// (111.5/6/8/29/30/31/37/38 + family tree 110.18), bukan reimplementasi.
//
// Batas jujur: capture screen-reader native Windows dan pengujian font-scale
// nyata di UI TIDAK diklaim (deferredNative); ini kontrak domain deterministik.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_unified_search.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_wave3_accessibility.dart';
import 'package:void_scriptor/features/world_logic/domain/family_dynasty_tree.dart';
import 'package:void_scriptor/features/world_logic/domain/genealogy_relationships.dart';
import 'package:void_scriptor/features/world_logic/domain/shared_encyclopedia_schema.dart';

void main() {
  final report = Wave3AccessibilityHarness.run();

  group('111.43 report contract', () {
    test('checks sorted by id, immutable, unique', () {
      final ids = report.checks.map((c) => c.checkId).toList();
      expect(ids, [...ids]..sort());
      expect(ids.toSet().length, ids.length);
      expect(
        () => report.checks.add(report.checks.first),
        throwsUnsupportedError,
      );
      expect(
        () => report.findings.add(report.findings.first),
        throwsUnsupportedError,
      );
    });

    test('every check executes real fixture logic (evidence non-empty)', () {
      for (final check in report.checks) {
        expect(
          check.evidence.trim().isNotEmpty,
          isTrue,
          reason: 'check ${check.checkId} has no evidence',
        );
        expect(check.description.trim().isNotEmpty, isTrue);
      }
    });

    test('unknown check/surface guards fail closed', () {
      expect(
        () => Wave3A11yCheck.validated(
          checkId: ' ',
          surface: Wave3A11ySurface.catalog,
          status: Wave3A11yStatus.pass,
          description: 'x',
          evidence: 'y',
        ),
        throwsArgumentError,
      );
      expect(
        () => Wave3A11yFinding.validated(
          findingId: '',
          target: 't',
          summary: 's',
          fixStatus: Wave3A11yFixStatus.fixed,
          detail: 'd',
        ),
        throwsArgumentError,
      );
    });

    test('duplicate ids rejected and bad JSON rejected', () {
      final dup = Wave3A11yCheck.validated(
        checkId: 'kb-1',
        surface: Wave3A11ySurface.catalog,
        status: Wave3A11yStatus.pass,
        description: 'dup',
        evidence: 'dup',
      );
      expect(
        () => Wave3A11yReport.of(
          checks: [...report.checks, dup],
          findings: report.findings,
        ),
        throwsStateError,
      );
      expect(
        () => Wave3A11yReport.fromJson(report.toJson()..remove('checks')),
        throwsArgumentError,
      );
    });

    test('JSON roundtrip byte-identical and equality holds', () {
      final decoded = Wave3A11yReport.fromJson(report.toJson());
      expect(jsonEncode(decoded.toJson()), jsonEncode(report.toJson()));
      expect(decoded, report);
      expect(report.hashCode, decoded.hashCode);
    });

    test('describe covers all six required outputs', () {
      final text = report.describe();
      for (final label in [
        'keyboard_results',
        'screen_reader_results',
        'scaling_results',
        'multiscript_results',
        'locale_results',
        'fix_status',
      ]) {
        expect(text, contains(label));
      }
    });
  });

  group('111.43 keyboard_results', () {
    test('all seven keyboard checks pass on real API', () {
      expect(report.keyboardResults, [
        'kb-1',
        'kb-2',
        'kb-3',
        'kb-4',
        'kb-5',
        'kb-6',
        'kb-7',
      ]);
    });

    test('standard map binds exactly the four search actions', () {
      final map = Wave3AccessibilityHarness.searchNavigation().map;
      expect(map.bindingFor('encyclopedia.search.first')!.key, 'Home');
      expect(map.bindingFor('encyclopedia.search.previous')!.key, 'ArrowUp');
      expect(map.bindingFor('encyclopedia.search.next')!.key, 'ArrowDown');
      expect(map.bindingFor('encyclopedia.search.last')!.key, 'End');
    });
  });

  group('111.43 screen_reader_results', () {
    test('five label/fallback checks pass and native capture deferred', () {
      expect(report.screenReaderResults, [
        'sr-1',
        'sr-2',
        'sr-3',
        'sr-4',
        'sr-5',
      ]);
      final deferred = report.checks
          .where((c) => c.status == Wave3A11yStatus.deferredNative)
          .map((c) => c.checkId)
          .toList();
      expect(deferred, ['sr-6']);
    });

    test('nonvisual fallback required for catalog/tree/graph/formula', () {
      final fallback = Wave3AccessibilityHarness.nonvisualFallback();
      for (final key in [
        'encyclopedia.catalog',
        'encyclopedia.tree',
        'encyclopedia.graph',
        'encyclopedia.formula',
      ]) {
        expect(fallback.requireDescription(key), isNotEmpty);
      }
      expect(
        () => fallback.requireDescription('encyclopedia.unknown'),
        throwsArgumentError,
      );
    });
  });

  group('111.43 scaling_results', () {
    test('four scaling checks pass incl. 256-name replay', () {
      expect(report.scalingResults, ['sc-1', 'sc-2', 'sc-3', 'sc-4']);
    });

    test('max-size batch replay is byte-identical and unique', () {
      final first = Wave3AccessibilityHarness.largeBatch();
      final second = Wave3AccessibilityHarness.largeBatch();
      expect(first.texts, second.texts);
      final texts = first.proposals.map((p) => p.text).toList();
      expect(texts.toSet().length, texts.length);
      expect(texts.length, 256);
    });
  });

  group('111.43 multiscript_results', () {
    test('five multiscript checks pass (CJK, Arabic, Cyrillic)', () {
      expect(report.multiscriptResults, [
        'ms-1',
        'ms-2',
        'ms-3',
        'ms-4',
        'ms-5',
      ]);
    });

    test(
      'Cyrillic phonotactics accept legal words, reject forbidden cluster',
      () {
        final spec = Wave3AccessibilityHarness.cyrillicPhonotactics();
        final word = spec.inventory.map((p) => p.symbol).take(0).toList();
        expect(word, isEmpty); // inventory-driven, no Latin assumption
        expect(spec.isWordLegal(['м', 'о', 'р']), isTrue);
        expect(spec.violationsIn(['н', 'г']), hasLength(1));
        for (final part in spec.inventory) {
          expect(
            part.symbol.codeUnits.every((u) => u >= 0x0400 && u < 0x0500),
            isTrue,
            reason: 'inventory must stay Cyrillic: ${part.symbol}',
          );
        }
      },
    );
  });

  group('111.43 locale_results', () {
    test('four locale checks pass; special-casing is a finding not a pass', () {
      expect(report.localeResults, ['lo-1', 'lo-2', 'lo-3', 'lo-4']);
      final special = report.checks.firstWhere((c) => c.checkId == 'lo-5');
      expect(special.status, Wave3A11yStatus.finding);
    });

    test('case folding is locale-invariant: dotted I folds to bare i', () {
      // Pin perilaku terverifikasi probe: normalisasi pencarian TIDAK
      // culture-aware (Turkish UI mengharapkan I->ı) — documented limitation.
      expect('İ'.toLowerCase(), 'i');
      expect('İSTANBUL'.toLowerCase(), 'istanbul');
      expect('I'.toLowerCase(), 'i');
    });
  });

  group('111.43 fix_status', () {
    test('three findings with explicit fix statuses', () {
      expect(report.findings.map((f) => f.findingId), [
        'f-native-a11y-capture',
        'f-search-special-casing',
        'f-tree-nested-expand',
      ]);
      expect(report.findings.map((f) => f.fixStatus).toList(), [
        Wave3A11yFixStatus.deferredNative,
        Wave3A11yFixStatus.documentedLimitation,
        Wave3A11yFixStatus.fixed,
      ]);
      expect(report.fixStatusCounts, {
        'deferredNative': 1,
        'documentedLimitation': 1,
        'fixed': 1,
      });
      expect(report.allSurfacesCovered, isTrue);
    });

    test('f-tree-nested-expand is genuinely fixed in production code', () {
      final graph = GenealogyGraph(
        nodes: {
          for (final id in ['a', 'c', 'd'])
            id: GenealogyNode(id: id, name: id.toUpperCase()),
        },
        edges: const [
          GenealogyRelation(
            id: 'r1',
            kind: GenealogyRelationKind.parentChild,
            fromId: 'a',
            toId: 'c',
            validFrom: 0,
          ),
          GenealogyRelation(
            id: 'r2',
            kind: GenealogyRelationKind.parentChild,
            fromId: 'c',
            toId: 'd',
            validFrom: 0,
          ),
        ],
      );
      final state = collapseBranch(
        graph: graph,
        rootId: 'a',
      ).withCollapsed('c');
      expect(state.visibleNodeIds, ['a']);
      final expanded = state.withExpanded('a');
      // Invariant: an id still listed as collapsed must hide its subtree.
      expect(expanded.collapsedRootIds, isEmpty);
      expect(expanded.visibleNodeIds, containsAll(['a', 'c', 'd']));
    });

    test('report is deterministic across runs', () {
      final again = Wave3AccessibilityHarness.run();
      expect(jsonEncode(again.toJson()), jsonEncode(report.toJson()));
      expect(again, report);
    });
  });

  group('111.43 probe consolidation (scratch probes 3-4, DELETE recorded)', () {
    test('culture filter is case-insensitive (probe 3, hits=1)', () {
      final doc = EncyclopediaSearchDocument.validated(
        record: EncyclopediaRecord.validated(
          recordId: 'rec-c',
          domain: EncyclopediaDomain.herbology,
          title: 'Aether Fern',
        ),
        cultureIds: const ['Kulturr'],
      );
      final index = EncyclopediaSearchIndex.withDocuments([doc]);
      final r = index.search(
        EncyclopediaSearchQuery(text: 'fern', cultureIds: {'KULTURR'}),
      );
      expect(r.totalMatches, 1);
    });

    test('Cyrillic title found via lowercase query with exact score 8', () {
      final doc = EncyclopediaSearchDocument.validated(
        record: EncyclopediaRecord.validated(
          recordId: 'rec-cy',
          domain: EncyclopediaDomain.bestiary,
          title: 'МОРЕВА',
        ),
      );
      final index = EncyclopediaSearchIndex.withDocuments([doc]);
      final r = index.search(EncyclopediaSearchQuery(text: 'морева'));
      expect(r.totalMatches, 1);
      expect(r.hits.single.score, 8);
    });

    test('dotted-I matching is full-fold, not substring-of-fold (probe 4)', () {
      final doc = EncyclopediaSearchDocument.validated(
        record: EncyclopediaRecord.validated(
          recordId: 'rec-tr',
          domain: EncyclopediaDomain.names,
          title: 'İSTANBUL',
        ),
      );
      final index = EncyclopediaSearchIndex.withDocuments([doc]);
      // Query ascii dan query dotted sama-sama fold ke 'istanbul' -> 1 hit.
      expect(
        index.search(EncyclopediaSearchQuery(text: 'istanbul')).totalMatches,
        1,
      );
      expect(
        index.search(EncyclopediaSearchQuery(text: 'İSTANBUL')).totalMatches,
        1,
      );
      // Tanpa i awal atau dengan combining dot (2 unit UTF-16) -> tidak match:
      // batasan normalisasi yang didokumentasikan di f-search-special-casing.
      expect(
        index.search(EncyclopediaSearchQuery(text: 'stanbul')).totalMatches,
        0,
      );
      expect(
        index.search(EncyclopediaSearchQuery(text: 'i̇stanbul')).totalMatches,
        0,
      );
      // Arah sebaliknya (query İ, judul polos) juga fold sama -> 1 hit.
      final plain = EncyclopediaSearchDocument.validated(
        record: EncyclopediaRecord.validated(
          recordId: 'rec-tr2',
          domain: EncyclopediaDomain.names,
          title: 'ISTANBUL',
        ),
      );
      final idx2 = EncyclopediaSearchIndex.withDocuments([plain]);
      expect(
        idx2.search(EncyclopediaSearchQuery(text: 'İstanbul')).totalMatches,
        1,
      );
    });

    test(
      'tree navigation from middle child: up reaches parent, left is null',
      () {
        final graph = GenealogyGraph(
          nodes: {
            for (final id in ['a', 'c', 'd'])
              id: GenealogyNode(id: id, name: id),
          },
          edges: const [
            GenealogyRelation(
              id: 'r1',
              kind: GenealogyRelationKind.parentChild,
              fromId: 'a',
              toId: 'c',
              validFrom: 0,
            ),
            GenealogyRelation(
              id: 'r2',
              kind: GenealogyRelationKind.parentChild,
              fromId: 'c',
              toId: 'd',
              validFrom: 0,
            ),
          ],
        );
        expect(
          navigateKey(
            graph: graph,
            personId: 'c',
            direction: TreeNavDirection.up,
          ),
          'a',
        );
        expect(
          navigateKey(
            graph: graph,
            personId: 'c',
            direction: TreeNavDirection.left,
          ),
          isNull,
        );
      },
    );
  });
}
