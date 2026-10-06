import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sprint 109 Sprint Closure Gate (109.52)', () {
    late Map<String, dynamic> closureJson;

    setUp(() {
      final file = File('docs/planning/v1.2/sprint_109_sprint_closure.json');
      expect(file.existsSync(), isTrue, reason: 'Closure json file must exist');
      closureJson = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    });

    test('declares canonical step 109.52 with VERIFIED-LOCAL status', () {
      expect(closureJson['canonical_step'], equals('109.52'));
      expect(closureJson['title'], equals('Sprint Closure'));
      expect(closureJson['status'], equals('VERIFIED-LOCAL'));
      expect(
        closureJson['closure_decision'],
        equals('CLOSED_LOCAL_DEFERRED_EXTERNAL'),
      );
      expect(
        closureJson['alpha_decision'],
        equals('GO_WITH_DOCUMENTED_RISK'),
      );
    });

    test('covers all eight canonical definition_of_done criteria', () {
      final dod = List<String>.from(closureJson['definition_of_done'] as List);
      expect(dod, hasLength(8));
      expect(dod, containsAll(<String>[
        'entry_gate_passed',
        'scope_contracts_delivered',
        'shared_architecture_and_schema_enforced',
        'migration_backup_verified',
        'features_wave1_implemented',
        'quality_gates_complete',
        'alpha_packaging_verified',
        'alpha_acceptance_decision_recorded',
      ]));

      final criteria = closureJson['criteria'] as Map<String, dynamic>;
      for (final item in dod) {
        expect(criteria.containsKey(item), isTrue, reason: 'Criteria must contain $item');
        final itemMap = criteria[item] as Map<String, dynamic>;
        expect(itemMap['status'], equals('VERIFIED-LOCAL'));
        expect((itemMap['evidence'] as List).isNotEmpty, isTrue);
      }
    });

    test('preserves deferred boundary and honest non-push limits', () {
      final openBoundary = List<String>.from(closureJson['open_boundary'] as List);
      expect(openBoundary.isNotEmpty, isTrue);

      final limits = List<String>.from(closureJson['limits'] as List);
      expect(limits.any((l) => l.contains('does not push')), isTrue);
    });
  });
}
