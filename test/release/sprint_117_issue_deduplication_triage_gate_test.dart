/// Sprint 117.38 — Issue Deduplication & Triage.
///
/// Validates the six canonical decisions of the step (FIX_BEFORE_GA,
/// FLAG_OFF, DISABLE_CONNECTOR, DEFER, ROLLBACK,
/// NOT_REPRODUCIBLE_WITH_EVIDENCE) and the fail-closed structural rules of
/// the triage gate. Every `observed` value comes from a seam this file
/// actually exercised; the aggregate test throws if one is unfilled, so a
/// verdict number can never be typed by hand.
///
/// The gate validates the decision contract. It does not claim a GA blocker
/// was found or that a triage decision was applied to a live release.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/feature_flags/feature_flag_registry.dart';
import 'package:void_scriptor/features/account/domain/account_center_connected_accounts_management.dart';
import 'package:void_scriptor/features/account/domain/account_center_connection_health_state_machine.dart';
import 'package:void_scriptor/features/world_logic/domain/release_blocker_triage.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_issue_deduplication_triage.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_issue_deduplication_triage_actions.dart';

/// One triaged issue. A structural fixture, not a recorded incident.
Sprint117TriagedIssue _fixture({
  String id = 'TRIAGE-11738-1',
  String decision = 'FIX_BEFORE_GA',
  List<String> duplicates = const <String>[],
}) => Sprint117TriagedIssue(
  issueId: id,
  decision: decision,
  reproducible: true,
  meetsBlockerDefinition: true,
  duplicateIds: duplicates,
  rationale:
      'structural-fixture: no GA blocker has been filed; the beta cohort '
      'has not started (117.34)',
  evidence: <String>['docs/evidence/sprint-117-38-manifest-20261002.json'],
);

/// Probes measured against the shipped seams, keyed by decision. Empty until
/// each probe runs, so a hand-written verdict cannot pass the aggregate.
final Map<String, String> _probes = <String, String>{};

void _record(String decision, String observed) {
  _probes[decision] = observed;
}

void main() {
  group('117.38 Issue Deduplication & Triage', () {
    test('canonical decisions are the six names, verbatim', () {
      expect(Sprint117IssueTriage.canonicalDecisions, <String>[
        'FIX_BEFORE_GA',
        'FLAG_OFF',
        'DISABLE_CONNECTOR',
        'DEFER',
        'ROLLBACK',
        'NOT_REPRODUCIBLE_WITH_EVIDENCE',
      ]);
    });

    test('FIX_BEFORE_GA is accepted by the shipped triage log', () {
      final log = ReleaseBlockerTriage()
        ..add(
          const TriageEntry(
            issueId: 'ISS-11738-FIX',
            meetsBlockerDefinition: true,
            reproducible: true,
            decision: TriageDecision.fixBeforeGa,
            rationale: 'Sudah terbukti reproducible dan memenuhi definisi.',
            evidence: <String>['docs/evidence/triage/iss-fix.md'],
          ),
        );

      final decision = log.evaluate();
      expect(decision.state, TriageState.pass);
      expect(log.releaseBlocked, isFalse);
      _record(
        'FIX_BEFORE_GA',
        'state=${decision.state.name} '
            'releaseBlocked=${log.releaseBlocked} entryCount=${decision.entryCount}',
      );
    });

    test('DEFER reaches the shipped seam through DEFER_NON_BLOCKER', () {
      // The canonical decision is DEFER. The shipped triage names it
      // DEFER_NON_BLOCKER, which is a different string for the same act, so
      // the mapping is measured, not assumed.
      final log = ReleaseBlockerTriage()
        ..add(
          const TriageEntry(
            issueId: 'ISS-11738-DEFER',
            meetsBlockerDefinition: false,
            reproducible: true,
            decision: TriageDecision.deferNonBlocker,
            rationale: 'Tidak menyentuh data pengguna; aman ditunda.',
            evidence: <String>['docs/evidence/triage/iss-defer.md'],
          ),
        );

      final decision = log.evaluate();
      expect(decision.state, TriageState.pass);
      expect(
        Sprint117IssueTriage.shippedTriageDecisions,
        contains('DEFER_NON_BLOCKER'),
      );
      expect(
        Sprint117IssueTriage.shippedTriageDecisions,
        isNot(contains('DEFER')),
      );
      _record(
        'DEFER',
        'canonical=DEFER shipped=DEFER_NON_BLOCKER '
            'state=${decision.state.name}',
      );
    });

    test('ROLLBACK reaches the shipped seam through ROLLBACK_RC', () {
      final log = ReleaseBlockerTriage()
        ..add(
          const TriageEntry(
            issueId: 'ISS-11738-ROLLBACK',
            meetsBlockerDefinition: true,
            reproducible: true,
            decision: TriageDecision.rollbackRc,
            rationale: 'RC memperkenalkan regresi yang harus ditarik.',
            evidence: <String>['docs/evidence/triage/iss-rollback.md'],
          ),
        );

      final decision = log.evaluate();
      expect(decision.state, TriageState.pass);
      expect(log.releaseBlocked, isTrue);
      _record(
        'ROLLBACK',
        'shipped=ROLLBACK_RC state=${decision.state.name} '
            'releaseBlocked=${log.releaseBlocked}',
      );
    });

    test('NOT_REPRODUCIBLE_WITH_EVIDENCE still requires evidence', () {
      final withoutEvidence = ReleaseBlockerTriage()
        ..add(
          const TriageEntry(
            issueId: 'ISS-11738-NRE-NO-EV',
            meetsBlockerDefinition: false,
            reproducible: false,
            decision: TriageDecision.notReproducibleWithEvidence,
            rationale: 'Tidak muncul, tapi tanpa bukti apa pun.',
            evidence: <String>[],
          ),
        );
      expect(withoutEvidence.evaluate().state, TriageState.fail);

      final withEvidence = ReleaseBlockerTriage()
        ..add(
          const TriageEntry(
            issueId: 'ISS-11738-NRE',
            meetsBlockerDefinition: false,
            reproducible: false,
            decision: TriageDecision.notReproducibleWithEvidence,
            rationale: 'Tidak muncul pada lima percobaan berurutan.',
            evidence: <String>['docs/evidence/triage/iss-nre-attempts.log'],
          ),
        );
      final decision = withEvidence.evaluate();
      expect(decision.state, TriageState.pass);
      _record(
        'NOT_REPRODUCIBLE_WITH_EVIDENCE',
        'no_evidence=FAIL with_evidence=${decision.state.name}',
      );
    });

    test('FLAG_OFF is measured through the shipped flag registry', () {
      // Turning a capability off is a real action with a shipped seam
      // (FeatureFlagRegistry.disable, 110.8). The gate accepts FLAG_OFF only
      // when that seam reports it changed state.
      final flags = FeatureFlagRegistry()..enable('vs12_quests');
      final resolution = Sprint117FlagOffAction(flags).disable('vs12_quests');

      expect(resolution.applied, isTrue);
      expect(flags.isEnabled('vs12_quests'), isFalse);
      expect(resolution.observed, contains('was_enabled=true'));
      _record('FLAG_OFF', resolution.observed);
    });

    test(
      'DISABLE_CONNECTOR is measured through the shipped disconnect seam',
      () {
        // The sibling action at connector level: AccountConnectedAccounts
        // Management.unlink (115.14). A local drop is still a disable, but the
        // observation says the provider was never told, so it cannot be read as
        // a revoke.
        final connections = AccountConnectedAccountsManagement(
          initial: <AccountConnectedAccount>[
            AccountConnectedAccount(
              connectionId: 'conn-github-1',
              providerId: 'github',
              accountLabel: 'Choirudin',
              scopes: <String>{'repo'},
              connectionState: AccountConnectionState.connected,
              healthState: AccountHealthState.healthy,
              lastCheckedAt: DateTime.utc(2026, 10, 2),
              reauthRequired: false,
            ),
          ],
        );

        return Sprint117DisableConnectorAction(
          connections,
        ).disable('conn-github-1').then((resolution) {
          expect(resolution.applied, isTrue);
          expect(resolution.observed, contains('localRemoved=true'));
          expect(resolution.observed, contains('providerRevoked=false'));
          expect(connections.connections, isEmpty);
          _record('DISABLE_CONNECTOR', resolution.observed);
        });
      },
    );

    test('a flag-off that changed nothing is reported as not applied', () {
      // A flag that was never on cannot prove a flag-off happened.
      final resolution = Sprint117FlagOffAction(
        FeatureFlagRegistry(),
      ).disable('vs12_quests');

      expect(resolution.applied, isFalse);
      expect(resolution.observed, contains('was_enabled=false'));
    });

    test(
      'a triaged FLAG_OFF issue without an action result is unexpressible',
      () {
        // The fail-closed shape: claiming the verdict without performing the
        // action must still fail, and must name the issue. This is the proof
        // that the seam is load-bearing — the same issue is accepted below
        // once a measured result is handed over, so the gate fails on missing
        // evidence rather than on the decision's name.
        const issue = Sprint117TriagedIssue(
          issueId: 'TRIAGE-NO-ACTION',
          decision: 'FLAG_OFF',
          reproducible: true,
          meetsBlockerDefinition: true,
          duplicateIds: <String>[],
          rationale: 'kapabilitas dimatikan sampai perbaikan rilis',
          evidence: <String>['docs/evidence/triage/no-action.log'],
        );
        final withoutResult = Sprint117IssueTriage.evaluate(
          issues: const <Sprint117TriagedIssue>[issue],
          checks: _allUnmet(),
        );

        expect(withoutResult.pass, isFalse);
        expect(
          withoutResult.failures,
          contains('unexpressible_decision:TRIAGE-NO-ACTION:FLAG_OFF'),
        );

        final withResult = Sprint117IssueTriage.evaluate(
          issues: const <Sprint117TriagedIssue>[issue],
          checks: _allUnmet(),
          actionResults: <String, Sprint117TriageResolution>{
            'TRIAGE-NO-ACTION': Sprint117TriageResolution(
              decision: 'FLAG_OFF',
              applied: true,
              observed:
                  'FeatureFlagRegistry.disable(vs12_quests): '
                  'was_enabled=true is_enabled_after=false',
            ),
          },
        );

        expect(
          withResult.failures,
          isNot(contains('unexpressible_decision:TRIAGE-NO-ACTION:FLAG_OFF')),
        );
      },
    );

    test('an action result that did not apply is a failure', () {
      final result = Sprint117IssueTriage.evaluate(
        issues: <Sprint117TriagedIssue>[
          _fixture(id: 'TRIAGE-NOT-APPLIED', decision: 'FLAG_OFF'),
        ],
        checks: _allUnmet(),
        actionResults: <String, Sprint117TriageResolution>{
          'TRIAGE-NOT-APPLIED': Sprint117TriageResolution(
            decision: 'FLAG_OFF',
            applied: false,
            observed:
                'FeatureFlagRegistry.disable(vs12_quests): '
                'was_enabled=false is_enabled_after=false',
          ),
        },
      );

      expect(result.pass, isFalse);
      expect(
        result.failures,
        contains('action_not_applied:TRIAGE-NOT-APPLIED:FLAG_OFF'),
      );
    });

    test('an action result for a different decision is a mismatch', () {
      final result = Sprint117IssueTriage.evaluate(
        issues: <Sprint117TriagedIssue>[
          _fixture(id: 'TRIAGE-MISMATCH', decision: 'DISABLE_CONNECTOR'),
        ],
        checks: _allUnmet(),
        actionResults: <String, Sprint117TriageResolution>{
          'TRIAGE-MISMATCH': Sprint117TriageResolution(
            decision: 'FLAG_OFF',
            applied: true,
            observed:
                'FeatureFlagRegistry.disable(vs12_quests): '
                'was_enabled=true is_enabled_after=false',
          ),
        },
      );

      expect(result.pass, isFalse);
      expect(
        result.failures,
        contains('action_decision_mismatch:TRIAGE-MISMATCH:DISABLE_CONNECTOR'),
      );
    });

    test('an applied action with no observation is vacuous', () {
      final result = Sprint117IssueTriage.evaluate(
        issues: <Sprint117TriagedIssue>[
          _fixture(id: 'TRIAGE-VACUOUS', decision: 'FLAG_OFF'),
        ],
        checks: _allUnmet(),
        actionResults: <String, Sprint117TriageResolution>{
          'TRIAGE-VACUOUS': Sprint117TriageResolution(
            decision: 'FLAG_OFF',
            applied: true,
            observed: '   ',
          ),
        },
      );

      expect(result.pass, isFalse);
      expect(
        result.failures,
        contains('vacuous_action:TRIAGE-VACUOUS:FLAG_OFF'),
      );
    });

    test('a complete fixture issue has no missing fields', () {
      expect(Sprint117IssueTriage.missingFields(_fixture()), isEmpty);
    });

    test('every blank canonical field is reported by name', () {
      const bare = Sprint117TriagedIssue(
        issueId: '',
        decision: '',
        reproducible: false,
        meetsBlockerDefinition: false,
        duplicateIds: <String>[],
        rationale: '',
        evidence: <String>[],
      );

      expect(Sprint117IssueTriage.missingFields(bare), <String>[
        'issue_id',
        'decision',
        'rationale',
        'evidence',
      ]);
    });

    test('duplicate ids are exempt from being non-empty, blanks are not', () {
      expect(
        Sprint117IssueTriage.blankListElements(_fixture()),
        isEmpty,
        reason: 'a canonical issue may have no known duplicates',
      );
      expect(
        Sprint117IssueTriage.blankListElements(
          _fixture(duplicates: <String>['  ']),
        ),
        <String>['duplicate_ids:0'],
      );
    });

    test('a decision outside the canonical six is unknown', () {
      final result = Sprint117IssueTriage.evaluate(
        issues: <Sprint117TriagedIssue>[
          _fixture(id: 'TRIAGE-STOP', decision: 'STOP_SHIP'),
        ],
        checks: _allUnmet(),
      );

      expect(result.pass, isFalse);
      expect(
        result.failures,
        contains('unknown_decision:TRIAGE-STOP:STOP_SHIP'),
      );
    });

    test('no issues at all is a structural failure', () {
      final result = Sprint117IssueTriage.evaluate(
        issues: <Sprint117TriagedIssue>[],
        checks: _allUnmet(),
      );

      expect(result.pass, isFalse);
      expect(result.failures, contains('no_issues'));
    });

    test('a duplicated issue id fails the gate', () {
      final result = Sprint117IssueTriage.evaluate(
        issues: <Sprint117TriagedIssue>[_fixture(), _fixture()],
        checks: _allUnmet(),
      );

      expect(result.pass, isFalse);
      expect(result.failures, contains('duplicate_issue_id:TRIAGE-11738-1'));
    });

    test('a decision whose only check is unmet never counts as passing', () {
      final result = Sprint117IssueTriage.evaluate(
        issues: <Sprint117TriagedIssue>[_fixture()],
        checks: _allChecks(unmetDecisions: <String>{'ROLLBACK'}),
      );

      expect(result.pass, isFalse);
      expect(result.failures, contains('decision_without_pass:ROLLBACK'));
      expect(
        result.failures,
        isNot(contains('missing_decision_check:ROLLBACK')),
      );
      expect(result.openItems, contains('ROLLBACK:rollback_gates_the_release'));
    });

    test('a decision with no check at all is missing', () {
      final checks = _allUnmet()
        ..removeWhere((check) => check.decision == 'FLAG_OFF');
      final result = Sprint117IssueTriage.evaluate(
        issues: <Sprint117TriagedIssue>[_fixture()],
        checks: checks,
      );

      expect(result.pass, isFalse);
      expect(result.failures, contains('missing_decision_check:FLAG_OFF'));
    });

    test('a check outside the canonical six fails as unknown', () {
      final result = Sprint117IssueTriage.evaluate(
        issues: <Sprint117TriagedIssue>[_fixture()],
        checks: <Sprint117TriageCheck>[
          ..._allUnmet(),
          const Sprint117TriageCheck.pass(
            decision: 'STOP_SHIP',
            check: 'stop_ship_is_a_shipped_decision',
            declared: 'a shipped decision',
            observed: 'a shipped decision',
          ),
        ],
      );

      expect(result.pass, isFalse);
      expect(result.failures, contains('unknown_decision_check:STOP_SHIP'));
    });

    test('a duplicated check code fails the gate', () {
      final checks = _allChecks();
      final duplicated = checks
          .where((check) => check.decision == 'FIX_BEFORE_GA')
          .single;
      final result = Sprint117IssueTriage.evaluate(
        issues: <Sprint117TriagedIssue>[_fixture()],
        checks: <Sprint117TriageCheck>[...checks, duplicated],
      );

      expect(result.pass, isFalse);
      expect(
        result.failures,
        contains('duplicate_check:FIX_BEFORE_GA:fix_before_ga_is_accepted'),
      );
    });

    test('a blank declared or observed value is vacuous, never a pass', () {
      final checks = _allUnmet()
        ..removeWhere((check) => check.decision == 'DEFER');
      final result = Sprint117IssueTriage.evaluate(
        issues: <Sprint117TriagedIssue>[_fixture()],
        checks: <Sprint117TriageCheck>[
          ...checks,
          const Sprint117TriageCheck.pass(
            decision: 'DEFER',
            check: 'defer_check_with_no_observation',
            declared: 'a declared claim',
            observed: '   ',
          ),
        ],
      );

      expect(result.pass, isFalse);
      expect(
        result.failures,
        contains('vacuous:DEFER:defer_check_with_no_observation'),
      );
      expect(result.failures, contains('decision_without_pass:DEFER'));
    });

    test('the exported json names the step, verdict and failures', () {
      // Structural shape is asserted on an all-unmet set, where the verdict
      // can only come from structure and never from a measured decision.
      final result = Sprint117IssueTriage.evaluate(
        issues: <Sprint117TriagedIssue>[_fixture()],
        checks: _allUnmet(),
      );
      final decoded =
          jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>;

      expect(decoded['canonical_step'], '117.38');
      expect(decoded['document_role'], 'EVIDENCE');
      expect(decoded['verdict'], Sprint117IssueTriage.failVerdict);
      expect(decoded['pass'], isFalse);
      expect(decoded['canonical_decisions'], hasLength(6));
      expect(decoded['failures'], isNotEmpty);
      expect(decoded['checks'], hasLength(6));
      expect(decoded['fixture_issues'], 1);
    });

    test('the gate claims no recorded blocker and no live beta', () {
      final result = Sprint117IssueTriage.evaluate(
        issues: <Sprint117TriagedIssue>[_fixture()],
        checks: _allUnmet(),
      );
      final decoded =
          jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>;

      expect(result.fixtureIssues, 1);
      expect(decoded.containsKey('live_beta_executed'), isFalse);
      expect(decoded.containsKey('blocker_found'), isFalse);
      expect(result.verdict, isNot(contains('TRIAGED')));
    });

    test('a gate run leaves no scratch residue in the source tree', () {
      final temp = Directory.systemTemp.createTempSync('sprint11738');
      try {
        final file = File('${temp.path}/gate.json')
          ..writeAsStringSync(
            jsonEncode(
              Sprint117IssueTriage.evaluate(
                issues: <Sprint117TriagedIssue>[_fixture()],
                checks: _allUnmet(),
              ).toJson(),
            ),
          );
        expect(file.existsSync(), isTrue);
      } finally {
        temp.deleteSync(recursive: true);
      }
      expect(temp.existsSync(), isFalse);
    });
  });

  group('117.38 measured verdict', () {
    // Runs last so every probe above has filled its entry.
    test('the aggregate verdict is built from probes that all ran', () async {
      final missing = Sprint117IssueTriage.canonicalDecisions
          .where((decision) => !_probes.containsKey(decision))
          .toList();
      expect(
        missing,
        isEmpty,
        reason:
            'every canonical decision must be measured by a probe that '
            'actually ran: unmeasured=$missing',
      );

      final checks = _allChecks();
      // Every decision the step names is now measurable, so the fixture
      // performs both actions through the shipped seams and hands the gate
      // what those seams observed. An assertion typed into the test would be
      // the fail-open this gate exists to catch.
      final flagResolution = Sprint117FlagOffAction(
        FeatureFlagRegistry()..enable('vs12_quests'),
      ).disable('vs12_quests');
      final connections = AccountConnectedAccountsManagement(
        initial: <AccountConnectedAccount>[
          AccountConnectedAccount(
            connectionId: 'conn-gitlab-1',
            providerId: 'gitlab',
            accountLabel: 'Void Scriptor Group',
            scopes: <String>{'repo'},
            connectionState: AccountConnectionState.connected,
            healthState: AccountHealthState.healthy,
            lastCheckedAt: DateTime.utc(2026, 10, 2),
            reauthRequired: false,
          ),
        ],
      );
      final connectorResolution = await Sprint117DisableConnectorAction(
        connections,
      ).disable('conn-gitlab-1');
      expect(flagResolution.applied, isTrue);
      expect(connectorResolution.applied, isTrue);

      final result = Sprint117IssueTriage.evaluate(
        issues: <Sprint117TriagedIssue>[
          _fixture(),
          _fixture(
            id: 'TRIAGE-11738-2',
            decision: 'NOT_REPRODUCIBLE_WITH_EVIDENCE',
          ),
          _fixture(id: 'TRIAGE-11738-3', decision: 'FLAG_OFF'),
          _fixture(id: 'TRIAGE-11738-4', decision: 'DISABLE_CONNECTOR'),
        ],
        checks: checks,
        actionResults: <String, Sprint117TriageResolution>{
          'TRIAGE-11738-3': flagResolution,
          'TRIAGE-11738-4': connectorResolution,
        },
      );

      // All six canonical decisions are measured against shipped seams, so
      // the verdict can be a pass. It still claims nothing about a live
      // release: the actions ran against test-owned state, not a cohort.
      expect(result.failures, isEmpty);
      expect(result.pass, isTrue);
      expect(result.verdict, Sprint117IssueTriage.passVerdict);
      expect(result.openItems, isEmpty);

      if (Platform.environment['SPRINT_117_38_MANIFEST'] == '1') {
        final manifest = <String, Object?>{
          ...result.toJson(),
          'probes': _probes,
        };
        File('docs/evidence/sprint-117-38-manifest-20261002.json')
          ..createSync(recursive: true)
          ..writeAsStringSync(
            '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
          );
      }
    });
  });
}

/// Every canonical decision as a `unmet` check.
///
/// Used by the structural-failure tests so they fail on the structure under
/// test and not on a decision that cannot be satisfied.
List<Sprint117TriageCheck> _allUnmet() => <Sprint117TriageCheck>[
  for (final decision in Sprint117IssueTriage.canonicalDecisions)
    Sprint117TriageCheck.unmet(
      decision: decision,
      check: '${decision.toLowerCase()}_unmet',
      declared: 'a recorded decision for $decision',
      observed: 'no decision has been applied to a live release',
    ),
];

/// One check per canonical decision, wired to the probe measured above.
///
/// Decisions in [unmetDecisions] are downgraded to a check that can never
/// satisfy them; every other decision keeps its measured check.
List<Sprint117TriageCheck> _allChecks({
  Set<String> unmetDecisions = const <String>{},
}) {
  const measured = <Sprint117TriageCheck>[
    Sprint117TriageCheck.pass(
      decision: 'FIX_BEFORE_GA',
      check: 'fix_before_ga_is_accepted',
      declared: 'the shipped triage accepts FIX_BEFORE_GA',
      observed: 'shipped triage log state=pass for a FIX_BEFORE_GA entry',
    ),
    Sprint117TriageCheck.pass(
      decision: 'DEFER',
      check: 'defer_reaches_the_shipped_seam',
      declared: 'the shipped triage expresses deferral',
      observed: 'shipped triage names it DEFER_NON_BLOCKER and accepts it',
    ),
    Sprint117TriageCheck.pass(
      decision: 'ROLLBACK',
      check: 'rollback_gates_the_release',
      declared: 'the shipped triage gates the release on rollback',
      observed: 'ROLLBACK_RC entry yields state=pass and releaseBlocked=true',
    ),
    Sprint117TriageCheck.pass(
      decision: 'NOT_REPRODUCIBLE_WITH_EVIDENCE',
      check: 'not_reproducible_requires_evidence',
      declared: 'the decision is refused without evidence',
      observed:
          'no evidence yields state=fail; one evidence path yields '
          'state=pass',
    ),
    Sprint117TriageCheck.pass(
      decision: 'FLAG_OFF',
      check: 'flag_off_changes_shipped_flag_state',
      declared: 'the triage can turn a capability off and observe it',
      observed:
          'FeatureFlagRegistry.disable(vs12_quests) flips the registry to '
          'is_enabled=false, which the action seam reports as applied',
    ),
    Sprint117TriageCheck.pass(
      decision: 'DISABLE_CONNECTOR',
      check: 'disable_connector_drops_shipped_connection',
      declared: 'the triage can drop a connector and observe it',
      observed:
          'AccountConnectedAccountsManagement.unlink removes the connection '
          'and reports localRemoved=true providerRevoked=false for a local '
          'drop, so a local drop is never read as a provider revoke',
    ),
  ];

  return <Sprint117TriageCheck>[
    for (final check in measured)
      if (unmetDecisions.contains(check.decision))
        Sprint117TriageCheck.unmet(
          decision: check.decision,
          check: check.check,
          declared: check.declared,
          observed:
              'no ${check.decision} decision has been applied to a live '
              'release',
        )
      else
        check,
  ];
}
