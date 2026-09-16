// Sprint 111.45 - Beta 1 Acceptance Gate.
//
// Gate domain-only yang menilai kelayakan Wave 3 menjadi v1.2.0-beta.1.
// Delapan required_evidence kanonik (sprint_111.json step 111.45) dievaluasi
// dengan EKSEKUSI NYATA atas API produksi 111.40-111.44 — bukan review
// karangan:
//   feature_acceptance    -> Wave3GuideCoverageReport atas katalog kanonik (111.44)
//   alias_validation      -> UnifiedSearch atas alias nyata (111.37)
//   test_results          -> TestMatrixReport dari sumber teraudit (111.40)
//   migration_results     -> SchemaCompatibilityCheck atas katalog besar (111.6)
//   performance_results   -> fingerprint golden 111.41 vs probe terukur
//   security_review       -> EncyclopediaWave3SecurityHarness.run() (111.42)
//   accessibility_review  -> Wave3AccessibilityHarness.run() (111.43)
//   rollback_readiness    -> portability round-trip + backup contract (111.39/111.6)
//
// Batas jujur: gate ini level domain; D-SCHEMA-01 (persistence Drift) tetap
// OPEN dan dicatat sebagai batasan di summary, bukan kegagalan gate domain;
// th-power-loss-integrity tetap deferredHardware (hardware-bound).
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_wave3_beta_gate.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_wave3_test_matrix.dart';

void main() {
  group('gate contract (fail-closed)', () {
    test('required evidence = 8 kanonik sprint_111.json step 111.45', () {
      expect(
        Wave3GateEvidence.names,
        unorderedEquals(<String>[
          'feature_acceptance',
          'alias_validation',
          'test_results',
          'migration_results',
          'performance_results',
          'security_review',
          'accessibility_review',
          'rollback_readiness',
        ]),
      );
      expect(Wave3GateEvidence.values.length, 8);
    });

    test('kriteria valid: summary kosong ditolak, note wajib saat gagal', () {
      expect(
        () => Wave3GateCriterion.validated(
          evidence: Wave3GateEvidence.testResults,
          passed: true,
          summary: '   ',
          details: const {'coverage': 1.0},
        ),
        throwsArgumentError,
      );
      expect(
        () => Wave3GateCriterion.validated(
          evidence: Wave3GateEvidence.testResults,
          passed: false,
          summary: 'matrix incomplete',
          details: const {},
        ),
        throwsArgumentError,
        reason: 'kriteria gagal tanpa note = tidak dapat diaudit',
      );
      final ok = Wave3GateCriterion.validated(
        evidence: Wave3GateEvidence.testResults,
        passed: false,
        summary: 'matrix incomplete',
        note: 'suite regression belum terlacak',
        details: const {'coverage': 0.5},
      );
      expect(ok.passed, isFalse);
      expect(ok.evidenceName, 'test_results');
    });

    test('report menolak duplikat evidence dan evidence hilang', () {
      final pass = Wave3GateCriterion.validated(
        evidence: Wave3GateEvidence.featureAcceptance,
        passed: true,
        summary: 'ok',
        details: const {'entries': 22},
      );
      expect(
        () => Wave3BetaGateReport.of(<Wave3GateCriterion>[pass, pass]),
        throwsStateError,
        reason: 'duplikat evidence harus gagal-tertutup',
      );
      expect(
        () => Wave3BetaGateReport.of(<Wave3GateCriterion>[pass]),
        throwsStateError,
        reason: 'evidence hilang harus gagal-tertutup, bukan diam-diam lolos',
      );
    });

    test(
      'isReadyForBeta hanya saat SEMUA kriteria lulus; input tak dimutasi',
      () {
        final criteria = <Wave3GateCriterion>[
          for (final evidence in Wave3GateEvidence.values)
            Wave3GateCriterion.validated(
              evidence: evidence,
              passed: evidence != Wave3GateEvidence.securityReview,
              summary: 'simulasi',
              note: evidence == Wave3GateEvidence.securityReview
                  ? 'kontrol gagal'
                  : null,
              details: const {'checks': 1},
            ),
        ];
        final snapshotJson = criteria.map((c) => c.toJson()).toList();
        final report = Wave3BetaGateReport.of(criteria);
        expect(report.isReadyForBeta, isFalse);
        expect(report.failedCriteria.map((c) => c.evidenceName), [
          'security_review',
        ]);
        expect(report.passedCount, 7);
        // No-mutation: daftar input identik byte-per-byte sebelum/sesudah.
        expect(criteria.map((c) => c.toJson()).toList(), snapshotJson);
      },
    );

    test('toJson/fromJson byte-identik dan operator == struktural', () {
      final report = Wave3BetaGateReport.of(<Wave3GateCriterion>[
        for (final evidence in Wave3GateEvidence.values)
          Wave3GateCriterion.validated(
            evidence: evidence,
            passed: true,
            summary: 'semua lulus (simulasi)',
            details: const {'checks': 1},
          ),
      ]);
      final json = report.toJson();
      final restored = Wave3BetaGateReport.fromJson(json);
      expect(restored.toJson(), json);
      expect(restored, report);
      expect(restored.hashCode, report.hashCode);
      expect(restored.isReadyForBeta, isTrue);
    });

    test('describe() memuat verdict dan seluruh nama evidence', () {
      final report = Wave3BetaGateReport.of(<Wave3GateCriterion>[
        for (final evidence in Wave3GateEvidence.values)
          Wave3GateCriterion.validated(
            evidence: evidence,
            passed: true,
            summary: 'lulus',
            details: const {'checks': 1},
          ),
      ]);
      final text = report.describe();
      expect(text, contains('VERDICT'));
      for (final name in Wave3GateEvidence.names) {
        expect(text, contains(name));
      }
    });
  });

  group('evaluate(): eksekusi nyata atas harness 111.40-111.44', () {
    final report = Wave3BetaGateReport.evaluate();

    test('seluruh 8 required_evidence lulus -> READY untuk beta.1', () {
      expect(report.failedCriteria, isEmpty);
      expect(report.passedCount, 8);
      expect(report.isReadyForBeta, isTrue);
      expect(report.verdict, contains('READY'));
    });

    test('feature_acceptance: coverage panduan 111.44 lengkap', () {
      final criterion = report.criterionFor(
        Wave3GateEvidence.featureAcceptance,
      );
      expect(criterion.passed, isTrue);
      expect(criterion.details['guidesComplete'], isTrue);
      expect(criterion.details['requiredTopicsMissing'], isEmpty);
    });

    test('alias_validation: pencarian alias nyata menemukan target', () {
      final criterion = report.criterionFor(Wave3GateEvidence.aliasValidation);
      expect(criterion.passed, isTrue);
      expect(criterion.details['aliasHits'], greaterThan(0));
      expect(criterion.details['emptyAliasRejected'], isTrue);
      expect(criterion.details['roundTripPreserved'], isTrue);
    });

    test('test_results: matriks 9 suite COMPLETE dari sumber teraudit', () {
      final criterion = report.criterionFor(Wave3GateEvidence.testResults);
      expect(criterion.passed, isTrue);
      expect(criterion.details['matrixComplete'], isTrue);
      expect(criterion.details['passedSuites'], 9);
      expect(
        criterion.details['coverage'],
        EncyclopediaWave3TestMatrixReport.fromSources(
          EncyclopediaWave3TestSuiteSources.wave3MatrixCounts(),
        ).coverage,
      );
    });

    test('migration_results: schema kompatibel bersih + batas D-SCHEMA-01', () {
      final criterion = report.criterionFor(Wave3GateEvidence.migrationResults);
      expect(criterion.passed, isTrue);
      expect(criterion.details['cleanCatalogIssues'], 0);
      expect(
        criterion.details['domainSchemaOpen'],
        isTrue,
        reason: 'D-SCHEMA-01 tetap dicatat jujur sebagai batasan domain',
      );
    });

    test('performance_results: fingerprint dataset cocok probe terukur', () {
      final criterion = report.criterionFor(
        Wave3GateEvidence.performanceResults,
      );
      expect(criterion.passed, isTrue);
      expect(criterion.details['fingerprintsMatched'], 5);
      expect(criterion.details['goldenCount'], 5);
    });

    test(
      'security_review: harness lulus; power-loss tetap deferredHardware',
      () {
        final criterion = report.criterionFor(Wave3GateEvidence.securityReview);
        expect(criterion.passed, isTrue);
        expect(criterion.details['securityPassing'], isTrue);
        expect(
          criterion.details['deferredThreatIds'],
          ['th-power-loss-integrity'],
          reason: 'hardware-bound tidak boleh dianggap lunak',
        );
      },
    );

    test('accessibility_review: tanpa fail, semua ranah tercover', () {
      final criterion = report.criterionFor(
        Wave3GateEvidence.accessibilityReview,
      );
      expect(criterion.passed, isTrue);
      expect(criterion.details['hasFailures'], isFalse);
      expect(criterion.details['allSurfacesCovered'], isTrue);
    });

    test('rollback_readiness: round-trip byte-identik + kontrak backup', () {
      final criterion = report.criterionFor(
        Wave3GateEvidence.rollbackReadiness,
      );
      expect(criterion.passed, isTrue);
      expect(criterion.details['checksumVerified'], isTrue);
      expect(criterion.details['roundTripIdentical'], isTrue);
      expect(criterion.details['backupContractAccepted'], isTrue);
    });
  });
}
