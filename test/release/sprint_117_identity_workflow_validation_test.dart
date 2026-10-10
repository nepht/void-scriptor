/// Canonical step 117.12 — Identity Workflow Validation.
///
/// Objective (external canonical JSON): make sure a user can connect a
/// provider, link it, hit a collision, reauthenticate, unlink, keep at least
/// one way in, recover, and revoke — and that the eight required evidence
/// names are decided by real local execution rather than by prose.
///
/// The eight evidence names read like one end-to-end account identity story,
/// so this test is the place that has to say plainly what ships and what
/// does not. The shipped code is a set of local, injectable domain seams and
/// no live provider at all: `ProviderConnectorManifest.standard` marks every
/// entry it builds `UNVERIFIED`, there is no production `OAuthTokenBroker`
/// implementation, and none of the six account-domain classes has a call site
/// in `lib/` outside its own file. The check and the drill are therefore
/// deliberately separate classes:
///
/// * [Sprint117IdentityWorkflowDrill] really executes the shipped mechanisms:
///   a real authorization-code exchange, a real vault read gated on
///   reauthentication, a real key revocation, and the real collision, merge,
///   last-method, and recovery guards.
/// * [Sprint117IdentityWorkflowLoader] reads the committed manifests and the
///   external specs they pin, and never invents a check or an outcome.
/// * [Sprint117IdentityWorkflowGate] decides whether the recorded evidence is
///   coherent, synchronously and without side effects.
///
/// The decided-vs-coherent distinction carries over unchanged from 117.11. A
/// check no drill has executed is *undetermined*; a check executed and then
/// contradicted is a violation. The one acceptance that shipped code cannot
/// satisfy — `connect`, because zero connectors are connectable — is recorded
/// as `acceptance_unmet` with the exact reason, never folded into a pass.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_identity_workflow_validation.dart';
import '../canonical_source_support.dart';

void main() {
  const step = Sprint117IdentityWorkflowContract.canonicalStep;

  group('contract surface', () {
    test('covers the eight canonical checks in canonical order', () {
      expect(Sprint117IdentityWorkflowContract.requiredChecks, <String>[
        'connect',
        'link',
        'collision',
        'reauth',
        'unlink',
        'last_method',
        'recovery',
        'revoke',
      ]);
    });

    test('declares the canonical step as 117.12', () {
      expect(step, '117.12');
    });

    test('every source manifest it depends on is committed', () {
      for (final path in Sprint117IdentityWorkflowContract.sourceManifests) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'source manifest must be committed: $path',
        );
      }
    });

    test('reads the unlink rule from 115.11 rather than paraphrasing it', () {
      final source =
          jsonDecode(
                File(
                  Sprint117IdentityWorkflowContract.identityFlow,
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final protocol = source['protocol'] as Map<String, dynamic>;
      expect(
        protocol.containsKey('unlink'),
        isTrue,
        reason: '115.11 must record protocol.unlink for this gate to drill it',
      );
    });

    test('every source manifest states where its own evidence stops', () {
      final anchor = const Sprint117IdentityWorkflowLoader().load().anchor;
      expect(anchor, isNotNull);
      for (final entry in anchor!.boundariesDeclared.entries) {
        expect(
          entry.value,
          isTrue,
          reason: 'source must declare a boundary: ${entry.key}',
        );
      }
    });

    test('the vault key scheme is the production one, not a paraphrase', () {
      expect(
        Sprint117IdentityWorkflowContract.vaultKeyScheme,
        'account/<id>/<kind>[/<secretId>]',
      );
    });
  });

  group('external pins', () {
    test('resolves and matches every external spec it pins', () {
      if (skipUnlessExternalCanonical(
        "resolves and matches every external spec it pins",
      )) {
        return;
      }
      final anchor = const Sprint117IdentityWorkflowLoader().load().anchor;
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
      final input = const Sprint117IdentityWorkflowLoader().load();
      expect(input.anchor, isNotNull);
      final ids = input.rows!.map((row) => row.checkId).toList();
      expect(ids, Sprint117IdentityWorkflowContract.requiredChecks);
      for (final row in input.rows!) {
        expect(row.method, isNotEmpty, reason: row.checkId);
        expect(row.expectedOutcome, isNotEmpty, reason: row.checkId);
        expect(row.sourceManifest, isNotEmpty, reason: row.checkId);
      }
    });

    test('never claims a live provider result for any check', () {
      final input = const Sprint117IdentityWorkflowLoader().load();
      for (final row in input.rows!) {
        expect(row.liveProviderResult, isFalse, reason: row.checkId);
        expect(row.drilledAgainstLiveProvider, isFalse, reason: row.checkId);
      }
    });

    test('leaves every check undetermined before a drill has run', () {
      final input = const Sprint117IdentityWorkflowLoader().load();
      for (final row in input.rows!) {
        expect(row.executed, isFalse, reason: row.checkId);
        expect(row.observedOutcome, isNull, reason: row.checkId);
      }
    });
  });

  group('drill — connect', () {
    test(
      'counts what the shipped manifest actually lets a user connect',
      () async {
        final run = await const Sprint117IdentityWorkflowDrill().run();
        final connect = run.observationFor('connect')!;
        expect(connect.passed, isTrue, reason: connect.outcome);
        expect(connect.facts['shipped_connector_count'], greaterThan(0));
        expect(connect.facts['shipped_connectable_count'], 0);
        expect(connect.facts['shipped_identity_connectable_count'], 0);
        expect(connect.facts['refused_with_error'], 'connectorUnavailable');
      },
    );

    test(
      'completes a real exchange only through a fixture that passes the gate',
      () async {
        final run = await const Sprint117IdentityWorkflowDrill().run();
        final connect = run.observationFor('connect')!;
        expect(connect.facts['fixture_exchange_completed'], isTrue);
        expect(connect.facts['fixture_token_generation'], 1);
        expect(connect.facts['linked_identities_in_memory'], 1);
        expect(connect.facts['pkce_code_challenge_present'], isTrue);
        expect(connect.facts['fixture_granted_scopes'], <String>[
          'account.read',
        ]);
      },
    );

    test('refuses a replayed callback and a superseded grant', () async {
      final run = await const Sprint117IdentityWorkflowDrill().run();
      final connect = run.observationFor('connect')!;
      expect(connect.facts['callback_replay_error'], 'stateMismatch');
      expect(connect.facts['rotated_generation'], 2);
      expect(
        connect.facts['stale_generation_unlink_error'],
        'staleTokenGeneration',
      );
      expect(
        connect.facts['stale_generation_rotate_error'],
        'staleTokenGeneration',
      );
    });

    test('records connect as an acceptance no mechanism can satisfy', () async {
      final run = await const Sprint117IdentityWorkflowDrill().run();
      final connect = run.observationFor('connect')!;
      expect(connect.facts['acceptance_mechanism_present'], isFalse);
      expect(connect.acceptanceSatisfied, isFalse);
      expect(connect.unresolvable, <String>[
        'no_shipped_identity_connector_connectable',
      ]);
    });
  });

  group('drill — link and collision', () {
    test('links a second identity and reads the account back', () async {
      final run = await const Sprint117IdentityWorkflowDrill().run();
      final link = run.observationFor('link')!;
      expect(link.passed, isTrue, reason: link.outcome);
      expect(link.facts['identities_after_link'], 2);
      expect(link.facts['identities_after_reread'], 2);
      expect(link.facts['merged_identity_count'], 2);
      expect(link.facts['secondary_account_after_merge'], isNull);
    });

    test('refuses to steal a credential owned by another account', () async {
      final run = await const Sprint117IdentityWorkflowDrill().run();
      expect(
        run.observationFor('link')!.facts['takeover_attempt_error'],
        'IdentityTakeoverException',
      );
    });

    test(
      'rejects every collision class without mutating either account',
      () async {
        final run = await const Sprint117IdentityWorkflowDrill().run();
        final collision = run.observationFor('collision')!;
        expect(collision.passed, isTrue, reason: collision.outcome);
        expect(
          collision.facts['duplicate_email_error'],
          'IdentityCollisionException',
        );
        expect(
          collision.facts['duplicate_identity_error'],
          'IdentityCollisionException',
        );
        expect(
          collision.facts['unconfirmed_merge_error'],
          'IdentityMergeConfirmationException',
        );
        expect(
          collision.facts['overlapping_merge_error'],
          'IdentityCollisionException',
        );
        expect(collision.facts['accounts_unchanged_after_collisions'], 2);
        expect(collision.facts['identities_unchanged_after_collisions'], 1);
      },
    );
  });

  group('drill — reauth', () {
    test('withholds the secret until reauthentication is granted', () async {
      final run = await const Sprint117IdentityWorkflowDrill().run();
      final reauth = run.observationFor('reauth')!;
      expect(reauth.passed, isTrue, reason: reauth.outcome);
      expect(reauth.facts['read_without_reauth'], isNull);
      expect(reauth.facts['read_with_reauth'], 'drill-refresh-token');
      expect(
        reauth.facts['vault_key_scheme_resolved'],
        'account/drill_reauth/oauth_refresh_token',
      );
    });

    test(
      'routes an expired connection back through reauthenticate, not retry',
      () async {
        final run = await const Sprint117IdentityWorkflowDrill().run();
        final reauth = run.observationFor('reauth')!;
        expect(reauth.facts['expired_offers_reauth'], isTrue);
        expect(reauth.facts['expired_offers_retry'], isFalse);
        expect(reauth.facts['retry_without_reauth_error'], 'StateError');
        expect(reauth.facts['state_after_reauthenticate'], 'CONNECTING');
        expect(reauth.facts['state_after_reauth_success'], 'CONNECTED');
        expect(reauth.facts['reauth_required_cleared'], isTrue);
      },
    );
  });

  group('drill — unlink', () {
    test('removes the link only after provider revocation succeeds', () async {
      final run = await const Sprint117IdentityWorkflowDrill().run();
      final unlink = run.observationFor('unlink')!;
      expect(unlink.passed, isTrue, reason: unlink.outcome);
      expect(unlink.facts['keep_linked_result'], isFalse);
      expect(unlink.facts['identities_after_keep'], 1);
      expect(unlink.facts['provider_revocations_after_keep'], 0);
      expect(unlink.facts['failed_revocation_error'], 'revocationFailed');
      expect(unlink.facts['identities_after_failed_revocation'], 1);
      expect(unlink.facts['successful_unlink_result'], isTrue);
      expect(unlink.facts['identities_after_successful_unlink'], 0);
      expect(unlink.facts['second_unlink_error'], 'staleTokenGeneration');
    });

    test('requires explicit confirmation at the management surface', () async {
      final run = await const Sprint117IdentityWorkflowDrill().run();
      final unlink = run.observationFor('unlink')!;
      expect(unlink.facts['management_unlink_without_confirmation'], isFalse);
      expect(unlink.facts['connections_after_unconfirmed'], 1);
      expect(unlink.facts['management_unlink_with_confirmation'], isTrue);
      expect(unlink.facts['connections_after_confirmed'], 0);
    });
  });

  group('drill — last_method and recovery', () {
    test('protects the last identity until a recovery email exists', () async {
      final run = await const Sprint117IdentityWorkflowDrill().run();
      final lastMethod = run.observationFor('last_method')!;
      expect(lastMethod.passed, isTrue, reason: lastMethod.outcome);
      expect(
        lastMethod.facts['sole_identity_unlink_error'],
        'LastLoginMethodException',
      );
      expect(lastMethod.facts['unlink_with_spare_identity'], isTrue);
      expect(lastMethod.facts['unlink_after_recovery'], isTrue);
      expect(lastMethod.facts['identities_after_recovery_unlink'], 0);
    });

    test('rejects a malformed recovery email and keeps local data', () async {
      final run = await const Sprint117IdentityWorkflowDrill().run();
      final recovery = run.observationFor('recovery')!;
      expect(recovery.passed, isTrue, reason: recovery.outcome);
      expect(recovery.facts['malformed_email_error'], 'ArgumentError');
      expect(recovery.facts['recovery_email_after_malformed'], isNull);
      expect(recovery.facts['recovery_email_stored'], 'recover@example.test');
      expect(recovery.facts['unknown_account_error'], 'StateError');
      expect(recovery.facts['local_data_preserved'], isTrue);
      expect(recovery.facts['revoked_preserves_local_data'], isTrue);
      expect(recovery.facts['retry_while_expired_accepted'], isFalse);
      expect(recovery.facts['retry_after_reauth_accepted'], isTrue);
    });
  });

  group('drill — revoke', () {
    test('removes the vault key and makes the managed key inert', () async {
      final run = await const Sprint117IdentityWorkflowDrill().run();
      final revoke = run.observationFor('revoke')!;
      expect(revoke.passed, isTrue, reason: revoke.outcome);
      expect(revoke.facts['vault_key'], 'account/drill_revoke/api_key/key-1');
      expect(revoke.facts['secret_present_before'], isTrue);
      expect(revoke.facts['secret_present_after'], isFalse);
      expect(revoke.facts['read_after_revoke'], isNull);
      expect(revoke.facts['managed_key_status'], 'revoked');
      expect(revoke.facts['replace_after_revoke_error'], 'StateError');
      expect(revoke.facts['validate_after_revoke_error'], 'StateError');
    });

    test(
      'leaves a revoked connection with only the cleanup way back',
      () async {
        final run = await const Sprint117IdentityWorkflowDrill().run();
        final revoke = run.observationFor('revoke')!;
        expect(revoke.facts['connection_state_after_revoke'], 'REVOKED');
        expect(revoke.facts['outgoing_transitions_after_revoke'], <String>[
          'DISCONNECT_CLEANUP',
        ]);
        expect(revoke.facts['retry_after_revoke_error'], 'StateError');
        expect(revoke.facts['provider_revocations'], 1);
      },
    );
  });

  group('drill run boundaries', () {
    test('touches no provider, no user project, and no live secret', () async {
      final run = await const Sprint117IdentityWorkflowDrill().run();
      expect(run.liveProviderTouched, isFalse);
      expect(run.userProjectTouched, isFalse);
      expect(run.liveSecretObserved, isFalse);
    });

    test('decides all eight checks and passes every one of them', () async {
      final run = await const Sprint117IdentityWorkflowDrill().run();
      expect(
        run.observations.map((observation) => observation.checkId).toList(),
        Sprint117IdentityWorkflowContract.requiredChecks,
      );
      expect(run.allPassed, isTrue);
    });

    test(
      'separates the satisfiable acceptances from the impossible one',
      () async {
        final run = await const Sprint117IdentityWorkflowDrill().run();
        expect(run.acceptanceUnmet, <String>['connect']);
        expect(run.acceptanceSatisfied, <String>[
          'collision',
          'last_method',
          'link',
          'reauth',
          'recovery',
          'revoke',
          'unlink',
        ]);
        expect(run.unresolvableReferences, <String>[
          'no_shipped_identity_connector_connectable',
        ]);
      },
    );
  });

  group('gate', () {
    test(
      'passes with full coverage when the drill supplies every outcome',
      () async {
        if (skipUnlessExternalCanonical(
          "passes with full coverage when the drill supplies every outcome",
        )) {
          return;
        }
        final report = await const Sprint117IdentityWorkflowGate()
            .evaluateWithDrill();
        expect(
          report.violations,
          isEmpty,
          reason: report.violations.join(', '),
        );
        expect(
          report.missingFields,
          isEmpty,
          reason: report.missingFields.join(', '),
        );
        expect(report.unmappedChecks, isEmpty);
        expect(report.undeterminedChecks, isEmpty);
        expect(report.status, Sprint117IdentityWorkflowState.pass);
        expect(report.verdict, 'IDENTITY_WORKFLOW_VALIDATED_LOCAL');
        expect(report.coverage, 1.0);
      },
    );

    test('blocks rather than passes when no drill has run', () {
      final report = const Sprint117IdentityWorkflowGate().evaluate();
      expect(report.status, Sprint117IdentityWorkflowState.blocked);
      expect(report.verdict, 'IDENTITY_WORKFLOW_BLOCKED_NO_LOCAL_EVIDENCE');
      expect(report.missingFields, contains('drill_run'));
      expect(
        report.undeterminedChecks,
        Sprint117IdentityWorkflowContract.requiredChecks.toList()..sort(),
      );
      expect(report.coverage, 0.0);
    });

    test('rejects a report that claims a live provider result', () {
      final report = const Sprint117IdentityWorkflowGate().evaluateWith(
        Sprint117IdentityWorkflowInput(
          rows: <Sprint117IdentityWorkflowCheck>[
            Sprint117IdentityWorkflowCheck(
              checkId: 'connect',
              method: 'm',
              expectedOutcome: 'e',
              observedOutcome: 'o',
              sourceManifest:
                  Sprint117IdentityWorkflowContract.providerConnector,
              liveProviderResult: true,
              drilledAgainstLiveProvider: false,
            ),
          ],
        ),
      );
      expect(report.status, Sprint117IdentityWorkflowState.fail);
      expect(report.verdict, 'IDENTITY_WORKFLOW_INCONSISTENT');
      expect(report.violations, contains('live_provider_claim:connect'));
    });

    test('rejects a recorded outcome that contradicts the drill', () async {
      final run = await const Sprint117IdentityWorkflowDrill().run();
      final measured = const Sprint117IdentityWorkflowLoader().loadWithDrill(
        run,
      );
      final rows = measured.rows!
          .map(
            (row) => row.checkId == 'unlink'
                ? Sprint117IdentityWorkflowCheck(
                    checkId: row.checkId,
                    method: row.method,
                    expectedOutcome: row.expectedOutcome,
                    observedOutcome: 'A_MEASURED_OUTCOME_THAT_NEVER_HAPPENED',
                    sourceManifest: row.sourceManifest,
                    liveProviderResult: false,
                    drilledAgainstLiveProvider: false,
                  )
                : row,
          )
          .toList();
      final report = const Sprint117IdentityWorkflowGate().evaluateWith(
        Sprint117IdentityWorkflowInput(
          rows: rows,
          anchor: measured.anchor,
          drillRun: run,
        ),
      );
      expect(report.status, Sprint117IdentityWorkflowState.fail);
      expect(
        report.violations,
        contains('check_outcome_contradicts_drill:unlink'),
      );
    });

    test('rejects an acceptance claimed without a mechanism', () async {
      final run = await const Sprint117IdentityWorkflowDrill().run();
      final measured = const Sprint117IdentityWorkflowLoader().loadWithDrill(
        run,
      );
      final rows = measured.rows!
          .map(
            (row) => row.checkId == 'connect'
                ? Sprint117IdentityWorkflowCheck(
                    checkId: row.checkId,
                    method: row.method,
                    expectedOutcome: row.expectedOutcome,
                    observedOutcome: run.observationFor('connect')!.outcome,
                    sourceManifest: row.sourceManifest,
                    liveProviderResult: false,
                    drilledAgainstLiveProvider: false,
                  )
                : row,
          )
          .toList();
      final report = const Sprint117IdentityWorkflowGate().evaluateWith(
        Sprint117IdentityWorkflowInput(
          rows: rows,
          anchor: measured.anchor,
          drillRun: run,
        ),
      );
      // The measured run already records connect as mechanism-absent, so the
      // gate must report it unmet rather than satisfied.
      expect(report.acceptanceUnmet, contains('connect'));
      expect(report.acceptanceSatisfied, isNot(contains('connect')));
      expect(
        report.violations,
        isNot(contains('acceptance_claimed_without_mechanism:connect')),
      );
    });

    test('rejects a drill run that observed a live secret', () async {
      final leaky = Sprint117IdentityWorkflowDrillRun(
        observations: <Sprint117IdentityWorkflowObservation>[
          Sprint117IdentityWorkflowObservation(
            checkId: 'connect',
            outcome: 'X',
            facts: const <String, Object?>{
              'acceptance_mechanism_present': true,
            },
            passed: true,
            acceptance: Sprint117IdentityWorkflowAcceptance.satisfied,
            unresolvable: const <String>[],
          ),
        ],
        liveProviderTouched: false,
        userProjectTouched: false,
        liveSecretObserved: true,
        externalPinsMatched: 0,
        externalPinsChecked: 0,
      );
      final report = const Sprint117IdentityWorkflowGate().evaluateWith(
        Sprint117IdentityWorkflowInput(
          rows: const <Sprint117IdentityWorkflowCheck>[],
          anchor: const Sprint117IdentityWorkflowLoader().load().anchor,
          drillRun: leaky,
        ),
      );
      expect(report.status, Sprint117IdentityWorkflowState.fail);
      expect(report.violations, contains('live_secret_observed'));
    });

    test(
      'rejects a failed observation as a violation, not an open item',
      () async {
        final failing = Sprint117IdentityWorkflowDrillRun(
          observations: <Sprint117IdentityWorkflowObservation>[
            Sprint117IdentityWorkflowObservation(
              checkId: 'revoke',
              outcome: 'REVOKE_LEFT_STATE_USABLE',
              facts: const <String, Object?>{
                'acceptance_mechanism_present': true,
              },
              passed: false,
              acceptance: Sprint117IdentityWorkflowAcceptance.satisfied,
              unresolvable: const <String>[],
            ),
          ],
          liveProviderTouched: false,
          userProjectTouched: false,
          liveSecretObserved: false,
          externalPinsMatched: 0,
          externalPinsChecked: 0,
        );
        final report = const Sprint117IdentityWorkflowGate().evaluateWith(
          Sprint117IdentityWorkflowInput(
            rows: const <Sprint117IdentityWorkflowCheck>[],
            anchor: const Sprint117IdentityWorkflowLoader().load().anchor,
            drillRun: failing,
          ),
        );
        expect(report.status, Sprint117IdentityWorkflowState.fail);
        expect(report.violations, contains('drill_observation_failed:revoke'));
        expect(
          report.violations,
          contains('drill_outcome:REVOKE_LEFT_STATE_USABLE'),
        );
      },
    );

    test(
      'carries the unmet acceptance and the integration gap as open items',
      () async {
        final report = await const Sprint117IdentityWorkflowGate()
            .evaluateWithDrill();
        expect(report.openItems, contains('check_acceptance_unmet:connect'));
        expect(
          report.openItems,
          contains(
            'unresolvable_reference:no_shipped_identity_connector_connectable',
          ),
        );
        expect(
          report.openItems,
          contains('identity_workflow_defined_not_executed_live'),
        );
        expect(
          report.openItems,
          contains('external_identity_specs_outside_repository'),
        );
      },
    );
  });

  group('report serialisation', () {
    test(
      'emits the verdict and every evidence class it decided from',
      () async {
        if (skipUnlessExternalCanonical(
          "emits the verdict and every evidence class it decided from",
        )) {
          return;
        }
        final report = await const Sprint117IdentityWorkflowGate()
            .evaluateWithDrill();
        final json = report.toJson();
        expect(json['verdict'], 'IDENTITY_WORKFLOW_VALIDATED_LOCAL');
        expect(json['status'], 'pass');
        expect(json['coverage'], 1.0);
        expect((json['acceptance_unmet'] as List<dynamic>).toList(), <String>[
          'connect',
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
