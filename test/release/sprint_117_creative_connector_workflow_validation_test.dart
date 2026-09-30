import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_creative_connector_workflow_validation.dart';

void main() {
  // The contract class is abstract on purpose, so it is read statically rather
  // than instantiated. A local `const` instance of it would not compile, and
  // wrapping it in a fake value class would reintroduce exactly the constant
  // the honesty machinery is meant to avoid.
  const List<String> requiredChecks =
      Sprint117CreativeConnectorWorkflowContract.requiredChecks;

  group('117.18 contract shape', () {
    test('names the six canonical evidence items in canonical order', () {
      expect(requiredChecks, hasLength(6));
      expect(requiredChecks, <String>[
        'asset_access',
        'rights',
        'attribution',
        'import',
        'export',
        'revoke',
      ]);
      expect(
        Sprint117CreativeConnectorWorkflowContract.canonicalStep,
        '117.18',
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
          .firstWhere((entry) => entry['id'] == '117.18');

      expect(step['title'], 'Creative Connector Workflow Validation');
      expect(step['required_evidence'], requiredChecks);
    });

    test('every committed source exists and states its own boundary', () {
      for (final path
          in Sprint117CreativeConnectorWorkflowContract.sourceManifests) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: path);
        final source =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final boundary =
            source['boundary'] ?? source['evidence_boundary'] ?? '';
        final limitations = source['limitations'];
        final externalGates = source['external_gates'];
        final declaresBoundary =
            (boundary is String && boundary.trim().isNotEmpty) ||
            (limitations is List && limitations.isNotEmpty) ||
            (externalGates is String && externalGates.trim().isNotEmpty);
        expect(declaresBoundary, isTrue, reason: path);
      }
    });
  });

  group('117.18 loader and anchor', () {
    test('reads the anchor, its declared acceptance, and both pins', () {
      final report = const Sprint117CreativeConnectorWorkflowGate().evaluate();

      expect(report.anchor, isNotNull);
      final anchor = report.anchor!;
      expect(anchor.externalPinsResolved, isTrue);
      expect(anchor.allExternalPinsMatch, isTrue);
      expect(
        anchor.declaredContractSizes.keys,
        containsAll(Sprint117CreativeConnectorWorkflowContract.sourceManifests),
      );
      for (final entry in anchor.declaredContractSizes.entries) {
        expect(entry.value, isNotEmpty, reason: entry.key);
      }
      // Only the certification sources promise rights records; the 115.29
      // contract manifest promises an acceptance list, so requiring records of
      // it would be the same false zero 117.17 removed.
      for (final path in <String>[
        Sprint117CreativeConnectorWorkflowContract.assetRights,
        Sprint117CreativeConnectorWorkflowContract.figmaCertification,
        Sprint117CreativeConnectorWorkflowContract
            .blenderSketchfabCertification,
      ]) {
        expect(
          anchor.rightsRecordsDeclared[path],
          greaterThan(0),
          reason: path,
        );
      }
      expect(
        anchor.rightsRecordsDeclared[Sprint117CreativeConnectorWorkflowContract
            .creativeTools],
        anyOf(isNull, 0),
        reason: '115.29 declares an acceptance list, not rights records',
      );
      expect(anchor.creativeAcceptanceDeclared, isTrue);
      expect(anchor.assetRightsFieldsDeclared, isTrue);
      expect(anchor.importExportAndAttributionDeclared, isTrue);
      expect(anchor.reauthBeforeSensitiveActionDeclared, isTrue);
      expect(anchor.disconnectProviderSensitiveAction, isTrue);
      expect(anchor.auditRedactionDeclared, isTrue);
    });

    test('builds one bound row per canonical check, each with a method', () {
      final report = const Sprint117CreativeConnectorWorkflowGate().evaluate();

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

  group('117.18 measured drill', () {
    late Sprint117CreativeConnectorWorkflowDrillRun run;

    setUpAll(() async {
      run = await const Sprint117CreativeConnectorWorkflowDrill().run();
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

    test('asset_access: permissions are deduplicated and immutable', () {
      final observation = run.observationFor('asset_access')!;
      expect(observation.passed, isTrue, reason: observation.outcome);
      expect(observation.facts['stored_permission_count'], 2);
      expect(observation.facts['duplicate_input_deduplicated'], isTrue);
      expect(observation.facts['permission_set_immutable'], isTrue);
      expect(observation.facts['empty_permissions_refused'], isTrue);
      expect(observation.facts['unverified_provider_refused'], isTrue);
      expect(observation.facts['non_creative_provider_refused'], isTrue);
      expect(observation.facts['creative_connectors_listed'], <String>[
        'canva',
        'figma',
      ]);
    });

    test('rights: every record declares every field and claims no license', () {
      final observation = run.observationFor('rights')!;
      expect(observation.passed, isTrue, reason: observation.outcome);
      expect(observation.facts['required_field_count'], 6);
      expect(observation.facts['every_required_field_declared'], isTrue);
      expect(observation.facts['record_count'], 2);
      expect(observation.facts['every_record_carries_every_field'], isTrue);
      expect(observation.facts['every_record_unverified'], isTrue);
    });

    test('attribution: required for licensed, preserved verbatim', () {
      final observation = run.observationFor('attribution')!;
      expect(observation.passed, isTrue, reason: observation.outcome);
      expect(observation.facts['licensed_without_attribution_refused'], isTrue);
      expect(observation.facts['blank_attribution_refused'], isTrue);
      expect(
        observation.facts['mixed_grant_without_attribution_refused'],
        isTrue,
      );
      expect(observation.facts['owned_asset_needs_no_attribution'], isTrue);
      expect(observation.facts['attribution_preserved_verbatim'], isTrue);
    });

    test('import: the scope is carried and cannot be rewritten', () {
      final observation = run.observationFor('import')!;
      expect(observation.passed, isTrue, reason: observation.outcome);
      expect(observation.facts['import_only_scope_recorded'], isTrue);
      expect(observation.facts['import_export_scope_recorded'], isTrue);
      expect(observation.facts['scope_carried_per_connection'], isTrue);
      expect(observation.facts['distinct_grants_stay_distinct'], isTrue);
      expect(observation.facts['scope_not_rewritable_after_grant'], isTrue);
    });

    test('export: the three grants stay distinct across a refusal', () {
      final observation = run.observationFor('export')!;
      expect(observation.passed, isTrue, reason: observation.outcome);
      expect(observation.facts['distinct_transfer_scopes'], 3);
      expect(
        observation.facts['import_only_not_reported_as_import_export'],
        isTrue,
      );
      expect(observation.facts['grant_survives_refused_disconnect'], isTrue);
      expect(observation.facts['connection_kept_after_refusal'], 1);
    });

    test('revoke: gated, fail-closed, rights intact, audited', () {
      final observation = run.observationFor('revoke')!;
      expect(observation.passed, isTrue, reason: observation.outcome);
      expect(observation.facts['gate_refusal_returned_false'], isTrue);
      expect(observation.facts['refusal_kept_the_connection'], isTrue);
      expect(observation.facts['rights_intact_after_refusal'], isTrue);
      expect(observation.facts['refusal_audited'], isTrue);
      expect(observation.facts['ungated_seam_fails_closed'], isTrue);
      expect(observation.facts['unconfirmed_cannot_disconnect'], isTrue);
      expect(observation.facts['allowed_disconnect_ended_connection'], isTrue);
      expect(observation.facts['success_audited'], isTrue);
      expect(observation.facts['audit_rows_carry_no_rights_material'], isTrue);
      expect(observation.facts['audit_actions'], <String>[
        'connect',
        'disconnect',
      ]);
    });
  });

  group('117.18 gate decisions', () {
    test(
      'the measured run passes with full coverage and no violation',
      () async {
        final report = await const Sprint117CreativeConnectorWorkflowGate()
            .evaluateWithDrill();

        expect(
          report.status,
          Sprint117CreativeConnectorWorkflowState.pass,
          reason:
              'missing=${report.missingFields} violations=${report.violations}',
        );
        expect(report.verdict, 'CREATIVE_CONNECTOR_WORKFLOW_VALIDATED_LOCAL');
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
        final report = await const Sprint117CreativeConnectorWorkflowGate()
            .evaluateWithDrill();

        expect(
          report.openItems,
          contains('creative_connector_workflow_defined_not_executed_live'),
        );
        expect(
          report.openItems,
          contains('external_connector_specs_outside_repository'),
        );
        // Measured, not asserted: the creative connector manager has no
        // consumer under lib/ outside this harness.
        expect(
          report.openItems,
          contains('no_shipped_consumer_for_creative_connector_manager'),
        );
        // Measured: `transferScope` is stored but read by no shipped file, so
        // the declared import/export boundary has no enforcement behind it.
        expect(
          report.openItems,
          contains(
            'transfer_scope_declared_but_never_enforced_by_shipped_code',
          ),
        );
      },
    );

    test('a run without a drill is blocked, never passed on prose', () {
      final report = const Sprint117CreativeConnectorWorkflowGate().evaluate();

      expect(report.status, Sprint117CreativeConnectorWorkflowState.blocked);
      expect(
        report.verdict,
        'CREATIVE_CONNECTOR_WORKFLOW_BLOCKED_NO_LOCAL_EVIDENCE',
      );
      expect(report.missingFields, contains('drill_run'));
      expect(report.coverage, 0.0);
      // A run that measured nothing claims no integration gap either.
      expect(
        report.openItems,
        isNot(contains('no_shipped_consumer_for_creative_connector_manager')),
      );
      expect(
        report.openItems,
        isNot(
          contains(
            'transfer_scope_declared_but_never_enforced_by_shipped_code',
          ),
        ),
      );
    });

    test(
      'the report serializes to valid JSON carrying its own decision',
      () async {
        final report = await const Sprint117CreativeConnectorWorkflowGate()
            .evaluateWithDrill();
        final json =
            jsonDecode(jsonEncode(report.toJson())) as Map<String, dynamic>;

        expect(json['canonical_step'], '117.18');
        expect(json['status'], 'pass');
        expect(json['verdict'], 'CREATIVE_CONNECTOR_WORKFLOW_VALIDATED_LOCAL');
        expect(json['coverage'], 1.0);
        expect((json['checks'] as List<dynamic>), hasLength(6));
        expect(json['anchor'], isA<Map<String, dynamic>>());
        expect(
          (json['anchor'] as Map<String, dynamic>)['external_pins_matched'],
          2,
        );
        expect(
          (json['anchor'] as Map<String, dynamic>)['audit_redaction_declared'],
          isTrue,
        );
      },
    );
  });

  group('117.18 gate rejects a contradictory or unrun measurement', () {
    Sprint117CreativeConnectorWorkflowObservation observation(
      String checkId, {
      required bool passed,
      bool mechanismPresent = true,
    }) => Sprint117CreativeConnectorWorkflowObservation(
      checkId: checkId,
      outcome: passed ? 'OK' : 'BROKEN',
      facts: <String, Object?>{
        'acceptance_mechanism_present': mechanismPresent,
      },
      passed: passed,
    );

    Sprint117CreativeConnectorWorkflowDrillRun runOf(
      List<Sprint117CreativeConnectorWorkflowObservation> observations, {
      int pinsMatched = 2,
      int pinsChecked = 2,
      bool productionCaller = true,
      bool transferScopeEnforced = true,
    }) => Sprint117CreativeConnectorWorkflowDrillRun(
      observations: observations,
      liveProviderTouched: false,
      userProjectTouched: false,
      liveCredentialObserved: false,
      externalPinsMatched: pinsMatched,
      externalPinsChecked: pinsChecked,
      productionCallerPresent: productionCaller,
      transferScopeEnforcedSomewhere: transferScopeEnforced,
    );

    test('a failed observation fails the gate and names the outcome', () async {
      final broken = runOf([
        for (final id in requiredChecks)
          observation(id, passed: id != 'attribution'),
      ]);
      final report = await const Sprint117CreativeConnectorWorkflowGate()
          .evaluateWithDrill(broken);

      expect(report.status, Sprint117CreativeConnectorWorkflowState.fail);
      expect(report.verdict, 'CREATIVE_CONNECTOR_WORKFLOW_INCONSISTENT');
      expect(
        report.violations,
        contains('drill_observation_failed:attribution'),
      );
      expect(report.violations, contains('drill_outcome:BROKEN'));
    });

    test(
      'a check claiming acceptance without a mechanism is a violation',
      () async {
        final contradicted = runOf([
          for (final id in requiredChecks)
            observation(id, passed: true, mechanismPresent: id != 'revoke'),
        ]);
        final report = await const Sprint117CreativeConnectorWorkflowGate()
            .evaluateWithDrill(contradicted);

        expect(report.status, Sprint117CreativeConnectorWorkflowState.fail);
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
        final report = await const Sprint117CreativeConnectorWorkflowGate()
            .evaluateWithDrill(drifted);

        expect(report.status, Sprint117CreativeConnectorWorkflowState.fail);
        expect(report.violations, contains('external_source_drift'));
      },
    );

    test('touching a live provider or a user project fails the gate', () async {
      final touched = Sprint117CreativeConnectorWorkflowDrillRun(
        observations: [
          for (final id in requiredChecks) observation(id, passed: true),
        ],
        liveProviderTouched: true,
        userProjectTouched: true,
        liveCredentialObserved: false,
        externalPinsMatched: 2,
        externalPinsChecked: 2,
      );
      final report = await const Sprint117CreativeConnectorWorkflowGate()
          .evaluateWithDrill(touched);

      expect(report.violations, contains('live_provider_touched'));
      expect(report.violations, contains('user_project_touched'));
    });

    test('a missing consumer is an open item, never a silent pass', () async {
      final unconsumed = runOf([
        for (final id in requiredChecks) observation(id, passed: true),
      ], productionCaller: false);
      final report = await const Sprint117CreativeConnectorWorkflowGate()
          .evaluateWithDrill(unconsumed);

      expect(
        report.status,
        Sprint117CreativeConnectorWorkflowState.pass,
        reason: 'a missing consumer is an open item, not a failure',
      );
      expect(
        report.openItems,
        contains('no_shipped_consumer_for_creative_connector_manager'),
      );
    });

    test(
      'an unenforced transfer scope is an open item, never a silent pass',
      () async {
        final unenforced = runOf([
          for (final id in requiredChecks) observation(id, passed: true),
        ], transferScopeEnforced: false);
        final report = await const Sprint117CreativeConnectorWorkflowGate()
            .evaluateWithDrill(unenforced);

        expect(
          report.status,
          Sprint117CreativeConnectorWorkflowState.pass,
          reason: 'a declared-but-unenforced scope is a gap, not a failure',
        );
        expect(
          report.openItems,
          contains(
            'transfer_scope_declared_but_never_enforced_by_shipped_code',
          ),
        );
      },
    );
  });
}
