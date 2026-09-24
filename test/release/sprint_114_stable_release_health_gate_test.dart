import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/stable_release_health_gate_v114.dart';

void main() {
  group('114.38 Stable Release Health Gate', () {
    final completeEvidence = StableReleaseHealthEvidence(
      observationWindowComplete: true,
      healthSignals: <String, String>{
        for (final signal
            in StableReleaseHealthGateContract.requiredHealthSignals)
          signal: 'ok',
      },
      incidentStatus: StableReleaseDimensionStatus.stable,
      migrationStatus: StableReleaseDimensionStatus.stable,
      recoveryStatus: StableReleaseDimensionStatus.stable,
      securityPrivacyStatus: StableReleaseDimensionStatus.stable,
      accessibilityStatus: StableReleaseDimensionStatus.stable,
      supportStatus: StableReleaseDimensionStatus.stable,
      rolloutStatus: StableReleaseDimensionStatus.stable,
    );

    test('declares the canonical evidence names in contract order', () {
      expect(StableReleaseHealthGateContract.canonicalStep, '114.38');
      expect(StableReleaseHealthGateContract.requiredEvidence, <String>[
        'health_signals',
        'incident_status',
        'migration_health',
        'recovery_health',
        'security_privacy_status',
        'accessibility_status',
        'support_status',
        'rollout_status',
      ]);
      expect(StableReleaseHealthGateContract.requiredHealthSignals, <String>[
        'install_success',
        'upgrade_success',
        'crash_rate',
        'migration_failure',
        'restore_failure',
        'performance_regression',
        'support_severity',
      ]);
    });

    test('absent evidence is blocked without claiming stable release', () {
      final report = StableReleaseHealthGate().evaluate(null);

      expect(report.state, StableReleaseHealthGateState.blocked);
      expect(report.verdict, 'NO_HEALTH_EVIDENCE');
      expect(
        report.missingEvidence,
        StableReleaseHealthGateContract.requiredEvidence,
      );
      expect(report.deferredChecks, contains('live_production_telemetry'));
    });

    test('complete evidence and a closed observation window pass', () {
      final report = StableReleaseHealthGate().evaluate(completeEvidence);

      expect(report.state, StableReleaseHealthGateState.pass);
      expect(report.verdict, 'STABLE_RELEASE');
      expect(report.missingEvidence, isEmpty);
      expect(report.invalidEvidence, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('an open observation window blocks even with healthy dimensions', () {
      final report = StableReleaseHealthGate().evaluate(
        completeEvidence.copyWith(observationWindowComplete: false),
      );

      expect(report.state, StableReleaseHealthGateState.blocked);
      expect(report.verdict, 'OBSERVATION_OR_EVIDENCE_BLOCKED');
      expect(report.missingEvidence, contains('observation_window'));
    });

    test('missing or unobserved health signals block by canonical name', () {
      final evidence = completeEvidence.copyWith(
        healthSignals: <String, String>{
          'install_success': 'ok',
          'upgrade_success': 'not_observed',
        },
      );
      final report = StableReleaseHealthGate().evaluate(evidence);

      expect(report.state, StableReleaseHealthGateState.blocked);
      expect(
        report.missingEvidence,
        containsAll(<String>[
          'health_signal_upgrade_success',
          'health_signal_crash_rate',
          'health_signal_migration_failure',
          'health_signal_restore_failure',
          'health_signal_performance_regression',
          'health_signal_support_severity',
        ]),
      );
    });

    test('breached health and unstable dimensions fail closed', () {
      final evidence = completeEvidence.copyWith(
        healthSignals: <String, String>{
          for (final signal
              in StableReleaseHealthGateContract.requiredHealthSignals)
            signal: signal == 'crash_rate' ? 'breach' : 'ok',
        },
        incidentStatus: StableReleaseDimensionStatus.reduced,
        migrationStatus: StableReleaseDimensionStatus.blocked,
        recoveryStatus: StableReleaseDimensionStatus.rolledBack,
      );
      final report = StableReleaseHealthGate().evaluate(evidence);

      expect(report.state, StableReleaseHealthGateState.fail);
      expect(report.verdict, 'HEALTH_EVIDENCE_FAILED');
      expect(report.violations, contains('health_signal_crash_rate_breach'));
      expect(report.violations, contains('incident_status_not_stable'));
      expect(report.violations, contains('migration_health_not_stable'));
      expect(report.violations, contains('recovery_health_not_stable'));
    });

    test('unknown signal and invalid value fail with named evidence', () {
      final evidence = completeEvidence.copyWith(
        healthSignals: <String, String>{
          for (final signal
              in StableReleaseHealthGateContract.requiredHealthSignals)
            signal: 'ok',
          'unknown_signal': 'healthy',
          'crash_rate': 'healthy',
        },
      );
      final report = StableReleaseHealthGate().evaluate(evidence);

      expect(report.state, StableReleaseHealthGateState.fail);
      expect(report.invalidEvidence, contains('health_signal_unknown_signal'));
      expect(report.invalidEvidence, contains('health_signal_crash_rate'));
    });

    test('missing dimensions block and never silently pass', () {
      final report = StableReleaseHealthGate().evaluate(
        StableReleaseHealthEvidence(
          observationWindowComplete: true,
          healthSignals: <String, String>{
            for (final signal
                in StableReleaseHealthGateContract.requiredHealthSignals)
              signal: 'ok',
          },
        ),
      );

      expect(report.state, StableReleaseHealthGateState.blocked);
      expect(
        report.missingEvidence,
        containsAll(<String>[
          'incident_status',
          'migration_health',
          'recovery_health',
          'security_privacy_status',
          'accessibility_status',
          'support_status',
          'rollout_status',
        ]),
      );
    });

    test('external gates remain deferred even for a local pass', () {
      final report = StableReleaseHealthGate().evaluate(completeEvidence);

      expect(report.deferredChecks, contains('public_release_signing'));
      expect(report.deferredChecks, contains('hosted_ci_validation'));
      expect(report.deferredChecks, contains('live_production_telemetry'));
      expect(report.toJson()['external_checks_status'], 'DEFERRED-EXTERNAL');
    });

    test('manifest records the contract and external boundary', () {
      final file = File(StableReleaseHealthGateContract.manifestPath);
      expect(file.existsSync(), isTrue);
      final manifest =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(manifest['canonical_step'], '114.38');
      expect(
        manifest['required_evidence'],
        StableReleaseHealthGateContract.requiredEvidence,
      );
      expect(
        manifest['required_health_signals'],
        StableReleaseHealthGateContract.requiredHealthSignals,
      );
      expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
      expect(manifest['observation_window'], isA<String>());
      expect(manifest['limitations'], isNotEmpty);
    });
  });
}
