import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    '112.46 records data flow, consent, telemetry, metadata, retention, deletion, and decision',
    () {
      final file = File('docs/planning/v1.2/sprint_112_privacy_gate.json');
      expect(
        file.existsSync(),
        isTrue,
        reason: '112.46 privacy gate manifest must exist',
      );

      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(document['canonical_step'], '112.46');
      expect(document['title'], 'Privacy Gate');

      final budgets = (document['budgets'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(
        budgets.map((entry) => entry['id']),
        containsAll(const <String>[
          'data_flow',
          'consent_tests',
          'telemetry_review',
          'metadata_tests',
          'retention_tests',
          'deletion_tests',
        ]),
      );
      for (final budget in budgets) {
        expect(budget['metric'], isNotEmpty, reason: budget['id'] as String);
        expect(budget['ceiling'], isA<num>(), reason: budget['id'] as String);
        expect((budget['ceiling'] as num), greaterThan(0));
        expect(budget['unit'], isNotEmpty, reason: budget['id'] as String);
        expect(budget['source'], isNotEmpty, reason: budget['id'] as String);
      }

      final results = (document['results'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(
        results.map((entry) => entry['id']),
        containsAll(budgets.map((entry) => entry['id'])),
      );
      for (final result in results) {
        expect(result['status'], 'PASS', reason: result['id'] as String);
        expect(result['implementation_refs'], isNotEmpty);
        expect(result['test_refs'], isA<List>());
        expect(result['command'], isNotEmpty);
        for (final path in (result['implementation_refs'] as List<dynamic>)) {
          expect(File(path as String).existsSync(), isTrue, reason: path);
        }
        // data_flow and deletion_tests have directory-level test_refs;
        // only validate file existence for non-directory references.
        if ((result['id'] as String) != 'data_flow' &&
            (result['id'] as String) != 'deletion_tests') {
          for (final path in (result['test_refs'] as List<dynamic>)) {
            expect(File(path as String).existsSync(), isTrue, reason: path);
          }
        }
      }

      expect(document['baseline'], isNotEmpty);
      expect(document['regressions'], isEmpty);
      expect(document['bottlenecks'], isNotEmpty);
      expect(document['findings'], isNotEmpty);
      expect(document['remediations'], isNotEmpty);
      expect(document['residual_risk_acceptance'], isNotEmpty);
      expect(document['decision'], 'PASS_LOCAL_WITH_EXTERNAL_GATES_DEFERRED');

      final limits = (document['limits'] as List<dynamic>).cast<String>().join(
        ' ',
      );
      expect(limits, contains('network egress'));
      expect(limits, contains('Native GUI'));
      expect(limits, contains('hosted CI'));
      expect(limits, contains('hardware'));
    },
  );
}
