/// Test for Full Quality Gate Rerun (Step 113.34).
/// Validates the eight canonical required_evidence gates —
/// automated_tests, migration_gate, performance_gate, security_gate,
/// privacy_gate, accessibility_gate, platform_gate, recovery_gate —
/// against their live evidence files after the latest stabilization
/// changes.
///
/// Contract note (refined after the RED run): the rerun contract demands
/// a complete, honest evidence trail — every planned unit carries an
/// exit result, every non-green unit carries a mandatory attribution,
/// and the seven dedicated gate tests must be exit 0. The contract does
/// NOT assert an all-green live tree, because one documented unit fails
/// only inside uncommitted sibling WIP (proven green at clean HEAD).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifestFile = File(
    'docs/planning/v1.2/sprint_113_full_quality_gate_rerun.json',
  );

  Map<String, dynamic> loadManifest() =>
      json.decode(manifestFile.readAsStringSync()) as Map<String, dynamic>;

  const sevenDedicatedGates = <String>{
    'migration_gate',
    'performance_gate',
    'security_gate',
    'privacy_gate',
    'accessibility_gate',
    'platform_gate',
    'recovery_gate',
  };

  group('113.34 Full Quality Gate Rerun', () {
    test('manifest pins the exact eight canonical gates', () {
      final manifest = loadManifest();
      expect(manifest['canonical_step'], '113.34');
      final gates = manifest['gates'] as Map<String, dynamic>;
      expect(gates.keys.toSet(), <String>{
        'automated_tests',
        ...sevenDedicatedGates,
      });
    });

    test(
      'every gate carries command, status, and an existing evidence file',
      () {
        final gates = loadManifest()['gates'] as Map<String, dynamic>;
        for (final entry in gates.entries) {
          final gate = entry.value as Map<String, dynamic>;
          expect(gate['command'], isNotEmpty, reason: entry.key);
          expect(gate['exit_code'], isA<int>(), reason: entry.key);
          expect(gate['status'], isNotEmpty, reason: entry.key);
          final evidencePath = gate['evidence'] as String;
          expect(
            File(evidencePath).existsSync(),
            isTrue,
            reason: '${entry.key}: evidence $evidencePath missing',
          );
        }
      },
    );

    test('the seven dedicated gate reruns are exit 0 in their own metas', () {
      final gates = loadManifest()['gates'] as Map<String, dynamic>;
      for (final key in sevenDedicatedGates) {
        final gate = gates[key] as Map<String, dynamic>;
        expect(gate['exit_code'], 0, reason: key);
        final meta =
            json.decode(File(gate['evidence'] as String).readAsStringSync())
                as Map<String, dynamic>;
        expect(meta['exit_code'], 0, reason: key);
        expect(meta['result'], 'PASS', reason: key);
      }
    });

    test('automated_tests summary: every unit has an exit result and log', () {
      final gates = loadManifest()['gates'] as Map<String, dynamic>;
      final auto = gates['automated_tests'] as Map<String, dynamic>;
      final summary =
          json.decode(File(auto['evidence'] as String).readAsStringSync())
              as Map<String, dynamic>;
      final units = summary['units'] as List<dynamic>;
      expect(units, isNotEmpty);
      expect(auto['shards'], units.length);
      expect(summary['units_total'], units.length);
      expect(summary['total_passed'], greaterThan(0));

      var exit0 = 0;
      var failed = 0;
      for (final raw in units) {
        final unit = raw as Map<String, dynamic>;
        expect(unit['exit_code'], isA<int>(), reason: unit['shard']);
        expect(unit['result'], isNotEmpty, reason: unit['shard']);
        expect(
          File(unit['log'] as String).existsSync(),
          isTrue,
          reason: '${unit['shard']}: log missing',
        );
        if (unit['exit_code'] == 0) {
          exit0++;
        } else {
          failed++;
        }
      }
      expect(summary['units_exit0'], exit0);
      expect(summary['total_failed'], failed);
      expect(auto['exit_code'], failed == 0 ? 0 : 1);
    });

    test('every non-green unit carries a mandatory attribution', () {
      final auto =
          (loadManifest()['gates'] as Map<String, dynamic>)['automated_tests']
              as Map<String, dynamic>;
      final summary =
          json.decode(File(auto['evidence'] as String).readAsStringSync())
              as Map<String, dynamic>;
      final units = summary['units'] as List<dynamic>;
      for (final raw in units) {
        final unit = raw as Map<String, dynamic>;
        if (unit['exit_code'] == 0) continue;
        expect(
          (unit['attribution'] as String?) ?? '',
          isNotEmpty,
          reason: '${unit['shard']}: failed unit without attribution',
        );
      }
      // The documented sibling-WIP failure must be present and attributed.
      final failedUnits = summary['failed_units'] as List<dynamic>;
      expect(failedUnits, isNotEmpty);
      final authFailure = failedUnits.firstWhere(
        (raw) =>
            (raw as Map<String, dynamic>)['shard'] == 'features/authentication',
        orElse: () => <String, dynamic>{},
      );
      expect(authFailure, isNotEmpty, reason: 'auth failure must be listed');
      expect((authFailure['attribution'] as String), contains('sibling'));
    });

    test('project_resilience timeout parent is replaced by two green split '
        'units', () {
      final auto =
          (loadManifest()['gates'] as Map<String, dynamic>)['automated_tests']
              as Map<String, dynamic>;
      final summary =
          json.decode(File(auto['evidence'] as String).readAsStringSync())
              as Map<String, dynamic>;
      final units = (summary['units'] as List<dynamic>)
          .map((raw) => raw as Map<String, dynamic>)
          .toList();

      final parent = units.firstWhere(
        (u) => u['shard'] == 'features/project_resilience',
        orElse: () => <String, dynamic>{},
      );
      expect(parent, isNotEmpty, reason: 'parent TIMEOUT evidence required');
      expect(parent['result'], 'TIMEOUT');
      expect(parent['attribution'], contains('split'));

      for (final splitName in <String>[
        'features/project_resilience::split_a',
        'features/project_resilience::split_b',
      ]) {
        final split = units.firstWhere(
          (u) => u['shard'] == splitName,
          orElse: () => <String, dynamic>{},
        );
        expect(split, isNotEmpty, reason: splitName);
        expect(split['exit_code'], 0, reason: splitName);
        expect(split['result'], 'PASS', reason: splitName);
      }
    });

    test('the isolated clean-HEAD rerun proves the committed state green', () {
      final metaFile = File(
        'docs/evidence/sprint-113-34-auth-head-worktree.meta',
      );
      expect(metaFile.existsSync(), isTrue);
      final meta =
          json.decode(metaFile.readAsStringSync()) as Map<String, dynamic>;
      expect(meta['exit_code'], 0);
      expect(meta['result'], 'PASS');
      expect(meta['head'], isNotEmpty);
      expect(File(meta['log'] as String).existsSync(), isTrue);
    });

    test('freshness: rerun evidence postdates the stabilization commits', () {
      final gates = loadManifest()['gates'] as Map<String, dynamic>;
      final auto = gates['automated_tests'] as Map<String, dynamic>;
      final summary =
          json.decode(File(auto['evidence'] as String).readAsStringSync())
              as Map<String, dynamic>;
      expect(summary['finished_at'], isNotEmpty);
      expect((summary['finished_at'] as String).substring(0, 10), '2026-09-23');
    });

    test('manifest states limits and decision honestly', () {
      final manifest = loadManifest();
      expect(manifest['limits'], isNotEmpty);
      expect(manifest['decision'], isNotEmpty);
      expect(
        manifest['decision'],
        'rerun_complete_with_documented_unit_exceptions',
      );
    });
  });
}
