import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_entry_gate.dart';

/// Synthetic evidence builder. Defaults describe a *fully satisfied* world so
/// each test can flip exactly the field it is about; a test that never flips
/// anything proves the pass path exists, and every other test proves one way
/// the gate refuses to take it.
Sprint118EntryEvidence _evidence({
  String approvalDecision = 'RELEASED',
  String? closureDecision,
  String approvalState = 'APPROVED',
  bool executionAuthorized = true,
  String releaseDecisionOwner = 'CHOIRUDIN',
  int certifiedCount = 3,
  int limitedCount = 0,
  int providerCount = 32,
  bool? correctiveScopeApproved = true,
  bool observationWindowActive = true,
  String artifactVersion = '1.3.0',
  List<String> knownIssues = const <String>[],
  bool rollbackExecuted = false,
}) {
  return Sprint118EntryEvidence(
    approvalDecision: approvalDecision,
    closureDecision: closureDecision ?? approvalDecision,
    approvalState: approvalState,
    executionAuthorized: executionAuthorized,
    releaseDecisionOwner: releaseDecisionOwner,
    certifiedCount: certifiedCount,
    limitedCount: limitedCount,
    providerCount: providerCount,
    correctiveScopeApproved: correctiveScopeApproved,
    observationWindowActive: observationWindowActive,
    artifactVersion: artifactVersion,
    knownIssues: knownIssues,
    rollbackExecuted: rollbackExecuted,
  );
}

void main() {
  group('118.1 Sprint Entry & Release-State Gate', () {
    test('declares the canonical evidence and source boundaries', () {
      expect(Sprint118EntryContract.canonicalStep, '118.1');
      expect(
        Sprint118EntryContract.manifestPath,
        'docs/planning/v1.3/sprint_118_entry_gate.json',
      );
      expect(Sprint118EntryContract.requiredEvidence, <String>[
        'sprint_117_decision',
        'release_state',
        'artifact_version',
        'visible_connector_subset',
        'known_issues',
        'rollback_state',
      ]);
      expect(
        Sprint118EntryContract.requiredSources,
        containsAll(<String>[
          Sprint118EntryContract.approvalGatePath,
          Sprint118EntryContract.closurePath,
          Sprint118EntryContract.registryPath,
          Sprint118EntryContract.handoffPath,
          Sprint118EntryContract.rollbackDrillPath,
        ]),
      );
      // The corrective scope is the gate for a delayed release; its path must
      // be declared even though the file is currently absent.
      expect(
        Sprint118EntryContract.correctiveScopePath,
        'docs/planning/v1.3/sprint_118_corrective_scope_approval.json',
      );
      expect(Sprint118EntryContract.baseVersion, '1.3.0');
    });

    test('release-state vocabulary maps words, never optimistically', () {
      expect(
        Sprint118EntryContract.releaseStateFromText('RELEASED'),
        Sprint118ReleaseState.gaReleased,
      );
      expect(
        Sprint118EntryContract.releaseStateFromText('ga_released'),
        Sprint118ReleaseState.gaReleased,
      );
      expect(
        Sprint118EntryContract.releaseStateFromText('DELAY'),
        Sprint118ReleaseState.gaDelayed,
      );
      expect(
        Sprint118EntryContract.releaseStateFromText('delayed'),
        Sprint118ReleaseState.gaDelayed,
      );
      expect(
        Sprint118EntryContract.releaseStateFromText('ROLLED_BACK'),
        Sprint118ReleaseState.rolledBack,
      );
      // An unknown word is undetermined -- never a release.
      expect(
        Sprint118EntryContract.releaseStateFromText('SHIP_IT'),
        Sprint118ReleaseState.undetermined,
      );
      expect(Sprint118EntryContract.isKnownDecision('SHIP_IT'), isFalse);
      expect(Sprint118EntryContract.isKnownDecision('RELEASED'), isTrue);
      expect(
        Sprint118EntryContract.releaseStateWord(
          Sprint118ReleaseState.gaDelayed,
        ),
        'GA_DELAYED',
      );
    });

    test(
      'committed witnesses are present and open the approved delayed path',
      () {
        // Every source the contract declares must exist on disk, or the gate is
        // blocked for the wrong reason.
        for (final source in Sprint118EntryContract.requiredSources) {
          expect(File(source).existsSync(), isTrue, reason: 'Missing $source');
        }

        final report = const Sprint118EntryGate().evaluate();

        // The delayed corrective path is now explicitly approved. It is allowed
        // to start local corrective work without pretending that a connector was
        // certified or that a GA release was authorised.
        expect(report.state, Sprint118EntryState.pass);
        expect(report.verdict, 'SPRINT_118_ENTRY_READY');
        expect(report.releaseState, Sprint118ReleaseState.gaDelayed);
        expect(report.releaseStateWord, 'GA_DELAYED');
        expect(report.executionAllowed, isTrue);
        expect(report.violations, isEmpty);
        expect(report.blockers, isEmpty);
      },
    );

    test('the committed record agrees with the gate that produced it', () {
      final record =
          jsonDecode(
                File(Sprint118EntryContract.manifestPath).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final report = const Sprint118EntryGate().evaluate();

      expect(record['canonical_step'], '118.1');
      expect(record['state'], report.state.name);
      expect(record['verdict'], report.verdict);
      expect(record['release_state'], report.releaseStateWord);
      expect(record['execution_allowed'], report.executionAllowed);
      expect(
        record['required_evidence'],
        Sprint118EntryContract.requiredEvidence,
      );
      // Facts in the record must match what the loader read, not a retyped
      // copy: the record cannot agree with itself.
      final evidence = const Sprint118EntryLoader().load();
      expect(evidence, isNotNull);
      expect(record['approval_decision'], evidence!.approvalDecision);
      expect(record['closure_decision'], evidence.closureDecision);
      expect(record['certified_count'], evidence.certifiedCount);
      expect(record['provider_count'], evidence.providerCount);
      expect(
        record['corrective_scope_approved'],
        evidence.correctiveScopeApproved,
      );
    });

    test('unreadable evidence blocks and names every required item', () {
      final report = const Sprint118EntryGate().evaluateWith(null);

      expect(report.state, Sprint118EntryState.blocked);
      expect(report.verdict, 'SPRINT_118_ENTRY_EVIDENCE_UNREADABLE');
      expect(report.releaseState, Sprint118ReleaseState.undetermined);
      expect(report.executionAllowed, isFalse);
      expect(report.missingEvidence, Sprint118EntryContract.requiredEvidence);
    });

    test('a fully satisfied release opens the gate', () {
      final report = const Sprint118EntryGate().evaluateWith(_evidence());

      expect(report.state, Sprint118EntryState.pass);
      expect(report.verdict, 'SPRINT_118_ENTRY_READY');
      expect(report.releaseState, Sprint118ReleaseState.gaReleased);
      expect(report.executionAllowed, isTrue);
      expect(report.blockers, isEmpty);
      expect(report.violations, isEmpty);
    });

    test('disagreeing decision sources fail rather than pick one', () {
      final report = const Sprint118EntryGate().evaluateWith(
        _evidence(approvalDecision: 'RELEASED', closureDecision: 'DELAY'),
      );

      expect(report.state, Sprint118EntryState.fail);
      expect(report.verdict, 'SPRINT_118_ENTRY_EVIDENCE_VIOLATION');
      expect(
        report.violations,
        contains('decision_source_disagreement:RELEASED:DELAY'),
      );
    });

    test('an unknown decision word is drift and fails', () {
      final report = const Sprint118EntryGate().evaluateWith(
        _evidence(approvalDecision: 'SHIP_IT', closureDecision: 'SHIP_IT'),
      );

      expect(report.state, Sprint118EntryState.fail);
      expect(report.violations, contains('unknown_release_decision:SHIP_IT'));
      expect(report.releaseState, Sprint118ReleaseState.undetermined);
    });

    test(
      'a delayed release never opens without an approved corrective scope',
      () {
        // Everything else is satisfied, but the corrective scope is absent
        // (null) -- undetermined, never permission.
        final noScope = const Sprint118EntryGate().evaluateWith(
          _evidence(approvalDecision: 'DELAY', correctiveScopeApproved: null),
        );
        final scopeRefused = const Sprint118EntryGate().evaluateWith(
          _evidence(approvalDecision: 'DELAY', correctiveScopeApproved: false),
        );

        for (final report in <Sprint118EntryReport>[noScope, scopeRefused]) {
          expect(report.state, Sprint118EntryState.blocked);
          expect(report.releaseState, Sprint118ReleaseState.gaDelayed);
          expect(report.blockers, contains('corrective_scope_not_approved'));
        }
      },
    );

    test(
      'a delayed release with approved scope opens local corrective work',
      () {
        // Corrective validation is the documented GA_DELAYED path. Connector
        // certification is deferred until a later release decision.
        final report = const Sprint118EntryGate().evaluateWith(
          _evidence(
            approvalDecision: 'DELAY',
            certifiedCount: 0,
            limitedCount: 0,
            executionAuthorized: false,
            approvalState: 'PENDING_CHOIRUDIN',
          ),
        );

        expect(report.state, Sprint118EntryState.pass);
        expect(report.verdict, 'SPRINT_118_ENTRY_READY');
        expect(report.executionAllowed, isTrue);
        expect(report.blockers, isEmpty);
      },
    );

    test('no certified connector and pending approval block a release too', () {
      final report = const Sprint118EntryGate().evaluateWith(
        _evidence(
          certifiedCount: 0,
          executionAuthorized: false,
          approvalState: 'PENDING_CHOIRUDIN',
        ),
      );

      expect(report.state, Sprint118EntryState.blocked);
      expect(report.blockers, contains('no_certified_or_limited_connector'));
      expect(
        report.blockers,
        contains('execution_authorization_pending:PENDING_CHOIRUDIN'),
      );
    });

    test('a released decision without an active observation window blocks', () {
      final report = const Sprint118EntryGate().evaluateWith(
        _evidence(observationWindowActive: false),
      );

      expect(report.state, Sprint118EntryState.blocked);
      expect(report.blockers, contains('observation_window_not_active'));
    });

    test('a rolled-back release blocks the sprint', () {
      final report = const Sprint118EntryGate().evaluateWith(
        _evidence(approvalDecision: 'ROLLED_BACK'),
      );

      expect(report.state, Sprint118EntryState.blocked);
      expect(report.releaseState, Sprint118ReleaseState.rolledBack);
      expect(report.blockers, contains('release_rolled_back'));
      expect(report.executionAllowed, isFalse);
    });
  });
}
