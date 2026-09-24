import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/memory_storage_cache_health.dart';

void main() {
  group('114.17 Memory, Storage & Cache Health', () {
    test('absent observations are blocked without health claims', () {
      final report = MemoryStorageCacheHealth().evaluate(null);

      expect(report.state, MemoryStorageState.blocked);
      expect(report.coveredSignals, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.notes, anyElement(contains('DEFERRED-EXTERNAL')));
    });

    test('incomplete signal coverage fails with signals invalid field', () {
      final report = MemoryStorageCacheHealth().evaluate(<MemoryObservation>[
        const MemoryObservation(
          signal: MemorySignal.memoryPressure,
          outcome: MemoryOutcome.ok,
          note: 'Heap usage versus the frozen memory budget.',
        ),
      ]);

      expect(report.state, MemoryStorageState.fail);
      expect(report.invalidFields, contains('signals'));
      expect(report.coveredSignals, <MemorySignal>[
        MemorySignal.memoryPressure,
      ]);
    });

    test('observation without a note is invalid evidence', () {
      final report = MemoryStorageCacheHealth().evaluate(
        _observations(
          memory: MemoryOutcome.ok,
          storage: MemoryOutcome.ok,
          snapshot: MemoryOutcome.ok,
          cache: MemoryOutcome.ok,
          temp: MemoryOutcome.ok,
          index: MemoryOutcome.ok,
          indexNote: '',
        ),
      );

      expect(report.state, MemoryStorageState.fail);
      expect(report.invalidFields, contains('notes'));
    });

    test('claiming ok growth while cache pressure failed is ignored', () {
      final report = MemoryStorageCacheHealth().evaluate(
        _observations(
          memory: MemoryOutcome.ok,
          storage: MemoryOutcome.ok,
          snapshot: MemoryOutcome.ok,
          cache: MemoryOutcome.failed,
          temp: MemoryOutcome.ok,
          index: MemoryOutcome.ok,
        ),
      );

      expect(report.state, MemoryStorageState.fail);
      expect(report.violations, contains('cache_pressure_ignored'));
    });

    test(
      'storage ok while cache pressure failed is ignored and unrecovered',
      () {
        final report = MemoryStorageCacheHealth().evaluate(
          _observations(
            memory: MemoryOutcome.ok,
            storage: MemoryOutcome.failed,
            snapshot: MemoryOutcome.ok,
            cache: MemoryOutcome.failed,
            temp: MemoryOutcome.ok,
            index: MemoryOutcome.ok,
          ),
        );

        expect(report.state, MemoryStorageState.fail);
        expect(report.violations, contains('cache_pressure_ignored'));
        expect(report.violations, contains('storage_growth_unrecovered'));
      },
    );

    test('failed snapshot growth under unresolved cache pressure is '
        'unrecovered', () {
      final report = MemoryStorageCacheHealth().evaluate(
        _observations(
          memory: MemoryOutcome.ok,
          storage: MemoryOutcome.ok,
          snapshot: MemoryOutcome.failed,
          cache: MemoryOutcome.failed,
          temp: MemoryOutcome.ok,
          index: MemoryOutcome.ok,
        ),
      );

      expect(report.state, MemoryStorageState.fail);
      expect(report.violations, contains('snapshot_growth_unrecovered'));
    });

    test('failed temp growth without cache pressure root cause is '
        'unrecovered', () {
      final report = MemoryStorageCacheHealth().evaluate(
        _observations(
          memory: MemoryOutcome.ok,
          storage: MemoryOutcome.ok,
          snapshot: MemoryOutcome.ok,
          cache: MemoryOutcome.ok,
          temp: MemoryOutcome.failed,
          index: MemoryOutcome.ok,
        ),
      );

      expect(report.state, MemoryStorageState.fail);
      expect(report.violations, contains('temp_growth_unrecovered'));
      expect(report.violations, isNot(contains('cache_pressure_ignored')));
    });

    test(
      'failed index growth with honestly recovered cache pressure passes',
      () {
        final report = MemoryStorageCacheHealth().evaluate(
          _observations(
            memory: MemoryOutcome.ok,
            storage: MemoryOutcome.ok,
            snapshot: MemoryOutcome.ok,
            cache: MemoryOutcome.recovered,
            temp: MemoryOutcome.ok,
            index: MemoryOutcome.failed,
          ),
        );

        expect(report.state, MemoryStorageState.pass);
        expect(report.invalidFields, isEmpty);
        expect(report.violations, isEmpty);
      },
    );

    test(
      'failed storage growth with honestly recovered cache pressure passes',
      () {
        final report = MemoryStorageCacheHealth().evaluate(
          _observations(
            memory: MemoryOutcome.ok,
            storage: MemoryOutcome.failed,
            snapshot: MemoryOutcome.ok,
            cache: MemoryOutcome.recovered,
            temp: MemoryOutcome.ok,
            index: MemoryOutcome.ok,
          ),
        );

        expect(report.state, MemoryStorageState.pass);
        expect(report.violations, isEmpty);
      },
    );

    test('failed memory pressure with honestly recovered cache pressure '
        'passes', () {
      final report = MemoryStorageCacheHealth().evaluate(
        _observations(
          memory: MemoryOutcome.failed,
          storage: MemoryOutcome.ok,
          snapshot: MemoryOutcome.ok,
          cache: MemoryOutcome.recovered,
          temp: MemoryOutcome.ok,
          index: MemoryOutcome.ok,
        ),
      );

      expect(report.state, MemoryStorageState.pass);
      expect(report.violations, isEmpty);
    });

    test('failed memory pressure without recovered cache pressure is '
        'unrecovered', () {
      final report = MemoryStorageCacheHealth().evaluate(
        _observations(
          memory: MemoryOutcome.failed,
          storage: MemoryOutcome.ok,
          snapshot: MemoryOutcome.ok,
          cache: MemoryOutcome.ok,
          temp: MemoryOutcome.ok,
          index: MemoryOutcome.ok,
        ),
      );

      expect(report.state, MemoryStorageState.fail);
      expect(report.violations, contains('memory_pressure_unrecovered'));
    });

    test('fully covered consistent record verifies all six signals', () {
      final report = MemoryStorageCacheHealth().evaluate(
        _observations(
          memory: MemoryOutcome.ok,
          storage: MemoryOutcome.ok,
          snapshot: MemoryOutcome.ok,
          cache: MemoryOutcome.ok,
          temp: MemoryOutcome.ok,
          index: MemoryOutcome.ok,
        ),
      );

      expect(report.state, MemoryStorageState.pass);
      expect(report.coveredSignals, <MemorySignal>[
        MemorySignal.memoryPressure,
        MemorySignal.storageGrowth,
        MemorySignal.snapshotGrowth,
        MemorySignal.cachePressure,
        MemorySignal.tempGrowth,
        MemorySignal.indexGrowth,
      ]);
      expect(report.invalidFields, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('manifest declares canonical evidence and external deferral', () {
      final file = File(
        'docs/planning/v1.2/sprint_114_memory_storage_cache_health.json',
      );
      expect(file.existsSync(), isTrue);
      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(document['canonical_step'], '114.17');
      expect(document['required_evidence'], <dynamic>[
        'memory_pressure',
        'storage_growth',
        'snapshot_growth',
        'cache_pressure',
        'temp_growth',
        'index_growth',
      ]);
      expect(document['live_resource_telemetry'], 'DEFERRED-EXTERNAL');
      expect(document['external_resource_gates'], 'DEFERRED-EXTERNAL');
    });
  });
}

List<MemoryObservation> _observations({
  required MemoryOutcome memory,
  required MemoryOutcome storage,
  required MemoryOutcome snapshot,
  required MemoryOutcome cache,
  required MemoryOutcome temp,
  required MemoryOutcome index,
  String? indexNote,
}) {
  return <MemoryObservation>[
    MemoryObservation(
      signal: MemorySignal.memoryPressure,
      outcome: memory,
      note: 'Peak working-set versus the frozen memory budget.',
    ),
    MemoryObservation(
      signal: MemorySignal.storageGrowth,
      outcome: storage,
      note: 'Workspace storage growth versus the retention budget.',
    ),
    MemoryObservation(
      signal: MemorySignal.snapshotGrowth,
      outcome: snapshot,
      note: 'Snapshot retention growth versus the retention budget.',
    ),
    MemoryObservation(
      signal: MemorySignal.cachePressure,
      outcome: cache,
      note: 'Cache eviction and reclaim behaviour under pressure.',
    ),
    MemoryObservation(
      signal: MemorySignal.tempGrowth,
      outcome: temp,
      note: 'Temporary artifact growth versus the cleanup budget.',
    ),
    MemoryObservation(
      signal: MemorySignal.indexGrowth,
      outcome: index,
      note: indexNote ?? 'Search index size growth versus the baseline.',
    ),
  ];
}
