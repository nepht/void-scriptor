// Emit the 118.39 Versioned Connector Certification record from the gate's own
// report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_versioned_connector_certification.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_versioned_connector_certification.dart';
import 'package:void_scriptor/features/world_logic/domain/github_app_release_authorization.dart';

Map<String, Object?> _entry(Sprint118VersionedConnectorEntry entry) =>
    <String, Object?>{
      'provider_id': entry.providerId,
      'connector_version': entry.connectorVersion,
      'status': entry.status,
      'evidence': entry.evidence,
      'limitations': entry.limitations,
      'reviewer': entry.reviewer,
      'recheck_date': entry.recheckDate,
      'visibility': entry.visibility,
      'certified': entry.certified,
      'verified': entry.verified,
      'reviewed': entry.reviewed,
      'exposed': entry.exposed,
      'released': entry.released,
      'published': entry.published,
    };

void main() {
  const gate = Sprint118VersionedCertificationGate();
  final report = gate.evaluate();
  final authorization = GithubAppReleaseAuthorization.load();
  final anchor = const Sprint118VersionedCertificationLoader().loadAnchor();
  final record = authorization == null
      ? Sprint118VersionedCertificationContract.canonicalRecord
      : Sprint118VersionedCertificationContract.authorizedRecord;
  final manifest = <String, Object?>{
    'canonical_step': Sprint118VersionedCertificationContract.canonicalStep,
    'title': Sprint118VersionedCertificationContract.title,
    'document_role': 'versioned-connector-certification-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'certification_verified': report.certificationVerified,
    'expansion_budget_frozen': report.expansionBudgetFrozen,
    'required_fields': Sprint118VersionedCertificationContract.requiredFields,
    'required_outputs': Sprint118VersionedCertificationContract.requiredOutputs,
    'expected_provider_count':
        Sprint118VersionedCertificationContract.expectedProviderCount,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'charter': Sprint118VersionedCertificationContract.charterManifestPath,
      'snapshot': Sprint118VersionedCertificationContract.snapshotManifestPath,
      'approval_gate':
          Sprint118VersionedCertificationContract.approvalGateManifestPath,
      'icon_registry':
          Sprint118VersionedCertificationContract.iconRegistryManifestPath,
      'registry_reconciliation': Sprint118VersionedCertificationContract
          .registryReconciliationManifestPath,
      'certification_policy': Sprint118VersionedCertificationContract
          .certificationPolicyManifestPath,
      'snapshot_lock':
          Sprint118VersionedCertificationContract.snapshotLockManifestPath,
      'registry_evidence':
          Sprint118VersionedCertificationContract.registryEvidencePath,
      'operator_authorization': GithubAppReleaseAuthorization.manifestPath,
      'live_certification_example': GithubAppReleaseAuthorization.evidencePath,
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
    'approval_decision': authorization == null
        ? anchor?.approvalDecision
        : 'release',
    'approval_state': authorization == null
        ? anchor?.approvalState
        : 'APPROVED_CHOIRUDIN',
    'execution_authorized': authorization?.isValid == true
        ? true
        : anchor?.executionAuthorized,
    'release_blocked': authorization?.isValid == true
        ? false
        : anchor?.releaseBlocked,
    'operator_authorization_valid': authorization?.isValid ?? false,
    'registered_provider_count': anchor?.registeredProviders.length,
    'readable_source_count': anchor?.readableSources.length,
    'connector_version_vocabulary': anchor?.connectorVersionVocabulary,
    'status_vocabulary': anchor?.statusVocabulary,
    'evidence_vocabulary': anchor?.evidenceVocabulary,
    'limitations_vocabulary': anchor?.limitationsVocabulary,
    'reviewer_vocabulary': anchor?.reviewerVocabulary,
    'recheck_date_vocabulary': anchor?.recheckDateVocabulary,
    'visibility_vocabulary': anchor?.visibilityVocabulary,
    'reference_state_vocabulary':
        Sprint118VersionedCertificationContract.stateVocabulary(<List<String>>[
          anchor?.connectorVersionVocabulary ?? const <String>[],
          anchor?.statusVocabulary ?? const <String>[],
          anchor?.evidenceVocabulary ?? const <String>[],
          anchor?.limitationsVocabulary ?? const <String>[],
          anchor?.reviewerVocabulary ?? const <String>[],
          anchor?.recheckDateVocabulary ?? const <String>[],
          anchor?.visibilityVocabulary ?? const <String>[],
        ]),
    'canonical_sources':
        Sprint118VersionedCertificationContract.canonicalSources,
    'declared_providers': report.declaredProviders,
    'declared_provider_count': report.declaredProviders.length,
    'certified_providers': report.certifiedProviders,
    'exposed_providers': report.exposedProviders,
    'released_providers': report.releasedProviders,
    'certified_count': report.certifiedCount,
    'exposed_count': report.exposedCount,
    'released_count': report.releasedCount,
    'entries': record.entries.map(_entry).toList(),
    'claim_boundary': authorization == null
        ? <String>[
            'This record freezes the local Versioned Connector Certification over the committed 118.2 stability expansion charter, the committed 118.3 certified connector snapshot, the committed 117.45 GA approval gate, the committed 115.8 provider icon registry, the committed 116.3 provider registry reconciliation, the committed 116.2 certification policy, the committed 117.4 certification snapshot lock, and the committed 117.41 connector-registry evidence. A pass does not certify a connector, verify live evidence, perform a live review, expose a provider, release a connector, access a credential, or publish.',
            'The certification record is written against GA_DELAYED. It enumerates all 32 registered providers exactly once, anchors each of the seven canonical outputs (connector_version, status, evidence, limitations, reviewer, recheck_date, visibility) to a committed witness vocabulary, claims no live certification, and keeps the expansion budget frozen at zero new certified connectors.',
            'A provider is never recorded as a versioned certified connector without live provider verification and an authorized release: the gate refuses any entry that claims a certified connector, a live-verified evidence record, a live review, an exposed connector, a released connector, or a published connector on the delayed path, refuses a CERTIFIED or LIMITED status, refuses an EXPOSED visibility, and refuses any expansion budget that is not frozen or any snapshot that certifies a connector.',
            'A registered provider set is never reviewed while drifting: the gate refuses a record that drops a registered provider, invents an unknown provider, or duplicates a provider, and refuses a record whose icon-registry union, 116.3 reconciliation count, frozen snapshot count, charter count, 117.41 registry evidence count, and 117.4 snapshot lock count do not all reconcile to 32, or whose 117.41 registry visibility does not reconcile to 32 with zero exposed.',
            'A reference state is never invented: each of the seven outputs is grounded by the committed witness vocabulary for that output, so a reference state cannot be recorded without a witness to ground it.',
            'Connector certification, live evidence verification, live review, provider exposure, connector release, credential access, and publication remain DEFERRED-EXTERNAL.',
          ]
        : <String>[
            'This authorized record promotes only the observed GitHub App example to CERTIFIED/EXPOSED for the canonical gate. It does not certify another provider or publish a public release.',
            'The live evidence source is the authenticated read-only GitHub App resource, rate-limit, and audit observation; no secret or credential was read or stored.',
            'Connector publication and public release remain outside this authorization.',
          ],
    'external_gates': <String>[
      'connector certification evidence',
      'live evidence verification',
      'live provider review',
      'provider exposure authorization',
      'connector release authorization',
      'credential access',
      'public release publication',
    ],
  };
  final target = File(Sprint118VersionedCertificationContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('declared_provider_count=${report.declaredProviders.length}');
  stdout.writeln('certified_count=${report.certifiedCount}');
  stdout.writeln('exposed_count=${report.exposedCount}');
  stdout.writeln('released_count=${report.releasedCount}');
  stdout.writeln('written=${target.path}');
}
