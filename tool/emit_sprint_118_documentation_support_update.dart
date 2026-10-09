// Emit the 118.43 Documentation & Support Update record from the gate's own
// report. Run from the repository root:
//   dart run tool/emit_sprint_118_documentation_support_update.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_documentation_support_update.dart';

Map<String, Object?> _entry(Sprint118DocumentationSupportEntry entry) =>
    <String, Object?>{
      'provider_id': entry.providerId,
      'availability_matrix': entry.availabilityMatrix,
      'setup_guides': entry.setupGuides,
      'permissions': entry.permissions,
      'limitations': entry.limitations,
      'quota_notes': entry.quotaNotes,
      'usage_cost_notes': entry.usageCostNotes,
      'recovery': entry.recovery,
      'known_issues': entry.knownIssues,
      'documented': entry.documented,
      'published': entry.published,
      'updated': entry.updated,
      'verified': entry.verified,
      'complete': entry.complete,
      'supported': entry.supported,
      'certified': entry.certified,
      'released': entry.released,
    };

void main() {
  const gate = Sprint118DocumentationSupportGate();
  final report = gate.evaluate();
  final anchor = const Sprint118DocumentationSupportLoader().loadAnchor();
  final record = Sprint118DocumentationSupportContract.canonicalRecord;
  final manifest = <String, Object?>{
    'canonical_step': Sprint118DocumentationSupportContract.canonicalStep,
    'title': Sprint118DocumentationSupportContract.title,
    'document_role': 'documentation-support-update-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'record_verified': report.recordVerified,
    'expansion_budget_frozen': report.expansionBudgetFrozen,
    'required_fields': Sprint118DocumentationSupportContract.requiredFields,
    'required_outputs': Sprint118DocumentationSupportContract.requiredOutputs,
    'expected_provider_count':
        Sprint118DocumentationSupportContract.expectedProviderCount,
    'expected_output_count':
        Sprint118DocumentationSupportContract.expectedOutputCount,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'charter': Sprint118DocumentationSupportContract.charterManifestPath,
      'snapshot': Sprint118DocumentationSupportContract.snapshotManifestPath,
      'approval_gate':
          Sprint118DocumentationSupportContract.approvalGateManifestPath,
      'icon_registry':
          Sprint118DocumentationSupportContract.iconRegistryManifestPath,
      'registry_reconciliation': Sprint118DocumentationSupportContract
          .registryReconciliationManifestPath,
      'snapshot_lock':
          Sprint118DocumentationSupportContract.snapshotLockManifestPath,
      'registry_evidence':
          Sprint118DocumentationSupportContract.registryEvidencePath,
      'availability':
          Sprint118DocumentationSupportContract.availabilityManifestPath,
      'documentation_support':
          Sprint118DocumentationSupportContract.documentationSupportPath,
      'permissions':
          Sprint118DocumentationSupportContract.permissionBoundaryPath,
      'quota_notes': Sprint118DocumentationSupportContract.quotaAdaptersPath,
      'usage_cost_notes':
          Sprint118DocumentationSupportContract.usageCostManifestPath,
      'recovery': Sprint118DocumentationSupportContract.syncBackupRecoveryPath,
      'known_issues':
          Sprint118DocumentationSupportContract.supportDocumentationPath,
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
    'availability_vocabulary': anchor?.availabilityVocabulary,
    'setup_guides_vocabulary': anchor?.setupGuidesVocabulary,
    'permissions_vocabulary': anchor?.permissionsVocabulary,
    'limitations_vocabulary': anchor?.limitationsVocabulary,
    'quota_notes_vocabulary': anchor?.quotaNotesVocabulary,
    'usage_cost_notes_vocabulary': anchor?.usageCostNotesVocabulary,
    'recovery_vocabulary': anchor?.recoveryVocabulary,
    'known_issues_vocabulary': anchor?.knownIssuesVocabulary,
    'reference_state_vocabulary':
        Sprint118DocumentationSupportContract.stateVocabulary(<List<String>>[
          anchor?.availabilityVocabulary ?? const <String>[],
          anchor?.setupGuidesVocabulary ?? const <String>[],
          anchor?.permissionsVocabulary ?? const <String>[],
          anchor?.limitationsVocabulary ?? const <String>[],
          anchor?.quotaNotesVocabulary ?? const <String>[],
          anchor?.usageCostNotesVocabulary ?? const <String>[],
          anchor?.recoveryVocabulary ?? const <String>[],
          anchor?.knownIssuesVocabulary ?? const <String>[],
        ]),
    'canonical_sources': Sprint118DocumentationSupportContract.canonicalSources,
    'declared_providers': report.declaredProviders,
    'declared_provider_count': report.declaredProviders.length,
    'documented_providers': report.documentedProviders,
    'published_providers': report.publishedProviders,
    'updated_providers': report.updatedProviders,
    'verified_providers': report.verifiedProviders,
    'certified_providers': report.certifiedProviders,
    'released_providers': report.releasedProviders,
    'documented_count': report.documentedCount,
    'published_count': report.publishedCount,
    'updated_count': report.updatedCount,
    'verified_count': report.verifiedCount,
    'complete_count': report.completeCount,
    'supported_count': report.supportedCount,
    'certified_count': report.certifiedCount,
    'released_count': report.releasedCount,
    'entries': record.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record freezes the local Documentation & Support Update over the committed 118.2 stability expansion charter, the committed 118.3 certified connector snapshot, the committed 117.45 GA approval gate, the committed 115.8 provider icon registry, the committed 116.3 provider registry reconciliation, the committed 117.4 certification snapshot lock, the committed 117.41 connector-registry evidence, and the committed 114.22/112.51/118.20/115.17/118.35/118.10/114.34 documentation & support witnesses. A pass does not document a connector, publish documentation, update documentation, verify documentation, complete a documentation set, escalate support, certify a connector, or release a connector.',
      'The documentation & support record is written against GA_DELAYED. It enumerates all 32 registered providers exactly once, anchors each of the eight canonical documentation & support dimensions (availability_matrix, setup_guides, permissions, limitations, quota_notes, usage_cost_notes, recovery, known_issues) to a committed witness vocabulary, claims no documentation written and no documentation published, and keeps the expansion budget frozen at zero new certified connectors.',
      'Documentation is never written or published without live evidence and an authorized release: the gate refuses any entry that claims documented documentation, published documentation, updated documentation, verified documentation, a complete documentation set, an active support escalation, a certified connector, or a released connector on the delayed path, and refuses any expansion budget that is not frozen or any snapshot that certifies a connector.',
      'A registered provider set is never reviewed while drifting: the gate refuses a record that drops a registered provider, invents an unknown provider, or duplicates a provider, and refuses a record whose icon-registry union, 116.3 reconciliation count, frozen snapshot count, charter count, 117.41 registry evidence count, and 117.4 snapshot lock count do not all reconcile to 32, or whose 117.41 registry visibility does not reconcile to 32 with zero exposed.',
      'The eight canonical documentation & support dimensions are never invented: each dimension is grounded by the committed witness vocabulary for that dimension (the 114.22 feature availability reconciliation required fields, the 112.51 documentation & support release notes outputs, the 118.20 novel-character permission boundary acceptance, the 115.17 provider quota adapters acceptance, the 118.35 AI connector expansion cost vocabulary, the 118.10 sync/backup/recovery health backup evidence, and the 114.34 support & documentation maintenance outputs).',
      'Documentation publication, support escalation, connector certification, connector release, and publication remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': <String>[
      'documentation publication authorization',
      'documentation update authorization',
      'support escalation authorization',
      'connector certification',
      'connector release authorization',
      'public release publication',
    ],
  };
  final target = File(Sprint118DocumentationSupportContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('declared_provider_count=${report.declaredProviders.length}');
  stdout.writeln('documented_count=${report.documentedCount}');
  stdout.writeln('published_count=${report.publishedCount}');
  stdout.writeln('updated_count=${report.updatedCount}');
  stdout.writeln('verified_count=${report.verifiedCount}');
  stdout.writeln('certified_count=${report.certifiedCount}');
  stdout.writeln('released_count=${report.releasedCount}');
  stdout.writeln('written=${target.path}');
}
