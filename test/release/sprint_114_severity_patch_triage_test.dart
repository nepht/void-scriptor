import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/severity_patch_triage_v114.dart';

void main() {
  group('114.27 Severity & Patch Triage', () {
    test('empty triage register is blocked without claiming a decision', () {
      final decision = SeverityPatchTriage().evaluate();

      expect(decision.status, TriageStatus.blocked);
      expect(decision.caseCount, 0);
      expect(decision.limitations, isNotEmpty);
    });

    test('complete case records canonical severity and patch decision', () {
      const triageCase = TriageCase(
        issueId: 'ISS-001',
        severity: 'P1',
        decision: TriageDecision.maintenanceFix,
        rationale: 'Workflow regression has a bounded local correction.',
        evidence: <String>['reproduction', 'root cause'],
      );

      expect(SeverityPatchTriage.missingFields(triageCase), isEmpty);
      final report = SeverityPatchTriage()..add(triageCase);
      expect(report.evaluate().status, TriageStatus.pass);
    });

    test('all canonical decisions are accepted and unknown values fail', () {
      expect(
        TriageDecision.values,
        containsAll(<TriageDecision>[
          TriageDecision.emergencyFix,
          TriageDecision.maintenanceFix,
          TriageDecision.documentationFix,
          TriageDecision.defer,
          TriageDecision.flagOff,
          TriageDecision.rollback,
        ]),
      );

      final triage = SeverityPatchTriage()
        ..add(
          const TriageCase(
            issueId: 'ISS-002',
            severity: 'P2',
            decision: TriageDecision.defer,
            rationale: 'Evidence is insufficient for a patch.',
            evidence: <String>['incident intake'],
          ),
        )
        ..add(
          const TriageCase(
            issueId: 'ISS-003',
            severity: 'P0',
            decision: TriageDecision.rollback,
            rationale: 'The release path is unsafe until contained.',
            evidence: <String>['security review'],
          ),
        );

      expect(triage.evaluate().status, TriageStatus.pass);
    });

    test('incomplete case fails with field evidence', () {
      final triage = SeverityPatchTriage()
        ..add(
          const TriageCase(
            issueId: '',
            severity: 'P1',
            decision: TriageDecision.maintenanceFix,
            rationale: '',
            evidence: <String>[],
          ),
        );

      final decision = triage.evaluate();
      expect(decision.status, TriageStatus.fail);
      expect(decision.limitations.join(' '), contains('issue_id'));
      expect(decision.limitations.join(' '), contains('rationale'));
      expect(decision.limitations.join(' '), contains('evidence'));
    });
  });
}
