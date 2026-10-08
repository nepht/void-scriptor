import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_maintenance_release_gate.dart';

/// A single maintenance-validation entry. Each test flips exactly the one thing
/// it is about, so a test that flips nothing proves the pass path exists and
/// every other test proves one way the gate refuses to take it.
Sprint118MaintenanceReleaseEntry _entry({
  String item = 'artifact',
  String referenceState = 'signed_artifacts',
  String source = Sprint118MaintenanceReleaseContract.packagingManifestPath,
  String detail =
      'The committed packaging manifest declares the signed artifact set while '
      'no artifact is built',
  List<String>? limitations,
  bool artifactBuilt = false,
  bool upgradeExecuted = false,
  bool rollbackExecuted = false,
  bool notesPublished = false,
  bool emergencyClaimed = false,
  bool observed = false,
}) {
  return Sprint118MaintenanceReleaseEntry(
    item: item,
    referenceState: referenceState,
    source: source,
    detail: detail,
    limitations: limitations ?? const <String>['synthetic_local'],
    artifactBuilt: artifactBuilt,
    upgradeExecuted: upgradeExecuted,
    rollbackExecuted: rollbackExecuted,
    notesPublished: notesPublished,
    emergencyClaimed: emergencyClaimed,
    observed: observed,
  );
}

Sprint118MaintenanceReleaseRecord _record({
  String releaseState = Sprint118MaintenanceReleaseContract.delayedReleaseState,
  Sprint118MaintenanceReleaseDecision selectedDecision =
      Sprint118MaintenanceReleaseDecision.noPatch,
  List<Sprint118MaintenanceReleaseEntry>? entries,
}) {
  return Sprint118MaintenanceReleaseRecord(
    releaseState: releaseState,
    selectedDecision: selectedDecision,
    entries:
        entries ?? Sprint118MaintenanceReleaseContract.canonicalRecord.entries,
  );
}

/// The canonical entries with exactly one validation domain replaced, so a test
/// can flip a single entry without rebuilding the whole record.
List<Sprint118MaintenanceReleaseEntry> _replacing(
  String item,
  Sprint118MaintenanceReleaseEntry replacement,
) {
  return <Sprint118MaintenanceReleaseEntry>[
    for (final e in Sprint118MaintenanceReleaseContract.canonicalRecord.entries)
      if (e.item == item) replacement else e,
  ];
}

Sprint118MaintenanceReleaseAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict =
      Sprint118MaintenanceReleaseContract.requiredBaselineVerdict,
  String releaseState = Sprint118MaintenanceReleaseContract.delayedReleaseState,
  String charterState = 'pass',
  String charterVerdict =
      Sprint118MaintenanceReleaseContract.requiredCharterVerdict,
  int charterWindowMinutes = 60480,
  String rolloutState = 'pass',
  String rolloutVerdict =
      Sprint118MaintenanceReleaseContract.requiredRolloutVerdict,
  String rolloutDecision = 'HOLD',
  String approvalDecision =
      Sprint118MaintenanceReleaseContract.requiredApprovalDecision,
  String approvalState = 'PENDING_CHOIRUDIN',
  bool executionAuthorized = false,
  bool releaseBlocked = true,
  int approvedFixCount = 0,
  bool emergencyReleaseRecorded = false,
  List<String>? maintenanceEvidence,
  List<String>? artifactOutputs,
  List<String>? packagingOutputs,
  List<String>? deferredChecks,
  List<String>? drillControls,
  List<String>? readableSources,
}) {
  return Sprint118MaintenanceReleaseAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    charterState: charterState,
    charterVerdict: charterVerdict,
    charterWindowMinutes: charterWindowMinutes,
    rolloutState: rolloutState,
    rolloutVerdict: rolloutVerdict,
    rolloutDecision: rolloutDecision,
    approvalDecision: approvalDecision,
    approvalState: approvalState,
    executionAuthorized: executionAuthorized,
    releaseBlocked: releaseBlocked,
    approvedFixCount: approvedFixCount,
    emergencyReleaseRecorded: emergencyReleaseRecorded,
    maintenanceEvidence:
        maintenanceEvidence ??
        const <String>[
          'approved_scope_or_no_patch',
          'test_results',
          'signed_artifact_if_needed',
          'upgrade_results',
          'rollback_results',
          'checksums',
          'release_notes',
        ],
    artifactOutputs:
        artifactOutputs ??
        const <String>[
          'signed_artifacts',
          'connector_manifest',
          'icon_manifest',
          'dependency_manifest',
          'schema_manifest',
          'flag_manifest',
          'checksums',
          'provenance',
        ],
    packagingOutputs:
        packagingOutputs ??
        const <String>[
          'signed_artifacts',
          'checksums',
          'version_manifest',
          'dependency_manifest',
          'licenses',
        ],
    deferredChecks:
        deferredChecks ??
        const <String>[
          'public_release_signing',
          'hosted_ci_validation',
          'live_production_telemetry',
          'published_artifact_validation',
          'upgrade_validation',
          'rollback_validation',
          'release_notes_publication',
          'publication',
        ],
    drillControls:
        drillControls ??
        const <String>[
          'kill_switch',
          'token_revoke',
          'queue_stop',
          'cache_handling',
          'artifact_rollback',
          'communication',
        ],
    readableSources:
        readableSources ??
        Sprint118MaintenanceReleaseContract.canonicalSources.toSet().toList(),
  );
}

Sprint118MaintenanceReleaseReport _run(
  Sprint118MaintenanceReleaseRecord record, {
  Sprint118MaintenanceReleaseAnchor? anchor,
}) {
  return const Sprint118MaintenanceReleaseGate().evaluateWith(
    anchor ?? _anchor(),
    record,
  );
}

void main() {
  group('Sprint 118.28 Maintenance Release Gate', () {
    test('the canonical decision vocabulary is the three options', () {
      expect(Sprint118MaintenanceReleaseContract.requiredDecisions, <String>[
        'BUILD_1_3_1',
        'NO_PATCH',
        'EMERGENCY_RELEASE_ALREADY_ISSUED',
      ]);
      for (final wire
          in Sprint118MaintenanceReleaseContract.requiredDecisions) {
        expect(
          Sprint118MaintenanceReleaseDecision.fromWire(wire)?.wireName,
          wire,
          reason: '$wire must round-trip through its exact wire name',
        );
      }
      expect(Sprint118MaintenanceReleaseDecision.fromWire('telepathy'), isNull);
      expect(Sprint118MaintenanceReleaseDecision.fromWire('no_patch'), isNull);
    });

    test('the canonical validation domains are the five objective items', () {
      expect(Sprint118MaintenanceReleaseContract.requiredValidations, <String>[
        'artifact',
        'upgrade',
        'rollback',
        'checksums',
        'notes',
      ]);
    });

    test(
      'the reference-state vocabulary is derived from committed witnesses',
      () {
        final vocabulary = Sprint118MaintenanceReleaseContract.stateVocabulary(
          <List<String>>[
            const <String>['signed_artifacts', 'checksums'],
            const <String>['artifact_rollback'],
          ],
        );
        expect(vocabulary, contains('signed_artifacts'));
        expect(vocabulary, contains('checksums'));
        expect(vocabulary, contains('artifact_rollback'));
        expect(
          vocabulary,
          contains(Sprint118MaintenanceReleaseContract.noReferenceState),
        );
        // A token only grounds when the witness names it exactly, or when every
        // underscore-separated part is itself a witness-declared value.
        expect(
          Sprint118MaintenanceReleaseContract.grounds(
            vocabulary,
            'signed_artifacts',
          ),
          isTrue,
        );
        expect(
          Sprint118MaintenanceReleaseContract.grounds(vocabulary, 'telepathy'),
          isFalse,
        );
        expect(
          Sprint118MaintenanceReleaseContract.grounds(const <String>[
            'release',
            'notes',
          ], 'release_notes'),
          isTrue,
        );
        expect(
          Sprint118MaintenanceReleaseContract.grounds(const <String>[
            'release',
          ], 'release_notes'),
          isFalse,
        );
      },
    );

    test(
      'canonical record covers the five validation domains and claims nothing '
      'live',
      () {
        final record = Sprint118MaintenanceReleaseContract.canonicalRecord;
        expect(record.entries.length, 5);
        expect(record.validationItems.toSet(), <String>{
          'artifact',
          'upgrade',
          'rollback',
          'checksums',
          'notes',
        });
        expect(
          record.selectedDecision,
          Sprint118MaintenanceReleaseDecision.noPatch,
        );
        for (final entry in record.entries) {
          expect(entry.artifactBuilt, isFalse);
          expect(entry.upgradeExecuted, isFalse);
          expect(entry.rollbackExecuted, isFalse);
          expect(entry.notesPublished, isFalse);
          expect(entry.emergencyClaimed, isFalse);
          expect(entry.observed, isFalse);
          expect(entry.limitations, isNotEmpty);
          for (final field
              in Sprint118MaintenanceReleaseContract.requiredFields) {
            expect(
              (entry.requiredFields[field] ?? '').trim(),
              isNotEmpty,
              reason: '${entry.item}.$field must not be blank',
            );
          }
        }
      },
    );

    test('passes on the canonical record and selects NO_PATCH', () {
      final report = _run(_record());
      expect(report.state, Sprint118MaintenanceReleaseState.pass);
      expect(report.verdict, 'MAINTENANCE_RELEASE_GATE_VERIFIED_LOCAL');
      expect(report.releaseVerified, isTrue);
      expect(report.selectedDecision, 'NO_PATCH');
      expect(report.declaredValidations.length, 5);
      expect(report.observedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      expect(report.openItems, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118MaintenanceReleaseGate().evaluateWith(
        null,
        _record(),
      );
      expect(report.state, Sprint118MaintenanceReleaseState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_MAINTENANCE_RELEASE_GATE_EVIDENCE_UNREADABLE',
      );
      expect(report.releaseVerified, isFalse);
      expect(
        report.blockers,
        contains('committed_maintenance_release_evidence_unreadable'),
      );
    });

    test('blocks when the committed baseline is not a frozen pass', () {
      final report = _run(
        _record(),
        anchor: _anchor(baselineVerdict: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118MaintenanceReleaseState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_MAINTENANCE_RELEASE_GATE_BLOCKED_UPSTREAM',
      );
      expect(report.blockers, contains('baseline_not_frozen:SOMETHING_ELSE'));
    });

    test('blocks when the committed charter is incomplete', () {
      final report = _run(_record(), anchor: _anchor(charterWindowMinutes: 0));
      expect(report.state, Sprint118MaintenanceReleaseState.blocked);
      expect(
        report.blockers,
        contains('charter_not_complete:CHARTER_COMPLETE_LOCAL'),
      );
    });

    test('blocks when the rollout progression decision is not verified', () {
      final report = _run(
        _record(),
        anchor: _anchor(rolloutVerdict: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118MaintenanceReleaseState.blocked);
      expect(
        report.blockers,
        contains('rollout_decision_not_verified:SOMETHING_ELSE'),
      );
    });

    test('blocks when the committed rollout decision is not HOLD', () {
      final report = _run(
        _record(),
        anchor: _anchor(rolloutDecision: 'EXPAND'),
      );
      expect(report.state, Sprint118MaintenanceReleaseState.blocked);
      expect(report.blockers, contains('rollout_decision_not_hold:EXPAND'));
    });

    test('blocks when the approval gate is not a delay', () {
      final report = _run(
        _record(),
        anchor: _anchor(approvalDecision: 'release'),
      );
      expect(report.state, Sprint118MaintenanceReleaseState.blocked);
      expect(report.blockers, contains('approval_gate_not_delay:release'));
    });

    test('fails when the record release state disagrees with the anchor', () {
      final report = _run(
        _record(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'GA_DELAYED'),
      );
      expect(report.state, Sprint118MaintenanceReleaseState.fail);
      expect(
        report.violations,
        contains('release_state_mismatch:anchor=GA_DELAYED:record=GA_RELEASED'),
      );
    });

    test('fails when a release is authorized on the delayed path', () {
      final report = _run(
        _record(),
        anchor: _anchor(executionAuthorized: true),
      );
      expect(report.state, Sprint118MaintenanceReleaseState.fail);
      expect(
        report.violations,
        contains('release_execution_authorized_on_delayed_path'),
      );
    });

    test('fails when the release is not blocked on the delayed path', () {
      final report = _run(_record(), anchor: _anchor(releaseBlocked: false));
      expect(report.state, Sprint118MaintenanceReleaseState.fail);
      expect(
        report.violations,
        contains('release_not_blocked_on_delayed_path'),
      );
    });

    test('fails when a canonical validation domain is missing', () {
      final report = _run(
        _record(
          entries: <Sprint118MaintenanceReleaseEntry>[
            for (final e
                in Sprint118MaintenanceReleaseContract.canonicalRecord.entries)
              if (e.item != 'checksums') e,
          ],
        ),
      );
      expect(report.state, Sprint118MaintenanceReleaseState.fail);
      expect(report.violations, contains('validation_missing:checksums'));
    });

    test('fails when a canonical validation domain is duplicated', () {
      final report = _run(
        _record(
          entries: <Sprint118MaintenanceReleaseEntry>[
            ...Sprint118MaintenanceReleaseContract.canonicalRecord.entries,
            _entry(item: 'notes', referenceState: 'release_notes'),
          ],
        ),
      );
      expect(report.state, Sprint118MaintenanceReleaseState.fail);
      expect(report.violations, contains('validation_duplicate:notes'));
    });

    test('fails when an unknown validation domain is invented', () {
      final report = _run(
        _record(
          entries: <Sprint118MaintenanceReleaseEntry>[
            ...Sprint118MaintenanceReleaseContract.canonicalRecord.entries,
            _entry(item: 'telepathy', referenceState: 'signed_artifacts'),
          ],
        ),
      );
      expect(report.state, Sprint118MaintenanceReleaseState.fail);
      expect(report.violations, contains('validation_unknown:telepathy'));
    });

    test('fails when a required entry field is blank', () {
      final report = _run(
        _record(
          entries: _replacing(
            'artifact',
            _entry(item: 'artifact', detail: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118MaintenanceReleaseState.fail);
      expect(report.violations, contains('entry_blank_detail:artifact'));
    });

    test('fails when a reference state is not grounded by a witness', () {
      final report = _run(
        _record(
          entries: _replacing(
            'artifact',
            _entry(item: 'artifact', referenceState: 'telepathy'),
          ),
        ),
      );
      expect(report.state, Sprint118MaintenanceReleaseState.fail);
      expect(report.violations, contains('reference_state_invalid:artifact'));
    });

    test(
      'records an open item when a reference state is the no-reference marker',
      () {
        final report = _run(
          _record(
            entries: _replacing(
              'artifact',
              _entry(
                item: 'artifact',
                referenceState:
                    Sprint118MaintenanceReleaseContract.noReferenceState,
              ),
            ),
          ),
        );
        expect(report.state, Sprint118MaintenanceReleaseState.pass);
        expect(
          report.openItems,
          contains('upstream_state_vocabulary_gap:artifact'),
        );
      },
    );

    test('fails when an entry source is not a readable committed source', () {
      final report = _run(
        _record(
          entries: _replacing(
            'artifact',
            _entry(item: 'artifact', source: 'docs/nope.json'),
          ),
        ),
      );
      expect(report.state, Sprint118MaintenanceReleaseState.fail);
      expect(report.violations, contains('source_unreadable:artifact'));
    });

    test('fails when an entry claims a built artifact', () {
      final report = _run(
        _record(
          entries: _replacing(
            'artifact',
            _entry(item: 'artifact', artifactBuilt: true),
          ),
        ),
      );
      expect(report.state, Sprint118MaintenanceReleaseState.fail);
      expect(
        report.violations,
        contains('artifact_built_without_release:artifact'),
      );
    });

    test('fails when an entry claims an executed upgrade', () {
      final report = _run(
        _record(
          entries: _replacing(
            'upgrade',
            _entry(
              item: 'upgrade',
              referenceState: 'upgrade_results',
              source: Sprint118MaintenanceReleaseContract
                  .maintenanceArtifactManifestPath,
              upgradeExecuted: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118MaintenanceReleaseState.fail);
      expect(
        report.violations,
        contains('upgrade_executed_without_release:upgrade'),
      );
    });

    test('fails when an entry claims an executed rollback', () {
      final report = _run(
        _record(
          entries: _replacing(
            'rollback',
            _entry(
              item: 'rollback',
              referenceState: 'artifact_rollback',
              source:
                  Sprint118MaintenanceReleaseContract.rollbackDrillManifestPath,
              rollbackExecuted: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118MaintenanceReleaseState.fail);
      expect(
        report.violations,
        contains('rollback_executed_without_release:rollback'),
      );
    });

    test('fails when an entry claims a published release note', () {
      final report = _run(
        _record(
          entries: _replacing(
            'notes',
            _entry(
              item: 'notes',
              referenceState: 'release_notes',
              source: Sprint118MaintenanceReleaseContract
                  .maintenanceScopeManifestPath,
              notesPublished: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118MaintenanceReleaseState.fail);
      expect(
        report.violations,
        contains('release_notes_published_without_release:notes'),
      );
    });

    test('fails when an entry claims an emergency release', () {
      final report = _run(
        _record(
          entries: _replacing(
            'artifact',
            _entry(item: 'artifact', emergencyClaimed: true),
          ),
        ),
      );
      expect(report.state, Sprint118MaintenanceReleaseState.fail);
      expect(
        report.violations,
        contains('emergency_release_claimed_without_record:artifact'),
      );
    });

    test('fails when an entry claims a live validation', () {
      final report = _run(
        _record(
          entries: _replacing(
            'checksums',
            _entry(
              item: 'checksums',
              referenceState: 'checksums',
              source: Sprint118MaintenanceReleaseContract
                  .artifactEvidenceManifestPath,
              observed: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118MaintenanceReleaseState.fail);
      expect(report.violations, contains('live_validation_claimed:checksums'));
    });

    test(
      'fails when BUILD_1_3_1 is selected without an approved fix scope',
      () {
        final report = _run(
          _record(
            selectedDecision: Sprint118MaintenanceReleaseDecision.build131,
          ),
        );
        expect(report.state, Sprint118MaintenanceReleaseState.fail);
        expect(
          report.violations,
          contains(
            'maintenance_release_without_approved_fix_scope:BUILD_1_3_1',
          ),
        );
      },
    );

    test(
      'fails when BUILD_1_3_1 is selected without an authorized release',
      () {
        final report = _run(
          _record(
            selectedDecision: Sprint118MaintenanceReleaseDecision.build131,
          ),
          anchor: _anchor(approvedFixCount: 2),
        );
        expect(report.state, Sprint118MaintenanceReleaseState.fail);
        expect(
          report.violations,
          contains('build_without_release:BUILD_1_3_1'),
        );
      },
    );

    test(
      'fails when an emergency release is claimed without a recorded emergency',
      () {
        final report = _run(
          _record(
            selectedDecision: Sprint118MaintenanceReleaseDecision
                .emergencyReleaseAlreadyIssued,
          ),
        );
        expect(report.state, Sprint118MaintenanceReleaseState.fail);
        expect(
          report.violations,
          contains(
            'emergency_release_without_record:'
            'EMERGENCY_RELEASE_ALREADY_ISSUED',
          ),
        );
      },
    );

    test('passes when BUILD_1_3_1 is selected with an approved fix and an '
        'authorized release', () {
      // The other direction: once an approved fix requires a patch and the
      // release is authorized, the gate is willing to record BUILD_1_3_1. An
      // authorized release is only refused on the delayed path, so both the
      // anchor and the record must leave GA_DELAYED for this to be coherent.
      final report = _run(
        _record(
          releaseState: 'GA_RELEASED',
          selectedDecision: Sprint118MaintenanceReleaseDecision.build131,
        ),
        anchor: _anchor(
          releaseState: 'GA_RELEASED',
          executionAuthorized: true,
          approvedFixCount: 1,
        ),
      );
      expect(report.state, Sprint118MaintenanceReleaseState.pass);
      expect(report.selectedDecision, 'BUILD_1_3_1');
    });

    test('passes when an emergency release is already issued and recorded', () {
      final report = _run(
        _record(
          releaseState: 'GA_RELEASED',
          selectedDecision:
              Sprint118MaintenanceReleaseDecision.emergencyReleaseAlreadyIssued,
        ),
        anchor: _anchor(
          releaseState: 'GA_RELEASED',
          executionAuthorized: true,
          approvedFixCount: 1,
          emergencyReleaseRecorded: true,
        ),
      );
      expect(report.state, Sprint118MaintenanceReleaseState.pass);
      expect(report.selectedDecision, 'EMERGENCY_RELEASE_ALREADY_ISSUED');
    });

    test('fails when a required evidence source is unreadable', () {
      final report = _run(
        _record(),
        anchor: _anchor(
          readableSources: <String>[
            Sprint118MaintenanceReleaseContract.packagingManifestPath,
          ],
        ),
      );
      expect(report.state, Sprint118MaintenanceReleaseState.fail);
      expect(
        report.violations,
        contains(
          'required_source_unreadable:'
          'docs/planning/v1.2/sprint_114_maintenance_artifact_release_gate.json',
        ),
      );
    });

    test('the loader reads the committed witnesses on disk', () {
      final anchor = const Sprint118MaintenanceReleaseLoader().loadAnchor();
      expect(anchor, isNotNull);
      expect(anchor!.baselineState, 'pass');
      expect(
        anchor.baselineVerdict,
        'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL',
      );
      expect(anchor.charterVerdict, 'CHARTER_COMPLETE_LOCAL');
      expect(anchor.charterWindowMinutes, 60480);
      expect(
        anchor.rolloutVerdict,
        'ROLLOUT_PROGRESSION_DECISION_VERIFIED_LOCAL',
      );
      expect(anchor.rolloutDecision, 'HOLD');
      expect(anchor.approvalDecision, 'delay');
      expect(anchor.approvalState, 'PENDING_CHOIRUDIN');
      expect(anchor.executionAuthorized, isFalse);
      expect(anchor.releaseBlocked, isTrue);
      expect(anchor.approvedFixCount, 0);
      expect(anchor.emergencyReleaseRecorded, isFalse);
      expect(anchor.readableSources.length, 9);
    });

    test('the gate evaluates the committed record to a pass on NO_PATCH', () {
      final report = const Sprint118MaintenanceReleaseGate().evaluate();
      expect(report.state, Sprint118MaintenanceReleaseState.pass);
      expect(report.selectedDecision, 'NO_PATCH');
      expect(report.releaseState, 'GA_DELAYED');
      expect(report.observedCount, 0);
    });
  });
}
