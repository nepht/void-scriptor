import 'dart:collection';

import 'package:void_scriptor/features/world_logic/domain/release_health_monitoring.dart';

enum StableReleaseHealthGateState { pass, fail, blocked }

enum StableReleaseDimensionStatus { stable, reduced, blocked, rolledBack }

class StableReleaseHealthEvidence {
  StableReleaseHealthEvidence({
    required this.observationWindowComplete,
    required Map<String, String> healthSignals,
    this.incidentStatus,
    this.migrationStatus,
    this.recoveryStatus,
    this.securityPrivacyStatus,
    this.accessibilityStatus,
    this.supportStatus,
    this.rolloutStatus,
  }) : healthSignals = UnmodifiableMapView<String, String>(
         Map<String, String>.from(healthSignals),
       );

  final bool observationWindowComplete;
  final Map<String, String> healthSignals;
  final StableReleaseDimensionStatus? incidentStatus;
  final StableReleaseDimensionStatus? migrationStatus;
  final StableReleaseDimensionStatus? recoveryStatus;
  final StableReleaseDimensionStatus? securityPrivacyStatus;
  final StableReleaseDimensionStatus? accessibilityStatus;
  final StableReleaseDimensionStatus? supportStatus;
  final StableReleaseDimensionStatus? rolloutStatus;

  StableReleaseHealthEvidence copyWith({
    bool? observationWindowComplete,
    Map<String, String>? healthSignals,
    StableReleaseDimensionStatus? incidentStatus,
    StableReleaseDimensionStatus? migrationStatus,
    StableReleaseDimensionStatus? recoveryStatus,
    StableReleaseDimensionStatus? securityPrivacyStatus,
    StableReleaseDimensionStatus? accessibilityStatus,
    StableReleaseDimensionStatus? supportStatus,
    StableReleaseDimensionStatus? rolloutStatus,
  }) {
    return StableReleaseHealthEvidence(
      observationWindowComplete:
          observationWindowComplete ?? this.observationWindowComplete,
      healthSignals: healthSignals ?? this.healthSignals,
      incidentStatus: incidentStatus ?? this.incidentStatus,
      migrationStatus: migrationStatus ?? this.migrationStatus,
      recoveryStatus: recoveryStatus ?? this.recoveryStatus,
      securityPrivacyStatus:
          securityPrivacyStatus ?? this.securityPrivacyStatus,
      accessibilityStatus: accessibilityStatus ?? this.accessibilityStatus,
      supportStatus: supportStatus ?? this.supportStatus,
      rolloutStatus: rolloutStatus ?? this.rolloutStatus,
    );
  }
}

class StableReleaseHealthGateReport {
  const StableReleaseHealthGateReport({
    required this.state,
    required this.verdict,
    required this.missingEvidence,
    required this.invalidEvidence,
    required this.violations,
    required this.healthSignals,
    required this.deferredChecks,
  });

  final StableReleaseHealthGateState state;
  final String verdict;
  final List<String> missingEvidence;
  final List<String> invalidEvidence;
  final List<String> violations;
  final Map<String, String> healthSignals;
  final List<String> deferredChecks;

  Map<String, Object> toJson() {
    return <String, Object>{
      'state': state.name,
      'verdict': verdict,
      'missing_evidence': List<String>.from(missingEvidence),
      'invalid_evidence': List<String>.from(invalidEvidence),
      'violations': List<String>.from(violations),
      'external_checks_status': 'DEFERRED-EXTERNAL',
      'deferred_checks': List<String>.from(deferredChecks),
    };
  }
}

abstract final class StableReleaseHealthGateContract {
  static const String canonicalStep = '114.38';
  static const String manifestPath =
      'docs/planning/v1.2/sprint_114_stable_release_health_gate.json';

  static const List<String> requiredEvidence = <String>[
    'health_signals',
    'incident_status',
    'migration_health',
    'recovery_health',
    'security_privacy_status',
    'accessibility_status',
    'support_status',
    'rollout_status',
  ];

  static const List<String> requiredHealthSignals = kReleaseHealthSignals;
  static const List<String> deferredChecks = <String>[
    'live_production_telemetry',
    'hosted_ci_validation',
    'public_release_signing',
    'participant_communication',
    'published_artifact_rollback_drill',
    'hardware_validation',
    'publication',
  ];
  static const Set<String> validHealthSignalStates = <String>{
    'ok',
    'breach',
    'not_observed',
  };
}

class StableReleaseHealthGate {
  StableReleaseHealthGateReport evaluate(
    StableReleaseHealthEvidence? evidence,
  ) {
    if (evidence == null) {
      return _report(
        state: StableReleaseHealthGateState.blocked,
        verdict: 'NO_HEALTH_EVIDENCE',
        missingEvidence: StableReleaseHealthGateContract.requiredEvidence,
        healthSignals: const <String, String>{},
      );
    }

    final missing = <String>[];
    final invalid = <String>[];
    final violations = <String>[];

    if (!evidence.observationWindowComplete) {
      missing.add('observation_window');
    }

    for (final signal
        in StableReleaseHealthGateContract.requiredHealthSignals) {
      final value = evidence.healthSignals[signal];
      if (value == null || value == 'not_observed') {
        missing.add('health_signal_$signal');
      } else if (!StableReleaseHealthGateContract.validHealthSignalStates
          .contains(value)) {
        invalid.add('health_signal_$signal');
      } else if (value == 'breach') {
        violations.add('health_signal_${signal}_breach');
      }
    }

    for (final signal in evidence.healthSignals.keys) {
      if (!StableReleaseHealthGateContract.requiredHealthSignals.contains(
        signal,
      )) {
        invalid.add('health_signal_$signal');
      }
    }

    void checkDimension(String name, StableReleaseDimensionStatus? status) {
      if (status == null) {
        missing.add(name);
      } else if (status != StableReleaseDimensionStatus.stable) {
        violations.add('${name}_not_stable');
      }
    }

    checkDimension('incident_status', evidence.incidentStatus);
    checkDimension('migration_health', evidence.migrationStatus);
    checkDimension('recovery_health', evidence.recoveryStatus);
    checkDimension('security_privacy_status', evidence.securityPrivacyStatus);
    checkDimension('accessibility_status', evidence.accessibilityStatus);
    checkDimension('support_status', evidence.supportStatus);
    checkDimension('rollout_status', evidence.rolloutStatus);

    if (missing.isNotEmpty) {
      return _report(
        state: StableReleaseHealthGateState.blocked,
        verdict: 'OBSERVATION_OR_EVIDENCE_BLOCKED',
        missingEvidence: missing,
        invalidEvidence: invalid,
        violations: violations,
        healthSignals: evidence.healthSignals,
      );
    }
    if (invalid.isNotEmpty || violations.isNotEmpty) {
      return _report(
        state: StableReleaseHealthGateState.fail,
        verdict: 'HEALTH_EVIDENCE_FAILED',
        missingEvidence: missing,
        invalidEvidence: invalid,
        violations: violations,
        healthSignals: evidence.healthSignals,
      );
    }

    return _report(
      state: StableReleaseHealthGateState.pass,
      verdict: 'STABLE_RELEASE',
      missingEvidence: missing,
      invalidEvidence: invalid,
      violations: violations,
      healthSignals: evidence.healthSignals,
    );
  }

  StableReleaseHealthGateReport _report({
    required StableReleaseHealthGateState state,
    required String verdict,
    required List<String> missingEvidence,
    List<String> invalidEvidence = const <String>[],
    List<String> violations = const <String>[],
    required Map<String, String> healthSignals,
  }) {
    return StableReleaseHealthGateReport(
      state: state,
      verdict: verdict,
      missingEvidence: List<String>.unmodifiable(missingEvidence),
      invalidEvidence: List<String>.unmodifiable(invalidEvidence),
      violations: List<String>.unmodifiable(violations),
      healthSignals: UnmodifiableMapView<String, String>(
        Map<String, String>.from(healthSignals),
      ),
      deferredChecks: List<String>.unmodifiable(
        StableReleaseHealthGateContract.deferredChecks,
      ),
    );
  }
}
