import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/crash_startup_health.dart';

void main() {
  group('114.11 Crash & Startup Health', () {
    test('absent observations are blocked without health claims', () {
      final report = CrashStartupHealth().evaluate(null);

      expect(report.state, CrashStartupHealthState.blocked);
      expect(report.coveredSignals, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.notes, anyElement(contains('DEFERRED-EXTERNAL')));
    });

    test('incomplete signal coverage fails with signals invalid field', () {
      final report = CrashStartupHealth().evaluate(<CrashStartupObservation>[
        const CrashStartupObservation(
          signal: CrashStartupSignal.startupFailure,
          outcome: CrashStartupOutcome.ok,
          note: 'Cold start reached shell in 2.1s.',
        ),
      ]);

      expect(report.state, CrashStartupHealthState.fail);
      expect(report.invalidFields, contains('signals'));
      expect(report.coveredSignals, <CrashStartupSignal>[
        CrashStartupSignal.startupFailure,
      ]);
    });

    test('observation without a note is invalid evidence', () {
      final report = CrashStartupHealth().evaluate(<CrashStartupObservation>[
        const CrashStartupObservation(
          signal: CrashStartupSignal.crashRate,
          outcome: CrashStartupOutcome.ok,
          note: '0 crashes per 1000 launches.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.startupFailure,
          outcome: CrashStartupOutcome.ok,
          note: 'Cold start reached shell in 2.1s.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.projectOpenFailure,
          outcome: CrashStartupOutcome.ok,
          note: 'Fixture project opened without error.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.crashLoop,
          outcome: CrashStartupOutcome.ok,
          note: '',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.recoverySuccess,
          outcome: CrashStartupOutcome.ok,
          note: 'No recovery required.',
        ),
      ]);

      expect(report.state, CrashStartupHealthState.fail);
      expect(report.invalidFields, contains('notes'));
    });

    test('healthy crash rate cannot ignore an observed crash loop', () {
      final report = CrashStartupHealth().evaluate(<CrashStartupObservation>[
        const CrashStartupObservation(
          signal: CrashStartupSignal.crashRate,
          outcome: CrashStartupOutcome.ok,
          note: 'Aggregate rate within budget.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.startupFailure,
          outcome: CrashStartupOutcome.ok,
          note: 'Cold start reached shell in 2.1s.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.projectOpenFailure,
          outcome: CrashStartupOutcome.ok,
          note: 'Fixture project opened without error.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.crashLoop,
          outcome: CrashStartupOutcome.failed,
          note: 'Three restarts in a row before shell.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.recoverySuccess,
          outcome: CrashStartupOutcome.recovered,
          note: 'Safe mode break stopped the loop.',
        ),
      ]);

      expect(report.state, CrashStartupHealthState.fail);
      expect(report.violations, contains('crash_loop_ignored'));
    });

    test('startup failure with failed recovery is unrecovered', () {
      final report = CrashStartupHealth().evaluate(<CrashStartupObservation>[
        const CrashStartupObservation(
          signal: CrashStartupSignal.crashRate,
          outcome: CrashStartupOutcome.failed,
          note: 'Crash on every launch in window.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.startupFailure,
          outcome: CrashStartupOutcome.failed,
          note: 'Shell never reached on 5 consecutive launches.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.projectOpenFailure,
          outcome: CrashStartupOutcome.ok,
          note: 'Not reached; startup fails earlier.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.crashLoop,
          outcome: CrashStartupOutcome.ok,
          note: 'Single failure mode, no repeated restarts.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.recoverySuccess,
          outcome: CrashStartupOutcome.failed,
          note: 'Recovery prompt reappeared and failed again.',
        ),
      ]);

      expect(report.state, CrashStartupHealthState.fail);
      expect(report.violations, contains('startup_unrecovered'));
    });

    test('project-open failure with failed recovery is unrecovered', () {
      final report = CrashStartupHealth().evaluate(<CrashStartupObservation>[
        const CrashStartupObservation(
          signal: CrashStartupSignal.crashRate,
          outcome: CrashStartupOutcome.failed,
          note: 'Crash during project open in window.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.startupFailure,
          outcome: CrashStartupOutcome.ok,
          note: 'Cold start reached shell in 2.1s.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.projectOpenFailure,
          outcome: CrashStartupOutcome.failed,
          note: 'Fixture project fails at registry repoint.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.crashLoop,
          outcome: CrashStartupOutcome.ok,
          note: 'No repeated restart observed.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.recoverySuccess,
          outcome: CrashStartupOutcome.failed,
          note: 'Restore-from-backup attempt failed twice.',
        ),
      ]);

      expect(report.state, CrashStartupHealthState.fail);
      expect(report.violations, contains('project_open_unrecovered'));
    });

    test('crash loop with failed recovery is unrecovered', () {
      final report = CrashStartupHealth().evaluate(<CrashStartupObservation>[
        const CrashStartupObservation(
          signal: CrashStartupSignal.crashRate,
          outcome: CrashStartupOutcome.failed,
          note: 'Loop drives rate above budget.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.startupFailure,
          outcome: CrashStartupOutcome.failed,
          note: 'Shell never reached while looping.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.projectOpenFailure,
          outcome: CrashStartupOutcome.ok,
          note: 'Not reached; startup fails earlier.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.crashLoop,
          outcome: CrashStartupOutcome.failed,
          note: 'Three restarts in a row before shell.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.recoverySuccess,
          outcome: CrashStartupOutcome.failed,
          note: 'Safe mode offer crashed as well.',
        ),
      ]);

      expect(report.state, CrashStartupHealthState.fail);
      expect(
        report.violations,
        containsAll(<String>['crash_loop_unrecovered', 'startup_unrecovered']),
      );
    });

    test('startup failure with successful recovery recovers honestly', () {
      final report = CrashStartupHealth().evaluate(<CrashStartupObservation>[
        const CrashStartupObservation(
          signal: CrashStartupSignal.crashRate,
          outcome: CrashStartupOutcome.failed,
          note: 'Two crashes before recovery in window.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.startupFailure,
          outcome: CrashStartupOutcome.failed,
          note: 'First two launches failed at plugin load.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.projectOpenFailure,
          outcome: CrashStartupOutcome.ok,
          note: 'Fixture project opened after recovery.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.crashLoop,
          outcome: CrashStartupOutcome.ok,
          note: 'No repeated restart observed.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.recoverySuccess,
          outcome: CrashStartupOutcome.recovered,
          note: 'Third launch started with degraded plugins.',
        ),
      ]);

      expect(report.state, CrashStartupHealthState.pass);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('fully covered consistent record verifies all five signals', () {
      final report = CrashStartupHealth().evaluate(<CrashStartupObservation>[
        const CrashStartupObservation(
          signal: CrashStartupSignal.crashRate,
          outcome: CrashStartupOutcome.ok,
          note: '0 crashes per 1000 launches.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.startupFailure,
          outcome: CrashStartupOutcome.ok,
          note: 'Cold start reached shell in 2.1s.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.projectOpenFailure,
          outcome: CrashStartupOutcome.ok,
          note: 'Fixture project opened without error.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.crashLoop,
          outcome: CrashStartupOutcome.ok,
          note: 'No repeated restart observed.',
        ),
        const CrashStartupObservation(
          signal: CrashStartupSignal.recoverySuccess,
          outcome: CrashStartupOutcome.ok,
          note: 'No recovery required.',
        ),
      ]);

      expect(report.state, CrashStartupHealthState.pass);
      expect(report.coveredSignals, <CrashStartupSignal>[
        CrashStartupSignal.crashRate,
        CrashStartupSignal.startupFailure,
        CrashStartupSignal.projectOpenFailure,
        CrashStartupSignal.crashLoop,
        CrashStartupSignal.recoverySuccess,
      ]);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('manifest declares canonical evidence and external deferral', () {
      final file = File(
        'docs/planning/v1.2/sprint_114_crash_startup_health.json',
      );
      expect(file.existsSync(), isTrue);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document['canonical_step'], '114.11');
      expect(document['required_evidence'], <dynamic>[
        'crash_rate',
        'startup_failure',
        'project_open_failure',
        'crash_loop',
        'recovery_success',
      ]);
      expect(document['live_crash_telemetry'], 'DEFERRED-EXTERNAL');
      expect(document['external_startup_gates'], 'DEFERRED-EXTERNAL');
    });
  });
}
