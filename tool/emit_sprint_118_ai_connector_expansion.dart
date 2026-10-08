// Emit the 118.35 AI Connector Expansion record from the gate's own report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_ai_connector_expansion.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_ai_connector_expansion.dart';

Map<String, Object?> _entry(Sprint118AiConnectorEntry entry) =>
    <String, Object?>{
      'provider_id': entry.providerId,
      'selected_provider': entry.selectedProvider,
      'models': entry.models,
      'usage': entry.usage,
      'cost': entry.cost,
      'privacy_destination': entry.privacyDestination,
      'cancellation': entry.cancellation,
      'fallback': entry.fallback,
      'certified': entry.certified,
      'selected': entry.selected,
      'models_verified': entry.modelsVerified,
      'usage_verified': entry.usageVerified,
      'cost_verified': entry.costVerified,
      'privacy_destination_verified': entry.privacyDestinationVerified,
      'cancellation_verified': entry.cancellationVerified,
      'fallback_verified': entry.fallbackVerified,
      'released': entry.released,
    };

void main() {
  const gate = Sprint118AiConnectorGate();
  final report = gate.evaluate();
  final anchor = const Sprint118AiConnectorLoader().loadAnchor();
  final record = Sprint118AiConnectorContract.canonicalRecord;
  final manifest = <String, Object?>{
    'canonical_step': Sprint118AiConnectorContract.canonicalStep,
    'title': Sprint118AiConnectorContract.title,
    'document_role': 'ai-connector-expansion-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'certification_verified': report.certificationVerified,
    'expansion_budget_frozen': report.expansionBudgetFrozen,
    'required_fields': Sprint118AiConnectorContract.requiredFields,
    'required_outputs': Sprint118AiConnectorContract.requiredOutputs,
    'expected_provider_count':
        Sprint118AiConnectorContract.expectedProviderCount,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'charter': Sprint118AiConnectorContract.charterManifestPath,
      'snapshot': Sprint118AiConnectorContract.snapshotManifestPath,
      'approval_gate': Sprint118AiConnectorContract.approvalGateManifestPath,
      'icon_registry': Sprint118AiConnectorContract.iconRegistryManifestPath,
      'registry_reconciliation':
          Sprint118AiConnectorContract.registryReconciliationManifestPath,
      'ai_provider_health':
          Sprint118AiConnectorContract.aiProviderHealthManifestPath,
      'ai_connection_model_settings':
          Sprint118AiConnectorContract.aiConnectionModelSettingsManifestPath,
      'ai_provider_registry':
          Sprint118AiConnectorContract.aiProviderRegistryManifestPath,
      'openai_connector_certification':
          Sprint118AiConnectorContract.openaiConnectorCertificationManifestPath,
      'ai_usage_cost_reconciliation':
          Sprint118AiConnectorContract.aiUsageCostReconciliationManifestPath,
      'openrouter_connector_certification': Sprint118AiConnectorContract
          .openrouterConnectorCertificationManifestPath,
      'anthropic_connector_certification': Sprint118AiConnectorContract
          .anthropicConnectorCertificationManifestPath,
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
    'ai_health_state': anchor?.aiHealthState,
    'ai_health_verdict': anchor?.aiHealthVerdict,
    'registered_provider_count': anchor?.registeredProviders.length,
    'readable_source_count': anchor?.readableSources.length,
    'selected_provider_vocabulary': anchor?.selectedProviderVocabulary,
    'models_vocabulary': anchor?.modelsVocabulary,
    'usage_vocabulary': anchor?.usageVocabulary,
    'cost_vocabulary': anchor?.costVocabulary,
    'privacy_destination_vocabulary': anchor?.privacyDestinationVocabulary,
    'cancellation_vocabulary': anchor?.cancellationVocabulary,
    'fallback_vocabulary': anchor?.fallbackVocabulary,
    'reference_state_vocabulary':
        Sprint118AiConnectorContract.stateVocabulary(<List<String>>[
          anchor?.selectedProviderVocabulary ?? const <String>[],
          anchor?.modelsVocabulary ?? const <String>[],
          anchor?.usageVocabulary ?? const <String>[],
          anchor?.costVocabulary ?? const <String>[],
          anchor?.privacyDestinationVocabulary ?? const <String>[],
          anchor?.cancellationVocabulary ?? const <String>[],
          anchor?.fallbackVocabulary ?? const <String>[],
        ]),
    'canonical_sources': Sprint118AiConnectorContract.canonicalSources,
    'declared_providers': report.declaredProviders,
    'declared_provider_count': report.declaredProviders.length,
    'certified_providers': report.certifiedProviders,
    'selected_providers': report.selectedProviders,
    'certified_count': report.certifiedCount,
    'selected_count': report.selectedCount,
    'entries': record.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record freezes the local AI Connector Expansion over the committed 118.2 stability expansion charter, the committed 118.3 certified connector snapshot, the committed 117.45 approval gate, the committed 115.8 provider icon registry, the committed 116.3 provider registry reconciliation, the committed 118.11 AI provider health review, the committed 115.25 AI connection & model settings, the committed 115.24 AI provider registry, the committed 116.21 OpenAI connector certification, the committed 116.27 AI usage & cost reconciliation, the committed 116.25 OpenRouter connector certification, and the committed 116.23 Anthropic connector certification. A pass does not select an AI connector, verify a model catalog live, read a live usage, read a live cost, verify a live privacy destination, exercise a live cancellation, exercise a live fallback, access a credential, certify a connector, expose a provider, authorize a release, or publish.',
      'The certification review is written against GA_DELAYED. It enumerates all 32 registered providers exactly once, anchors each of the seven canonical outputs (selected_provider, models, usage, cost, privacy_destination, cancellation, fallback) to a committed witness vocabulary, claims no live certification, and keeps the expansion budget frozen at zero new certified connectors.',
      'A provider is never recorded as a certified AI connector without live provider verification and an authorized release: the gate refuses any entry that claims a certified connector, a selected provider, a live-verified model catalog, a live-verified usage, a live-verified cost, a live-verified privacy destination, a live-verified cancellation, a live-verified fallback, or a released provider on the delayed path, and refuses any expansion budget that is not frozen.',
      'A registered provider set is never reviewed while drifting: the gate refuses a record that drops a registered provider, invents an unknown provider, or duplicates a provider, and refuses a record whose icon-registry union, 116.3 reconciliation count, frozen snapshot count, and charter count do not all reconcile to 32.',
      'A reference state is never invented: each of the seven outputs is grounded by the committed witness vocabulary for that output, so a reference state cannot be recorded without a witness to ground it.',
      'AI connector selection, live model catalog verification, live usage reads, live cost reads, live privacy-destination verification, live cancellation exercises, live fallback exercises, credential access, connector certification, provider exposure, and publication remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': <String>[
      'AI connector selection',
      'live model catalog verification',
      'live usage reads',
      'live cost reads',
      'live privacy-destination verification',
      'live cancellation exercises',
      'live fallback exercises',
      'credential access',
      'connector certification evidence',
      'provider exposure authorization',
      'public release publication',
    ],
  };
  final target = File(Sprint118AiConnectorContract.manifestPath);
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
