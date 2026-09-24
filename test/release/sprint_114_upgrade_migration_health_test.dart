import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/upgrade_migration_health.dart';

void main() {
  group('114.10 Upgrade & Migration Health', () {
    test('absent observations are blocked without health claims', () {
      final report = UpgradeMigrationHealth().evaluate(null);

      expect(report.state, UpgradeMigrationHealthState.blocked);
      expect(report.coveredSignals, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.notes, anyElement(contains('DEFERRED-EXTERNAL')));
    });

    test('incomplete signal coverage fails with signals invalid field', () {
      final report = UpgradeMigrationHealth()
          .evaluate(<UpgradeMigrationObservation>[
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.migrationSuccess,
              outcome: UpgradeMigrationOutcome.ok,
              note: 'Migration from 1.1.3 completed.',
            ),
          ]);

      expect(report.state, UpgradeMigrationHealthState.fail);
      expect(report.invalidFields, contains('signals'));
      expect(report.coveredSignals, <UpgradeMigrationSignal>[
        UpgradeMigrationSignal.migrationSuccess,
      ]);
    });

    test('observation without a note is invalid evidence', () {
      final report = UpgradeMigrationHealth()
          .evaluate(<UpgradeMigrationObservation>[
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.migrationSuccess,
              outcome: UpgradeMigrationOutcome.ok,
              note: 'Migration from 1.1.3 completed.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.migrationDuration,
              outcome: UpgradeMigrationOutcome.ok,
              note: '4.2s within 30s budget.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.warnings,
              outcome: UpgradeMigrationOutcome.failed,
              note: '',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.repairRequired,
              outcome: UpgradeMigrationOutcome.ok,
              note: 'No repair required.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.rollbackResult,
              outcome: UpgradeMigrationOutcome.ok,
              note: 'Rollback not required.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.integrityResult,
              outcome: UpgradeMigrationOutcome.ok,
              note: 'Row counts and checksums match.',
            ),
          ]);

      expect(report.state, UpgradeMigrationHealthState.fail);
      expect(report.invalidFields, contains('notes'));
    });

    test('migration success ignores failed integrity or pending repair', () {
      final report = UpgradeMigrationHealth()
          .evaluate(<UpgradeMigrationObservation>[
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.migrationSuccess,
              outcome: UpgradeMigrationOutcome.ok,
              note: 'Migration from 1.1.3 completed.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.migrationDuration,
              outcome: UpgradeMigrationOutcome.ok,
              note: '4.2s within 30s budget.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.warnings,
              outcome: UpgradeMigrationOutcome.failed,
              note: 'Two deprecated column warnings surfaced.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.repairRequired,
              outcome: UpgradeMigrationOutcome.failed,
              note: 'Repair pass needed but not run.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.rollbackResult,
              outcome: UpgradeMigrationOutcome.ok,
              note: 'Rollback not required.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.integrityResult,
              outcome: UpgradeMigrationOutcome.failed,
              note: 'Checksum mismatch on lore table.',
            ),
          ]);

      expect(report.state, UpgradeMigrationHealthState.fail);
      expect(
        report.violations,
        containsAll(<String>[
          'integrity_failure_ignored',
          'repair_required_ignored',
        ]),
      );
    });

    test('failed migration with failed rollback is unrecovered', () {
      final report = UpgradeMigrationHealth()
          .evaluate(<UpgradeMigrationObservation>[
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.migrationSuccess,
              outcome: UpgradeMigrationOutcome.failed,
              note: 'Migration aborted on schema step 7.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.migrationDuration,
              outcome: UpgradeMigrationOutcome.failed,
              note: 'Exceeded 30s budget before abort.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.warnings,
              outcome: UpgradeMigrationOutcome.ok,
              note: 'No warnings before abort.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.repairRequired,
              outcome: UpgradeMigrationOutcome.ok,
              note: 'No repair required after rollback attempt.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.rollbackResult,
              outcome: UpgradeMigrationOutcome.failed,
              note: 'Rollback snapshot missing.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.integrityResult,
              outcome: UpgradeMigrationOutcome.failed,
              note: 'Cannot compare; database left partial.',
            ),
          ]);

      expect(report.state, UpgradeMigrationHealthState.fail);
      expect(report.violations, contains('migration_unrecovered'));
    });

    test('failed migration with successful rollback recovers honestly', () {
      final report = UpgradeMigrationHealth()
          .evaluate(<UpgradeMigrationObservation>[
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.migrationSuccess,
              outcome: UpgradeMigrationOutcome.failed,
              note: 'Migration aborted on schema step 7.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.migrationDuration,
              outcome: UpgradeMigrationOutcome.failed,
              note: 'Exceeded 30s budget before abort.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.warnings,
              outcome: UpgradeMigrationOutcome.ok,
              note: 'No warnings before abort.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.repairRequired,
              outcome: UpgradeMigrationOutcome.ok,
              note: 'No repair required after rollback.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.rollbackResult,
              outcome: UpgradeMigrationOutcome.recovered,
              note: 'Snapshot restore returned pre-upgrade state.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.integrityResult,
              outcome: UpgradeMigrationOutcome.ok,
              note: 'Row counts and checksums match pre-upgrade baseline.',
            ),
          ]);

      expect(report.state, UpgradeMigrationHealthState.pass);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('fully covered consistent record verifies all six signals', () {
      final report = UpgradeMigrationHealth()
          .evaluate(<UpgradeMigrationObservation>[
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.migrationSuccess,
              outcome: UpgradeMigrationOutcome.ok,
              note: 'Migration from 1.1.3 completed.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.migrationDuration,
              outcome: UpgradeMigrationOutcome.ok,
              note: '4.2s within 30s budget.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.warnings,
              outcome: UpgradeMigrationOutcome.ok,
              note: 'No migration warnings.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.repairRequired,
              outcome: UpgradeMigrationOutcome.ok,
              note: 'No repair required.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.rollbackResult,
              outcome: UpgradeMigrationOutcome.ok,
              note: 'Rollback not required.',
            ),
            const UpgradeMigrationObservation(
              signal: UpgradeMigrationSignal.integrityResult,
              outcome: UpgradeMigrationOutcome.ok,
              note: 'Row counts and checksums match.',
            ),
          ]);

      expect(report.state, UpgradeMigrationHealthState.pass);
      expect(report.coveredSignals, <UpgradeMigrationSignal>[
        UpgradeMigrationSignal.migrationSuccess,
        UpgradeMigrationSignal.migrationDuration,
        UpgradeMigrationSignal.warnings,
        UpgradeMigrationSignal.repairRequired,
        UpgradeMigrationSignal.rollbackResult,
        UpgradeMigrationSignal.integrityResult,
      ]);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('manifest declares canonical evidence and external deferral', () {
      final file = File(
        'docs/planning/v1.2/sprint_114_upgrade_migration_health.json',
      );
      expect(file.existsSync(), isTrue);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document['canonical_step'], '114.10');
      expect(document['required_evidence'], <dynamic>[
        'migration_success',
        'migration_duration',
        'warnings',
        'repair_required',
        'rollback_result',
        'integrity_result',
      ]);
      expect(document['live_migration_telemetry'], 'DEFERRED-EXTERNAL');
      expect(document['external_upgrade_gates'], 'DEFERRED-EXTERNAL');
    });
  });
}
