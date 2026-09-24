/// Fail-closed maintenance release scope contract for Sprint 114.39.
library;

enum MaintenanceReleaseScopeState { pass, fail, blocked }

enum StableReleaseHealthDecision { pass, fail, blocked }

enum RolloutScopeDecision { expand, hold, reduce, rollback }

enum MaintenanceReleaseScopeDecision {
  build121('BUILD_1_2_1'),
  noPatch('NO_PATCH'),
  emergencyAlreadyIssued('EMERGENCY_RELEASE_ALREADY_ISSUED');

  const MaintenanceReleaseScopeDecision(this.wireName);

  final String wireName;
}

class MaintenanceReleaseScopeFix {
  const MaintenanceReleaseScopeFix({
    required this.fixId,
    required this.issueId,
    required this.source,
    required this.releaseNote,
  });

  final String fixId;
  final String issueId;
  final String source;
  final String releaseNote;
}

class MaintenanceReleaseScopeDecisionRecord {
  const MaintenanceReleaseScopeDecisionRecord({
    required this.decision,
    required this.stableReleaseHealthGate,
    required this.rolloutDecision,
    required this.approvedFixes,
    required this.rationale,
    required this.decisionAuthority,
  });

  final MaintenanceReleaseScopeDecision decision;
  final StableReleaseHealthDecision stableReleaseHealthGate;
  final RolloutScopeDecision rolloutDecision;
  final List<MaintenanceReleaseScopeFix> approvedFixes;
  final List<String> rationale;
  final String decisionAuthority;
}

class MaintenanceReleaseScopeReport {
  const MaintenanceReleaseScopeReport({
    required this.state,
    required this.decision,
    required this.approvedFixIds,
    required this.missingEvidence,
    required this.violations,
    required this.deferredChecks,
  });

  final MaintenanceReleaseScopeState state;
  final MaintenanceReleaseScopeDecision? decision;
  final List<String> approvedFixIds;
  final List<String> missingEvidence;
  final List<String> violations;
  final List<String> deferredChecks;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'state': state.name,
      'decision': decision?.wireName,
      'approved_fix_ids': <Object>[...approvedFixIds],
      'missing_evidence': List<String>.from(missingEvidence),
      'violations': List<String>.from(violations),
      'external_gates': 'DEFERRED-EXTERNAL',
      'deferred_checks': List<String>.from(deferredChecks),
    };
  }
}

abstract final class MaintenanceReleaseScopeContract {
  static const String canonicalStep = '114.39';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_114_maintenance_release_scope.json';

  static const List<MaintenanceReleaseScopeDecision> decisions =
      <MaintenanceReleaseScopeDecision>[
        MaintenanceReleaseScopeDecision.build121,
        MaintenanceReleaseScopeDecision.noPatch,
        MaintenanceReleaseScopeDecision.emergencyAlreadyIssued,
      ];

  static const List<String> requiredEvidence = <String>[
    'stable_release_health_gate',
    'rollout_decision',
    'approved_fix_scope',
    'rationale',
    'decision_authority',
  ];

  static const List<String> deferredChecks = <String>[
    'public_release_signing',
    'hosted_ci_validation',
    'live_production_telemetry',
    'published_artifact_validation',
    'upgrade_validation',
    'rollback_validation',
    'release_notes_publication',
    'publication',
  ];
}

class MaintenanceReleaseScopeGate {
  MaintenanceReleaseScopeReport evaluate(
    MaintenanceReleaseScopeDecisionRecord? record,
  ) {
    if (record == null) {
      return _report(
        state: MaintenanceReleaseScopeState.blocked,
        decision: null,
        approvedFixIds: const <String>[],
        missingEvidence: MaintenanceReleaseScopeContract.requiredEvidence,
        violations: const <String>[],
      );
    }

    final violations = <String>[];
    final seenFixIds = <String>{};
    final approvedFixIds = <String>[];

    for (var index = 0; index < record.approvedFixes.length; index += 1) {
      final fix = record.approvedFixes[index];
      final prefix = 'approved_fix_${index}_';
      if (fix.fixId.trim().isEmpty) {
        violations.add('${prefix}missing_fix_id');
      } else if (!seenFixIds.add(fix.fixId.trim())) {
        violations.add('${prefix}duplicate_fix_id');
      } else {
        approvedFixIds.add(fix.fixId.trim());
      }
      if (fix.issueId.trim().isEmpty) {
        violations.add('${prefix}missing_issue_id');
      }
      if (fix.source.trim().isEmpty) {
        violations.add('${prefix}missing_source');
      }
      if (fix.releaseNote.trim().isEmpty) {
        violations.add('${prefix}missing_release_note');
      }
    }

    if (record.rationale.isEmpty ||
        record.rationale.any((item) => item.trim().isEmpty)) {
      violations.add('rationale_missing_or_blank');
    }
    if (record.decisionAuthority.trim().isEmpty) {
      violations.add('decision_authority_missing_or_blank');
    }

    switch (record.decision) {
      case MaintenanceReleaseScopeDecision.build121:
        if (record.approvedFixes.isEmpty) {
          violations.add('build_requires_approved_fixes');
        }
      case MaintenanceReleaseScopeDecision.noPatch:
        if (record.approvedFixes.isNotEmpty) {
          violations.add('no_patch_with_approved_fixes');
        }
      case MaintenanceReleaseScopeDecision.emergencyAlreadyIssued:
        if (record.approvedFixes.isNotEmpty) {
          violations.add('emergency_already_issued_with_additional_fixes');
        }
    }

    return _report(
      state: violations.isEmpty
          ? MaintenanceReleaseScopeState.pass
          : MaintenanceReleaseScopeState.fail,
      decision: record.decision,
      approvedFixIds: approvedFixIds,
      missingEvidence: const <String>[],
      violations: violations,
    );
  }

  MaintenanceReleaseScopeReport _report({
    required MaintenanceReleaseScopeState state,
    required MaintenanceReleaseScopeDecision? decision,
    required List<String> approvedFixIds,
    required List<String> missingEvidence,
    required List<String> violations,
  }) {
    return MaintenanceReleaseScopeReport(
      state: state,
      decision: decision,
      approvedFixIds: List<String>.unmodifiable(approvedFixIds),
      missingEvidence: List<String>.unmodifiable(missingEvidence),
      violations: List<String>.unmodifiable(violations),
      deferredChecks: List<String>.unmodifiable(
        MaintenanceReleaseScopeContract.deferredChecks,
      ),
    );
  }
}
