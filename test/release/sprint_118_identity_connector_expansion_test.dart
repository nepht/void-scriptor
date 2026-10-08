import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_identity_connector_expansion.dart';

/// A single identity connector expansion entry. Each test flips exactly the one
/// thing it is about, so a test that flips nothing proves the pass path exists
/// and every other test proves one way the gate refuses to take it.
Sprint118IdentityConnectorEntry _entry({
  String providerId = 'openai',
  String selectedProvider =
      Sprint118IdentityConnectorContract.selectedProviderToken,
  String authContract = Sprint118IdentityConnectorContract.authContractToken,
  String minimumScopes = Sprint118IdentityConnectorContract.minimumScopesToken,
  String collisionTests =
      Sprint118IdentityConnectorContract.collisionTestsToken,
  String revoke = Sprint118IdentityConnectorContract.revokeToken,
  String securityReview =
      Sprint118IdentityConnectorContract.securityReviewToken,
  bool certified = false,
  bool selected = false,
  bool connectable = false,
  bool scopesGranted = false,
  bool takeoverProtectionVerified = false,
  bool released = false,
}) {
  return Sprint118IdentityConnectorEntry(
    providerId: providerId,
    selectedProvider: selectedProvider,
    authContract: authContract,
    minimumScopes: minimumScopes,
    collisionTests: collisionTests,
    revoke: revoke,
    securityReview: securityReview,
    certified: certified,
    selected: selected,
    connectable: connectable,
    scopesGranted: scopesGranted,
    takeoverProtectionVerified: takeoverProtectionVerified,
    released: released,
  );
}

Sprint118IdentityConnectorRecord _record({
  String releaseState = Sprint118IdentityConnectorContract.delayedReleaseState,
  List<Sprint118IdentityConnectorEntry>? entries,
}) {
  return Sprint118IdentityConnectorRecord(
    releaseState: releaseState,
    entries:
        entries ?? Sprint118IdentityConnectorContract.canonicalRecord.entries,
  );
}

/// The canonical entries with exactly one provider replaced, so a test can flip
/// a single entry without rebuilding the whole record.
List<Sprint118IdentityConnectorEntry> _replacing(
  String providerId,
  Sprint118IdentityConnectorEntry replacement,
) {
  return <Sprint118IdentityConnectorEntry>[
    for (final e in Sprint118IdentityConnectorContract.canonicalRecord.entries)
      if (e.providerId == providerId) replacement else e,
  ];
}

Sprint118IdentityConnectorAnchor _anchor({
  String charterState = 'pass',
  String charterVerdict =
      Sprint118IdentityConnectorContract.requiredCharterVerdict,
  int charterMaxNewCertified = 0,
  int charterCurrentlyCertified = 0,
  int charterRegisteredProviders =
      Sprint118IdentityConnectorContract.expectedProviderCount,
  String snapshotState = 'pass',
  String snapshotVerdict =
      Sprint118IdentityConnectorContract.requiredSnapshotVerdict,
  int snapshotCertified = 0,
  int snapshotRegistered =
      Sprint118IdentityConnectorContract.expectedProviderCount,
  String releaseState = Sprint118IdentityConnectorContract.delayedReleaseState,
  int registryExpectedCount =
      Sprint118IdentityConnectorContract.expectedProviderCount,
  String approvalDecision =
      Sprint118IdentityConnectorContract.requiredApprovalDecision,
  String approvalState = 'PENDING_CHOIRUDIN',
  bool executionAuthorized = false,
  bool releaseBlocked = true,
  String identityWorkflowStatus =
      Sprint118IdentityConnectorContract.requiredIdentityWorkflowStatus,
  String identityWorkflowVerdict =
      Sprint118IdentityConnectorContract.requiredIdentityWorkflowVerdict,
  List<String>? registeredProviders,
  List<String>? selectedProviderVocabulary,
  List<String>? authContractVocabulary,
  List<String>? minimumScopesVocabulary,
  List<String>? collisionTestsVocabulary,
  List<String>? revokeVocabulary,
  List<String>? securityReviewVocabulary,
  List<String>? readableSources,
}) {
  return Sprint118IdentityConnectorAnchor(
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
    approvalDecision: approvalDecision,
    approvalState: approvalState,
    executionAuthorized: executionAuthorized,
    releaseBlocked: releaseBlocked,
    identityWorkflowStatus: identityWorkflowStatus,
    identityWorkflowVerdict: identityWorkflowVerdict,
    registeredProviders:
        registeredProviders ??
        Sprint118IdentityConnectorContract.canonicalProviders,
    selectedProviderVocabulary:
        selectedProviderVocabulary ??
        const <String>['connect', 'link', 'unlink', 'revoke', 'reauth'],
    authContractVocabulary:
        authContractVocabulary ??
        const <String>[
          'pkce',
          'state_validation',
          'nonce_when_required',
          'scoped_consent',
          'token_rotation',
          'revocation',
        ],
    minimumScopesVocabulary:
        minimumScopesVocabulary ??
        const <String>[
          'pkce',
          'state_validation',
          'nonce_when_required',
          'scoped_consent',
          'token_rotation',
          'revocation',
        ],
    collisionTestsVocabulary:
        collisionTestsVocabulary ??
        const <String>[
          'collision_detection',
          'safe_merge',
          'last_method_protection',
          'takeover_prevention',
          'unlink',
          'recovery',
        ],
    revokeVocabulary:
        revokeVocabulary ??
        const <String>[
          'pkce',
          'state_validation',
          'nonce_when_required',
          'scoped_consent',
          'token_rotation',
          'revocation',
        ],
    securityReviewVocabulary:
        securityReviewVocabulary ??
        const <String>[
          'oauth_tests',
          'vault_tests',
          'redirect_tests',
          'session_tests',
          'permission_tests',
          'webhook_tests',
          'dependency_scan',
          'audit_tests',
        ],
    readableSources:
        readableSources ??
        Sprint118IdentityConnectorContract.witnessSources.toSet().toList(),
  );
}

Sprint118IdentityConnectorReport _run(
  Sprint118IdentityConnectorRecord record, {
  Sprint118IdentityConnectorAnchor? anchor,
}) {
  return const Sprint118IdentityConnectorGate().evaluateWith(
    anchor ?? _anchor(),
    record,
  );
}

void main() {
  group('Sprint 118.33 Identity Connector Expansion', () {
    test('the canonical field vocabulary is the seven objective fields', () {
      expect(Sprint118IdentityConnectorContract.requiredFields, <String>[
        'provider_id',
        'selected_provider',
        'auth_contract',
        'minimum_scopes',
        'collision_tests',
        'revoke',
        'security_review',
      ]);
    });

    test('the canonical outputs are the six objective items', () {
      expect(Sprint118IdentityConnectorContract.requiredOutputs, <String>[
        'selected_provider',
        'auth_contract',
        'minimum_scopes',
        'collision_tests',
        'revoke',
        'security_review',
      ]);
    });

    test(
      'the reference-state vocabulary is derived from committed witnesses',
      () {
        final vocabulary = Sprint118IdentityConnectorContract.stateVocabulary(
          <List<String>>[
            const <String>['connect', 'link'],
            const <String>['pkce', 'scoped_consent'],
          ],
        );
        expect(vocabulary, contains('connect'));
        expect(vocabulary, contains('pkce'));
        expect(vocabulary, contains('scoped_consent'));
        expect(
          vocabulary,
          contains(Sprint118IdentityConnectorContract.noReferenceState),
        );
        expect(
          Sprint118IdentityConnectorContract.grounds(vocabulary, 'connect'),
          isTrue,
        );
        expect(
          Sprint118IdentityConnectorContract.grounds(vocabulary, 'telepathy'),
          isFalse,
        );
      },
    );

    test(
      'canonical record covers all 32 registered providers and claims nothing',
      () {
        final record = Sprint118IdentityConnectorContract.canonicalRecord;
        expect(record.entries.length, 32);
        expect(
          record.providerIds.toSet(),
          Sprint118IdentityConnectorContract.canonicalProviders.toSet(),
        );
        for (final entry in record.entries) {
          expect(entry.certified, isFalse);
          expect(entry.selected, isFalse);
          expect(entry.connectable, isFalse);
          expect(entry.scopesGranted, isFalse);
          expect(entry.takeoverProtectionVerified, isFalse);
          expect(entry.released, isFalse);
          for (final field
              in Sprint118IdentityConnectorContract.requiredFields) {
            expect(
              (entry.requiredFields[field] ?? '').trim(),
              isNotEmpty,
              reason: '${entry.providerId}.$field must not be blank',
            );
          }
        }
      },
    );

    test('passes on the canonical record and claims no live certification', () {
      final report = _run(_record());
      expect(report.state, Sprint118IdentityConnectorState.pass);
      expect(report.verdict, 'IDENTITY_CONNECTOR_EXPANSION_VERIFIED_LOCAL');
      expect(report.certificationVerified, isTrue);
      expect(report.declaredProviders.length, 32);
      expect(report.certifiedProviders, isEmpty);
      expect(report.selectedProviders, isEmpty);
      expect(report.expansionBudgetFrozen, isTrue);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      expect(report.openItems, isEmpty);
      expect(report.externalGates, 'DEFERRED-EXTERNAL');
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118IdentityConnectorGate().evaluateWith(
        null,
        _record(),
      );
      expect(report.state, Sprint118IdentityConnectorState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_IDENTITY_CONNECTOR_EXPANSION_EVIDENCE_UNREADABLE',
      );
      expect(report.certificationVerified, isFalse);
      expect(
        report.blockers,
        contains('committed_identity_connector_evidence_unreadable'),
      );
    });

    test('blocks when the committed charter is not complete', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterVerdict: 'CHARTER_INCOMPLETE_LOCAL'),
      );
      expect(report.state, Sprint118IdentityConnectorState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_IDENTITY_CONNECTOR_EXPANSION_BLOCKED_UPSTREAM',
      );
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
      expect(report.state, Sprint118IdentityConnectorState.blocked);
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
      expect(report.state, Sprint118IdentityConnectorState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('approval_gate_not_delay:')),
        isTrue,
      );
    });

    test('blocks when the committed identity workflow is not validated', () {
      final report = _run(
        _record(),
        anchor: _anchor(identityWorkflowVerdict: 'IDENTITY_WORKFLOW_DRIFT'),
      );
      expect(report.state, Sprint118IdentityConnectorState.blocked);
      expect(
        report.blockers.any(
          (b) => b.startsWith('identity_workflow_not_validated:'),
        ),
        isTrue,
      );
    });

    test('blocks when the registered provider set does not reconcile', () {
      final report = _run(
        _record(),
        anchor: _anchor(registryExpectedCount: 31),
      );
      expect(report.state, Sprint118IdentityConnectorState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('registry_not_reconciled:')),
        isTrue,
      );
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
      expect(report.state, Sprint118IdentityConnectorState.fail);
      expect(
        report.violations,
        contains('identity_connector_certified_claimed_on_delayed_path:openai'),
      );
      expect(report.certifiedCount, 1);
    });

    test('fails when a provider claims it was selected', () {
      final report = _run(
        _record(
          entries: _replacing(
            'google',
            _entry(providerId: 'google', selected: true),
          ),
        ),
      );
      expect(report.state, Sprint118IdentityConnectorState.fail);
      expect(
        report.violations,
        contains('identity_connector_selected_claimed_on_delayed_path:google'),
      );
      expect(report.selectedCount, 1);
    });

    test('fails when a connector claims it is connectable', () {
      final report = _run(
        _record(
          entries: _replacing(
            'apple',
            _entry(providerId: 'apple', connectable: true),
          ),
        ),
      );
      expect(report.state, Sprint118IdentityConnectorState.fail);
      expect(
        report.violations,
        contains(
          'identity_connector_connectable_claimed_on_delayed_path:apple',
        ),
      );
    });

    test('fails when a minimum scope is claimed granted', () {
      final report = _run(
        _record(
          entries: _replacing(
            'github',
            _entry(providerId: 'github', scopesGranted: true),
          ),
        ),
      );
      expect(report.state, Sprint118IdentityConnectorState.fail);
      expect(
        report.violations,
        contains('identity_connector_scopes_granted_on_delayed_path:github'),
      );
    });

    test('fails when takeover protection is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'microsoft',
            _entry(providerId: 'microsoft', takeoverProtectionVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118IdentityConnectorState.fail);
      expect(
        report.violations,
        contains(
          'identity_connector_takeover_protection_verified_on_delayed_path:microsoft',
        ),
      );
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
      expect(report.state, Sprint118IdentityConnectorState.fail);
      expect(
        report.violations,
        contains('identity_connector_provider_released_claimed:stripe'),
      );
    });

    test('fails when the expansion budget is not frozen', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterMaxNewCertified: 1),
      );
      expect(report.state, Sprint118IdentityConnectorState.fail);
      expect(
        report.violations.any(
          (v) =>
              v.startsWith('identity_connector_expansion_budget_not_frozen:'),
        ),
        isTrue,
      );
      expect(report.expansionBudgetFrozen, isFalse);
    });

    test('fails when a registered provider is missing', () {
      final entries = <Sprint118IdentityConnectorEntry>[
        for (final e
            in Sprint118IdentityConnectorContract.canonicalRecord.entries)
          if (e.providerId != 'kofi') e,
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118IdentityConnectorState.fail);
      expect(
        report.violations,
        contains('identity_connector_provider_missing:kofi'),
      );
    });

    test('fails when an unknown provider is invented', () {
      final entries = <Sprint118IdentityConnectorEntry>[
        ...Sprint118IdentityConnectorContract.canonicalRecord.entries,
        _entry(providerId: 'telepathy'),
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118IdentityConnectorState.fail);
      expect(
        report.violations,
        contains('identity_connector_provider_unknown:telepathy'),
      );
    });

    test('fails when a provider is duplicated', () {
      final entries = <Sprint118IdentityConnectorEntry>[
        ...Sprint118IdentityConnectorContract.canonicalRecord.entries,
        _entry(providerId: 'openai'),
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118IdentityConnectorState.fail);
      expect(
        report.violations,
        contains('identity_connector_provider_duplicate:openai'),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', authContract: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118IdentityConnectorState.fail);
      expect(report.violations, contains('entry_blank_auth_contract:openai'));
    });

    test('fails when a reference state is not grounded by a witness', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', collisionTests: 'telepathy'),
          ),
        ),
      );
      expect(report.state, Sprint118IdentityConnectorState.fail);
      expect(
        report.violations,
        contains('reference_state_invalid:collision_tests:openai'),
      );
    });

    test('records an open item when a requirement has no reference state', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(
              providerId: 'openai',
              revoke: Sprint118IdentityConnectorContract.noReferenceState,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118IdentityConnectorState.pass);
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:revoke:openai'),
      );
    });

    test('fails when the record is not on the delayed path', () {
      final report = _run(_record(releaseState: 'GA_RELEASED'));
      expect(report.state, Sprint118IdentityConnectorState.fail);
      expect(
        report.violations,
        contains('identity_connector_not_on_delayed_path:GA_RELEASED'),
      );
    });

    test('fails when the release state disagrees with the anchor', () {
      final report = _run(
        _record(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118IdentityConnectorState.fail);
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
      expect(report.state, Sprint118IdentityConnectorState.fail);
      expect(
        report.violations,
        contains('identity_connector_execution_authorized_on_delayed_path'),
      );
    });

    test('fails when the release is not blocked on the delayed path', () {
      final report = _run(_record(), anchor: _anchor(releaseBlocked: false));
      expect(report.state, Sprint118IdentityConnectorState.fail);
      expect(
        report.violations,
        contains('identity_connector_release_not_blocked_on_delayed_path'),
      );
    });

    test('fails when a committed evidence source is unreadable', () {
      final report = _run(
        _record(),
        anchor: _anchor(readableSources: const <String>[]),
      );
      expect(report.state, Sprint118IdentityConnectorState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('required_source_unreadable:'),
        ),
        isTrue,
      );
    });

    test('the canonical sources cover every requirement', () {
      expect(
        Sprint118IdentityConnectorContract.canonicalSources.length,
        Sprint118IdentityConnectorContract.requiredOutputs.length,
      );
      for (final output in Sprint118IdentityConnectorContract.requiredOutputs) {
        expect(
          Sprint118IdentityConnectorContract.sourceFor(output),
          isNotEmpty,
          reason: '$output must have a committed source',
        );
      }
    });

    test('the loader reads the committed witnesses', () {
      final anchor = const Sprint118IdentityConnectorLoader().loadAnchor();
      expect(anchor, isNotNull);
      expect(anchor!.registeredProviders.length, 32);
      expect(anchor.charterVerdict, 'CHARTER_COMPLETE_LOCAL');
      expect(
        anchor.snapshotVerdict,
        'CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL',
      );
      expect(anchor.approvalDecision, 'delay');
      expect(
        anchor.identityWorkflowVerdict,
        'IDENTITY_WORKFLOW_VALIDATED_LOCAL',
      );
      expect(anchor.readableSources.length, 9);
      expect(anchor.selectedProviderVocabulary, contains('connect'));
      expect(anchor.authContractVocabulary, contains('pkce'));
      expect(anchor.minimumScopesVocabulary, contains('scoped_consent'));
      expect(anchor.collisionTestsVocabulary, contains('takeover_prevention'));
      expect(anchor.revokeVocabulary, contains('revocation'));
      expect(anchor.securityReviewVocabulary, contains('oauth_tests'));
    });

    test('the gate passes end to end against the committed witnesses', () {
      final report = const Sprint118IdentityConnectorGate().evaluate();
      expect(report.state, Sprint118IdentityConnectorState.pass);
      expect(report.verdict, 'IDENTITY_CONNECTOR_EXPANSION_VERIFIED_LOCAL');
      expect(report.certifiedCount, 0);
      expect(report.selectedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
    });
  });
}
