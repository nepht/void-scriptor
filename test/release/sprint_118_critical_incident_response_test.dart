import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_critical_incident_response.dart';

/// A single response record. Each test flips exactly the one thing it is about,
/// so a test that flips nothing proves the pass path exists and every other
/// test proves one way the gate refuses to take it.
Sprint118IncidentResponseEntry _entry({
  String incidentClass = 'account_takeover',
  String incidentId = 'RESPONSE-ACCOUNT-TAKEOVER-REF',
  String containment = Sprint118IncidentResponseContract.referenceContainment,
  String connectorDisable =
      Sprint118IncidentResponseContract.referenceConnectorDisable,
  String userProtection =
      Sprint118IncidentResponseContract.referenceUserProtection,
  String rootCause = Sprint118IncidentResponseContract.referenceRootCause,
  String fix = Sprint118IncidentResponseContract.referenceFix,
  String tests = Sprint118IncidentResponseContract.referenceTests,
  String advisory = Sprint118IncidentResponseContract.referenceAdvisory,
  String rollback = Sprint118IncidentResponseContract.referenceRollback,
  String owner = Sprint118IncidentResponseContract.responseOwner,
  String evidence =
      'docs/planning/v1.3/sprint_117_identity_workflow_validation.json',
  bool liveIncidentClaimed = false,
}) {
  return Sprint118IncidentResponseEntry(
    incidentClass: incidentClass,
    incidentId: incidentId,
    containment: containment,
    connectorDisable: connectorDisable,
    userProtection: userProtection,
    rootCause: rootCause,
    fix: fix,
    tests: tests,
    advisory: advisory,
    rollback: rollback,
    owner: owner,
    evidence: evidence,
    liveIncidentClaimed: liveIncidentClaimed,
  );
}

Sprint118IncidentResponsePlan _plan({
  String releaseState = Sprint118IncidentResponseContract.delayedReleaseState,
  List<Sprint118IncidentResponseEntry>? entries,
}) {
  return Sprint118IncidentResponsePlan(
    releaseState: releaseState,
    entries: entries ?? Sprint118IncidentResponseContract.canonicalPlan.entries,
  );
}

/// The canonical entries with exactly one class replaced, so a test can flip a
/// single field without rebuilding the whole plan.
List<Sprint118IncidentResponseEntry> _replacing(
  String incidentClass,
  Sprint118IncidentResponseEntry replacement,
) {
  return <Sprint118IncidentResponseEntry>[
    for (final e in Sprint118IncidentResponseContract.canonicalPlan.entries)
      if (e.incidentClass == incidentClass) replacement else e,
  ];
}

Sprint118IncidentResponseAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict =
      Sprint118IncidentResponseContract.requiredBaselineVerdict,
  String releaseState = Sprint118IncidentResponseContract.delayedReleaseState,
  String charterState = 'pass',
  String charterVerdict =
      Sprint118IncidentResponseContract.requiredCharterVerdict,
  String readinessState = 'pass',
  String readinessVerdict =
      Sprint118IncidentResponseContract.requiredReadinessVerdict,
  bool liveIncidentExecuted = false,
  List<String>? owners,
  List<String>? p0Outputs,
  List<String>? connectorDisableScopes,
  List<String>? readableSources,
}) {
  return Sprint118IncidentResponseAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    charterState: charterState,
    charterVerdict: charterVerdict,
    readinessState: readinessState,
    readinessVerdict: readinessVerdict,
    liveIncidentExecuted: liveIncidentExecuted,
    owners: owners ?? const <String>['Choirudin', 'nephthys'],
    p0Outputs:
        p0Outputs ??
        const <String>[
          'containment',
          'user_protection',
          'root_cause',
          'fix',
          'tests',
          'advisory',
          'rollback_or_patch',
        ],
    connectorDisableScopes:
        connectorDisableScopes ?? const <String>['connector_disable'],
    readableSources:
        readableSources ?? Sprint118IncidentResponseContract.canonicalSources,
  );
}

Sprint118IncidentResponseReport _run(
  Sprint118IncidentResponsePlan plan, {
  Sprint118IncidentResponseAnchor? anchor,
}) {
  return const Sprint118IncidentResponseGate().evaluateWith(
    anchor ?? _anchor(),
    plan,
  );
}

void main() {
  group('118.23 Critical Incident Response', () {
    test('declares the canonical step, title, outputs, and paths', () {
      expect(Sprint118IncidentResponseContract.canonicalStep, '118.23');
      expect(
        Sprint118IncidentResponseContract.title,
        'Critical Incident Response',
      );
      expect(
        Sprint118IncidentResponseContract.manifestPath,
        'docs/planning/v1.3/sprint_118_critical_incident_response.json',
      );
      expect(Sprint118IncidentResponseContract.requiredOutputs, <String>[
        'containment',
        'connector_disable',
        'user_protection',
        'root_cause',
        'fix',
        'tests',
        'advisory',
        'rollback',
      ]);
      expect(
        Sprint118IncidentResponseContract.externalGates,
        'DEFERRED-EXTERNAL',
      );
    });

    test('vocabularies are internally consistent', () {
      expect(Sprint118IncidentResponseContract.requiredOutputs.length, 8);
      expect(Sprint118IncidentResponseContract.incidentClasses.length, 7);
      expect(Sprint118IncidentResponseContract.canonicalSources.length, 7);
    });

    test('grounds each required output in a committed witness', () {
      const p0 = <String>[
        'containment',
        'user_protection',
        'root_cause',
        'fix',
        'tests',
        'advisory',
        'rollback_or_patch',
      ];
      const scopes = <String>['connector_disable'];
      for (final output in Sprint118IncidentResponseContract.requiredOutputs) {
        expect(
          Sprint118IncidentResponseContract.grounds(p0, output) ||
              Sprint118IncidentResponseContract.grounds(scopes, output),
          isTrue,
          reason: '$output must be grounded in a witness vocabulary',
        );
      }
      expect(Sprint118IncidentResponseContract.grounds(p0, 'unknown'), isFalse);
    });

    test(
      'canonical plan covers the seven classes and claims no live response',
      () {
        final plan = Sprint118IncidentResponseContract.canonicalPlan;
        expect(plan.entries.length, 7);
        expect(plan.incidentClasses.toSet(), <String>{
          'account_takeover',
          'token_leak',
          'payment_error',
          'data_loss',
          'privacy_leak',
          'sync_corruption',
          'crash_loop',
        });
        for (final entry in plan.entries) {
          expect(entry.liveIncidentClaimed, isFalse);
          for (final output
              in Sprint118IncidentResponseContract.requiredOutputs) {
            expect(
              (entry.outputs[output] ?? '').trim(),
              isNotEmpty,
              reason: '${entry.incidentClass}.$output must not be blank',
            );
          }
        }
      },
    );

    test('passes on the canonical plan', () {
      final report = _run(_plan());
      expect(report.state, Sprint118IncidentResponseState.pass);
      expect(report.verdict, 'CRITICAL_INCIDENT_RESPONSE_VERIFIED_LOCAL');
      expect(report.planVerified, isTrue);
      expect(report.declaredClasses.length, 7);
      expect(report.responseCount, 7);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      expect(report.openItems, isEmpty);
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118IncidentResponseGate().evaluateWith(
        null,
        _plan(),
      );
      expect(report.state, Sprint118IncidentResponseState.blocked);
      expect(report.verdict, 'SPRINT_118_RESPONSE_EVIDENCE_UNREADABLE');
      expect(
        report.blockers,
        contains('committed_response_evidence_unreadable'),
      );
    });

    test('blocks when the 118.4 baseline did not freeze', () {
      final report = _run(
        _plan(),
        anchor: _anchor(
          baselineVerdict: 'SPRINT_118_BASELINE_EVIDENCE_VIOLATION',
        ),
      );
      expect(report.state, Sprint118IncidentResponseState.blocked);
      expect(
        report.blockers,
        contains('baseline_not_frozen:SPRINT_118_BASELINE_EVIDENCE_VIOLATION'),
      );
    });

    test('blocks when the 118.2 charter is not complete', () {
      final report = _run(
        _plan(),
        anchor: _anchor(charterVerdict: 'CHARTER_EVIDENCE_VIOLATION'),
      );
      expect(report.state, Sprint118IncidentResponseState.blocked);
      expect(
        report.blockers,
        contains('charter_not_complete:CHARTER_EVIDENCE_VIOLATION'),
      );
    });

    test('blocks when the 117.6 readiness witness is not a pass', () {
      final report = _run(
        _plan(),
        anchor: _anchor(
          readinessVerdict: 'SUPPORT_INCIDENT_READINESS_VIOLATION',
        ),
      );
      expect(report.state, Sprint118IncidentResponseState.blocked);
      expect(
        report.blockers,
        contains('readiness_not_defined:SUPPORT_INCIDENT_READINESS_VIOLATION'),
      );
    });

    test('fails when the release state disagrees with the baseline', () {
      final report = _run(
        _plan(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'GA_DELAYED'),
      );
      expect(report.state, Sprint118IncidentResponseState.fail);
      expect(
        report.violations.any((v) => v.startsWith('release_state_mismatch:')),
        isTrue,
      );
    });

    test('fails when a live incident is claimed on the delayed path', () {
      final report = _run(_plan(), anchor: _anchor(liveIncidentExecuted: true));
      expect(report.state, Sprint118IncidentResponseState.fail);
      expect(
        report.violations,
        contains('live_incident_claimed_executed_without_release'),
      );
    });

    test('fails when a record claims a live incident response', () {
      final report = _run(
        _plan(
          entries: _replacing(
            'token_leak',
            _entry(
              incidentClass: 'token_leak',
              incidentId: 'RESPONSE-TOKEN-LEAK-REF',
              evidence:
                  'docs/planning/v1.2/sprint_115_secure_token_secret_vault.json',
              liveIncidentClaimed: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118IncidentResponseState.fail);
      expect(
        report.violations,
        contains('live_incident_claimed_without_release:token_leak'),
      );
    });

    test('fails when a required output is blank', () {
      final report = _run(
        _plan(
          entries: _replacing(
            'payment_error',
            _entry(
              incidentClass: 'payment_error',
              incidentId: 'RESPONSE-PAYMENT-ERROR-REF',
              evidence:
                  'docs/planning/v1.2/sprint_116_billing_entitlement_webhook_reconciliation.json',
              containment: '   ',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118IncidentResponseState.fail);
      expect(
        report.violations,
        contains('entry_blank_containment:payment_error'),
      );
    });

    test('fails when a record carries an unknown owner', () {
      final report = _run(
        _plan(
          entries: _replacing(
            'data_loss',
            _entry(
              incidentClass: 'data_loss',
              incidentId: 'RESPONSE-DATA-LOSS-REF',
              evidence:
                  'docs/planning/v1.2/sprint_113_incident_stop_ship_protocol.json',
              owner: 'nobody',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118IncidentResponseState.fail);
      expect(
        report.violations,
        contains('entry_unknown_owner:data_loss:nobody'),
      );
    });

    test('fails when a record cites an unreadable evidence source', () {
      final report = _run(
        _plan(
          entries: _replacing(
            'privacy_leak',
            _entry(
              incidentClass: 'privacy_leak',
              incidentId: 'RESPONSE-PRIVACY-LEAK-REF',
              evidence:
                  'docs/planning/v1.3/sprint_118_privacy_safe_observation.json',
            ),
          ),
        ),
        anchor: _anchor(
          readableSources: <String>[
            'docs/planning/v1.3/sprint_117_identity_workflow_validation.json',
          ],
        ),
      );
      expect(report.state, Sprint118IncidentResponseState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('entry_unreadable_evidence:privacy_leak:'),
        ),
        isTrue,
      );
    });

    test('fails on a duplicate incident class', () {
      final entries = <Sprint118IncidentResponseEntry>[
        ...Sprint118IncidentResponseContract.canonicalPlan.entries,
        _entry(
          incidentClass: 'account_takeover',
          incidentId: 'RESPONSE-ACCOUNT-TAKEOVER-DUP',
        ),
      ];
      final report = _run(_plan(entries: entries));
      expect(report.state, Sprint118IncidentResponseState.fail);
      expect(
        report.violations,
        contains('response_class_duplicate:account_takeover'),
      );
    });

    test('fails when a canonical incident class is missing', () {
      final entries = <Sprint118IncidentResponseEntry>[
        for (final e in Sprint118IncidentResponseContract.canonicalPlan.entries)
          if (e.incidentClass != 'crash_loop') e,
      ];
      final report = _run(_plan(entries: entries));
      expect(report.state, Sprint118IncidentResponseState.fail);
      expect(report.violations, contains('response_class_missing:crash_loop'));
    });

    test('fails when a record names an unknown incident class', () {
      final report = _run(
        _plan(
          entries: _replacing(
            'account_takeover',
            _entry(incidentClass: 'unknown_class'),
          ),
        ),
      );
      expect(report.state, Sprint118IncidentResponseState.fail);
      // The replacement also removes the real 'account_takeover' record, so both
      // the unknown-class and the missing-class violations are expected.
      expect(
        report.violations,
        contains('response_class_unknown:unknown_class'),
      );
      expect(
        report.violations,
        contains('response_class_missing:account_takeover'),
      );
    });

    test('fails when a committed source is not readable', () {
      final report = _run(
        _plan(),
        anchor: _anchor(
          readableSources: <String>[
            'docs/planning/v1.3/sprint_117_identity_workflow_validation.json',
          ],
        ),
      );
      expect(report.state, Sprint118IncidentResponseState.fail);
      expect(
        report.violations.any((v) => v.startsWith('unreadable_source:')),
        isTrue,
      );
    });

    test('reports the missing upstream owner vocabulary honestly', () {
      final report = _run(_plan(), anchor: _anchor(owners: const <String>[]));
      expect(report.openItems, contains('upstream_owner_vocabulary_missing'));
    });

    test('reports the missing upstream P0 output vocabulary honestly', () {
      final report = _run(
        _plan(),
        anchor: _anchor(p0Outputs: const <String>[]),
      );
      expect(
        report.openItems,
        contains('upstream_p0_output_vocabulary_missing'),
      );
    });

    test('reports the missing connector-disable vocabulary honestly', () {
      final report = _run(
        _plan(),
        anchor: _anchor(connectorDisableScopes: const <String>[]),
      );
      expect(
        report.openItems,
        contains('upstream_connector_disable_vocabulary_missing'),
      );
    });

    test('reports a canonical output the witness does not ground', () {
      final report = _run(
        _plan(),
        anchor: _anchor(p0Outputs: const <String>['containment']),
      );
      expect(
        report.openItems,
        contains('output_not_grounded_in_witness:rollback'),
      );
    });

    test('sourceFor maps each class to its committed evidence source', () {
      expect(
        Sprint118IncidentResponseContract.sourceFor('token_leak'),
        'docs/planning/v1.2/sprint_115_secure_token_secret_vault.json',
      );
      expect(
        Sprint118IncidentResponseContract.sourceFor('crash_loop'),
        'docs/planning/v1.2/sprint_114_crash_startup_health.json',
      );
      expect(Sprint118IncidentResponseContract.sourceFor('unknown'), '');
    });
  });
}
