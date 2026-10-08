// Emit the 118.37 Creative Connector Expansion record from the gate's own report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_creative_connector_expansion.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_creative_connector_expansion.dart';

Map<String, Object?> _entry(Sprint118CreativeConnectorEntry entry) =>
    <String, Object?>{
      'provider_id': entry.providerId,
      'selected_provider': entry.selectedProvider,
      'asset_rights': entry.assetRights,
      'attribution': entry.attribution,
      'import': entry.importBoundary,
      'export': entry.exportBoundary,
      'plan_limits': entry.planLimits,
      'certified': entry.certified,
      'selected': entry.selected,
      'asset_rights_verified': entry.assetRightsVerified,
      'attribution_verified': entry.attributionVerified,
      'import_verified': entry.importVerified,
      'export_verified': entry.exportVerified,
      'plan_limits_verified': entry.planLimitsVerified,
      'released': entry.released,
    };

void main() {
  const gate = Sprint118CreativeConnectorGate();
  final report = gate.evaluate();
  final anchor = const Sprint118CreativeConnectorLoader().loadAnchor();
  final record = Sprint118CreativeConnectorContract.canonicalRecord;
  final manifest = <String, Object?>{
    'canonical_step': Sprint118CreativeConnectorContract.canonicalStep,
    'title': Sprint118CreativeConnectorContract.title,
    'document_role': 'creative-connector-expansion-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'certification_verified': report.certificationVerified,
    'expansion_budget_frozen': report.expansionBudgetFrozen,
    'required_fields': Sprint118CreativeConnectorContract.requiredFields,
    'required_outputs': Sprint118CreativeConnectorContract.requiredOutputs,
    'expected_provider_count':
        Sprint118CreativeConnectorContract.expectedProviderCount,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'charter': Sprint118CreativeConnectorContract.charterManifestPath,
      'snapshot': Sprint118CreativeConnectorContract.snapshotManifestPath,
      'approval_gate':
          Sprint118CreativeConnectorContract.approvalGateManifestPath,
      'icon_registry':
          Sprint118CreativeConnectorContract.iconRegistryManifestPath,
      'registry_reconciliation':
          Sprint118CreativeConnectorContract.registryReconciliationManifestPath,
      'creative_workflow_validation': Sprint118CreativeConnectorContract
          .creativeWorkflowValidationManifestPath,
      'creative_tools_connections': Sprint118CreativeConnectorContract
          .creativeToolsConnectionsManifestPath,
      'figma_certification':
          Sprint118CreativeConnectorContract.figmaCertificationManifestPath,
      'adobe_canva_certification': Sprint118CreativeConnectorContract
          .adobeCanvaCertificationManifestPath,
      'blender_sketchfab_certification': Sprint118CreativeConnectorContract
          .blenderSketchfabCertificationManifestPath,
      'creative_asset_rights_verification': Sprint118CreativeConnectorContract
          .creativeAssetRightsVerificationManifestPath,
    },
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_max_new_certified': anchor?.charterMaxNewCertified,
    'charter_currently_certified': anchor?.charterCurrentlyCertified,
    'charter_registered_providers': anchor?.charterRegisteredProviders,
    'snapshot_state': anchor?.snapshotState,
    'snapshot_verdict': anchor?.snapshotVerdict,
    'snapshot_certified': anchor?.snapshotCertified,
    'snapshot_registered': anchor?.snapshotRegistered,
    'registry_expected_count': anchor?.registryExpectedCount,
    'approval_decision': anchor?.approvalDecision,
    'approval_state': anchor?.approvalState,
    'execution_authorized': anchor?.executionAuthorized,
    'release_blocked': anchor?.releaseBlocked,
    'creative_workflow_status': anchor?.creativeWorkflowStatus,
    'creative_workflow_verdict': anchor?.creativeWorkflowVerdict,
    'registered_provider_count': anchor?.registeredProviders.length,
    'readable_source_count': anchor?.readableSources.length,
    'selected_provider_vocabulary': anchor?.selectedProviderVocabulary,
    'asset_rights_vocabulary': anchor?.assetRightsVocabulary,
    'attribution_vocabulary': anchor?.attributionVocabulary,
    'import_vocabulary': anchor?.importVocabulary,
    'export_vocabulary': anchor?.exportVocabulary,
    'plan_limits_vocabulary': anchor?.planLimitsVocabulary,
    'reference_state_vocabulary':
        Sprint118CreativeConnectorContract.stateVocabulary(<List<String>>[
          anchor?.selectedProviderVocabulary ?? const <String>[],
          anchor?.assetRightsVocabulary ?? const <String>[],
          anchor?.attributionVocabulary ?? const <String>[],
          anchor?.importVocabulary ?? const <String>[],
          anchor?.exportVocabulary ?? const <String>[],
          anchor?.planLimitsVocabulary ?? const <String>[],
        ]),
    'canonical_sources': Sprint118CreativeConnectorContract.canonicalSources,
    'declared_providers': report.declaredProviders,
    'declared_provider_count': report.declaredProviders.length,
    'certified_providers': report.certifiedProviders,
    'selected_providers': report.selectedProviders,
    'certified_count': report.certifiedCount,
    'selected_count': report.selectedCount,
    'entries': record.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record freezes the local Creative Connector Expansion over the committed 118.2 stability expansion charter, the committed 118.3 certified connector snapshot, the committed 117.45 approval gate, the committed 115.8 provider icon registry, the committed 116.3 provider registry reconciliation, the committed 117.18 creative connector workflow validation, the committed 115.29 creative tools connections, the committed 116.32 Figma certification, the committed 116.33 Adobe/Canva certification, the committed 116.34 Blender Cloud/Sketchfab certification, and the committed 116.35 creative asset rights verification. A pass does not select a creative connector, verify a live asset right, verify a live attribution, execute a live asset import, execute a live asset export, read a live plan limit, access a credential, certify a connector, expose a provider, authorize a release, or publish.',
      'The certification review is written against GA_DELAYED. It enumerates all 32 registered providers exactly once, anchors each of the six canonical outputs (selected_provider, asset_rights, attribution, import, export, plan_limits) to a committed witness vocabulary, claims no live certification, and keeps the expansion budget frozen at zero new certified connectors.',
      'A provider is never recorded as a certified creative connector without live provider verification and an authorized release: the gate refuses any entry that claims a certified connector, a selected provider, a live-verified asset right, a live-verified attribution, a live asset import, a live asset export, a live plan limit, or a released provider on the delayed path, and refuses any expansion budget that is not frozen.',
      'A registered provider set is never reviewed while drifting: the gate refuses a record that drops a registered provider, invents an unknown provider, or duplicates a provider, and refuses a record whose icon-registry union, 116.3 reconciliation count, frozen snapshot count, and charter count do not all reconcile to 32.',
      'A reference state is never invented: each of the six outputs is grounded by the committed witness vocabulary for that output, so a reference state cannot be recorded without a witness to ground it.',
      'Creative connector selection, live asset-rights verification, live attribution verification, live asset import, live asset export, live plan-limit reads, credential access, connector certification, provider exposure, and publication remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': <String>[
      'creative connector selection',
      'live asset-rights verification',
      'live attribution verification',
      'live asset import',
      'live asset export',
      'live plan-limit reads',
      'credential access',
      'connector certification evidence',
      'provider exposure authorization',
      'public release publication',
    ],
  };
  final target = File(Sprint118CreativeConnectorContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('declared_provider_count=${report.declaredProviders.length}');
  stdout.writeln('certified_count=${report.certifiedCount}');
  stdout.writeln('selected_count=${report.selectedCount}');
  stdout.writeln('written=${target.path}');
}
