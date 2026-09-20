import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Sprint 112.50 — Failure Injection & Recovery Gate manifest validation.
///
/// Verifies the manifest records budgets, baselines, scenarios, data-loss
/// results, recovery results, repair results, user guidance, test refs,
/// and decision. All paths are checked for existence.
void main() {
  test('112.50 records failure scenarios, evidence, and decision', () {
    final file = File(
      'docs/planning/v1.2/sprint_112_failure_injection_recovery_gate.json',
    );
    expect(
      file.existsSync(),
      isTrue,
      reason: '112.50 failure injection gate manifest must exist',
    );

    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(document['canonical_step'], '112.50');
    expect(document['title'], 'Failure Injection & Recovery Gate');

    final requiredEvidence = (document['required_evidence'] as List)
        .cast<String>();
    expect(
      requiredEvidence,
      containsAll(const <String>[
        'failure_scenarios',
        'data_loss_results',
        'recovery_results',
        'repair_results',
        'user_guidance',
        'decision',
      ]),
    );

    final scenarios = (document['scenarios'] as List)
        .cast<Map<String, dynamic>>();
    expect(
      scenarios.map((s) => s['id']),
      containsAll(const <String>[
        'crash',
        'power_loss',
        'disk_full',
        'permission_loss',
        'missing_file',
        'corrupt_index',
        'interrupted_migration',
      ]),
    );
    for (final scenario in scenarios) {
      expect(scenario['metric'], isNotEmpty, reason: scenario['id'] as String);
      expect(scenario['ceiling'], isA<num>(), reason: scenario['id'] as String);
      expect((scenario['ceiling'] as num), greaterThan(0));
      expect(scenario['unit'], isNotEmpty, reason: scenario['id'] as String);
      expect(scenario['source'], isNotEmpty, reason: scenario['id'] as String);
    }

    final results = (document['results'] as List).cast<Map<String, dynamic>>();
    expect(
      results.map((r) => r['id']),
      containsAll(scenarios.map((s) => s['id'])),
    );
    for (final result in results) {
      expect(result['status'], 'PASS', reason: result['id'] as String);
      expect(result['implementation_refs'], isNotEmpty);
      expect(result['test_refs'], isNotEmpty);
      expect(result['command'], isNotEmpty);
      for (final path
          in (result['implementation_refs'] as List).cast<String>()) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
      for (final path in (result['test_refs'] as List).cast<String>()) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    }

    final dataLossResults = (document['data_loss_results'] as List)
        .cast<Map<String, dynamic>>();
    expect(dataLossResults, isNotEmpty);
    for (final r in dataLossResults) {
      expect(r['status'], 'PASS', reason: r['scenario'] as String);
      expect(r['evidence'], isNotEmpty);
    }

    final recoveryResults = (document['recovery_results'] as List)
        .cast<Map<String, dynamic>>();
    expect(recoveryResults, isNotEmpty);
    for (final r in recoveryResults) {
      expect(r['status'], 'PASS', reason: r['scenario'] as String);
    }

    final repairResults = (document['repair_results'] as List)
        .cast<Map<String, dynamic>>();
    expect(repairResults, isNotEmpty);
    for (final r in repairResults) {
      expect(r['status'], 'PASS', reason: r['id'] as String);
    }

    final userGuidance = (document['user_guidance'] as List)
        .cast<Map<String, dynamic>>();
    expect(userGuidance, isNotEmpty);
    for (final g in userGuidance) {
      expect(g['status'], 'PASS', reason: g['scenario'] as String);
    }

    final baselines = (document['baseline'] as List)
        .cast<Map<String, dynamic>>();
    expect(baselines, isNotEmpty);
    for (final b in baselines) {
      expect(b['status'], isNotEmpty, reason: b['id'] as String);
      expect(b['evidence'], isNotEmpty, reason: b['id'] as String);
    }

    expect(document['regressions'], isEmpty);
    expect(document['bottlenecks'], isNotEmpty);
    expect(document['decision'], 'PASS_LOCAL_WITH_EXTERNAL_GATES_DEFERRED');

    final limits = (document['limits'] as List).cast<String>().join(' ');
    expect(limits, contains('power-loss'));
    expect(limits, contains('ENOSPC'));
    expect(limits, contains('Native GUI'));
    expect(limits, contains('hosted CI'));
    expect(limits, contains('signing'));
    expect(limits, contains('hardware'));
  });
}
