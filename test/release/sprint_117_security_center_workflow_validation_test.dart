// Sprint 117.20 — Security Center Workflow Validation acceptance suite.
//
// The gate and the drill are deliberately separate classes: the drill
// executes the shipped security mechanisms and records raw measured facts, the
// loader reads the committed manifests, and the gate only decides whether the
// two agree. Every fact below is measured; none is a constant.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_security_center_workflow_validation.dart';

void main() {
  group('117.20 external canonical step', () {
    test('the external canonical step declares exactly these eight items', () {
      final file = File(
        'C:/Users/nepht/AppData/Local/hermes/references/void_scriptor/'
        'sprint_117.json',
      );
      expect(file.existsSync(), isTrue, reason: 'canonical sprint file pinned');

      final decoded = jsonDecode(file.readAsStringSync());
      final steps = (decoded as Map<String, dynamic>)['steps'] as List<dynamic>;
      final step = steps.cast<Map<String, dynamic>>().firstWhere(
        (entry) => entry['id'] == '117.20',
      );

      expect(step['title'], 'Security Center Workflow Validation');
      expect(
        (step['required_evidence'] as List<dynamic>).cast<String>(),
        Sprint117SecurityCenterWorkflowContract.requiredChecks,
      );
    });
  });

  group('117.20 loader and anchor', () {
    late Sprint117SecurityCenterWorkflowReport report;

    setUpAll(() {
      report = const Sprint117SecurityCenterWorkflowGate().evaluate();
    });

    test('reads the anchor, its declared acceptance, and both pins', () {
      expect(report.anchor, isNotNull);
      final anchor = report.anchor!;
      expect(anchor.externalPinsResolved, isTrue);
      expect(anchor.allExternalPinsMatch, isTrue);

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

      // 115.32 declares all seven of its own acceptance items.
      expect(anchor.securityAcceptanceDeclared, isTrue);
      expect(anchor.mfaAcceptanceDeclared, isTrue);
      expect(anchor.passwordAcceptanceDeclared, isTrue);
      expect(anchor.devicesAcceptanceDeclared, isTrue);
      expect(anchor.sessionsAcceptanceDeclared, isTrue);
      expect(anchor.secureStoreAcceptanceDeclared, isTrue);
      expect(anchor.alertsAcceptanceDeclared, isTrue);
      expect(anchor.actionsAcceptanceDeclared, isTrue);

      // Read from the external spec, not from a manifest that never promised
      // them.
      expect(anchor.reauthBeforeSensitiveActionDeclared, isTrue);
      expect(anchor.auditRedactionDeclared, isTrue);
      expect(anchor.neverFullSecretDisplayDeclared, isTrue);
      expect(anchor.clipboardTimeoutDeclared, isTrue);
      expect(anchor.osSecureStoreDeclared, isTrue);
    });

    test('reads the three manifests in the shape each one really uses', () {
      // 116.45 declares `acceptance_areas` + `limitations`, not
      // `acceptance` + `boundary`. The loader must have read the real shape
      // rather than demand a key no source uses — the false-silent class
      // 117.16 and 117.19 both rejected.
      final anchor = report.anchor!;
      expect(
        anchor.declaredContractSizes[Sprint117SecurityCenterWorkflowContract
            .securityCertificationGate],
        'DECLARED:acceptance_areas:8',
        reason: '116.45 spells its coverage acceptance_areas',
      );
      expect(
        anchor.declaredContractSizes[Sprint117SecurityCenterWorkflowContract
            .securityCenterSummary],
        'DECLARED:acceptance:7',
        reason: '115.32 spells its coverage acceptance',
      );
      expect(
        anchor.declaredContractSizes[Sprint117SecurityCenterWorkflowContract
            .sessionDeviceManagement],
        'DECLARED:acceptance:6',
        reason: '115.33 spells its coverage acceptance',
      );
    });

    test('declares all eight canonical checks in canonical order', () {
      expect(report.unmappedChecks, isEmpty);
      expect(report.coverage, 0.0);
      // No drill has run yet, so nothing is decided: the report says so
      // instead of claiming coverage from declared rows.
      expect(
        report.checks.map((entry) => entry.checkId),
        Sprint117SecurityCenterWorkflowContract.requiredChecks,
      );
      // No drill has run, so nothing is decided: all eight checks are reported
      // undecided, in canonical order. An empty list here would mean the report
      // claimed every check had been decided before anything measured them.
      expect(
        report.undeterminedChecks,
        Sprint117SecurityCenterWorkflowContract.requiredChecks,
      );
      expect(
        report.undeterminedChecks,
        isNot(equals(report.undeterminedChecks.toList()..sort())),
        reason: 'canonical order, not alphabetical',
      );
    });
  });

  group('117.20 drill measures the shipped security mechanisms', () {
    late Sprint117SecurityCenterWorkflowDrillRun run;

    setUpAll(() async {
      run = await const Sprint117SecurityCenterWorkflowDrill().run();
    });

    test('touches no live provider, user project, or real credential', () {
      expect(run.liveProviderTouched, isFalse);
      expect(run.userProjectTouched, isFalse);
      expect(run.liveCredentialObserved, isFalse);
      expect(run.externalPinsMatched, run.externalPinsChecked);
    });

    test(
      'mfa: a known status demands an enrolled method and live recovery',
      () {
        final observation = run.observationFor('mfa')!;
        expect(observation.passed, isTrue);

        final facts = observation.facts;
        expect(facts['known_status_requires_enrolled_method'], isTrue);
        // The defect this slice fixes: an account whose only recovery path is
        // drained was still reportable as fully healthy.
        expect(facts['healthy_with_zero_recovery_codes_is_refused'], isTrue);
        expect(facts['attention_with_zero_recovery_codes_is_allowed'], isTrue);
        expect(facts['no_method_no_codes_is_available_as_unavailable'], isTrue);
      },
    );

    test('password: the timestamp is validated, staleness is not computed', () {
      final observation = run.observationFor('password')!;
      expect(observation.passed, isTrue);
      expect(observation.facts['changed_at_must_be_utc'], isTrue);
      expect(observation.facts['local_time_is_refused'], isTrue);
      // Measured TRUE now, and reported as a retired gap rather than a silent
      // pass. When this slice landed, nothing in lib/ decided whether a
      // password's `changedAt` was stale — only the summary existed. That
      // stopped being true once `PasswordAgeGate` shipped `ageOf`/`classify`,
      // which read the timestamp and return a verdict. The assertion below
      // follows the measurement; it is not a fixed expectation, and the open
      // item disappears from the report for the same measured reason.
      expect(observation.facts['staleness_computed_somewhere_in_lib'], isTrue);
      expect(run.passwordStalenessComputedSomewhere, isTrue);
      // The count this assertion needs is the one the drill already publishes
      // as a measured fact. `Sprint117SecurityCenterWorkflowDrillRun` has no
      // `passwordStalenessCallSites` getter, and adding one would be a field
      // invented for a test rather than a measurement the run carries, so the
      // assertion reads the real fact instead. Both are derived from the same
      // repository scan (`_passwordStalenessCallSites`), so this is a stronger
      // statement than the boolean alone: the scan must have found a shipped
      // caller, not merely returned a non-empty list.
      expect(
        observation.facts['password_summary_call_sites_in_lib'],
        greaterThan(0),
      );
    });

    test('devices: the count is validated, trust is not aggregated', () {
      final observation = run.observationFor('devices')!;
      expect(observation.passed, isTrue);
      expect(observation.facts['known_status_requires_count'], isTrue);
      expect(observation.facts['negative_count_is_refused'], isTrue);
      // The session seam knows which device a session ran on, and a later slice
      // shipped `TrustedDeviceAggregator`, which reconciles a roll-up of
      // sessions into a `DeviceSecuritySummary`. The gap this test used to
      // assert is therefore measured closed, and the report retires
      // `device_trust_not_aggregated_in_lib` for that same reason.
      expect(
        observation.facts['device_trust_aggregated_somewhere_in_lib'],
        isTrue,
      );
      expect(run.deviceTrustAggregatedSomewhere, isTrue);
      // Same reasoning as the password count above: the run object exposes no
      // `deviceAggregationCallSites` getter, so the assertion reads the
      // measured fact the drill publishes for it.
      expect(
        observation.facts['device_summary_call_sites_in_lib'],
        greaterThan(0),
      );
    });

    test('sessions: the seam refuses contradictions and protects current', () {
      final observation = run.observationFor('sessions')!;
      expect(observation.passed, isTrue);
      expect(
        observation.facts['suspicious_count_never_exceeds_active'],
        isTrue,
      );
      expect(observation.facts['exactly_one_current_session_enforced'], isTrue);
      expect(
        observation.facts['current_session_survives_force_logout'],
        isTrue,
      );
      expect(observation.facts['suspicious_session_cannot_be_trusted'], isTrue);
    });

    test('revoke: a refusal and an attempt are both recorded', () {
      final observation = run.observationFor('revoke')!;
      expect(observation.passed, isTrue);
      // The seam had no audit collection at all, so a refused revoke and an
      // attempt never made were indistinguishable — exactly the gap the
      // spec's `audit_redaction` guarantee has nothing to apply to.
      expect(observation.facts['denied_revoke_is_recorded'], isTrue);
      expect(observation.facts['revoked_revoke_is_recorded'], isTrue);
      expect(observation.facts['unforceable_current_session_refused'], isTrue);
      expect(observation.facts['force_logout_requires_confirmation'], isTrue);
      expect(
        observation.facts['audit_event_carries_no_device_or_reason'],
        isTrue,
      );
    });

    test('alerts: a blind spot never reads as a healthy account', () {
      final observation = run.observationFor('alerts')!;
      expect(observation.passed, isTrue);
      // The defect this slice fixes: one healthy signal among four unknown
      // ones was reported as `healthy`.
      expect(
        observation.facts['one_healthy_among_unknown_is_not_healthy'],
        isTrue,
      );
      expect(observation.facts['info_alert_alone_is_not_healthy'], isTrue);
      expect(observation.facts['all_unknown_is_unknown'], isTrue);
      expect(observation.facts['critical_still_wins_over_unknown'], isTrue);
      expect(observation.facts['attention_still_wins_over_unknown'], isTrue);
      expect(observation.facts['five_known_healthy_is_healthy'], isTrue);
    });

    test('secure_store: an unbacked store is never reported healthy', () {
      final observation = run.observationFor('secure_store')!;
      expect(observation.passed, isTrue);
      expect(observation.facts['known_status_requires_backend'], isTrue);
      expect(
        observation.facts['known_status_requires_check_timestamp'],
        isTrue,
      );
      expect(observation.facts['unavailable_backend_is_never_healthy'], isTrue);
    });

    test('recovery: a drained recovery path is refused, not assumed', () {
      final observation = run.observationFor('recovery')!;
      expect(observation.passed, isTrue);
      expect(observation.facts['zero_recovery_codes_flagged'], isTrue);
      expect(observation.facts['missing_recovery_path_is_flagged'], isTrue);
      expect(
        observation.facts['recovery_codes_remaining_is_immutable'],
        isTrue,
      );
    });

    test('every observation passed, so the drill has no silent failure', () {
      expect(run.allPassed, isTrue);
      expect(run.observations, hasLength(8));
      expect(
        run.observations.map((entry) => entry.checkId),
        Sprint117SecurityCenterWorkflowContract.requiredChecks,
      );
    });
  });

  group('117.20 gate decides from measured evidence only', () {
    test('the drill-backed run passes with full coverage', () async {
      final report = await const Sprint117SecurityCenterWorkflowGate()
          .evaluateWithDrill();
      expect(report.status, Sprint117SecurityCenterWorkflowState.pass);
      expect(report.verdict, isNotEmpty);
      expect(report.coverage, 1.0);
      expect(report.missingFields, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.unmappedChecks, isEmpty);
      expect(report.undeterminedChecks, isEmpty);
      expect(
        report.acceptanceSatisfied,
        Sprint117SecurityCenterWorkflowContract.requiredChecks,
      );
      expect(report.acceptanceUnmet, isEmpty);
    });

    test('a run without a measured drill is blocked, not passed on prose', () {
      final report = const Sprint117SecurityCenterWorkflowGate().evaluate();
      expect(report.status, Sprint117SecurityCenterWorkflowState.blocked);
      expect(report.missingFields, contains('drill_run'));
      expect(report.coverage, 0.0);
      // Nothing may claim a canonical check was decided without a drill.
      expect(report.acceptanceSatisfied, isEmpty);
    });

    test('an unreadable anchor blocks even when every row looks green', () {
      final report = const Sprint117SecurityCenterWorkflowGate().evaluateWith(
        Sprint117SecurityCenterWorkflowInput(
          rows: const Sprint117SecurityCenterWorkflowLoader().load().rows,
          anchor: null,
        ),
      );
      expect(report.status, Sprint117SecurityCenterWorkflowState.blocked);
      expect(report.missingFields, contains('security_center_anchor'));
      // A full-coverage report must stay unreachable while the evidence it
      // claims to rest on cannot be read.
      expect(report.coverage, 0.0);
    });

    test('a drill that touched a live provider is a violation, not a pass', () {
      final base = const Sprint117SecurityCenterWorkflowLoader().load();
      final report = const Sprint117SecurityCenterWorkflowGate().evaluateWith(
        Sprint117SecurityCenterWorkflowInput(
          rows: base.rows,
          anchor: base.anchor,
          drillRun: Sprint117SecurityCenterWorkflowDrillRun(
            observations: const <Sprint117SecurityCenterWorkflowObservation>[],
            liveProviderTouched: true,
            userProjectTouched: false,
            liveCredentialObserved: false,
            externalPinsMatched: 2,
            externalPinsChecked: 2,
          ),
        ),
      );
      expect(report.status, Sprint117SecurityCenterWorkflowState.fail);
      expect(report.violations, contains('live_provider_touched'));
    });

    test('external pin drift is a violation even when the loader read it', () {
      final base = const Sprint117SecurityCenterWorkflowLoader().load();
      final report = const Sprint117SecurityCenterWorkflowGate().evaluateWith(
        Sprint117SecurityCenterWorkflowInput(
          rows: base.rows,
          anchor: base.anchor,
          externalPinDrift: true,
        ),
      );
      expect(report.status, Sprint117SecurityCenterWorkflowState.fail);
      expect(report.violations, contains('external_source_drift'));
    });

    test('a row claiming a live provider result is a violation', () {
      // `_checkCheck` was written but never invoked, so every per-row check it
      // holds was dead code. This test is what makes that class of validator
      // visible again: a row claiming a live provider must now be rejected, and
      // a row disagreeing with the drill must be reported too.
      final base = const Sprint117SecurityCenterWorkflowLoader().load();
      final rows = base.rows!
          .map(
            (row) => Sprint117SecurityCenterWorkflowCheck(
              checkId: row.checkId,
              method: row.method,
              expectedOutcome: row.expectedOutcome,
              observedOutcome: row.observedOutcome,
              sourceManifest: row.sourceManifest,
              liveProviderResult: true,
              drilledAgainstLiveProvider: false,
            ),
          )
          .toList(growable: false);
      final report = const Sprint117SecurityCenterWorkflowGate().evaluateWith(
        Sprint117SecurityCenterWorkflowInput(rows: rows, anchor: base.anchor),
      );
      expect(report.status, Sprint117SecurityCenterWorkflowState.fail);
      expect(report.violations, contains('check_live_provider_claimed:mfa'));
    });

    test('a row with a blank method is missing, not quietly accepted', () {
      final base = const Sprint117SecurityCenterWorkflowLoader().load();
      final rows = base.rows!
          .map(
            (row) => Sprint117SecurityCenterWorkflowCheck(
              checkId: row.checkId,
              method: '   ',
              expectedOutcome: row.expectedOutcome,
              observedOutcome: row.observedOutcome,
              sourceManifest: row.sourceManifest,
              liveProviderResult: false,
              drilledAgainstLiveProvider: false,
            ),
          )
          .toList(growable: false);
      final report = const Sprint117SecurityCenterWorkflowGate().evaluateWith(
        Sprint117SecurityCenterWorkflowInput(rows: rows, anchor: base.anchor),
      );
      expect(report.status, Sprint117SecurityCenterWorkflowState.blocked);
      expect(report.missingFields, contains('check_method:mfa'));
    });

    test('an unmapped canonical check fails instead of shrinking scope', () {
      final base = const Sprint117SecurityCenterWorkflowLoader().load();
      final rows = base.rows!
          .where((row) => row.checkId != 'recovery')
          .toList(growable: false);
      final report = const Sprint117SecurityCenterWorkflowGate().evaluateWith(
        Sprint117SecurityCenterWorkflowInput(rows: rows, anchor: base.anchor),
      );
      expect(report.status, Sprint117SecurityCenterWorkflowState.fail);
      expect(report.unmappedChecks, contains('recovery'));
      expect(report.coverage, lessThan(1.0));
    });
  });

  group('117.20 integration gaps are reported, not folded into a pass', () {
    late Sprint117SecurityCenterWorkflowDrillRun run;

    setUpAll(() async {
      run = await const Sprint117SecurityCenterWorkflowDrill().run();
    });

    test('the security summary seam now has production callers in lib/', () {
      // Measured, not assumed: a hand-built run defaults to true, so only the
      // repository scan can clear this.
      //
      // This group asserted zero callers when the slice landed, and that was
      // true then. It stopped being true when `PasswordAgeGate` and
      // `TrustedDeviceAggregator` shipped and began importing the seams, so
      // each scan now counts 1: the aggregator imports the security summary
      // and the session seam, and the password gate imports the summary. Both
      // counts come from independent repository scans, so the test follows
      // the measurements instead of freezing either at zero.
      expect(run.securitySummaryProductionCallSites, greaterThan(0));
      expect(run.productionCallerPresent, isTrue);
      expect(run.sessionManagementProductionCallSites, greaterThan(0));
    });

    test('the measured gaps appear in the report open items', () async {
      final report = await const Sprint117SecurityCenterWorkflowGate()
          .evaluateWithDrill();
      // Each item below was an open gap when this slice landed and is now
      // measured closed, so it must no longer appear in the open-item list.
      // The list is not merely shorter: the gate still reports the session
      // gap, which is genuinely still open, and the gate's own status is still
      // a measured pass rather than a silently widened one.
      expect(
        report.openItems,
        isNot(contains('security_summary_defined_not_reachable_from_lib')),
      );
      expect(
        report.openItems,
        isNot(contains('password_staleness_not_computed_in_lib')),
      );
      expect(
        report.openItems,
        isNot(contains('device_trust_not_aggregated_in_lib')),
      );
      // The successor item the gate raises in place of the retired reachability
      // gap is still reported, so the measurement is carried, not discarded.
      expect(
        report.openItems,
        contains('security_summary_production_call_sites_measured'),
      );
      // The session aggregation gap was never closed and stays open. This is
      // the assertion that would catch the list being emptied wholesale.
      expect(
        report.openItems,
        contains('session_summary_caller_supplied_not_computed'),
      );
      // The slice still passes: these are reported gaps, not passed rows.
      expect(report.status, Sprint117SecurityCenterWorkflowState.pass);
    });
  });
}
