import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_114_closure_v114.dart';

void main() {
  group('114.44 Sprint Closure', () {
    final completeCriteria = <Sprint114ClosureCriterion>[
      for (final name in Sprint114Closure.criteriaNames)
        Sprint114ClosureCriterion(
          name: name,
          passed: true,
          evidence: 'docs/planning/v1.2/sprint_114_sprint_closure.json',
        ),
    ];

    test('declares the canonical seven definition-of-done criteria', () {
      expect(Sprint114Closure.canonicalStep, '114.44');
      expect(Sprint114Closure.criteriaNames, <String>[
        'release_path_confirmed',
        'observation_completed_or_corrective_path_recorded',
        'critical_incidents_resolved_or_release_stopped',
        'stability_gate_decided',
        'patch_decision_recorded',
        'evidence_report_complete',
        'sprint_115_readiness_decided',
      ]);
      expect(
        Sprint114Closure.manifestPath,
        endsWith('sprint_114_sprint_closure.json'),
      );
    });

    test('manifest records local deferred closure and external boundary', () {
      final file = File(Sprint114Closure.manifestPath);
      expect(file.existsSync(), isTrue);
      final manifest =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(manifest['canonical_step'], '114.44');
      expect(manifest['status'], 'VERIFIED-LOCAL');
      expect(manifest['release_path'], 'DELAYED');
      expect(manifest['closure_decision'], 'CLOSED_LOCAL_DEFERRED_EXTERNAL');
      expect(manifest['definition_of_done'], hasLength(7));
      expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
      expect(manifest['limitations'], isNotEmpty);
    });

    test(
      'closes the local sprint when every criterion passes on DELAYED path',
      () {
        final report = Sprint114Closure.evaluate(
          criteria: completeCriteria,
          releasePath: 'DELAYED',
        );

        expect(report.passedCount, 7);
        expect(report.unmetCriteria, isEmpty);
        expect(report.violations, isEmpty);
        expect(
          report.decision,
          Sprint114ClosureDecision.closedLocalDeferredExternal,
        );
        expect(report.isClosed, isTrue);
        expect(report.externalGates, 'DEFERRED-EXTERNAL');
      },
    );

    test('an unmet criterion blocks closure and names the criterion', () {
      final incomplete = completeCriteria
          .map(
            (criterion) => criterion.name == 'stability_gate_decided'
                ? Sprint114ClosureCriterion(
                    name: criterion.name,
                    passed: false,
                    evidence: criterion.evidence,
                  )
                : criterion,
          )
          .toList(growable: false);

      final report = Sprint114Closure.evaluate(
        criteria: incomplete,
        releasePath: 'DELAYED',
      );

      expect(report.isClosed, isFalse);
      expect(report.decision, Sprint114ClosureDecision.blocked);
      expect(report.unmetCriteria, <String>['stability_gate_decided']);
    });

    test('unknown release path and blank evidence fail closed', () {
      final report = Sprint114Closure.evaluate(
        criteria: completeCriteria
            .map(
              (criterion) => criterion.name == 'patch_decision_recorded'
                  ? Sprint114ClosureCriterion(
                      name: criterion.name,
                      passed: true,
                      evidence: ' ',
                    )
                  : criterion,
            )
            .toList(growable: false),
        releasePath: 'PUBLISHED_UNKNOWN',
      );

      expect(report.decision, Sprint114ClosureDecision.blocked);
      expect(report.violations, contains('unsupported_release_path'));
      expect(
        report.violations,
        contains('patch_decision_recorded_missing_evidence'),
      );
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('rejects criteria that are not exactly the canonical set', () {
      expect(
        () => Sprint114Closure.evaluate(
          criteria: <Sprint114ClosureCriterion>[completeCriteria.first],
          releasePath: 'DELAYED',
        ),
        throwsArgumentError,
      );
      expect(
        () => Sprint114Closure.evaluate(
          criteria: <Sprint114ClosureCriterion>[
            ...completeCriteria,
            Sprint114ClosureCriterion(
              name: 'unexpected_criterion',
              passed: true,
              evidence: 'fixture',
            ),
          ],
          releasePath: 'DELAYED',
        ),
        throwsArgumentError,
      );
    });
  });
}
