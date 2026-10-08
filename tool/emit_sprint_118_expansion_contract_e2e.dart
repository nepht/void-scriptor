// Emit the 118.40 Expansion Contract & End-to-End Tests record from the gate's
// own report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_expansion_contract_e2e.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_expansion_contract_e2e.dart';

Map<String, Object?> _entry(Sprint118ExpansionConnectorEntry entry) =>
    <String, Object?>{
      'provider_id': entry.providerId,
      'manifest': entry.manifest,
      'auth': entry.auth,
      'capability': entry.capability,
      'usage': entry.usage,
      'error': entry.error,
      'reauth': entry.reauth,
      'disconnect': entry.disconnect,
      'cleanup': entry.cleanup,
      'regression': entry.regression,
      'connected': entry.connected,
      'used': entry.used,
      'refreshed': entry.refreshed,
      'reauthenticated': entry.reauthenticated,
      'disconnected': entry.disconnected,
      'cleanedUp': entry.cleanedUp,
      'e2ePassed': entry.e2ePassed,
      'certified': entry.certified,
      'released': entry.released,
    };

void main() {
  const gate = Sprint118ExpansionContractGate();
  final report = gate.evaluate();
  final anchor = const Sprint118ExpansionContractLoader().loadAnchor();
  final record = Sprint118ExpansionE2eContract.canonicalRecord;
  final manifest = <String, Object?>{
    'canonical_step': Sprint118ExpansionE2eContract.canonicalStep,
    'title': Sprint118ExpansionE2eContract.title,
    'document_role': 'expansion-contract-e2e-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'contract_verified': report.contractVerified,
    'expansion_budget_frozen': report.expansionBudgetFrozen,
    'required_fields': Sprint118ExpansionE2eContract.requiredFields,
    'required_outputs': Sprint118ExpansionE2eContract.requiredOutputs,
    'expected_provider_count':
        Sprint118ExpansionE2eContract.expectedProviderCount,
    'expected_suite_count': Sprint118ExpansionE2eContract.expectedSuiteCount,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'charter': Sprint118ExpansionE2eContract.charterManifestPath,
      'snapshot': Sprint118ExpansionE2eContract.snapshotManifestPath,
      'approval_gate': Sprint118ExpansionE2eContract.approvalGateManifestPath,
      'icon_registry': Sprint118ExpansionE2eContract.iconRegistryManifestPath,
      'registry_reconciliation':
          Sprint118ExpansionE2eContract.registryReconciliationManifestPath,
      'snapshot_lock': Sprint118ExpansionE2eContract.snapshotLockManifestPath,
      'registry_evidence': Sprint118ExpansionE2eContract.registryEvidencePath,
      'connector_manifest': Sprint118ExpansionE2eContract.connectorManifestPath,
      'oauth_flow': Sprint118ExpansionE2eContract.oauthManifestPath,
      'account_model': Sprint118ExpansionE2eContract.accountModelManifestPath,
      'usage_cost': Sprint118ExpansionE2eContract.usageCostManifestPath,
      'error_state': Sprint118ExpansionE2eContract.errorStateManifestPath,
      'token_expiry': Sprint118ExpansionE2eContract.tokenExpiryManifestPath,
      'connected_accounts':
          Sprint118ExpansionE2eContract.connectedAccountsManifestPath,
      'secret_vault': Sprint118ExpansionE2eContract.secretVaultManifestPath,
      'e2e_matrix': Sprint118ExpansionE2eContract.e2eMatrixManifestPath,
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
    'registry_evidence_provider_count': anchor?.registryEvidenceProviderCount,
    'registry_evidence_exposed': anchor?.registryEvidenceExposed,
    'registry_evidence_withheld': anchor?.registryEvidenceWithheld,
    'snapshot_lock_locked_count': anchor?.snapshotLockLockedCount,
    'approval_decision': anchor?.approvalDecision,
    'approval_state': anchor?.approvalState,
    'execution_authorized': anchor?.executionAuthorized,
    'release_blocked': anchor?.releaseBlocked,
    'registered_provider_count': anchor?.registeredProviders.length,
    'readable_source_count': anchor?.readableSources.length,
    'suite_contract_vocabulary': anchor?.suiteContractVocabulary,
    'manifest_vocabulary': anchor?.manifestVocabulary,
    'auth_vocabulary': anchor?.authVocabulary,
    'capability_vocabulary': anchor?.capabilityVocabulary,
    'usage_vocabulary': anchor?.usageVocabulary,
    'error_vocabulary': anchor?.errorVocabulary,
    'reauth_vocabulary': anchor?.reauthVocabulary,
    'disconnect_vocabulary': anchor?.disconnectVocabulary,
    'cleanup_vocabulary': anchor?.cleanupVocabulary,
    'regression_vocabulary': anchor?.regressionVocabulary,
    'reference_state_vocabulary':
        Sprint118ExpansionE2eContract.stateVocabulary(<List<String>>[
          anchor?.manifestVocabulary ?? const <String>[],
          anchor?.authVocabulary ?? const <String>[],
          anchor?.capabilityVocabulary ?? const <String>[],
          anchor?.usageVocabulary ?? const <String>[],
          anchor?.errorVocabulary ?? const <String>[],
          anchor?.reauthVocabulary ?? const <String>[],
          anchor?.disconnectVocabulary ?? const <String>[],
          anchor?.cleanupVocabulary ?? const <String>[],
          anchor?.regressionVocabulary ?? const <String>[],
        ]),
    'canonical_sources': Sprint118ExpansionE2eContract.canonicalSources,
    'declared_providers': report.declaredProviders,
    'declared_provider_count': report.declaredProviders.length,
    'connected_providers': report.connectedProviders,
    'passed_providers': report.passedProviders,
    'certified_providers': report.certifiedProviders,
    'released_providers': report.releasedProviders,
    'connected_count': report.connectedCount,
    'passed_count': report.passedCount,
    'certified_count': report.certifiedCount,
    'released_count': report.releasedCount,
    'entries': record.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record freezes the local Expansion Contract & End-to-End Tests over the committed 118.2 stability expansion charter, the committed 118.3 certified connector snapshot, the committed 117.45 GA approval gate, the committed 115.8 provider icon registry, the committed 116.3 provider registry reconciliation, the committed 117.4 certification snapshot lock, the committed 117.41 connector-registry evidence, and the committed 115.9/115.11/115.16/116.21/116.15/115.13/115.15/115.12/116.48 suite witnesses. A pass does not connect a connector, use a connector, refresh a token, exercise a provider error, reauthenticate, disconnect, clean up a credential, run an end-to-end suite, certify a connector, or release a connector.',
      'The expansion contract is written against GA_DELAYED. It enumerates all 32 registered providers exactly once, anchors each of the nine canonical suites (manifest, auth, capability, usage, error, reauth, disconnect, cleanup, regression) to a committed witness vocabulary, claims no suite ran, and keeps the expansion budget frozen at zero new certified connectors.',
      'A connector is never recorded as having passed an end-to-end suite without live provider verification and an authorized release: the gate refuses any entry that claims a connected connector, a used connector, a refreshed token, a reauthenticated connector, a disconnected connector, a cleaned-up credential, a passing end-to-end suite, a certified connector, or a released connector on the delayed path, and refuses any expansion budget that is not frozen or any snapshot that certifies a connector.',
      'A registered provider set is never reviewed while drifting: the gate refuses a record that drops a registered provider, invents an unknown provider, or duplicates a provider, and refuses a record whose icon-registry union, 116.3 reconciliation count, frozen snapshot count, charter count, 117.41 registry evidence count, and 117.4 snapshot lock count do not all reconcile to 32, or whose 117.41 registry visibility does not reconcile to 32 with zero exposed.',
      'The nine canonical suites are never invented: the suite set must reconcile against the committed 116.48 connector-contract end-to-end matrix acceptance_suites, and each suite is grounded by the committed witness vocabulary for that suite.',
      'Connector connection, connector use, token refresh, provider error handling, reauthentication, disconnection, credential cleanup, end-to-end suite execution, connector certification, connector release, and publication remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': <String>[
      'connector connection authorization',
      'connector use authorization',
      'token refresh execution',
      'provider error handling',
      'reauthentication execution',
      'disconnection execution',
      'credential cleanup execution',
      'end-to-end suite execution',
      'connector certification',
      'connector release authorization',
      'public release publication',
    ],
  };
  final target = File(Sprint118ExpansionE2eContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('declared_provider_count=${report.declaredProviders.length}');
  stdout.writeln('connected_count=${report.connectedCount}');
  stdout.writeln('passed_count=${report.passedCount}');
  stdout.writeln('certified_count=${report.certifiedCount}');
  stdout.writeln('released_count=${report.releasedCount}');
  stdout.writeln('written=${target.path}');
}
