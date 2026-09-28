import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_112_closure.dart';

void main() {
  test('112.54 closure manifest records the deferred RC decision', () {
    final file = File('docs/planning/v1.2/sprint_112_sprint_closure.json');
    expect(file.existsSync(), isTrue);
    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(document['canonical_step'], '112.54');
    expect(document['definition_of_done'], hasLength(8));
    expect(document['rc_decision'], 'DEFERRED_EXTERNAL_GATES');
    expect(document['closure_decision'], 'DEFERRED');
  });

  test('112.54 exposes the canonical eight closure criteria', () {
    expect(Sprint112Closure.criteriaNames, <String>[
      'entry_gate_passed',
      'scope_frozen',
      '29_unique_features_accounted_for',
      'feature_30_alias_validated',
      'integration_verified',
      'quality_gates_complete',
      'rc_decision_recorded',
      'remaining_risks_owned',
    ]);
  });

  test('closure remains deferred when RC decision defers external gates', () {
    final report = Sprint112Closure.evaluate(
      criteria: Sprint112Closure.canonicalCriteria,
      rcDecision: 'DEFERRED_EXTERNAL_GATES',
    );

    expect(report.criteria.length, 8);
    expect(report.passedCount, 8);
    expect(report.decision, Sprint112ClosureDecision.deferred);
    expect(report.isClosed, isFalse);
    expect(report.unmetCriteria, isEmpty);
    expect(report.summary, contains('DEFERRED_EXTERNAL_GATES'));
  });

  test('closure fails closed when a criterion is missing or false', () {
    final criteria = [
      ...Sprint112Closure.canonicalCriteria,
      const Sprint112ClosureCriterion(
        name: 'unexpected',
        passed: true,
        evidence: 'test',
      ),
    ];

    expect(
      () => Sprint112Closure.evaluate(
        criteria: criteria,
        rcDecision: 'DEFERRED_EXTERNAL_GATES',
      ),
      throwsA(isA<ArgumentError>()),
    );

    final failed = Sprint112Closure.canonicalCriteria
        .map(
          (criterion) => criterion.name == 'quality_gates_complete'
              ? const Sprint112ClosureCriterion(
                  name: 'quality_gates_complete',
                  passed: false,
                  evidence: 'hosted CI remains unavailable',
                )
              : criterion,
        )
        .toList();
    final report = Sprint112Closure.evaluate(
      criteria: failed,
      rcDecision: 'DEFERRED_EXTERNAL_GATES',
    );
    expect(report.decision, Sprint112ClosureDecision.deferred);
    expect(report.unmetCriteria, <String>['quality_gates_complete']);
  });
}
