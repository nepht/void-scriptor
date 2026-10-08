// Emit the 118.34 Storage Connector Expansion record from the gate's own
// report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_storage_connector_expansion.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_storage_connector_expansion.dart';

Map<String, Object?> _entry(Sprint118StorageConnectorEntry entry) =>
    <String, Object?>{
      'provider_id': entry.providerId,
      'selected_provider': entry.selectedProvider,
      'storage_contract': entry.storageContract,
      'quota': entry.quota,
      'delta': entry.delta,
      'conflict': entry.conflict,
      'backup': entry.backup,
      'restore': entry.restore,
      'certified': entry.certified,
      'selected': entry.selected,
      'quota_verified': entry.quotaVerified,
      'delta_verified': entry.deltaVerified,
      'conflict_resolved': entry.conflictResolved,
      'backup_verified': entry.backupVerified,
      'restore_verified': entry.restoreVerified,
      'released': entry.released,
    };

void main() {
  const gate = Sprint118StorageConnectorGate();
  final report = gate.evaluate();
  final anchor = const Sprint118StorageConnectorLoader().loadAnchor();
  final record = Sprint118StorageConnectorContract.canonicalRecord;
  final manifest = <String, Object?>{
    'canonical_step': Sprint118StorageConnectorContract.canonicalStep,
    'title': Sprint118StorageConnectorContract.title,
    'document_role': 'storage-connector-expansion-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'certification_verified': report.certificationVerified,
    'expansion_budget_frozen': report.expansionBudgetFrozen,
    'required_fields': Sprint118StorageConnectorContract.requiredFields,
    'required_outputs': Sprint118StorageConnectorContract.requiredOutputs,
    'expected_provider_count':
        Sprint118StorageConnectorContract.expectedProviderCount,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'charter': Sprint118StorageConnectorContract.charterManifestPath,
      'snapshot': Sprint118StorageConnectorContract.snapshotManifestPath,
      'approval_gate':
          Sprint118StorageConnectorContract.approvalGateManifestPath,
      'icon_registry':
          Sprint118StorageConnectorContract.iconRegistryManifestPath,
      'registry_reconciliation':
          Sprint118StorageConnectorContract.registryReconciliationManifestPath,
      'storage_quota_validation':
          Sprint118StorageConnectorContract.storageQuotaValidationManifestPath,
      'cloud_storage_account_model': Sprint118StorageConnectorContract
          .cloudStorageAccountModelManifestPath,
      'provider_quota_adapters':
          Sprint118StorageConnectorContract.providerQuotaAdaptersManifestPath,
      'cloud_transfer_sync_controls': Sprint118StorageConnectorContract
          .cloudTransferSyncControlsManifestPath,
      'sync_conflict_center':
          Sprint118StorageConnectorContract.syncConflictCenterManifestPath,
      'backup_policies_destinations': Sprint118StorageConnectorContract
          .backupPoliciesDestinationsManifestPath,
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
    'storage_quota_status': anchor?.storageQuotaStatus,
    'storage_quota_verdict': anchor?.storageQuotaVerdict,
    'registered_provider_count': anchor?.registeredProviders.length,
    'readable_source_count': anchor?.readableSources.length,
    'selected_provider_vocabulary': anchor?.selectedProviderVocabulary,
    'storage_contract_vocabulary': anchor?.storageContractVocabulary,
    'quota_vocabulary': anchor?.quotaVocabulary,
    'delta_vocabulary': anchor?.deltaVocabulary,
    'conflict_vocabulary': anchor?.conflictVocabulary,
    'backup_vocabulary': anchor?.backupVocabulary,
    'restore_vocabulary': anchor?.restoreVocabulary,
    'reference_state_vocabulary':
        Sprint118StorageConnectorContract.stateVocabulary(<List<String>>[
          anchor?.selectedProviderVocabulary ?? const <String>[],
          anchor?.storageContractVocabulary ?? const <String>[],
          anchor?.quotaVocabulary ?? const <String>[],
          anchor?.deltaVocabulary ?? const <String>[],
          anchor?.conflictVocabulary ?? const <String>[],
          anchor?.backupVocabulary ?? const <String>[],
          anchor?.restoreVocabulary ?? const <String>[],
        ]),
    'canonical_sources': Sprint118StorageConnectorContract.canonicalSources,
    'declared_providers': report.declaredProviders,
    'declared_provider_count': report.declaredProviders.length,
    'certified_providers': report.certifiedProviders,
    'selected_providers': report.selectedProviders,
    'certified_count': report.certifiedCount,
    'selected_count': report.selectedCount,
    'entries': record.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record freezes the local Storage Connector Expansion over the committed 118.2 stability expansion charter, the committed 118.3 certified connector snapshot, the committed 117.45 approval gate, the committed 115.8 provider icon registry, the committed 116.3 provider registry reconciliation, the committed 117 cloud storage quota validation, the committed 115.16 cloud storage account model, the committed 115.17 provider quota adapters, the committed 115.21 cloud transfer & sync controls, the committed 115.23 sync conflict center, and the committed 115.22 backup policies & destinations. A pass does not select a storage connector, verify a storage contract live, read a live quota, run a live delta sync, resolve a live conflict, verify a live backup, verify a live restore, access a credential, certify a connector, expose a provider, authorize a release, or publish.',
      'The certification review is written against GA_DELAYED. It enumerates all 32 registered providers exactly once, anchors each of the seven canonical outputs (selected_provider, storage_contract, quota, delta, conflict, backup, restore) to a committed witness vocabulary, claims no live certification, and keeps the expansion budget frozen at zero new certified connectors.',
      'A provider is never recorded as a certified storage connector without live provider verification and an authorized release: the gate refuses any entry that claims a certified connector, a selected provider, a live-verified quota, a live-verified delta sync, a resolved conflict, a verified backup, a verified restore, or a released provider on the delayed path, and refuses any expansion budget that is not frozen.',
      'A registered provider set is never reviewed while drifting: the gate refuses a record that drops a registered provider, invents an unknown provider, or duplicates a provider, and refuses a record whose icon-registry union, 116.3 reconciliation count, frozen snapshot count, and charter count do not all reconcile to 32.',
      'A reference state is never invented: each of the seven outputs is grounded by the committed witness vocabulary for that output, so a reference state cannot be recorded without a witness to ground it.',
      'Storage connector selection, live storage-contract verification, live quota reads, live delta sync, live conflict resolution, live backup verification, live restore verification, credential access, connector certification, provider exposure, and publication remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': <String>[
      'storage connector selection',
      'live storage-contract verification',
      'live quota reads',
      'live delta sync execution',
      'live conflict resolution',
      'live backup verification',
      'live restore verification',
      'credential access',
      'connector certification evidence',
      'provider exposure authorization',
      'public release publication',
    ],
  };
  final target = File(Sprint118StorageConnectorContract.manifestPath);
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
