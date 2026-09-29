import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_117_beta_entry_gate.dart';

const String _manifestArtifact =
    'docs/planning/v1.3/sprint_117_beta_entry_gate.json';

Sprint117Sprint116Acceptance _sprint116Acceptance({
  String step = '116.52',
  String status = 'VERIFIED-LOCAL',
  String decision = 'CLOSED_LOCAL_DEFERRED_EXTERNAL',
  String betaDecision = 'BETA_ACCEPTANCE_LOCAL_READY',
  List<String> criteria = const <String>[
    '32_providers_accounted_for',
    'no_bulk_fake_certification',
    'icons_reviewed',
    'quality_gates_complete',
    'uncertified_hidden_or_labeled',
    'beta_decision_recorded',
    'remaining_risks_owned',
  ],
  List<String> decisionCriteria = const <String>[
    '32_providers_accounted_for',
    'no_bulk_fake_certification',
    'icons_reviewed',
    'quality_gates_complete',
    'uncertified_hidden_or_labeled',
    'beta_decision_recorded',
    'remaining_risks_owned',
  ],
}) => Sprint117Sprint116Acceptance(
  step: step,
  status: status,
  closureDecision: decision,
  betaDecision: betaDecision,
  definitionOfDone: criteria,
  metCriteria: decisionCriteria,
);

Sprint117CertificationRegistry _registry({
  int? providerCount,
  List<String> certified = const <String>['openai', 'gemini'],
  List<String> limited = const <String>['kofi'],
  List<String> blocked = const <String>['saweria'],
  int evidenceProviderCount = 3,
}) => Sprint117CertificationRegistry(
  // The default is derived from the subsets so a healthy fixture cannot
  // contradict itself; tests that exercise the unaccounted-registry rule pass
  // an explicit count.
  providerCount:
      providerCount ?? certified.length + limited.length + blocked.length,
  certified: certified,
  limited: limited,
  blocked: blocked,
  evidenceProviderCount: evidenceProviderCount,
);

Sprint117BetaArtifact _betaArtifact({
  String version = 'v1.3.0-beta.1',
  String pubspecVersion = 'v1.3.0-beta.1',
  bool releaseCut = true,
  bool artifactRecorded = true,
}) => Sprint117BetaArtifact(
  betaVersion: version,
  pubspecVersion: pubspecVersion,
  releaseCut: releaseCut,
  artifactRecorded: artifactRecorded,
);

Sprint117KnownIssues _knownIssues({
  List<String> issueIds = const <String>['ki_release_cut'],
  List<String> ownedBy = const <String>['operator'],
  int declaredCount = 1,
}) => Sprint117KnownIssues(
  issueIds: issueIds,
  owners: ownedBy,
  declaredCount: declaredCount,
);

Sprint117RollbackReadiness _rollback({
  int stopConditions = 5,
  int rollbackProcedures = 3,
  int killSwitches = 2,
  int coveredConnectors = 2,
  List<String> exposedConnectors = const <String>['conn_openai', 'conn_gemini'],
  List<String> killSwitchedConnectors = const <String>[
    'conn_openai',
    'conn_gemini',
  ],
  bool drillExecuted = false,
}) => Sprint117RollbackReadiness(
  stopConditions: stopConditions,
  rollbackProcedures: rollbackProcedures,
  killSwitches: killSwitches,
  coveredConnectors: coveredConnectors,
  exposedConnectors: exposedConnectors,
  killSwitchedConnectors: killSwitchedConnectors,
  drillExecuted: drillExecuted,
);

Sprint117BetaEntryInput _healthyInput({
  Sprint117Sprint116Acceptance? sprint116,
  Sprint117CertificationRegistry? registry,
  Sprint117BetaArtifact? betaArtifact,
  Sprint117KnownIssues? knownIssues,
  Sprint117RollbackReadiness? rollback,
  bool omitAcceptance = false,
  bool omitRegistry = false,
  bool omitBetaArtifact = false,
  bool omitKnownIssues = false,
  bool omitRollback = false,
}) => Sprint117BetaEntryInput(
  sprint116Acceptance: omitAcceptance
      ? null
      : sprint116 ?? _sprint116Acceptance(),
  certificationRegistry: omitRegistry ? null : registry ?? _registry(),
  betaArtifact: omitBetaArtifact ? null : betaArtifact ?? _betaArtifact(),
  knownIssues: omitKnownIssues ? null : knownIssues ?? _knownIssues(),
  rollbackReadiness: omitRollback ? null : rollback ?? _rollback(),
);

void main() {
  group('117.1 Beta Entry Gate contract', () {
    test('locks the six evidence areas the canonical step demands', () {
      expect(Sprint117BetaEntryContract.requiredEvidence, <String>[
        'sprint_116_acceptance',
        'certification_registry',
        'certified_or_limited_subset',
        'beta_artifact',
        'known_issues',
        'rollback_readiness',
      ]);
      expect(Sprint117BetaEntryContract.canonicalStep, '117.1');
      expect(
        Sprint117BetaEntryContract.manifestPath,
        'docs/planning/v1.3/sprint_117_beta_entry_gate.json',
      );
      expect(
        Sprint117BetaEntryContract.ledgerPath,
        'docs/sprints/sprint-117-beta-validation.md',
      );
      expect(
        Sprint117BetaEntryContract.closureManifestPath,
        'docs/planning/v1.2/sprint_116_sprint_closure.json',
      );
      expect(
        Sprint117BetaEntryContract.acceptanceManifestPath,
        'docs/planning/v1.2/sprint_116_beta_acceptance_gate.json',
      );
      expect(
        Sprint117BetaEntryContract.rolloutManifestPath,
        'docs/planning/v1.2/sprint_116_staged_beta_rollout_monitoring.json',
      );
      expect(Sprint117BetaEntryContract.ledgerPath, contains('117'));
      expect(Sprint117BetaEntryContract.externalGates, 'DEFERRED-EXTERNAL');
      expect(Sprint117BetaEntryContract.startCondition, contains('CERTIFIED'));
      expect(Sprint117BetaEntryContract.betaVersion, 'v1.3.0-beta.1');
      expect(
        Sprint117BetaEntryContract.canonicalEntryReadiness,
        'BLOCKED_NO_CERTIFIED_CONNECTOR_CURRENTLY_RECORDED',
      );
      expect(Sprint117BetaEntryContract.knownVerdicts, <String>[
        'BETA_ENTRY_LOCAL_READY',
        'BETA_ENTRY_BLOCKED',
        'BETA_ENTRY_FAILED',
      ]);
      expect(Sprint117BetaEntryContract.knownVisibilities, <String>[
        'certified',
        'limited',
        'blocked',
      ]);
    });

    test('a healthy synthetic input passes every evidence area', () {
      final report = Sprint117BetaEntryGate().evaluateWith(_healthyInput());
      expect(report.state, Sprint117BetaEntryState.pass);
      expect(report.verdict, 'BETA_ENTRY_LOCAL_READY');
      expect(report.missingEvidence, isEmpty);
      expect(report.violations, isEmpty);
      expect(report.certifiedSubset, <String>['openai', 'gemini']);
      expect(report.limitedSubset, <String>['kofi']);
      expect(report.blockedSubset, <String>['saweria']);
      expect(report.exposedBetaSubset, <String>['openai', 'gemini', 'kofi']);
      expect(
        report.evidenceCoverage.keys,
        containsAll(Sprint117BetaEntryContract.requiredEvidence),
      );
      expect(report.releaseCut, isTrue);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });
  });

  group('117.1 live repository evaluation', () {
    test('the live gate resolves the canonical entry block honestly', () {
      final report = Sprint117BetaEntryGate().evaluate();
      expect(
        report.state,
        isNot(Sprint117BetaEntryState.fail),
        reason: report.violations.toString(),
      );
      expect(
        report.missingEvidence,
        isEmpty,
        reason:
            'every canonical evidence area must resolve: '
            '${report.missingEvidence}',
      );
      // Sprint 116 closed locally and its acceptance gate passed with a real
      // certified/limited split, so the document-creation entry block
      // (0 certified / 0 limited) no longer describes the repository.
      expect(report.sprint116Closed, isTrue);
      expect(report.certifiedSubset, isNotEmpty);
      expect(report.limitedSubset, isNotEmpty);
      expect(
        report.certifiedSubset.length +
            report.limitedSubset.length +
            report.blockedSubset.length,
        32,
      );
      expect(report.blockedSubset, isNotEmpty);
      // Release cut is an open item, reported next to the beta target and
      // never assumed equal.
      expect(report.betaVersion, 'v1.3.0-beta.1');
      expect(report.pubspecVersion, isNotEmpty);
      expect(report.releaseCut, report.pubspecVersion == '1.3.0-beta.1');
      expect(report.openItems, contains(startsWith('release_cut_pending')));
      expect(report.liveBetaExecuted, isFalse);
    });

    test(
      'the live certified subset matches the 116.51 acceptance gate exactly',
      () {
        final report = Sprint117BetaEntryGate().evaluate();
        final acceptance =
            jsonDecode(
                  File(
                    Sprint117BetaEntryContract.acceptanceManifestPath,
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        expect(
          report.certifiedSubset,
          List<String>.from(acceptance['certified_subset'] as List<dynamic>),
        );
        expect(
          report.limitedSubset,
          List<String>.from(acceptance['limited_connectors'] as List<dynamic>),
        );
        expect(
          report.blockedSubset,
          List<String>.from(acceptance['blocked_connectors'] as List<dynamic>),
        );
        expect(
          report.certifiedSubset.length +
              report.limitedSubset.length +
              report.blockedSubset.length,
          report.registryProviderCount,
        );
      },
    );

    test('every provider that has not passed is kept out of the beta', () {
      final report = Sprint117BetaEntryGate().evaluate();
      final exposed = report.exposedBetaSubset.toSet();
      for (final provider in report.certifiedSubset) {
        expect(exposed.contains(provider), isTrue, reason: provider);
      }
      for (final provider in report.limitedSubset) {
        expect(exposed.contains(provider), isTrue, reason: provider);
      }
      for (final provider in report.blockedSubset) {
        expect(exposed.contains(provider), isFalse, reason: provider);
        expect(report.visibility[provider], 'blocked');
      }
    });

    test('the live rollback readiness comes from the 116.50 rollout plan', () {
      final report = Sprint117BetaEntryGate().evaluate();
      expect(report.rollbackStopConditions, greaterThan(0));
      expect(report.rollbackProcedures, greaterThan(0));
      expect(report.killSwitches, greaterThan(0));
      expect(report.exposedConnectors, isNotEmpty);
      expect(
        report.rollbackKillSwitchedConnectors,
        containsAll(report.exposedConnectors),
      );
      // No drill has ever run against a real system; that stays visible.
      expect(report.rollbackDrillExecuted, isFalse);
    });

    test('the committed manifest matches the live gate result', () {
      final report = Sprint117BetaEntryGate().evaluate();
      final manifest =
          jsonDecode(
                File(
                  Sprint117BetaEntryContract.manifestPath,
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;

      expect(manifest['canonical_step'], '117.1');
      expect(manifest['status'], 'UNVERIFIED');
      expect(manifest['live_beta_executed'], isFalse);
      expect(
        manifest['required_evidence'],
        Sprint117BetaEntryContract.requiredEvidence,
      );
      expect(manifest['beta_version'], report.betaVersion);
      expect(manifest['pubspec_version'], report.pubspecVersion);
      expect(manifest['release_cut'], report.releaseCut);
      expect(manifest['state'], report.state.name);
      expect(manifest['verdict'], report.verdict);
      expect(manifest['registry_provider_count'], report.registryProviderCount);
      expect(manifest['certified_subset'], report.certifiedSubset);
      expect(manifest['limited_subset'], report.limitedSubset);
      expect(manifest['blocked_subset'], report.blockedSubset);
      expect(
        List<String>.from(manifest['open_items'] as List<dynamic>),
        report.openItems,
      );
      expect(manifest['external_gates'], 'DEFERRED-EXTERNAL');
    });

    test('the committed manifest carries no secret material', () {
      final raw = File(_manifestArtifact).readAsStringSync();
      final manifest = jsonDecode(raw) as Map<String, dynamic>;
      final report = Sprint117BetaEntryGate().evaluate();
      final vocabulary = <String>{
        ...Sprint117BetaEntryContract.requiredEvidence,
        ...Sprint117BetaEntryContract.knownVisibilities,
        ...report.certifiedSubset,
        ...report.limitedSubset,
        ...report.blockedSubset,
        ...report.exposedConnectors,
        ...report.knownIssueIds,
      };

      bool carriesSecret(Object? node) {
        if (node is Map) {
          for (final entry in node.entries) {
            final key = entry.key.toString().toLowerCase();
            if (key.contains('api_key') || key.contains('secret')) {
              return true;
            }
            if (carriesSecret(entry.value)) return true;
          }
          return false;
        }
        if (node is List) return node.any(carriesSecret);
        final text = node.toString();
        if (vocabulary.contains(text)) return false;
        return text.toLowerCase().contains('api_key') ||
            text.toLowerCase().contains('bearer') ||
            text.toLowerCase().contains('private_key') ||
            text.contains('sk-');
      }

      expect(carriesSecret(manifest), isFalse);
      expect(raw.contains('sk-'), isFalse);
    });
  });

  group('117.1 fail-closed sprint 116 acceptance', () {
    test('an absent sprint 116 acceptance blocks the acceptance area', () {
      final report = Sprint117BetaEntryGate().evaluateWith(
        _healthyInput(omitAcceptance: true),
      );
      expect(report.state, Sprint117BetaEntryState.blocked);
      expect(report.missingEvidence, contains('sprint_116_acceptance'));
    });

    test('a sprint 116 that is not closed blocks the entry', () {
      final report = Sprint117BetaEntryGate().evaluateWith(
        _healthyInput(sprint116: _sprint116Acceptance(decision: 'NOT_CLOSED')),
      );
      expect(report.state, Sprint117BetaEntryState.blocked);
      expect(report.missingEvidence, contains('sprint_116_acceptance'));
      expect(report.sprint116Closed, isFalse);
    });

    test('a sprint 116 closure that is not verified fails the entry', () {
      final report = Sprint117BetaEntryGate().evaluateWith(
        _healthyInput(sprint116: _sprint116Acceptance(status: 'PENDING')),
      );
      expect(report.state, Sprint117BetaEntryState.fail);
      expect(report.violations, contains('sprint_116_status:PENDING'));
    });

    test('a closure recorded against another step fails the entry', () {
      final report = Sprint117BetaEntryGate().evaluateWith(
        _healthyInput(sprint116: _sprint116Acceptance(step: '116.51')),
      );
      expect(report.state, Sprint117BetaEntryState.fail);
      expect(report.violations, contains('sprint_116_step:116.51'));
    });

    test(
      'a closure that claims a beta decision sprint 116 never reached fails',
      () {
        final report = Sprint117BetaEntryGate().evaluateWith(
          _healthyInput(
            sprint116: _sprint116Acceptance(
              betaDecision: 'BETA_ACCEPTANCE_BLOCKED',
            ),
          ),
        );
        expect(report.state, Sprint117BetaEntryState.fail);
        expect(
          report.violations,
          contains('sprint_116_beta_decision:BETA_ACCEPTANCE_BLOCKED'),
        );
      },
    );

    test(
      'a closure whose criteria were skipped blocks the entry and names them',
      () {
        final report = Sprint117BetaEntryGate().evaluateWith(
          _healthyInput(
            sprint116: _sprint116Acceptance(
              decisionCriteria: const <String>['beta_decision_recorded'],
            ),
          ),
        );
        // An unmet definition-of-done means the acceptance evidence is
        // incomplete, which blocks rather than fails; the criterion is still
        // recorded as a violation and named, mirroring the 116.52 closure
        // contract that reports an unmet criterion as blocked by name.
        expect(report.state, Sprint117BetaEntryState.blocked);
        expect(report.unmetClosureCriteria, contains('icons_reviewed'));
        expect(report.missingEvidence, contains('sprint_116_acceptance'));
        expect(report.violations, contains('closure_criterion:icons_reviewed'));
      },
    );
  });

  group('117.1 fail-closed certification registry', () {
    test('an absent certification registry blocks the registry area', () {
      final report = Sprint117BetaEntryGate().evaluateWith(
        _healthyInput(omitRegistry: true),
      );
      expect(report.state, Sprint117BetaEntryState.blocked);
      expect(report.missingEvidence, contains('certification_registry'));
    });

    test('a registry with no certified or limited subset blocks the entry', () {
      final report = Sprint117BetaEntryGate().evaluateWith(
        _healthyInput(
          registry: _registry(
            certified: const <String>[],
            limited: const <String>[],
            evidenceProviderCount: 1,
          ),
        ),
      );
      expect(report.state, Sprint117BetaEntryState.blocked);
      expect(report.missingEvidence, contains('certified_or_limited_subset'));
    });

    test('a subset that does not account for the registry fails the entry', () {
      final report = Sprint117BetaEntryGate().evaluateWith(
        _healthyInput(
          registry: _registry(
            providerCount: 32,
            certified: const <String>['openai'],
            limited: const <String>[],
            blocked: const <String>['saweria'],
          ),
        ),
      );
      expect(report.state, Sprint117BetaEntryState.fail);
      expect(
        report.violations.any((v) => v.startsWith('registry_unaccounted')),
        isTrue,
        reason: report.violations.toString(),
      );
    });

    test('a provider appears in two subsets at once fails the entry', () {
      final report = Sprint117BetaEntryGate().evaluateWith(
        _healthyInput(
          registry: _registry(
            certified: const <String>['openai', 'gemini'],
            limited: const <String>['gemini'],
            blocked: const <String>['saweria'],
          ),
        ),
      );
      expect(report.state, Sprint117BetaEntryState.fail);
      expect(report.violations, contains('subset_overlap:gemini'));
    });

    test('an empty provider name is rejected as a phantom record', () {
      final report = Sprint117BetaEntryGate().evaluateWith(
        _healthyInput(
          registry: _registry(
            // A certified subset survives so the blank name is the only
            // defect: without one the gate blocks on the missing subset before
            // the phantom record can fail the entry.
            certified: const <String>['openai', ''],
            limited: const <String>[],
            blocked: const <String>['saweria'],
            evidenceProviderCount: 1,
          ),
        ),
      );
      expect(report.state, Sprint117BetaEntryState.fail);
      expect(report.violations, contains('phantom_provider:'));
    });
  });

  group('117.1 fail-closed beta artifact', () {
    test('an absent beta artifact blocks the artifact area', () {
      final report = Sprint117BetaEntryGate().evaluateWith(
        _healthyInput(omitBetaArtifact: true),
      );
      expect(report.state, Sprint117BetaEntryState.blocked);
      expect(report.missingEvidence, contains('beta_artifact'));
    });

    test('a beta target other than the contract version fails the entry', () {
      final report = Sprint117BetaEntryGate().evaluateWith(
        _healthyInput(betaArtifact: _betaArtifact(version: 'v1.4.0')),
      );
      expect(report.state, Sprint117BetaEntryState.fail);
      expect(report.violations, contains('beta_version:v1.4.0'));
    });

    test(
      'an uncertified release cut is an open item, not a certification claim',
      () {
        final report = Sprint117BetaEntryGate().evaluateWith(
          _healthyInput(
            betaArtifact: _betaArtifact(
              pubspecVersion: '1.2.0-rc.1',
              releaseCut: false,
            ),
          ),
        );
        expect(report.state, Sprint117BetaEntryState.pass);
        expect(report.releaseCut, isFalse);
        expect(report.openItems, contains(startsWith('release_cut_pending')));
      },
    );

    test(
      'a beta artifact that was never recorded blocks the artifact area',
      () {
        final report = Sprint117BetaEntryGate().evaluateWith(
          _healthyInput(betaArtifact: _betaArtifact(artifactRecorded: false)),
        );
        expect(report.state, Sprint117BetaEntryState.blocked);
        expect(report.missingEvidence, contains('beta_artifact'));
      },
    );
  });

  group('117.1 fail-closed known issues and rollback', () {
    test('absent known issues blocks the issues area', () {
      final report = Sprint117BetaEntryGate().evaluateWith(
        _healthyInput(omitKnownIssues: true),
      );
      expect(report.state, Sprint117BetaEntryState.blocked);
      expect(report.missingEvidence, contains('known_issues'));
    });

    test('an issue with no owner fails the entry', () {
      final report = Sprint117BetaEntryGate().evaluateWith(
        _healthyInput(knownIssues: _knownIssues(ownedBy: const <String>[])),
      );
      expect(report.state, Sprint117BetaEntryState.fail);
      expect(report.violations.any((v) => v.startsWith('issue_owner')), isTrue);
    });

    test('an unowned declared issue count fails the entry', () {
      final report = Sprint117BetaEntryGate().evaluateWith(
        _healthyInput(
          knownIssues: _knownIssues(
            issueIds: const <String>['ki_release_cut'],
            ownedBy: const <String>['operator'],
            declaredCount: 2,
          ),
        ),
      );
      expect(report.state, Sprint117BetaEntryState.fail);
      expect(report.violations, contains('issue_ownership:2:1'));
    });

    test('absent rollback readiness blocks the rollback area', () {
      final report = Sprint117BetaEntryGate().evaluateWith(
        _healthyInput(omitRollback: true),
      );
      expect(report.state, Sprint117BetaEntryState.blocked);
      expect(report.missingEvidence, contains('rollback_readiness'));
    });

    test('a rollout with no stop condition fails the entry', () {
      final report = Sprint117BetaEntryGate().evaluateWith(
        _healthyInput(rollback: _rollback(stopConditions: 0)),
      );
      expect(report.state, Sprint117BetaEntryState.fail);
      expect(report.violations, contains('rollback_stop_conditions'));
    });

    test('a rollout with no kill switch fails the entry', () {
      final report = Sprint117BetaEntryGate().evaluateWith(
        _healthyInput(rollback: _rollback(killSwitches: 0)),
      );
      expect(report.state, Sprint117BetaEntryState.fail);
      expect(report.violations, contains('rollback_kill_switches'));
    });

    test('an exposed connector without a kill switch fails the entry', () {
      final report = Sprint117BetaEntryGate().evaluateWith(
        _healthyInput(
          rollback: _rollback(
            exposedConnectors: const <String>['conn_openai', 'conn_gemini'],
            killSwitchedConnectors: const <String>['conn_openai'],
          ),
        ),
      );
      expect(report.state, Sprint117BetaEntryState.fail);
      expect(report.violations, contains('kill_switch_coverage:conn_gemini'));
      expect(report.rollbackReady, isFalse);
    });
  });
}
