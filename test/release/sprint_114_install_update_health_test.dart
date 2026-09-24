import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/install_update_health.dart';

void main() {
  group('114.9 Install & Update Health', () {
    test('absent observations are blocked without health claims', () {
      final report = InstallUpdateHealth().evaluate(null);

      expect(report.state, InstallUpdateHealthState.blocked);
      expect(report.coveredSignals, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.notes, anyElement(contains('DEFERRED-EXTERNAL')));
    });

    test('incomplete signal coverage fails with signals invalid field', () {
      final report = InstallUpdateHealth().evaluate(<InstallUpdateObservation>[
        const InstallUpdateObservation(
          signal: InstallUpdateSignal.installSuccess,
          outcome: InstallUpdateOutcome.ok,
          note: 'Fresh install completed from local artifact.',
        ),
      ]);

      expect(report.state, InstallUpdateHealthState.fail);
      expect(report.invalidFields, contains('signals'));
      expect(report.coveredSignals, <InstallUpdateSignal>[
        InstallUpdateSignal.installSuccess,
      ]);
    });

    test('failed signal without a note is invalid evidence', () {
      final report = InstallUpdateHealth().evaluate(<InstallUpdateObservation>[
        const InstallUpdateObservation(
          signal: InstallUpdateSignal.installSuccess,
          outcome: InstallUpdateOutcome.ok,
          note: 'Fresh install completed from local artifact.',
        ),
        const InstallUpdateObservation(
          signal: InstallUpdateSignal.downloadFailure,
          outcome: InstallUpdateOutcome.failed,
          note: '',
        ),
        const InstallUpdateObservation(
          signal: InstallUpdateSignal.signatureFailure,
          outcome: InstallUpdateOutcome.ok,
          note: 'Signature verified.',
        ),
        const InstallUpdateObservation(
          signal: InstallUpdateSignal.insufficientSpace,
          outcome: InstallUpdateOutcome.ok,
          note: 'Space check passed.',
        ),
        const InstallUpdateObservation(
          signal: InstallUpdateSignal.retrySuccess,
          outcome: InstallUpdateOutcome.ok,
          note: 'Retry not required.',
        ),
        const InstallUpdateObservation(
          signal: InstallUpdateSignal.updateCompletion,
          outcome: InstallUpdateOutcome.ok,
          note: 'Update completed.',
        ),
      ]);

      expect(report.state, InstallUpdateHealthState.fail);
      expect(report.invalidFields, contains('notes'));
    });

    test('signature or space failure ignored by completed update fails', () {
      final report = InstallUpdateHealth().evaluate(<InstallUpdateObservation>[
        const InstallUpdateObservation(
          signal: InstallUpdateSignal.installSuccess,
          outcome: InstallUpdateOutcome.ok,
          note: 'Fresh install completed from local artifact.',
        ),
        const InstallUpdateObservation(
          signal: InstallUpdateSignal.downloadFailure,
          outcome: InstallUpdateOutcome.recovered,
          note: 'First attempt failed, resumed download succeeded.',
        ),
        const InstallUpdateObservation(
          signal: InstallUpdateSignal.signatureFailure,
          outcome: InstallUpdateOutcome.failed,
          note: 'Signature mismatch against pinned certificate.',
        ),
        const InstallUpdateObservation(
          signal: InstallUpdateSignal.insufficientSpace,
          outcome: InstallUpdateOutcome.failed,
          note: 'Space below required bytes before unpack.',
        ),
        const InstallUpdateObservation(
          signal: InstallUpdateSignal.retrySuccess,
          outcome: InstallUpdateOutcome.ok,
          note: 'Retry completed after resume.',
        ),
        const InstallUpdateObservation(
          signal: InstallUpdateSignal.updateCompletion,
          outcome: InstallUpdateOutcome.ok,
          note: 'Update marked complete.',
        ),
      ]);

      expect(report.state, InstallUpdateHealthState.fail);
      expect(
        report.violations,
        containsAll(<String>[
          'signature_failure_ignored',
          'space_check_ignored',
        ]),
      );
    });

    test('fully covered consistent record verifies all six signals', () {
      final report = InstallUpdateHealth().evaluate(<InstallUpdateObservation>[
        const InstallUpdateObservation(
          signal: InstallUpdateSignal.installSuccess,
          outcome: InstallUpdateOutcome.ok,
          note: 'Fresh install completed from local artifact.',
        ),
        const InstallUpdateObservation(
          signal: InstallUpdateSignal.downloadFailure,
          outcome: InstallUpdateOutcome.failed,
          note: 'Interrupted download reported and surfaced.',
        ),
        const InstallUpdateObservation(
          signal: InstallUpdateSignal.signatureFailure,
          outcome: InstallUpdateOutcome.ok,
          note: 'Signature verified against local certificate.',
        ),
        const InstallUpdateObservation(
          signal: InstallUpdateSignal.insufficientSpace,
          outcome: InstallUpdateOutcome.ok,
          note: 'Free space above required bytes.',
        ),
        const InstallUpdateObservation(
          signal: InstallUpdateSignal.retrySuccess,
          outcome: InstallUpdateOutcome.ok,
          note: 'Retry succeeded after failure surfaced.',
        ),
        const InstallUpdateObservation(
          signal: InstallUpdateSignal.updateCompletion,
          outcome: InstallUpdateOutcome.failed,
          note: 'Update not completed after failed download.',
        ),
      ]);

      expect(report.state, InstallUpdateHealthState.pass);
      expect(report.coveredSignals, <InstallUpdateSignal>[
        InstallUpdateSignal.installSuccess,
        InstallUpdateSignal.downloadFailure,
        InstallUpdateSignal.signatureFailure,
        InstallUpdateSignal.insufficientSpace,
        InstallUpdateSignal.retrySuccess,
        InstallUpdateSignal.updateCompletion,
      ]);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('manifest declares canonical evidence and external deferral', () {
      final file = File(
        'docs/planning/v1.2/sprint_114_install_update_health.json',
      );
      expect(file.existsSync(), isTrue);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document['canonical_step'], '114.9');
      expect(document['required_evidence'], <dynamic>[
        'install_success',
        'download_failure',
        'signature_failure',
        'insufficient_space',
        'retry_success',
        'update_completion',
      ]);
      expect(document['live_install_telemetry'], 'DEFERRED-EXTERNAL');
      expect(document['external_distribution_gates'], 'DEFERRED-EXTERNAL');
    });
  });
}
