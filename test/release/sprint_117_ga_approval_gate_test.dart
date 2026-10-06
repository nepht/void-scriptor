// 117.45 — GA Approval Gate.
//
// The gate decides release, delay, subset reduction, or rollback from eight
// canonical beta-evidence groups plus rollback readiness. Writing the record
// is not approval: a release decision additionally requires Choirudin's
// explicit approval, no active release blockers, and confirmed rollback
// readiness. Sprint 117's committed evidence forces a delay.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_ga_approval_gate.dart';

void main() {
  final manifestFile = File(
    'docs/planning/v1.3/sprint_117_ga_approval_gate.json',
  );

  group('117.45 GA approval gate', () {
    test('declares the eight canonical evidence keys in contract order', () {
      expect(Sprint117GaApprovalGate.requiredEvidenceKeys, <String>[
        'beta_results',
        'connector_registry',
        'blocker_status',
        'quality_gates',
        'known_limits',
        'signed_artifacts',
        'rollout_plan',
        'rollback_readiness',
      ]);
      expect(Sprint117GaApprovalGate.requiredEvidenceKeys.toSet().length, 8);
      expect(Sprint117GaApprovalGate.canonicalStep, '117.45');
    });

    test('planning manifest records the gate with sources on disk', () {
      expect(
        manifestFile.existsSync(),
        isTrue,
        reason:
            'missing docs/planning/v1.3/sprint_117_ga_approval_gate.json',
      );
      final manifest =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      expect(manifest['canonical_step'], '117.45');
      expect(manifest['status'], 'VERIFIED-LOCAL');
      expect(manifest['version'], '1.3.0-beta.1');

      final evidence = manifest['required_evidence'] as Map<String, dynamic>;
      expect(
        evidence.keys.toSet(),
        Sprint117GaApprovalGate.requiredEvidenceKeys.toSet(),
      );
      for (final name in Sprint117GaApprovalGate.requiredEvidenceKeys) {
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

      // The recorded outcome is a delay awaiting Choirudin's decision.
      expect(manifest['decision'], 'DELAY');
      final approval = manifest['approval'] as Map<String, dynamic>;
      expect(approval['decision'], 'delay');
      expect(approval['approval_state'], 'PENDING_CHOIRUDIN');
      expect(approval['execution_authorized'], isFalse);

      final blockers = manifest['blocker_status'] as Map<String, dynamic>;
      expect(blockers['release_blocked'], isTrue);
      final openItems = (blockers['open_items'] as List<dynamic>)
          .cast<String>();
      expect(
        openItems,
        isNotEmpty,
        reason: 'the blocking items that force a delay stay listed',
      );
      expect(
        openItems.join(' '),
        contains('117.41'),
        reason: 'zero certified connectors is the primary release blocker',
      );

      final rollback = manifest['rollback_readiness'] as Map<String, dynamic>;
      expect(rollback['ready'], isTrue);
      expect((rollback['basis'] as List<dynamic>).cast<String>(), isNotEmpty);

      final limits = (manifest['limits'] as List<dynamic>).cast<String>();
      expect(limits, isNotEmpty);
      expect(limits.join(' ').toLowerCase(), contains('release'));
    });

    test('domain reports missing evidence by canonical name', () {
      final complete = <String, Sprint117GaEvidenceRecord>{
        for (final name in Sprint117GaApprovalGate.requiredEvidenceKeys)
          name: const Sprint117GaEvidenceRecord(
            present: true,
            sources: <String>['docs/planning/v1.3/source.json'],
          ),
      };

      expect(Sprint117GaApprovalGate.missingEvidence(null), isNotEmpty);
      expect(
        Sprint117GaApprovalGate.missingEvidence(const Sprint117GaApprovalGate()),
        unorderedEquals(Sprint117GaApprovalGate.requiredEvidenceKeys),
      );

      final withHole = Map<String, Sprint117GaEvidenceRecord>.from(complete)
        ..remove('known_limits')
        ..['signed_artifacts'] = const Sprint117GaEvidenceRecord(
          present: false,
          sources: <String>['docs/release/v1.2.0-rc.1-checksums.txt'],
        )
        ..['blocker_status'] = const Sprint117GaEvidenceRecord(
          present: true,
          sources: <String>[],
        );
      expect(
        Sprint117GaApprovalGate.missingEvidence(
          Sprint117GaApprovalGate(evidence: withHole),
        ),
        unorderedEquals(<String>[
          'known_limits',
          'signed_artifacts',
          'blocker_status',
        ]),
      );

      expect(
        Sprint117GaApprovalGate.missingEvidence(
          Sprint117GaApprovalGate(evidence: complete),
        ),
        isEmpty,
      );
    });

    test('evaluation blocks without a record and fails on incomplete data', () {
      expect(
        Sprint117GaApprovalGate.evaluate(null).state,
        Sprint117GaGateState.blocked,
      );
      expect(
        Sprint117GaApprovalGate.evaluate(const Sprint117GaApprovalGate()).state,
        Sprint117GaGateState.blocked,
      );

      final completeEvidence = <String, Sprint117GaEvidenceRecord>{
        for (final name in Sprint117GaApprovalGate.requiredEvidenceKeys)
          name: const Sprint117GaEvidenceRecord(
            present: true,
            sources: <String>['docs/planning/v1.3/source.json'],
          ),
      };

      // One evidence group missing -> fail naming it.
      final hole = Map<String, Sprint117GaEvidenceRecord>.from(completeEvidence)
        ..remove('rollback_readiness');
      final holeEval = Sprint117GaApprovalGate.evaluate(
        Sprint117GaApprovalGate(
          evidence: hole,
          decision: Sprint117GaDecision.release,
          approval: Sprint117GaApprovalState.approved,
          rollbackReady: true,
          releaseBlocked: false,
        ),
      );
      expect(holeEval.state, Sprint117GaGateState.fail);
      expect(holeEval.notes.join(' '), contains('rollback_readiness'));

      // Structural fields absent -> fail naming the field.
      final structural = Sprint117GaApprovalGate.evaluate(
        Sprint117GaApprovalGate(evidence: completeEvidence),
      );
      expect(structural.state, Sprint117GaGateState.fail);
      expect(structural.notes.join(' '), contains('decision'));
    });

    test(
      'release requires approval, clear blockers, and rollback readiness',
      () {
        final evidence = <String, Sprint117GaEvidenceRecord>{
          for (final name in Sprint117GaApprovalGate.requiredEvidenceKeys)
            name: const Sprint117GaEvidenceRecord(
              present: true,
              sources: <String>['docs/planning/v1.3/source.json'],
            ),
        };

        Sprint117GaApprovalGate gate({
          required Sprint117GaDecision decision,
          required Sprint117GaApprovalState approval,
          bool rollbackReady = true,
          bool releaseBlocked = false,
        }) => Sprint117GaApprovalGate(
          evidence: evidence,
          decision: decision,
          approval: approval,
          rollbackReady: rollbackReady,
          releaseBlocked: releaseBlocked,
        );

        // Release without explicit approval -> fail naming the state.
        final pending = Sprint117GaApprovalGate.evaluate(
          gate(
            decision: Sprint117GaDecision.release,
            approval: Sprint117GaApprovalState.pendingChoirudin,
          ),
        );
        expect(pending.state, Sprint117GaGateState.fail);
        expect(pending.notes.join(' '), contains('PENDING_CHOIRUDIN'));

        // Release while blockers are active -> fail.
        final blocked = Sprint117GaApprovalGate.evaluate(
          gate(
            decision: Sprint117GaDecision.release,
            approval: Sprint117GaApprovalState.approved,
            releaseBlocked: true,
          ),
        );
        expect(blocked.state, Sprint117GaGateState.fail);
        expect(blocked.notes.join(' ').toLowerCase(), contains('blocker'));

        // Release without rollback readiness -> fail.
        final noRollback = Sprint117GaApprovalGate.evaluate(
          gate(
            decision: Sprint117GaDecision.release,
            approval: Sprint117GaApprovalState.approved,
            rollbackReady: false,
          ),
        );
        expect(noRollback.state, Sprint117GaGateState.fail);
        expect(noRollback.notes.join(' ').toLowerCase(), contains('rollback'));

        // Fully satisfied release -> pass with counts.
        final release = Sprint117GaApprovalGate.evaluate(
          gate(
            decision: Sprint117GaDecision.release,
            approval: Sprint117GaApprovalState.approved,
          ),
        );
        expect(release.state, Sprint117GaGateState.pass);
        expect(release.notes.join(' '), contains('evidence: 8'));
        expect(release.notes.join(' '), contains('decision: release'));
      },
    );

    test(
      'delay passes while approval stays pending; subset reduction and '
      'rollback are recorded',
      () {
        final evidence = <String, Sprint117GaEvidenceRecord>{
          for (final name in Sprint117GaApprovalGate.requiredEvidenceKeys)
            name: const Sprint117GaEvidenceRecord(
              present: true,
              sources: <String>['docs/planning/v1.3/source.json'],
            ),
        };

        final delayEval = Sprint117GaApprovalGate.evaluate(
          Sprint117GaApprovalGate(
            evidence: evidence,
            decision: Sprint117GaDecision.delay,
            approval: Sprint117GaApprovalState.pendingChoirudin,
            rollbackReady: true,
            releaseBlocked: true,
          ),
        );
        expect(delayEval.state, Sprint117GaGateState.pass);
        expect(delayEval.notes.join(' '), contains('decision: delay'));
        expect(delayEval.notes.join(' '), contains('PENDING_CHOIRUDIN'));

        final subsetEval = Sprint117GaApprovalGate.evaluate(
          Sprint117GaApprovalGate(
            evidence: evidence,
            decision: Sprint117GaDecision.subsetReduction,
            approval: Sprint117GaApprovalState.pendingChoirudin,
            rollbackReady: true,
            releaseBlocked: false,
          ),
        );
        expect(subsetEval.state, Sprint117GaGateState.pass);
        expect(
          subsetEval.notes.join(' '),
          contains('decision: subset_reduction'),
        );

        final rollbackEval = Sprint117GaApprovalGate.evaluate(
          Sprint117GaApprovalGate(
            evidence: evidence,
            decision: Sprint117GaDecision.rollback,
            approval: Sprint117GaApprovalState.pendingChoirudin,
            rollbackReady: false,
            releaseBlocked: true,
          ),
        );
        expect(rollbackEval.state, Sprint117GaGateState.pass);
        expect(rollbackEval.notes.join(' '), contains('decision: rollback'));
      },
    );

    test('manifest parses into the domain and evaluates to delay-pass', () {
      final manifest =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      final gate = Sprint117GaApprovalGate.fromManifest(manifest);
      expect(Sprint117GaApprovalGate.missingEvidence(gate), isEmpty);
      expect(gate.decision, Sprint117GaDecision.delay);
      expect(gate.approval, Sprint117GaApprovalState.pendingChoirudin);
      expect(gate.rollbackReady, isTrue);
      expect(gate.releaseBlocked, isTrue);

      final evaluation = Sprint117GaApprovalGate.evaluate(gate);
      expect(evaluation.state, Sprint117GaGateState.pass);
      expect(evaluation.notes.join(' '), contains('decision: delay'));
      expect(evaluation.notes.join(' '), contains('approval: PENDING_CHOIRUDIN'));

      // Execution is not authorized for a delayed record.
      expect(manifest['approval']['execution_authorized'], isFalse);
    });
  });
}
