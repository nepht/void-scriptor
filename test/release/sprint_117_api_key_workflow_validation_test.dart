import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_api_key_workflow_validation.dart';
import '../canonical_source_support.dart';

void main() {
  group('Sprint117ApiKeyWorkflowContract', () {
    test('names exactly the canonical 117.16 evidence items', () {
      expect(Sprint117ApiKeyWorkflowContract.canonicalStep, '117.16');
      expect(Sprint117ApiKeyWorkflowContract.requiredChecks, <String>[
        'add_replace',
        'validate',
        'mask',
        'scope',
        'secure_copy',
        'revoke',
        'audit',
        'no_plaintext',
        // Declared by anchor 115.27 and decided here, not left unmapped.
        'last_used',
      ]);
    });

    test('every committed source exists and declares its own boundary', () {
      for (final path in Sprint117ApiKeyWorkflowContract.sourceManifests) {
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    });

    test('external pins are the committed sha256 values', () {
      expect(Sprint117ApiKeyWorkflowContract.externalPins, hasLength(2));
      expect(
        Sprint117ApiKeyWorkflowContract.externalPins.values.every(
          (sha) => RegExp(r'^[0-9a-f]{64}$').hasMatch(sha),
        ),
        isTrue,
      );
    });
  });

  group('Sprint117ApiKeyWorkflowLoader', () {
    test('loads every canonical check with a method and a source', () {
      final rows = const Sprint117ApiKeyWorkflowLoader().load().rows;
      expect(rows, isNotNull);
      expect(
        rows!.map((r) => r.checkId).toSet(),
        Sprint117ApiKeyWorkflowContract.requiredChecks.toSet(),
      );
      for (final row in rows) {
        expect(row.method.trim(), isNotEmpty, reason: row.checkId);
        expect(row.expectedOutcome.trim(), isNotEmpty, reason: row.checkId);
        expect(
          File(row.sourceManifest).existsSync(),
          isTrue,
          reason: row.checkId,
        );
      }
    });

    test('anchor reads the secret guarantees from the committed spec', () {
      if (skipUnlessExternalCanonical(
        "anchor reads the secret guarantees from the committed spec",
      )) {
        return;
      }
      final anchor = const Sprint117ApiKeyWorkflowLoader().load().anchor;
      expect(anchor, isNotNull);
      expect(anchor!.neverPlaintextDeclared, isTrue);
      expect(anchor.reauthBeforeSensitiveActionDeclared, isTrue);
      expect(anchor.auditRedactionDeclared, isTrue);
      expect(anchor.sensitiveActionsDeclared, isTrue);
      expect(anchor.allExternalPinsMatch, isTrue);
    });

    test('no check claims a live provider or live credential run', () {
      final rows = const Sprint117ApiKeyWorkflowLoader().load().rows!;
      expect(rows.every((r) => !r.liveProviderResult), isTrue);
      expect(rows.every((r) => !r.drilledAgainstLiveProvider), isTrue);
    });

    test('without a drill every check stays undetermined, never passed', () {
      final report = const Sprint117ApiKeyWorkflowGate().evaluate();
      expect(report.status, Sprint117ApiKeyWorkflowState.blocked);
      expect(report.verdict, 'API_KEY_WORKFLOW_BLOCKED_NO_LOCAL_EVIDENCE');
      expect(report.missingFields, contains('drill_run'));
      expect(
        report.undeterminedChecks,
        hasLength(Sprint117ApiKeyWorkflowContract.requiredChecks.length),
      );
      expect(report.coverage, 0.0);
      expect(report.checks.every((c) => !c.executed), isTrue);
    });
  });

  group('Sprint117ApiKeyWorkflowGate', () {
    test('the measured drill decides every check and passes', () async {
      if (skipUnlessExternalCanonical(
        "the measured drill decides every check and passes",
      )) {
        return;
      }
      final report = await const Sprint117ApiKeyWorkflowGate()
          .evaluateWithDrill();
      expect(report.violations, isEmpty);
      expect(report.missingFields, isEmpty);
      expect(report.unmappedChecks, isEmpty);
      expect(report.undeterminedChecks, isEmpty);
      expect(report.coverage, 1.0);
      expect(report.status, Sprint117ApiKeyWorkflowState.pass);
      expect(report.verdict, 'API_KEY_WORKFLOW_VALIDATED_LOCAL');
      expect(report.acceptanceUnmet, isEmpty);
      expect(report.anchor!.allExternalPinsMatch, isTrue);
    });

    test('the drill touches no live provider, project, or secret', () async {
      final run = await const Sprint117ApiKeyWorkflowDrill().run();
      expect(run.liveProviderTouched, isFalse);
      expect(run.userProjectTouched, isFalse);
      expect(run.liveSecretObserved, isFalse);
      expect(
        run.observations,
        hasLength(Sprint117ApiKeyWorkflowContract.requiredChecks.length),
      );
      expect(
        run.observations.map((o) => o.checkId).toList(),
        Sprint117ApiKeyWorkflowContract.requiredChecks,
      );
      expect(run.allPassed, isTrue);
    });

    test('the drill is reproducible across runs', () async {
      final first = await const Sprint117ApiKeyWorkflowDrill().run();
      final second = await const Sprint117ApiKeyWorkflowDrill().run();
      expect(
        first.observations.map((o) => o.outcome).toList(),
        second.observations.map((o) => o.outcome).toList(),
      );
    });

    test(
      'a failing observation fails the gate instead of passing it',
      () async {
        final healthy = await const Sprint117ApiKeyWorkflowDrill().run();
        final poisoned = healthy.observations
            .map(
              (o) => o.checkId == 'revoke'
                  ? Sprint117ApiKeyWorkflowObservation(
                      checkId: 'revoke',
                      outcome: 'REVOKE_LEFT_KEY_MATERIAL_USABLE',
                      facts: const <String, Object?>{},
                      passed: false,
                    )
                  : o,
            )
            .toList(growable: false);

        final report = const Sprint117ApiKeyWorkflowGate().evaluateWith(
          Sprint117ApiKeyWorkflowInput(
            rows: const Sprint117ApiKeyWorkflowLoader().load().rows,
            anchor: const Sprint117ApiKeyWorkflowLoader().load().anchor,
            drillRun: Sprint117ApiKeyWorkflowDrillRun(
              observations: poisoned,
              liveProviderTouched: false,
              userProjectTouched: false,
              liveSecretObserved: false,
              externalPinsMatched: 0,
              externalPinsChecked: 0,
            ),
          ),
        );

        expect(report.status, Sprint117ApiKeyWorkflowState.fail);
        expect(report.violations, contains('drill_observation_failed:revoke'));
        expect(report.coverage, lessThan(1.0));
      },
    );

    test('an unreadable anchor blocks rather than passing on prose', () {
      final report = const Sprint117ApiKeyWorkflowGate().evaluateWith(
        const Sprint117ApiKeyWorkflowInput(),
      );
      expect(report.status, Sprint117ApiKeyWorkflowState.blocked);
      expect(report.missingFields, contains('api_key_anchor'));
      expect(report.missingFields, contains('check_rows'));
      expect(report.missingFields, contains('drill_run'));
      expect(report.coverage, 0.0);
    });

    test('an unreadable anchor cannot reach full coverage', () {
      // Coverage must not be reachable while the evidence it rests on is
      // unreadable, even with every row green.
      final rows = const Sprint117ApiKeyWorkflowLoader().load().rows!;
      final run = Sprint117ApiKeyWorkflowDrillRun(
        observations: <Sprint117ApiKeyWorkflowObservation>[
          for (final row in rows)
            Sprint117ApiKeyWorkflowObservation(
              checkId: row.checkId,
              outcome: row.checkId,
              facts: const <String, Object?>{},
              passed: true,
            ),
        ],
        liveProviderTouched: false,
        userProjectTouched: false,
        liveSecretObserved: false,
        externalPinsMatched: 0,
        externalPinsChecked: 0,
      );
      final report = const Sprint117ApiKeyWorkflowGate().evaluateWith(
        Sprint117ApiKeyWorkflowInput(rows: rows, anchor: null, drillRun: run),
      );
      expect(report.missingFields, contains('api_key_anchor'));
      expect(
        report.coverage,
        0.0,
        reason: 'an unresolved anchor must decide nothing',
      );
    });

    test('a claimed acceptance without its mechanism is a violation', () {
      final run = Sprint117ApiKeyWorkflowDrillRun(
        observations: <Sprint117ApiKeyWorkflowObservation>[
          for (final row in const Sprint117ApiKeyWorkflowLoader().load().rows!)
            Sprint117ApiKeyWorkflowObservation(
              checkId: row.checkId,
              outcome: row.checkId,
              facts: const <String, Object?>{
                'acceptance_mechanism_present': false,
              },
              passed: true,
            ),
        ],
        liveProviderTouched: false,
        userProjectTouched: false,
        liveSecretObserved: false,
        externalPinsMatched: 0,
        externalPinsChecked: 0,
      );
      final report = const Sprint117ApiKeyWorkflowGate().evaluateWith(
        Sprint117ApiKeyWorkflowInput(
          rows: const Sprint117ApiKeyWorkflowLoader().load().rows,
          anchor: const Sprint117ApiKeyWorkflowLoader().load().anchor,
          drillRun: run,
        ),
      );
      expect(report.status, Sprint117ApiKeyWorkflowState.fail);
      expect(
        report.violations,
        contains('acceptance_claimed_without_mechanism:add_replace'),
      );
    });

    test(
      'a recorded outcome that contradicts the drill is a violation',
      () async {
        final run = await const Sprint117ApiKeyWorkflowDrill().run();
        final rows = const Sprint117ApiKeyWorkflowLoader()
            .load()
            .rows!
            .map(
              (row) => Sprint117ApiKeyWorkflowCheck(
                checkId: row.checkId,
                method: row.method,
                expectedOutcome: row.expectedOutcome,
                // Keep the ids, change every outcome, so each recorded row
                // disagrees with what the drill actually measured.
                observedOutcome: 'SOMETHING_ELSE',
                sourceManifest: row.sourceManifest,
                liveProviderResult: false,
                drilledAgainstLiveProvider: false,
              ),
            )
            .toList(growable: false);
        final report = const Sprint117ApiKeyWorkflowGate().evaluateWith(
          Sprint117ApiKeyWorkflowInput(
            rows: rows,
            anchor: const Sprint117ApiKeyWorkflowLoader().load().anchor,
            drillRun: run,
          ),
        );
        expect(report.status, Sprint117ApiKeyWorkflowState.fail);
        expect(
          report.violations,
          contains('check_outcome_contradicts_drill:mask'),
        );
        expect(
          report.violations,
          contains('check_outcome_contradicts_drill:revoke'),
        );
      },
    );

    test('an observed outcome with no matching drill row is unsourced', () {
      final rows = const Sprint117ApiKeyWorkflowLoader()
          .load()
          .rows!
          .map(
            (row) => Sprint117ApiKeyWorkflowCheck(
              checkId: row.checkId,
              method: row.method,
              expectedOutcome: row.expectedOutcome,
              observedOutcome: 'SOMETHING_ELSE',
              sourceManifest: row.sourceManifest,
              liveProviderResult: false,
              drilledAgainstLiveProvider: false,
            ),
          )
          .toList(growable: false);
      final report = const Sprint117ApiKeyWorkflowGate().evaluateWith(
        Sprint117ApiKeyWorkflowInput(
          rows: rows,
          anchor: const Sprint117ApiKeyWorkflowLoader().load().anchor,
          drillRun: null,
        ),
      );
      expect(report.status, Sprint117ApiKeyWorkflowState.fail);
      expect(report.violations, contains('check_observation_unsourced:mask'));
    });

    test('external pin drift fails the report', () async {
      final run = await const Sprint117ApiKeyWorkflowDrill().run();
      const loader = Sprint117ApiKeyWorkflowLoader();
      final drifted = loader.loadWithDrill(
        Sprint117ApiKeyWorkflowDrillRun(
          observations: run.observations,
          liveProviderTouched: false,
          userProjectTouched: false,
          liveSecretObserved: false,
          externalPinsMatched: 0,
          externalPinsChecked:
              Sprint117ApiKeyWorkflowContract.externalPins.length,
        ),
      );
      final report = const Sprint117ApiKeyWorkflowGate().evaluateWith(drifted);
      expect(report.violations, contains('external_source_drift'));
      expect(report.status, Sprint117ApiKeyWorkflowState.fail);
    });

    test('a live provider claim is a violation', () {
      final rows = <Sprint117ApiKeyWorkflowCheck>[
        Sprint117ApiKeyWorkflowCheck(
          checkId: 'mask',
          method: 'm',
          expectedOutcome: 'e',
          observedOutcome: 'o',
          sourceManifest: Sprint117ApiKeyWorkflowContract.secureTokenVault,
          liveProviderResult: true,
          drilledAgainstLiveProvider: false,
        ),
      ];
      final report = const Sprint117ApiKeyWorkflowGate().evaluateWith(
        Sprint117ApiKeyWorkflowInput(rows: rows),
      );
      expect(report.violations, contains('live_provider_claim:mask'));
    });

    test('a blank or duplicate check id is a violation', () {
      final report = const Sprint117ApiKeyWorkflowGate().evaluateWith(
        Sprint117ApiKeyWorkflowInput(
          rows: <Sprint117ApiKeyWorkflowCheck>[
            Sprint117ApiKeyWorkflowCheck(
              checkId: '  ',
              method: 'm',
              expectedOutcome: 'e',
              observedOutcome: 'o',
              sourceManifest:
                  'docs/planning/v1.2/sprint_115_api_keys_manager.json',
              liveProviderResult: false,
              drilledAgainstLiveProvider: false,
            ),
            Sprint117ApiKeyWorkflowCheck(
              checkId: 'mask',
              method: 'm',
              expectedOutcome: 'e',
              observedOutcome: 'o',
              sourceManifest:
                  'docs/planning/v1.2/sprint_115_api_keys_manager.json',
              liveProviderResult: false,
              drilledAgainstLiveProvider: false,
            ),
            Sprint117ApiKeyWorkflowCheck(
              checkId: 'mask',
              method: 'm',
              expectedOutcome: 'e',
              observedOutcome: 'o',
              sourceManifest:
                  'docs/planning/v1.2/sprint_115_api_keys_manager.json',
              liveProviderResult: false,
              drilledAgainstLiveProvider: false,
            ),
          ],
        ),
      );
      expect(report.violations, contains('check_id_blank'));
      expect(report.violations, contains('check_duplicate:mask'));
    });

    test('an unmapped canonical check fails the report', () {
      final all = const Sprint117ApiKeyWorkflowLoader().load().rows!;
      final report = const Sprint117ApiKeyWorkflowGate().evaluateWith(
        Sprint117ApiKeyWorkflowInput(
          rows: all.where((r) => r.checkId != 'revoke').toList(),
          anchor: const Sprint117ApiKeyWorkflowLoader().load().anchor,
        ),
      );
      expect(report.unmappedChecks, contains('revoke'));
      expect(report.violations, contains('check_unmapped:revoke'));
    });

    test(
      'the report round-trips through JSON without losing a check',
      () async {
        if (skipUnlessExternalCanonical(
          "the report round-trips through JSON without losing a check",
        )) {
          return;
        }
        final report = await const Sprint117ApiKeyWorkflowGate()
            .evaluateWithDrill();
        final decoded =
            jsonDecode(jsonEncode(report.toJson())) as Map<String, Object?>;
        expect(decoded['canonical_step'], '117.16');
        expect(decoded['status'], 'pass');
        expect(
          decoded['checks']! as List<dynamic>,
          hasLength(Sprint117ApiKeyWorkflowContract.requiredChecks.length),
        );
        expect(decoded['open_items'], isNotEmpty);
        expect(
          (decoded['open_items']! as List<dynamic>).contains(
            'api_key_workflow_defined_not_executed_live',
          ),
          isTrue,
        );
      },
    );
  });

  group('Sprint117ApiKeyWorkflowDrill observations', () {
    test('add_replace measures a real rotation and a real refusal', () async {
      final run = await const Sprint117ApiKeyWorkflowDrill().run();
      final o = run.observationFor('add_replace')!;
      expect(
        o.outcome,
        'ROTATED_KEY_SERVES_NEW_SECRET_AND_REFUSAL_CHANGES_NOTHING',
      );
      expect(o.facts['stored_after_replace_is_rotated'], isTrue);
      expect(o.facts['refused_rotation_threw'], isTrue);
      expect(o.facts['refused_rotation_kept_previous_secret'], isTrue);
      expect(o.facts['denied_replace_audited'], isTrue);
    });

    test('validate records a refusal as a decided, audited result', () async {
      final run = await const Sprint117ApiKeyWorkflowDrill().run();
      final o = run.observationFor('validate')!;
      expect(o.outcome, 'VALIDATION_DECIDED_AND_AUDITED_INCLUDING_REFUSAL');
      expect(o.facts['refusal_marked_invalid'], 'invalid');
      expect(o.facts['refusal_timestamped'], isTrue);
      expect(o.facts['denied_validate_audit_rows'], 1);
      // The gate refused, so no probe may have run for that attempt.
      expect(o.facts['probe_invocations'], 2);
    });

    test('mask never renders the secret', () async {
      final run = await const Sprint117ApiKeyWorkflowDrill().run();
      final o = run.observationFor('mask')!;
      expect(o.outcome, 'KEY_NEVER_RENDERED_AS_SECRET');
      expect(o.facts['public_projection_free_of_secret'], isTrue);
      expect(o.facts['empty_secret_masked_to_empty'], isTrue);
    });

    test('scope keeps each key set own and unmodifiable', () async {
      final run = await const Sprint117ApiKeyWorkflowDrill().run();
      final o = run.observationFor('scope')!;
      expect(o.outcome, 'EACH_KEY_SCOPE_SET_KEPT_OWN_AND_UNMODIFIABLE');
      expect(o.facts['reader_scope_count'], 1);
      expect(o.facts['writer_scope_count'], 2);
      expect(o.facts['probe_received_key_own_scopes'], isTrue);
      expect(o.facts['scope_set_immutable'], isTrue);
    });

    test('secure_copy refuses before reading when the gate refuses', () async {
      final run = await const Sprint117ApiKeyWorkflowDrill().run();
      final o = run.observationFor('secure_copy')!;
      expect(o.outcome, 'COPY_ONLY_AFTER_REAUTHENTICATION');
      expect(o.facts['refused_copy_wrote_nothing'], isTrue);
    });

    test('revoke wipes the clipboard copy, not just the stored one', () async {
      final run = await const Sprint117ApiKeyWorkflowDrill().run();
      final o = run.observationFor('revoke')!;
      expect(o.outcome, 'REVOKED_KEY_KEEPS_NO_SECRET_NO_CLIPBOARD_NO_ACTION');
      expect(o.facts['clipboard_held_secret_before_revoke'], isTrue);
      expect(o.facts['clipboard_cleared_at_revoke'], isTrue);
      expect(o.facts['validate_refused_after_revoke'], isTrue);
    });

    test(
      'audit covers every action without carrying secret material',
      () async {
        final run = await const Sprint117ApiKeyWorkflowDrill().run();
        final o = run.observationFor('audit')!;
        expect(o.outcome, 'EVERY_ACTION_AUDITED_WITHOUT_SECRET_MATERIAL');
        expect(o.facts['no_audit_row_carries_secret'], isTrue);
        expect(o.facts['every_manager_action_audited'], isTrue);
      },
    );

    test('no_plaintext is measured against the encrypted envelope', () async {
      final run = await const Sprint117ApiKeyWorkflowDrill().run();
      final o = run.observationFor('no_plaintext')!;
      expect(o.outcome, 'NO_PLAINTEXT_AT_REST_OR_IN_ANY_PROJECTION');
      expect(o.facts['cipher_envelope_present'], isTrue);
      expect(o.facts['secret_absent_at_rest'], isTrue);
      expect(o.facts['encrypted_store_round_trips'], isTrue);
      expect(o.facts['account_namespace_isolated'], isTrue);
    });

    // Two defects in this slice's own honesty machinery, both found by
    // auditing the shipped code rather than by running the harness.
    //
    // (1) `Sprint117ApiKeyWorkflowObservation.acceptance` defaults to
    // `satisfied`, and the drill never set it on any of its eight rows. The
    // consequence is structural: `acceptanceUnmet` could never be non-empty,
    // so the report claimed all eight canonical acceptances were satisfiable
    // by shipped code without ever measuring it. 117.15 set the field
    // explicitly on the one row whose mechanism was missing; this drill set it
    // nowhere, which is the same silent optimism with wider blast radius.
    test(
      'every observation states whether its mechanism exists at all',
      () async {
        final run = await const Sprint117ApiKeyWorkflowDrill().run();
        for (final observation in run.observations) {
          expect(
            observation.facts.containsKey('acceptance_mechanism_present'),
            isTrue,
            reason:
                '${observation.checkId} decided acceptance without measuring '
                'whether shipped code can satisfy it',
          );
        }
      },
    );

    // (2) Anchor 115.27 declares seven acceptance items
    // (add_replace, validate, revoke, scope, last_used, masked_only,
    // secure_copy). `mask` stands in for masked_only, but `last_used` has no
    // check, even though `AccountCenterApiKeysManager` stamps
    // `lastUsedAt`. An anchor that declares an item and no row decides it is
    // the same unmapped gap 117.15 fixed for its own lane.
    test('canonical anchor item last_used is decided by a check', () async {
      const manifest = 'docs/planning/v1.2/sprint_115_api_keys_manager.json';
      final json =
          jsonDecode(File(manifest).readAsStringSync()) as Map<String, Object?>;
      final declared = (json['acceptance'] as List<Object?>)
          .cast<String>()
          .toList();

      expect(
        declared,
        contains('last_used'),
        reason: 'the pinned 115.27 manifest is expected to declare last_used',
      );

      final run = await const Sprint117ApiKeyWorkflowDrill().run();
      expect(
        run.observationFor('last_used'),
        isNotNull,
        reason:
            'a declared anchor item with no check row is an unmapped gap, '
            'and the anchor already names last_used as an acceptance of '
            'the API Keys Manager this slice validates',
      );
    });
  });
}
