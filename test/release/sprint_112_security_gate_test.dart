import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    '112.45 records threat model, security tests, findings, and decision',
    () {
      final file = File('docs/planning/v1.2/sprint_112_security_gate.json');
      expect(
        file.existsSync(),
        isTrue,
        reason: '112.45 security gate manifest must exist',
      );

      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(document['canonical_step'], '112.45');
      expect(document['title'], 'Security Gate');

      final budgets = (document['budgets'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(
        budgets.map((entry) => entry['id']),
        containsAll(const <String>[
          'threat_model',
          'isolation',
          'encryption',
          'credential_storage',
          'project_lock',
          'integrity',
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
        // dependency_scan is documented evidence, not a test file.
        if ((result['id'] as String) != 'dependency_scan') {
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
      expect(limits, contains('penetration testing'));
      expect(limits, contains('Native GUI'));
      expect(limits, contains('hosted CI'));
      expect(limits, contains('hardware'));
    },
  );
}
