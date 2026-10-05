import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_ai_provider_workflow_validation.dart';
import '../canonical_source_support.dart';

/// Sentinel distinguishing "argument omitted" from an explicit null.
const Object _absent = Object();

void main() {
  group('117.15 gate', () {
    test('drill decides all nine canonical checks locally', () async {
      if (skipUnlessExternalCanonical(
        "drill decides all nine canonical checks locally",
      )) {
        return;
      }
      final report = await const Sprint117AiProviderWorkflowGate()
          .evaluateWithDrill();

      expect(
        Sprint117AiProviderWorkflowContract.requiredChecks,
        <String>[
          'connect',
          'models',
          'execution',
          'cancellation',
          'usage',
          'cost',
          'privacy_destination',
          'fallback',
          'errors',
        ],
        reason: 'the nine evidence names are canonical, not chosen by the run',
      );
      expect(report.coverage, 1.0);
      expect(report.status, Sprint117AiProviderWorkflowState.pass);
      expect(report.verdict, 'AI_PROVIDER_WORKFLOW_VALIDATED_LOCAL');
      expect(report.violations, isEmpty);
      expect(report.missingFields, isEmpty);
      expect(report.unmappedChecks, isEmpty);
      expect(report.undeterminedChecks, isEmpty);
    });

    test(
      'anchor resolves every committed source and every external pin',
      () async {
        if (skipUnlessExternalCanonical(
          "anchor resolves every committed source and every external pin",
        )) {
          return;
        }
        final report = await const Sprint117AiProviderWorkflowGate()
            .evaluateWithDrill();
        final anchor = report.anchor!;

        expect(anchor.declaredContractSizes, hasLength(5));
        for (final entry in anchor.declaredContractSizes.entries) {
          expect(
            entry.value.trim(),
            isNotEmpty,
            reason: '${entry.key} declares no contract to drill from',
          );
        }
        expect(anchor.boundariesDeclared.values, everyElement(isTrue));
        expect(anchor.localAiPrivacyDeclared, isTrue);
        expect(anchor.errorStatesDeclared, isTrue);
        expect(anchor.errorStatesCount, 8);
        expect(anchor.localLiveVerificationClaimed, isFalse);
        expect(anchor.externalPinsResolved, isTrue);
        expect(anchor.allExternalPinsMatch, isTrue);
        expect(anchor.externalPinsMatched, 3);
      },
    );

    test('the drill touched no live provider, project, or secret', () async {
      final run = await const Sprint117AiProviderWorkflowDrill().run();
      expect(run.liveProviderTouched, isFalse);
      expect(run.userProjectTouched, isFalse);
      expect(run.liveSecretObserved, isFalse);
      expect(run.allPassed, isTrue);
      expect(run.observations, hasLength(9));
    });

    test('every check is bound to a committed manifest that exists', () async {
      final report = await const Sprint117AiProviderWorkflowGate()
          .evaluateWithDrill();
      final checkIds = report.checks.map((check) => check.checkId).toList();
      expect(
        checkIds,
        containsAll(Sprint117AiProviderWorkflowContract.requiredChecks),
      );
      for (final check in report.checks) {
        expect(check.method.trim(), isNotEmpty, reason: check.checkId);
        expect(check.expectedOutcome.trim(), isNotEmpty, reason: check.checkId);
        expect(check.sourceManifest.trim(), isNotEmpty, reason: check.checkId);
        expect(check.executed, isTrue, reason: check.checkId);
        expect(check.liveProviderResult, isFalse, reason: check.checkId);
        expect(
          check.drilledAgainstLiveProvider,
          isFalse,
          reason: check.checkId,
        );
      }
    });
  });

  group('117.15 measured findings', () {
    test(
      'connect fails closed before any transport while uncredentialed',
      () async {
        final run = await const Sprint117AiProviderWorkflowDrill().run();
        final observation = run.observationFor('connect')!;

        expect(observation.passed, isTrue);
        expect(
          observation.outcome,
          'CREDENTIAL_GATE_FAILS_CLOSED_BEFORE_TRANSPORT',
        );
        expect(
          observation.facts['list_models_refused_without_credential'],
          isTrue,
        );
        expect(
          observation.facts['transport_reached_while_uncredentialed'],
          isFalse,
        );
        // A provider that always refuses would also pass the first two, so the
        // positive control proves the gate is about the credential.
        expect(
          observation.facts['transport_reached_once_credentialed'],
          isTrue,
        );
      },
    );

    test(
      'models caches, degrades to the cache, and rethrows when empty',
      () async {
        final run = await const Sprint117AiProviderWorkflowDrill().run();
        final observation = run.observationFor('models')!;

        expect(observation.passed, isTrue);
        expect(observation.facts['discovered_models'], 1);
        expect(observation.facts['cached_models_after_live'], 1);
        expect(observation.facts['degraded_from_cache'], isTrue);
        expect(
          observation.facts['empty_cache_rethrew'],
          isTrue,
          reason: 'an empty cache must surface, never silently block',
        );
      },
    );

    test('execution completes one job and fails the other', () async {
      final run = await const Sprint117AiProviderWorkflowDrill().run();
      final observation = run.observationFor('execution')!;

      expect(observation.passed, isTrue);
      expect(observation.facts['completed_job_status'], 'completed');
      expect(observation.facts['failed_job_status'], 'failed');
    });

    test('a cancelled job is never executed', () async {
      final run = await const Sprint117AiProviderWorkflowDrill().run();
      final observation = run.observationFor('cancellation')!;

      expect(observation.passed, isTrue);
      expect(observation.facts['executed_job_ids'], <String>['job-runs']);
      expect(observation.facts['cancelled_status'], 'cancelled');
      expect(observation.facts['unknown_cancel_returned_true'], isFalse);
    });

    test('errors are typed and never echo credential material', () async {
      final run = await const Sprint117AiProviderWorkflowDrill().run();
      final observation = run.observationFor('errors')!;

      expect(observation.passed, isTrue);
      expect(observation.facts['timeout_is_typed_exception'], isTrue);
      expect(observation.facts['any_message_echoes_credential'], isFalse);
      expect(observation.facts['declared_error_state_count'], 8);
    });

    test(
      'privacy_destination denies an unlisted destination and audits it',
      () async {
        final run = await const Sprint117AiProviderWorkflowDrill().run();
        final observation = run.observationFor('privacy_destination')!;

        expect(observation.passed, isTrue);
        expect(observation.facts['allowlisted_decision'], 'allowed');
        expect(observation.facts['unlisted_decision'], 'deniedByDefault');
        expect(observation.facts['audit_entries'], 3);
      },
    );
  });

  group('117.15 the defect this step fixed', () {
    test(
      'cost is booked to the serving provider, not the requested one',
      () async {
        final run = await const Sprint117AiProviderWorkflowDrill().run();
        final observation = run.observationFor('fallback')!;

        expect(observation.passed, isTrue);
        expect(
          observation.outcome,
          'FALLBACK_SERVES_AND_IS_THE_PROVIDER_CHARGED',
        );
        expect(observation.facts['requested_provider'], 'failed');
        expect(
          observation.facts['serving_provider'],
          'serving',
          reason: 'the requested provider failed and produced nothing',
        );
        expect(
          observation.facts['booked_provider_ids'],
          <String>['serving'],
          reason:
              'cost booked to the requested provider would charge a provider '
              'that failed',
        );
        expect(observation.facts['resolve_with_preferred'], 'serving');
      },
    );

    test(
      'a configured price table is used and an absent one stays zero',
      () async {
        final run = await const Sprint117AiProviderWorkflowDrill().run();
        final observation = run.observationFor('cost')!;

        expect(observation.passed, isTrue);
        expect(
          observation.facts['priced_call_cost'],
          0.5,
          reason: 'costOf was stored but never read, so every call cost zero',
        );
        expect(observation.facts['priced_call_provider'], 'serving');
        expect(observation.facts['unpriced_call_cost'], 0.0);
        expect(observation.facts['cheapest_capable_selected'], 'cheap');
      },
    );

    test(
      'the served-provider API is what makes attribution possible',
      () async {
        final run = await const Sprint117AiProviderWorkflowDrill().run();
        // The fallback check can only pass because the router reports who
        // served; assert the record carries it rather than a bare result.
        final fallback = run.observationFor('fallback')!;
        expect(
          fallback.facts['serving_provider'],
          isNot(fallback.facts['requested_provider']),
        );
      },
    );
  });

  group('117.15 acceptance honesty', () {
    test(
      'usage is reported unmet because no shipped code writes a row',
      () async {
        final run = await const Sprint117AiProviderWorkflowDrill().run();
        final observation = run.observationFor('usage')!;

        expect(
          observation.facts['shipped_usage_writer_call_sites'],
          0,
          reason: 'a usage writer existing but never called is still unwired',
        );
        expect(
          observation.facts['shipped_usage_reader_call_sites'],
          greaterThan(0),
        );
        expect(observation.facts['acceptance_mechanism_present'], isFalse);
        expect(
          observation.acceptance,
          Sprint117AiProviderWorkflowAcceptance.mechanismAbsent,
        );
        expect(
          observation.unresolvable,
          contains('no_shipped_ai_usage_writer'),
        );
      },
    );

    test(
      'the report lists the unmet acceptance instead of folding it in',
      () async {
        final report = await const Sprint117AiProviderWorkflowGate()
            .evaluateWithDrill();
        expect(report.acceptanceUnmet, <String>['usage']);
        expect(report.acceptanceSatisfied, isNot(contains('usage')));
        expect(report.openItems, contains('check_acceptance_unmet:usage'));
        expect(
          report.openItems,
          contains('unresolvable_reference:no_shipped_ai_usage_writer'),
        );
        expect(
          report.openItems,
          contains('ai_provider_defined_not_executed_live'),
        );
      },
    );

    test('a passing check that admits a missing mechanism is a violation', () {
      // Hand-built so the contradiction is isolated from the real drill.
      final observation = Sprint117AiProviderWorkflowObservation(
        checkId: 'usage',
        outcome: 'USAGE_OK',
        facts: const <String, Object?>{'acceptance_mechanism_present': false},
        passed: true,
      );
      final report = const Sprint117AiProviderWorkflowGate().evaluateWith(
        Sprint117AiProviderWorkflowInput(
          rows: <Sprint117AiProviderWorkflowCheck>[
            Sprint117AiProviderWorkflowCheck(
              checkId: 'usage',
              method: 'm',
              expectedOutcome: 'e',
              observedOutcome: 'USAGE_OK',
              sourceManifest:
                  'docs/planning/v1.2/sprint_115_ai_usage_credits_cost_view.json',
              liveProviderResult: false,
              drilledAgainstLiveProvider: false,
            ),
          ],
          anchor: const Sprint117AiProviderWorkflowLoader().load().anchor,
          drillRun: Sprint117AiProviderWorkflowDrillRun(
            observations: <Sprint117AiProviderWorkflowObservation>[observation],
            liveProviderTouched: false,
            userProjectTouched: false,
            liveSecretObserved: false,
            externalPinsMatched: 3,
            externalPinsChecked: 3,
          ),
        ),
      );

      expect(report.status, Sprint117AiProviderWorkflowState.fail);
      expect(
        report.violations,
        contains('acceptance_claimed_without_mechanism:usage'),
      );
    });
  });

  group('117.15 gate rejection classes', () {
    const gate = Sprint117AiProviderWorkflowGate();

    /// Builds an input. [anchor] accepts an explicit null through a sentinel,
    /// because a plain `??` cannot tell "not supplied" from a deliberate null —
    /// which is exactly the input a caller passes when proving the gate refuses
    /// to pass without an anchor.
    Sprint117AiProviderWorkflowInput buildInput({
      List<Sprint117AiProviderWorkflowCheck>? rows,
      Sprint117AiProviderWorkflowDrillRun? run,
      bool pinDrift = false,
      Object? anchor = _absent,
    }) {
      final loaded = const Sprint117AiProviderWorkflowLoader().load();
      return Sprint117AiProviderWorkflowInput(
        rows: rows ?? loaded.rows,
        anchor: identical(anchor, _absent)
            ? loaded.anchor
            : anchor as Sprint117AiProviderWorkflowAnchor?,
        drillRun: run,
        externalPinDrift: pinDrift,
      );
    }

    test('no drill is blocked, never passed on prose', () async {
      final report = gate.evaluate();
      expect(report.status, Sprint117AiProviderWorkflowState.blocked);
      expect(report.missingFields, contains('drill_run'));
      expect(report.coverage, 0.0);
      // With no drill there is no observation to source an outcome from, so
      // every defined check is undetermined rather than reported missing.
      expect(report.undeterminedChecks, hasLength(9));
      expect(
        report.missingFields,
        isNot(contains('check_observed_outcome:connect')),
      );
    });

    test(
      'a drill that omits a check leaves it undetermined and missing',
      () async {
        final good = await const Sprint117AiProviderWorkflowDrill().run();
        final run = Sprint117AiProviderWorkflowDrillRun(
          observations: good.observations
              .where((observation) => observation.checkId != 'fallback')
              .toList(),
          liveProviderTouched: false,
          userProjectTouched: false,
          liveSecretObserved: false,
          externalPinsMatched: good.externalPinsMatched,
          externalPinsChecked: good.externalPinsChecked,
        );
        final loaded = const Sprint117AiProviderWorkflowLoader().loadWithDrill(
          run,
        );

        final report = gate.evaluateWith(
          buildInput(rows: loaded.rows, run: run),
        );
        expect(report.status, Sprint117AiProviderWorkflowState.blocked);
        expect(report.undeterminedChecks, contains('fallback'));
        expect(
          report.missingFields,
          contains('check_observed_outcome:fallback'),
        );
        // Coverage drops because the evidence decided less than it claims to.
        expect(report.coverage, lessThan(1.0));
      },
    );

    test('a live-provider claim on a check is a violation', () async {
      final run = await const Sprint117AiProviderWorkflowDrill().run();
      final rows = const Sprint117AiProviderWorkflowLoader()
          .loadWithDrill(run)
          .rows!
          .map(
            (row) => Sprint117AiProviderWorkflowCheck(
              checkId: row.checkId,
              method: row.method,
              expectedOutcome: row.expectedOutcome,
              observedOutcome: row.observedOutcome,
              sourceManifest: row.sourceManifest,
              liveProviderResult: true,
              drilledAgainstLiveProvider: false,
            ),
          )
          .toList();

      final report = gate.evaluateWith(buildInput(rows: rows, run: run));
      expect(report.status, Sprint117AiProviderWorkflowState.fail);
      expect(report.violations, contains('live_provider_claim:connect'));
    });

    test(
      'a recorded outcome that contradicts the drill is a violation',
      () async {
        final run = await const Sprint117AiProviderWorkflowDrill().run();
        final rows = const Sprint117AiProviderWorkflowLoader()
            .loadWithDrill(run)
            .rows!
            .map(
              (row) => row.checkId == 'fallback'
                  ? Sprint117AiProviderWorkflowCheck(
                      checkId: row.checkId,
                      method: row.method,
                      expectedOutcome: row.expectedOutcome,
                      observedOutcome: 'FALLBACK_SOMETHING_ELSE',
                      sourceManifest: row.sourceManifest,
                      liveProviderResult: false,
                      drilledAgainstLiveProvider: false,
                    )
                  : row,
            )
            .toList();

        final report = gate.evaluateWith(buildInput(rows: rows, run: run));
        expect(report.status, Sprint117AiProviderWorkflowState.fail);
        expect(
          report.violations,
          contains('check_outcome_contradicts_drill:fallback'),
        );
      },
    );

    test('a failed drill observation fails the whole gate', () async {
      final good = await const Sprint117AiProviderWorkflowDrill().run();
      final run = Sprint117AiProviderWorkflowDrillRun(
        observations: good.observations
            .map(
              (observation) => observation.checkId == 'connect'
                  ? Sprint117AiProviderWorkflowObservation(
                      checkId: 'connect',
                      outcome: 'CONNECT_BROKEN',
                      facts: observation.facts,
                      passed: false,
                    )
                  : observation,
            )
            .toList(),
        liveProviderTouched: false,
        userProjectTouched: false,
        liveSecretObserved: false,
        externalPinsMatched: good.externalPinsMatched,
        externalPinsChecked: good.externalPinsChecked,
      );

      final report = gate.evaluateWith(buildInput(run: run));
      expect(report.status, Sprint117AiProviderWorkflowState.fail);
      expect(report.violations, contains('drill_observation_failed:connect'));
    });

    test('a drill that touched a live provider is a violation', () async {
      final good = await const Sprint117AiProviderWorkflowDrill().run();
      final run = Sprint117AiProviderWorkflowDrillRun(
        observations: good.observations,
        liveProviderTouched: true,
        userProjectTouched: false,
        liveSecretObserved: false,
        externalPinsMatched: good.externalPinsMatched,
        externalPinsChecked: good.externalPinsChecked,
      );

      final report = gate.evaluateWith(buildInput(run: run));
      expect(report.violations, contains('live_provider_touched'));
    });

    test('external pin drift is a violation', () async {
      final run = await const Sprint117AiProviderWorkflowDrill().run();
      final report = gate.evaluateWith(buildInput(run: run, pinDrift: true));
      expect(report.violations, contains('external_source_drift'));
    });

    test('a duplicated check is a violation', () async {
      final run = await const Sprint117AiProviderWorkflowDrill().run();
      final rows = const Sprint117AiProviderWorkflowLoader()
          .loadWithDrill(run)
          .rows!;
      final report = gate.evaluateWith(
        buildInput(
          rows: <Sprint117AiProviderWorkflowCheck>[...rows, rows.first],
          run: run,
        ),
      );
      expect(report.status, Sprint117AiProviderWorkflowState.fail);
      expect(
        report.violations,
        contains('check_duplicate:${rows.first.checkId}'),
      );
    });

    test('a missing anchor is blocked, not passed', () async {
      final run = await const Sprint117AiProviderWorkflowDrill().run();
      final loaded = const Sprint117AiProviderWorkflowLoader().loadWithDrill(
        run,
      );
      final report = gate.evaluateWith(
        buildInput(rows: loaded.rows, anchor: null, run: run),
      );
      expect(report.status, Sprint117AiProviderWorkflowState.blocked);
      expect(report.missingFields, contains('ai_provider_anchor'));
      // Without an anchor the checks cannot be bound to committed sources, so
      // the run must not be able to reach pass no matter how green it looks.
      expect(report.coverage, lessThan(1.0));
    });

    test('a source claiming live verification is a violation', () {
      final report = gate.evaluateWith(
        buildInput(
          rows: const <Sprint117AiProviderWorkflowCheck>[],
          anchor: Sprint117AiProviderWorkflowAnchor(
            declaredContractSizes: const <String, String>{},
            boundariesDeclared: const <String, bool>{},
            localAiPrivacyDeclared: true,
            errorStatesDeclared: true,
            errorStatesCount: 8,
            localLiveVerificationClaimed: true,
            externalPinsMatched: 3,
            externalPinsChecked: 3,
          ),
        ),
      );
      expect(report.violations, contains('live_provider_claim_in_source'));
    });
  });

  group('117.15 determinism', () {
    test('two drill runs produce the same observations and facts', () async {
      final first = await const Sprint117AiProviderWorkflowDrill().run();
      final second = await const Sprint117AiProviderWorkflowDrill().run();
      expect(jsonEncode(first.toJson()), jsonEncode(second.toJson()));
    });

    test(
      'the report serializes with every canonical section present',
      () async {
        final report = await const Sprint117AiProviderWorkflowGate()
            .evaluateWithDrill();
        final encoded =
            jsonDecode(jsonEncode(report.toJson())) as Map<String, dynamic>;
        for (final key in const <String>[
          'verdict',
          'status',
          'missing_fields',
          'violations',
          'unmapped_checks',
          'undetermined_checks',
          'coverage',
          'acceptance_satisfied',
          'acceptance_unmet',
          'open_items',
          'anchor',
          'checks',
        ]) {
          expect(encoded.containsKey(key), isTrue, reason: key);
        }
        expect(encoded['checks'], hasLength(9));
      },
    );
  });
}
