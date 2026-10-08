import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_creative_connector_expansion.dart';

/// A single creative connector expansion entry. Each test flips exactly the one
/// thing it is about, so a test that flips nothing proves the pass path exists
/// and every other test proves one way the gate refuses to take it.
Sprint118CreativeConnectorEntry _entry({
  String providerId = 'figma',
  String selectedProvider =
      Sprint118CreativeConnectorContract.selectedProviderToken,
  String assetRights = Sprint118CreativeConnectorContract.assetRightsToken,
  String attribution = Sprint118CreativeConnectorContract.attributionToken,
  String importBoundary = Sprint118CreativeConnectorContract.importToken,
  String exportBoundary = Sprint118CreativeConnectorContract.exportToken,
  String planLimits = Sprint118CreativeConnectorContract.planLimitsToken,
  bool certified = false,
  bool selected = false,
  bool assetRightsVerified = false,
  bool attributionVerified = false,
  bool importVerified = false,
  bool exportVerified = false,
  bool planLimitsVerified = false,
  bool released = false,
}) {
  return Sprint118CreativeConnectorEntry(
    providerId: providerId,
    selectedProvider: selectedProvider,
    assetRights: assetRights,
    attribution: attribution,
    importBoundary: importBoundary,
    exportBoundary: exportBoundary,
    planLimits: planLimits,
    certified: certified,
    selected: selected,
    assetRightsVerified: assetRightsVerified,
    attributionVerified: attributionVerified,
    importVerified: importVerified,
    exportVerified: exportVerified,
    planLimitsVerified: planLimitsVerified,
    released: released,
  );
}

Sprint118CreativeConnectorRecord _record({
  String releaseState = Sprint118CreativeConnectorContract.delayedReleaseState,
  List<Sprint118CreativeConnectorEntry>? entries,
}) {
  return Sprint118CreativeConnectorRecord(
    releaseState: releaseState,
    entries:
        entries ?? Sprint118CreativeConnectorContract.canonicalRecord.entries,
  );
}

/// The canonical entries with exactly one provider replaced, so a test can flip
/// a single entry without rebuilding the whole record.
List<Sprint118CreativeConnectorEntry> _replacing(
  String providerId,
  Sprint118CreativeConnectorEntry replacement,
) {
  return <Sprint118CreativeConnectorEntry>[
    for (final e in Sprint118CreativeConnectorContract.canonicalRecord.entries)
      if (e.providerId == providerId) replacement else e,
  ];
}

Sprint118CreativeConnectorAnchor _anchor({
  String charterState = 'pass',
  String charterVerdict =
      Sprint118CreativeConnectorContract.requiredCharterVerdict,
  int charterMaxNewCertified = 0,
  int charterCurrentlyCertified = 0,
  int charterRegisteredProviders =
      Sprint118CreativeConnectorContract.expectedProviderCount,
  String snapshotState = 'pass',
  String snapshotVerdict =
      Sprint118CreativeConnectorContract.requiredSnapshotVerdict,
  int snapshotCertified = 0,
  int snapshotRegistered =
      Sprint118CreativeConnectorContract.expectedProviderCount,
  String releaseState = Sprint118CreativeConnectorContract.delayedReleaseState,
  int registryExpectedCount =
      Sprint118CreativeConnectorContract.expectedProviderCount,
  String approvalDecision =
      Sprint118CreativeConnectorContract.requiredApprovalDecision,
  String approvalState = 'PENDING_CHOIRUDIN',
  bool executionAuthorized = false,
  bool releaseBlocked = true,
  String creativeWorkflowStatus =
      Sprint118CreativeConnectorContract.requiredCreativeWorkflowStatus,
  String creativeWorkflowVerdict =
      Sprint118CreativeConnectorContract.requiredCreativeWorkflowVerdict,
  List<String>? registeredProviders,
  List<String>? selectedProviderVocabulary,
  List<String>? assetRightsVocabulary,
  List<String>? attributionVocabulary,
  List<String>? importVocabulary,
  List<String>? exportVocabulary,
  List<String>? planLimitsVocabulary,
  List<String>? readableSources,
}) {
  return Sprint118CreativeConnectorAnchor(
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
    creativeWorkflowStatus: creativeWorkflowStatus,
    creativeWorkflowVerdict: creativeWorkflowVerdict,
    registeredProviders:
        registeredProviders ??
        Sprint118CreativeConnectorContract.canonicalProviders,
    selectedProviderVocabulary:
        selectedProviderVocabulary ??
        const <String>[
          'manifest_driven',
          'asset_permissions',
          'import_export_scope',
          'disconnect',
          'unavailable_state',
          'attribution',
        ],
    assetRightsVocabulary:
        assetRightsVocabulary ??
        const <String>[
          'provider_id',
          'integration_availability',
          'asset_rights',
          'download_scopes',
          'upload_scopes',
          'attribution',
          'limitations',
        ],
    attributionVocabulary:
        attributionVocabulary ??
        const <String>[
          'provider_id',
          'file_access',
          'asset_import_export',
          'scopes',
          'attribution',
          'rate_limits',
          'revoke',
        ],
    importVocabulary:
        importVocabulary ??
        const <String>[
          'asset_access',
          'attribution',
          'export',
          'import',
          'revoke',
          'rights',
        ],
    exportVocabulary:
        exportVocabulary ??
        const <String>[
          'asset_access',
          'attribution',
          'export',
          'import',
          'revoke',
          'rights',
        ],
    planLimitsVocabulary:
        planLimitsVocabulary ??
        const <String>[
          'provider_id',
          'actual_apis',
          'supported_capabilities',
          'licensing',
          'scopes',
          'region_plan_limits',
          'unavailable_states',
        ],
    readableSources:
        readableSources ??
        Sprint118CreativeConnectorContract.witnessSources.toSet().toList(),
  );
}

Sprint118CreativeConnectorReport _run(
  Sprint118CreativeConnectorRecord record, {
  Sprint118CreativeConnectorAnchor? anchor,
}) {
  return const Sprint118CreativeConnectorGate().evaluateWith(
    anchor ?? _anchor(),
    record,
  );
}

void main() {
  group('Sprint 118.37 Creative Connector Expansion', () {
    test('the canonical field vocabulary is the seven objective fields', () {
      expect(Sprint118CreativeConnectorContract.requiredFields, <String>[
        'provider_id',
        'selected_provider',
        'asset_rights',
        'attribution',
        'import',
        'export',
        'plan_limits',
      ]);
    });

    test('the canonical outputs are the six objective items', () {
      expect(Sprint118CreativeConnectorContract.requiredOutputs, <String>[
        'selected_provider',
        'asset_rights',
        'attribution',
        'import',
        'export',
        'plan_limits',
      ]);
    });

    test(
      'the reference-state vocabulary is derived from committed witnesses',
      () {
        final vocabulary = Sprint118CreativeConnectorContract.stateVocabulary(
          <List<String>>[
            const <String>['manifest_driven', 'attribution'],
            const <String>['import', 'export'],
          ],
        );
        expect(vocabulary, contains('manifest_driven'));
        expect(vocabulary, contains('attribution'));
        expect(vocabulary, contains('import'));
        expect(vocabulary, contains('export'));
        expect(
          vocabulary,
          contains(Sprint118CreativeConnectorContract.noReferenceState),
        );
        expect(
          Sprint118CreativeConnectorContract.grounds(vocabulary, 'import'),
          isTrue,
        );
        expect(
          Sprint118CreativeConnectorContract.grounds(vocabulary, 'telepathy'),
          isFalse,
        );
      },
    );

    test(
      'canonical record covers all 32 registered providers and claims nothing',
      () {
        final record = Sprint118CreativeConnectorContract.canonicalRecord;
        expect(record.entries.length, 32);
        expect(
          record.providerIds.toSet(),
          Sprint118CreativeConnectorContract.canonicalProviders.toSet(),
        );
        for (final entry in record.entries) {
          expect(entry.certified, isFalse);
          expect(entry.selected, isFalse);
          expect(entry.assetRightsVerified, isFalse);
          expect(entry.attributionVerified, isFalse);
          expect(entry.importVerified, isFalse);
          expect(entry.exportVerified, isFalse);
          expect(entry.planLimitsVerified, isFalse);
          expect(entry.released, isFalse);
          for (final field
              in Sprint118CreativeConnectorContract.requiredFields) {
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
      expect(report.state, Sprint118CreativeConnectorState.pass);
      expect(report.verdict, 'CREATIVE_CONNECTOR_EXPANSION_VERIFIED_LOCAL');
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
      final report = const Sprint118CreativeConnectorGate().evaluateWith(
        null,
        _record(),
      );
      expect(report.state, Sprint118CreativeConnectorState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_CREATIVE_CONNECTOR_EXPANSION_EVIDENCE_UNREADABLE',
      );
      expect(report.certificationVerified, isFalse);
      expect(
        report.blockers,
        contains('committed_creative_connector_evidence_unreadable'),
      );
    });

    test('blocks when the committed charter is not complete', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterVerdict: 'CHARTER_INCOMPLETE_LOCAL'),
      );
      expect(report.state, Sprint118CreativeConnectorState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_CREATIVE_CONNECTOR_EXPANSION_BLOCKED_UPSTREAM',
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
      expect(report.state, Sprint118CreativeConnectorState.blocked);
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
      expect(report.state, Sprint118CreativeConnectorState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('approval_gate_not_delay:')),
        isTrue,
      );
    });

    test('blocks when the committed creative workflow is not a pass', () {
      final report = _run(
        _record(),
        anchor: _anchor(
          creativeWorkflowVerdict: 'CREATIVE_CONNECTOR_WORKFLOW_DRIFT',
        ),
      );
      expect(report.state, Sprint118CreativeConnectorState.blocked);
      expect(
        report.blockers.any(
          (b) => b.startsWith('creative_workflow_not_validated:'),
        ),
        isTrue,
      );
    });

    test('blocks when the registered provider set does not reconcile', () {
      final report = _run(
        _record(),
        anchor: _anchor(registryExpectedCount: 31),
      );
      expect(report.state, Sprint118CreativeConnectorState.blocked);
      expect(
        report.blockers.any((b) => b.startsWith('registry_not_reconciled:')),
        isTrue,
      );
    });

    test('fails when a provider claims a certified connector', () {
      final report = _run(
        _record(
          entries: _replacing(
            'figma',
            _entry(providerId: 'figma', certified: true),
          ),
        ),
      );
      expect(report.state, Sprint118CreativeConnectorState.fail);
      expect(
        report.violations,
        contains('creative_connector_certified_claimed_on_delayed_path:figma'),
      );
      expect(report.certifiedCount, 1);
    });

    test('fails when a provider claims it was selected', () {
      final report = _run(
        _record(
          entries: _replacing(
            'adobe',
            _entry(providerId: 'adobe', selected: true),
          ),
        ),
      );
      expect(report.state, Sprint118CreativeConnectorState.fail);
      expect(
        report.violations,
        contains('creative_connector_selected_claimed_on_delayed_path:adobe'),
      );
      expect(report.selectedCount, 1);
    });

    test('fails when an asset right is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'canva',
            _entry(providerId: 'canva', assetRightsVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118CreativeConnectorState.fail);
      expect(
        report.violations,
        contains(
          'creative_connector_asset_rights_verified_on_delayed_path:canva',
        ),
      );
    });

    test('fails when an attribution is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'blender_cloud',
            _entry(providerId: 'blender_cloud', attributionVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118CreativeConnectorState.fail);
      expect(
        report.violations,
        contains(
          'creative_connector_attribution_verified_on_delayed_path:'
          'blender_cloud',
        ),
      );
    });

    test('fails when an import is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'sketchfab',
            _entry(providerId: 'sketchfab', importVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118CreativeConnectorState.fail);
      expect(
        report.violations,
        contains(
          'creative_connector_import_verified_on_delayed_path:sketchfab',
        ),
      );
    });

    test('fails when an export is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'figma',
            _entry(providerId: 'figma', exportVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118CreativeConnectorState.fail);
      expect(
        report.violations,
        contains('creative_connector_export_verified_on_delayed_path:figma'),
      );
    });

    test('fails when a plan limit is claimed verified', () {
      final report = _run(
        _record(
          entries: _replacing(
            'canva',
            _entry(providerId: 'canva', planLimitsVerified: true),
          ),
        ),
      );
      expect(report.state, Sprint118CreativeConnectorState.fail);
      expect(
        report.violations,
        contains(
          'creative_connector_plan_limits_verified_on_delayed_path:canva',
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
      expect(report.state, Sprint118CreativeConnectorState.fail);
      expect(
        report.violations,
        contains('creative_connector_provider_released_claimed:kofi'),
      );
    });

    test('fails when the expansion budget is not frozen', () {
      final report = _run(
        _record(),
        anchor: _anchor(charterMaxNewCertified: 1),
      );
      expect(report.state, Sprint118CreativeConnectorState.fail);
      expect(
        report.violations.any(
          (v) =>
              v.startsWith('creative_connector_expansion_budget_not_frozen:'),
        ),
        isTrue,
      );
      expect(report.expansionBudgetFrozen, isFalse);
    });

    test('fails when a registered provider is missing', () {
      final entries = <Sprint118CreativeConnectorEntry>[
        for (final e
            in Sprint118CreativeConnectorContract.canonicalRecord.entries)
          if (e.providerId != 'kofi') e,
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118CreativeConnectorState.fail);
      expect(
        report.violations,
        contains('creative_connector_provider_missing:kofi'),
      );
    });

    test('fails when an unknown provider is invented', () {
      final entries = <Sprint118CreativeConnectorEntry>[
        ...Sprint118CreativeConnectorContract.canonicalRecord.entries,
        _entry(providerId: 'telepathy'),
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118CreativeConnectorState.fail);
      expect(
        report.violations,
        contains('creative_connector_provider_unknown:telepathy'),
      );
    });

    test('fails when a provider is duplicated', () {
      final entries = <Sprint118CreativeConnectorEntry>[
        ...Sprint118CreativeConnectorContract.canonicalRecord.entries,
        _entry(providerId: 'figma'),
      ];
      final report = _run(_record(entries: entries));
      expect(report.state, Sprint118CreativeConnectorState.fail);
      expect(
        report.violations,
        contains('creative_connector_provider_duplicate:figma'),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _record(
          entries: _replacing(
            'figma',
            _entry(providerId: 'figma', assetRights: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118CreativeConnectorState.fail);
      expect(report.violations, contains('entry_blank_asset_rights:figma'));
    });

    test('fails when a reference state is not grounded by a witness', () {
      final report = _run(
        _record(
          entries: _replacing(
            'figma',
            _entry(providerId: 'figma', assetRights: 'telepathy'),
          ),
        ),
      );
      expect(report.state, Sprint118CreativeConnectorState.fail);
      expect(
        report.violations,
        contains('reference_state_invalid:asset_rights:figma'),
      );
    });

    test('records an open item when a requirement has no reference state', () {
      final report = _run(
        _record(
          entries: _replacing(
            'figma',
            _entry(
              providerId: 'figma',
              assetRights: Sprint118CreativeConnectorContract.noReferenceState,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118CreativeConnectorState.pass);
      expect(
        report.openItems,
        contains('upstream_state_vocabulary_gap:asset_rights:figma'),
      );
    });

    test('fails when the record is not on the delayed path', () {
      final report = _run(_record(releaseState: 'GA_RELEASED'));
      expect(report.state, Sprint118CreativeConnectorState.fail);
      expect(
        report.violations,
        contains('creative_connector_not_on_delayed_path:GA_RELEASED'),
      );
    });

    test('fails when the release state disagrees with the anchor', () {
      final report = _run(
        _record(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'SOMETHING_ELSE'),
      );
      expect(report.state, Sprint118CreativeConnectorState.fail);
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
      expect(report.state, Sprint118CreativeConnectorState.fail);
      expect(
        report.violations,
        contains('creative_connector_execution_authorized_on_delayed_path'),
      );
    });

    test('fails when the release is not blocked on the delayed path', () {
      final report = _run(_record(), anchor: _anchor(releaseBlocked: false));
      expect(report.state, Sprint118CreativeConnectorState.fail);
      expect(
        report.violations,
        contains('creative_connector_release_not_blocked_on_delayed_path'),
      );
    });

    test('fails when a committed evidence source is unreadable', () {
      final report = _run(
        _record(),
        anchor: _anchor(readableSources: const <String>[]),
      );
      expect(report.state, Sprint118CreativeConnectorState.fail);
      expect(
        report.violations.any(
          (v) => v.startsWith('required_source_unreadable:'),
        ),
        isTrue,
      );
    });

    test('the canonical sources cover every requirement', () {
      expect(
        Sprint118CreativeConnectorContract.canonicalSources.length,
        Sprint118CreativeConnectorContract.requiredOutputs.length,
      );
      for (final output in Sprint118CreativeConnectorContract.requiredOutputs) {
        expect(
          Sprint118CreativeConnectorContract.sourceFor(output),
          isNotEmpty,
          reason: '$output must have a committed source',
        );
      }
    });

    test('the loader reads the committed witnesses', () {
      final anchor = const Sprint118CreativeConnectorLoader().loadAnchor();
      expect(anchor, isNotNull);
      expect(anchor!.registeredProviders.length, 32);
      expect(anchor.charterVerdict, 'CHARTER_COMPLETE_LOCAL');
      expect(
        anchor.snapshotVerdict,
        'CERTIFIED_CONNECTOR_SNAPSHOT_FROZEN_LOCAL',
      );
      expect(anchor.approvalDecision, 'delay');
      expect(
        anchor.creativeWorkflowVerdict,
        'CREATIVE_CONNECTOR_WORKFLOW_VALIDATED_LOCAL',
      );
      expect(anchor.readableSources.length, 11);
      expect(anchor.selectedProviderVocabulary, contains('manifest_driven'));
      expect(anchor.assetRightsVocabulary, contains('asset_rights'));
      expect(anchor.attributionVocabulary, contains('attribution'));
      expect(anchor.importVocabulary, contains('import'));
      expect(anchor.exportVocabulary, contains('export'));
      expect(anchor.planLimitsVocabulary, contains('region_plan_limits'));
    });

    test('the gate passes end to end against the committed witnesses', () {
      final report = const Sprint118CreativeConnectorGate().evaluate();
      expect(report.state, Sprint118CreativeConnectorState.pass);
      expect(report.verdict, 'CREATIVE_CONNECTOR_EXPANSION_VERIFIED_LOCAL');
      expect(report.certifiedCount, 0);
      expect(report.selectedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
    });
  });
}
