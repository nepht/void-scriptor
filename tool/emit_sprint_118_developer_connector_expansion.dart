// Emit the 118.36 Developer Connector Expansion record from the gate's own report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_developer_connector_expansion.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_developer_connector_expansion.dart';

Map<String, Object?> _entry(Sprint118DeveloperConnectorEntry entry) =>
    <String, Object?>{
      'provider_id': entry.providerId,
      'selected_provider': entry.selectedProvider,
      'scopes': entry.scopes,
      'resources': entry.resources,
      'rate_limits': entry.rateLimits,
      'organization_policy': entry.organizationPolicy,
      'revoke': entry.revoke,
      'audit': entry.audit,
      'certified': entry.certified,
      'selected': entry.selected,
      'scopes_granted': entry.scopesGranted,
      'resources_verified': entry.resourcesVerified,
      'rate_limits_verified': entry.rateLimitsVerified,
      'organization_policy_verified': entry.organizationPolicyVerified,
      'revoke_verified': entry.revokeVerified,
      'audit_verified': entry.auditVerified,
      'released': entry.released,
    };

void main() {
  const gate = Sprint118DeveloperConnectorGate();
  final report = gate.evaluate();
  final anchor = const Sprint118DeveloperConnectorLoader().loadAnchor();
  final record = Sprint118DeveloperConnectorContract.canonicalRecord;
  final manifest = <String, Object?>{
    'canonical_step': Sprint118DeveloperConnectorContract.canonicalStep,
    'title': Sprint118DeveloperConnectorContract.title,
    'document_role': 'developer-connector-expansion-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'certification_verified': report.certificationVerified,
    'expansion_budget_frozen': report.expansionBudgetFrozen,
    'required_fields': Sprint118DeveloperConnectorContract.requiredFields,
    'required_outputs': Sprint118DeveloperConnectorContract.requiredOutputs,
    'expected_provider_count':
        Sprint118DeveloperConnectorContract.expectedProviderCount,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'charter': Sprint118DeveloperConnectorContract.charterManifestPath,
      'snapshot': Sprint118DeveloperConnectorContract.snapshotManifestPath,
      'approval_gate':
          Sprint118DeveloperConnectorContract.approvalGateManifestPath,
      'icon_registry':
          Sprint118DeveloperConnectorContract.iconRegistryManifestPath,
      'registry_reconciliation': Sprint118DeveloperConnectorContract
          .registryReconciliationManifestPath,
      'developer_workflow_validation': Sprint118DeveloperConnectorContract
          .developerWorkflowValidationManifestPath,
      'developer_tools_connections': Sprint118DeveloperConnectorContract
          .developerToolsConnectionsManifestPath,
      'github_developer_certification': Sprint118DeveloperConnectorContract
          .githubDeveloperCertificationManifestPath,
      'gitlab_developer_certification': Sprint118DeveloperConnectorContract
          .gitlabDeveloperCertificationManifestPath,
      'bitbucket_developer_certification': Sprint118DeveloperConnectorContract
          .bitbucketDeveloperCertificationManifestPath,
      'azure_devops_certification': Sprint118DeveloperConnectorContract
          .azureDevopsCertificationManifestPath,
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
    'developer_workflow_status': anchor?.developerWorkflowStatus,
    'developer_workflow_verdict': anchor?.developerWorkflowVerdict,
    'registered_provider_count': anchor?.registeredProviders.length,
    'readable_source_count': anchor?.readableSources.length,
    'selected_provider_vocabulary': anchor?.selectedProviderVocabulary,
    'scopes_vocabulary': anchor?.scopesVocabulary,
    'resources_vocabulary': anchor?.resourcesVocabulary,
    'rate_limits_vocabulary': anchor?.rateLimitsVocabulary,
    'organization_policy_vocabulary': anchor?.organizationPolicyVocabulary,
    'revoke_vocabulary': anchor?.revokeVocabulary,
    'audit_vocabulary': anchor?.auditVocabulary,
    'reference_state_vocabulary':
        Sprint118DeveloperConnectorContract.stateVocabulary(<List<String>>[
          anchor?.selectedProviderVocabulary ?? const <String>[],
          anchor?.scopesVocabulary ?? const <String>[],
          anchor?.resourcesVocabulary ?? const <String>[],
          anchor?.rateLimitsVocabulary ?? const <String>[],
          anchor?.organizationPolicyVocabulary ?? const <String>[],
          anchor?.revokeVocabulary ?? const <String>[],
          anchor?.auditVocabulary ?? const <String>[],
        ]),
    'canonical_sources': Sprint118DeveloperConnectorContract.canonicalSources,
    'declared_providers': report.declaredProviders,
    'declared_provider_count': report.declaredProviders.length,
    'certified_providers': report.certifiedProviders,
    'selected_providers': report.selectedProviders,
    'certified_count': report.certifiedCount,
    'selected_count': report.selectedCount,
    'entries': record.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record freezes the local Developer Connector Expansion over the committed 118.2 stability expansion charter, the committed 118.3 certified connector snapshot, the committed 117.45 approval gate, the committed 115.8 provider icon registry, the committed 116.3 provider registry reconciliation, the committed 117.17 developer connector workflow validation, the committed 115.28 developer tools connections, the committed 116.28 GitHub developer certification, the committed 116.29 GitLab developer certification, the committed 116.30 Bitbucket developer certification, and the committed 116.31 Azure DevOps certification. A pass does not select a developer connector, grant a live scope, verify a live resource access, observe a live rate-limit window, read a live organization policy, exercise a live revocation, read a live audit stream, access a credential, certify a connector, expose a provider, authorize a release, or publish.',
      'The certification review is written against GA_DELAYED. It enumerates all 32 registered providers exactly once, anchors each of the seven canonical outputs (selected_provider, scopes, resources, rate_limits, organization_policy, revoke, audit) to a committed witness vocabulary, claims no live certification, and keeps the expansion budget frozen at zero new certified connectors.',
      'A provider is never recorded as a certified developer connector without live provider verification and an authorized release: the gate refuses any entry that claims a certified connector, a selected provider, a live-granted scope, a live-verified resource access, a live-observed rate-limit window, a live-read organization policy, a live revocation, a live audit stream, or a released provider on the delayed path, and refuses any expansion budget that is not frozen.',
      'A registered provider set is never reviewed while drifting: the gate refuses a record that drops a registered provider, invents an unknown provider, or duplicates a provider, and refuses a record whose icon-registry union, 116.3 reconciliation count, frozen snapshot count, and charter count do not all reconcile to 32.',
      'A reference state is never invented: each of the seven outputs is grounded by the committed witness vocabulary for that output, so a reference state cannot be recorded without a witness to ground it.',
      'Developer connector selection, live scope verification, live resource-access verification, live rate-limit observation, live organization-policy reads, live revocation exercises, live audit reads, credential access, connector certification, provider exposure, and publication remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': <String>[
      'developer connector selection',
      'live scope verification',
      'live resource-access verification',
      'live rate-limit observation',
      'live organization-policy reads',
      'live revocation exercises',
      'live audit reads',
      'credential access',
      'connector certification evidence',
      'provider exposure authorization',
      'public release publication',
    ],
  };
  final target = File(Sprint118DeveloperConnectorContract.manifestPath);
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
