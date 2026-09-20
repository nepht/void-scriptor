import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('112.42 records reproducible outputs with executable evidence', () {
    final file = File(
      'docs/planning/v1.2/sprint_112_determinism_data_integrity_verification.json',
    );
    expect(
      file.existsSync(),
      isTrue,
      reason: '112.42 verification manifest must exist',
    );

    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(document['canonical_step'], '112.42');
    expect(document['title'], 'Determinism & Data Integrity Verification');

    final results = (document['results'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    expect(
      results.map((entry) => entry['id']),
      orderedEquals(const <String>[
        'seed_replay',
        'simulation_replay',
        'generator_replay',
        'index_checks',
        'link_checks',
        'export_checks',
      ]),
    );

    for (final result in results) {
      expect(result['status'], 'PASS', reason: result['id'] as String);
      expect(result['implementation_refs'], isNotEmpty);
      expect(result['test_refs'], isNotEmpty);
      expect(result['command'], isNotEmpty);
      for (final path in (result['implementation_refs'] as List<dynamic>)) {
        expect(File(path as String).existsSync(), isTrue, reason: path);
      }
      for (final path in (result['test_refs'] as List<dynamic>)) {
        expect(File(path as String).existsSync(), isTrue, reason: path);
      }
    }

    expect(document['new_integrity_failures'], isEmpty);
    expect(document['local_release_blockers'], isEmpty);
    expect(document['decision'], 'PASS_LOCAL_WITH_EXTERNAL_GATES_DEFERRED');

    final limits = (document['limits'] as List<dynamic>).cast<String>().join(
      ' ',
    );
    expect(limits, contains('Native GUI'));
    expect(limits, contains('hosted CI'));
    expect(limits, contains('signing'));
    expect(limits, contains('hardware'));
    expect(limits, contains('public release'));
  });
}
