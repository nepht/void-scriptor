// Sprint 111.42 — Security, Privacy & Content Safety Verification (domain-only).
//
// Objective kanonik (sprint_111.json): menguji isolasi project, spoiler,
// metadata media, import berbahaya, export, dan hasil generator.
// Required outputs: threat_review, isolation_tests, import_tests,
// metadata_tests, spoiler_tests, fix_status.
//
// Harness ini TIDAK menduplikasi logika produksi: setiap check memanggil API
// nyata 111.6/111.7/111.8/111.31/111.37/111.39 dan membuktikan perilaku
// fail-closed. Deterministik penuh — tanpa wall-clock, random, network,
// persistence, atau file IO (D-SCHEMA-01 tetap OPEN).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_portability.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_spoiler_accessibility.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_unified_search.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_wave3_security.dart';
import 'package:void_scriptor/features/world_logic/domain/shared_encyclopedia_schema.dart';

EncyclopediaSearchDocument _doc(
  String id,
  EncyclopediaDomain domain,
  String title, {
  List<String> aliases = const [],
  SpoilerLevel spoiler = SpoilerLevel.safe,
}) {
  return EncyclopediaSearchDocument.validated(
    record: EncyclopediaRecord.validated(
      recordId: id,
      domain: domain,
      title: title,
    ),
    aliases: aliases,
    spoilerLevel: spoiler,
  );
}

void main() {
  group('harness runs real security checks', () {
    final report = EncyclopediaWave3SecurityHarness.run();

    test('every executed check passes (fail-closed harness)', () {
      final failed = report.outcomes
          .where((o) => !o.passed)
          .map((o) => '${o.checkId}: ${o.evidence}')
          .toList();
      expect(failed, isEmpty);
      expect(report.passing, isTrue);
    });

    test('required outputs present: all six surfaces have checks', () {
      for (final surface in Wave3SecuritySurface.values) {
        expect(
          report.checksFor(surface),
          isNotEmpty,
          reason: 'surface ${surface.name} needs at least one executed check',
        );
      }
      expect(report.threatReview, isNotEmpty);
      expect(report.fixStatus, isNotEmpty);
    });

    test('isolation_tests: two project namespaces never cross', () {
      final ids = report
          .checksFor(Wave3SecuritySurface.projectIsolation)
          .map((o) => o.checkId)
          .toList();
      expect(
        ids,
        containsAll(<String>[
          'chk-isolation-registry-namespace',
          'chk-isolation-search-visibility',
          'chk-isolation-export-leak',
        ]),
      );
    });

    test('import_tests: hostile payloads are all rejected', () {
      final ids = report
          .checksFor(Wave3SecuritySurface.dangerousImport)
          .map((o) => o.checkId)
          .toList();
      expect(
        ids,
        containsAll(<String>[
          'chk-import-malformed-json',
          'chk-import-non-map-payload',
          'chk-import-tampered-checksum',
          'chk-import-missing-checksum',
          'chk-import-unsanitized-manifest',
        ]),
      );
    });

    test('metadata_tests: sensitive metadata stripped, paths contained', () {
      final ids = report
          .checksFor(Wave3SecuritySurface.mediaMetadata)
          .map((o) => o.checkId)
          .toList();
      expect(
        ids,
        containsAll(<String>[
          'chk-metadata-sensitive-stripped',
          'chk-metadata-path-containment',
          'chk-metadata-sanitization-gate',
        ]),
      );
    });

    test(
      'spoiler_tests: masked/dropped exports and hidden search leak nothing',
      () {
        final ids = report
            .checksFor(Wave3SecuritySurface.spoilerLeak)
            .map((o) => o.checkId)
            .toList();
        expect(
          ids,
          containsAll(<String>[
            'chk-spoiler-export-mask',
            'chk-spoiler-export-drop',
            'chk-spoiler-search-hidden-ids-only',
            'chk-spoiler-override-beats-default',
          ]),
        );
      },
    );

    test('export safety + generator safety are checked', () {
      expect(
        report
            .checksFor(Wave3SecuritySurface.exportSafety)
            .map((o) => o.checkId),
        containsAll(<String>[
          'chk-export-explicit-opt-in',
          'chk-export-missing-media-excluded',
          'chk-export-round-trip-integrity',
        ]),
      );
      expect(
        report
            .checksFor(Wave3SecuritySurface.generatorSafety)
            .map((o) => o.checkId),
        containsAll(<String>[
          'chk-generator-explicit-seed',
          'chk-generator-replay-determinism',
          'chk-generator-batch-bounds',
          'chk-generator-no-auto-canon',
        ]),
      );
    });

    test('the missing-checksum threat is recorded as fixedThisSlice', () {
      expect(
        report.fixStatus['th-import-checksum-bypass'],
        Wave3SecurityStatus.fixedThisSlice.name,
      );
      final threat = report.threatNamed('th-import-checksum-bypass');
      expect(threat.surface, Wave3SecuritySurface.dangerousImport);
      expect(threat.controls, contains('chk-import-missing-checksum'));
    });

    test('hardware-bound threat is DEFERRED, never claimed as verified', () {
      expect(
        report.fixStatus['th-power-loss-integrity'],
        Wave3SecurityStatus.deferredHardware.name,
      );
      final deferred = report.deferredThreatIds;
      expect(deferred, contains('th-power-loss-integrity'));
      expect(
        report.threatNamed('th-power-loss-integrity').controls,
        isEmpty,
        reason: 'no software check may claim hardware proof',
      );
      expect(report.describe(), contains('UNVERIFIABLE'));
    });

    test('JSON round trip is byte-identical and equality holds', () {
      final text = jsonEncode(report.toJson());
      final rebuilt = EncyclopediaWave3SecurityReport.fromJson(
        jsonDecode(text) as Map<String, Object?>,
      );
      expect(jsonEncode(rebuilt.toJson()), text);
      expect(rebuilt, report);
    });

    test('outcomes are re-runnable and byte-stable', () {
      final again = EncyclopediaWave3SecurityHarness.run();
      expect(jsonEncode(again.toJson()), jsonEncode(report.toJson()));
    });
  });

  group('report integrity guards (fail-closed construction)', () {
    final good = EncyclopediaWave3SecurityHarness.run();

    test('unknown control id on a threat is rejected', () {
      expect(
        () => EncyclopediaWave3SecurityReport.of(
          threats: <Wave3SecurityThreat>[
            ...good.threats,
            Wave3SecurityThreat(
              threatId: 'th-orphan',
              surface: Wave3SecuritySurface.dangerousImport,
              description: 'x',
              controls: const <String>['chk-does-not-exist'],
            ),
          ],
          outcomes: good.outcomes,
        ),
        throwsArgumentError,
      );
    });

    test('an outcome no threat references is rejected', () {
      expect(
        () => EncyclopediaWave3SecurityReport.of(
          threats: const <Wave3SecurityThreat>[],
          outcomes: good.outcomes,
        ),
        throwsArgumentError,
      );
    });

    test('duplicate threat or check ids are rejected', () {
      expect(
        () => EncyclopediaWave3SecurityReport.of(
          threats: <Wave3SecurityThreat>[...good.threats, good.threats.first],
          outcomes: good.outcomes,
        ),
        throwsStateError,
      );
      expect(
        () => EncyclopediaWave3SecurityReport.of(
          threats: good.threats,
          outcomes: <Wave3SecurityCheckOutcome>[
            ...good.outcomes,
            good.outcomes.first,
          ],
        ),
        throwsStateError,
      );
    });

    test('a single failed outcome flips passing to false', () {
      final broken = EncyclopediaWave3SecurityReport.of(
        threats: good.threats,
        outcomes: <Wave3SecurityCheckOutcome>[
          for (final o in good.outcomes)
            if (o.checkId == 'chk-import-missing-checksum')
              Wave3SecurityCheckOutcome.failed(
                checkId: o.checkId,
                evidence: 'simulated regression',
              )
            else
              o,
        ],
      );
      expect(broken.passing, isFalse);
      expect(broken.failedCheckIds, ['chk-import-missing-checksum']);
      expect(broken.describe(), contains('GAGAL'));
    });

    test('blank ids and descriptions are rejected', () {
      expect(
        () => Wave3SecurityThreat(
          threatId: ' ',
          surface: Wave3SecuritySurface.spoilerLeak,
          description: 'x',
        ),
        throwsArgumentError,
      );
      expect(
        () =>
            Wave3SecurityCheckOutcome(checkId: '', passed: true, evidence: 'x'),
        throwsArgumentError,
      );
    });
  });

  group('production fail-closed contract for missing checksum', () {
    test('payload without checksum is blocking and cannot be imported', () {
      final bundle = EncyclopediaPortabilityService.buildBundle(
        documents: [_doc('r1', EncyclopediaDomain.herbology, 'Void Fern')],
        options: EncyclopediaExportOptions(explicitExport: true),
      );
      final text = EncyclopediaPortabilityService.exportText(bundle);
      final decoded = jsonDecode(text) as Map<String, Object?>
        ..remove('checksum');
      final stripped = jsonEncode(decoded);
      // Sanity: the stripped text still decodes and holds the same document.
      expect(stripped, contains('Void Fern'));
      final report = EncyclopediaPortabilityService.validateJson(stripped);
      expect(report.hasBlockingIssues, isTrue);
      expect(
        report.issuesOfKind(PortabilityValidationKind.checksumMissing),
        isNotEmpty,
      );
      expect(
        () => EncyclopediaPortabilityService.importText(stripped),
        throwsStateError,
      );
    });
  });
}
