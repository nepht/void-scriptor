import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_provider_expansion_evidence_inventory.dart';

/// A single expansion-evidence entry. Each test flips exactly the one thing it
/// is about, so a test that flips nothing proves the pass path exists and every
/// other test proves one way the gate refuses to take it.
Sprint118ExpansionEvidenceEntry _entry({
  String providerId = 'openai',
  String demandEvidence =
      Sprint118ExpansionEvidenceContract.demandEvidenceToken,
  String workflowValue = 'writer',
  String apiFeasibility =
      Sprint118ExpansionEvidenceContract.apiFeasibilityToken,
  String maintenanceCost =
      Sprint118ExpansionEvidenceContract.maintenanceCostToken,
  String security = Sprint118ExpansionEvidenceContract.securityToken,
  String privacy = Sprint118ExpansionEvidenceContract.privacyToken,
  String regionConstraints =
      Sprint118ExpansionEvidenceContract.regionConstraintsToken,
  bool certified = false,
  bool available = false,
  bool demanded = false,
  bool observed = false,
  bool released = false,
}) {
  return Sprint118ExpansionEvidenceEntry(
    providerId: providerId,
    demandEvidence: demandEvidence,
    workflowValue: workflowValue,
    apiFeasibility: apiFeasibility,
    maintenanceCost: maintenanceCost,
    security: security,
    privacy: privacy,
    regionConstraints: regionConstraints,
    certified: certified,
    available: available,
    demanded: demanded,
    observed: observed,
    released: released,
  );
}

Sprint118ExpansionEvidenceRecord _record({
  String releaseState = Sprint118ExpansionEvidenceContract.delayedReleaseState,
  List<Sprint118ExpansionEvidenceEntry>? entries,
}) {
  return Sprint118ExpansionEvidenceRecord(
    releaseState: releaseState,
    entries:
        entries ?? Sprint118ExpansionEvidenceContract.canonicalRecord.entries,
  );
}

/// The canonical entries with exactly one provider replaced, so a test can flip
/// a single entry without rebuilding the whole record.
List<Sprint118ExpansionEvidenceEntry> _replacing(
  String providerId,
  Sprint118ExpansionEvidenceEntry replacement,
) {
  return <Sprint118ExpansionEvidenceEntry>[
    for (final e in Sprint118ExpansionEvidenceContract.canonicalRecord.entries)
      if (e.providerId == providerId) replacement else e,
  ];
}

Sprint118ExpansionEvidenceAnchor _anchor({
  String charterState = 'pass',
  String charterVerdict =
      Sprint118ExpansionEvidenceContract.requiredCharterVerdict,
  int charterMaxNewCertified = 0,
  int charterCurrentlyCertified = 0,
  int charterRegisteredProviders =
      Sprint118ExpansionEvidenceContract.expectedProviderCount,
  String snapshotState = 'pass',
  String snapshotVerdict =
      Sprint118ExpansionEvidenceContract.requiredSnapshotVerdict,
  int snapshotCertified = 0,
  int snapshotRegistered =
      Sprint118ExpansionEvidenceContract.expectedProviderCount,
  String releaseState = Sprint118ExpansionEvidenceContract.delayedReleaseState,
  int registryExpectedCount =
      Sprint118ExpansionEvidenceContract.expectedProviderCount,
  String approvalDecision =
      Sprint118ExpansionEvidenceContract.requiredApprovalDecision,
  String approvalState = 'PENDING_CHOIRUDIN',
  bool executionAuthorized = false,
  bool releaseBlocked = true,
  List<String>? registeredProviders,
  List<String>? demandOutcomes,
  List<String>? workflows,
  List<String>? dependencySignals,
  List<String>? costAcceptance,
  List<String>? securityOutputs,
  List<String>? privacySubjects,
  List<String>? feasibilityStates,
  List<String>? readableSources,
}) {
  return Sprint118ExpansionEvidenceAnchor(
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
    registeredProviders:
        registeredProviders ??
        Sprint118ExpansionEvidenceContract.canonicalProviders,
    demandOutcomes:
        demandOutcomes ??
        const <String>[
          'completion',
          'failure',
          'recovery',
          'abandonment',
          'workaround',
          'repeat_use',
          'limitations',
          'no_live_outcome',
        ],
    workflows:
        workflows ??
        const <String>['writer', 'lore', 'simulation', 'sharing', 'publishing'],
    dependencySignals:
        dependencySignals ??
        const <String>[
          'provider_availability',
          'timeout',
          'throttling',
          'auth_expiry',
          'cost_visibility',
          'fallback_success',
          'consent_failure',
        ],
    costAcceptance:
        costAcceptance ??
        const <String>[
          'raw_bytes',
          'provider_timestamp',
          'unit_metadata',
          'quota_unavailable',
          'stale_state',
          'refresh',
        ],
    securityOutputs:
        securityOutputs ??
        const <String>[
          'oauth_tests',
          'vault_tests',
          'key_tests',
          'session_tests',
          'permission_tests',
          'webhook_tests',
          'entitlement_tests',
          'audit_tests',
        ],
    privacySubjects:
        privacySubjects ??
        const <String>[
          'account_metadata',
          'tokens',
          'usage',
          'storage',
          'billing',
          'diagnostics',
          'retention',
          'external_transfers',
        ],
    feasibilityStates:
        feasibilityStates ??
        const <String>[
          'invalid_credentials',
          'expired',
          'revoked',
          'scope_denied',
          'rate_limited',
          'outage',
          'unsupported_region',
          'unsupported_plan',
        ],
    readableSources:
        readableSources ??
        Sprint118ExpansionEvidenceContract.witnessSources.toSet().toList(),
  );
}

Sprint118ExpansionEvidenceReport _run(
  Sprint118ExpansionEvidenceRecord record, {
  Sprint118ExpansionEvidenceAnchor? anchor,
}) {
  return const Sprint118ExpansionEvidenceGate().evaluateWith(
    anchor ?? _anchor(),
    record,
  );
}

void main() {
  group('Sprint 118.29 Provider Expansion Evidence Inventory', () {
    test('the canonical field vocabulary is the eight objective fields', () {
      expect(Sprint118ExpansionEvidenceContract.requiredFields, <String>[
        'provider_id',
        'demand_evidence',
        'workflow_value',
        'api_feasibility',
        'maintenance_cost',
        'security',
        'privacy',
        'region_constraints',
      ]);
    });

    test('the canonical evidence dimensions are the seven objective items', () {
      expect(Sprint118ExpansionEvidenceContract.requiredDimensions, <String>[
        'demand_evidence',
        'workflow_value',
        'api_feasibility',
        'maintenance_cost',
        'security',
        'privacy',
        'region_constraints',
      ]);
    });

    test(
      'the reference-state vocabulary is derived from committed witnesses',
      () {
        final vocabulary = Sprint118ExpansionEvidenceContract.stateVocabulary(
          <List<String>>[
            const <String>['no_live_outcome', 'completion'],
            const <String>['unsupported_region'],
          ],
        );
        expect(vocabulary, contains('no_live_outcome'));
        expect(vocabulary, contains('completion'));
        expect(vocabulary, contains('unsupported_region'));
        expect(
          vocabulary,
          contains(Sprint118ExpansionEvidenceContract.noReferenceState),
        );
        // A token only grounds when the witness names it exactly, or when every
        // underscore-separated part is itself a witness-declared value.
        expect(
          Sprint118ExpansionEvidenceContract.grounds(
            vocabulary,
            'no_live_outcome',
          ),
          isTrue,
        );
        expect(
          Sprint118ExpansionEvidenceContract.grounds(vocabulary, 'telepathy'),
          isFalse,
        );
        expect(
          Sprint118ExpansionEvidenceContract.grounds(const <String>[
            'unsupported',
            'region',
          ], 'unsupported_region'),
          isTrue,
        );
        expect(
          Sprint118ExpansionEvidenceContract.grounds(const <String>[
            'unsupported',
          ], 'unsupported_region'),
          isFalse,
        );
      },
    );

    test(
      'canonical record covers all 32 registered providers and claims nothing '
      'live',
      () {
        final record = Sprint118ExpansionEvidenceContract.canonicalRecord;
        expect(record.entries.length, 32);
        expect(
          record.providerIds.toSet(),
          Sprint118ExpansionEvidenceContract.canonicalProviders.toSet(),
        );
        for (final entry in record.entries) {
          expect(entry.certified, isFalse);
          expect(entry.available, isFalse);
          expect(entry.demanded, isFalse);
          expect(entry.observed, isFalse);
          expect(entry.released, isFalse);
          for (final field
              in Sprint118ExpansionEvidenceContract.requiredFields) {
            expect(
              (entry.requiredFields[field] ?? '').trim(),
              isNotEmpty,
              reason: '${entry.providerId}.$field must not be blank',
            );
          }
        }
      },
    );

    test(
      'passes on the canonical record and selects no expansion candidate',
      () {
        final report = _run(_record());
        expect(report.state, Sprint118ExpansionEvidenceState.pass);
        expect(
          report.verdict,
          'PROVIDER_EXPANSION_EVIDENCE_INVENTORY_VERIFIED_LOCAL',
        );
        expect(report.inventoryVerified, isTrue);
        expect(report.declaredProviders.length, 32);
        expect(report.observedCount, 0);
        expect(report.certifiedCount, 0);
        expect(report.expansionBudgetFrozen, isTrue);
        expect(report.violations, isEmpty);
        expect(report.blockers, isEmpty);
        expect(report.openItems, isEmpty);
        expect(report.externalGates, 'DEFERRED-EXTERNAL');
      },
    );

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118ExpansionEvidenceGate().evaluateWith(
        null,
        _record(),
      );
      expect(report.state, Sprint118ExpansionEvidenceState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_EXPANSION_EVIDENCE_INVENTORY_EVIDENCE_UNREADABLE',
      );
      expect(report.inventoryVerified, isFalse);
      expect(
        report.blockers,
        contains('committed_expansion_evidence_unreadable'),
      );
    });

    test('blocks when the committed charter is incomplete', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterVerdict: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118ExpansionEvidenceState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_EXPANSION_EVIDENCE_INVENTORY_BLOCKED_UPSTREAM',
      );
      expect(report.blockers, contains('charter_not_complete:SOMETHING_ELSE'));
    });

    test('blocks when the committed snapshot is not frozen', () {
      final report = _run(
        _record(),
        anchor: _anchor(snapshotVerdict: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118ExpansionEvidenceState.blocked);
      expect(report.blockers, contains('snapshot_not_frozen:SOMETHING_ELSE'));
    });

    test('blocks when the approval gate is not a delay', () {
      final report = _run(
        _record(),
        anchor: _anchor(approvalDecision: 'release'),
      );
      expect(report.state, Sprint118ExpansionEvidenceState.blocked);
      expect(report.blockers, contains('approval_gate_not_delay:release'));
    });

    test('blocks when the registered provider set does not reconcile', () {
      final report = _run(
        _record(),
        anchor: _anchor(registryExpectedCount: 31),
      );
      expect(report.state, Sprint118ExpansionEvidenceState.blocked);
      expect(
        report.blockers,
        contains(
          'registry_not_reconciled:icon=32:reconciliation=31:'
          'snapshot=32:charter=32',
        ),
      );
    });

    test('fails when the record release state disagrees with the anchor', () {
      final report = _run(
        _record(releaseState: 'GA_RELEASED'),
        anchor: _anchor(),
      );
      expect(report.state, Sprint118ExpansionEvidenceState.fail);
      expect(
        report.violations,
        contains('release_state_mismatch:anchor=GA_DELAYED:record=GA_RELEASED'),
      );
    });

    test('fails when the inventory is not on the delayed path', () {
      final report = _run(_record(releaseState: 'GA_RELEASED'));
      expect(report.state, Sprint118ExpansionEvidenceState.fail);
      expect(
        report.violations,
        contains('expansion_inventory_not_on_delayed_path:GA_RELEASED'),
      );
    });

    test(
      'fails when expansion execution is authorized on the delayed path',
      () {
        final report = _run(
          _record(),
          anchor: _anchor(executionAuthorized: true),
        );
        expect(report.state, Sprint118ExpansionEvidenceState.fail);
        expect(
          report.violations,
          contains('expansion_execution_authorized_on_delayed_path'),
        );
      },
    );

    test(
      'fails when the expansion release is not blocked on the delayed path',
      () {
        final report = _run(_record(), anchor: _anchor(releaseBlocked: false));
        expect(report.state, Sprint118ExpansionEvidenceState.fail);
        expect(
          report.violations,
          contains('expansion_release_not_blocked_on_delayed_path'),
        );
      },
    );

    test('fails when the expansion budget is not frozen', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterMaxNewCertified: 1),
      );
      expect(report.state, Sprint118ExpansionEvidenceState.fail);
      expect(
        report.violations,
        contains('expansion_budget_not_frozen:max_new=1:currently=0'),
      );
    });

    test('fails when a registered provider is missing', () {
      final report = _run(
        _record(
          entries: <Sprint118ExpansionEvidenceEntry>[
            for (final e
                in Sprint118ExpansionEvidenceContract.canonicalRecord.entries)
              if (e.providerId != 'openai') e,
          ],
        ),
      );
      expect(report.state, Sprint118ExpansionEvidenceState.fail);
      expect(report.violations, contains('expansion_provider_missing:openai'));
    });

    test('fails when a registered provider is duplicated', () {
      final report = _run(
        _record(
          entries: <Sprint118ExpansionEvidenceEntry>[
            ...Sprint118ExpansionEvidenceContract.canonicalRecord.entries,
            _entry(providerId: 'openai'),
          ],
        ),
      );
      expect(report.state, Sprint118ExpansionEvidenceState.fail);
      expect(
        report.violations,
        contains('expansion_provider_duplicate:openai'),
      );
    });

    test('fails when an unknown provider is invented', () {
      final report = _run(
        _record(
          entries: <Sprint118ExpansionEvidenceEntry>[
            ...Sprint118ExpansionEvidenceContract.canonicalRecord.entries,
            _entry(providerId: 'telepathy'),
          ],
        ),
      );
      expect(report.state, Sprint118ExpansionEvidenceState.fail);
      expect(
        report.violations,
        contains('expansion_provider_unknown:telepathy'),
      );
    });

    test('fails when a required entry field is blank', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', demandEvidence: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionEvidenceState.fail);
      expect(report.violations, contains('entry_blank_demand_evidence:openai'));
    });

    test('fails when a reference state is not grounded by a witness', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', apiFeasibility: 'telepathy'),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionEvidenceState.fail);
      expect(
        report.violations,
        contains('reference_state_invalid:api_feasibility:openai'),
      );
    });

    test(
      'records an open item when a reference state is the no-reference marker',
      () {
        final report = _run(
          _record(
            entries: _replacing(
              'openai',
              _entry(
                providerId: 'openai',
                regionConstraints:
                    Sprint118ExpansionEvidenceContract.noReferenceState,
              ),
            ),
          ),
        );
        expect(report.state, Sprint118ExpansionEvidenceState.pass);
        expect(
          report.openItems,
          contains('upstream_state_vocabulary_gap:region_constraints:openai'),
        );
      },
    );

    test('fails when an entry claims a certified connector', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', certified: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionEvidenceState.fail);
      expect(
        report.violations,
        contains('expansion_provider_certified_claimed:openai'),
      );
    });

    test('fails when an entry claims an available endpoint', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', available: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionEvidenceState.fail);
      expect(
        report.violations,
        contains('expansion_provider_available_claimed:openai'),
      );
    });

    test('fails when an entry claims a measured demand', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', demanded: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionEvidenceState.fail);
      expect(
        report.violations,
        contains('expansion_provider_demanded_claimed:openai'),
      );
    });

    test('fails when an entry claims a live observation', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', observed: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionEvidenceState.fail);
      expect(
        report.violations,
        contains('expansion_provider_observed_claimed:openai'),
      );
    });

    test('fails when an entry claims a released provider', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', released: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionEvidenceState.fail);
      expect(
        report.violations,
        contains('expansion_provider_released_claimed:openai'),
      );
    });

    test('fails when a required evidence source is unreadable', () {
      final report = _run(
        _record(),
        anchor: _anchor(
          readableSources: <String>[
            Sprint118ExpansionEvidenceContract.iconRegistryManifestPath,
          ],
        ),
      );
      expect(report.state, Sprint118ExpansionEvidenceState.fail);
      expect(
        report.violations,
        contains(
          'required_source_unreadable:'
          'docs/planning/v1.3/sprint_118_stability_expansion_charter.json',
        ),
      );
    });

    test('the loader reads the committed witnesses on disk', () {
      final anchor = const Sprint118ExpansionEvidenceLoader().loadAnchor();
      expect(anchor, isNotNull);
      expect(anchor!.charterState, 'pass');
      expect(anchor.charterVerdict, 'CHARTER_COMPLETE_LOCAL');
      expect(anchor.charterMaxNewCertified, 0);
      expect(anchor.charterCurrentlyCertified, 0);
      expect(anchor.charterRegisteredProviders, 32);
      expect(
        anchor.snapshotVerdict,
        'CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL',
      );
      expect(anchor.snapshotRegistered, 32);
      expect(anchor.registryExpectedCount, 32);
      expect(anchor.approvalDecision, 'delay');
      expect(anchor.approvalState, 'PENDING_CHOIRUDIN');
      expect(anchor.executionAuthorized, isFalse);
      expect(anchor.releaseBlocked, isTrue);
      expect(anchor.registeredProviders.length, 32);
      expect(anchor.demandOutcomes, contains('no_live_outcome'));
      expect(anchor.workflows, contains('writer'));
      expect(anchor.dependencySignals, contains('provider_availability'));
      expect(anchor.costAcceptance, contains('quota_unavailable'));
      expect(anchor.securityOutputs, contains('permission_tests'));
      expect(anchor.privacySubjects, contains('external_transfers'));
      expect(anchor.feasibilityStates, contains('unsupported_region'));
      expect(anchor.readableSources.length, 11);
    });

    test('the gate evaluates the committed record to a pass', () {
      final report = const Sprint118ExpansionEvidenceGate().evaluate();
      expect(report.state, Sprint118ExpansionEvidenceState.pass);
      expect(
        report.verdict,
        'PROVIDER_EXPANSION_EVIDENCE_INVENTORY_VERIFIED_LOCAL',
      );
      expect(report.releaseState, 'GA_DELAYED');
      expect(report.declaredProviders.length, 32);
      expect(report.observedCount, 0);
    });
  });
}
