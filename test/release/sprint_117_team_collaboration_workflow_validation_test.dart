// Sprint 117.19 — Team & Collaboration Validation acceptance suite.
//
// The gate and the drill are deliberately separate classes: the drill
// executes the shipped membership mechanisms and prints raw measured facts,
// the loader reads the committed manifests, and the gate only decides whether
// the two agree. Every fact below is measured; none is a constant.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_team_collaboration_workflow_validation.dart';
import '../canonical_source_support.dart';

void main() {
  group('117.19 external canonical step', () {
    test('the external canonical step declares exactly these seven items', () {
      if (skipUnlessExternalCanonical(
        "the external canonical step declares exactly these seven items",
      )) {
        return;
      }
      // Pinned by sha256 in the loader, so the read below is of the file the
      // contract actually depends on rather than of whichever pin happens to
      // sort first.
      final file = File(
        'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/'
        'sprint_117.json',
      );
      expect(file.existsSync(), isTrue, reason: 'canonical sprint file pinned');

      final decoded = jsonDecode(file.readAsStringSync());
      final steps = (decoded as Map<String, dynamic>)['steps'] as List<dynamic>;
      final step = steps.cast<Map<String, dynamic>>().firstWhere(
        (entry) => entry['id'] == '117.19',
      );

      expect(step['title'], 'Team & Collaboration Validation');
      // Read from the canonical file, not from a copy of the list: a constant
      // here would make the gate's contract look declared by something that
      // never opened the source.
      expect(
        (step['required_evidence'] as List<dynamic>).cast<String>(),
        Sprint117TeamCollaborationWorkflowContract.requiredChecks,
      );
    });
  });

  group('117.19 loader and anchor', () {
    late Sprint117TeamCollaborationWorkflowReport report;

    setUpAll(() {
      report = const Sprint117TeamCollaborationWorkflowGate().evaluate();
    });

    test('reads the anchor, its declared acceptance, and both pins', () {
      if (skipUnlessExternalCanonical(
        "reads the anchor, its declared acceptance, and both pins",
      )) {
        return;
      }
      expect(report.anchor, isNotNull);
      final anchor = report.anchor!;
      expect(anchor.externalPinsResolved, isTrue);
      expect(anchor.allExternalPinsMatch, isTrue);

      // Every committed source declares a contract, and each says where its
      // own evidence stops.
      for (final entry in anchor.declaredContractSizes.entries) {
        expect(
          entry.value.trim(),
          isNotEmpty,
          reason: '${entry.key} must declare a contract',
        );
      }
      for (final entry in anchor.boundariesDeclared.entries) {
        expect(
          entry.value,
          isTrue,
          reason: '${entry.key} must state its own boundary',
        );
      }

      // 115.30 declares all six of its own acceptance items.
      expect(anchor.teamAcceptanceDeclared, isTrue);
      expect(anchor.seatCountDeclared, isTrue);
      expect(anchor.pendingInvitesDeclared, isTrue);
      expect(anchor.permissionHealthDeclared, isTrue);

      // The guarantees live in the external spec the manifests point at, so
      // they are read from the spec and not from a manifest that never
      // promised them.
      expect(anchor.reauthBeforeSensitiveActionDeclared, isTrue);
      expect(anchor.removeTeamMemberSensitiveAction, isTrue);
      expect(anchor.auditRedactionDeclared, isTrue);
    });
  });

  group('117.19 gate', () {
    test('without a drill it is blocked, never passed on prose', () {
      if (skipUnlessExternalCanonical(
        "without a drill it is blocked, never passed on prose",
      )) {
        return;
      }
      final report = const Sprint117TeamCollaborationWorkflowGate().evaluate();

      expect(report.status, Sprint117TeamCollaborationWorkflowState.blocked);
      expect(report.verdict, contains('BLOCKED'));
      expect(report.missingFields, contains('drill_run'));
      // An undetermined check is an open item, not a violation invented by the
      // gate for something nobody ran.
      expect(
        report.violations,
        isNot(contains('check_outcome_contradicts_drill')),
      );
      expect(
        report.undeterminedChecks,
        containsAll(Sprint117TeamCollaborationWorkflowContract.requiredChecks),
      );
      // Coverage cannot reach 1.0 while nothing has been decided.
      expect(report.coverage, 0.0);
    });

    test(
      'a measured run passes with full coverage and no violations',
      () async {
        if (skipUnlessExternalCanonical(
          "a measured run passes with full coverage and no violations",
        )) {
          return;
        }
        final report = await const Sprint117TeamCollaborationWorkflowGate()
            .evaluateWithDrill();

        expect(report.status, Sprint117TeamCollaborationWorkflowState.pass);
        expect(report.verdict, 'TEAM_COLLABORATION_WORKFLOW_VALIDATED_LOCAL');
        expect(report.missingFields, isEmpty);
        expect(report.violations, isEmpty);
        expect(report.unmappedChecks, isEmpty);
        expect(report.undeterminedChecks, isEmpty);
        expect(report.coverage, 1.0);

        // Every canonical item was decided by its own measured observation, and
        // the rows keep the canonical order rather than an alphabetical one.
        expect(
          report.checks.map((check) => check.checkId),
          Sprint117TeamCollaborationWorkflowContract.requiredChecks,
        );
        expect(
          report.checks.map((check) => check.checkId).toSet(),
          Sprint117TeamCollaborationWorkflowContract.requiredChecks.toSet(),
          reason: 'no canonical item may be missing or duplicated',
        );
        for (final check in report.checks) {
          expect(check.executed, isTrue, reason: '${check.checkId} executed');
          expect(check.liveProviderResult, isFalse);
          expect(check.drilledAgainstLiveProvider, isFalse);
        }
        expect(
          report.acceptanceSatisfied,
          Sprint117TeamCollaborationWorkflowContract.requiredChecks,
        );
        expect(report.acceptanceUnmet, isEmpty);

        // The run touched nothing real.
        final run = report.acceptanceSatisfied;
        expect(run, hasLength(7));
      },
    );

    test('a run that claims a live provider is a violation', () async {
      final drill = await const Sprint117TeamCollaborationWorkflowDrill().run();
      final tampered = Sprint117TeamCollaborationWorkflowDrillRun(
        observations: drill.observations,
        liveProviderTouched: true,
        userProjectTouched: false,
        liveCredentialObserved: false,
        externalPinsMatched: drill.externalPinsMatched,
        externalPinsChecked: drill.externalPinsChecked,
      );
      final report = const Sprint117TeamCollaborationWorkflowGate()
          .evaluateWith(
            const Sprint117TeamCollaborationWorkflowLoader().loadWithDrill(
              tampered,
            ),
          );

      expect(report.status, Sprint117TeamCollaborationWorkflowState.fail);
      expect(report.violations, contains('live_provider_touched'));
    });

    test('an unreadable external pin blocks instead of passing', () {
      const input = Sprint117TeamCollaborationWorkflowInput(
        rows: <Sprint117TeamCollaborationWorkflowCheck>[],
        anchor: null,
        drillRun: null,
      );
      final report = const Sprint117TeamCollaborationWorkflowGate()
          .evaluateWith(input);

      expect(report.status, Sprint117TeamCollaborationWorkflowState.blocked);
      expect(report.missingFields, contains('team_collaboration_anchor'));
      // Without an anchor nothing counts as decided, so a green-looking
      // coverage is unreachable.
      expect(report.coverage, 0.0);
    });
  });

  group('117.19 measured observations', () {
    late Sprint117TeamCollaborationWorkflowDrillRun run;

    setUpAll(() async {
      run = await const Sprint117TeamCollaborationWorkflowDrill().run();
    });

    test('nothing real was touched and no pin drifted', () {
      if (skipUnlessExternalCanonical(
        "nothing real was touched and no pin drifted",
      )) {
        return;
      }
      expect(run.liveProviderTouched, isFalse);
      expect(run.userProjectTouched, isFalse);
      expect(run.liveCredentialObserved, isFalse);
      expect(run.externalPinsResolved, isTrue);
      expect(run.allExternalPinsMatchForDrill, isTrue);
    });

    test('each canonical item is decided by its own measured fact', () {
      expect(
        run.observations.map((entry) => entry.checkId),
        Sprint117TeamCollaborationWorkflowContract.requiredChecks,
      );
      for (final observation in run.observations) {
        expect(observation.passed, isTrue, reason: observation.outcome);
        expect(observation.outcome, isNotEmpty);
        expect(observation.facts, isNotEmpty);
      }
    });

    test('member removal is measured as gated, not merely claimed', () {
      final observation = run.observationFor('member_removal')!;
      expect(observation.facts['ungated_removal_refused'], isTrue);
      expect(observation.facts['member_survived_ungated_attempt'], isTrue);
      expect(observation.facts['gate_refusal_refused_removal'], isTrue);
      expect(observation.facts['stranger_cannot_remove'], isTrue);
      expect(
        observation.facts['member_without_permission_cannot_remove'],
        isTrue,
      );
      expect(observation.facts['last_administrator_kept'], isTrue);
      expect(observation.facts['permitted_removal_succeeded'], isTrue);
      expect(observation.facts['seat_released_after_removal'], isTrue);
      // The mechanism facts are read off the shipped source, so a future
      // rename makes them false instead of leaving a constant behind.
      for (final key in <String>[
        'acceptance_mechanism_present',
        'gate_mechanism_present',
        'permission_mechanism_present',
        'last_admin_mechanism_present',
        'denied_audit_mechanism_present',
      ]) {
        expect(observation.facts[key], isTrue, reason: key);
      }
    });

    test('audit refusals are visible and carry no authority material', () {
      final observation = run.observationFor('audit')!;
      expect(observation.facts['removal_events'], 1);
      // Both the gate's refusal and the unknown target are refused attempts.
      expect(observation.facts['denied_removal_events'], 2);
      expect(observation.facts['refusals_visible'], isTrue);
      expect(observation.facts['both_refusals_named'], isTrue);
      expect(observation.facts['removal_attributed_to_actor'], isTrue);
      expect(observation.facts['refused_seat_audited'], isTrue);
      expect(
        observation.facts['audit_leaks_role_or_permission_or_secret'],
        isFalse,
      );
      expect(observation.facts['audit_ring_capped'], isTrue);
    });

    test('the measured gaps are reported, never folded into a pass', () {
      if (skipUnlessExternalCanonical(
        "the measured gaps are reported, never folded into a pass",
      )) {
        return;
      }
      // This seam IS reachable from main.dart (app_router renders
      // StudioManagementPanel from DemoStudio.registry), so the caller is
      // present and the open item must NOT claim otherwise. The scan proved
      // that on repository-relative paths: the previous absolute-path filter
      // matched 0 of 2891 Dart files and produced a false zero.
      expect(run.productionCallerPresent, isTrue);
      final report = const Sprint117TeamCollaborationWorkflowGate()
          .evaluateWith(
            const Sprint117TeamCollaborationWorkflowLoader().loadWithDrill(run),
          );
      expect(
        report.openItems,
        isNot(contains('no_shipped_consumer_for_membership_registry')),
      );

      // Measured absences, each reported as its own open item.
      //
      // `invitationLifecycleEnforcedSomewhere` used to be asserted false, and
      // that was true when the slice landed. It stopped being true when a later
      // slice shipped `TeamInvitationRegistry`, which genuinely moves an
      // invitation through pending -> accepted and inserts the member. The
      // probe now requires a file that both acts on a status AND seats a
      // member, so it finds that registry and retires the open item on
      // evidence rather than on a hardcoded expectation that would have kept
      // reporting a gap the product has genuinely closed.
      expect(run.invitationLifecycleEnforcedSomewhere, isTrue);
      expect(run.invitationLifecycleCallSites, greaterThan(0));
      expect(
        report.openItems,
        isNot(
          contains('invitation_status_declared_but_no_lifecycle_enforces_it'),
        ),
      );

      // The other half is still an open gap and is asserted as one:
      // `computePermissionHealth()` derives health from its own local rules
      // (empty roster, missing owner) and never consults the role matrix, so
      // the probe that requires a real matrix read still measures zero.
      expect(run.permissionHealthComputedSomewhere, isFalse);
      expect(run.permissionHealthComputationCallSites, 0);

      expect(report.status, Sprint117TeamCollaborationWorkflowState.pass);
      expect(
        report.openItems,
        containsAll(<String>[
          'permission_health_supplied_by_caller_never_computed_from_role_matrix',
          'team_collaboration_workflow_defined_not_executed_live',
          'external_identity_provider_outside_repository',
        ]),
      );
      // An open item is not a violation, so the report still passes.
      expect(report.violations, isEmpty);
    });
  });

  group('117.19 report shape', () {
    test('serializes every section a manifest reader needs', () async {
      if (skipUnlessExternalCanonical(
        "serializes every section a manifest reader needs",
      )) {
        return;
      }
      final report = await const Sprint117TeamCollaborationWorkflowGate()
          .evaluateWithDrill();
      final json = report.toJson();
      final decoded = jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

      expect(decoded['canonical_step'], '117.19');
      expect(decoded['status'], 'pass');
      expect(decoded['coverage'], 1.0);
      expect((decoded['checks'] as List<dynamic>), hasLength(7));

      final anchor = decoded['anchor'] as Map<String, dynamic>;
      expect(anchor['external_pins_matched'], 2);
      expect(anchor['remove_team_member_sensitive_action'], isTrue);
      expect(anchor['reauth_before_sensitive_action_declared'], isTrue);
      expect(anchor['audit_redaction_declared'], isTrue);
    });
  });
}
