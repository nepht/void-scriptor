// Sprint 111.46 - Sprint Closure.
//
// Gate closure domain-only fail-closed yang menilai tujuh definition_of_done
// kanonik (sprint_111.json step 111.46):
//   entry_gate_passed
//   6_feature_contracts_resolved
//   feature_30_merged_into_24
//   cross_domain_integration_verified
//   quality_reviews_complete
//   beta_1_decision_recorded
//   remaining_risks_owned
// dengan EKSEKUSI NYATA atas API produksi 111.8 (flags), 111.38 (integration),
// dan 111.45 (beta gate yang menjalankan harness 111.40-111.43) — bukan
// review naratif.
//
// Batas jujur: closure level domain. Keputusan rilis/tag/push tetap milik
// Choirudin; risiko terbuka (D-SCHEMA-01, power-loss deferredHardware,
// deferredNative) wajib berpemilik + rencana, bukan disembunyikan.
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_spoiler_accessibility.dart';
import 'package:void_scriptor/features/world_logic/domain/encyclopedia_wave3_closure.dart';

void main() {
  group('closure contract (fail-closed)', () {
    test('seven DoD items = kanonik sprint_111.json step 111.46', () {
      expect(
        SprintClosureItem.names,
        unorderedEquals(<String>[
          'entry_gate_passed',
          '6_feature_contracts_resolved',
          'feature_30_merged_into_24',
          'cross_domain_integration_verified',
          'quality_reviews_complete',
          'beta_1_decision_recorded',
          'remaining_risks_owned',
        ]),
      );
      expect(SprintClosureItem.values.length, 7);
    });

    test('kriteria valid: summary kosong ditolak, note wajib saat gagal', () {
      expect(
        () => SprintClosureCriterion.validated(
          item: SprintClosureItem.entryGatePassed,
          passed: true,
          summary: '   ',
        ),
        throwsArgumentError,
      );
      expect(
        () => SprintClosureCriterion.validated(
          item: SprintClosureItem.entryGatePassed,
          passed: false,
          summary: 'entry gate belum terbukti',
        ),
        throwsArgumentError,
        reason: 'kriteria gagal tanpa note = tidak dapat diaudit',
      );
      final ok = SprintClosureCriterion.validated(
        item: SprintClosureItem.entryGatePassed,
        passed: false,
        summary: 'entry gate belum terbukti',
        note: '111.1 status belum resolved pada sumber',
      );
      expect(ok.passed, isFalse);
      expect(ok.itemName, 'entry_gate_passed');
    });

    test('report menolak duplikat item dan item hilang', () {
      final pass = SprintClosureCriterion.validated(
        item: SprintClosureItem.entryGatePassed,
        passed: true,
        summary: 'ok',
      );
      expect(
        () => SprintClosureReport.of([pass, pass]),
        throwsStateError,
        reason: 'duplikat DoD item membuat hitungan palsu',
      );
      expect(() => SprintClosureReport.of(const []), throwsStateError);
    });
  });

  group('entry_gate_passed', () {
    test('feature flags default OFF untuk seluruh katalog wave3', () {
      const flags = EncyclopediaFeatureFlags();
      for (final id in EncyclopediaFeatureFlags.wave3Catalog) {
        expect(flags.isEnabled(id), isFalse, reason: '$id default OFF');
      }
    });

    test('dokumen entry gate + scope contract tercatat non-kosong', () {
      const records = Wave3ClosureRecords.canonical;
      expect(records.entryGateDoc, contains('sprint_111_entry_gate.md'));
      expect(
        records.scopeContractDoc,
        contains('sprint_111_scope_contract.md'),
      );
    });
  });

  group('6_feature_contracts_resolved', () {
    test('census sumber = 111.1..111.45 (111.46 adalah langkah ini)', () {
      final census = Wave3ClosureSources.sprint111ResolvedBeforeClosure();
      expect(census.first, '111.1');
      expect(census.last, '111.45');
      expect(census.length, 45);
      expect(census.contains('111.46'), isFalse);
    });

    test('keenam kontrak fitur (F23/F24/F26/F27/F28/F29) tercakup sumber', () {
      final report = SprintClosureReport.evaluate();
      final criterion = report.criterionFor(
        SprintClosureItem.featureContractsResolved,
      );
      expect(criterion.passed, isTrue, reason: criterion.summary);
      final features = criterion.details['featureStepCoverage'] as List;
      expect(features.length, 6);
      // Setiap fitur wajib lulus seluruh langkah kanoniknya.
      for (final entry in features) {
        final map = entry as Map<String, Object?>;
        expect(map['allStepsResolved'], isTrue, reason: '$map');
      }
      expect(criterion.details['foundationResolved'], isTrue);
    });

    test('sumber dengan langkah fitur hilang gagal tanpa melempar', () {
      final partial = Wave3ClosureSources(
        resolvedStepIds: Wave3ClosureSources.sprint111ResolvedBeforeClosure()
          ..removeLast(),
      );
      final report = SprintClosureReport.evaluate(sources: partial);
      final criterion = report.criterionFor(
        SprintClosureItem.featureContractsResolved,
      );
      expect(criterion.passed, isFalse);
      expect(criterion.note, isNotNull);
    });
  });

  group('feature_30_merged_into_24', () {
    test('F30 tidak punya identitas flag independen (ditolak keras)', () {
      const flags = EncyclopediaFeatureFlags();
      expect(() => flags.isEnabled('F30'), throwsArgumentError);
    });

    test('alias tercatat: F30 -> F24 dengan alasan kanonik', () {
      final alias = Wave3ClosureRecords.canonical.feature30Alias;
      expect(alias.aliasFeatureId, 'F30');
      expect(alias.canonicalFeatureId, 'F24');
      expect(alias.reason, contains('Bestiary Creature Profile'));
      expect(alias.reason, contains('Bestiary Journal'));
    });
  });

  group('cross_domain_integration_verified', () {
    test('validasi integrasi 111.38 nyata: katalog, link, timeline, graph', () {
      final criterion = SprintClosureReport.evaluate().criterionFor(
        SprintClosureItem.crossDomainIntegrationVerified,
      );
      expect(criterion.passed, isTrue, reason: criterion.summary);
      expect(criterion.details['integrationIssueCount'], 0);
      expect(criterion.details['resolvedLinkCount'], greaterThan(0));
    });

    test('kontrol positif non-vakum: link rusak terdeteksi validator', () {
      final finding = Wave3ClosureIntegrationProbe.brokenLinkFinding();
      expect(finding, isNotNull);
      expect(finding!, contains('matches no catalog entity'));
    });
  });

  group('quality_reviews_complete', () {
    test('beta gate 111.45 lulus penuh via eksekusi nyata', () {
      final criterion = SprintClosureReport.evaluate().criterionFor(
        SprintClosureItem.qualityReviewsComplete,
      );
      expect(criterion.passed, isTrue, reason: criterion.summary);
      expect(criterion.details['gateReadyForBeta'], isTrue);
      expect(criterion.details['gatePassedCount'], 8);
      // Ancaman hardware-bound tetap tercatat, tidak dianggap lunak.
      expect(
        criterion.details['deferredThreatIds'],
        contains('th-power-loss-integrity'),
      );
    });
  });

  group('beta_1_decision_recorded', () {
    test('keputusan beta tercatat dengan provenansi dan batas otoritas', () {
      final decision = Wave3ClosureRecords.canonical.betaDecision;
      expect(decision.verdict, contains('READY'));
      expect(decision.recordedBy, isNotEmpty);
      expect(
        decision.authorityNote,
        contains('Choirudin'),
        reason: 'rilis/tag/push tetap keputusan pengguna',
      );
    });

    test('record keputusan round-trip JSON byte-identik', () {
      final decision = Wave3ClosureRecords.canonical.betaDecision;
      final json = decision.toJson();
      final restored = Beta1Decision.fromJson(json);
      expect(restored.toJson(), json);
      expect(restored, decision);
    });
  });

  group('remaining_risks_owned', () {
    test('risiko kanonik: D-SCHEMA-01, power-loss, deferredNative', () {
      final risks = Wave3ClosureRisks.canonical;
      final ids = risks.map((r) => r.riskId).toList();
      expect(ids, contains('D-SCHEMA-01'));
      expect(ids, contains('th-power-loss-integrity'));
      expect(ids, contains('deferred-native-gui'));
      for (final risk in risks) {
        expect(risk.owner, isNotEmpty, reason: '${risk.riskId} tanpa pemilik');
        expect(risk.plan, isNotEmpty, reason: '${risk.riskId} tanpa rencana');
      }
      expect(
        risks.firstWhere((r) => r.riskId == 'th-power-loss-integrity').status,
        ClosureRiskStatus.deferred,
      );
    });

    test('risiko tanpa pemilik atau rencana ditolak (fail-closed)', () {
      expect(
        () => ClosureRisk.validated(
          riskId: 'r-x',
          title: 'risiko uji',
          status: ClosureRiskStatus.open,
          owner: '   ',
          plan: 'rencana',
        ),
        throwsArgumentError,
      );
      expect(
        () => ClosureRisk.validated(
          riskId: 'r-x',
          title: 'risiko uji',
          status: ClosureRiskStatus.open,
          owner: 'pemilik',
          plan: '',
        ),
        throwsArgumentError,
      );
    });
  });

  group('agregat closure', () {
    test('evaluate() menutup sprint 111 pada level domain', () {
      final report = SprintClosureReport.evaluate();
      expect(report.criteria, hasLength(7));
      expect(report.passedCount, 7);
      expect(report.isClosed, isTrue);
      expect(report.describe(), contains('VERDICT: SPRINT 111 CLOSED'));
    });

    test('report gagal (bukan lempar) saat satu DoD tidak terpenuhi', () {
      final partial = Wave3ClosureSources(
        resolvedStepIds: Wave3ClosureSources.sprint111ResolvedBeforeClosure()
          ..removeAt(0), // 111.1 entry gate hilang
      );
      final report = SprintClosureReport.evaluate(sources: partial);
      expect(report.isClosed, isFalse);
      expect(report.describe(), contains('VERDICT: SPRINT 111 NOT CLOSED'));
      expect(report.failedItems, contains(SprintClosureItem.entryGatePassed));
    });

    test('report JSON round-trip byte-identik', () {
      final report = SprintClosureReport.evaluate();
      final json = report.toJson();
      final restored = SprintClosureReport.fromJson(json);
      expect(restored.toJson(), json);
    });

    test('evaluate() tidak memutasi sumber (no-mutation, JSON-compare)', () {
      final sources = Wave3ClosureSources(
        resolvedStepIds: List<String>.of(
          Wave3ClosureSources.sprint111ResolvedBeforeClosure(),
        ),
      );
      final before = List<String>.of(sources.resolvedStepIds);
      SprintClosureReport.evaluate(sources: sources);
      expect(List<String>.of(sources.resolvedStepIds), before);
    });
  });
}
