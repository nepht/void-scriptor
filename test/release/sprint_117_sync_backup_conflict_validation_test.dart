/// Canonical step 117.14 — Sync, Backup & Conflict Validation.
///
/// Objective (external canonical JSON): test transfer, delta, retry, resume,
/// encrypted backup, restore, conflicts, large assets, and workspace
/// boundaries.
///
/// The eight evidence names are properties of state a user can lose, so this
/// test is the place that has to say plainly what ships and what does not. The
/// shipped code is a set of local domain contracts plus two filesystem-backed
/// services: `FolderCloudSyncService` round-trips a whole project map through
/// one JSON file, and there is no delta protocol, no chunked or streamed
/// transfer, and no encrypted-archive writer anywhere in `lib/`. The check and
/// the drill are therefore deliberately separate classes, and every acceptance
/// shipped code cannot satisfy is recorded as `acceptance_unmet` with the exact
/// reason, never folded into a pass.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_sync_backup_conflict_validation.dart';

void main() {
  const step = Sprint117SyncBackupConflictContract.canonicalStep;

  group('contract surface', () {
    test('covers the eight canonical checks in canonical order', () {
      expect(Sprint117SyncBackupConflictContract.requiredChecks, <String>[
        'transfer',
        'delta',
        'retry_resume',
        'encrypted_backup',
        'restore',
        'conflicts',
        'large_assets',
        'workspace_boundaries',
      ]);
    });

    test('declares the canonical step as 117.14', () {
      expect(step, '117.14');
    });

    test('every source manifest it depends on is committed', () {
      for (final path in Sprint117SyncBackupConflictContract.sourceManifests) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'source manifest must be committed: $path',
        );
      }
    });

    test('drills the backup-before-resolution and consent acceptances the '
        'sources declare', () {
      final anchor = const Sprint117SyncBackupConflictLoader().load().anchor!;
      expect(anchor.backupBeforeResolutionDeclared, isTrue);
      expect(anchor.explicitConsentDeclared, isTrue);
      expect(
        Sprint117SyncBackupConflictContract.backupBeforeResolutionAcceptance,
        'backup_before_resolution',
      );
      expect(
        Sprint117SyncBackupConflictContract.explicitConsentAcceptance,
        'explicit_transfer_consent',
      );
    });

    test('every source manifest states where its own evidence stops', () {
      final anchor = const Sprint117SyncBackupConflictLoader().load().anchor;
      expect(anchor, isNotNull);
      for (final entry in anchor!.boundariesDeclared.entries) {
        expect(
          entry.value,
          isTrue,
          reason: 'source must declare a boundary: ${entry.key}',
        );
      }
    });
  });

  group('external pins', () {
    test('resolves and matches every external spec it pins', () {
      final anchor = const Sprint117SyncBackupConflictLoader().load().anchor;
      expect(anchor, isNotNull);
      expect(
        anchor!.externalPinsResolved,
        isTrue,
        reason:
            'all external pins must be readable to prove anything from them',
      );
      expect(
        anchor.allExternalPinsMatch,
        isTrue,
        reason: 'external source drift invalidates every decision from it',
      );
      expect(anchor.externalPinsChecked, 3);
    });
  });

  group('loader', () {
    test('maps every canonical check to a declared source contract', () {
      final input = const Sprint117SyncBackupConflictLoader().load();
      expect(input.anchor, isNotNull);
      final ids = input.rows!.map((row) => row.checkId).toList();
      expect(ids, Sprint117SyncBackupConflictContract.requiredChecks);
      for (final row in input.rows!) {
        expect(row.method, isNotEmpty, reason: row.checkId);
        expect(row.expectedOutcome, isNotEmpty, reason: row.checkId);
        expect(row.sourceManifest, isNotEmpty, reason: row.checkId);
      }
    });

    test('never claims a live provider result for any check', () {
      final input = const Sprint117SyncBackupConflictLoader().load();
      for (final row in input.rows!) {
        expect(row.liveProviderResult, isFalse, reason: row.checkId);
        expect(row.drilledAgainstLiveProvider, isFalse, reason: row.checkId);
      }
    });

    test('leaves every check undetermined before a drill has run', () {
      final input = const Sprint117SyncBackupConflictLoader().load();
      for (final row in input.rows!) {
        expect(row.executed, isFalse, reason: row.checkId);
        expect(row.observedOutcome, isNull, reason: row.checkId);
      }
    });
  });

  group('drill — transfer', () {
    test('refuses a cross-scope transfer without explicit consent', () async {
      final run = await const Sprint117SyncBackupConflictDrill().run();
      final transfer = run.observationFor('transfer')!;
      expect(transfer.passed, isTrue, reason: transfer.outcome);
      expect(transfer.facts['refused_without_consent'], isTrue);
      expect(transfer.facts['refusal_error'], 'ArgumentError');
      expect(transfer.facts['same_scope_requires_consent'], isFalse);
      expect(transfer.facts['consented_request_has_consent'], isTrue);
    });

    test(
      'marks a consented transfer resumable and refuses bad input',
      () async {
        final run = await const Sprint117SyncBackupConflictDrill().run();
        final transfer = run.observationFor('transfer')!;
        expect(transfer.facts['consented_request_is_resumable'], isTrue);
        expect(transfer.facts['negative_total_bytes_refused'], isTrue);
        expect(transfer.facts['negative_total_bytes_error'], 'ArgumentError');
      },
    );
  });

  group('drill — delta', () {
    test('computes exactly the changed keys a delta would carry', () async {
      final run = await const Sprint117SyncBackupConflictDrill().run();
      final delta = run.observationFor('delta')!;
      expect(delta.passed, isTrue, reason: delta.outcome);
      expect(delta.facts['total_keys'], 4);
      expect(delta.facts['changed_keys'], 2);
      expect(delta.facts['changed_key_ids'], <String>['chapter:2', 'scene:1']);
      expect(delta.facts['full_resend_keys'], 4);
      expect(delta.facts['delta_payload_keys'], 2);
    });

    test('records delta as an acceptance no mechanism can satisfy', () async {
      final run = await const Sprint117SyncBackupConflictDrill().run();
      final delta = run.observationFor('delta')!;
      expect(
        delta.acceptance,
        Sprint117SyncBackupConflictAcceptance.mechanismAbsent,
      );
      expect(
        delta.unresolvable,
        contains('no_shipped_delta_transport_protocol'),
      );
      expect(delta.facts['shipped_delta_transport_implementations'], 0);
      // The count is measured by scanning for classes that implement the
      // protocol, not read off a comment.
      expect(delta.facts['shipped_cloud_sync_service_implementations'], 3);
    });
  });

  group('drill — retry_resume', () {
    test('pause and resume preserve the bytes already transferred', () async {
      final run = await const Sprint117SyncBackupConflictDrill().run();
      final retry = run.observationFor('retry_resume')!;
      expect(retry.passed, isTrue, reason: retry.outcome);
      expect(retry.facts['total_bytes'], 4096);
      expect(retry.facts['bytes_after_pause'], 2048);
      expect(retry.facts['bytes_after_resume'], 2048);
      expect(retry.facts['state_after_completion'], 'completed');
    });

    test('retry is bounded and a backwards advance is refused', () async {
      final run = await const Sprint117SyncBackupConflictDrill().run();
      final retry = run.observationFor('retry_resume')!;
      expect(retry.facts['retry_count_after_first'], 1);
      expect(retry.facts['retry_count_after_third'], 3);
      expect(retry.facts['fourth_retry_refused'], isTrue);
      expect(retry.facts['fourth_retry_error'], 'StateError');
      expect(retry.facts['zero_total_bytes_refused'], isTrue);
      expect(retry.facts['backwards_advance_error'], 'ArgumentError');
    });
  });

  group('drill — encrypted_backup', () {
    test(
      'a backup may run only with encryption and a live destination',
      () async {
        final run = await const Sprint117SyncBackupConflictDrill().run();
        final backup = run.observationFor('encrypted_backup')!;
        expect(backup.passed, isTrue, reason: backup.outcome);
        expect(backup.facts['encrypted_policy_can_run'], isTrue);
        expect(backup.facts['unencrypted_policy_can_run'], isFalse);
        expect(backup.facts['unavailable_destination_can_run'], isFalse);
        expect(backup.facts['invalid_hour_refused'], isTrue);
        expect(backup.facts['non_positive_retention_refused'], isTrue);
      },
    );

    test(
      'records encryption as a declared field no shipped code executes',
      () async {
        final run = await const Sprint117SyncBackupConflictDrill().run();
        final backup = run.observationFor('encrypted_backup')!;
        expect(backup.facts['encryption_executed_by_shipped_code'], isFalse);
        expect(
          backup.acceptance,
          Sprint117SyncBackupConflictAcceptance.mechanismAbsent,
        );
        expect(
          backup.unresolvable,
          contains('no_shipped_encrypted_backup_writer'),
        );
        expect(backup.facts['pending_evidence_is_verified'], isFalse);
        expect(backup.facts['pending_evidence_has_restore_test'], isFalse);
      },
    );
  });

  group('drill — restore', () {
    test('a restore test is reported only from completed evidence', () async {
      final run = await const Sprint117SyncBackupConflictDrill().run();
      final restore = run.observationFor('restore')!;
      expect(restore.passed, isTrue, reason: restore.outcome);
      expect(restore.facts['verified_evidence_is_verified'], isTrue);
      expect(restore.facts['verified_evidence_has_restore_test'], isTrue);
      expect(restore.facts['verification_only_has_restore_test'], isFalse);
      expect(restore.facts['live_restore_executed'], isFalse);
    });

    test(
      'retention prunes per category without cross-category eviction',
      () async {
        final run = await const Sprint117SyncBackupConflictDrill().run();
        final restore = run.observationFor('restore')!;
        expect(restore.facts['max_automatic'], 2);
        expect(restore.facts['max_manual'], 1);
        // Five backups over budgets (3 automatic / 2 manual) prune the oldest of
        // each category: a1 and m1, never one category from the other.
        expect(restore.facts['pruned_backup_ids'], <String>['a1', 'm1']);
        expect(restore.facts['blank_evidence_id_refused'], isTrue);
      },
    );
  });

  group('drill — conflicts', () {
    test(
      'detects a conflict and refuses resolution without a backup',
      () async {
        final run = await const Sprint117SyncBackupConflictDrill().run();
        final conflicts = run.observationFor('conflicts')!;
        expect(conflicts.passed, isTrue, reason: conflicts.outcome);
        expect(conflicts.facts['detected_conflict_keys'], <String>['a']);
        expect(conflicts.facts['resolution_without_backup_refused'], isTrue);
        expect(conflicts.facts['selected_version_after_keep_local'], 'v-local');
        expect(conflicts.facts['history_entries'], 1);
        expect(conflicts.facts['re_resolve_after_resolution_refused'], isTrue);
      },
    );

    test(
      'a remote-only edit and a remote-only addition survive the merge',
      () async {
        final run = await const Sprint117SyncBackupConflictDrill().run();
        final conflicts = run.observationFor('conflicts')!;
        expect(conflicts.facts['remote_only_edit_merged_value'], '2');
        expect(conflicts.facts['remote_only_addition_merged_value'], '2');
        expect(conflicts.facts['remote_only_addition_key_count'], 1);
        // The defect this step owns: before the fix the merge emitted neither,
        // so the remote edit reverted to base and the addition vanished.
        expect(conflicts.facts['local_deletion_kept_key'], isTrue);
        expect(conflicts.facts['local_deletion_merged_value_is_null'], isTrue);
        expect(conflicts.facts['already_resolved_fallback'], 'alreadyResolved');
        expect(conflicts.facts['unknown_fallback'], 'notFound');
      },
    );
  });

  group('drill — large_assets', () {
    test(
      'records the whole-map transport shape a large payload takes',
      () async {
        final run = await const Sprint117SyncBackupConflictDrill().run();
        final large = run.observationFor('large_assets')!;
        expect(large.passed, isTrue, reason: large.outcome);
        expect(large.facts['payload_key_count'], 3);
        expect(large.facts['serialized_payload_bytes'], 6149);
        expect(large.facts['largest_single_value_bytes'], 4096);
        expect(large.facts['transport_is_whole_map'], isTrue);
      },
    );

    test(
      'records large_assets as an acceptance no mechanism can satisfy',
      () async {
        final run = await const Sprint117SyncBackupConflictDrill().run();
        final large = run.observationFor('large_assets')!;
        expect(
          large.acceptance,
          Sprint117SyncBackupConflictAcceptance.mechanismAbsent,
        );
        expect(
          large.unresolvable,
          contains('no_shipped_chunked_or_streamed_transfer'),
        );
        expect(large.facts['shipped_chunked_transfer_implementations'], 0);
        expect(large.facts['shipped_streaming_upload_implementations'], 0);
      },
    );
  });

  group('drill — workspace_boundaries', () {
    test('denies workspace access, cross-scope transfer, and mixing', () async {
      final run = await const Sprint117SyncBackupConflictDrill().run();
      final boundary = run.observationFor('workspace_boundaries')!;
      expect(boundary.passed, isTrue, reason: boundary.outcome);
      expect(boundary.facts['global_access_decision'], 'ALLOWED_GLOBAL_SCOPE');
      expect(
        boundary.facts['workspace_access_without_permission'],
        'DENIED_WORKSPACE_PERMISSION_REQUIRED',
      );
      expect(
        boundary.facts['workspace_access_with_permission'],
        'ALLOWED_WORKSPACE_SCOPED',
      );
      expect(
        boundary.facts['cross_scope_transfer_without_consent'],
        'DENIED_TRANSFER_CONSENT_REQUIRED',
      );
    });

    test(
      'detects boundary violations and leaves a clean boundary clean',
      () async {
        final run = await const Sprint117SyncBackupConflictDrill().run();
        final boundary = run.observationFor('workspace_boundaries')!;
        expect(
          boundary.facts['account_boundary_holding_workspace_data'],
          contains('ACCOUNT_GLOBAL_MUST_NOT_HOLD_WORKSPACE_DATA'),
        );
        expect(
          boundary.facts['novel_boundary_holding_character_data'],
          contains('NOVEL_WORKSPACE_BOUNDARY_MUST_NOT_HOLD_CHARACTER_DATA'),
        );
        expect(boundary.facts['clean_boundary_violations'], 0);
        expect(
          boundary.facts['account_route_nested_under_workspace_is_global'],
          isFalse,
        );
        expect(boundary.facts['co_ownership_allowed'], isFalse);
      },
    );
  });

  group('gate', () {
    test('passes with every canonical check decided by a real drill', () async {
      final report = await const Sprint117SyncBackupConflictGate()
          .evaluateWithDrill();
      expect(report.status, Sprint117SyncBackupConflictState.pass);
      expect(report.verdict, 'SYNC_BACKUP_CONFLICT_VALIDATED_LOCAL');
      expect(report.coverage, 1.0);
      expect(report.missingFields, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.unmappedChecks, isEmpty);
      expect(report.undeterminedChecks, isEmpty);
    });

    test('blocks instead of passing when no drill has run', () {
      final report = const Sprint117SyncBackupConflictGate().evaluate();
      expect(report.status, Sprint117SyncBackupConflictState.blocked);
      expect(report.missingFields, contains('drill_run'));
      expect(report.verdict, 'SYNC_BACKUP_CONFLICT_BLOCKED_NO_LOCAL_EVIDENCE');
    });

    test('rejects external source drift', () {
      final report = const Sprint117SyncBackupConflictGate().evaluateWith(
        Sprint117SyncBackupConflictInput(
          rows: const <Sprint117SyncBackupConflictCheck>[],
          anchor: const Sprint117SyncBackupConflictLoader().load().anchor,
          externalPinDrift: true,
        ),
      );
      expect(report.status, Sprint117SyncBackupConflictState.fail);
      expect(report.violations, contains('external_source_drift'));
    });

    test('rejects a check that claims a live provider result', () {
      final report = const Sprint117SyncBackupConflictGate().evaluateWith(
        Sprint117SyncBackupConflictInput(
          rows: <Sprint117SyncBackupConflictCheck>[
            Sprint117SyncBackupConflictCheck(
              checkId: 'transfer',
              method: 'm',
              expectedOutcome: 'e',
              observedOutcome: null,
              sourceManifest:
                  'docs/planning/v1.2/sprint_115_cloud_transfer_sync_controls.json',
              liveProviderResult: true,
              drilledAgainstLiveProvider: false,
            ),
          ],
        ),
      );
      expect(report.status, Sprint117SyncBackupConflictState.fail);
      expect(report.violations, contains('live_provider_claim:transfer'));
    });

    test('rejects a drill run that contacted a provider', () {
      final leaky = Sprint117SyncBackupConflictDrillRun(
        observations: <Sprint117SyncBackupConflictObservation>[
          Sprint117SyncBackupConflictObservation(
            checkId: 'delta',
            outcome: 'X',
            facts: const <String, Object?>{
              'acceptance_mechanism_present': true,
            },
            passed: true,
          ),
        ],
        liveProviderTouched: true,
        userProjectTouched: false,
        liveSecretObserved: false,
        externalPinsMatched: 0,
        externalPinsChecked: 0,
      );
      final report = const Sprint117SyncBackupConflictGate().evaluateWith(
        Sprint117SyncBackupConflictInput(
          rows: const <Sprint117SyncBackupConflictCheck>[],
          anchor: const Sprint117SyncBackupConflictLoader().load().anchor,
          drillRun: leaky,
        ),
      );
      expect(report.status, Sprint117SyncBackupConflictState.fail);
      expect(report.violations, contains('live_provider_touched'));
    });

    test('rejects a drill run that opened a user project', () {
      final leaky = Sprint117SyncBackupConflictDrillRun(
        observations: <Sprint117SyncBackupConflictObservation>[
          Sprint117SyncBackupConflictObservation(
            checkId: 'restore',
            outcome: 'X',
            facts: const <String, Object?>{
              'acceptance_mechanism_present': true,
            },
            passed: true,
          ),
        ],
        liveProviderTouched: false,
        userProjectTouched: true,
        liveSecretObserved: false,
        externalPinsMatched: 0,
        externalPinsChecked: 0,
      );
      final report = const Sprint117SyncBackupConflictGate().evaluateWith(
        Sprint117SyncBackupConflictInput(
          rows: const <Sprint117SyncBackupConflictCheck>[],
          anchor: const Sprint117SyncBackupConflictLoader().load().anchor,
          drillRun: leaky,
        ),
      );
      expect(report.status, Sprint117SyncBackupConflictState.fail);
      expect(report.violations, contains('user_project_touched'));
    });

    test('rejects a failed observation as a violation, not an open item', () {
      final failing = Sprint117SyncBackupConflictDrillRun(
        observations: <Sprint117SyncBackupConflictObservation>[
          Sprint117SyncBackupConflictObservation(
            checkId: 'conflicts',
            outcome: 'MERGE_DROPPED_A_REMOTE_ONLY_CHANGE',
            facts: const <String, Object?>{
              'acceptance_mechanism_present': true,
            },
            passed: false,
          ),
        ],
        liveProviderTouched: false,
        userProjectTouched: false,
        liveSecretObserved: false,
        externalPinsMatched: 0,
        externalPinsChecked: 0,
      );
      final report = const Sprint117SyncBackupConflictGate().evaluateWith(
        Sprint117SyncBackupConflictInput(
          rows: const <Sprint117SyncBackupConflictCheck>[],
          anchor: const Sprint117SyncBackupConflictLoader().load().anchor,
          drillRun: failing,
        ),
      );
      expect(report.status, Sprint117SyncBackupConflictState.fail);
      expect(report.violations, contains('drill_observation_failed:conflicts'));
      expect(
        report.violations,
        contains('drill_outcome:MERGE_DROPPED_A_REMOTE_ONLY_CHANGE'),
      );
    });

    test('rejects a run that left a canonical check undecided', () async {
      final run = await const Sprint117SyncBackupConflictDrill().run();
      final input = const Sprint117SyncBackupConflictLoader().loadWithDrill(
        run,
      );
      final dropped = <Sprint117SyncBackupConflictCheck>[
        for (final row in input.rows!)
          if (row.checkId != 'workspace_boundaries') row,
      ];
      final report = const Sprint117SyncBackupConflictGate().evaluateWith(
        Sprint117SyncBackupConflictInput(
          rows: dropped,
          // The anchor decides which canonical checks must be mapped, so a
          // missing one would report `blocked` for an unrelated reason and the
          // unmapped check would never be reached.
          anchor: const Sprint117SyncBackupConflictLoader().load().anchor,
          drillRun: run,
        ),
      );
      expect(report.status, Sprint117SyncBackupConflictState.fail);
      expect(
        report.violations,
        contains('check_unmapped:workspace_boundaries'),
      );
    });

    test(
      'rejects an acceptance claimed without a mechanism behind it',
      () async {
        final run = await const Sprint117SyncBackupConflictDrill().run();
        final honest = run.observationFor('delta')!;
        // Same outcome, but relabelled as acceptance-satisfied while its own
        // recorded fact says no mechanism ships. The two claims contradict.
        final contradicting = Sprint117SyncBackupConflictDrillRun(
          observations: <Sprint117SyncBackupConflictObservation>[
            for (final observation in run.observations)
              if (observation.checkId == 'delta')
                Sprint117SyncBackupConflictObservation(
                  checkId: observation.checkId,
                  outcome: observation.outcome,
                  facts: observation.facts,
                  passed: observation.passed,
                  acceptance: Sprint117SyncBackupConflictAcceptance.satisfied,
                )
              else
                observation,
          ],
          liveProviderTouched: run.liveProviderTouched,
          userProjectTouched: run.userProjectTouched,
          liveSecretObserved: run.liveSecretObserved,
          externalPinsMatched: run.externalPinsMatched,
          externalPinsChecked: run.externalPinsChecked,
        );
        expect(
          honest.acceptance,
          Sprint117SyncBackupConflictAcceptance.mechanismAbsent,
        );
        final evaluated = const Sprint117SyncBackupConflictGate().evaluateWith(
          const Sprint117SyncBackupConflictLoader().loadWithDrill(
            contradicting,
          ),
        );
        expect(evaluated.status, Sprint117SyncBackupConflictState.fail);
        expect(
          evaluated.violations,
          contains('acceptance_claimed_without_mechanism:delta'),
        );
      },
    );

    test(
      'carries every unmet acceptance and the integration gap as open items',
      () async {
        final report = await const Sprint117SyncBackupConflictGate()
            .evaluateWithDrill();
        expect(report.acceptanceUnmet, <String>[
          'delta',
          'encrypted_backup',
          'large_assets',
        ]);
        expect(report.openItems, contains('check_acceptance_unmet:delta'));
        expect(
          report.openItems,
          contains(
            'unresolvable_reference:no_shipped_delta_transport_protocol',
          ),
        );
        expect(
          report.openItems,
          contains('unresolvable_reference:no_shipped_encrypted_backup_writer'),
        );
        expect(
          report.openItems,
          contains(
            'unresolvable_reference:no_shipped_chunked_or_streamed_transfer',
          ),
        );
        expect(report.openItems, contains('sync_defined_not_executed_live'));
        expect(
          report.openItems,
          contains('external_sync_specs_outside_repository'),
        );
      },
    );
  });

  group('report serialisation', () {
    test(
      'emits the verdict and every evidence class it decided from',
      () async {
        final report = await const Sprint117SyncBackupConflictGate()
            .evaluateWithDrill();
        final json = report.toJson();
        expect(json['verdict'], 'SYNC_BACKUP_CONFLICT_VALIDATED_LOCAL');
        expect(json['status'], 'pass');
        expect(json['coverage'], 1.0);
        expect((json['acceptance_unmet'] as List<dynamic>).toList(), <String>[
          'delta',
          'encrypted_backup',
          'large_assets',
        ]);
        expect(json['anchor'], isA<Map<String, dynamic>>());
        expect((json['checks'] as List<dynamic>).length, 8);
        // The emitted manifest must itself be valid JSON, byte-for-byte
        // round-trippable, so a generator can write it without a second pass.
        expect(() => jsonDecode(jsonEncode(json)), returnsNormally);
      },
    );
  });
}
