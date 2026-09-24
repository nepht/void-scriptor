import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/backup_restore_health.dart';

void main() {
  group('114.14 Backup & Restore Health', () {
    test('absent observations are blocked without health claims', () {
      final report = BackupRestoreHealth().evaluate(null);

      expect(report.state, BackupRestoreState.blocked);
      expect(report.coveredSignals, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.notes, anyElement(contains('DEFERRED-EXTERNAL')));
    });

    test('incomplete signal coverage fails with signals invalid field', () {
      final report = BackupRestoreHealth().evaluate(<BackupRestoreObservation>[
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.backupSuccess,
          outcome: BackupRestoreOutcome.ok,
          note: 'Scheduled backup completed without error.',
        ),
      ]);

      expect(report.state, BackupRestoreState.fail);
      expect(report.invalidFields, contains('signals'));
      expect(report.coveredSignals, <BackupRestoreSignal>[
        BackupRestoreSignal.backupSuccess,
      ]);
    });

    test('observation without a note is invalid evidence', () {
      final report = BackupRestoreHealth().evaluate(<BackupRestoreObservation>[
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.backupSuccess,
          outcome: BackupRestoreOutcome.ok,
          note: 'Scheduled backup completed without error.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.encryptionSuccess,
          outcome: BackupRestoreOutcome.ok,
          note: 'Backup volume encrypted and key verified.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.restoreSuccess,
          outcome: BackupRestoreOutcome.ok,
          note: 'Restore drill returned a readable workspace.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.mediaIntegrity,
          outcome: BackupRestoreOutcome.ok,
          note: 'Media manifest checksums match after restore.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.linkIntegrity,
          outcome: BackupRestoreOutcome.ok,
          note: 'Cross-workspace links resolve after restore.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.recoveryTime,
          outcome: BackupRestoreOutcome.ok,
          note: '',
        ),
      ]);

      expect(report.state, BackupRestoreState.fail);
      expect(report.invalidFields, contains('notes'));
    });

    test('backup claiming success while encryption failed is ignored', () {
      final report = BackupRestoreHealth().evaluate(<BackupRestoreObservation>[
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.backupSuccess,
          outcome: BackupRestoreOutcome.ok,
          note: 'Scheduled backup completed without error.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.encryptionSuccess,
          outcome: BackupRestoreOutcome.failed,
          note: 'Encryption pass aborted; volume written in clear.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.restoreSuccess,
          outcome: BackupRestoreOutcome.ok,
          note: 'Restore drill returned a readable workspace.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.mediaIntegrity,
          outcome: BackupRestoreOutcome.ok,
          note: 'Media manifest checksums match after restore.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.linkIntegrity,
          outcome: BackupRestoreOutcome.ok,
          note: 'Cross-workspace links resolve after restore.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.recoveryTime,
          outcome: BackupRestoreOutcome.ok,
          note: 'Recovery completed within the target window.',
        ),
      ]);

      expect(report.state, BackupRestoreState.fail);
      expect(report.violations, contains('encryption_failure_ignored'));
    });

    test('failed backup without a working restore is unrecoverable', () {
      final report = BackupRestoreHealth().evaluate(<BackupRestoreObservation>[
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.backupSuccess,
          outcome: BackupRestoreOutcome.failed,
          note: 'Backup aborted mid-write; no usable archive produced.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.encryptionSuccess,
          outcome: BackupRestoreOutcome.ok,
          note: 'Backup volume encrypted and key verified.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.restoreSuccess,
          outcome: BackupRestoreOutcome.failed,
          note: 'Restore drill declined the truncated archive.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.mediaIntegrity,
          outcome: BackupRestoreOutcome.ok,
          note: 'Media manifest checksums match after restore.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.linkIntegrity,
          outcome: BackupRestoreOutcome.ok,
          note: 'Cross-workspace links resolve after restore.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.recoveryTime,
          outcome: BackupRestoreOutcome.failed,
          note: 'Recovery window exceeded the target.',
        ),
      ]);

      expect(report.state, BackupRestoreState.fail);
      expect(report.violations, contains('backup_restore_unrecovered'));
      expect(report.violations, contains('restore_unrecovered'));
    });

    test('media damage without successful restore is unrecovered', () {
      final report = BackupRestoreHealth().evaluate(<BackupRestoreObservation>[
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.backupSuccess,
          outcome: BackupRestoreOutcome.ok,
          note: 'Scheduled backup completed without error.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.encryptionSuccess,
          outcome: BackupRestoreOutcome.ok,
          note: 'Backup volume encrypted and key verified.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.restoreSuccess,
          outcome: BackupRestoreOutcome.failed,
          note: 'Restore drill declined the truncated archive.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.mediaIntegrity,
          outcome: BackupRestoreOutcome.failed,
          note: 'Media manifest lists files the archive cannot supply.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.linkIntegrity,
          outcome: BackupRestoreOutcome.ok,
          note: 'Cross-workspace links resolve after restore.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.recoveryTime,
          outcome: BackupRestoreOutcome.failed,
          note: 'Recovery window exceeded the target.',
        ),
      ]);

      expect(report.state, BackupRestoreState.fail);
      expect(report.violations, contains('media_unrecovered'));
      expect(report.violations, contains('restore_unrecovered'));
    });

    test('broken links without successful restore are unrepaired', () {
      final report = BackupRestoreHealth().evaluate(<BackupRestoreObservation>[
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.backupSuccess,
          outcome: BackupRestoreOutcome.ok,
          note: 'Scheduled backup completed without error.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.encryptionSuccess,
          outcome: BackupRestoreOutcome.ok,
          note: 'Backup volume encrypted and key verified.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.restoreSuccess,
          outcome: BackupRestoreOutcome.failed,
          note: 'Restore drill declined the truncated archive.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.mediaIntegrity,
          outcome: BackupRestoreOutcome.ok,
          note: 'Media manifest checksums match after restore.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.linkIntegrity,
          outcome: BackupRestoreOutcome.failed,
          note: 'Scene-to-character links dangle after restore.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.recoveryTime,
          outcome: BackupRestoreOutcome.failed,
          note: 'Recovery window exceeded the target.',
        ),
      ]);

      expect(report.state, BackupRestoreState.fail);
      expect(report.violations, contains('links_unrepaired'));
      expect(report.violations, contains('restore_unrecovered'));
    });

    test('recovery time claimed while restore failed is unsubstantiated', () {
      final report = BackupRestoreHealth().evaluate(<BackupRestoreObservation>[
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.backupSuccess,
          outcome: BackupRestoreOutcome.ok,
          note: 'Scheduled backup completed without error.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.encryptionSuccess,
          outcome: BackupRestoreOutcome.ok,
          note: 'Backup volume encrypted and key verified.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.restoreSuccess,
          outcome: BackupRestoreOutcome.failed,
          note: 'Restore drill declined the truncated archive.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.mediaIntegrity,
          outcome: BackupRestoreOutcome.ok,
          note: 'Media manifest checksums match after restore.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.linkIntegrity,
          outcome: BackupRestoreOutcome.ok,
          note: 'Cross-workspace links resolve after restore.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.recoveryTime,
          outcome: BackupRestoreOutcome.ok,
          note: 'Recovery completed within the target window.',
        ),
      ]);

      expect(report.state, BackupRestoreState.fail);
      expect(report.violations, contains('recovery_claim_without_restore'));
    });

    test('detected failures with honest restore recovery pass', () {
      final report = BackupRestoreHealth().evaluate(<BackupRestoreObservation>[
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.backupSuccess,
          outcome: BackupRestoreOutcome.failed,
          note: 'Backup aborted mid-write; no usable archive produced.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.encryptionSuccess,
          outcome: BackupRestoreOutcome.failed,
          note: 'Encryption pass aborted; volume written in clear.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.restoreSuccess,
          outcome: BackupRestoreOutcome.recovered,
          note: 'Restore retried from the previous archive and succeeded.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.mediaIntegrity,
          outcome: BackupRestoreOutcome.failed,
          note: 'Media manifest lists files the archive cannot supply.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.linkIntegrity,
          outcome: BackupRestoreOutcome.failed,
          note: 'Scene-to-character links dangle after restore.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.recoveryTime,
          outcome: BackupRestoreOutcome.ok,
          note: 'Recovery completed within the target window.',
        ),
      ]);

      expect(report.state, BackupRestoreState.pass);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('fully covered consistent record verifies all six signals', () {
      final report = BackupRestoreHealth().evaluate(<BackupRestoreObservation>[
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.backupSuccess,
          outcome: BackupRestoreOutcome.ok,
          note: 'Scheduled backup completed without error.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.encryptionSuccess,
          outcome: BackupRestoreOutcome.ok,
          note: 'Backup volume encrypted and key verified.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.restoreSuccess,
          outcome: BackupRestoreOutcome.ok,
          note: 'Restore drill returned a readable workspace.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.mediaIntegrity,
          outcome: BackupRestoreOutcome.ok,
          note: 'Media manifest checksums match after restore.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.linkIntegrity,
          outcome: BackupRestoreOutcome.ok,
          note: 'Cross-workspace links resolve after restore.',
        ),
        const BackupRestoreObservation(
          signal: BackupRestoreSignal.recoveryTime,
          outcome: BackupRestoreOutcome.ok,
          note: 'Recovery completed within the target window.',
        ),
      ]);

      expect(report.state, BackupRestoreState.pass);
      expect(report.coveredSignals, <BackupRestoreSignal>[
        BackupRestoreSignal.backupSuccess,
        BackupRestoreSignal.encryptionSuccess,
        BackupRestoreSignal.restoreSuccess,
        BackupRestoreSignal.mediaIntegrity,
        BackupRestoreSignal.linkIntegrity,
        BackupRestoreSignal.recoveryTime,
      ]);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('manifest declares canonical evidence and external deferral', () {
      final file = File(
        'docs/planning/v1.2/sprint_114_backup_restore_health.json',
      );
      expect(file.existsSync(), isTrue);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document['canonical_step'], '114.14');
      expect(document['required_evidence'], <dynamic>[
        'backup_success',
        'encryption_success',
        'restore_success',
        'media_integrity',
        'link_integrity',
        'recovery_time',
      ]);
      expect(document['live_backup_telemetry'], 'DEFERRED-EXTERNAL');
      expect(document['external_backup_gates'], 'DEFERRED-EXTERNAL');
    });
  });
}
