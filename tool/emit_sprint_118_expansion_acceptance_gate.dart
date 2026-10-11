// Emit the 118.42 Expansion Acceptance Gate record from the gate's own report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_expansion_acceptance_gate.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_expansion_acceptance_gate.dart';
import 'package:void_scriptor/features/world_logic/domain/github_app_release_authorization.dart';

Map<String, Object?> _entry(Sprint118ExpansionAcceptanceEntry entry) =>
    <String, Object?>{
      'provider_id': entry.providerId,
      'certification': entry.certification,
      'contract_tests': entry.contractTests,
      'security': entry.security,
      'privacy': entry.privacy,
      'accessibility': entry.accessibility,
      'documentation': entry.documentation,
      'rollback': entry.rollback,
      'allowed': entry.allowed,
      'admitted': entry.admitted,
      'accepted': entry.accepted,
      'passed': entry.passed,
      'evidence_complete': entry.evidenceComplete,
      'certified': entry.certified,
      'released': entry.released,
    };

void main() {
  const gate = Sprint118ExpansionAcceptanceGate();
  final report = gate.evaluate();
  final authorization = GithubAppReleaseAuthorization.load();
  final anchor = const Sprint118ExpansionAcceptanceLoader().loadAnchor();
  final record = authorization == null
      ? Sprint118ExpansionAcceptanceContract.canonicalRecord
      : Sprint118ExpansionAcceptanceContract.authorizedRecord;
  final manifest = <String, Object?>{
    'canonical_step': Sprint118ExpansionAcceptanceContract.canonicalStep,
    'title': Sprint118ExpansionAcceptanceContract.title,
    'document_role': 'expansion-acceptance-gate-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'record_verified': report.recordVerified,
    'expansion_budget_frozen': report.expansionBudgetFrozen,
    'required_fields': Sprint118ExpansionAcceptanceContract.requiredFields,
    'required_outputs': Sprint118ExpansionAcceptanceContract.requiredOutputs,
    'expected_provider_count':
        Sprint118ExpansionAcceptanceContract.expectedProviderCount,
    'expected_output_count':
        Sprint118ExpansionAcceptanceContract.expectedOutputCount,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'charter': Sprint118ExpansionAcceptanceContract.charterManifestPath,
      'snapshot': Sprint118ExpansionAcceptanceContract.snapshotManifestPath,
      'approval_gate':
          Sprint118ExpansionAcceptanceContract.approvalGateManifestPath,
      'icon_registry':
          Sprint118ExpansionAcceptanceContract.iconRegistryManifestPath,
      'registry_reconciliation': Sprint118ExpansionAcceptanceContract
          .registryReconciliationManifestPath,
      'snapshot_lock':
          Sprint118ExpansionAcceptanceContract.snapshotLockManifestPath,
      'registry_evidence':
          Sprint118ExpansionAcceptanceContract.registryEvidencePath,
      'certification':
          Sprint118ExpansionAcceptanceContract.certificationManifestPath,
      'contract_tests':
          Sprint118ExpansionAcceptanceContract.contractManifestPath,
      'security': Sprint118ExpansionAcceptanceContract.securityHealthPath,
      'privacy': Sprint118ExpansionAcceptanceContract.privacyHealthPath,
      'accessibility':
          Sprint118ExpansionAcceptanceContract.accessibilityHealthPath,
      'documentation':
          Sprint118ExpansionAcceptanceContract.documentationManifestPath,
      'staged_beta_rollout':
          Sprint118ExpansionAcceptanceContract.stagedBetaRolloutPath,
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
    'certification_vocabulary': anchor?.certificationVocabulary,
    'contract_vocabulary': anchor?.contractVocabulary,
    'security_vocabulary': anchor?.securityVocabulary,
    'privacy_vocabulary': anchor?.privacyVocabulary,
    'accessibility_vocabulary': anchor?.accessibilityVocabulary,
    'documentation_vocabulary': anchor?.documentationVocabulary,
    'rollback_vocabulary': anchor?.rollbackVocabulary,
    'reference_state_vocabulary':
        Sprint118ExpansionAcceptanceContract.stateVocabulary(<List<String>>[
          anchor?.certificationVocabulary ?? const <String>[],
          anchor?.contractVocabulary ?? const <String>[],
          anchor?.securityVocabulary ?? const <String>[],
          anchor?.privacyVocabulary ?? const <String>[],
          anchor?.accessibilityVocabulary ?? const <String>[],
          anchor?.documentationVocabulary ?? const <String>[],
          anchor?.rollbackVocabulary ?? const <String>[],
        ]),
    'canonical_sources': Sprint118ExpansionAcceptanceContract.canonicalSources,
    'declared_providers': report.declaredProviders,
    'declared_provider_count': report.declaredProviders.length,
    'allowed_providers': report.allowedProviders,
    'admitted_providers': report.admittedProviders,
    'accepted_providers': report.acceptedProviders,
    'passed_providers': report.passedProviders,
    'certified_providers': report.certifiedProviders,
    'released_providers': report.releasedProviders,
    'allowed_count': report.allowedCount,
    'admitted_count': report.admittedCount,
    'accepted_count': report.acceptedCount,
    'passed_count': report.passedCount,
    'certified_count': report.certifiedCount,
    'released_count': report.releasedCount,
    'entries': record.entries.map(_entry).toList(),
    'claim_boundary': authorization == null
        ? <String>[
            'This record freezes the local Expansion Acceptance Gate over the committed 118.2 stability expansion charter, the committed 118.3 certified connector snapshot, the committed 117.45 GA approval gate, the committed 115.8 provider icon registry, the committed 116.3 provider registry reconciliation, the committed 117.4 certification snapshot lock, the committed 117.41 connector-registry evidence, and the committed 118.39/118.40/118 security/privacy/accessibility/112/116.50 acceptance evidence witnesses. A pass does not allow a connector into the ecosystem, admit a connector, grant acceptance, pass an acceptance gate, complete an evidence set, certify a connector, or release a connector.',
            'The acceptance record is written against GA_DELAYED. It enumerates all 32 registered providers exactly once, anchors each of the seven canonical acceptance evidence dimensions (certification, contract_tests, security, privacy, accessibility, documentation, rollback) to a committed witness vocabulary, claims no connector allowed and no acceptance granted, and keeps the expansion budget frozen at zero new certified connectors.',
            'A connector is never allowed into the ecosystem without complete live evidence and an authorized release: the gate refuses any entry that claims an allowed connector, an admitted connector, granted acceptance, a passed acceptance gate, a complete evidence set, a certified connector, or a released connector on the delayed path, and refuses any expansion budget that is not frozen or any snapshot that certifies a connector.',
            'A registered provider set is never reviewed while drifting: the gate refuses a record that drops a registered provider, invents an unknown provider, or duplicates a provider, and refuses a record whose icon-registry union, 116.3 reconciliation count, frozen snapshot count, charter count, 117.41 registry evidence count, and 117.4 snapshot lock count do not all reconcile to 32, or whose 117.41 registry visibility does not reconcile to 32 with zero exposed.',
            'The seven canonical acceptance evidence dimensions are never invented: each dimension is grounded by the committed witness vocabulary for that dimension (the 118.39 versioned connector certification status vocabulary, the 118.40 expansion contract suite-contract vocabulary, the 118 security/privacy/accessibility health reference states, the 112 documentation & support release notes outputs, and the 116.50 staged beta rollout monitoring rollback ids).',
            'Connector acceptance, connector allowance, evidence verification, connector certification, connector release, and publication remain DEFERRED-EXTERNAL.',
          ]
        : <String>[
            'This authorized acceptance record admits only the observed GitHub App certification example; it does not grant public publication or promote another provider.',
            'The certification dimension is authorized from the live read-only GitHub App example. Security, privacy, accessibility, documentation, and rollback remain separately bounded witnesses.',
            'Public release and publication remain outside this authorization.',
          ],
    'external_gates': <String>[
      'connector acceptance authorization',
      'connector allowance authorization',
      'acceptance evidence verification',
      'acceptance gate pass authorization',
      'connector certification',
      'connector release authorization',
      'public release publication',
    ],
  };
  final target = File(Sprint118ExpansionAcceptanceContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('declared_provider_count=${report.declaredProviders.length}');
  stdout.writeln('allowed_count=${report.allowedCount}');
  stdout.writeln('admitted_count=${report.admittedCount}');
  stdout.writeln('accepted_count=${report.acceptedCount}');
  stdout.writeln('passed_count=${report.passedCount}');
  stdout.writeln('certified_count=${report.certifiedCount}');
  stdout.writeln('released_count=${report.releasedCount}');
  stdout.writeln('written=${target.path}');
}
