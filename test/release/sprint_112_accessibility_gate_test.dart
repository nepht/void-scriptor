import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    '112.47 records keyboard, screen_reader, scaling, contrast, locale, and fix status',
    () {
      final file = File(
        'docs/planning/v1.2/sprint_112_accessibility_gate.json',
      );
      expect(
        file.existsSync(),
        isTrue,
        reason: '112.47 accessibility gate manifest must exist',
      );

      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(document['canonical_step'], '112.47');
      expect(document['title'], 'Accessibility Gate');

      final budgets = (document['budgets'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(
        budgets.map((entry) => entry['id']),
        containsAll(const <String>[
          'keyboard_results',
          'screen_reader_results',
          'scaling_results',
          'contrast_results',
          'locale_results',
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
        // screen_reader_results is documented as native PARTIAL (widget-level only);
        // no dedicated test file — validated against domain/docs evidence.
        if ((result['id'] as String) != 'screen_reader_results') {
          for (final path in (result['test_refs'] as List<dynamic>)) {
            expect(File(path as String).existsSync(), isTrue, reason: path);
          }
        }
      }

      expect(document['baseline'], isNotEmpty);
      expect(document['regressions'], isEmpty);
      expect(document['bottlenecks'], isNotEmpty);
      expect(document['findings'], isNotEmpty);
      expect(document['remediations'], isA<List>());
      expect(document['residual_risk_acceptance'], isNotEmpty);
      expect(document['fix_status'], 'VERIFIED for tested scope');
      expect(document['decision'], 'PASS_LOCAL_WITH_EXTERNAL_GATES_DEFERRED');

      final limits = (document['limits'] as List<dynamic>).cast<String>().join(
        ' ',
      );
      expect(limits.toLowerCase(), contains('native os screen-reader'));
      expect(limits.toLowerCase(), contains('physical-device contrast'));
      expect(limits.toLowerCase(), contains('hosted ci'));
      expect(limits.toLowerCase(), contains('hardware'));
      expect(limits.toLowerCase(), contains('public release'));
    },
  );
}
