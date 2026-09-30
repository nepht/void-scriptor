import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_developer_connector_workflow_validation.dart';

void main() {
  // The contract class is abstract on purpose, so it is read statically rather
  // than instantiated. A local `const` instance of it would not compile, and
  // wrapping it in a fake value class would reintroduce exactly the constant
  // the honesty machinery is meant to avoid.
  const List<String> requiredChecks =
      Sprint117DeveloperConnectorWorkflowContract.requiredChecks;

  group('117.17 contract shape', () {
    test('names the six canonical evidence items in canonical order', () {
      expect(requiredChecks, hasLength(6));
      expect(requiredChecks, <String>[
        'scopes',
        'resource_access',
        'rate_limits',
        'reauth',
        'revoke',
        'audit',
      ]);
      expect(
        Sprint117DeveloperConnectorWorkflowContract.canonicalStep,
        '117.17',
      );
    });

    test('the external canonical step declares exactly these six items', () {
      // Pinned by sha256 in the loader, so the read below is of the file the
      // contract actually depends on rather than of whichever pin happens to
      // sort first.
      final file = File(
        'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/'
        'sprint_117.json',
      );
      expect(file.existsSync(), isTrue);
      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final step = (decoded['steps'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((entry) => entry['id'] == '117.17');

      expect(step['title'], 'Developer Connector Workflow Validation');
      expect(step['required_evidence'], requiredChecks);
    });

    test('every committed source exists and states its own boundary', () {
      for (final path
          in Sprint117DeveloperConnectorWorkflowContract.sourceManifests) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: path);
        final source =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final boundary =
            source['boundary'] ?? source['evidence_boundary'] ?? '';
        expect(boundary, isNotEmpty, reason: path);
      }
    });
  });

  group('117.17 loader and anchor', () {
    test('reads the anchor, its declared acceptance, and both pins', () {
      final report = const Sprint117DeveloperConnectorWorkflowGate().evaluate();

      expect(report.anchor, isNotNull);
      final anchor = report.anchor!;
      expect(anchor.externalPinsResolved, isTrue);
      expect(anchor.allExternalPinsMatch, isTrue);
      expect(
        anchor.declaredContractSizes.keys,
        containsAll(
          Sprint117DeveloperConnectorWorkflowContract.sourceManifests,
        ),
      );
      for (final entry in anchor.declaredContractSizes.entries) {
        expect(entry.value, isNotEmpty, reason: entry.key);
      }
      expect(anchor.developerAcceptanceDeclared, isTrue);
      expect(anchor.reauthAcceptanceDeclared, isTrue);
      expect(anchor.healthAcceptanceDeclared, isTrue);
      expect(anchor.reauthBeforeSensitiveActionDeclared, isTrue);
      expect(anchor.disconnectProviderSensitiveAction, isTrue);
    });

    test('builds one bound row per canonical check, each with a method', () {
      final report = const Sprint117DeveloperConnectorWorkflowGate().evaluate();

      expect(
        report.checks.map((row) => row.checkId).toList()..sort(),
        requiredChecks.toList()..sort(),
      );
      expect(report.unmappedChecks, isEmpty);
      for (final row in report.checks) {
        expect(row.method, isNotEmpty, reason: row.checkId);
        expect(row.expectedOutcome, isNotEmpty, reason: row.checkId);
        expect(
          File(row.sourceManifest).existsSync(),
          isTrue,
          reason: row.checkId,
        );
        expect(row.liveProviderResult, isFalse, reason: row.checkId);
        expect(row.drilledAgainstLiveProvider, isFalse, reason: row.checkId);
      }
    });
  });

  group('117.17 measured drill', () {
    late Sprint117DeveloperConnectorWorkflowDrillRun run;

    setUpAll(() async {
      run = await const Sprint117DeveloperConnectorWorkflowDrill().run();
    });

    test('touches no provider, no user project, and no credential', () {
      expect(run.liveProviderTouched, isFalse);
      expect(run.userProjectTouched, isFalse);
      expect(run.liveCredentialObserved, isFalse);
    });

    test('resolves and matches every external pin', () {
      expect(run.externalPinsResolved, isTrue);
      expect(run.allExternalPinsMatchForDrill, isTrue);
    });

    test('decides every canonical check with a non-empty outcome', () {
      expect(run.observations, hasLength(requiredChecks.length));
      for (final observation in run.observations) {
        expect(observation.outcome, isNotEmpty, reason: observation.checkId);
        expect(observation.facts, isNotEmpty, reason: observation.checkId);
        expect(
          observation.facts['acceptance_mechanism_present'],
          isTrue,
          reason: observation.checkId,
        );
      }
    });

    test('scopes: the stored set is normalized, deduplicated, immutable', () {
      final observation = run.observationFor('scopes')!;
      expect(observation.passed, isTrue, reason: observation.outcome);
      expect(observation.facts['stored_scope_count'], 2);
      expect(observation.facts['duplicate_and_cased_input_normalized'], isTrue);
      expect(observation.facts['scope_set_immutable'], isTrue);
      expect(observation.facts['empty_scopes_refused'], isTrue);
      expect(observation.facts['blank_scopes_refused'], isTrue);
    });

    test('resource_access: declared access always matches the grant', () {
      final observation = run.observationFor('resource_access')!;
      expect(observation.passed, isTrue, reason: observation.outcome);
      expect(observation.facts['wider_access_than_grant_refused'], isTrue);
      expect(observation.facts['narrower_access_than_grant_refused'], isTrue);
      expect(observation.facts['write_access_carries_write_scope'], isTrue);
    });

    test('rate_limits: the limit is visible and never laundered', () {
      final observation = run.observationFor('rate_limits')!;
      expect(observation.passed, isTrue, reason: observation.outcome);
      expect(observation.facts['connection_state_under_limit'], 'CONNECTED');
      expect(observation.facts['health_state_under_limit'], 'RATE_LIMITED');
      expect(observation.facts['status_label'], 'Rate limited');
      expect(observation.facts['limit_timestamped'], isTrue);
      expect(observation.facts['cleared_only_by_a_real_refresh'], isTrue);
    });

    test('reauth: the request is cleared by proof and stays isolated', () {
      final observation = run.observationFor('reauth')!;
      expect(observation.passed, isTrue, reason: observation.outcome);
      expect(observation.facts['request_sets_flag'], isTrue);
      expect(observation.facts['request_carries_granted_scopes'], isTrue);
      expect(observation.facts['cleared_by_health_observation'], isTrue);
      expect(observation.facts['cleared_in_stored_connection'], isTrue);
      expect(observation.facts['other_account_unaffected'], isTrue);
    });

    test('revoke: terminal state, gated disconnect, refusal audited', () {
      final observation = run.observationFor('revoke')!;
      expect(observation.passed, isTrue, reason: observation.outcome);
      expect(observation.facts['connection_state_after_revoke'], 'REVOKED');
      expect(observation.facts['no_transition_available'], isTrue);
      expect(observation.facts['retry_after_revoke_refused'], isTrue);
      expect(observation.facts['reconnect_after_revoke_refused'], isTrue);
      expect(
        observation.facts['gated_disconnect_refused_without_reauth'],
        isTrue,
      );
      expect(observation.facts['refusal_kept_the_connection'], isTrue);
      expect(observation.facts['refusal_audited'], isTrue);
      expect(observation.facts['ungated_seam_fails_closed'], isTrue);
    });

    test(
      'audit: every action and refusal is audited without scope material',
      () {
        final observation = run.observationFor('audit')!;
        expect(observation.passed, isTrue, reason: observation.outcome);
        expect(observation.facts['connect_rows'], 1);
        expect(observation.facts['disconnect_rows'], 1);
        expect(observation.facts['denied_rows'], 2);
        expect(observation.facts['one_row_per_action_taken'], isTrue);
        expect(observation.facts['no_row_carries_scope_material'], isTrue);
        expect(observation.facts['every_row_named_and_timestamped'], isTrue);
      },
    );
  });

  group('117.17 gate decisions', () {
    test(
      'the measured run passes with full coverage and no violation',
      () async {
        final report = await const Sprint117DeveloperConnectorWorkflowGate()
            .evaluateWithDrill();

        expect(
          report.status,
          Sprint117DeveloperConnectorWorkflowState.pass,
          reason:
              'missing=${report.missingFields} violations=${report.violations}',
        );
        expect(report.verdict, 'DEVELOPER_CONNECTOR_WORKFLOW_VALIDATED_LOCAL');
        expect(report.coverage, 1.0);
        expect(report.violations, isEmpty);
        expect(report.missingFields, isEmpty);
        expect(report.unmappedChecks, isEmpty);
        expect(report.undeterminedChecks, isEmpty);
        expect(report.acceptanceSatisfied, requiredChecks.toList()..sort());
        expect(report.acceptanceUnmet, isEmpty);
      },
    );

    test(
      'records what stays open instead of folding it into the verdict',
      () async {
        final report = await const Sprint117DeveloperConnectorWorkflowGate()
            .evaluateWithDrill();

        expect(
          report.openItems,
          contains('developer_connector_workflow_defined_not_executed_live'),
        );
        expect(
          report.openItems,
          contains('external_connector_specs_outside_repository'),
        );
        // Measured, not asserted: the three shipped managers have no consumer
        // under lib/ outside this harness.
        expect(
          report.openItems,
          contains('no_shipped_consumer_for_developer_connector_managers'),
        );
        expect(
          report.openItems,
          contains(
            'organization_workspace_acceptance_undeclared_by_anchor_sources',
          ),
        );
        expect(
          report.openItems,
          contains('rate_limit_acceptance_undeclared_by_anchor_sources'),
        );
      },
    );

    test('a run without a drill is blocked, never passed on prose', () {
      final report = const Sprint117DeveloperConnectorWorkflowGate().evaluate();

      expect(report.status, Sprint117DeveloperConnectorWorkflowState.blocked);
      expect(
        report.verdict,
        'DEVELOPER_CONNECTOR_WORKFLOW_BLOCKED_NO_LOCAL_EVIDENCE',
      );
      expect(report.missingFields, contains('drill_run'));
      expect(report.coverage, 0.0);
      // A run that measured nothing claims no integration gap either.
      expect(
        report.openItems,
        isNot(contains('no_shipped_consumer_for_developer_connector_managers')),
      );
    });

    test(
      'the report serializes to valid JSON carrying its own decision',
      () async {
        final report = await const Sprint117DeveloperConnectorWorkflowGate()
            .evaluateWithDrill();
        final json =
            jsonDecode(jsonEncode(report.toJson())) as Map<String, dynamic>;

        expect(json['canonical_step'], '117.17');
        expect(json['status'], 'pass');
        expect(json['verdict'], 'DEVELOPER_CONNECTOR_WORKFLOW_VALIDATED_LOCAL');
        expect(json['coverage'], 1.0);
        expect((json['checks'] as List<dynamic>), hasLength(6));
        expect(json['anchor'], isA<Map<String, dynamic>>());
        expect(
          (json['anchor'] as Map<String, dynamic>)['external_pins_matched'],
          2,
        );
      },
    );
  });

  group('117.17 gate rejects a contradictory or unrun measurement', () {
    Sprint117DeveloperConnectorWorkflowObservation observation(
      String checkId, {
      required bool passed,
      bool mechanismPresent = true,
    }) => Sprint117DeveloperConnectorWorkflowObservation(
      checkId: checkId,
      outcome: passed ? 'OK' : 'BROKEN',
      facts: <String, Object?>{
        'acceptance_mechanism_present': mechanismPresent,
      },
      passed: passed,
    );

    Sprint117DeveloperConnectorWorkflowDrillRun runOf(
      List<Sprint117DeveloperConnectorWorkflowObservation> observations, {
      int pinsMatched = 2,
      int pinsChecked = 2,
      bool productionCaller = true,
    }) => Sprint117DeveloperConnectorWorkflowDrillRun(
      observations: observations,
      liveProviderTouched: false,
      userProjectTouched: false,
      liveCredentialObserved: false,
      externalPinsMatched: pinsMatched,
      externalPinsChecked: pinsChecked,
      productionCallerPresent: productionCaller,
    );

    test('a failed observation fails the gate and names the outcome', () async {
      final broken = runOf([
        for (final id in requiredChecks) observation(id, passed: id != 'audit'),
      ]);
      final report = await const Sprint117DeveloperConnectorWorkflowGate()
          .evaluateWithDrill(broken);

      expect(report.status, Sprint117DeveloperConnectorWorkflowState.fail);
      expect(report.verdict, 'DEVELOPER_CONNECTOR_WORKFLOW_INCONSISTENT');
      expect(report.violations, contains('drill_observation_failed:audit'));
      expect(report.violations, contains('drill_outcome:BROKEN'));
    });

    test(
      'a check claiming acceptance without a mechanism is a violation',
      () async {
        final contradicted = runOf([
          for (final id in requiredChecks)
            observation(id, passed: true, mechanismPresent: id != 'revoke'),
        ]);
        final report = await const Sprint117DeveloperConnectorWorkflowGate()
            .evaluateWithDrill(contradicted);

        expect(report.status, Sprint117DeveloperConnectorWorkflowState.fail);
        expect(
          report.violations,
          contains('acceptance_claimed_without_mechanism:revoke'),
        );
      },
    );

    test(
      'a drifted or unread external pin is a violation, not a pass',
      () async {
        final drifted = runOf([
          for (final id in requiredChecks) observation(id, passed: true),
        ], pinsMatched: 1);
        final report = await const Sprint117DeveloperConnectorWorkflowGate()
            .evaluateWithDrill(drifted);

        expect(report.status, Sprint117DeveloperConnectorWorkflowState.fail);
        expect(report.violations, contains('external_source_drift'));
      },
    );

    test('touching a live provider or a user project fails the gate', () async {
      final touched = Sprint117DeveloperConnectorWorkflowDrillRun(
        observations: [
          for (final id in requiredChecks) observation(id, passed: true),
        ],
        liveProviderTouched: true,
        userProjectTouched: true,
        liveCredentialObserved: false,
        externalPinsMatched: 2,
        externalPinsChecked: 2,
      );
      final report = await const Sprint117DeveloperConnectorWorkflowGate()
          .evaluateWithDrill(touched);

      expect(report.violations, contains('live_provider_touched'));
      expect(report.violations, contains('user_project_touched'));
    });

    test('a missing consumer is an open item, never a silent pass', () async {
      final unconsumed = runOf([
        for (final id in requiredChecks) observation(id, passed: true),
      ], productionCaller: false);
      final report = await const Sprint117DeveloperConnectorWorkflowGate()
          .evaluateWithDrill(unconsumed);

      expect(
        report.status,
        Sprint117DeveloperConnectorWorkflowState.pass,
        reason: 'a missing consumer is an open item, not a failure',
      );
      expect(
        report.openItems,
        contains('no_shipped_consumer_for_developer_connector_managers'),
      );
    });
  });
}
