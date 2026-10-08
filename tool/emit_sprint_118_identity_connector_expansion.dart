// Emit the 118.33 Identity Connector Expansion record from the gate's own
// report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_identity_connector_expansion.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_identity_connector_expansion.dart';

Map<String, Object?> _entry(Sprint118IdentityConnectorEntry entry) =>
    <String, Object?>{
      'provider_id': entry.providerId,
      'selected_provider': entry.selectedProvider,
      'auth_contract': entry.authContract,
      'minimum_scopes': entry.minimumScopes,
      'collision_tests': entry.collisionTests,
      'revoke': entry.revoke,
      'security_review': entry.securityReview,
      'certified': entry.certified,
      'selected': entry.selected,
      'connectable': entry.connectable,
      'scopes_granted': entry.scopesGranted,
      'takeover_protection_verified': entry.takeoverProtectionVerified,
      'released': entry.released,
    };

void main() {
  const gate = Sprint118IdentityConnectorGate();
  final report = gate.evaluate();
  final anchor = const Sprint118IdentityConnectorLoader().loadAnchor();
  final record = Sprint118IdentityConnectorContract.canonicalRecord;
  final manifest = <String, Object?>{
    'canonical_step': Sprint118IdentityConnectorContract.canonicalStep,
    'title': Sprint118IdentityConnectorContract.title,
    'document_role': 'identity-connector-expansion-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'certification_verified': report.certificationVerified,
    'expansion_budget_frozen': report.expansionBudgetFrozen,
    'required_fields': Sprint118IdentityConnectorContract.requiredFields,
    'required_outputs': Sprint118IdentityConnectorContract.requiredOutputs,
    'expected_provider_count':
        Sprint118IdentityConnectorContract.expectedProviderCount,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'charter': Sprint118IdentityConnectorContract.charterManifestPath,
      'snapshot': Sprint118IdentityConnectorContract.snapshotManifestPath,
      'approval_gate':
          Sprint118IdentityConnectorContract.approvalGateManifestPath,
      'icon_registry':
          Sprint118IdentityConnectorContract.iconRegistryManifestPath,
      'registry_reconciliation':
          Sprint118IdentityConnectorContract.registryReconciliationManifestPath,
      'identity_workflow_validation': Sprint118IdentityConnectorContract
          .identityWorkflowValidationManifestPath,
      'oauth_linked_identity_flow': Sprint118IdentityConnectorContract
          .oauthLinkedIdentityFlowManifestPath,
      'identity_linking_collision': Sprint118IdentityConnectorContract
          .identityLinkingCollisionManifestPath,
      'security_certification_gate': Sprint118IdentityConnectorContract
          .securityCertificationGateManifestPath,
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
    'identity_workflow_status': anchor?.identityWorkflowStatus,
    'identity_workflow_verdict': anchor?.identityWorkflowVerdict,
    'registered_provider_count': anchor?.registeredProviders.length,
    'readable_source_count': anchor?.readableSources.length,
    'selected_provider_vocabulary': anchor?.selectedProviderVocabulary,
    'auth_contract_vocabulary': anchor?.authContractVocabulary,
    'minimum_scopes_vocabulary': anchor?.minimumScopesVocabulary,
    'collision_tests_vocabulary': anchor?.collisionTestsVocabulary,
    'revoke_vocabulary': anchor?.revokeVocabulary,
    'security_review_vocabulary': anchor?.securityReviewVocabulary,
    'reference_state_vocabulary':
        Sprint118IdentityConnectorContract.stateVocabulary(<List<String>>[
          anchor?.selectedProviderVocabulary ?? const <String>[],
          anchor?.authContractVocabulary ?? const <String>[],
          anchor?.minimumScopesVocabulary ?? const <String>[],
          anchor?.collisionTestsVocabulary ?? const <String>[],
          anchor?.revokeVocabulary ?? const <String>[],
          anchor?.securityReviewVocabulary ?? const <String>[],
        ]),
    'canonical_sources': Sprint118IdentityConnectorContract.canonicalSources,
    'declared_providers': report.declaredProviders,
    'declared_provider_count': report.declaredProviders.length,
    'certified_providers': report.certifiedProviders,
    'selected_providers': report.selectedProviders,
    'certified_count': report.certifiedCount,
    'selected_count': report.selectedCount,
    'entries': record.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record freezes the local Identity Connector Expansion over the committed 118.2 stability expansion charter, the committed 118.3 certified connector snapshot, the committed 117.45 approval gate, the committed 115.8 provider icon registry, the committed 116.3 provider registry reconciliation, the committed 117.12 identity workflow validation, the committed 115.11 OAuth linked identity flow, the committed 116.14 identity linking & collision, and the committed 116.45 security certification gate. A pass does not select an identity connector, verify an auth contract live, grant a minimum scope, run a collision test against a live provider, execute a provider revocation, verify a live connector, access a credential, certify a connector, expose a provider, authorize a release, or publish.',
      'The certification review is written against GA_DELAYED. It enumerates all 32 registered providers exactly once, anchors each of the six canonical outputs (selected_provider, auth_contract, minimum_scopes, collision_tests, revoke, security_review) to a committed witness vocabulary, claims no live certification, and keeps the expansion budget frozen at zero new certified connectors.',
      'A provider is never recorded as a certified identity connector without live provider verification and an authorized release: the gate refuses any entry that claims a certified connector, a selected provider, a connectable connector, a granted minimum scope, a live-verified takeover protection, or a released provider on the delayed path, and refuses any expansion budget that is not frozen.',
      'A registered provider set is never reviewed while drifting: the gate refuses a record that drops a registered provider, invents an unknown provider, or duplicates a provider, and refuses a record whose icon-registry union, 116.3 reconciliation count, frozen snapshot count, and charter count do not all reconcile to 32.',
      'A reference state is never invented: each of the six outputs is grounded by the committed witness vocabulary for that output, so a reference state cannot be recorded without a witness to ground it.',
      'Identity connector selection, live auth-contract verification, live minimum scope grants, live collision tests, provider revocation, live security review, credential access, connector certification, provider exposure, and publication remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': <String>[
      'identity connector selection',
      'live auth-contract verification',
      'live minimum scope grants',
      'live collision tests',
      'provider revocation execution',
      'live security review',
      'credential access',
      'connector certification evidence',
      'provider exposure authorization',
      'public release publication',
    ],
  };
  final target = File(Sprint118IdentityConnectorContract.manifestPath);
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
