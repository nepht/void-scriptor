import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/performance_responsiveness_health.dart';

void main() {
  group('114.16 Performance & Responsiveness Health', () {
    test('absent observations are blocked without health claims', () {
      final report = PerformanceResponsivenessHealth().evaluate(null);

      expect(report.state, PerformanceState.blocked);
      expect(report.coveredSignals, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.notes, anyElement(contains('DEFERRED-EXTERNAL')));
    });

    test('incomplete signal coverage fails with signals invalid field', () {
      final report = PerformanceResponsivenessHealth()
          .evaluate(<PerformanceObservation>[
            const PerformanceObservation(
              signal: PerformanceSignal.startup,
              outcome: PerformanceOutcome.ok,
              note: 'Cold start duration versus the frozen baseline.',
            ),
          ]);

      expect(report.state, PerformanceState.fail);
      expect(report.invalidFields, contains('signals'));
      expect(report.coveredSignals, <PerformanceSignal>[
        PerformanceSignal.startup,
      ]);
    });

    test('observation without a note is invalid evidence', () {
      final report = PerformanceResponsivenessHealth().evaluate(
        _observations(
          startup: PerformanceOutcome.ok,
          editor: PerformanceOutcome.ok,
          search: PerformanceOutcome.ok,
          graph: PerformanceOutcome.ok,
          simulation: PerformanceOutcome.ok,
          exportDuration: PerformanceOutcome.ok,
          contention: PerformanceOutcome.ok,
          exportNote: '',
        ),
      );

      expect(report.state, PerformanceState.fail);
      expect(report.invalidFields, contains('notes'));
    });

    test('claiming ok responsiveness while background contention failed is '
        'ignored', () {
      final report = PerformanceResponsivenessHealth().evaluate(
        _observations(
          startup: PerformanceOutcome.ok,
          editor: PerformanceOutcome.ok,
          search: PerformanceOutcome.ok,
          graph: PerformanceOutcome.ok,
          simulation: PerformanceOutcome.ok,
          exportDuration: PerformanceOutcome.ok,
          contention: PerformanceOutcome.failed,
        ),
      );

      expect(report.state, PerformanceState.fail);
      expect(report.violations, contains('contention_ignored'));
    });

    test('startup ok while background contention failed is ignored', () {
      final report = PerformanceResponsivenessHealth().evaluate(
        _observations(
          startup: PerformanceOutcome.ok,
          editor: PerformanceOutcome.failed,
          search: PerformanceOutcome.ok,
          graph: PerformanceOutcome.ok,
          simulation: PerformanceOutcome.ok,
          exportDuration: PerformanceOutcome.ok,
          contention: PerformanceOutcome.failed,
        ),
      );

      expect(report.state, PerformanceState.fail);
      expect(report.violations, contains('contention_ignored'));
      expect(report.violations, contains('editor_latency_unrecovered'));
    });

    test(
      'failed editor latency under unresolved contention is unrecovered',
      () {
        final report = PerformanceResponsivenessHealth().evaluate(
          _observations(
            startup: PerformanceOutcome.ok,
            editor: PerformanceOutcome.failed,
            search: PerformanceOutcome.ok,
            graph: PerformanceOutcome.ok,
            simulation: PerformanceOutcome.ok,
            exportDuration: PerformanceOutcome.ok,
            contention: PerformanceOutcome.failed,
          ),
        );

        expect(report.state, PerformanceState.fail);
        expect(report.violations, contains('editor_latency_unrecovered'));
      },
    );

    test(
      'failed search latency without contention root cause is unrecovered',
      () {
        final report = PerformanceResponsivenessHealth().evaluate(
          _observations(
            startup: PerformanceOutcome.ok,
            editor: PerformanceOutcome.ok,
            search: PerformanceOutcome.failed,
            graph: PerformanceOutcome.ok,
            simulation: PerformanceOutcome.ok,
            exportDuration: PerformanceOutcome.ok,
            contention: PerformanceOutcome.ok,
          ),
        );

        expect(report.state, PerformanceState.fail);
        expect(report.violations, contains('search_latency_unrecovered'));
        expect(report.violations, isNot(contains('contention_ignored')));
      },
    );

    test('failed graph latency with honestly recovered contention passes', () {
      final report = PerformanceResponsivenessHealth().evaluate(
        _observations(
          startup: PerformanceOutcome.ok,
          editor: PerformanceOutcome.ok,
          search: PerformanceOutcome.ok,
          graph: PerformanceOutcome.failed,
          simulation: PerformanceOutcome.ok,
          exportDuration: PerformanceOutcome.ok,
          contention: PerformanceOutcome.recovered,
        ),
      );

      expect(report.state, PerformanceState.pass);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test(
      'failed simulation latency with honestly recovered contention passes',
      () {
        final report = PerformanceResponsivenessHealth().evaluate(
          _observations(
            startup: PerformanceOutcome.ok,
            editor: PerformanceOutcome.ok,
            search: PerformanceOutcome.ok,
            graph: PerformanceOutcome.ok,
            simulation: PerformanceOutcome.failed,
            exportDuration: PerformanceOutcome.ok,
            contention: PerformanceOutcome.recovered,
          ),
        );

        expect(report.state, PerformanceState.pass);
        expect(report.violations, isEmpty);
      },
    );

    test(
      'failed export duration with honestly recovered contention passes',
      () {
        final report = PerformanceResponsivenessHealth().evaluate(
          _observations(
            startup: PerformanceOutcome.ok,
            editor: PerformanceOutcome.ok,
            search: PerformanceOutcome.ok,
            graph: PerformanceOutcome.ok,
            simulation: PerformanceOutcome.ok,
            exportDuration: PerformanceOutcome.failed,
            contention: PerformanceOutcome.recovered,
          ),
        );

        expect(report.state, PerformanceState.pass);
        expect(report.violations, isEmpty);
      },
    );

    test('failed startup without recovered contention is unrecovered', () {
      final report = PerformanceResponsivenessHealth().evaluate(
        _observations(
          startup: PerformanceOutcome.failed,
          editor: PerformanceOutcome.ok,
          search: PerformanceOutcome.ok,
          graph: PerformanceOutcome.ok,
          simulation: PerformanceOutcome.ok,
          exportDuration: PerformanceOutcome.ok,
          contention: PerformanceOutcome.ok,
        ),
      );

      expect(report.state, PerformanceState.fail);
      expect(report.violations, contains('startup_unrecovered'));
    });

    test('fully covered consistent record verifies all seven signals', () {
      final report = PerformanceResponsivenessHealth().evaluate(
        _observations(
          startup: PerformanceOutcome.ok,
          editor: PerformanceOutcome.ok,
          search: PerformanceOutcome.ok,
          graph: PerformanceOutcome.ok,
          simulation: PerformanceOutcome.ok,
          exportDuration: PerformanceOutcome.ok,
          contention: PerformanceOutcome.ok,
        ),
      );

      expect(report.state, PerformanceState.pass);
      expect(report.coveredSignals, <PerformanceSignal>[
        PerformanceSignal.startup,
        PerformanceSignal.editorLatency,
        PerformanceSignal.searchLatency,
        PerformanceSignal.graphLatency,
        PerformanceSignal.simulationLatency,
        PerformanceSignal.exportDuration,
        PerformanceSignal.backgroundContention,
      ]);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('manifest declares canonical evidence and external deferral', () {
      final file = File(
        'docs/planning/v1.2/sprint_114_performance_responsiveness_health.json',
      );
      expect(file.existsSync(), isTrue);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document['canonical_step'], '114.16');
      expect(document['required_evidence'], <dynamic>[
        'startup',
        'editor_latency',
        'search_latency',
        'graph_latency',
        'simulation_latency',
        'export_duration',
        'background_contention',
      ]);
      expect(document['live_performance_telemetry'], 'DEFERRED-EXTERNAL');
      expect(document['external_performance_gates'], 'DEFERRED-EXTERNAL');
    });
  });
}

List<PerformanceObservation> _observations({
  required PerformanceOutcome startup,
  required PerformanceOutcome editor,
  required PerformanceOutcome search,
  required PerformanceOutcome graph,
  required PerformanceOutcome simulation,
  required PerformanceOutcome exportDuration,
  required PerformanceOutcome contention,
  String? exportNote,
}) {
  return <PerformanceObservation>[
    PerformanceObservation(
      signal: PerformanceSignal.startup,
      outcome: startup,
      note: 'Cold start duration versus the frozen local baseline.',
    ),
    PerformanceObservation(
      signal: PerformanceSignal.editorLatency,
      outcome: editor,
      note: 'Editor input-to-frame latency versus the baseline budget.',
    ),
    PerformanceObservation(
      signal: PerformanceSignal.searchLatency,
      outcome: search,
      note: 'Search query latency versus the baseline budget.',
    ),
    PerformanceObservation(
      signal: PerformanceSignal.graphLatency,
      outcome: graph,
      note: 'Graph render/update latency versus the baseline budget.',
    ),
    PerformanceObservation(
      signal: PerformanceSignal.simulationLatency,
      outcome: simulation,
      note: 'Simulation tick latency versus the baseline budget.',
    ),
    PerformanceObservation(
      signal: PerformanceSignal.exportDuration,
      outcome: exportDuration,
      note: exportNote ?? 'Export duration versus the frozen baseline.',
    ),
    PerformanceObservation(
      signal: PerformanceSignal.backgroundContention,
      outcome: contention,
      note: 'Background work contention observed during the measured window.',
    ),
  ];
}
