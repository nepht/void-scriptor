import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/release_candidate_entry_gate.dart';

void main() {
  group('112.1 Release Candidate Entry Gate', () {
    test(
      'canonical gate admits RC work only with five required evidence items',
      () {
        final report = ReleaseCandidateEntryGate.evaluateCanonical();

        expect(report.evidence.map((entry) => entry.id), <String>[
          'sprint_109_acceptance',
          'sprint_110_acceptance',
          'sprint_111_acceptance',
          'open_risk_register',
          'migration_readiness',
        ]);
        expect(report.isEntryAllowed, isTrue);
        expect(report.decision, RcEntryDecision.readyWithOwnedRisk);
        expect(
          report.evidenceFor('sprint_109_acceptance').status,
          RcEvidenceStatus.acceptedWithRisk,
        );
        expect(
          report.evidenceFor('sprint_110_acceptance').status,
          RcEvidenceStatus.accepted,
        );
        expect(
          report.evidenceFor('sprint_111_acceptance').status,
          RcEvidenceStatus.accepted,
        );
        expect(
          report.evidenceFor('migration_readiness').status,
          RcEvidenceStatus.readyWithLimits,
        );
        expect(report.openRisks, isNotEmpty);
        expect(
          report.openRisks.every(
            (risk) => risk.owner.isNotEmpty && risk.mitigation.isNotEmpty,
          ),
          isTrue,
        );
        expect(
          report.openRisks.map((risk) => risk.id),
          contains('D-SCHEMA-01'),
        );
        expect(report.describe(), contains('READY_WITH_OWNED_RISK'));
        expect(report.describe(), contains('sprint_109_acceptance'));
      },
    );

    test('fails closed when one canonical evidence item is missing', () {
      final canonical = ReleaseCandidateEntryGate.evaluateCanonical();

      expect(
        () => RcEntryReport.fromEvidence(
          evidence: canonical.evidence
              .where((entry) => entry.id != 'migration_readiness')
              .toList(),
          openRisks: canonical.openRisks,
        ),
        throwsStateError,
      );
    });

    test('fails closed on duplicate evidence and unowned open risk', () {
      final canonical = ReleaseCandidateEntryGate.evaluateCanonical();

      expect(
        () => RcEntryReport.fromEvidence(
          evidence: <RcEntryEvidence>[
            ...canonical.evidence,
            canonical.evidence.first,
          ],
          openRisks: canonical.openRisks,
        ),
        throwsStateError,
      );
      expect(
        () => RcOpenRisk.validated(
          id: 'unowned-risk',
          title: 'Unowned risk',
          owner: ' ',
          mitigation: 'Mitigate before RC approval',
        ),
        throwsArgumentError,
      );
    });

    test('a blocked upstream decision blocks RC entry', () {
      final canonical = ReleaseCandidateEntryGate.evaluateCanonical();
      final blocked = canonical.evidence
          .map(
            (entry) => entry.id == 'sprint_110_acceptance'
                ? RcEntryEvidence.validated(
                    id: entry.id,
                    status: RcEvidenceStatus.blocked,
                    source: entry.source,
                    summary: 'Upstream acceptance is blocked.',
                  )
                : entry,
          )
          .toList();

      final report = RcEntryReport.fromEvidence(
        evidence: blocked,
        openRisks: canonical.openRisks,
      );
      expect(report.isEntryAllowed, isFalse);
      expect(report.decision, RcEntryDecision.blocked);
    });
  });
}
