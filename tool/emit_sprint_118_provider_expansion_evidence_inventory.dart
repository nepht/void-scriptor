// Emit the 118.29 Provider Expansion Evidence Inventory record from the gate's
// own report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_provider_expansion_evidence_inventory.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_provider_expansion_evidence_inventory.dart';

Map<String, Object?> _entry(Sprint118ExpansionEvidenceEntry entry) =>
    <String, Object?>{
      'provider_id': entry.providerId,
      'demand_evidence': entry.demandEvidence,
      'workflow_value': entry.workflowValue,
      'api_feasibility': entry.apiFeasibility,
      'maintenance_cost': entry.maintenanceCost,
      'security': entry.security,
      'privacy': entry.privacy,
      'region_constraints': entry.regionConstraints,
      'certified': entry.certified,
      'available': entry.available,
      'demanded': entry.demanded,
      'observed': entry.observed,
      'released': entry.released,
    };

void main() {
  const gate = Sprint118ExpansionEvidenceGate();
  final report = gate.evaluate();
  final anchor = const Sprint118ExpansionEvidenceLoader().loadAnchor();
  final record = Sprint118ExpansionEvidenceContract.canonicalRecord;
  final manifest = <String, Object?>{
    'canonical_step': Sprint118ExpansionEvidenceContract.canonicalStep,
    'title': Sprint118ExpansionEvidenceContract.title,
    'document_role': 'provider-expansion-evidence-inventory-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'inventory_verified': report.inventoryVerified,
    'expansion_budget_frozen': report.expansionBudgetFrozen,
    'required_fields': Sprint118ExpansionEvidenceContract.requiredFields,
    'required_dimensions':
        Sprint118ExpansionEvidenceContract.requiredDimensions,
    'expected_provider_count':
        Sprint118ExpansionEvidenceContract.expectedProviderCount,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'charter': Sprint118ExpansionEvidenceContract.charterManifestPath,
      'snapshot': Sprint118ExpansionEvidenceContract.snapshotManifestPath,
      'approval_gate':
          Sprint118ExpansionEvidenceContract.approvalGateManifestPath,
      'icon_registry':
          Sprint118ExpansionEvidenceContract.iconRegistryManifestPath,
      'registry_reconciliation':
          Sprint118ExpansionEvidenceContract.registryReconciliationManifestPath,
      'feedback_log':
          Sprint118ExpansionEvidenceContract.feedbackLogManifestPath,
      'external_dependency':
          Sprint118ExpansionEvidenceContract.externalDependencyManifestPath,
      'quota_adapters':
          Sprint118ExpansionEvidenceContract.quotaAdaptersManifestPath,
      'privacy_review':
          Sprint118ExpansionEvidenceContract.privacyReviewManifestPath,
      'security_verification':
          Sprint118ExpansionEvidenceContract.securityVerificationManifestPath,
      'error_state': Sprint118ExpansionEvidenceContract.errorStateManifestPath,
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
    'registered_provider_count': anchor?.registeredProviders.length,
    'readable_source_count': anchor?.readableSources.length,
    'demand_vocabulary': anchor?.demandOutcomes,
    'workflow_vocabulary': anchor?.workflows,
    'api_feasibility_vocabulary': anchor?.dependencySignals,
    'maintenance_cost_vocabulary': anchor?.costAcceptance,
    'security_vocabulary': anchor?.securityOutputs,
    'privacy_vocabulary': anchor?.privacySubjects,
    'region_constraints_vocabulary': anchor?.feasibilityStates,
    'reference_state_vocabulary':
        Sprint118ExpansionEvidenceContract.stateVocabulary(<List<String>>[
          anchor?.demandOutcomes ?? const <String>[],
          anchor?.workflows ?? const <String>[],
          anchor?.dependencySignals ?? const <String>[],
          anchor?.costAcceptance ?? const <String>[],
          anchor?.securityOutputs ?? const <String>[],
          anchor?.privacySubjects ?? const <String>[],
          anchor?.feasibilityStates ?? const <String>[],
        ]),
    'canonical_sources': Sprint118ExpansionEvidenceContract.canonicalSources,
    'declared_providers': report.declaredProviders,
    'declared_provider_count': report.declaredProviders.length,
    'observed_count': report.observedCount,
    'certified_count': report.certifiedCount,
    'entries': record.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record freezes the local Provider Expansion Evidence Inventory over the committed 118.2 stability expansion charter, the committed 118.3 certified connector snapshot, the committed 117.45 approval gate, the committed 115.8 provider icon registry, the committed 116.3 provider registry reconciliation, the committed 118.21 feedback & adoption evidence log, the committed 114.25 external dependency health, the committed 115.17 quota adapters, the committed 115.50 privacy data-flow review, the committed 115.54 security verification, and the committed 116.42 provider error-state certification. A pass does not certify a connector, expose a provider, probe an endpoint, measure demand, read cost or quota, access a credential, authorize a release, or publish.',
      'The inventory is written against GA_DELAYED. It enumerates all 32 registered providers exactly once, anchors each of the seven canonical evidence dimensions (demand_evidence, workflow_value, api_feasibility, maintenance_cost, security, privacy, region_constraints) to a committed witness vocabulary, claims no certified connector, no available endpoint, no measured demand, no live observation, and no released provider, and keeps the expansion budget frozen at zero new certified connectors.',
      'A provider is never recorded as expansion-ready without committed certification evidence and an authorized release: the gate refuses any entry that claims a certified connector, an available endpoint, a measured demand, a live observation, or a released provider on the delayed path, and refuses any expansion budget that is not frozen.',
      'A registered provider set is never inventoried while drifting: the gate refuses a record that drops a registered provider, invents an unknown provider, or duplicates a provider, and refuses a record whose icon-registry union, 116.3 reconciliation count, frozen snapshot count, and charter count do not all reconcile to 32.',
      'An evidence value is never invented: each of the seven dimensions is grounded by the committed witness vocabulary for that dimension, so a reference state cannot be recorded without a witness to ground it.',
      'Connector certification, provider exposure, live availability, live demand, cost and quota reads, credential access, and publication remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': <String>[
      'connector certification evidence',
      'provider exposure authorization',
      'live provider availability',
      'live demand measurement',
      'cost and quota reads',
      'credential access',
      'public release publication',
    ],
  };
  final target = File(Sprint118ExpansionEvidenceContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('declared_provider_count=${report.declaredProviders.length}');
  stdout.writeln('written=${target.path}');
}
