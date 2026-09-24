import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/offline_local_first_health.dart';

void main() {
  group('114.18 Offline & Local-First Health', () {
    test('absent observations are blocked without health claims', () {
      final report = OfflineLocalFirstHealth().evaluate(null);

      expect(report.state, OfflineLocalFirstState.blocked);
      expect(report.coveredSignals, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.notes, anyElement(contains('DEFERRED-EXTERNAL')));
    });

    test('incomplete signal coverage fails with signals invalid field', () {
      final report = OfflineLocalFirstHealth().evaluate(<OfflineObservation>[
        const OfflineObservation(
          signal: OfflineSignal.offlineOpen,
          outcome: OfflineOutcome.ok,
          note: 'Project open completes with the network unavailable.',
        ),
      ]);

      expect(report.state, OfflineLocalFirstState.fail);
      expect(report.invalidFields, contains('signals'));
      expect(report.coveredSignals, <OfflineSignal>[OfflineSignal.offlineOpen]);
    });

    test('observation without a note is invalid evidence', () {
      final report = OfflineLocalFirstHealth().evaluate(
        _observations(
          open: OfflineOutcome.ok,
          edit: OfflineOutcome.ok,
          search: OfflineOutcome.ok,
          analysis: OfflineOutcome.ok,
          export: OfflineOutcome.ok,
          queue: OfflineOutcome.ok,
          exportNote: '',
        ),
      );

      expect(report.state, OfflineLocalFirstState.fail);
      expect(report.invalidFields, contains('notes'));
    });

    test('claiming ok workflows while queue recovery failed is ignored', () {
      final report = OfflineLocalFirstHealth().evaluate(
        _observations(
          open: OfflineOutcome.ok,
          edit: OfflineOutcome.ok,
          search: OfflineOutcome.ok,
          analysis: OfflineOutcome.ok,
          export: OfflineOutcome.ok,
          queue: OfflineOutcome.failed,
        ),
      );

      expect(report.state, OfflineLocalFirstState.fail);
      expect(report.violations, contains('queue_recovery_ignored'));
    });

    test('failed offline edit while queue recovery failed is ignored and '
        'unrecovered', () {
      final report = OfflineLocalFirstHealth().evaluate(
        _observations(
          open: OfflineOutcome.ok,
          edit: OfflineOutcome.failed,
          search: OfflineOutcome.ok,
          analysis: OfflineOutcome.ok,
          export: OfflineOutcome.ok,
          queue: OfflineOutcome.failed,
        ),
      );

      expect(report.state, OfflineLocalFirstState.fail);
      expect(report.violations, contains('queue_recovery_ignored'));
      expect(report.violations, contains('offline_edit_unrecovered'));
    });

    test('failed local export with healthy queue is unrecovered', () {
      final report = OfflineLocalFirstHealth().evaluate(
        _observations(
          open: OfflineOutcome.ok,
          edit: OfflineOutcome.ok,
          search: OfflineOutcome.ok,
          analysis: OfflineOutcome.ok,
          export: OfflineOutcome.failed,
          queue: OfflineOutcome.ok,
        ),
      );

      expect(report.state, OfflineLocalFirstState.fail);
      expect(report.violations, contains('local_export_unrecovered'));
      expect(report.violations, isNot(contains('queue_recovery_ignored')));
    });

    test('failed offline search with healthy queue is unrecovered', () {
      final report = OfflineLocalFirstHealth().evaluate(
        _observations(
          open: OfflineOutcome.ok,
          edit: OfflineOutcome.ok,
          search: OfflineOutcome.failed,
          analysis: OfflineOutcome.ok,
          export: OfflineOutcome.ok,
          queue: OfflineOutcome.ok,
        ),
      );

      expect(report.state, OfflineLocalFirstState.fail);
      expect(report.violations, contains('offline_search_unrecovered'));
      expect(report.violations, isNot(contains('queue_recovery_ignored')));
    });

    test('failed local analysis with honestly recovered queue passes', () {
      final report = OfflineLocalFirstHealth().evaluate(
        _observations(
          open: OfflineOutcome.ok,
          edit: OfflineOutcome.ok,
          search: OfflineOutcome.ok,
          analysis: OfflineOutcome.failed,
          export: OfflineOutcome.ok,
          queue: OfflineOutcome.recovered,
        ),
      );

      expect(report.state, OfflineLocalFirstState.pass);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('failed local export with honestly recovered queue passes', () {
      final report = OfflineLocalFirstHealth().evaluate(
        _observations(
          open: OfflineOutcome.ok,
          edit: OfflineOutcome.ok,
          search: OfflineOutcome.ok,
          analysis: OfflineOutcome.ok,
          export: OfflineOutcome.failed,
          queue: OfflineOutcome.recovered,
        ),
      );

      expect(report.state, OfflineLocalFirstState.pass);
      expect(report.violations, isEmpty);
    });

    test('failed offline edit with honestly recovered queue passes', () {
      final report = OfflineLocalFirstHealth().evaluate(
        _observations(
          open: OfflineOutcome.ok,
          edit: OfflineOutcome.failed,
          search: OfflineOutcome.ok,
          analysis: OfflineOutcome.ok,
          export: OfflineOutcome.ok,
          queue: OfflineOutcome.recovered,
        ),
      );

      expect(report.state, OfflineLocalFirstState.pass);
      expect(report.violations, isEmpty);
    });

    test('failed offline open with healthy queue is unrecovered', () {
      final report = OfflineLocalFirstHealth().evaluate(
        _observations(
          open: OfflineOutcome.failed,
          edit: OfflineOutcome.ok,
          search: OfflineOutcome.ok,
          analysis: OfflineOutcome.ok,
          export: OfflineOutcome.ok,
          queue: OfflineOutcome.ok,
        ),
      );

      expect(report.state, OfflineLocalFirstState.fail);
      expect(report.violations, contains('offline_open_unrecovered'));
    });

    test('fully covered consistent record verifies all six signals', () {
      final report = OfflineLocalFirstHealth().evaluate(
        _observations(
          open: OfflineOutcome.ok,
          edit: OfflineOutcome.ok,
          search: OfflineOutcome.ok,
          analysis: OfflineOutcome.ok,
          export: OfflineOutcome.ok,
          queue: OfflineOutcome.ok,
        ),
      );

      expect(report.state, OfflineLocalFirstState.pass);
      expect(report.coveredSignals, <OfflineSignal>[
        OfflineSignal.offlineOpen,
        OfflineSignal.offlineEdit,
        OfflineSignal.offlineSearch,
        OfflineSignal.localAnalysis,
        OfflineSignal.localExport,
        OfflineSignal.queueRecovery,
      ]);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('manifest declares canonical evidence and external deferral', () {
      final file = File(
        'docs/planning/v1.2/sprint_114_offline_local_first_health.json',
      );
      expect(file.existsSync(), isTrue);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document['canonical_step'], '114.18');
      expect(document['required_evidence'], <dynamic>[
        'offline_open',
        'offline_edit',
        'offline_search',
        'local_analysis',
        'local_export',
        'queue_recovery',
      ]);
      expect(document['live_offline_telemetry'], 'DEFERRED-EXTERNAL');
      expect(document['external_network_gates'], 'DEFERRED-EXTERNAL');
    });
  });
}

List<OfflineObservation> _observations({
  required OfflineOutcome open,
  required OfflineOutcome edit,
  required OfflineOutcome search,
  required OfflineOutcome analysis,
  required OfflineOutcome export,
  required OfflineOutcome queue,
  String? exportNote,
}) {
  return <OfflineObservation>[
    OfflineObservation(
      signal: OfflineSignal.offlineOpen,
      outcome: open,
      note: 'Project and workspace open with the network unavailable.',
    ),
    OfflineObservation(
      signal: OfflineSignal.offlineEdit,
      outcome: edit,
      note: 'Draft edits persist locally without connectivity.',
    ),
    OfflineObservation(
      signal: OfflineSignal.offlineSearch,
      outcome: search,
      note: 'Local search results resolve without connectivity.',
    ),
    OfflineObservation(
      signal: OfflineSignal.localAnalysis,
      outcome: analysis,
      note: 'Local analysis runs on-device without network calls.',
    ),
    OfflineObservation(
      signal: OfflineSignal.localExport,
      outcome: export,
      note: exportNote ?? 'Local export completes without connectivity.',
    ),
    OfflineObservation(
      signal: OfflineSignal.queueRecovery,
      outcome: queue,
      note: 'Queued offline actions replay and settle after reconnect.',
    ),
  ];
}
