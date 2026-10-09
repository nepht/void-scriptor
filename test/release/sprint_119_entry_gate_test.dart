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
    });

    test(
      'committed witnesses keep the SDK entry closed until certification is proven',
      () {
        final report = const Sprint119EntryGate().evaluate();

        expect(report.state, Sprint119EntryGateState.blocked);
        expect(report.verdict, 'SPRINT_119_ENTRY_BLOCKED_UPSTREAM');
        expect(report.executionAllowed, isFalse);
        expect(
          report.blockers,
          contains('sprint_118_readiness_not_expansion_ready'),
        );
        expect(
          report.blockers,
          contains('stable_account_center_not_proven_external'),
        );
        expect(report.blockers, contains('certification_examples_missing'));
        expect(report.criteria, hasLength(6));
        expect(report.satisfiedCount, 3);
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
      },
    );
  });
}
