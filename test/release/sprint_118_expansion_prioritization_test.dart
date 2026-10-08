import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_expansion_prioritization.dart';

/// A single expansion-priority entry. Each test flips exactly the one thing it
/// is about, so a test that flips nothing proves the pass path exists and every
/// other test proves one way the gate refuses to take it.
Sprint118ExpansionPriorityEntry _entry({
  String providerId = 'openai',
  String userValue = Sprint118ExpansionPriorityContract.userValueToken,
  String evidenceStrength =
      Sprint118ExpansionPriorityContract.evidenceStrengthToken,
  String feasibility = Sprint118ExpansionPriorityContract.feasibilityToken,
  String risk = Sprint118ExpansionPriorityContract.riskToken,
  String maintenance = Sprint118ExpansionPriorityContract.maintenanceToken,
  String supportCost = Sprint118ExpansionPriorityContract.supportCostToken,
  String strategicFit = Sprint118ExpansionPriorityContract.strategicFitToken,
  bool prioritized = false,
  bool ranked = false,
  bool recommended = false,
  bool certified = false,
  bool released = false,
}) {
  return Sprint118ExpansionPriorityEntry(
    providerId: providerId,
    userValue: userValue,
    evidenceStrength: evidenceStrength,
    feasibility: feasibility,
    risk: risk,
    maintenance: maintenance,
    supportCost: supportCost,
    strategicFit: strategicFit,
    prioritized: prioritized,
    ranked: ranked,
    recommended: recommended,
    certified: certified,
    released: released,
  );
}

Sprint118ExpansionPriorityRecord _record({
  String releaseState = Sprint118ExpansionPriorityContract.delayedReleaseState,
  List<Sprint118ExpansionPriorityEntry>? entries,
}) {
  return Sprint118ExpansionPriorityRecord(
    releaseState: releaseState,
    entries:
        entries ?? Sprint118ExpansionPriorityContract.canonicalRecord.entries,
  );
}

/// The canonical entries with exactly one provider replaced, so a test can flip
/// a single entry without rebuilding the whole record.
List<Sprint118ExpansionPriorityEntry> _replacing(
  String providerId,
  Sprint118ExpansionPriorityEntry replacement,
) {
  return <Sprint118ExpansionPriorityEntry>[
    for (final e in Sprint118ExpansionPriorityContract.canonicalRecord.entries)
      if (e.providerId == providerId) replacement else e,
  ];
}

Sprint118ExpansionPriorityAnchor _anchor({
  String charterState = 'pass',
  String charterVerdict =
      Sprint118ExpansionPriorityContract.requiredCharterVerdict,
  int charterMaxNewCertified = 0,
  int charterCurrentlyCertified = 0,
  int charterRegisteredProviders =
      Sprint118ExpansionPriorityContract.expectedProviderCount,
  String snapshotState = 'pass',
  String snapshotVerdict =
      Sprint118ExpansionPriorityContract.requiredSnapshotVerdict,
  int snapshotCertified = 0,
  int snapshotRegistered =
      Sprint118ExpansionPriorityContract.expectedProviderCount,
  String releaseState = Sprint118ExpansionPriorityContract.delayedReleaseState,
  int registryExpectedCount =
      Sprint118ExpansionPriorityContract.expectedProviderCount,
  String approvalDecision =
      Sprint118ExpansionPriorityContract.requiredApprovalDecision,
  String approvalState = 'PENDING_CHOIRUDIN',
  bool executionAuthorized = false,
  bool releaseBlocked = true,
  List<String>? registeredProviders,
  List<String>? charterStopMetrics,
  List<String>? charterStrategicAreas,
  List<String>? userValueVocabulary,
  List<String>? evidenceStrengthVocabulary,
  List<String>? feasibilityVocabulary,
  List<String>? maintenanceVocabulary,
  List<String>? supportCostVocabulary,
  List<String>? readableSources,
}) {
  return Sprint118ExpansionPriorityAnchor(
    charterState: charterState,
    charterVerdict: charterVerdict,
    charterMaxNewCertified: charterMaxNewCertified,
    charterCurrentlyCertified: charterCurrentlyCertified,
    charterRegisteredProviders: charterRegisteredProviders,
    charterStopMetrics:
        charterStopMetrics ??
        const <String>[
          'crash_rate',
          'auth_success',
          'sync_integrity_issue',
          'privacy_leak',
          'error_rate',
        ],
    charterStrategicAreas:
        charterStrategicAreas ??
        const <String>[
          'connection_health',
          'oauth_reauth',
          'quota_storage',
          'sync_backup_recovery',
          'ai_provider',
          'billing_entitlement',
          'security',
          'privacy',
          'novel_character_boundary',
          'accessibility',
          'performance',
          'provider_outage_recovery',
        ],
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
        Sprint118ExpansionPriorityContract.canonicalProviders,
    userValueVocabulary:
        userValueVocabulary ??
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
    evidenceStrengthVocabulary:
        evidenceStrengthVocabulary ??
        const <String>[
          'demand_evidence',
          'workflow_value',
          'api_feasibility',
          'maintenance_cost',
          'security',
          'privacy',
          'region_constraints',
        ],
    feasibilityVocabulary:
        feasibilityVocabulary ??
        const <String>[
          'provider_availability',
          'timeout',
          'throttling',
          'auth_expiry',
          'cost_visibility',
          'fallback_success',
          'consent_failure',
        ],
    maintenanceVocabulary:
        maintenanceVocabulary ??
        const <String>[
          'live_production_telemetry',
          'public_incident_intake',
          'external_adoption_evidence',
          'public_release_signing',
          'hosted_ci_validation',
          'published_artifact_validation',
          'hardware_validation',
          'publication',
        ],
    supportCostVocabulary:
        supportCostVocabulary ?? const <String>['P0', 'P1', 'P2', 'P3'],
    readableSources:
        readableSources ??
        Sprint118ExpansionPriorityContract.witnessSources.toSet().toList(),
  );
}

Sprint118ExpansionPriorityReport _run(
  Sprint118ExpansionPriorityRecord record, {
  Sprint118ExpansionPriorityAnchor? anchor,
}) {
  return const Sprint118ExpansionPriorityGate().evaluateWith(
    anchor ?? _anchor(),
    record,
  );
}

void main() {
  group('Sprint 118.30 Expansion Prioritization', () {
    test('the canonical field vocabulary is the eight objective fields', () {
      expect(Sprint118ExpansionPriorityContract.requiredFields, <String>[
        'provider_id',
        'user_value',
        'evidence_strength',
        'feasibility',
        'risk',
        'maintenance',
        'support_cost',
        'strategic_fit',
      ]);
    });

    test('the canonical criteria are the seven objective items', () {
      expect(Sprint118ExpansionPriorityContract.requiredCriteria, <String>[
        'user_value',
        'evidence_strength',
        'feasibility',
        'risk',
        'maintenance',
        'support_cost',
        'strategic_fit',
      ]);
    });

    test(
      'the reference-state vocabulary is derived from committed witnesses',
      () {
        final vocabulary = Sprint118ExpansionPriorityContract.stateVocabulary(
          <List<String>>[
            const <String>['no_live_outcome', 'completion'],
            const <String>['provider_availability'],
          ],
        );
        expect(vocabulary, contains('no_live_outcome'));
        expect(vocabulary, contains('completion'));
        expect(vocabulary, contains('provider_availability'));
        expect(
          vocabulary,
          contains(Sprint118ExpansionPriorityContract.noReferenceState),
        );
        // A token only grounds when the witness names it exactly, or when every
        // underscore-separated part is itself a witness-declared value.
        expect(
          Sprint118ExpansionPriorityContract.grounds(
            vocabulary,
            'no_live_outcome',
          ),
          isTrue,
        );
        expect(
          Sprint118ExpansionPriorityContract.grounds(vocabulary, 'telepathy'),
          isFalse,
        );
        expect(
          Sprint118ExpansionPriorityContract.grounds(const <String>[
            'provider',
            'availability',
          ], 'provider_availability'),
          isTrue,
        );
        expect(
          Sprint118ExpansionPriorityContract.grounds(const <String>[
            'provider',
          ], 'provider_availability'),
          isFalse,
        );
      },
    );

    test(
      'canonical record covers all 32 registered providers and selects nothing',
      () {
        final record = Sprint118ExpansionPriorityContract.canonicalRecord;
        expect(record.entries.length, 32);
        expect(
          record.providerIds.toSet(),
          Sprint118ExpansionPriorityContract.canonicalProviders.toSet(),
        );
        expect(record.selectedProviders, isEmpty);
        expect(record.prioritizedCount, 0);
        expect(record.rankedCount, 0);
        expect(record.recommendedCount, 0);
        for (final entry in record.entries) {
          expect(entry.prioritized, isFalse);
          expect(entry.ranked, isFalse);
          expect(entry.recommended, isFalse);
          expect(entry.certified, isFalse);
          expect(entry.released, isFalse);
          for (final field
              in Sprint118ExpansionPriorityContract.requiredFields) {
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
        expect(report.state, Sprint118ExpansionPriorityState.pass);
        expect(report.verdict, 'EXPANSION_PRIORITIZATION_VERIFIED_LOCAL');
        expect(report.prioritizationVerified, isTrue);
        expect(report.declaredProviders.length, 32);
        expect(report.selectedProviders, isEmpty);
        expect(report.prioritizedCount, 0);
        expect(report.rankedCount, 0);
        expect(report.recommendedCount, 0);
        expect(report.expansionBudgetFrozen, isTrue);
        expect(report.violations, isEmpty);
        expect(report.blockers, isEmpty);
        expect(report.openItems, isEmpty);
        expect(report.externalGates, 'DEFERRED-EXTERNAL');
      },
    );

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118ExpansionPriorityGate().evaluateWith(
        null,
        _record(),
      );
      expect(report.state, Sprint118ExpansionPriorityState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_EXPANSION_PRIORITIZATION_EVIDENCE_UNREADABLE',
      );
      expect(report.prioritizationVerified, isFalse);
      expect(
        report.blockers,
        contains('committed_expansion_priority_evidence_unreadable'),
      );
    });

    test('blocks when the committed charter is incomplete', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterVerdict: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118ExpansionPriorityState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_EXPANSION_PRIORITIZATION_BLOCKED_UPSTREAM',
      );
      expect(report.blockers, contains('charter_not_complete:SOMETHING_ELSE'));
    });

    test('blocks when the committed snapshot is not frozen', () {
      final report = _run(
        _record(),
        anchor: _anchor(snapshotVerdict: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118ExpansionPriorityState.blocked);
      expect(report.blockers, contains('snapshot_not_frozen:SOMETHING_ELSE'));
    });

    test('blocks when the approval gate is not a delay', () {
      final report = _run(
        _record(),
        anchor: _anchor(approvalDecision: 'release'),
      );
      expect(report.state, Sprint118ExpansionPriorityState.blocked);
      expect(report.blockers, contains('approval_gate_not_delay:release'));
    });

    test('blocks when the registered provider set does not reconcile', () {
      final report = _run(
        _record(),
        anchor: _anchor(registryExpectedCount: 31),
      );
      expect(report.state, Sprint118ExpansionPriorityState.blocked);
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
      expect(report.state, Sprint118ExpansionPriorityState.fail);
      expect(
        report.violations,
        contains('release_state_mismatch:anchor=GA_DELAYED:record=GA_RELEASED'),
      );
    });

    test('fails when the prioritization is not on the delayed path', () {
      final report = _run(_record(releaseState: 'GA_RELEASED'));
      expect(report.state, Sprint118ExpansionPriorityState.fail);
      expect(
        report.violations,
        contains('expansion_prioritization_not_on_delayed_path:GA_RELEASED'),
      );
    });

    test(
      'fails when expansion execution is authorized on the delayed path',
      () {
        final report = _run(
          _record(),
          anchor: _anchor(executionAuthorized: true),
        );
        expect(report.state, Sprint118ExpansionPriorityState.fail);
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
        expect(report.state, Sprint118ExpansionPriorityState.fail);
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
      expect(report.state, Sprint118ExpansionPriorityState.fail);
      expect(
        report.violations,
        contains('expansion_budget_not_frozen:max_new=1:currently=0'),
      );
    });

    test('fails when a registered provider is missing', () {
      final report = _run(
        _record(
          entries: <Sprint118ExpansionPriorityEntry>[
            for (final e
                in Sprint118ExpansionPriorityContract.canonicalRecord.entries)
              if (e.providerId != 'openai') e,
          ],
        ),
      );
      expect(report.state, Sprint118ExpansionPriorityState.fail);
      expect(report.violations, contains('expansion_provider_missing:openai'));
    });

    test('fails when a registered provider is duplicated', () {
      final report = _run(
        _record(
          entries: <Sprint118ExpansionPriorityEntry>[
            ...Sprint118ExpansionPriorityContract.canonicalRecord.entries,
            _entry(providerId: 'openai'),
          ],
        ),
      );
      expect(report.state, Sprint118ExpansionPriorityState.fail);
      expect(
        report.violations,
        contains('expansion_provider_duplicate:openai'),
      );
    });

    test('fails when an unknown provider is invented', () {
      final report = _run(
        _record(
          entries: <Sprint118ExpansionPriorityEntry>[
            ...Sprint118ExpansionPriorityContract.canonicalRecord.entries,
            _entry(providerId: 'telepathy'),
          ],
        ),
      );
      expect(report.state, Sprint118ExpansionPriorityState.fail);
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
            _entry(providerId: 'openai', userValue: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionPriorityState.fail);
      expect(report.violations, contains('entry_blank_user_value:openai'));
    });

    test('fails when a criterion is not grounded by a witness', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', feasibility: 'telepathy'),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionPriorityState.fail);
      expect(
        report.violations,
        contains('reference_state_invalid:feasibility:openai'),
      );
    });

    test(
      'records an open item when a criterion is the no-reference marker',
      () {
        final report = _run(
          _record(
            entries: _replacing(
              'openai',
              _entry(
                providerId: 'openai',
                strategicFit:
                    Sprint118ExpansionPriorityContract.noReferenceState,
              ),
            ),
          ),
        );
        expect(report.state, Sprint118ExpansionPriorityState.pass);
        expect(
          report.openItems,
          contains('upstream_state_vocabulary_gap:strategic_fit:openai'),
        );
      },
    );

    test('fails when an entry selects a provider as a priority', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', prioritized: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionPriorityState.fail);
      expect(
        report.violations,
        contains('expansion_priority_claimed_on_delayed_path:openai'),
      );
      expect(report.selectedProviders, contains('openai'));
    });

    test('fails when an entry ranks a provider', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', ranked: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionPriorityState.fail);
      expect(
        report.violations,
        contains('expansion_rank_claimed_on_delayed_path:openai'),
      );
    });

    test('fails when an entry recommends a provider', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', recommended: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionPriorityState.fail);
      expect(
        report.violations,
        contains('expansion_recommendation_claimed_on_delayed_path:openai'),
      );
    });

    test('fails when an entry claims a certified connector', () {
      final report = _run(
        _record(
          entries: _replacing(
            'openai',
            _entry(providerId: 'openai', certified: true),
          ),
        ),
      );
      expect(report.state, Sprint118ExpansionPriorityState.fail);
      expect(
        report.violations,
        contains('expansion_provider_certified_claimed:openai'),
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
      expect(report.state, Sprint118ExpansionPriorityState.fail);
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
            Sprint118ExpansionPriorityContract.iconRegistryManifestPath,
          ],
        ),
      );
      expect(report.state, Sprint118ExpansionPriorityState.fail);
      expect(
        report.violations,
        contains(
          'required_source_unreadable:'
          'docs/planning/v1.3/sprint_118_stability_expansion_charter.json',
        ),
      );
    });

    test('the loader reads the committed witnesses on disk', () {
      final anchor = const Sprint118ExpansionPriorityLoader().loadAnchor();
      expect(anchor, isNotNull);
      expect(anchor!.charterState, 'pass');
      expect(anchor.charterVerdict, 'CHARTER_COMPLETE_LOCAL');
      expect(anchor.charterMaxNewCertified, 0);
      expect(anchor.charterCurrentlyCertified, 0);
      expect(anchor.charterRegisteredProviders, 32);
      expect(anchor.charterStopMetrics, contains('error_rate'));
      expect(
        anchor.charterStrategicAreas,
        contains('provider_outage_recovery'),
      );
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
      expect(anchor.userValueVocabulary, contains('no_live_outcome'));
      expect(anchor.evidenceStrengthVocabulary, contains('demand_evidence'));
      expect(anchor.feasibilityVocabulary, contains('provider_availability'));
      expect(anchor.maintenanceVocabulary, contains('hosted_ci_validation'));
      expect(anchor.supportCostVocabulary, contains('P3'));
      expect(anchor.readableSources.length, 10);
    });

    test('the gate evaluates the committed record to a pass', () {
      final report = const Sprint118ExpansionPriorityGate().evaluate();
      expect(report.state, Sprint118ExpansionPriorityState.pass);
      expect(report.verdict, 'EXPANSION_PRIORITIZATION_VERIFIED_LOCAL');
      expect(report.releaseState, 'GA_DELAYED');
      expect(report.declaredProviders.length, 32);
      expect(report.selectedProviders, isEmpty);
    });
  });
}
