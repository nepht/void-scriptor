import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_expansion_contract_e2e.dart';

/// A single expansion-contract entry. Each test flips exactly the one thing it
/// is about, so a test that flips nothing proves the pass path exists and every
/// other test proves one way the gate refuses to take it.
Sprint118ExpansionConnectorEntry _entry({
  String providerId = 'stripe',
  String manifest = Sprint118ExpansionE2eContract.manifestToken,
  String auth = Sprint118ExpansionE2eContract.authToken,
  String capability = Sprint118ExpansionE2eContract.capabilityToken,
  String usage = Sprint118ExpansionE2eContract.usageToken,
  String error = Sprint118ExpansionE2eContract.errorToken,
  String reauth = Sprint118ExpansionE2eContract.reauthToken,
  String disconnect = Sprint118ExpansionE2eContract.disconnectToken,
  String cleanup = Sprint118ExpansionE2eContract.cleanupToken,
  String regression = Sprint118ExpansionE2eContract.regressionToken,
  bool connected = false,
  bool used = false,
  bool refreshed = false,
  bool reauthenticated = false,
  bool disconnected = false,
  bool cleanedUp = false,
  bool e2ePassed = false,
  bool certified = false,
  bool released = false,
}) {
  return Sprint118ExpansionConnectorEntry(
    providerId: providerId,
    manifest: manifest,
    auth: auth,
    capability: capability,
    usage: usage,
    error: error,
    reauth: reauth,
    disconnect: disconnect,
    cleanup: cleanup,
    regression: regression,
    connected: connected,
    used: used,
    refreshed: refreshed,
    reauthenticated: reauthenticated,
    disconnected: disconnected,
    cleanedUp: cleanedUp,
    e2ePassed: e2ePassed,
    certified: certified,
    released: released,
  );
}

Sprint118ExpansionContractRecord _record({
  String releaseState = Sprint118ExpansionE2eContract.delayedReleaseState,
  List<Sprint118ExpansionConnectorEntry>? entries,
}) {
  return Sprint118ExpansionContractRecord(
    releaseState: releaseState,
    entries: entries ?? Sprint118ExpansionE2eContract.canonicalRecord.entries,
  );
}

/// The canonical entries with exactly one provider replaced, so a test can flip
/// a single entry without rebuilding the whole record.
List<Sprint118ExpansionConnectorEntry> _replacing(
  String providerId,
  Sprint118ExpansionConnectorEntry replacement,
) {
  return <Sprint118ExpansionConnectorEntry>[
    for (final e in Sprint118ExpansionE2eContract.canonicalRecord.entries)
      if (e.providerId == providerId) replacement else e,
  ];
}

Sprint118ExpansionContractAnchor _anchor({
  String charterState = 'pass',
  String charterVerdict = Sprint118ExpansionE2eContract.requiredCharterVerdict,
  int charterMaxNewCertified = 0,
  int charterCurrentlyCertified = 0,
  int charterRegisteredProviders =
      Sprint118ExpansionE2eContract.expectedProviderCount,
  String snapshotState = 'pass',
  String snapshotVerdict =
      Sprint118ExpansionE2eContract.requiredSnapshotVerdict,
  int snapshotCertified = 0,
  int snapshotRegistered = Sprint118ExpansionE2eContract.expectedProviderCount,
  String releaseState = Sprint118ExpansionE2eContract.delayedReleaseState,
  int registryExpectedCount =
      Sprint118ExpansionE2eContract.expectedProviderCount,
  int registryEvidenceProviderCount =
      Sprint118ExpansionE2eContract.expectedProviderCount,
  int registryEvidenceExposed = 0,
  int registryEvidenceWithheld =
      Sprint118ExpansionE2eContract.expectedProviderCount,
  int snapshotLockLockedCount =
      Sprint118ExpansionE2eContract.expectedProviderCount,
  String approvalDecision =
      Sprint118ExpansionE2eContract.requiredApprovalDecision,
  String approvalState = 'PENDING_CHOIRUDIN',
  bool executionAuthorized = false,
  bool releaseBlocked = true,
  List<String>? registeredProviders,
  List<String>? suiteContractVocabulary,
  List<String>? manifestVocabulary,
  List<String>? authVocabulary,
  List<String>? capabilityVocabulary,
  List<String>? usageVocabulary,
  List<String>? errorVocabulary,
  List<String>? reauthVocabulary,
  List<String>? disconnectVocabulary,
  List<String>? cleanupVocabulary,
  List<String>? regressionVocabulary,
  List<String>? readableSources,
}) {
  return Sprint118ExpansionContractAnchor(
    charterState: charterState,
    charterVerdict: charterVerdict,
    charterMaxNewCertified: charterMaxNewCertified,
    charterCurrentlyCertified: charterCurrentlyCertified,
    charterRegisteredProviders: charterRegisteredProviders,
    snapshotState: snapshotState,
    snapshotVerdict: snapshotVerdict,
    snapshotCertified: snapshotCertified,
    snapshotRegistered: snapshotRegistered,
    releaseState: releaseState,
    registryExpectedCount: registryExpectedCount,
    registryEvidenceProviderCount: registryEvidenceProviderCount,
    registryEvidenceExposed: registryEvidenceExposed,
    registryEvidenceWithheld: registryEvidenceWithheld,
    snapshotLockLockedCount: snapshotLockLockedCount,
    approvalDecision: approvalDecision,
    approvalState: approvalState,
    executionAuthorized: executionAuthorized,
    releaseBlocked: releaseBlocked,
    registeredProviders:
        registeredProviders ?? Sprint118ExpansionE2eContract.canonicalProviders,
    suiteContractVocabulary:
        suiteContractVocabulary ??
        Sprint118ExpansionE2eContract.requiredOutputs,
    manifestVocabulary:
        manifestVocabulary ?? const <String>['connector_version'],
    authVocabulary: authVocabulary ?? const <String>['scoped_consent'],
    capabilityVocabulary:
        capabilityVocabulary ?? const <String>['capabilities'],
    usageVocabulary: usageVocabulary ?? const <String>['usage_units'],
    errorVocabulary: errorVocabulary ?? const <String>['invalid_credentials'],
    reauthVocabulary: reauthVocabulary ?? const <String>['reauth'],
    disconnectVocabulary:
        disconnectVocabulary ?? const <String>['unlink_confirmation'],
    cleanupVocabulary: cleanupVocabulary ?? const <String>['no_plaintext'],
    regressionVocabulary: regressionVocabulary ?? const <String>['regression'],
    readableSources:
        readableSources ??
        Sprint118ExpansionE2eContract.witnessSources.toSet().toList(),
  );
}

Sprint118ExpansionContractReport _run(
  Sprint118ExpansionContractRecord record, {
  Sprint118ExpansionContractAnchor? anchor,
}) {
  return const Sprint118ExpansionContractGate().evaluateWith(
    anchor ?? _anchor(),
    record,
  );
}

void main() {
  group('Sprint 118.40 Expansion Contract & End-to-End Tests', () {
    test('the canonical field vocabulary is the ten objective fields', () {
      expect(Sprint118ExpansionE2eContract.requiredFields, <String>[
        'provider_id',
        'manifest',
        'auth',
        'capability',
        'usage',
        'error',
        'reauth',
        'disconnect',
        'cleanup',
        'regression',
      ]);
    });

    test('the canonical outputs are the nine objective suites', () {
      expect(Sprint118ExpansionE2eContract.requiredOutputs, <String>[
        'manifest',
        'auth',
        'capability',
        'usage',
        'error',
        'reauth',
        'disconnect',
        'cleanup',
        'regression',
      ]);
    });

    test(
      'the reference-state vocabulary is derived from committed witnesses',
      () {
        final vocabulary = Sprint118ExpansionE2eContract.stateVocabulary(
          <List<String>>[
            const <String>['connector_version', 'scoped_consent'],
            const <String>['capabilities', 'usage_units'],
          ],
        );
        expect(vocabulary, contains('connector_version'));
        expect(vocabulary, contains('scoped_consent'));
        expect(vocabulary, contains('capabilities'));
        expect(vocabulary, contains('usage_units'));
        expect(
          vocabulary,
          contains(Sprint118ExpansionE2eContract.noReferenceState),
        );
        expect(
          Sprint118ExpansionE2eContract.grounds(
            vocabulary,
            'connector_version',
          ),
          isTrue,
        );
        expect(
          Sprint118ExpansionE2eContract.grounds(vocabulary, 'telepathy'),
          isFalse,
        );
      },
    );

    test(
      'a compound reference state is grounded only when every part is a witness value',
      () {
        final vocabulary = <String>['no_plaintext', 'os_secure_store'];
        expect(
          Sprint118ExpansionE2eContract.grounds(vocabulary, 'no_plaintext'),
          isTrue,
        );
        expect(
          Sprint118ExpansionE2eContract.grounds(vocabulary, 'os_secure_store'),
          isTrue,
        );
        expect(
          Sprint118ExpansionE2eContract.grounds(vocabulary, 'no_telepathy'),
          isFalse,
        );
      },
    );

    test(
      'canonical record covers all 32 registered providers and claims nothing',
      () {
        final record = Sprint118ExpansionE2eContract.canonicalRecord;
        expect(record.entries.length, 32);
        expect(
          record.providerIds.toSet(),
          Sprint118ExpansionE2eContract.canonicalProviders.toSet(),
        );
        for (final entry in record.entries) {
          expect(entry.connected, isFalse);
          expect(entry.used, isFalse);
          expect(entry.refreshed, isFalse);
          expect(entry.reauthenticated, isFalse);
          expect(entry.disconnected, isFalse);
          expect(entry.cleanedUp, isFalse);
          expect(entry.e2ePassed, isFalse);
          expect(entry.certified, isFalse);
          expect(entry.released, isFalse);
          for (final field in Sprint118ExpansionE2eContract.requiredFields) {
            expect(
              (entry.requiredFields[field] ?? '').trim(),
              isNotEmpty,
              reason: '${entry.providerId}.$field must not be blank',
            );
          }
        }
      },
    );

    test('passes on the canonical record and claims no live suite', () {
      final report = _run(_record());
      expect(report.state, Sprint118ExpansionContractState.pass);
      expect(report.verdict, 'EXPANSION_CONTRACT_E2E_VERIFIED_LOCAL');
      expect(report.contractVerified, isTrue);
      expect(report.declaredProviders.length, 32);
      expect(report.connectedProviders, isEmpty);
      expect(report.passedProviders, isEmpty);
      expect(report.certifiedProviders, isEmpty);
      expect(report.releasedProviders, isEmpty);
      expect(report.expansionBudgetFrozen, isTrue);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      expect(report.openItems, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118ExpansionContractGate().evaluateWith(
        null,
        _record(),
      );
      expect(report.state, Sprint118ExpansionContractState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_EXPANSION_CONTRACT_EVIDENCE_UNREADABLE',
      );
      expect(report.contractVerified, isFalse);
      expect(
        report.blockers,
        contains('committed_expansion_contract_evidence_unreadable'),
      );
    });

    test('blocks when the committed charter is not complete', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterVerdict: 'CHARTER_INCOMPLETE_LOCAL'),
      );
      expect(report.state, Sprint118ExpansionContractState.blocked);
      expect(report.verdict, 'SPRINT_118_EXPANSION_CONTRACT_BLOCKED_UPSTREAM');
      expect(
        report.blockers.any((b) => b.startsWith('charter_not_complete:')),
        isTrue,
      );
    });

    test('blocks when the committed snapshot is not frozen', () {
      final report = _run(
        _record(),
        anchor: _anchor(snapshotVerdict: 'CERTIFIED_CONNECTOR_SNAPSHOT_DRIFT'),
      );
      expect(report.state, Sprint118ExpansionContractState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('snapshot_not_frozen:')),
        isTrue,
      );
    });

    test('blocks when the committed approval gate is not a delay', () {
      final report = _run(
        _record(),
        anchor: _anchor(approvalDecision: 'release'),
      );
      expect(report.state, Sprint118ExpansionContractState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('approval_gate_not_delay:')),
        isTrue,
      );
    });

    test('blocks when the registered provider set does not reconcile', () {
      final report = _run(
        _record(),
        anchor: _anchor(registryExpectedCount: 31),
      );
      expect(report.state, Sprint118ExpansionContractState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('registry_not_reconciled:')),
        isTrue,
      );
    });

    test(
      'blocks when the registry evidence provider count does not reconcile',
      () {
        final report = _run(
          _record(),
          anchor: _anchor(registryEvidenceProviderCount: 31),
        );
        expect(report.state, Sprint118ExpansionContractState.blocked);
        expect(
          report.blockers.any((b) => b.startsWith('registry_not_reconciled:')),
          isTrue,
        );
      },
    );

    test('blocks when the snapshot lock count does not reconcile', () {
      final report = _run(
        _record(),
        anchor: _anchor(snapshotLockLockedCount: 31),
      );
      expect(report.state, Sprint118ExpansionContractState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('registry_not_reconciled:')),
        isTrue,
      );
    });

    test('blocks when the registry visibility does not reconcile', () {
      final report = _run(
        _record(),
        anchor: _anchor(registryEvidenceWithheld: 31),
      );
      expect(report.state, Sprint118ExpansionContractState.blocked);
      expect(
        report.blockers.any(
          (b) => b.startsWith('registry_visibility_not_reconciled:'),
        ),
        isTrue,
      );
    });

    test('blocks when the registry already exposes a connector', () {
      final report = _run(
        _record(),
        anchor: _anchor(
          registryEvidenceExposed: 1,
          registryEvidenceWithheld: 31,
        ),
      );
      expect(report.state, Sprint118ExpansionContractState.blocked);
      expect(
        report.blockers.any(
          (b) => b.startsWith('registry_visibility_exposed_on_delayed_path:'),
        ),
        isTrue,
      );
    });

    test('blocks when the suite contract does not reconcile', () {
      final report = _run(
        _record(),
        anchor: _anchor(
          suiteContractVocabulary: const <String>['manifest', 'auth'],
        ),
      );
      expect(report.state, Sprint118ExpansionContractState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('suite_contract_missing:')),
        isTrue,
      );
      expect(
        report.blockers.any(
          (b) => b.startsWith('suite_contract_not_reconciled:'),
        ),
        isTrue,
      );
    });

    test('fails when a provider claims a connected connector', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', connected: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionContractState.fail);
      expect(
        report.violations,
        contains('expansion_contract_connected_claimed_on_delayed_path:stripe'),
      );
      expect(report.connectedCount, 1);
    });

    test('fails when a provider claims a used connector', () {
      final report = _run(
        _record(
          entries: _replacing(
            'paypal',
            _entry(providerId: 'paypal', used: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionContractState.fail);
      expect(
        report.violations,
        contains('expansion_contract_used_claimed_on_delayed_path:paypal'),
      );
    });

    test('fails when a provider claims a refreshed token', () {
      final report = _run(
        _record(
          entries: _replacing(
            'midtrans',
            _entry(providerId: 'midtrans', refreshed: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionContractState.fail);
      expect(
        report.violations,
        contains(
          'expansion_contract_refreshed_claimed_on_delayed_path:midtrans',
        ),
      );
    });

    test('fails when a provider claims a reauthenticated connector', () {
      final report = _run(
        _record(
          entries: _replacing(
            'saweria',
            _entry(providerId: 'saweria', reauthenticated: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionContractState.fail);
      expect(
        report.violations,
        contains(
          'expansion_contract_reauthenticated_claimed_on_delayed_path:saweria',
        ),
      );
    });

    test('fails when a provider claims a disconnected connector', () {
      final report = _run(
        _record(
          entries: _replacing(
            'kofi',
            _entry(providerId: 'kofi', disconnected: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionContractState.fail);
      expect(
        report.violations,
        contains(
          'expansion_contract_disconnected_claimed_on_delayed_path:kofi',
        ),
      );
    });

    test('fails when a provider claims a cleaned-up credential', () {
      final report = _run(
        _record(
          entries: _replacing(
            'google_drive',
            _entry(providerId: 'google_drive', cleanedUp: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionContractState.fail);
      expect(
        report.violations,
        contains(
          'expansion_contract_cleaned_up_claimed_on_delayed_path:google_drive',
        ),
      );
    });

    test('fails when a provider claims a passed end-to-end suite', () {
      final report = _run(
        _record(
          entries: _replacing(
            'github',
            _entry(providerId: 'github', e2ePassed: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionContractState.fail);
      expect(
        report.violations,
        contains(
          'expansion_contract_e2e_passed_claimed_on_delayed_path:github',
        ),
      );
      expect(report.passedCount, 1);
    });

    test('fails when a provider claims a certified connector', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', certified: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionContractState.fail);
      expect(
        report.violations,
        contains('expansion_contract_certified_claimed_on_delayed_path:openai'),
      );
      expect(report.certifiedCount, 1);
    });

    test('fails when a provider is claimed released', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', released: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionContractState.fail);
      expect(
        report.violations,
        contains('expansion_contract_released_claimed:stripe'),
      );
      expect(report.releasedCount, 1);
    });

    test('fails when the expansion budget is not frozen', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterMaxNewCertified: 1),
      );
      expect(report.state, Sprint118ExpansionContractState.fail);
      expect(
        report.violations.any(
          (v) =>
              v.startsWith('expansion_contract_expansion_budget_not_frozen:'),
        ),
        isTrue,
      );
      expect(report.expansionBudgetFrozen, isFalse);
    });

    test('fails when the snapshot certifies a connector', () {
      final report = _run(_record(), anchor: _anchor(snapshotCertified: 1));
      expect(report.state, Sprint118ExpansionContractState.fail);
      expect(
        report.violations,
        contains('expansion_contract_snapshot_certified_nonzero:1'),
      );
    });

    test('fails when a registered provider is missing', () {
      final entries = <Sprint118ExpansionConnectorEntry>[
        for (final e in Sprint118ExpansionE2eContract.canonicalRecord.entries)
          if (e.providerId != 'kofi') e,
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118ExpansionContractState.fail);
      expect(
        report.violations,
        contains('expansion_contract_provider_missing:kofi'),
      );
    });

    test('fails when an unknown provider is invented', () {
      final entries = <Sprint118ExpansionConnectorEntry>[
        ...Sprint118ExpansionE2eContract.canonicalRecord.entries,
        _entry(providerId: 'telepathy'),
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118ExpansionContractState.fail);
      expect(
        report.violations,
        contains('expansion_contract_provider_unknown:telepathy'),
      );
    });

    test('fails when a provider is duplicated', () {
      final entries = <Sprint118ExpansionConnectorEntry>[
        ...Sprint118ExpansionE2eContract.canonicalRecord.entries,
        _entry(providerId: 'stripe'),
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118ExpansionContractState.fail);
      expect(
        report.violations,
        contains('expansion_contract_provider_duplicate:stripe'),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', auth: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionContractState.fail);
      expect(report.violations, contains('entry_blank_auth:stripe'));
    });

    test('fails when a reference state is not grounded by a witness', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', auth: 'telepathy'),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionContractState.fail);
      expect(
        report.violations,
        contains('reference_state_invalid:auth:stripe'),
      );
    });

    test('records an open item when a requirement has no reference state', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(
              providerId: 'stripe',
              auth: Sprint118ExpansionE2eContract.noReferenceState,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionContractState.pass);
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:auth:stripe'),
      );
    });

    test('fails when the record is not on the delayed path', () {
      final report = _run(_record(releaseState: 'GA_RELEASED'));
      expect(report.state, Sprint118ExpansionContractState.fail);
      expect(
        report.violations,
        contains('expansion_contract_not_on_delayed_path:GA_RELEASED'),
      );
    });

    test('fails when the release state disagrees with the anchor', () {
      final report = _run(
        _record(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118ExpansionContractState.fail);
      expect(
        report.violations.any((v) => v.startsWith('release_state_mismatch:')),
        isTrue,
      );
    });

    test('fails when execution is authorized on the delayed path', () {
      final report = _run(
        _record(),
        anchor: _anchor(executionAuthorized: true),
      );
      expect(report.state, Sprint118ExpansionContractState.fail);
      expect(
        report.violations,
        contains('expansion_contract_execution_authorized_on_delayed_path'),
      );
    });

    test('fails when the release is not blocked on the delayed path', () {
      final report = _run(_record(), anchor: _anchor(releaseBlocked: false));
      expect(report.state, Sprint118ExpansionContractState.fail);
      expect(
        report.violations,
        contains('expansion_contract_release_not_blocked_on_delayed_path'),
      );
    });

    test('fails when a committed evidence source is unreadable', () {
      final report = _run(
        _record(),
        anchor: _anchor(readableSources: const <String>[]),
      );
      expect(report.state, Sprint118ExpansionContractState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('required_source_unreadable:'),
        ),
        isTrue,
      );
    });

    test('the canonical sources cover every requirement', () {
      expect(
        Sprint118ExpansionE2eContract.canonicalSources.length,
        Sprint118ExpansionE2eContract.requiredOutputs.length,
      );
      for (final output in Sprint118ExpansionE2eContract.requiredOutputs) {
        expect(
          Sprint118ExpansionE2eContract.sourceFor(output),
          isNotEmpty,
          reason: '$output must have a committed source',
        );
      }
    });

    test('the loader reads the committed witnesses', () {
      final anchor = const Sprint118ExpansionContractLoader().loadAnchor();
      expect(anchor, isNotNull);
      expect(anchor!.registeredProviders.length, 32);
      expect(anchor.charterVerdict, 'CHARTER_COMPLETE_LOCAL');
      expect(
        anchor.snapshotVerdict,
        'CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL',
      );
      expect(anchor.approvalDecision, 'delay');
      expect(anchor.releaseState, 'GA_DELAYED');
      expect(anchor.registryEvidenceExposed, 0);
      expect(anchor.registryEvidenceWithheld, 32);
      expect(anchor.snapshotLockLockedCount, 32);
      expect(anchor.readableSources.length, 16);
      expect(anchor.manifestVocabulary, contains('connector_version'));
      expect(anchor.authVocabulary, contains('scoped_consent'));
      expect(anchor.capabilityVocabulary, contains('capabilities'));
      expect(anchor.usageVocabulary, contains('usage_units'));
      expect(anchor.errorVocabulary, contains('invalid_credentials'));
      expect(anchor.reauthVocabulary, contains('reauth'));
      expect(anchor.disconnectVocabulary, contains('unlink_confirmation'));
      expect(anchor.cleanupVocabulary, contains('no_plaintext'));
      expect(
        anchor.suiteContractVocabulary,
        containsAll(<String>[
          'manifest',
          'auth',
          'capability',
          'usage',
          'error',
          'reauth',
          'disconnect',
          'cleanup',
          'regression',
        ]),
      );
    });

    test('the gate passes end to end against the committed witnesses', () {
      final report = const Sprint118ExpansionContractGate().evaluate();
      expect(report.state, Sprint118ExpansionContractState.pass);
      expect(report.verdict, 'EXPANSION_CONTRACT_E2E_VERIFIED_LOCAL');
      expect(report.connectedCount, 0);
      expect(report.passedCount, 0);
      expect(report.certifiedCount, 0);
      expect(report.releasedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
    });
  });
}
