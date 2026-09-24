import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/data_integrity_health.dart';

void main() {
  group('114.12 Data Integrity Health', () {
    test('absent observations are blocked without health claims', () {
      final report = DataIntegrityHealth().evaluate(null);

      expect(report.state, DataIntegrityHealthState.blocked);
      expect(report.coveredSignals, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.notes, anyElement(contains('DEFERRED-EXTERNAL')));
    });

    test('incomplete signal coverage fails with signals invalid field', () {
      final report = DataIntegrityHealth().evaluate(<DataIntegrityObservation>[
        const DataIntegrityObservation(
          signal: DataIntegritySignal.brokenLinks,
          outcome: DataIntegrityOutcome.ok,
          note: 'Link scan resolved every reference.',
        ),
      ]);

      expect(report.state, DataIntegrityHealthState.fail);
      expect(report.invalidFields, contains('signals'));
      expect(report.coveredSignals, <DataIntegritySignal>[
        DataIntegritySignal.brokenLinks,
      ]);
    });

    test('observation without a note is invalid evidence', () {
      final report = DataIntegrityHealth().evaluate(<DataIntegrityObservation>[
        const DataIntegrityObservation(
          signal: DataIntegritySignal.brokenLinks,
          outcome: DataIntegrityOutcome.ok,
          note: 'Link scan resolved every reference.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.orphanRecords,
          outcome: DataIntegrityOutcome.ok,
          note: 'No orphan records after sweep.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.indexMismatch,
          outcome: DataIntegrityOutcome.ok,
          note: 'Search index matches store counts.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.checksumFailure,
          outcome: DataIntegrityOutcome.ok,
          note: 'All manifest checksums match.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.silentLossReport,
          outcome: DataIntegrityOutcome.ok,
          note: '',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.repairSuccess,
          outcome: DataIntegrityOutcome.ok,
          note: 'No repair required.',
        ),
      ]);

      expect(report.state, DataIntegrityHealthState.fail);
      expect(report.invalidFields, contains('notes'));
    });

    test('broken links without successful repair are unrepaired', () {
      final report = DataIntegrityHealth().evaluate(<DataIntegrityObservation>[
        const DataIntegrityObservation(
          signal: DataIntegritySignal.brokenLinks,
          outcome: DataIntegrityOutcome.failed,
          note: 'Two scene->character links dangle after import.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.orphanRecords,
          outcome: DataIntegrityOutcome.ok,
          note: 'No orphan records after sweep.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.indexMismatch,
          outcome: DataIntegrityOutcome.ok,
          note: 'Search index matches store counts.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.checksumFailure,
          outcome: DataIntegrityOutcome.ok,
          note: 'All manifest checksums match.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.silentLossReport,
          outcome: DataIntegrityOutcome.ok,
          note: 'Dangling links reported, not silent.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.repairSuccess,
          outcome: DataIntegrityOutcome.failed,
          note: 'Repair pass aborted on locked file.',
        ),
      ]);

      expect(report.state, DataIntegrityHealthState.fail);
      expect(report.violations, contains('broken_links_unrepaired'));
    });

    test('orphan records without successful repair are unrepaired', () {
      final report = DataIntegrityHealth().evaluate(<DataIntegrityObservation>[
        const DataIntegrityObservation(
          signal: DataIntegritySignal.brokenLinks,
          outcome: DataIntegrityOutcome.ok,
          note: 'Link scan resolved every reference.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.orphanRecords,
          outcome: DataIntegrityOutcome.failed,
          note: 'Three characters without owning project.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.indexMismatch,
          outcome: DataIntegrityOutcome.ok,
          note: 'Search index matches store counts.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.checksumFailure,
          outcome: DataIntegrityOutcome.ok,
          note: 'All manifest checksums match.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.silentLossReport,
          outcome: DataIntegrityOutcome.ok,
          note: 'Orphans enumerated in report.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.repairSuccess,
          outcome: DataIntegrityOutcome.failed,
          note: 'Repair transaction rolled back.',
        ),
      ]);

      expect(report.state, DataIntegrityHealthState.fail);
      expect(report.violations, contains('orphan_records_unrepaired'));
    });

    test('index mismatch without successful repair is unrepaired', () {
      final report = DataIntegrityHealth().evaluate(<DataIntegrityObservation>[
        const DataIntegrityObservation(
          signal: DataIntegritySignal.brokenLinks,
          outcome: DataIntegrityOutcome.ok,
          note: 'Link scan resolved every reference.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.orphanRecords,
          outcome: DataIntegrityOutcome.ok,
          note: 'No orphan records after sweep.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.indexMismatch,
          outcome: DataIntegrityOutcome.failed,
          note: 'Search index off by 14 documents.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.checksumFailure,
          outcome: DataIntegrityOutcome.ok,
          note: 'All manifest checksums match.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.silentLossReport,
          outcome: DataIntegrityOutcome.ok,
          note: 'Index drift surfaced in report.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.repairSuccess,
          outcome: DataIntegrityOutcome.failed,
          note: 'Reindex failed on corrupt segment.',
        ),
      ]);

      expect(report.state, DataIntegrityHealthState.fail);
      expect(report.violations, contains('index_mismatch_unrepaired'));
    });

    test('checksum failure without successful repair is unrepaired', () {
      final report = DataIntegrityHealth().evaluate(<DataIntegrityObservation>[
        const DataIntegrityObservation(
          signal: DataIntegritySignal.brokenLinks,
          outcome: DataIntegrityOutcome.ok,
          note: 'Link scan resolved every reference.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.orphanRecords,
          outcome: DataIntegrityOutcome.ok,
          note: 'No orphan records after sweep.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.indexMismatch,
          outcome: DataIntegrityOutcome.ok,
          note: 'Search index matches store counts.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.checksumFailure,
          outcome: DataIntegrityOutcome.failed,
          note: 'Scene file hash mismatch vs manifest.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.silentLossReport,
          outcome: DataIntegrityOutcome.ok,
          note: 'Mismatch surfaced in report.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.repairSuccess,
          outcome: DataIntegrityOutcome.failed,
          note: 'Restore from backup declined twice.',
        ),
      ]);

      expect(report.state, DataIntegrityHealthState.fail);
      expect(report.violations, contains('checksum_unrepaired'));
    });

    test('silent loss without successful repair is unrepaired', () {
      final report = DataIntegrityHealth().evaluate(<DataIntegrityObservation>[
        const DataIntegrityObservation(
          signal: DataIntegritySignal.brokenLinks,
          outcome: DataIntegrityOutcome.ok,
          note: 'Link scan resolved every reference.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.orphanRecords,
          outcome: DataIntegrityOutcome.ok,
          note: 'No orphan records after sweep.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.indexMismatch,
          outcome: DataIntegrityOutcome.ok,
          note: 'Search index matches store counts.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.checksumFailure,
          outcome: DataIntegrityOutcome.ok,
          note: 'All manifest checksums match.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.silentLossReport,
          outcome: DataIntegrityOutcome.failed,
          note: 'Autosave loss detected without any failure record.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.repairSuccess,
          outcome: DataIntegrityOutcome.failed,
          note: 'Snapshot replay rejected the journal.',
        ),
      ]);

      expect(report.state, DataIntegrityHealthState.fail);
      expect(report.violations, contains('silent_loss_unrepaired'));
    });

    test('detected failures with honest repair recovers consistently', () {
      final report = DataIntegrityHealth().evaluate(<DataIntegrityObservation>[
        const DataIntegrityObservation(
          signal: DataIntegritySignal.brokenLinks,
          outcome: DataIntegrityOutcome.failed,
          note: 'Two scene->character links dangle after import.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.orphanRecords,
          outcome: DataIntegrityOutcome.failed,
          note: 'Three characters without owning project.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.indexMismatch,
          outcome: DataIntegrityOutcome.ok,
          note: 'Search index matches store counts.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.checksumFailure,
          outcome: DataIntegrityOutcome.failed,
          note: 'Scene file hash mismatch vs manifest.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.silentLossReport,
          outcome: DataIntegrityOutcome.ok,
          note: 'Every failure surfaced in reports.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.repairSuccess,
          outcome: DataIntegrityOutcome.recovered,
          note:
              'Repair pass restored links, rehomed orphans, '
              'and rebuilt the mismatched checksum.',
        ),
      ]);

      expect(report.state, DataIntegrityHealthState.pass);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('fully covered consistent record verifies all six signals', () {
      final report = DataIntegrityHealth().evaluate(<DataIntegrityObservation>[
        const DataIntegrityObservation(
          signal: DataIntegritySignal.brokenLinks,
          outcome: DataIntegrityOutcome.ok,
          note: 'Link scan resolved every reference.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.orphanRecords,
          outcome: DataIntegrityOutcome.ok,
          note: 'No orphan records after sweep.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.indexMismatch,
          outcome: DataIntegrityOutcome.ok,
          note: 'Search index matches store counts.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.checksumFailure,
          outcome: DataIntegrityOutcome.ok,
          note: 'All manifest checksums match.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.silentLossReport,
          outcome: DataIntegrityOutcome.ok,
          note: 'No silent loss detected in window.',
        ),
        const DataIntegrityObservation(
          signal: DataIntegritySignal.repairSuccess,
          outcome: DataIntegrityOutcome.ok,
          note: 'No repair required.',
        ),
      ]);

      expect(report.state, DataIntegrityHealthState.pass);
      expect(report.coveredSignals, <DataIntegritySignal>[
        DataIntegritySignal.brokenLinks,
        DataIntegritySignal.orphanRecords,
        DataIntegritySignal.indexMismatch,
        DataIntegritySignal.checksumFailure,
        DataIntegritySignal.silentLossReport,
        DataIntegritySignal.repairSuccess,
      ]);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('manifest declares canonical evidence and external deferral', () {
      final file = File(
        'docs/planning/v1.2/sprint_114_data_integrity_health.json',
      );
      expect(file.existsSync(), isTrue);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document['canonical_step'], '114.12');
      expect(document['required_evidence'], <dynamic>[
        'broken_links',
        'orphan_records',
        'index_mismatch',
        'checksum_failure',
        'silent_loss_report',
        'repair_success',
      ]);
      expect(document['live_integrity_telemetry'], 'DEFERRED-EXTERNAL');
      expect(document['external_integrity_gates'], 'DEFERRED-EXTERNAL');
    });
  });
}
