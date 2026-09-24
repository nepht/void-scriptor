/// Fail-closed readiness contract for activating Sprint 115 after Sprint 114.
library;

enum Sprint115ReadinessState { pass, fail, blocked }

class Sprint115ReadinessEvidence {
  Sprint115ReadinessEvidence({
    required this.stableReleaseHealthGate,
    required this.patchDecision,
    required List<String> remainingIncidents,
    required this.capacity,
    required this.accountCloudCenterScope,
    required this.securityPrivacyConstraints,
    required this.releaseState,
  }) : remainingIncidents = List<String>.unmodifiable(remainingIncidents);

  final String stableReleaseHealthGate;
  final String patchDecision;
  final List<String> remainingIncidents;
  final String capacity;
  final String accountCloudCenterScope;
  final String securityPrivacyConstraints;
  final String releaseState;

  Sprint115ReadinessEvidence copyWith({
    String? stableReleaseHealthGate,
    String? patchDecision,
    List<String>? remainingIncidents,
    String? capacity,
    String? accountCloudCenterScope,
    String? securityPrivacyConstraints,
    String? releaseState,
  }) {
    return Sprint115ReadinessEvidence(
      stableReleaseHealthGate:
          stableReleaseHealthGate ?? this.stableReleaseHealthGate,
      patchDecision: patchDecision ?? this.patchDecision,
      remainingIncidents: remainingIncidents ?? this.remainingIncidents,
      capacity: capacity ?? this.capacity,
      accountCloudCenterScope:
          accountCloudCenterScope ?? this.accountCloudCenterScope,
      securityPrivacyConstraints:
          securityPrivacyConstraints ?? this.securityPrivacyConstraints,
      releaseState: releaseState ?? this.releaseState,
    );
  }
}

class Sprint115ReadinessReport {
  Sprint115ReadinessReport({
    required this.state,
    required this.verdict,
    required List<String> missingEvidence,
    required List<String> violations,
  }) : missingEvidence = List<String>.unmodifiable(missingEvidence),
       violations = List<String>.unmodifiable(violations);

  final Sprint115ReadinessState state;
  final String verdict;
  final List<String> missingEvidence;
  final List<String> violations;
  final String externalGates = 'DEFERRED-EXTERNAL';

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'state': state.name,
      'verdict': verdict,
      'missing_evidence': List<String>.from(missingEvidence),
      'violations': List<String>.from(violations),
      'external_gates': externalGates,
    };
  }
}

abstract final class Sprint115ReadinessGateContract {
  static const String canonicalStep = '114.43';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_115_readiness_gate.json';

  static const List<String> requiredEvidence = <String>[
    'stable_release_health_gate',
    'patch_decision',
    'remaining_incidents',
    'capacity',
    'account_cloud_center_scope',
    'security_privacy_constraints',
  ];

  static const Set<String> releaseStates = <String>{
    'RELEASED',
    'DELAYED',
    'ROLLED_BACK',
  };

  static const Set<String> patchDecisions = <String>{
    'BUILD_1_2_1',
    'NO_PATCH',
    'EMERGENCY_RELEASE_ALREADY_ISSUED',
  };

  static const Set<String> approvedScopes = <String>{
    'CORRECTIVE_SCOPE_APPROVED',
    'FULL_SCOPE_APPROVED',
  };

  static const Set<String> localVerifiedStates = <String>{'VERIFIED-LOCAL'};
}

class Sprint115ReadinessGate {
  Sprint115ReadinessReport evaluate(Sprint115ReadinessEvidence? evidence) {
    if (evidence == null) {
      return _report(
        state: Sprint115ReadinessState.blocked,
        verdict: 'NO_READINESS_EVIDENCE',
        missingEvidence: Sprint115ReadinessGateContract.requiredEvidence,
      );
    }

    final missing = <String>[];
    final violations = <String>[];
    final releaseState = evidence.releaseState.trim();
    final healthGate = evidence.stableReleaseHealthGate.trim();
    final patchDecision = evidence.patchDecision.trim();
    final capacity = evidence.capacity.trim();
    final scope = evidence.accountCloudCenterScope.trim();
    final securityPrivacy = evidence.securityPrivacyConstraints.trim();

    if (!Sprint115ReadinessGateContract.releaseStates.contains(releaseState)) {
      violations.add('unsupported_release_state_$releaseState');
    }
    if (!Sprint115ReadinessGateContract.localVerifiedStates.contains(
      healthGate,
    )) {
      if (healthGate.isEmpty) {
        missing.add('stable_release_health_gate');
      } else if (healthGate != 'DEFERRED-EXTERNAL') {
        violations.add('stable_release_health_gate_not_verified');
      } else {
        missing.add('stable_release_health_gate');
      }
    }
    if (!Sprint115ReadinessGateContract.patchDecisions.contains(
      patchDecision,
    )) {
      if (patchDecision.isEmpty) {
        missing.add('patch_decision');
      } else {
        violations.add('unsupported_patch_decision_$patchDecision');
      }
    }
    if (evidence.remainingIncidents.any(
      (incident) => incident.trim().isEmpty,
    )) {
      violations.add('blank_remaining_incident');
    }
    if (evidence.remainingIncidents.isNotEmpty) {
      missing.add('remaining_incidents');
    }
    if (capacity.isEmpty) {
      missing.add('capacity');
    } else if (!Sprint115ReadinessGateContract.localVerifiedStates.contains(
      capacity,
    )) {
      violations.add('capacity_not_verified');
    }
    if (!Sprint115ReadinessGateContract.approvedScopes.contains(scope)) {
      if (scope.isEmpty) {
        missing.add('account_cloud_center_scope');
      } else {
        violations.add('account_cloud_center_scope_unapproved');
      }
    }
    if (securityPrivacy.isEmpty) {
      missing.add('security_privacy_constraints');
    } else if (!Sprint115ReadinessGateContract.localVerifiedStates.contains(
      securityPrivacy,
    )) {
      if (securityPrivacy == 'DEFERRED-EXTERNAL') {
        missing.add('security_privacy_constraints');
      } else {
        violations.add('security_privacy_constraints_not_verified');
      }
    }

    if (releaseState == 'RELEASED' && scope == 'CORRECTIVE_SCOPE_APPROVED') {
      violations.add('stable_release_requires_full_scope_approval');
    }
    if (releaseState == 'ROLLED_BACK' && scope == 'FULL_SCOPE_APPROVED') {
      violations.add('rolled_back_release_requires_corrective_scope_only');
    }

    final state = missing.isNotEmpty
        ? Sprint115ReadinessState.blocked
        : violations.isNotEmpty
        ? Sprint115ReadinessState.fail
        : Sprint115ReadinessState.pass;
    final verdict = state == Sprint115ReadinessState.pass
        ? releaseState == 'RELEASED'
              ? 'STABLE_RELEASE_READY'
              : 'CORRECTIVE_SCOPE_APPROVED'
        : 'SPRINT_115_READINESS_NOT_VERIFIED';

    return _report(
      state: state,
      verdict: verdict,
      missingEvidence: missing,
      violations: violations,
    );
  }

  Sprint115ReadinessReport _report({
    required Sprint115ReadinessState state,
    required String verdict,
    required List<String> missingEvidence,
    List<String> violations = const <String>[],
  }) {
    return Sprint115ReadinessReport(
      state: state,
      verdict: verdict,
      missingEvidence: missingEvidence,
      violations: violations,
    );
  }
}
