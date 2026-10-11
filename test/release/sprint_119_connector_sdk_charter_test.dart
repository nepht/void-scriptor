import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_119_connector_sdk_charter.dart';

Sprint119ConnectorSdkCharter _charter({
  List<Sprint119SdkUseCase>? useCases,
  List<Sprint119SdkAudience>? audiences,
  List<Sprint119SdkBoundary>? boundaries,
  List<Sprint119SdkNonGoal>? nonGoals,
  List<Sprint119SdkMetric>? metrics,
  List<Sprint119SdkExitCriterion>? exitCriteria,
}) {
  return Sprint119ConnectorSdkCharter(
    useCases: useCases ?? Sprint119SdkCharterContract.canonicalCharter.useCases,
    audiences:
        audiences ?? Sprint119SdkCharterContract.canonicalCharter.audiences,
    boundaries:
        boundaries ?? Sprint119SdkCharterContract.canonicalCharter.boundaries,
    nonGoals: nonGoals ?? Sprint119SdkCharterContract.canonicalCharter.nonGoals,
    metrics: metrics ?? Sprint119SdkCharterContract.canonicalCharter.metrics,
    exitCriteria:
        exitCriteria ??
        Sprint119SdkCharterContract.canonicalCharter.exitCriteria,
  );
}

Sprint119SdkCharterReport _run(
  Sprint119ConnectorSdkCharter charter, {
  Sprint119SdkCharterAnchor? anchor,
}) {
  return const Sprint119SdkCharterGate().evaluateWith(
    anchor ?? Sprint119SdkCharterContract.canonicalAnchor,
    charter,
  );
}

void main() {
  group('119.2 Connector SDK Charter', () {
    test('declares the canonical step and six required fields', () {
      expect(Sprint119SdkCharterContract.canonicalStep, '119.2');
      expect(Sprint119SdkCharterContract.title, 'Connector SDK Charter');
      expect(
        Sprint119SdkCharterContract.manifestPath,
        'docs/planning/v1.3/sprint_119_connector_sdk_charter.json',
      );
      expect(Sprint119SdkCharterContract.requiredFields, <String>[
        'use_cases',
        'audiences',
        'boundaries',
        'non_goals',
        'metrics',
        'exit_criteria',
      ]);
      expect(Sprint119SdkCharterContract.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('the canonical charter passes against the 119.1 entry evidence', () {
      final report = const Sprint119SdkCharterGate().evaluate();

      expect(report.state, Sprint119SdkCharterState.pass);
      expect(report.verdict, 'CHARTER_COMPLETE_LOCAL');
      expect(report.charterExecutable, isTrue);
      expect(report.missingFields, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('the emitted manifest preserves the evaluator result and boundaries', () {
      final file = File(Sprint119SdkCharterContract.manifestPath);
      expect(file.existsSync(), isTrue);

      final record = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(record['canonical_step'], '119.2');
      expect(record['state'], 'pass');
      expect(record['verdict'], 'CHARTER_COMPLETE_LOCAL');
      expect(record['charter_executable'], isTrue);
      expect((record['use_cases'] as List<dynamic>), isNotEmpty);
      expect((record['boundaries'] as List<dynamic>), isNotEmpty);
      expect((record['non_goals'] as List<dynamic>), isNotEmpty);
      expect((record['metrics'] as List<dynamic>), isNotEmpty);
      expect((record['exit_criteria'] as List<dynamic>), isNotEmpty);
      expect(record['external_gates'], isNotEmpty);
    });

    test('a missing field is named and blocks execution', () {
      final report = _run(_charter(useCases: const <Sprint119SdkUseCase>[]));

      expect(report.state, Sprint119SdkCharterState.blocked);
      expect(report.verdict, 'SPRINT_119_SDK_CHARTER_FIELDS_MISSING');
      expect(report.missingFields, <String>['use_cases']);
      expect(report.charterExecutable, isFalse);
    });

    test('an entry witness that is not ready blocks the charter', () {
      final report = _run(
        _charter(),
        anchor: const Sprint119SdkCharterAnchor(
          entryState: 'blocked',
          entryVerdict: Sprint119SdkCharterContract.requiredEntryVerdict,
          executionAllowed: true,
        ),
      );

      expect(report.state, Sprint119SdkCharterState.blocked);
      expect(report.verdict, 'SPRINT_119_SDK_CHARTER_ENTRY_BLOCKED');
      expect(report.blockers, contains('committed_entry_gate_not_ready'));
    });

    test('a use case cannot reference an unknown audience', () {
      final report = _run(
        _charter(
          useCases: <Sprint119SdkUseCase>[
            const Sprint119SdkUseCase(
              useCaseId: 'broken',
              audienceId: 'missing',
              capability: 'read',
              outcome: 'not valid',
            ),
          ],
        ),
      );

      expect(report.state, Sprint119SdkCharterState.fail);
      expect(report.verdict, 'SPRINT_119_SDK_CHARTER_INVALID');
      expect(report.violations, contains('use_case_audience_unknown:broken'));
    });

    test('duplicate identifiers fail closed', () {
      final base = Sprint119SdkCharterContract.canonicalCharter.audiences.first;
      final report = _run(
        _charter(
          audiences: <Sprint119SdkAudience>[
            base,
            Sprint119SdkAudience(
              audienceId: base.audienceId,
              role: 'duplicate',
              needs: base.needs,
            ),
          ],
        ),
      );

      expect(report.state, Sprint119SdkCharterState.fail);
      expect(
        report.violations,
        contains('duplicate_audience_id:${base.audienceId}'),
      );
    });

    test('a metric without a measurable target is rejected', () {
      final report = _run(
        _charter(
          metrics: <Sprint119SdkMetric>[
            const Sprint119SdkMetric(
              metricId: 'unmeasured',
              name: 'Unknown result',
              target: '',
              measurement: 'missing',
              source: 'none',
            ),
          ],
        ),
      );

      expect(report.state, Sprint119SdkCharterState.fail);
      expect(report.violations, contains('metric_target_missing:unmeasured'));
    });

    test('all required exit gates are covered by evidence', () {
      final gates = Sprint119SdkCharterContract.requiredExitGates;
      final actual = Sprint119SdkCharterContract.canonicalCharter.exitCriteria
          .map((criterion) => criterion.gate)
          .toSet();

      expect(actual, containsAll(gates));
      expect(
        Sprint119SdkCharterContract.canonicalCharter.exitCriteria,
        everyElement(
          predicate<Sprint119SdkExitCriterion>(
            (criterion) => criterion.requiresEvidence,
          ),
        ),
      );
    });
  });
}
