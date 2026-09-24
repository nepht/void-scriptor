import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/cloud_sync_conflict_health.dart';

void main() {
  group('114.15 Cloud Sync & Conflict Health', () {
    test('absent observations are blocked without health claims', () {
      final report = CloudSyncConflictHealth().evaluate(null);

      expect(report.state, CloudSyncConflictState.blocked);
      expect(report.coveredSignals, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.notes, anyElement(contains('DEFERRED-EXTERNAL')));
    });

    test('incomplete signal coverage fails with signals invalid field', () {
      final report = CloudSyncConflictHealth().evaluate(<CloudSyncObservation>[
        const CloudSyncObservation(
          signal: CloudSyncSignal.syncSuccess,
          outcome: CloudSyncOutcome.ok,
          note: 'Sync session completed without reported error.',
        ),
      ]);

      expect(report.state, CloudSyncConflictState.fail);
      expect(report.invalidFields, contains('signals'));
      expect(report.coveredSignals, <CloudSyncSignal>[
        CloudSyncSignal.syncSuccess,
      ]);
    });

    test('observation without a note is invalid evidence', () {
      final report = CloudSyncConflictHealth().evaluate(
        _observations(
          sync: CloudSyncOutcome.ok,
          queueAge: CloudSyncOutcome.ok,
          transfer: CloudSyncOutcome.ok,
          retry: CloudSyncOutcome.ok,
          conflict: CloudSyncOutcome.ok,
          resolution: CloudSyncOutcome.ok,
          duplicate: CloudSyncOutcome.ok,
          duplicateNote: '',
        ),
      );

      expect(report.state, CloudSyncConflictState.fail);
      expect(report.invalidFields, contains('notes'));
    });

    test('sync claiming success while transfer failed is ignored', () {
      final report = CloudSyncConflictHealth().evaluate(
        _observations(
          sync: CloudSyncOutcome.ok,
          queueAge: CloudSyncOutcome.ok,
          transfer: CloudSyncOutcome.failed,
          retry: CloudSyncOutcome.ok,
          conflict: CloudSyncOutcome.ok,
          resolution: CloudSyncOutcome.ok,
          duplicate: CloudSyncOutcome.ok,
        ),
      );

      expect(report.state, CloudSyncConflictState.fail);
      expect(report.violations, contains('transfer_failure_ignored'));
    });

    test('sync claiming success while offline queue is stale is ignored', () {
      final report = CloudSyncConflictHealth().evaluate(
        _observations(
          sync: CloudSyncOutcome.ok,
          queueAge: CloudSyncOutcome.failed,
          transfer: CloudSyncOutcome.ok,
          retry: CloudSyncOutcome.ok,
          conflict: CloudSyncOutcome.ok,
          resolution: CloudSyncOutcome.ok,
          duplicate: CloudSyncOutcome.ok,
        ),
      );

      expect(report.state, CloudSyncConflictState.fail);
      expect(report.violations, contains('stale_queue_ignored'));
    });

    test(
      'sync claiming success while duplicate effects persist is ignored',
      () {
        final report = CloudSyncConflictHealth().evaluate(
          _observations(
            sync: CloudSyncOutcome.ok,
            queueAge: CloudSyncOutcome.ok,
            transfer: CloudSyncOutcome.ok,
            retry: CloudSyncOutcome.ok,
            conflict: CloudSyncOutcome.ok,
            resolution: CloudSyncOutcome.ok,
            duplicate: CloudSyncOutcome.failed,
          ),
        );

        expect(report.state, CloudSyncConflictState.fail);
        expect(report.violations, contains('duplicate_effects_ignored'));
      },
    );

    test('failed transfer without successful retry is unrecovered', () {
      final report = CloudSyncConflictHealth().evaluate(
        _observations(
          sync: CloudSyncOutcome.failed,
          queueAge: CloudSyncOutcome.ok,
          transfer: CloudSyncOutcome.failed,
          retry: CloudSyncOutcome.failed,
          conflict: CloudSyncOutcome.ok,
          resolution: CloudSyncOutcome.ok,
          duplicate: CloudSyncOutcome.ok,
        ),
      );

      expect(report.state, CloudSyncConflictState.fail);
      expect(report.violations, contains('transfer_unrecovered'));
      expect(report.violations, contains('sync_unrecovered'));
    });

    test('failed sync without successful retry is unrecovered', () {
      final report = CloudSyncConflictHealth().evaluate(
        _observations(
          sync: CloudSyncOutcome.failed,
          queueAge: CloudSyncOutcome.ok,
          transfer: CloudSyncOutcome.ok,
          retry: CloudSyncOutcome.failed,
          conflict: CloudSyncOutcome.ok,
          resolution: CloudSyncOutcome.ok,
          duplicate: CloudSyncOutcome.ok,
        ),
      );

      expect(report.state, CloudSyncConflictState.fail);
      expect(report.violations, contains('sync_unrecovered'));
      expect(report.violations, isNot(contains('transfer_unrecovered')));
    });

    test(
      'rising conflict rate without successful resolution is unresolved',
      () {
        final report = CloudSyncConflictHealth().evaluate(
          _observations(
            sync: CloudSyncOutcome.ok,
            queueAge: CloudSyncOutcome.ok,
            transfer: CloudSyncOutcome.ok,
            retry: CloudSyncOutcome.ok,
            conflict: CloudSyncOutcome.failed,
            resolution: CloudSyncOutcome.failed,
            duplicate: CloudSyncOutcome.ok,
          ),
        );

        expect(report.state, CloudSyncConflictState.fail);
        expect(report.violations, contains('conflict_unresolved'));
      },
    );

    test('detected failures with honest retry recovery pass', () {
      final report = CloudSyncConflictHealth().evaluate(
        _observations(
          sync: CloudSyncOutcome.failed,
          queueAge: CloudSyncOutcome.ok,
          transfer: CloudSyncOutcome.failed,
          retry: CloudSyncOutcome.recovered,
          conflict: CloudSyncOutcome.ok,
          resolution: CloudSyncOutcome.ok,
          duplicate: CloudSyncOutcome.ok,
        ),
      );

      expect(report.state, CloudSyncConflictState.pass);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('fully covered consistent record verifies all seven signals', () {
      final report = CloudSyncConflictHealth().evaluate(
        _observations(
          sync: CloudSyncOutcome.ok,
          queueAge: CloudSyncOutcome.ok,
          transfer: CloudSyncOutcome.ok,
          retry: CloudSyncOutcome.ok,
          conflict: CloudSyncOutcome.ok,
          resolution: CloudSyncOutcome.ok,
          duplicate: CloudSyncOutcome.ok,
        ),
      );

      expect(report.state, CloudSyncConflictState.pass);
      expect(report.coveredSignals, <CloudSyncSignal>[
        CloudSyncSignal.syncSuccess,
        CloudSyncSignal.queueAge,
        CloudSyncSignal.transferFailure,
        CloudSyncSignal.retrySuccess,
        CloudSyncSignal.conflictRate,
        CloudSyncSignal.resolutionSuccess,
        CloudSyncSignal.duplicateEffect,
      ]);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('manifest declares canonical evidence and external deferral', () {
      final file = File(
        'docs/planning/v1.2/sprint_114_cloud_sync_conflict_health.json',
      );
      expect(file.existsSync(), isTrue);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document['canonical_step'], '114.15');
      expect(document['required_evidence'], <dynamic>[
        'sync_success',
        'queue_age',
        'transfer_failure',
        'retry_success',
        'conflict_rate',
        'resolution_success',
        'duplicate_effect',
      ]);
      expect(document['live_cloud_sync_telemetry'], 'DEFERRED-EXTERNAL');
      expect(document['external_sync_gates'], 'DEFERRED-EXTERNAL');
    });
  });
}

List<CloudSyncObservation> _observations({
  required CloudSyncOutcome sync,
  required CloudSyncOutcome queueAge,
  required CloudSyncOutcome transfer,
  required CloudSyncOutcome retry,
  required CloudSyncOutcome conflict,
  required CloudSyncOutcome resolution,
  required CloudSyncOutcome duplicate,
  String? duplicateNote,
}) {
  return <CloudSyncObservation>[
    CloudSyncObservation(
      signal: CloudSyncSignal.syncSuccess,
      outcome: sync,
      note: 'Sync session outcome recorded from the local queue journal.',
    ),
    CloudSyncObservation(
      signal: CloudSyncSignal.queueAge,
      outcome: queueAge,
      note: 'Oldest pending offline queue entry age versus target.',
    ),
    CloudSyncObservation(
      signal: CloudSyncSignal.transferFailure,
      outcome: transfer,
      note: 'Transfer failures observed during the sync window.',
    ),
    CloudSyncObservation(
      signal: CloudSyncSignal.retrySuccess,
      outcome: retry,
      note: 'Retry attempts that completed the failed transfer or sync.',
    ),
    CloudSyncObservation(
      signal: CloudSyncSignal.conflictRate,
      outcome: conflict,
      note: 'Conflict rate versus the agreed tolerance threshold.',
    ),
    CloudSyncObservation(
      signal: CloudSyncSignal.resolutionSuccess,
      outcome: resolution,
      note: 'Conflicts resolved without data loss or overwrite.',
    ),
    CloudSyncObservation(
      signal: CloudSyncSignal.duplicateEffect,
      outcome: duplicate,
      note:
          duplicateNote ??
          'Duplicate records created by repeated sync application.',
    ),
  ];
}
