// Emit the 118.30 Expansion Prioritization record from the gate's own report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_expansion_prioritization.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_expansion_prioritization.dart';

Map<String, Object?> _entry(Sprint118ExpansionPriorityEntry entry) =>
    <String, Object?>{
      'provider_id': entry.providerId,
      'user_value': entry.userValue,
      'evidence_strength': entry.evidenceStrength,
      'feasibility': entry.feasibility,
      'risk': entry.risk,
      'maintenance': entry.maintenance,
      'support_cost': entry.supportCost,
      'strategic_fit': entry.strategicFit,
      'prioritized': entry.prioritized,
      'ranked': entry.ranked,
      'recommended': entry.recommended,
      'certified': entry.certified,
      'released': entry.released,
    };

void main() {
  const gate = Sprint118ExpansionPriorityGate();
  final report = gate.evaluate();
  final anchor = const Sprint118ExpansionPriorityLoader().loadAnchor();
  final record = Sprint118ExpansionPriorityContract.canonicalRecord;
  final manifest = <String, Object?>{
    'canonical_step': Sprint118ExpansionPriorityContract.canonicalStep,
    'title': Sprint118ExpansionPriorityContract.title,
    'document_role': 'expansion-prioritization-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'prioritization_verified': report.prioritizationVerified,
    'expansion_budget_frozen': report.expansionBudgetFrozen,
    'required_fields': Sprint118ExpansionPriorityContract.requiredFields,
    'required_criteria': Sprint118ExpansionPriorityContract.requiredCriteria,
    'expected_provider_count':
        Sprint118ExpansionPriorityContract.expectedProviderCount,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'charter': Sprint118ExpansionPriorityContract.charterManifestPath,
      'snapshot': Sprint118ExpansionPriorityContract.snapshotManifestPath,
      'approval_gate':
          Sprint118ExpansionPriorityContract.approvalGateManifestPath,
      'icon_registry':
          Sprint118ExpansionPriorityContract.iconRegistryManifestPath,
      'registry_reconciliation':
          Sprint118ExpansionPriorityContract.registryReconciliationManifestPath,
      'feedback_log':
          Sprint118ExpansionPriorityContract.feedbackLogManifestPath,
      'expansion_inventory':
          Sprint118ExpansionPriorityContract.expansionInventoryManifestPath,
      'external_dependency':
          Sprint118ExpansionPriorityContract.externalDependencyManifestPath,
      'technical_debt':
          Sprint118ExpansionPriorityContract.technicalDebtManifestPath,
      'support_readiness':
          Sprint118ExpansionPriorityContract.supportReadinessManifestPath,
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
    'user_value_vocabulary': anchor?.userValueVocabulary,
    'evidence_strength_vocabulary': anchor?.evidenceStrengthVocabulary,
    'feasibility_vocabulary': anchor?.feasibilityVocabulary,
    'risk_vocabulary': anchor?.charterStopMetrics,
    'maintenance_vocabulary': anchor?.maintenanceVocabulary,
    'support_cost_vocabulary': anchor?.supportCostVocabulary,
    'strategic_fit_vocabulary': anchor?.charterStrategicAreas,
    'reference_state_vocabulary':
        Sprint118ExpansionPriorityContract.stateVocabulary(<List<String>>[
          anchor?.userValueVocabulary ?? const <String>[],
          anchor?.evidenceStrengthVocabulary ?? const <String>[],
          anchor?.feasibilityVocabulary ?? const <String>[],
          anchor?.charterStopMetrics ?? const <String>[],
          anchor?.maintenanceVocabulary ?? const <String>[],
          anchor?.supportCostVocabulary ?? const <String>[],
          anchor?.charterStrategicAreas ?? const <String>[],
        ]),
    'canonical_sources': Sprint118ExpansionPriorityContract.canonicalSources,
    'declared_providers': report.declaredProviders,
    'declared_provider_count': report.declaredProviders.length,
    'selected_providers': report.selectedProviders,
    'prioritized_count': report.prioritizedCount,
    'ranked_count': report.rankedCount,
    'recommended_count': report.recommendedCount,
    'entries': record.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record freezes the local Expansion Prioritization over the committed 118.2 stability expansion charter, the committed 118.3 certified connector snapshot, the committed 117.45 approval gate, the committed 115.8 provider icon registry, the committed 116.3 provider registry reconciliation, the committed 118.21 feedback & adoption evidence log, the committed 118.29 provider expansion evidence inventory, the committed 114.25 external dependency health, the committed 114.42 technical debt & deferred risk register, and the committed 117.6 support incident readiness. A pass does not certify a connector, expose a provider, probe an endpoint, measure demand, read cost or quota, access a credential, authorize a release, prioritize a provider, rank a provider, recommend a provider, or publish.',
      'The prioritization is written against GA_DELAYED. It enumerates all 32 registered providers exactly once, anchors each of the seven canonical criteria (user_value, evidence_strength, feasibility, risk, maintenance, support_cost, strategic_fit) to a committed witness vocabulary, selects no expansion candidate, ranks no provider, recommends no provider, claims no certified connector and no released provider, and keeps the expansion budget frozen at zero new certified connectors.',
      'A provider is never recorded as an expansion priority without committed certification evidence and an authorized release: the gate refuses any entry that selects a provider as a priority, ranks a provider, recommends a provider, claims a certified connector, or claims a released provider on the delayed path, and refuses any expansion budget that is not frozen.',
      'A registered provider set is never prioritized while drifting: the gate refuses a record that drops a registered provider, invents an unknown provider, or duplicates a provider, and refuses a record whose icon-registry union, 116.3 reconciliation count, frozen snapshot count, and charter count do not all reconcile to 32.',
      'A priority value is never invented: each of the seven criteria is grounded by the committed witness vocabulary for that criterion, so a reference state cannot be recorded without a witness to ground it.',
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
  final target = File(Sprint118ExpansionPriorityContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('declared_provider_count=${report.declaredProviders.length}');
  stdout.writeln('selected_provider_count=${report.selectedProviders.length}');
  stdout.writeln('written=${target.path}');
}
