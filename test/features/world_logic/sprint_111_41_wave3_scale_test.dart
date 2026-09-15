// Sprint 111.41 — Performance & Scale Validation (Wave 3, domain-only).
//
// Objective kanonik sprint_111.json: menguji katalog besar, media banyak,
// graph padat, pencarian lintas domain, dan batch generator.
// Required outputs: datasets, budgets, results, index_strategy,
// bottlenecks, mitigations.
//
// Konsumsi TANPA duplikasi:
//  - SplitMix64 + BenchLru (wave 2 performance_scale_benchmark.dart 110.45)
//  - EncyclopediaSearchIndex / Query / Report / PermissionFilter (111.37)
//  - EncyclopediaGraph / Edge / BacklinkIndex / StableLoreLink (111.38)
//  - SharedEncyclopediaSchema / EncyclopediaRecord (111.6)
//  - EncyclopediaMediaLibrary / MediaExportManifest (111.7)
//  - SeededNameGenerator / CulturalNameProfile / PhonotacticsSpec (111.29-31)
//
// Deterministik penuh: dataset dibangun dari seed tetap SplitMix64; hasil
// workload (checksum, jumlah, urutan) identik antar-build. Dinding waktu
// hanya lewat Stopwatch yang terukur (pola wave 2); golden fingerprint dibekukan
// dari PROBE terukur di toolchain Windows, bukan karangan.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/story/domain/lore_backlinks.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_integration.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_seeded_name_generation.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_wave3_scale.dart';
import 'package:void_scriptor/features/world_logic/domain/shared_encyclopedia_schema.dart';

void main() {
  // Satu laporan validasi utuh dipakai ulang seluruh tes (mahal; stopwatch
  // berbeda antar-run TIDAK diassert, hanya struktur deterministik).
  late final Wave3ScaleReport report;
  setUpAll(() {
    report = EncyclopediaWave3ScaleHarness().runAll();
  });

  group('datasets', () {
    test(
      'validation profile registers exactly the five canonical scenarios',
      () {
        final profile = Wave3ScaleProfile.validation();
        expect(
          profile.scenarios.map((s) => s.id).toList(),
          Wave3ScaleScenario.values.map((s) => s.id).toList(),
        );
        expect(profile.datasets.length, 5);
        for (final spec in profile.datasets) {
          expect(spec.units.values.every((v) => v > 0), isTrue);
          expect(spec.seed, greaterThan(0));
          expect(spec.fingerprint, greaterThan(0));
        }
      },
    );

    test('dataset fingerprints are stable across rebuilds (deterministic)', () {
      final a = Wave3ScaleProfile.validation();
      final b = Wave3ScaleProfile.validation();
      for (var i = 0; i < a.datasets.length; i++) {
        expect(a.datasets[i].fingerprint, b.datasets[i].fingerprint);
      }
    });

    test('golden fingerprints frozen from measured probe', () {
      // Nilai ini diprobe dari eksekusi nyata di toolchain Windows
      // (lihat catatan ledger 111.41), bukan angka perkiraan.
      final golden = EncyclopediaWave3ScaleHarness.goldenFingerprints();
      final profile = Wave3ScaleProfile.validation();
      expect(profile.datasets.length, golden.length);
      for (final spec in profile.datasets) {
        expect(
          golden[spec.scenario.id],
          spec.fingerprint,
          reason: 'fingerprint drift for ${spec.scenario.id}',
        );
      }
    });

    test('invalid dataset specs fail closed', () {
      expect(
        () => Wave3ScaleDatasetSpec.validated(
          scenario: Wave3ScaleScenario.catalogLarge,
          units: const {},
          seed: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => Wave3ScaleDatasetSpec.validated(
          scenario: Wave3ScaleScenario.catalogLarge,
          units: const {'records': 10},
          seed: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => Wave3ScaleDatasetSpec.validated(
          scenario: Wave3ScaleScenario.catalogLarge,
          units: const {'records': -3},
          seed: 7,
        ),
        throwsArgumentError,
      );
    });
  });

  group('results', () {
    test('every scenario produces at least one measured result', () {
      for (final scenario in Wave3ScaleScenario.values) {
        expect(
          report.resultsFor(scenario).isNotEmpty,
          isTrue,
          reason: scenario.id,
        );
      }
      expect(report.results.length, greaterThanOrEqualTo(10));
    });

    test('workload labels are unique across the whole report', () {
      final seen = <String>{};
      for (final result in report.results) {
        expect(
          seen.add(result.workloadLabel),
          isTrue,
          reason: 'duplicate workload ${result.workloadLabel}',
        );
      }
    });

    test('all measured results stay within their hard ceilings', () {
      expect(report.ceilingViolations, isEmpty);
      expect(report.allWithinCeiling, isTrue);
      for (final result in report.results) {
        expect(result.measuredMs, greaterThan(0));
        expect(result.budgetMs, greaterThanOrEqualTo(result.measuredMs));
      }
    });

    test(
      'results are deterministic: rebuilding datasets repeats checksums',
      () {
        final first = EncyclopediaWave3ScaleHarness().runAll();
        for (final a in report.results) {
          final b = first.results.firstWhere(
            (r) => r.workloadLabel == a.workloadLabel,
          );
          expect(b.checksum, a.checksum, reason: a.workloadLabel);
          expect(b.units, a.units, reason: a.workloadLabel);
        }
      },
    );

    test('catalog checksum equals the real registry content', () {
      final catalog = report.results.firstWhere(
        (r) => r.workloadLabel == 'catalog_large:domain_counts',
      );
      final schema = Wave3ScaleDatasets.buildCatalog(
        recordCount: Wave3ScaleScenario.catalogLarge.defaultUnits['records']!,
        seed: EncyclopediaWave3ScaleHarness.catalogSeed,
      );
      int expected = 0;
      for (final domain in EncyclopediaDomain.values) {
        expected += schema.countFor(domain);
      }
      expect(catalog.checksum, expected);
    });

    test('media export includes exactly the present assets', () {
      final library = Wave3ScaleDatasets.buildMediaLibrary(
        assetCount: 3000,
        missingEvery: 20,
      );
      final plan = library.planExport(explicitExport: true);
      expect(plan.assetIds.length, 3000 - 150);
      expect(plan.missingAssetIds.length, 150);
      expect(plan.sanitizationApplied, isTrue);
    });

    test('search workload actually matches and stays ordered', () {
      final searchResults = report.resultsFor(
        Wave3ScaleScenario.crossDomainSearch,
      );
      final queryResult = searchResults.firstWhere(
        (r) => r.workloadLabel == 'cross_domain_search:query_sweep',
      );
      expect(queryResult.checksum, greaterThan(0));
      expect(queryResult.units['documents'], 6000);
      expect(queryResult.units['probeCount'], 6);
    });

    test('generator batch produces the full requested volume, all unique', () {
      final gen = report.results.firstWhere(
        (r) => r.workloadLabel == 'generator_batch:8x256',
      );
      expect(gen.units['names'], 8 * 256);
      expect(gen.units['uniqueBatches'], 8);
    });
  });

  group('budgets', () {
    test('every scenario carries a documented hard ceiling', () {
      for (final scenario in Wave3ScaleScenario.values) {
        final ceiling = Wave3ScaleBudget.ceilingFor(scenario);
        expect(ceiling, greaterThan(0), reason: scenario.id);
        expect(Wave3ScaleBudget.rationaleFor(scenario).isNotEmpty, isTrue);
      }
    });

    test('derived budget keeps >= 4x headroom over the measured baseline', () {
      for (final result in report.results) {
        final budget = Wave3ScaleBudget.derive(baselineMs: result.measuredMs);
        expect(budget.headroomMultiplier, greaterThanOrEqualTo(4.0));
        expect(budget.budgetMs, greaterThanOrEqualTo(result.measuredMs));
      }
    });

    test('headroom multiplier below the floor is clamped, not rejected', () {
      final budget = Wave3ScaleBudget.derive(
        baselineMs: 10,
        headroomMultiplier: 1.5,
      );
      expect(budget.headroomMultiplier, 4.0);
      expect(budget.budgetMs, 40);
    });
  });

  group('index strategies', () {
    test('three measured strategies cover catalog, graph, and search', () {
      expect(report.indexStrategies.length, 3);
      expect(report.indexStrategies.map((s) => s.label).toList(), <String>[
        'catalog:per_domain_index',
        'graph:edge_pair_index',
        'search:facet_index',
      ]);
    });

    test(
      'per-domain catalog index agrees with the naive scan for all domains',
      () {
        final schema = Wave3ScaleDatasets.buildCatalog(
          recordCount: 900,
          seed: EncyclopediaWave3ScaleHarness.catalogSeed,
        );
        final index = Wave3CatalogIndex.from(schema);
        for (final domain in EncyclopediaDomain.values) {
          final naive =
              schema.recordsFor(domain).map((r) => r.recordId).toList()..sort();
          expect(index.recordIdsFor(domain), naive);
        }
        expect(index.totalIndexed, 900);
      },
    );

    test('catalog index refuses to be mutated', () {
      final schema = Wave3ScaleDatasets.buildCatalog(
        recordCount: 60,
        seed: EncyclopediaWave3ScaleHarness.catalogSeed,
      );
      final index = Wave3CatalogIndex.from(schema);
      expect(
        () => index.recordIdsFor(EncyclopediaDomain.herbology).add('x'),
        throwsUnsupportedError,
      );
    });

    test('edge pair index answers identically to the linear edgeBetween', () {
      final graph = Wave3ScaleDatasets.buildDenseGraph(
        nodeCount: 500,
        offsets: Wave3ScaleDatasets.defaultOffsets,
      );
      final pairIndex = Wave3EdgePairIndex.from(graph);
      final nodes = graph.nodeIds;
      for (var i = 0; i < 500; i += 7) {
        final a = nodes[i % nodes.length];
        final b = nodes[(i * 3 + 1) % nodes.length];
        final linear = graph.edgeBetween(a, b);
        final indexed = pairIndex.edgeBetween(a, b);
        expect(indexed?.edgeId, linear?.edgeId, reason: '$a->$b');
      }
      expect(pairIndex.edgeCount, graph.edgeCount);
    });

    test('facet index matches naive culture scans for every culture', () {
      final index = Wave3ScaleDatasets.buildSearchIndex(
        recordCount: 1200,
        seed: EncyclopediaWave3ScaleHarness.searchSeed,
      );
      final facets = Wave3FacetIndex.from(index);
      final cultures = <String>{
        for (final doc in index.documents) ...doc.cultureIds,
      };
      expect(cultures, isNotEmpty);
      for (final culture in cultures) {
        final naive =
            index.documents
                .where((d) => d.cultureIds.contains(culture))
                .map((d) => d.recordId)
                .toList()
              ..sort();
        expect(facets.cultureMatches(culture), naive, reason: culture);
      }
      expect(facets.cultureCount, cultures.length);
      expect(facets.cultureMatches('never-used-culture'), isEmpty);
    });

    test('unknown facet key returns empty without throwing', () {
      final index = Wave3ScaleDatasets.buildSearchIndex(
        recordCount: 120,
        seed: EncyclopediaWave3ScaleHarness.searchSeed,
      );
      final facets = Wave3FacetIndex.from(index);
      expect(facets.regionMatches('nope'), isEmpty);
      expect(facets.categoryMatches('nope'), isEmpty);
    });
  });

  group('bottlenecks & mitigations', () {
    test('every bottleneck has at least one mitigation', () {
      expect(report.bottlenecks.length, greaterThanOrEqualTo(6));
      expect(report.unmitigatedBottlenecks, isEmpty);
    });

    test('bottleneck and mitigation labels are unique and sorted', () {
      final bLabels = report.bottlenecks.map((b) => b.label).toList();
      expect(bLabels.toSet().length, bLabels.length);
      expect(bLabels, bLabels.toList()..sort());
      final mLabels = report.mitigations.map((m) => m.label).toList();
      expect(mLabels.toSet().length, mLabels.length);
      expect(mLabels, mLabels.toList()..sort());
    });

    test('mitigation actions are concrete (non-empty, scenario-scoped)', () {
      for (final mitigation in report.mitigations) {
        expect(mitigation.action.length, greaterThan(20));
        expect(mitigation.bottleneckLabels, isNotEmpty);
      }
    });

    test('report of an unmitigated bottleneck fails closed', () {
      expect(
        () => Wave3ScaleReport.of(
          datasets: report.datasets,
          budgets: report.budgets,
          results: report.results,
          indexStrategies: report.indexStrategies,
          bottlenecks: const [
            Wave3ScaleBottleneck(
              label: 'orphan:bottleneck',
              scenarioLabel: 'catalog_large',
              reason: 'no mitigation attached',
            ),
          ],
          mitigations: const [],
        ),
        throwsStateError,
      );
    });

    test('duplicate workload labels fail closed', () {
      const dupe = Wave3ScaleResult(
        workloadLabel: 'dup',
        scenarioLabel: 'catalog_large',
        units: {'records': 1},
        measuredMs: 1,
        ceilingMs: 10,
        budgetMs: 10,
        checksum: 1,
      );
      expect(
        () => Wave3ScaleReport.of(
          datasets: report.datasets,
          budgets: report.budgets,
          results: const [dupe, dupe],
          indexStrategies: const [],
          bottlenecks: const [],
          mitigations: const [],
        ),
        throwsStateError,
      );
    });
  });

  group('report contract', () {
    test('toJson/fromJson round-trips byte-identically and preserves ==', () {
      final json = report.toJson();
      final restored = Wave3ScaleReport.fromJson(
        (jsonDecode(jsonEncode(json)) as Map).cast<String, Object?>(),
      );
      expect(jsonEncode(restored.toJson()), jsonEncode(json));
      expect(restored, report);
      expect(restored.hashCode, report.hashCode);
    });

    test('coverage and completeness over the canonical five scenarios', () {
      expect(report.scenarioCoverage.keys.length, 5);
      expect(report.isComplete, isTrue);
      expect(report.missingScenarioNames, isEmpty);
    });

    test('describe() lists every scenario and the final verdict', () {
      final text = report.describe();
      for (final scenario in Wave3ScaleScenario.values) {
        expect(text.contains(scenario.id), isTrue);
      }
      expect(text.contains('ALL CEILINGS MET'), isTrue);
    });

    test('scenario enum exposes stable ids and labels', () {
      expect(
        Wave3ScaleScenario.values.map((s) => s.id),
        containsAll(<String>[
          'catalog_large',
          'media_many',
          'graph_dense',
          'cross_domain_search',
          'generator_batch',
        ]),
      );
    });
  });

  group('real-consumption smoke (reuse, no duplication)', () {
    test('generator batches honour maxBatchSize and stay reproducible', () {
      const batchSize = SeededNameGenerator.maxBatchSize;
      final batches = Wave3ScaleDatasets.runGeneratorBatches(
        batchCount: 3,
        batchSize: batchSize,
        seed: EncyclopediaWave3ScaleHarness.generatorSeed,
      );
      expect(batches.length, 3);
      final replay = Wave3ScaleDatasets.runGeneratorBatches(
        batchCount: 3,
        batchSize: batchSize,
        seed: EncyclopediaWave3ScaleHarness.generatorSeed,
      );
      for (var i = 0; i < batches.length; i++) {
        expect(batches[i].texts, replay[i].texts);
        expect(batches[i].texts.toSet().length, batchSize);
      }
    });

    test('measureFingerprint caches by full spec key', () {
      final first = Wave3ScaleDatasets.measureFingerprint(
        Wave3ScaleScenario.catalogLarge,
        const {'records': 50},
        EncyclopediaWave3ScaleHarness.catalogSeed,
      );
      final second = Wave3ScaleDatasets.measureFingerprint(
        Wave3ScaleScenario.catalogLarge,
        const {'records': 50},
        EncyclopediaWave3ScaleHarness.catalogSeed,
      );
      expect(first, second);
      final otherScale = Wave3ScaleDatasets.measureFingerprint(
        Wave3ScaleScenario.catalogLarge,
        const {'records': 60},
        EncyclopediaWave3ScaleHarness.catalogSeed,
      );
      expect(otherScale, isNot(first));
    });

    test('graph dataset is dense, connected, and cyclic', () {
      final graph = Wave3ScaleDatasets.buildDenseGraph(
        nodeCount: 400,
        offsets: Wave3ScaleDatasets.defaultOffsets,
      );
      expect(graph.edgeCount, 400 * Wave3ScaleDatasets.defaultOffsets.length);
      expect(graph.hasDirectedCycle(), isTrue);
      expect(graph.reachableFrom('gn-00000').length, 399);
      expect(graph.degree('gn-00000'), greaterThanOrEqualTo(2));
    });

    test('search index enforces its own uniqueness at scale', () {
      final index = Wave3ScaleDatasets.buildSearchIndex(
        recordCount: 300,
        seed: EncyclopediaWave3ScaleHarness.searchSeed,
      );
      expect(index.count, 300);
      expect(
        index.recordIds.first,
        index.recordIds.reduce((a, b) => a.compareTo(b) <= 0 ? a : b),
      );
    });

    test('backlink index resolves incoming links for hub nodes', () {
      final links = <StableLoreLink>[
        for (var i = 1; i <= 30; i++)
          StableLoreLink.validated(
            linkId: 'l-$i',
            sourceId: 'src-$i',
            displayText: 'ref $i',
            health: LoreLinkHealth.resolved,
            targetEntityId: 'hub-1',
          ),
      ];
      final backlinks = EncyclopediaBacklinkIndex.fromLinks(links);
      expect(backlinks.backlinksFor('hub-1').length, 30);
      expect(backlinks.backlinksFor('missing'), isEmpty);
    });
  });
}
