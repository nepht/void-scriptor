import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    '112.49 records platform_matrix, input, filesystem, package, upgrade, uninstall, and decision',
    () {
      final file = File(
        'docs/planning/v1.2/sprint_112_platform_compatibility_gate.json',
      );
      expect(
        file.existsSync(),
        isTrue,
        reason: '112.49 platform compatibility gate manifest must exist',
      );

      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(document['canonical_step'], '112.49');
      expect(document['title'], 'Platform Compatibility Gate');

      final budgets = (document['budgets'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(
        budgets.map((entry) => entry['id']),
        containsAll(const <String>[
          'platform_matrix',
          'input_results',
          'filesystem_results',
          'package_results',
          'upgrade_results',
          'uninstall_results',
        ]),
      );
      for (final budget in budgets) {
        expect(budget['metric'], isNotEmpty, reason: budget['id'] as String);
        expect(budget['ceiling'], isA<num>(), reason: budget['id'] as String);
        expect((budget['ceiling'] as num), greaterThan(0));
        expect(budget['unit'], isNotEmpty, reason: budget['id'] as String);
        expect(budget['source'], isNotEmpty, reason: budget['id'] as String);
      }

      final required = (document['required_outputs'] as List<dynamic>)
          .cast<String>();
      expect(
        required,
        containsAll(const <String>[
          'platform_matrix',
          'input_results',
          'filesystem_results',
          'package_results',
          'upgrade_results',
          'uninstall_results',
        ]),
      );
      expect(required, contains('decision'));

      final results = (document['results'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(
        results.map((entry) => entry['id']),
        containsAll(budgets.map((entry) => entry['id'])),
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

      expect(document['baseline'], isNotEmpty);
      expect(document['regressions'], isEmpty);
      expect(document['bottlenecks'], isNotEmpty);
      expect(document['findings'], isNotEmpty);
      expect(document['remediations'], isA<List>());
      expect(document['residual_risk_acceptance'], isNotEmpty);
      expect(document['decision'], 'PASS_LOCAL_WITH_EXTERNAL_GATES_DEFERRED');

      final limits = (document['limits'] as List<dynamic>).cast<String>().join(
        ' ',
      );
      expect(limits.toLowerCase(), contains('platform matrix'));
      expect(limits.toLowerCase(), contains('packaging'));
      expect(limits.toLowerCase(), contains('uninstall'));
      expect(limits.toLowerCase(), contains('hosted ci'));
      expect(limits.toLowerCase(), contains('public release'));
    },
  );
}
