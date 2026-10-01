// 113.43 — GA Approval Gate.
//
// The gate decides release, defer, or cancel from eight canonical
// evidence groups plus rollback readiness. Writing the record is not
// approval: a release decision additionally requires Choirudin's
// explicit approval, no active release blockers, and confirmed
// rollback readiness.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/ga_approval_gate.dart';

void main() {
  final manifestFile = File(
    'docs/planning/v1.2/sprint_113_ga_approval_gate.json',
  );

  group('113.43 GA approval gate', () {
    test('declares the eight canonical evidence keys in roadmap order', () {
      expect(GaApprovalGate.requiredEvidenceKeys, <String>[
        'validation_results',
        'blocker_status',
        'quality_gate_rerun',
        'feature_reconciliation',
        'known_issues',
        'signed_artifacts',
        'staged_rollout_plan',
        'rollback_readiness',
      ]);
      expect(GaApprovalGate.requiredEvidenceKeys.toSet().length, 8);
      expect(GaApprovalGate.canonicalStep, '113.43');
    });

    test('planning manifest records the gate with sources on disk', () {
      expect(
        manifestFile.existsSync(),
        isTrue,
        reason: 'missing docs/planning/v1.2/sprint_113_ga_approval_gate.json',
      );
      final manifest =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      expect(manifest['canonical_step'], '113.43');
      expect(manifest['status'], 'VERIFIED-LOCAL');
      expect(manifest['version'], '1.2.0-rc.1');

      final evidence = manifest['required_evidence'] as Map<String, dynamic>;
      expect(
        evidence.keys.toSet(),
        GaApprovalGate.requiredEvidenceKeys.toSet(),
      );
      for (final name in GaApprovalGate.requiredEvidenceKeys) {
        final entry = evidence[name] as Map<String, dynamic>;
        expect(
          entry['present'],
          isTrue,
          reason: '$name must be recorded as present',
        );
        final sources = (entry['sources'] as List<dynamic>).cast<String>();
        expect(sources, isNotEmpty, reason: '$name needs at least one source');
        for (final source in sources) {
          expect(
            source.trim(),
            isNotEmpty,
            reason: '$name has a blank source path',
          );
          expect(
            File(source).existsSync(),
            isTrue,
            reason: '$name source not found on disk: $source',
          );
        }
        expect(
          (entry['summary'] as String).trim(),
          isNotEmpty,
          reason: '$name needs a summary',
        );
      }

      // The recorded outcome is an explicitly approved release.
      expect(manifest['decision'], 'APPROVED');
      final approval = manifest['approval'] as Map<String, dynamic>;
      expect(approval['decision'], 'release');
      expect(approval['approval_state'], 'APPROVED');
      expect(approval['execution_authorized'], isTrue);

      final blockers = manifest['blocker_status'] as Map<String, dynamic>;
      expect(blockers['release_blocked'], isFalse);
      final openItems = (blockers['open_items'] as List<dynamic>)
          .cast<String>();
      expect(
        openItems,
        isNotEmpty,
        reason: 'open non-blocker items stay listed',
      );
      expect(
        openItems.join(' '),
        isNot(contains('REC-01')),
        reason:
            'REC-01 flag-matrix reconciliation closed 2026-09-23; resolved '
            'findings leave the open-item list but stay recorded in the '
            'reconciliation manifest and known_issues',
      );

      final rollback = manifest['rollback_readiness'] as Map<String, dynamic>;
      expect(rollback['ready'], isTrue);
      expect((rollback['basis'] as List<dynamic>).cast<String>(), isNotEmpty);

      final limits = (manifest['limits'] as List<dynamic>).cast<String>();
      expect(limits, isNotEmpty);
      expect(limits.join(' ').toLowerCase(), contains('public release'));
    });

    test('domain reports missing evidence by canonical name', () {
      final complete = <String, GaEvidenceRecord>{
        for (final name in GaApprovalGate.requiredEvidenceKeys)
          name: const GaEvidenceRecord(
            present: true,
            sources: <String>['docs/planning/v1.2/source.json'],
          ),
      };

      expect(GaApprovalGate.missingEvidence(null), isNotEmpty);
      expect(
        GaApprovalGate.missingEvidence(const GaApprovalGate()),
        unorderedEquals(GaApprovalGate.requiredEvidenceKeys),
      );

      final withHole = Map<String, GaEvidenceRecord>.from(complete)
        ..remove('known_issues')
        ..['signed_artifacts'] = const GaEvidenceRecord(
          present: false,
          sources: <String>['docs/release/v1.2.0-rc.1-checksums.txt'],
        )
        ..['blocker_status'] = const GaEvidenceRecord(
          present: true,
          sources: <String>[],
        );
      expect(
        GaApprovalGate.missingEvidence(GaApprovalGate(evidence: withHole)),
        unorderedEquals(<String>[
          'known_issues',
          'signed_artifacts',
          'blocker_status',
        ]),
      );

      expect(
        GaApprovalGate.missingEvidence(GaApprovalGate(evidence: complete)),
        isEmpty,
      );
    });

    test('evaluation blocks without a record and fails on incomplete data', () {
      expect(GaApprovalGate.evaluate(null).state, GaGateState.blocked);
      expect(
        GaApprovalGate.evaluate(const GaApprovalGate()).state,
        GaGateState.blocked,
      );

      final completeEvidence = <String, GaEvidenceRecord>{
        for (final name in GaApprovalGate.requiredEvidenceKeys)
          name: const GaEvidenceRecord(
            present: true,
            sources: <String>['docs/planning/v1.2/source.json'],
          ),
      };

      // One evidence group missing -> fail naming it.
      final hole = Map<String, GaEvidenceRecord>.from(completeEvidence)
        ..remove('rollback_readiness');
      final holeEval = GaApprovalGate.evaluate(
        GaApprovalGate(
          evidence: hole,
          decision: GaDecision.release,
          approval: GaApprovalState.approved,
          rollbackReady: true,
          releaseBlocked: false,
        ),
      );
      expect(holeEval.state, GaGateState.fail);
      expect(holeEval.notes.join(' '), contains('rollback_readiness'));

      // Structural fields absent -> fail naming the field.
      final structural = GaApprovalGate.evaluate(
        GaApprovalGate(evidence: completeEvidence),
      );
      expect(structural.state, GaGateState.fail);
      expect(structural.notes.join(' '), contains('decision'));
    });

    test(
      'release requires approval, clear blockers, and rollback readiness',
      () {
        final evidence = <String, GaEvidenceRecord>{
          for (final name in GaApprovalGate.requiredEvidenceKeys)
            name: const GaEvidenceRecord(
              present: true,
              sources: <String>['docs/planning/v1.2/source.json'],
            ),
        };

        GaApprovalGate gate({
          required GaDecision decision,
          required GaApprovalState approval,
          bool rollbackReady = true,
          bool releaseBlocked = false,
        }) => GaApprovalGate(
          evidence: evidence,
          decision: decision,
          approval: approval,
          rollbackReady: rollbackReady,
          releaseBlocked: releaseBlocked,
        );

        // Release without explicit approval -> fail naming the state.
        final pending = GaApprovalGate.evaluate(
          gate(
            decision: GaDecision.release,
            approval: GaApprovalState.pendingChoirudin,
          ),
        );
        expect(pending.state, GaGateState.fail);
        expect(pending.notes.join(' '), contains('PENDING_CHOIRUDIN'));

        // Release while blockers are active -> fail.
        final blocked = GaApprovalGate.evaluate(
          gate(
            decision: GaDecision.release,
            approval: GaApprovalState.approved,
            releaseBlocked: true,
          ),
        );
        expect(blocked.state, GaGateState.fail);
        expect(blocked.notes.join(' ').toLowerCase(), contains('blocker'));

        // Release without rollback readiness -> fail.
        final noRollback = GaApprovalGate.evaluate(
          gate(
            decision: GaDecision.release,
            approval: GaApprovalState.approved,
            rollbackReady: false,
          ),
        );
        expect(noRollback.state, GaGateState.fail);
        expect(noRollback.notes.join(' ').toLowerCase(), contains('rollback'));

        // Fully satisfied release -> pass with counts.
        final release = GaApprovalGate.evaluate(
          gate(
            decision: GaDecision.release,
            approval: GaApprovalState.approved,
          ),
        );
        expect(release.state, GaGateState.pass);
        expect(release.notes.join(' '), contains('evidence: 8'));
        expect(release.notes.join(' '), contains('decision: release'));
      },
    );

    test('defer passes while approval stays pending, cancel is recorded', () {
      final evidence = <String, GaEvidenceRecord>{
        for (final name in GaApprovalGate.requiredEvidenceKeys)
          name: const GaEvidenceRecord(
            present: true,
            sources: <String>['docs/planning/v1.2/source.json'],
          ),
      };

      final deferEval = GaApprovalGate.evaluate(
        GaApprovalGate(
          evidence: evidence,
          decision: GaDecision.defer,
          approval: GaApprovalState.pendingChoirudin,
          rollbackReady: true,
          releaseBlocked: false,
        ),
      );
      expect(deferEval.state, GaGateState.pass);
      expect(deferEval.notes.join(' '), contains('decision: defer'));
      expect(deferEval.notes.join(' '), contains('PENDING_CHOIRUDIN'));

      final cancelEval = GaApprovalGate.evaluate(
        GaApprovalGate(
          evidence: evidence,
          decision: GaDecision.cancel,
          approval: GaApprovalState.pendingChoirudin,
          rollbackReady: false,
          releaseBlocked: true,
        ),
      );
      expect(cancelEval.state, GaGateState.pass);
      expect(cancelEval.notes.join(' '), contains('decision: cancel'));
    });

    test(
      'manifest parses into the domain and evaluates to approved release-pass',
      () {
        final manifest =
            jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
        final gate = GaApprovalGate.fromManifest(manifest);
        expect(GaApprovalGate.missingEvidence(gate), isEmpty);
        expect(gate.decision, GaDecision.release);
        expect(gate.approval, GaApprovalState.approved);
        expect(gate.rollbackReady, isTrue);
        expect(gate.releaseBlocked, isFalse);

        final evaluation = GaApprovalGate.evaluate(gate);
        expect(evaluation.state, GaGateState.pass);
        expect(evaluation.notes.join(' '), contains('decision: release'));
        expect(evaluation.notes.join(' '), contains('approval: APPROVED'));

        // Approval is explicit and execution is authorized for the approved release.
        expect(manifest['approval']['execution_authorized'], isTrue);
      },
    );
  });
}
