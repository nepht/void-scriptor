import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_113_closure.dart';

void main() {
  test('113.46 manifest maps the canonical seven definition-of-done items', () {
    final file = File('docs/planning/v1.2/sprint_113_sprint_closure.json');
    expect(file.existsSync(), isTrue);
    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    expect(document['canonical_step'], '113.46');
    expect(document['definition_of_done'], hasLength(7));
    expect(document['ga_decision'], 'DEFERRED_RELEASE');
    expect(document['closure_decision'], 'CLOSED_LOCAL_DEFERRED_RELEASE');
  });

  test(
    '113.46 closes locally only when all seven criteria pass and release is deferred',
    () {
      final report = Sprint113Closure.evaluate(
        criteria: Sprint113Closure.canonicalCriteria,
        gaDecision: 'DEFERRED_RELEASE',
      );
      expect(report.criteria, hasLength(7));
      expect(report.passedCount, 7);
      expect(
        report.decision,
        Sprint113ClosureDecision.closedLocalDeferredRelease,
      );
      expect(report.isClosed, isTrue);
      expect(report.unmetCriteria, isEmpty);
    },
  );

  test(
    '113.46 fails closed for incomplete criteria or an unrecognized decision',
    () {
      final failed = Sprint113Closure.canonicalCriteria
          .map(
            (criterion) => criterion.name == 'quality_gates_passed'
                ? const Sprint113ClosureCriterion(
                    name: 'quality_gates_passed',
                    passed: false,
                    evidence: 'quality gate missing',
                  )
                : criterion,
          )
          .toList();
      final report = Sprint113Closure.evaluate(
        criteria: failed,
        gaDecision: 'DEFERRED_RELEASE',
      );
      expect(report.decision, Sprint113ClosureDecision.blocked);
      expect(report.unmetCriteria, <String>['quality_gates_passed']);
      expect(
        () => Sprint113Closure.evaluate(
          criteria: Sprint113Closure.canonicalCriteria,
          gaDecision: 'PUBLISHED',
        ),
        throwsA(isA<ArgumentError>()),
      );
    },
  );
}
