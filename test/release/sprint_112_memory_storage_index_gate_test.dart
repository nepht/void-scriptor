import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    '112.44 records memory, storage, retention, cache, and reindex results',
    () {
      final file = File(
        'docs/planning/v1.2/sprint_112_memory_storage_index_gate.json',
      );
      expect(
        file.existsSync(),
        isTrue,
        reason: '112.44 memory/storage/index gate manifest must exist',
      );

      final document =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(document['canonical_step'], '112.44');
      expect(document['title'], 'Memory, Storage & Index Gate');

      final budgets = (document['budgets'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(
        budgets.map((entry) => entry['id']),
        containsAll(const <String>[
          'memory',
          'storage_growth',
          'retention',
          'cache',
          'reindex',
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
      expect(document['decision'], 'PASS_LOCAL_WITH_EXTERNAL_GATES_DEFERRED');

      final limits = (document['limits'] as List<dynamic>).cast<String>().join(
        ' ',
      );
      expect(limits, contains('heap'));
      expect(limits, contains('Native GUI'));
      expect(limits, contains('hosted CI'));
      expect(limits, contains('hardware'));
    },
  );
}
