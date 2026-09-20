import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    '112.48 records locale, calendar, number_unit, text_expansion, rtl, multiscript, and decision',
    () {
      final file = File('docs/planning/v1.2/sprint_112_localization_gate.json');
      expect(
        file.existsSync(),
        isTrue,
        reason: '112.48 localization gate manifest must exist',
      );

      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(document['canonical_step'], '112.48');
      expect(document['title'], 'Localization & Multiscript Gate');

      final budgets = (document['budgets'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(
        budgets.map((entry) => entry['id']),
        containsAll(const <String>[
          'locale_results',
          'calendar_results',
          'number_unit_results',
          'text_expansion_results',
          'rtl_results',
          'multiscript_results',
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
          'locale_results',
          'calendar_results',
          'number_unit_results',
          'text_expansion_results',
          'rtl_results',
          'multiscript_results',
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
      expect(limits.toLowerCase(), contains('rtl layout'));
      expect(limits.toLowerCase(), contains('hosted ci'));
      expect(limits.toLowerCase(), contains('hardware'));
      expect(limits.toLowerCase(), contains('public release'));
    },
  );
}
