// Sprint 110.50 - Sprint Closure (RED->GREEN contract).
//
// Verifies the canonical `definition_of_done` from
// `sprint_110.json:110.50`:
//   1. entry_gate_passed
//   2. 10_feature_contracts_resolved
//   3. cross_simulation_integration_verified
//   4. quality_reviews_complete
//   5. alpha_2_decision_recorded
//   6. remaining_risks_owned
//
// Domain-only, deterministic. No persistence, no UI, no wall clock,
// no locale, no random, no network.

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/alpha2_acceptance_gate.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_110_closure.dart';

void main() {
  group('Sprint 110.50 - closure DoD entries', () {
    test('factory exposes the canonical six DoD keys', () {
      const keys = Sprint110Closure.dodKeys;
      expect(keys, hasLength(6));
      expect(keys, contains('entry_gate_passed'));
      expect(keys, contains('10_feature_contracts_resolved'));
      expect(keys, contains('cross_simulation_integration_verified'));
      expect(keys, contains('quality_reviews_complete'));
      expect(keys, contains('alpha_2_decision_recorded'));
      expect(keys, contains('remaining_risks_owned'));
    });
    test('ClosureDoD validates non-empty key + non-empty sourceRevision', () {
      expect(
        () => ClosureDoD.validated(key: '', passed: true, sourceRevision: 'x'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => ClosureDoD.validated(key: 'ok', passed: true, sourceRevision: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('ClosureDoD.validated accepts well-formed entry', () {
      const entry = ClosureDoD(
        key: 'entry_gate_passed',
        passed: true,
        sourceRevision: 'sprint_110.json:110.1',
      );
      expect(entry.key, 'entry_gate_passed');
      expect(entry.passed, isTrue);
      expect(entry.sourceRevision, 'sprint_110.json:110.1');
    });
  });
  group('Sprint 110.50 - closure report aggregation', () {
    Alpha2AcceptanceReport alpha2AllPass() {
      return Alpha2AcceptanceReport.from(
        scope: const Alpha2FeatureScope(
          totalSteps: 10,
          verifiedSteps: 10,
          capabilities: Alpha2AcceptanceGate.canonicalCapabilities,
        ),
        evidences: Alpha2AcceptanceGate.buildCanonicalEvidence(
          verifiedSteps: 10,
          determinismGreen: true,
          testResultsGreen: true,
          benchReportWithinBudget: true,
          threatReviewFixStatus: 'clean',
          a11yFixStatus: 'clean',
          rollbackRecorded: true,
        ),
      );
    }

    Alpha2AcceptanceReport alpha2Partial() {
      return Alpha2AcceptanceReport.from(
        scope: const Alpha2FeatureScope(
          totalSteps: 10,
          verifiedSteps: 9,
          capabilities: Alpha2AcceptanceGate.canonicalCapabilities,
        ),
        evidences: Alpha2AcceptanceGate.buildCanonicalEvidence(
          verifiedSteps: 9,
          determinismGreen: true,
          testResultsGreen: true,
          benchReportWithinBudget: true,
          threatReviewFixStatus: 'acceptable',
          a11yFixStatus: 'acceptable',
          rollbackRecorded: true,
        ),
      );
    }

    test('all six DoD pass + alpha2 pass produces CLOSED decision', () {
      final report = Sprint110Closure.evaluate(
        dod: const [
          ClosureDoD(
            key: 'entry_gate_passed',
            passed: true,
            sourceRevision: 'sprint_110.json:110.1',
          ),
          ClosureDoD(
            key: '10_feature_contracts_resolved',
            passed: true,
            sourceRevision: 'sprint_110.json:110.3-110.42',
          ),
          ClosureDoD(
            key: 'cross_simulation_integration_verified',
            passed: true,
            sourceRevision: 'sprint_110.json:110.42',
          ),
          ClosureDoD(
            key: 'quality_reviews_complete',
            passed: true,
            sourceRevision: 'sprint_110.json:110.43-110.47',
          ),
          ClosureDoD(
            key: 'alpha_2_decision_recorded',
            passed: true,
            sourceRevision: 'sprint_110.json:110.49',
          ),
          ClosureDoD(
            key: 'remaining_risks_owned',
            passed: true,
            sourceRevision: 'sprint_110.json:110.46,110.47',
          ),
        ],
        alpha2Report: alpha2AllPass(),
      );
      expect(report.decision, ClosureDecision.closed);
      expect(report.passedCount, 6);
      expect(report.totalCount, 6);
      expect(report.unmetDoDKeys, isEmpty);
      expect(report.alpha2Summary.contains('decision=GO'), isTrue);
    });
    test('one DoD unmet yields DEFERRED decision', () {
      final report = Sprint110Closure.evaluate(
        dod: const [
          ClosureDoD(
            key: 'entry_gate_passed',
            passed: true,
            sourceRevision: 'sprint_110.json:110.1',
          ),
          ClosureDoD(
            key: '10_feature_contracts_resolved',
            passed: false,
            sourceRevision: 'sprint_110.json:110.3-110.42',
          ),
          ClosureDoD(
            key: 'cross_simulation_integration_verified',
            passed: true,
            sourceRevision: 'sprint_110.json:110.42',
          ),
          ClosureDoD(
            key: 'quality_reviews_complete',
            passed: true,
            sourceRevision: 'sprint_110.json:110.43-110.47',
          ),
          ClosureDoD(
            key: 'alpha_2_decision_recorded',
            passed: true,
            sourceRevision: 'sprint_110.json:110.49',
          ),
          ClosureDoD(
            key: 'remaining_risks_owned',
            passed: true,
            sourceRevision: 'sprint_110.json:110.46,110.47',
          ),
        ],
        alpha2Report: alpha2AllPass(),
      );
      expect(report.decision, ClosureDecision.deferred);
      expect(report.unmetDoDKeys, ['10_feature_contracts_resolved']);
      expect(report.passedCount, 5);
    });
    test('alpha-2 blocked propagates BLOCKED decision regardless of DoD', () {
      final alpha2Blocked = Alpha2AcceptanceReport.from(
        scope: const Alpha2FeatureScope(
          totalSteps: 10,
          verifiedSteps: 10,
          capabilities: Alpha2AcceptanceGate.canonicalCapabilities,
        ),
        evidences: Alpha2AcceptanceGate.buildCanonicalEvidence(
          verifiedSteps: 10,
          determinismGreen: false,
          testResultsGreen: true,
          benchReportWithinBudget: true,
          threatReviewFixStatus: 'clean',
          a11yFixStatus: 'clean',
          rollbackRecorded: true,
        ),
      );
      final report = Sprint110Closure.evaluate(
        dod: List<ClosureDoD>.generate(
          6,
          (i) => ClosureDoD(
            key: Sprint110Closure.dodKeys[i],
            passed: true,
            sourceRevision: 'sprint_110.json:110.${i + 1}',
          ),
        ),
        alpha2Report: alpha2Blocked,
      );
      expect(report.decision, ClosureDecision.blocked);
      expect(alpha2Blocked.isBlocked, isTrue);
    });
    test('alpha-2 partial propagates DEFERRED', () {
      final report = Sprint110Closure.evaluate(
        dod: List<ClosureDoD>.generate(
          6,
          (i) => ClosureDoD(
            key: Sprint110Closure.dodKeys[i],
            passed: true,
            sourceRevision: 'sprint_110.json:110.${i + 1}',
          ),
        ),
        alpha2Report: alpha2Partial(),
      );
      expect(report.decision, ClosureDecision.deferred);
      expect(report.alpha2Summary.contains('steps=9/10'), isTrue);
    });

    test('DoD list shorter than canonical six is rejected', () {
      expect(
        () => Sprint110Closure.evaluate(
          dod: const [
            ClosureDoD(
              key: 'entry_gate_passed',
              passed: true,
              sourceRevision: 'sprint_110.json:110.1',
            ),
          ],
          alpha2Report: alpha2AllPass(),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
    test('DoD list longer than canonical six is rejected', () {
      final dod = List<ClosureDoD>.generate(
        7,
        (i) => ClosureDoD(
          key: i < Sprint110Closure.dodKeys.length
              ? Sprint110Closure.dodKeys[i]
              : 'extra_${i - Sprint110Closure.dodKeys.length}',
          passed: true,
          sourceRevision: 'sprint_110.json:110.${i + 1}',
        ),
      );
      expect(
        () =>
            Sprint110Closure.evaluate(dod: dod, alpha2Report: alpha2AllPass()),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('summary string records decision + counts + alpha2 summary', () {
      final report = Sprint110Closure.evaluate(
        dod: List<ClosureDoD>.generate(
          6,
          (i) => ClosureDoD(
            key: Sprint110Closure.dodKeys[i],
            passed: true,
            sourceRevision: 'sprint_110.json:110.${i + 1}',
          ),
        ),
        alpha2Report: alpha2AllPass(),
      );
      expect(report.summary, contains('decision=CLOSED'));
      expect(report.summary, contains('passed=6/6'));
      expect(report.summary, contains('alpha2='));
    });
  });
}
