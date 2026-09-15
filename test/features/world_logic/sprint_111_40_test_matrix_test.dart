// Sprint 111.40 - Automated Test Matrix (domain-only, pure Dart — no Flutter
// widget bindings so it runs under `dart test`-style isolation as well).
//
// Acceptance canonical (sprint_111.json step 111.40 required_suites):
// - unit             -> every Wave 3 encyclopedia domain module has at least
//                       one focused test file that imports it (full repo scan)
// - property         -> generator invariants over sampled seeds (determinism,
//                       uniqueness, legality, batch-count, immutable inputs)
// - integration      -> cross-module chains names->collision,
//                       names->search, search->portability round-trip
// - contract         -> JSON contracts byte-stable and import-safe across
//                       modules (proposal, report, bundle)
// - migration        -> SchemaCompatibilityCheck health on empty and
//                       populated registries (domain-level migration gate;
//                       Drift schema migration stays under D-SCHEMA-01)
// - ui               -> keyboard navigation contract drives selection over
//                       real search results (domain-side of 111.37 UI)
// - generator_replay -> golden seed->text vectors replay byte-identically
// - end_to_end       -> generate -> propose -> canonicalize -> index ->
//                       search -> export -> import -> re-export identity
// - regression       -> every Wave 3 test file passes AND the matrix report
//                       is reproducible in-process (guards 111.21..111.39)
//
// Domain-only: no persistence, wall clock, locale, random, or network.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_name_collision.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_name_profiles.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_portability.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_seeded_name_generation.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_syllable_phonotactics.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_unified_search.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_wave3_test_matrix.dart';
import 'package:void_scriptor/features/world_logic/domain/shared_encyclopedia_schema.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

PhonotacticsSpec matrixSpec() {
  return PhonotacticsSpec.validated(
    id: 'matrix-spec',
    languageId: 'elv-a',
    inventory: <SyllablePart>[
      SyllablePart.validated(
        symbol: 'a',
        slots: <SyllableSlot>[SyllableSlot.nucleus],
      ),
      SyllablePart.validated(
        symbol: 'e',
        slots: <SyllableSlot>[SyllableSlot.nucleus],
      ),
      SyllablePart.validated(
        symbol: 'i',
        slots: <SyllableSlot>[SyllableSlot.nucleus],
      ),
      SyllablePart.validated(
        symbol: 'k',
        slots: <SyllableSlot>[SyllableSlot.onset, SyllableSlot.coda],
      ),
      SyllablePart.validated(
        symbol: 'l',
        slots: <SyllableSlot>[SyllableSlot.onset, SyllableSlot.coda],
      ),
      SyllablePart.validated(
        symbol: 'm',
        slots: <SyllableSlot>[SyllableSlot.onset],
      ),
      SyllablePart.validated(
        symbol: 'n',
        slots: <SyllableSlot>[SyllableSlot.onset],
      ),
      SyllablePart.validated(
        symbol: 'r',
        slots: <SyllableSlot>[SyllableSlot.onset],
      ),
      SyllablePart.validated(
        symbol: 's',
        slots: <SyllableSlot>[SyllableSlot.onset],
      ),
      SyllablePart.validated(
        symbol: 't',
        slots: <SyllableSlot>[SyllableSlot.onset],
      ),
    ],
    patterns: <SyllablePattern>[
      SyllablePattern.parse(id: 'cv', template: 'CV', weight: 3),
      SyllablePattern.parse(id: 'cvc', template: 'CVC', weight: 2),
    ],
  );
}

CulturalNameProfile matrixProfile() {
  return CulturalNameProfile.validated(
    profileId: 'prof-matrix',
    cultureId: 'c-elenar',
    languageId: 'elv-a',
    entityTypes: <NameEntityType>{NameEntityType.person},
  );
}

SeededNameRequest matrixRequest({required int seed}) {
  return SeededNameRequest.validated(
    profile: matrixProfile(),
    spec: matrixSpec(),
    entityType: NameEntityType.person,
    syllableCount: 3,
    addAffixes: false,
    seed: seed,
  );
}

EncyclopediaSearchDocument matrixDocument({
  required String recordId,
  required String title,
  CanonStatus canon = CanonStatus.canon,
  List<String> cultureIds = const <String>['c-elenar'],
}) {
  return EncyclopediaSearchDocument.validated(
    record: EncyclopediaRecord.validated(
      recordId: recordId,
      domain: EncyclopediaDomain.names,
      title: title,
      taxonomyCategoryId: 'elf-names',
      canonStatus: canon,
    ),
    cultureIds: cultureIds,
  );
}

void main() {
  group('111.40 registry - matrix declares the nine required suites', () {
    test('exact required-suite set from sprint_111.json step 111.40', () {
      expect(EncyclopediaWave3TestMatrix.suiteNames, <String>[
        'contract',
        'end_to_end',
        'generator_replay',
        'integration',
        'migration',
        'property',
        'regression',
        'ui',
        'unit',
      ]);
    });

    test('every suite entry has a non-empty verifier id and evidence note', () {
      for (final suite in EncyclopediaWave3TestMatrix.suites) {
        expect(suite.name.trim(), isNotEmpty);
        expect(suite.verifier.trim(), isNotEmpty);
        expect(suite.evidence.trim(), isNotEmpty);
      }
    });

    test('suite lookup by name is exact and rejects unknown names', () {
      expect(
        EncyclopediaWave3TestMatrix.suiteNamed('generator_replay')?.name,
        'generator_replay',
      );
      expect(EncyclopediaWave3TestMatrix.suiteNamed('load_test'), isNull);
    });
  });

  group('111.40 report - deterministic aggregate over the nine suites', () {
    test('fromSources maps each suite to the source count that imports it', () {
      final report =
          EncyclopediaWave3TestMatrixReport.fromSources(<String, int>{
            'unit': 32,
            'property': 4,
            'integration': 5,
            'contract': 9,
            'migration': 2,
            'ui': 1,
            'generator_replay': 3,
            'end_to_end': 2,
            'regression': 6,
          });
      expect(report.passedCount, 9);
      expect(report.totalCount, 9);
      expect(report.coverage, 1.0);
      expect(report.isComplete, isTrue);
      expect(
        report.entryFor('unit')?.sourceCount,
        32,
        reason: 'unit maps to the 32 focused domain test files',
      );
      expect(report.entryFor('generator_replay')?.sourceCount, 3);
      expect(report.entryFor('missing_suite'), isNull);
    });

    test('zero-count sources are recorded as failed, not dropped', () {
      final report =
          EncyclopediaWave3TestMatrixReport.fromSources(<String, int>{
            for (final name in EncyclopediaWave3TestMatrix.suiteNames) name: 1,
            'property': 0,
            'migration': 0,
          });
      expect(report.totalCount, 9);
      expect(report.passedCount, 7);
      expect(report.failedSuiteNames, <String>['migration', 'property']);
      expect(report.coverage, closeTo(7 / 9, 1e-9));
      expect(report.isComplete, isFalse);
    });

    test(
      'unknown suite names are rejected (fail-closed, no invented rows)',
      () {
        expect(
          () => EncyclopediaWave3TestMatrixReport.fromSources(<String, int>{
            'load_test': 5,
          }),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('load_test'),
            ),
          ),
        );
      },
    );

    test('duplicate or empty suite rows cannot be constructed directly', () {
      final ok = <String, int>{
        for (final name in EncyclopediaWave3TestMatrix.suiteNames) name: 1,
      };
      expect(
        () => EncyclopediaWave3TestMatrixReport.fromSources(ok),
        returnsNormally,
      );
      final entries = <EncyclopediaTestSuiteEntry>[
        for (final name in EncyclopediaWave3TestMatrix.suiteNames)
          EncyclopediaWave3TestMatrix.suiteNamed(name)!.withSourceCount(2),
      ];
      expect(
        () => EncyclopediaWave3TestMatrixReport.of(<EncyclopediaTestSuiteEntry>[
          ...entries,
          entries.first,
        ]),
        throwsStateError,
      );
      expect(
        () => EncyclopediaTestSuiteEntry.validated(
          name: '  ',
          verifier: 'v',
          evidence: 'e',
          sourceCount: 1,
        ),
        throwsArgumentError,
      );
    });

    test('JSON round-trip is byte-identical through canonical encode', () {
      final report =
          EncyclopediaWave3TestMatrixReport.fromSources(<String, int>{
            'unit': 32,
            'property': 4,
            'integration': 5,
            'contract': 9,
            'migration': 2,
            'ui': 1,
            'generator_replay': 3,
            'end_to_end': 2,
            'regression': 6,
          });
      final first = jsonEncode(report.toJson());
      final back = EncyclopediaWave3TestMatrixReport.fromJson(
        jsonDecode(first) as Map<String, Object?>,
      );
      expect(jsonEncode(back.toJson()), first);
      expect(back, report);
      expect(back.coverage, report.coverage);
      expect(back.failedSuiteNames, report.failedSuiteNames);
    });

    test('describe() lists every suite and flags failures', () {
      final report = EncyclopediaWave3TestMatrixReport.fromSources(
        <String, int>{
          for (final name in EncyclopediaWave3TestMatrix.suiteNames) name: 1,
          'ui': 0,
        },
      );
      final text = report.describe();
      for (final name in EncyclopediaWave3TestMatrix.suiteNames) {
        expect(text, contains(name));
      }
      expect(text, contains('ui'));
      expect(text.toLowerCase(), contains('fail'));
    });
  });

  group('111.40 generator_replay - golden seed vectors replay byte-exact', () {
    for (final vector in EncyclopediaWave3GoldenVectors.seedVectors) {
      test('seed ${vector.seed} replays to its frozen batch', () {
        final batch = SeededNameGenerator.generateBatch(
          request: matrixRequest(seed: vector.seed),
          count: vector.texts.length,
        );
        expect(batch.texts, vector.texts, reason: 'replay drift = bug');
        expect(<String>[
          for (final p in batch.proposals) p.proposalId,
        ], vector.proposalIds);
      });
    }

    test(
      'proposal JSON contract replays through fromJson byte-identically',
      () {
        final vector = EncyclopediaWave3GoldenVectors.seedVectors.first;
        final batch = SeededNameGenerator.generateBatch(
          request: matrixRequest(seed: vector.seed),
          count: vector.texts.length,
        );
        final encoded = jsonEncode(batch.toJson());
        final decoded = SeededNameBatch.fromJson(
          jsonDecode(encoded) as Map<String, Object?>,
        );
        expect(jsonEncode(decoded.toJson()), encoded);
        expect(decoded.texts, vector.texts);
      },
    );

    test('nextSeed chain replays as a frozen ladder', () {
      final chain = <int>[];
      var seed = EncyclopediaWave3GoldenVectors.seedChainStart;
      for (var i = 0; i < EncyclopediaWave3GoldenVectors.seedChainLength; i++) {
        chain.add(seed);
        seed = SeededNameGenerator.nextSeed(seed);
      }
      expect(chain, EncyclopediaWave3GoldenVectors.seedChain);
    });
  });

  group('111.40 property - generator invariants over sampled seeds', () {
    final sampledSeeds = <int>[
      1,
      7,
      99,
      12345,
      424242,
      999999937,
      EncyclopediaWave3GoldenVectors.seedVectors.first.seed,
    ];

    test(
      'identical seed produces identical batch in fresh request objects',
      () {
        for (final seed in sampledSeeds) {
          final a = SeededNameGenerator.generateBatch(
            request: matrixRequest(seed: seed),
            count: 6,
          );
          final b = SeededNameGenerator.generateBatch(
            request: matrixRequest(seed: seed),
            count: 6,
          );
          expect(b.texts, a.texts, reason: 'seed $seed not reproducible');
          expect(
            <String>[for (final p in b.proposals) p.proposalId],
            <String>[for (final p in a.proposals) p.proposalId],
          );
        }
      },
    );

    test(
      'distinct seeds produce distinct first texts (collision pressure)',
      () {
        final firstTexts = <String>{};
        for (final seed in sampledSeeds) {
          firstTexts.add(
            SeededNameGenerator.generateBatch(
              request: matrixRequest(seed: seed),
              count: 1,
            ).texts.single,
          );
        }
        expect(firstTexts.length, sampledSeeds.length);
      },
    );

    test('batch texts are unique within a batch and match requested count', () {
      for (final seed in sampledSeeds) {
        for (final count in const <int>[1, 2, 9]) {
          final batch = SeededNameGenerator.generateBatch(
            request: matrixRequest(seed: seed),
            count: count,
          );
          expect(batch.count, count);
          expect(batch.texts.toSet().length, count);
          expect(<int>[
            for (final p in batch.proposals) p.index,
          ], List<int>.generate(count, (i) => i));
        }
      }
    });

    test('generated syllables always stay inside the spec inventory', () {
      final spec = matrixSpec();
      final inventory = <String>{
        for (final part in spec.inventory) part.symbol,
      };
      for (final seed in sampledSeeds) {
        final batch = SeededNameGenerator.generateBatch(
          request: matrixRequest(seed: seed),
          count: 5,
        );
        for (final proposal in batch.proposals) {
          for (final syllable in proposal.syllables) {
            for (final symbol in syllable.split('')) {
              expect(
                inventory,
                contains(symbol),
                reason: '${proposal.text} uses out-of-inventory $symbol',
              );
            }
          }
        }
      }
    });

    test(
      'regenerate moves to a distinct derived seed, never the same batch',
      () {
        for (final seed in sampledSeeds) {
          final batch = SeededNameGenerator.generateBatch(
            request: matrixRequest(seed: seed),
            count: 4,
          );
          final next = batch.regenerate();
          expect(next.seed, isNot(batch.seed));
          expect(next.count, batch.count);
          expect(next.texts, isNot(batch.texts));
          // Repeated regenerate from the same batch is itself deterministic.
          expect(batch.regenerate().texts, next.texts);
        }
      },
    );
  });

  group('111.40 integration - cross-module chains', () {
    test('generator -> collision validator: fresh proposals pass cleanly', () {
      final spec = matrixSpec();
      final profile = matrixProfile();
      final request = matrixRequest(seed: 20260916);
      final batch = SeededNameGenerator.generateBatch(
        request: request,
        count: 4,
      );
      final candidates = <NameCandidate>[
        for (final p in batch.proposals) NameCandidate.fromProposal(p, request),
      ];
      final report = const NameConsistencyValidator().validate(
        candidates: candidates,
        registry: CanonicalNameRegistry.validated(records: const []),
        profile: profile,
        spec: spec,
      );
      expect(report.hasBlockingIssues, isFalse, reason: report.describe());
      expect(candidates.first.cultureId, profile.cultureId);
      expect(candidates.first.languageId, profile.languageId);
    });

    test('generator -> collision registry: exact replay is flagged exact', () {
      final request = matrixRequest(seed: 20260916);
      final batch = SeededNameGenerator.generateBatch(
        request: request,
        count: 2,
      );
      final canonical = CanonicalNameRecord.validated(
        recordId: 'canon-1',
        text: batch.texts.first,
        cultureId: request.profile.cultureId,
        languageId: request.profile.languageId,
        entityType: NameEntityType.person,
      );
      final replay = SeededNameGenerator.generateBatch(
        request: matrixRequest(seed: 20260916),
        count: 2,
      );
      final candidate = NameCandidate.fromProposal(
        replay.proposals.first,
        request,
      );
      final report = const NameConsistencyValidator().validate(
        candidates: <NameCandidate>[candidate],
        registry: CanonicalNameRegistry.validated(
          records: <CanonicalNameRecord>[canonical],
        ),
        profile: request.profile,
        spec: matrixSpec(),
      );
      expect(
        report.issuesOf(NameCheckKind.exactCollision),
        isNotEmpty,
        reason: 'a replayed accepted name must collide with canon',
      );
      expect(report.hasBlockingIssues, isTrue);
    });

    test('generator -> search index -> export -> import keeps identity', () {
      final request = matrixRequest(seed: 20260916);
      final batch = SeededNameGenerator.generateBatch(
        request: request,
        count: 2,
      );
      final documents = <EncyclopediaSearchDocument>[
        matrixDocument(recordId: 'rec-e2e-1', title: batch.texts[0]),
        matrixDocument(recordId: 'rec-e2e-2', title: batch.texts[1]),
      ];
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: documents,
        options: EncyclopediaExportOptions(explicitExport: true),
      );
      final text = EncyclopediaPortabilityService.exportText(bundle);
      final reimported = EncyclopediaPortabilityService.importText(text);
      expect(reimported.documents.length, 2);
      expect(
        EncyclopediaPortabilityService.roundTripText(text),
        text,
        reason: 'export -> import -> export must be byte-identical',
      );
      expect(
        reimported.documents.map((d) => d.title).toSet(),
        bundle.documents.map((d) => d.title).toSet(),
      );
    });
  });

  group('111.40 contract - JSON byte-stability across modules', () {
    test('collision report JSON replays byte-identically through fromJson', () {
      final request = matrixRequest(seed: 20260916);
      final batch = SeededNameGenerator.generateBatch(
        request: request,
        count: 3,
      );
      final candidates = <NameCandidate>[
        for (final p in batch.proposals) NameCandidate.fromProposal(p, request),
      ];
      final report = const NameConsistencyValidator().validate(
        candidates: candidates,
        registry: CanonicalNameRegistry.validated(
          records: <CanonicalNameRecord>[
            CanonicalNameRecord.validated(
              recordId: 'canon-k',
              text: batch.texts.first,
              cultureId: request.profile.cultureId,
              languageId: request.profile.languageId,
              entityType: NameEntityType.person,
            ),
          ],
        ),
        profile: request.profile,
        spec: matrixSpec(),
      );
      expect(report.hasIssues, isTrue);
      final encoded = jsonEncode(report.toJson());
      final decoded = NameCheckReport.fromJson(
        jsonDecode(encoded) as Map<String, Object?>,
      );
      expect(jsonEncode(decoded.toJson()), encoded);
    });

    test('tampered export payload is rejected by the portability contract', () {
      final doc = matrixDocument(recordId: 'rec-tamper', title: 'Aluarin');
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: <EncyclopediaSearchDocument>[doc],
        options: EncyclopediaExportOptions(explicitExport: true),
      );
      final text = EncyclopediaPortabilityService.exportText(bundle);
      expect(EncyclopediaPortabilityService.verifyChecksum(text), isTrue);
      final tampered = text.replaceFirst('"Aluarin"', '"Aluarim"');
      expect(EncyclopediaPortabilityService.verifyChecksum(tampered), isFalse);
      final report = EncyclopediaPortabilityService.validateJson(tampered);
      expect(
        report.issuesOfKind(PortabilityValidationKind.checksumMismatch),
        isNotEmpty,
      );
      expect(report.hasBlockingIssues, isTrue);
      expect(
        () => EncyclopediaPortabilityService.importText(tampered),
        throwsStateError,
      );
    });
  });

  group('111.40 migration - domain schema compatibility stays healthy', () {
    test('empty registry is healthy', () {
      final check = SchemaCompatibilityCheck.evaluate(
        SharedEncyclopediaSchema(),
      );
      expect(check.isHealthy, isTrue);
    });

    test('populated migration sample keeps every category check green', () {
      final registry = SharedEncyclopediaSchema();
      for (final domain in EncyclopediaDomain.values) {
        registry.register(
          EncyclopediaRecord.validated(
            recordId: 'rec-mig-${domain.id}',
            domain: domain,
            title: 'Sample ${domain.id}',
            taxonomyCategoryId: 'cat-${domain.id}',
          ),
        );
      }
      final check = SchemaCompatibilityCheck.evaluate(registry);
      expect(check.issues, isEmpty);
      expect(check.isHealthy, isTrue, reason: 'matrix fixture must be clean');
    });

    test('missing category is detected (the check itself is not vacuous)', () {
      final registry = SharedEncyclopediaSchema()
        ..register(
          EncyclopediaRecord.validated(
            recordId: 'rec-nocat',
            domain: EncyclopediaDomain.names,
            title: 'NoCat',
          ),
        );
      final check = SchemaCompatibilityCheck.evaluate(registry);
      expect(check.isHealthy, isFalse);
      expect(
        check.issuesOfKind(CompatibilityIssueKind.missingCategory),
        isNotEmpty,
      );
    });
  });

  group('111.40 ui - keyboard contract drives selection over real results', () {
    test('navigation visits every result index without wrap', () {
      final request = matrixRequest(seed: 20260916);
      final batch = SeededNameGenerator.generateBatch(
        request: request,
        count: 5,
      );
      final documents = <EncyclopediaSearchDocument>[
        for (var i = 0; i < batch.texts.length; i++)
          EncyclopediaSearchDocument.validated(
            record: EncyclopediaRecord.validated(
              recordId: 'rec-kb-$i',
              domain: EncyclopediaDomain.names,
              title: batch.texts[i],
              taxonomyCategoryId: 'elf-names',
            ),
            aliases: const <String>['matrix shared name'],
            cultureIds: const <String>['c-elenar'],
          ),
      ];
      final index = EncyclopediaSearchIndex.withDocuments(documents);
      final nav = EncyclopediaKeyboardNavigation();
      // Query on the shared alias: every document matches deterministically
      // regardless of generated word content.
      final hits = index
          .search(
            EncyclopediaSearchQuery(
              text: 'matrix shared name',
              requireAllTerms: true,
              domains: const <EncyclopediaDomain>{EncyclopediaDomain.names},
            ),
          )
          .hits;
      expect(hits.length, 5);
      var selected = nav.selectedIndexFor(
        EncyclopediaKeyboardNavigation.actionFirst,
        resultCount: hits.length,
        selectedIndex: 2,
      );
      final visited = <int>{selected!};
      for (var step = 0; step < hits.length * 2; step++) {
        selected = nav.selectedIndexFor(
          EncyclopediaKeyboardNavigation.actionNext,
          resultCount: hits.length,
          selectedIndex: selected!,
        );
        visited.add(selected!);
      }
      expect(visited, <int>{0, 1, 2, 3, 4});
      expect(selected, hits.length - 1, reason: 'End-of-list clamp, no wrap');
      expect(
        nav.selectedIndexFor(
          EncyclopediaKeyboardNavigation.actionNext,
          resultCount: hits.length,
          selectedIndex: selected!,
        ),
        hits.length - 1,
      );
      expect(
        nav.selectedIndexFor(
          EncyclopediaKeyboardNavigation.actionLast,
          resultCount: hits.length,
          selectedIndex: 0,
        ),
        hits.length - 1,
      );
      expect(
        nav.selectedIndexFor(
          EncyclopediaKeyboardNavigation.actionPrevious,
          resultCount: hits.length,
          selectedIndex: 0,
        ),
        0,
        reason: 'Start-of-list clamp, no wrap',
      );
      // Each visited index resolves to a distinct real hit.
      final seenTitles = <String>{};
      for (final position in visited) {
        seenTitles.add(hits[position].document.title);
      }
      expect(seenTitles.length, hits.length);
    });
  });

  group('111.40 end_to_end - proposal lifecycle across five modules', () {
    test(
      'generate -> propose -> canonicalize -> index -> search -> export',
      () {
        final request = matrixRequest(seed: 4242);
        final batch = SeededNameGenerator.generateBatch(
          request: request,
          count: 3,
        );
        final accepted = batch.accept(batch.proposals.first.proposalId);
        expect(accepted.acceptedCount, 1);
        expect(accepted.proposedCount, 2);
        expect(batch.acceptedCount, 0, reason: 'accept is non-mutating');

        final canonical = CanonicalNameRecord.validated(
          recordId: 'canon-e2e',
          text: accepted.proposals.first.text,
          cultureId: request.profile.cultureId,
          languageId: request.profile.languageId,
          entityType: NameEntityType.person,
        );
        final registry = CanonicalNameRegistry.validated(
          records: <CanonicalNameRecord>[canonical],
        );
        expect(registry.isReserved(canonical.normalizedText), isFalse);

        final documents = <EncyclopediaSearchDocument>[
          for (final record in registry.records)
            matrixDocument(
              recordId: 'e2e-${record.recordId}',
              title: record.text,
              cultureIds: <String>[record.cultureId],
            ),
        ];
        final index = EncyclopediaSearchIndex.withDocuments(documents);
        final searchReport = index.search(
          EncyclopediaSearchQuery(
            text: canonical.text,
            cultureIds: <String>{canonical.cultureId},
          ),
        );
        expect(searchReport.hits, isNotEmpty);
        expect(searchReport.hits.first.document.title, canonical.text);

        final bundle = EncyclopediaPortabilityService.buildBundle(
          documents: documents,
          options: EncyclopediaExportOptions(explicitExport: true),
        );
        final text = EncyclopediaPortabilityService.exportText(bundle);
        final reimported = EncyclopediaPortabilityService.importText(text);
        expect(EncyclopediaPortabilityService.roundTripText(text), text);
        final reopened = EncyclopediaSearchIndex.withDocuments(
          reimported.documents,
        );
        final replayed = reopened.search(
          EncyclopediaSearchQuery(
            text: canonical.text,
            cultureIds: <String>{canonical.cultureId},
          ),
        );
        expect(replayed.hits.first.document.title, canonical.text);

        final matrix = EncyclopediaWave3TestMatrixReport.fromSources(
          EncyclopediaWave3TestSuiteSources.wave3MatrixCounts(),
        );
        expect(matrix.isComplete, isTrue, reason: matrix.describe());
      },
    );
  });

  group('111.40 regression - Wave 3 surface guards', () {
    test('every Wave 3 domain module appears in the unit-census list', () {
      final modules = EncyclopediaWave3TestSuiteSources.wave3DomainModules();
      expect(modules.length, greaterThanOrEqualTo(30));
      expect(
        modules,
        contains('encyclopedia_portability.dart'),
        reason: 'newest Wave 3 domain module must be listed',
      );
      for (final module in modules) {
        expect(module, endsWith('.dart'));
        expect(module, isNot(contains('/')));
      }
    });

    test('matrix report is reproducible in-process (idempotent aggregate)', () {
      final first = EncyclopediaWave3TestMatrixReport.fromSources(
        EncyclopediaWave3TestSuiteSources.wave3MatrixCounts(),
      );
      final second = EncyclopediaWave3TestMatrixReport.fromSources(
        EncyclopediaWave3TestSuiteSources.wave3MatrixCounts(),
      );
      expect(jsonEncode(second.toJson()), jsonEncode(first.toJson()));
      expect(second, first);
    });

    test('wave3MatrixCounts covers exactly the nine required suites', () {
      expect(
        EncyclopediaWave3TestSuiteSources.wave3MatrixCounts().keys.toSet(),
        EncyclopediaWave3TestMatrix.suiteNames.toSet(),
      );
    });
  });
}
