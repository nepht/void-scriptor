import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_119_entry_gate.dart';

void main() {
  group('119.1 Sprint Entry Gate', () {
    test('declares the canonical six evidence dimensions and source map', () {
      expect(Sprint119EntryContract.canonicalStep, '119.1');
      expect(Sprint119EntryContract.requiredEvidence, <String>[
        'sprint_118_readiness',
        'stable_account_center',
        'certification_examples',
        'incident_status',
        'security_constraints',
        'support_capacity',
      ]);
      expect(
        Sprint119EntryContract.requiredSources.keys,
        containsAll(Sprint119EntryContract.requiredEvidence),
      );
      for (final source in Sprint119EntryContract.requiredSources.values) {
        expect(File(source).existsSync(), isTrue, reason: 'Missing $source');
      }
      expect(
        File(
          Sprint119EntryContract.externalAccountCenterObservationPath,
        ).existsSync(),
        isTrue,
        reason: 'Missing external Account Center observation',
      );
    });

    test(
      'authorized GitHub App certification opens the local Sprint 119 entry',
      () {
        final report = const Sprint119EntryGate().evaluate();

        expect(report.state, Sprint119EntryGateState.pass);
        expect(report.verdict, 'SPRINT_119_ENTRY_READY_LOCAL');
        expect(report.executionAllowed, isTrue);
        expect(report.correctiveExecutionAllowed, isFalse);
        expect(report.executionMode, 'EXPANSION_LOCAL_ENTRY');
        expect(report.blockers, isEmpty);
        expect(report.criteria, hasLength(6));
        expect(report.satisfiedCount, 6);
      },
    );

    test(
      'a measured live Account Center observation remains part of the ready entry',
      () {
        final report = const Sprint119EntryGate().evaluate();
        final criterion = report.criteria.firstWhere(
          (item) => item.key == 'stable_account_center',
        );

        expect(criterion.entrySatisfied, isTrue);
        expect(
          criterion.evidence,
          contains(Sprint119EntryContract.externalAccountCenterObservationPath),
        );
        expect(
          report.blockers,
          isNot(contains('stable_account_center_not_proven_external')),
        );
        expect(report.executionAllowed, isTrue);
      },
    );

    test('the emitted record agrees with the loader-backed report', () {
      final record =
          jsonDecode(
                File(Sprint119EntryContract.manifestPath).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final report = const Sprint119EntryGate().evaluate();

      expect(record['canonical_step'], Sprint119EntryContract.canonicalStep);
      expect(record['state'], report.state.name);
      expect(record['verdict'], report.verdict);
      expect(record['execution_allowed'], report.executionAllowed);
      expect(
        record['corrective_execution_allowed'],
        report.correctiveExecutionAllowed,
      );
      expect(record['execution_mode'], report.executionMode);
      expect(record['active_sprint_unchanged'], '118');
      expect(record['next_step'], '119.1');
      expect(record['criteria'], hasLength(6));
      expect(record['blockers'], report.blockers);
    });

    test('unreadable evidence fails closed without activating Sprint 119', () {
      final report = const Sprint119EntryGate().evaluateWith(null);

      expect(report.state, Sprint119EntryGateState.blocked);
      expect(report.verdict, 'SPRINT_119_ENTRY_EVIDENCE_UNREADABLE');
      expect(report.executionAllowed, isFalse);
      expect(report.correctiveExecutionAllowed, isFalse);
      expect(report.executionMode, 'BLOCKED');
      expect(report.missingEvidence, Sprint119EntryContract.requiredEvidence);
      expect(report.activeSprintUnchanged, '118');
    });

    test('a complete synthetic evidence set can open only a local entry', () {
      final report = const Sprint119EntryGate().evaluateWith(
        Sprint119EntryEvidence.allProven(),
      );

      expect(report.state, Sprint119EntryGateState.pass);
      expect(report.verdict, 'SPRINT_119_ENTRY_READY_LOCAL');
      expect(report.executionAllowed, isTrue);
      expect(report.correctiveExecutionAllowed, isFalse);
      expect(report.executionMode, 'EXPANSION_LOCAL_ENTRY');
      expect(report.blockers, isEmpty);
      expect(report.satisfiedCount, 6);
    });

    test(
      'zero certified providers blocks even when every other witness is present',
      () {
        final evidence = Sprint119EntryEvidence.allProven(
          certificationExamplesProven: false,
          certifiedProviderCount: 0,
        );
        final report = const Sprint119EntryGate().evaluateWith(evidence);

        expect(report.state, Sprint119EntryGateState.blocked);
        expect(report.blockers, contains('certification_examples_missing'));
        expect(report.executionAllowed, isFalse);
        expect(report.correctiveExecutionAllowed, isFalse);
      },
    );

    test(
      'approved corrective scope can run locally without opening expansion',
      () {
        final report = const Sprint119EntryGate().evaluateWith(
          Sprint119EntryEvidence.allProven(
            certificationExamplesProven: false,
            certifiedProviderCount: 0,
            correctiveScopeApproved: true,
            readinessDecision: 'CORRECTIVE_STABILIZATION',
          ),
        );

        expect(report.state, Sprint119EntryGateState.blocked);
        expect(report.executionAllowed, isFalse);
        expect(report.correctiveExecutionAllowed, isTrue);
        expect(report.executionMode, 'CORRECTIVE_ONLY');
      },
    );
  });
}
