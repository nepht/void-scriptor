import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_developer_connector_expansion.dart';

/// A single developer connector expansion entry. Each test flips exactly the one
/// thing it is about, so a test that flips nothing proves the pass path exists
/// and every other test proves one way the gate refuses to take it.
Sprint118DeveloperConnectorEntry _entry({
  String providerId = 'github',
  String selectedProvider =
      Sprint118DeveloperConnectorContract.selectedProviderToken,
  String scopes = Sprint118DeveloperConnectorContract.scopesToken,
  String resources = Sprint118DeveloperConnectorContract.resourcesToken,
  String rateLimits = Sprint118DeveloperConnectorContract.rateLimitsToken,
  String organizationPolicy =
      Sprint118DeveloperConnectorContract.organizationPolicyToken,
  String revoke = Sprint118DeveloperConnectorContract.revokeToken,
  String audit = Sprint118DeveloperConnectorContract.auditToken,
  bool certified = false,
  bool selected = false,
  bool scopesGranted = false,
  bool resourcesVerified = false,
  bool rateLimitsVerified = false,
  bool organizationPolicyVerified = false,
  bool revokeVerified = false,
  bool auditVerified = false,
  bool released = false,
}) {
  return Sprint118DeveloperConnectorEntry(
    providerId: providerId,
    selectedProvider: selectedProvider,
    scopes: scopes,
    resources: resources,
    rateLimits: rateLimits,
    organizationPolicy: organizationPolicy,
    revoke: revoke,
    audit: audit,
    certified: certified,
    selected: selected,
    scopesGranted: scopesGranted,
    resourcesVerified: resourcesVerified,
    rateLimitsVerified: rateLimitsVerified,
    organizationPolicyVerified: organizationPolicyVerified,
    revokeVerified: revokeVerified,
    auditVerified: auditVerified,
    released: released,
  );
}

Sprint118DeveloperConnectorRecord _record({
  String releaseState = Sprint118DeveloperConnectorContract.delayedReleaseState,
  List<Sprint118DeveloperConnectorEntry>? entries,
}) {
  return Sprint118DeveloperConnectorRecord(
    releaseState: releaseState,
    entries:
        entries ?? Sprint118DeveloperConnectorContract.canonicalRecord.entries,
  );
}

/// The canonical entries with exactly one provider replaced, so a test can flip
/// a single entry without rebuilding the whole record.
List<Sprint118DeveloperConnectorEntry> _replacing(
  String providerId,
  Sprint118DeveloperConnectorEntry replacement,
) {
  return <Sprint118DeveloperConnectorEntry>[
    for (final e in Sprint118DeveloperConnectorContract.canonicalRecord.entries)
      if (e.providerId == providerId) replacement else e,
  ];
}

Sprint118DeveloperConnectorAnchor _anchor({
  String charterState = 'pass',
  String charterVerdict =
      Sprint118DeveloperConnectorContract.requiredCharterVerdict,
  int charterMaxNewCertified = 0,
  int charterCurrentlyCertified = 0,
  int charterRegisteredProviders =
      Sprint118DeveloperConnectorContract.expectedProviderCount,
  String snapshotState = 'pass',
  String snapshotVerdict =
      Sprint118DeveloperConnectorContract.requiredSnapshotVerdict,
  int snapshotCertified = 0,
  int snapshotRegistered =
      Sprint118DeveloperConnectorContract.expectedProviderCount,
  String releaseState = Sprint118DeveloperConnectorContract.delayedReleaseState,
  int registryExpectedCount =
      Sprint118DeveloperConnectorContract.expectedProviderCount,
  String approvalDecision =
      Sprint118DeveloperConnectorContract.requiredApprovalDecision,
  String approvalState = 'PENDING_CHOIRUDIN',
  bool executionAuthorized = false,
  bool releaseBlocked = true,
  String developerWorkflowStatus =
      Sprint118DeveloperConnectorContract.requiredDeveloperWorkflowStatus,
  String developerWorkflowVerdict =
      Sprint118DeveloperConnectorContract.requiredDeveloperWorkflowVerdict,
  List<String>? registeredProviders,
  List<String>? selectedProviderVocabulary,
  List<String>? scopesVocabulary,
  List<String>? resourcesVocabulary,
  List<String>? rateLimitsVocabulary,
  List<String>? organizationPolicyVocabulary,
  List<String>? revokeVocabulary,
  List<String>? auditVocabulary,
  List<String>? readableSources,
}) {
  return Sprint118DeveloperConnectorAnchor(
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
    developerWorkflowStatus: developerWorkflowStatus,
    developerWorkflowVerdict: developerWorkflowVerdict,
    registeredProviders:
        registeredProviders ??
        Sprint118DeveloperConnectorContract.canonicalProviders,
    selectedProviderVocabulary:
        selectedProviderVocabulary ??
        const <String>[
          'manifest_driven',
          'scopes',
          'repository_access',
          'disconnect',
          'unavailable_state',
          'audit',
        ],
    scopesVocabulary:
        scopesVocabulary ??
        const <String>[
          'manifest_driven',
          'scopes',
          'repository_access',
          'disconnect',
          'unavailable_state',
          'audit',
        ],
    resourcesVocabulary:
        resourcesVocabulary ??
        const <String>[
          'audit',
          'rate_limits',
          'reauth',
          'resource_access',
          'revoke',
          'scopes',
        ],
    rateLimitsVocabulary:
        rateLimitsVocabulary ??
        const <String>[
          'provider_id',
          'organizations',
          'projects',
          'repository_scopes',
          'token_lifecycle',
          'rate_limits',
          'audit',
        ],
    organizationPolicyVocabulary:
        organizationPolicyVocabulary ??
        const <String>[
          'provider_id',
          'repository_scopes',
          'identity_scopes_separation',
          'organization_policy',
          'rate_limits',
          'revoke',
          'audit',
        ],
    revokeVocabulary:
        revokeVocabulary ??
        const <String>[
          'provider_id',
          'deployment_types',
          'repository_scopes',
          'rate_limits',
          'revoke',
          'audit',
        ],
    auditVocabulary:
        auditVocabulary ??
        const <String>[
          'provider_id',
          'repository_scopes',
          'workspaces',
          'rate_limits',
          'revoke',
          'audit',
        ],
    readableSources:
        readableSources ??
        Sprint118DeveloperConnectorContract.witnessSources.toSet().toList(),
  );
}

Sprint118DeveloperConnectorReport _run(
  Sprint118DeveloperConnectorRecord record, {
  Sprint118DeveloperConnectorAnchor? anchor,
}) {
  return const Sprint118DeveloperConnectorGate().evaluateWith(
    anchor ?? _anchor(),
    record,
  );
}

void main() {
  group('Sprint 118.36 Developer Connector Expansion', () {
    test('the canonical field vocabulary is the eight objective fields', () {
      expect(Sprint118DeveloperConnectorContract.requiredFields, <String>[
        'provider_id',
        'selected_provider',
        'scopes',
        'resources',
        'rate_limits',
        'organization_policy',
        'revoke',
        'audit',
      ]);
    });

    test('the canonical outputs are the seven objective items', () {
      expect(Sprint118DeveloperConnectorContract.requiredOutputs, <String>[
        'selected_provider',
        'scopes',
        'resources',
        'rate_limits',
        'organization_policy',
        'revoke',
        'audit',
      ]);
    });

    test(
      'the reference-state vocabulary is derived from committed witnesses',
      () {
        final vocabulary = Sprint118DeveloperConnectorContract.stateVocabulary(
          <List<String>>[
            const <String>['manifest_driven', 'resource_access'],
            const <String>['rate_limits', 'revoke'],
          ],
        );
        expect(vocabulary, contains('manifest_driven'));
        expect(vocabulary, contains('resource_access'));
        expect(vocabulary, contains('rate_limits'));
        expect(vocabulary, contains('revoke'));
        expect(
          vocabulary,
          contains(Sprint118DeveloperConnectorContract.noReferenceState),
        );
        expect(
          Sprint118DeveloperConnectorContract.grounds(
            vocabulary,
            'resource_access',
          ),
          isTrue,
        );
        expect(
          Sprint118DeveloperConnectorContract.grounds(vocabulary, 'telepathy'),
          isFalse,
        );
      },
    );

    test(
      'canonical record covers all 32 registered providers and claims nothing',
      () {
        final record = Sprint118DeveloperConnectorContract.canonicalRecord;
        expect(record.entries.length, 32);
        expect(
          record.providerIds.toSet(),
          Sprint118DeveloperConnectorContract.canonicalProviders.toSet(),
        );
        for (final entry in record.entries) {
          expect(entry.certified, isFalse);
          expect(entry.selected, isFalse);
          expect(entry.scopesGranted, isFalse);
          expect(entry.resourcesVerified, isFalse);
          expect(entry.rateLimitsVerified, isFalse);
          expect(entry.organizationPolicyVerified, isFalse);
          expect(entry.revokeVerified, isFalse);
          expect(entry.auditVerified, isFalse);
          expect(entry.released, isFalse);
          for (final field
              in Sprint118DeveloperConnectorContract.requiredFields) {
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
      expect(report.state, Sprint118DeveloperConnectorState.pass);
      expect(report.verdict, 'DEVELOPER_CONNECTOR_EXPANSION_VERIFIED_LOCAL');
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
      final report = const Sprint118DeveloperConnectorGate().evaluateWith(
        null,
        _record(),
      );
      expect(report.state, Sprint118DeveloperConnectorState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_DEVELOPER_CONNECTOR_EXPANSION_EVIDENCE_UNREADABLE',
      );
      expect(report.certificationVerified, isFalse);
      expect(
        report.blockers,
        contains('committed_developer_connector_evidence_unreadable'),
      );
    });

    test('blocks when the committed charter is not complete', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterVerdict: 'CHARTER_INCOMPLETE_LOCAL'),
      );
      expect(report.state, Sprint118DeveloperConnectorState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_DEVELOPER_CONNECTOR_EXPANSION_BLOCKED_UPSTREAM',
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
      expect(report.state, Sprint118DeveloperConnectorState.blocked);
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
      expect(report.state, Sprint118DeveloperConnectorState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('approval_gate_not_delay:')),
        isTrue,
      );
    });

    test('blocks when the committed developer workflow is not a pass', () {
      final report = _run(
        _record(),
        anchor: _anchor(
          developerWorkflowVerdict: 'DEVELOPER_CONNECTOR_WORKFLOW_DRIFT',
        ),
      );
      expect(report.state, Sprint118DeveloperConnectorState.blocked);
      expect(
        report.blockers.any(
          (b) => b.startsWith('developer_workflow_not_validated:'),
        ),
        isTrue,
      );
    });

    test('blocks when the registered provider set does not reconcile', () {
      final report = _run(
        _record(),
        anchor: _anchor(registryExpectedCount: 31),
      );
      expect(report.state, Sprint118DeveloperConnectorState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('registry_not_reconciled:')),
        isTrue,
      );
    });

    test('fails when a provider claims a certified connector', () {
      final report = _run(
        _record(
          entries: _replacing(
            'github',
            _entry(providerId: 'github', certified: true),
          ),
        ),
      );
      expect(report.state, Sprint118DeveloperConnectorState.fail);
      expect(
        report.violations,
        contains(
          'developer_connector_certified_claimed_on_delayed_path:github',
        ),
      );
      expect(report.certifiedCount, 1);
    });

    test('fails when a provider claims it was selected', () {
      final report = _run(
        _record(
          entries: _replacing(
            'gitlab',
            _entry(providerId: 'gitlab', selected: true),
          ),
        ),
      );
      expect(report.state, Sprint118DeveloperConnectorState.fail);
      expect(
        report.violations,
        contains('developer_connector_selected_claimed_on_delayed_path:gitlab'),
      );
      expect(report.selectedCount, 1);
    });

    test('fails when a scope is claimed granted', () {
      final report = _run(
        _record(
          entries: _replacing(
            'bitbucket',
            _entry(providerId: 'bitbucket', scopesGranted: true),
          ),
        ),
      );
      expect(report.state, Sprint118DeveloperConnectorState.fail);
      expect(
        report.violations,
        contains(
          'developer_connector_scopes_granted_on_delayed_path:bitbucket',
        ),
      );
    });

    test('fails when a resource access is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'azure_devops',
            _entry(providerId: 'azure_devops', resourcesVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118DeveloperConnectorState.fail);
      expect(
        report.violations,
        contains(
          'developer_connector_resources_verified_on_delayed_path:azure_devops',
        ),
      );
    });

    test('fails when a rate limit is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', rateLimitsVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118DeveloperConnectorState.fail);
      expect(
        report.violations,
        contains(
          'developer_connector_rate_limits_verified_on_delayed_path:openai',
        ),
      );
    });

    test('fails when an organization policy is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'google',
            _entry(providerId: 'google', organizationPolicyVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118DeveloperConnectorState.fail);
      expect(
        report.violations,
        contains(
          'developer_connector_organization_policy_verified_on_delayed_path:google',
        ),
      );
    });

    test('fails when a revoke is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'stripe',
            _entry(providerId: 'stripe', revokeVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118DeveloperConnectorState.fail);
      expect(
        report.violations,
        contains('developer_connector_revoke_verified_on_delayed_path:stripe'),
      );
    });

    test('fails when an audit is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'microsoft',
            _entry(providerId: 'microsoft', auditVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118DeveloperConnectorState.fail);
      expect(
        report.violations,
        contains(
          'developer_connector_audit_verified_on_delayed_path:microsoft',
        ),
      );
    });

    test('fails when a provider is claimed released', () {
      final report = _run(
        _record(
          entries: _replacing(
            'kofi',
            _entry(providerId: 'kofi', released: true),
          ),
        ),
      );
      expect(report.state, Sprint118DeveloperConnectorState.fail);
      expect(
        report.violations,
        contains('developer_connector_provider_released_claimed:kofi'),
      );
    });

    test('fails when the expansion budget is not frozen', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterMaxNewCertified: 1),
      );
      expect(report.state, Sprint118DeveloperConnectorState.fail);
      expect(
        report.violations.any(
          (v) =>
              v.startsWith('developer_connector_expansion_budget_not_frozen:'),
        ),
        isTrue,
      );
      expect(report.expansionBudgetFrozen, isFalse);
    });

    test('fails when a registered provider is missing', () {
      final entries = <Sprint118DeveloperConnectorEntry>[
        for (final e
            in Sprint118DeveloperConnectorContract.canonicalRecord.entries)
          if (e.providerId != 'kofi') e,
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118DeveloperConnectorState.fail);
      expect(
        report.violations,
        contains('developer_connector_provider_missing:kofi'),
      );
    });

    test('fails when an unknown provider is invented', () {
      final entries = <Sprint118DeveloperConnectorEntry>[
        ...Sprint118DeveloperConnectorContract.canonicalRecord.entries,
        _entry(providerId: 'telepathy'),
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118DeveloperConnectorState.fail);
      expect(
        report.violations,
        contains('developer_connector_provider_unknown:telepathy'),
      );
    });

    test('fails when a provider is duplicated', () {
      final entries = <Sprint118DeveloperConnectorEntry>[
        ...Sprint118DeveloperConnectorContract.canonicalRecord.entries,
        _entry(providerId: 'github'),
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118DeveloperConnectorState.fail);
      expect(
        report.violations,
        contains('developer_connector_provider_duplicate:github'),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _record(
          entries: _replacing(
            'github',
            _entry(providerId: 'github', resources: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118DeveloperConnectorState.fail);
      expect(report.violations, contains('entry_blank_resources:github'));
    });

    test('fails when a reference state is not grounded by a witness', () {
      final report = _run(
        _record(
          entries: _replacing(
            'github',
            _entry(providerId: 'github', resources: 'telepathy'),
          ),
        ),
      );
      expect(report.state, Sprint118DeveloperConnectorState.fail);
      expect(
        report.violations,
        contains('reference_state_invalid:resources:github'),
      );
    });

    test('records an open item when a requirement has no reference state', () {
      final report = _run(
        _record(
          entries: _replacing(
            'github',
            _entry(
              providerId: 'github',
              resources: Sprint118DeveloperConnectorContract.noReferenceState,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118DeveloperConnectorState.pass);
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:resources:github'),
      );
    });

    test('fails when the record is not on the delayed path', () {
      final report = _run(_record(releaseState: 'GA_RELEASED'));
      expect(report.state, Sprint118DeveloperConnectorState.fail);
      expect(
        report.violations,
        contains('developer_connector_not_on_delayed_path:GA_RELEASED'),
      );
    });

    test('fails when the release state disagrees with the anchor', () {
      final report = _run(
        _record(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118DeveloperConnectorState.fail);
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
      expect(report.state, Sprint118DeveloperConnectorState.fail);
      expect(
        report.violations,
        contains('developer_connector_execution_authorized_on_delayed_path'),
      );
    });

    test('fails when the release is not blocked on the delayed path', () {
      final report = _run(_record(), anchor: _anchor(releaseBlocked: false));
      expect(report.state, Sprint118DeveloperConnectorState.fail);
      expect(
        report.violations,
        contains('developer_connector_release_not_blocked_on_delayed_path'),
      );
    });

    test('fails when a committed evidence source is unreadable', () {
      final report = _run(
        _record(),
        anchor: _anchor(readableSources: const <String>[]),
      );
      expect(report.state, Sprint118DeveloperConnectorState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('required_source_unreadable:'),
        ),
        isTrue,
      );
    });

    test('the canonical sources cover every requirement', () {
      expect(
        Sprint118DeveloperConnectorContract.canonicalSources.length,
        Sprint118DeveloperConnectorContract.requiredOutputs.length,
      );
      for (final output
          in Sprint118DeveloperConnectorContract.requiredOutputs) {
        expect(
          Sprint118DeveloperConnectorContract.sourceFor(output),
          isNotEmpty,
          reason: '$output must have a committed source',
        );
      }
    });

    test('the loader reads the committed witnesses', () {
      final anchor = const Sprint118DeveloperConnectorLoader().loadAnchor();
      expect(anchor, isNotNull);
      expect(anchor!.registeredProviders.length, 32);
      expect(anchor.charterVerdict, 'CHARTER_COMPLETE_LOCAL');
      expect(
        anchor.snapshotVerdict,
        'CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL',
      );
      expect(anchor.approvalDecision, 'delay');
      expect(
        anchor.developerWorkflowVerdict,
        'DEVELOPER_CONNECTOR_WORKFLOW_VALIDATED_LOCAL',
      );
      expect(anchor.readableSources.length, 11);
      expect(anchor.selectedProviderVocabulary, contains('manifest_driven'));
      expect(anchor.scopesVocabulary, contains('scopes'));
      expect(anchor.resourcesVocabulary, contains('resource_access'));
      expect(anchor.rateLimitsVocabulary, contains('rate_limits'));
      expect(
        anchor.organizationPolicyVocabulary,
        contains('organization_policy'),
      );
      expect(anchor.revokeVocabulary, contains('revoke'));
      expect(anchor.auditVocabulary, contains('audit'));
    });

    test('the gate passes end to end against the committed witnesses', () {
      final report = const Sprint118DeveloperConnectorGate().evaluate();
      expect(report.state, Sprint118DeveloperConnectorState.pass);
      expect(report.verdict, 'DEVELOPER_CONNECTOR_EXPANSION_VERIFIED_LOCAL');
      expect(report.certifiedCount, 0);
      expect(report.selectedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
    });
  });
}
