import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/maintenance_release_scope_v114.dart';

void main() {
  group('114.39 Maintenance Release Scope', () {
    test('declares the canonical decisions in roadmap order', () {
      expect(MaintenanceReleaseScopeContract.canonicalStep, '114.39');
      expect(
        MaintenanceReleaseScopeContract.decisions.map(
          (decision) => decision.wireName,
        ),
        <String>['BUILD_1_2_1', 'NO_PATCH', 'EMERGENCY_RELEASE_ALREADY_ISSUED'],
      );
    });

    test('absent scope is blocked without inventing a patch decision', () {
      final report = MaintenanceReleaseScopeGate().evaluate(null);

      expect(report.state, MaintenanceReleaseScopeState.blocked);
      expect(report.decision, isNull);
      expect(
        report.missingEvidence,
        MaintenanceReleaseScopeContract.requiredEvidence,
      );
      expect(report.deferredChecks, contains('public_release_signing'));
    });

    test('a complete no-patch decision passes with an explicit rationale', () {
      const decision = MaintenanceReleaseScopeDecisionRecord(
        decision: MaintenanceReleaseScopeDecision.noPatch,
        stableReleaseHealthGate: StableReleaseHealthDecision.pass,
        rolloutDecision: RolloutScopeDecision.hold,
        approvedFixes: <MaintenanceReleaseScopeFix>[],
        rationale: <String>[
          'No approved production defect requires a v1.2.1 maintenance patch.',
        ],
        decisionAuthority: 'Choirudin',
      );

      final report = MaintenanceReleaseScopeGate().evaluate(decision);

      expect(report.state, MaintenanceReleaseScopeState.pass);
      expect(report.decision, MaintenanceReleaseScopeDecision.noPatch);
      expect(report.approvedFixIds, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('a build decision requires unique approved fixes and evidence', () {
      const fix = MaintenanceReleaseScopeFix(
        fixId: 'VS-114-001',
        issueId: 'issue-1',
        source: 'docs/planning/v1.2/sprint_114_p1_stability_fixes.json',
        releaseNote: 'Fixes a verified production regression.',
      );
      const decision = MaintenanceReleaseScopeDecisionRecord(
        decision: MaintenanceReleaseScopeDecision.build121,
        stableReleaseHealthGate: StableReleaseHealthDecision.pass,
        rolloutDecision: RolloutScopeDecision.hold,
        approvedFixes: <MaintenanceReleaseScopeFix>[fix],
        rationale: <String>['Approved patch scope is limited to VS-114-001.'],
        decisionAuthority: 'Choi',
      );

      final report = MaintenanceReleaseScopeGate().evaluate(decision);

      expect(report.state, MaintenanceReleaseScopeState.pass);
      expect(report.decision, MaintenanceReleaseScopeDecision.build121);
      expect(report.approvedFixIds, <String>['VS-114-001']);
    });

    test('an unapproved or incomplete fix cannot enter v1.2.1 scope', () {
      const fix = MaintenanceReleaseScopeFix(
        fixId: '   ',
        issueId: '',
        source: ' ',
        releaseNote: '',
      );
      const decision = MaintenanceReleaseScopeDecisionRecord(
        decision: MaintenanceReleaseScopeDecision.build121,
        stableReleaseHealthGate: StableReleaseHealthDecision.pass,
        rolloutDecision: RolloutScopeDecision.hold,
        approvedFixes: <MaintenanceReleaseScopeFix>[fix],
        rationale: <String>['Build requested.'],
        decisionAuthority: 'Choi',
      );

      final report = MaintenanceReleaseScopeGate().evaluate(decision);

      expect(report.state, MaintenanceReleaseScopeState.fail);
      expect(report.violations, contains('approved_fix_0_missing_fix_id'));
      expect(report.violations, contains('approved_fix_0_missing_issue_id'));
      expect(report.violations, contains('approved_fix_0_missing_source'));
      expect(
        report.violations,
        contains('approved_fix_0_missing_release_note'),
      );
    });

    test('no-patch rejects a non-empty fix list', () {
      const fix = MaintenanceReleaseScopeFix(
        fixId: 'VS-114-001',
        issueId: 'issue-1',
        source: 'docs/source.json',
        releaseNote: 'Unapproved scope.',
      );
      final report = MaintenanceReleaseScopeGate().evaluate(
        const MaintenanceReleaseScopeDecisionRecord(
          decision: MaintenanceReleaseScopeDecision.noPatch,
          stableReleaseHealthGate: StableReleaseHealthDecision.pass,
          rolloutDecision: RolloutScopeDecision.hold,
          approvedFixes: <MaintenanceReleaseScopeFix>[fix],
          rationale: <String>['No patch selected.'],
          decisionAuthority: 'Choi',
        ),
      );

      expect(report.state, MaintenanceReleaseScopeState.fail);
      expect(report.violations, contains('no_patch_with_approved_fixes'));
    });

    test('emergency-already-issued must not claim an unissued build', () {
      final report = MaintenanceReleaseScopeGate().evaluate(
        const MaintenanceReleaseScopeDecisionRecord(
          decision: MaintenanceReleaseScopeDecision.emergencyAlreadyIssued,
          stableReleaseHealthGate: StableReleaseHealthDecision.blocked,
          rolloutDecision: RolloutScopeDecision.rollback,
          approvedFixes: <MaintenanceReleaseScopeFix>[],
          rationale: <String>['Emergency fix already issued.'],
          decisionAuthority: 'Choi',
        ),
      );

      expect(report.state, MaintenanceReleaseScopeState.pass);
      expect(
        report.decision,
        MaintenanceReleaseScopeDecision.emergencyAlreadyIssued,
      );
      expect(report.deferredChecks, contains('published_artifact_validation'));
    });

    test('external publication gates remain deferred for every decision', () {
      final report = MaintenanceReleaseScopeGate().evaluate(
        const MaintenanceReleaseScopeDecisionRecord(
          decision: MaintenanceReleaseScopeDecision.noPatch,
          stableReleaseHealthGate: StableReleaseHealthDecision.pass,
          rolloutDecision: RolloutScopeDecision.hold,
          approvedFixes: <MaintenanceReleaseScopeFix>[],
          rationale: <String>['No patch needed.'],
          decisionAuthority: 'Choi',
        ),
      );

      expect(report.toJson()['external_gates'], 'DEFERRED-EXTERNAL');
      expect(
        report.deferredChecks,
        containsAll(<String>[
          'public_release_signing',
          'hosted_ci_validation',
          'live_production_telemetry',
          'published_artifact_validation',
          'upgrade_validation',
          'rollback_validation',
          'release_notes_publication',
          'publication',
        ]),
      );
    });

    test('manifest records NO_PATCH without claiming v1.2.1 publication', () {
      final file = File(MaintenanceReleaseScopeContract.manifestPath);
      expect(file.existsSync(), isTrue);
      final manifest =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(manifest['canonical_step'], '114.39');
      expect(manifest['status'], 'VERIFIED-LOCAL');
      expect(manifest['selected_decision'], 'NO_PATCH');
      expect(manifest['target_version'], '1.2.1');
      expect(manifest['approved_fixes'], isEmpty);
      expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
      expect(manifest['limitations'], isNotEmpty);
    });
  });
}
