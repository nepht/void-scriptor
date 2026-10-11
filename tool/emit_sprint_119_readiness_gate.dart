// Emit the 118.45 Sprint 119 Readiness Gate record from the gate's own report.
// Run from the repository root:
//   dart run tool/emit_sprint_119_readiness_gate.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_119_readiness_gate.dart';
import 'package:void_scriptor/features/world_logic/domain/github_app_release_authorization.dart';

Map<String, Object?> _dimension(Sprint119ReadinessDimension dimension) =>
    <String, Object?>{
      'dimension': dimension.dimension,
      'reference_state': dimension.referenceState,
      'summary': dimension.summary,
      'evidence': dimension.evidence,
      'ready': dimension.ready,
      'admitted': dimension.admitted,
      'passed': dimension.passed,
      'verified': dimension.verified,
      'complete': dimension.complete,
      'certified': dimension.certified,
      'released': dimension.released,
      'self_service_enabled': dimension.selfServiceEnabled,
      'ecosystem_ready': dimension.ecosystemReady,
    };

void main() {
  const gate = Sprint119ReadinessGate();
  final report = gate.evaluate();
  final authorization = GithubAppReleaseAuthorization.load();
  final anchor = const Sprint119ReadinessLoader().loadAnchor();
  final record = authorization == null
      ? Sprint119ReadinessContract.canonicalRecord
      : Sprint119ReadinessContract.authorizedRecord;
  final manifest = <String, Object?>{
    'canonical_step': Sprint119ReadinessContract.canonicalStep,
    'title': Sprint119ReadinessContract.title,
    'document_role': 'sprint-119-readiness-gate-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'readiness_decision': report.readinessDecision,
    'readiness_verified': report.readinessVerified,
    'expansion_budget_frozen': report.expansionBudgetFrozen,
    'required_evidence': Sprint119ReadinessContract.requiredEvidence,
    'required_outputs': Sprint119ReadinessContract.requiredOutputs,
    'expected_evidence_count': Sprint119ReadinessContract.expectedEvidenceCount,
    'expected_provider_count': Sprint119ReadinessContract.expectedProviderCount,
    'decision_vocabulary': Sprint119ReadinessContract.decisionVocabulary,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'charter': Sprint119ReadinessContract.charterManifestPath,
      'snapshot': Sprint119ReadinessContract.snapshotManifestPath,
      'approval_gate': Sprint119ReadinessContract.approvalGateManifestPath,
      'icon_registry': Sprint119ReadinessContract.iconRegistryManifestPath,
      'registry_reconciliation':
          Sprint119ReadinessContract.registryReconciliationManifestPath,
      'snapshot_lock': Sprint119ReadinessContract.snapshotLockManifestPath,
      'registry_evidence': Sprint119ReadinessContract.registryEvidencePath,
      'stability_gate': Sprint119ReadinessContract.stabilityReportPath,
      'expansion_gate': Sprint119ReadinessContract.expansionAcceptancePath,
      'support_capacity': Sprint119ReadinessContract.incidentIntakePath,
      'security_privacy_constraints':
          Sprint119ReadinessContract.securityGatePath,
      'technical_debt': Sprint119ReadinessContract.technicalDebtPath,
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
    'stability_vocabulary': anchor?.stabilityVocabulary,
    'expansion_vocabulary': anchor?.expansionVocabulary,
    'registry_vocabulary': anchor?.registryVocabulary,
    'support_vocabulary': anchor?.supportVocabulary,
    'security_privacy_vocabulary': anchor?.securityPrivacyVocabulary,
    'technical_debt_vocabulary': anchor?.technicalDebtVocabulary,
    'reference_state_vocabulary':
        Sprint119ReadinessContract.stateVocabulary(<List<String>>[
          anchor?.stabilityVocabulary ?? const <String>[],
          anchor?.expansionVocabulary ?? const <String>[],
          anchor?.registryVocabulary ?? const <String>[],
          anchor?.supportVocabulary ?? const <String>[],
          anchor?.securityPrivacyVocabulary ?? const <String>[],
          anchor?.technicalDebtVocabulary ?? const <String>[],
        ]),
    'canonical_sources': Sprint119ReadinessContract.canonicalSources,
    'declared_dimensions': report.declaredDimensions,
    'declared_dimension_count': report.declaredDimensions.length,
    'ready_dimensions': report.readyDimensions,
    'admitted_dimensions': report.admittedDimensions,
    'passed_dimensions': report.passedDimensions,
    'verified_dimensions': report.verifiedDimensions,
    'complete_dimensions': report.completeDimensions,
    'certified_dimensions': report.certifiedDimensions,
    'released_dimensions': report.releasedDimensions,
    'self_service_enabled_dimensions': report.selfServiceEnabledDimensions,
    'ecosystem_ready_dimensions': report.ecosystemReadyDimensions,
    'ready_count': report.readyCount,
    'admitted_count': report.admittedCount,
    'passed_count': report.passedCount,
    'verified_count': report.verifiedCount,
    'complete_count': report.completeCount,
    'certified_count': report.certifiedCount,
    'released_count': report.releasedCount,
    'self_service_enabled_count': report.selfServiceEnabledCount,
    'ecosystem_ready_count': report.ecosystemReadyCount,
    'dimensions': record.dimensions.map(_dimension).toList(),
    'claim_boundary': authorization == null
        ? <String>[
            'This record freezes the local Sprint 119 readiness decision over the committed 118.2 stability expansion charter, the committed 118.3 certified connector snapshot, the committed 117.45 GA approval gate, the committed 115.8 provider icon registry, the committed 116.3 provider registry reconciliation, the committed 117.4 certification snapshot lock, the committed 117.41 connector-registry evidence, the committed 118.44 stability & expansion report, the committed 118.42 expansion acceptance gate, the committed 118.6 incident support intake, the committed 116.45 security certification gate, the committed 116.46 privacy compliance gate, and the committed 114.42 technical debt deferred risk register witnesses. A pass does not declare a dimension ready, admit a provider, pass a dimension, verify a dimension, complete a dimension, certify a connector, release a connector, enable self-service tooling, or declare the connector ecosystem ready.',
            'The readiness decision is written against GA_DELAYED. It enumerates all six canonical evidence dimensions exactly once (stability_gate, expansion_gate, provider_registry, support_capacity, security_privacy_constraints, technical_debt), anchors each dimension to a committed witness vocabulary, claims no readiness, and decides the next corrective stabilization because zero connectors are certified (118.3 snapshot: 0 of 32; 117.41 registry evidence: 32 UNVERIFIED, 0 EXPOSED, 32 WITHHELD) and the release is not authorized (117.45 decision=delay, execution_authorized=false, release_blocked=true).',
            'A connector ecosystem is never declared ready without certified connectors, and self-service tooling is never declared ready without an authorized release: on the delayed path the gate refuses a CONNECTOR_ECOSYSTEM or SELF_SERVICE_TOOLING decision, and refuses any dimension that claims readiness, an admitted provider, a pass, verification, completion, certification, a release, self-service enablement, or ecosystem readiness.',
            'A readiness decision is never trusted while its anchors drift: the gate refuses a decision whose icon-registry union, 116.3 reconciliation count, frozen snapshot count, charter count, 117.41 registry evidence count, and 117.4 snapshot lock count do not all reconcile to 32, or whose 117.41 registry visibility does not reconcile to 32 with zero exposed, or whose committed 118.2 charter, 118.3 snapshot, or 117.45 approval gate is not a genuine frozen pass or delay.',
            'The six canonical dimensions are never invented: each dimension is grounded by the committed witness vocabulary for that dimension (the 118.44 stability & expansion report release state, the 118.42 expansion acceptance gate certification statuses, the 117.41 connector-registry evidence status and visibility counts, the 118.6 incident support intake severity levels and owners, the 116.45 security certification gate and 116.46 privacy compliance gate acceptance areas, and the 114.42 technical debt deferred risk register required fields and deferred checks).',
            'Live health observation, incident response, connector certification, connector release, expansion authorization, self-service enablement, and Sprint 119 execution remain DEFERRED-EXTERNAL.',
          ]
        : <String>[
            'This authorized readiness record admits Sprint 119 entry for the observed GitHub App connector example only; it does not enable self-service tooling or public publication.',
            'The provider registry dimension is authorized from the live read-only GitHub App certification example. Incident response, security, privacy, accessibility, documentation, rollback, and public release remain separately bounded.',
            'No secret, credential, token, or private key was read or stored by this gate.',
          ],
    'external_gates': <String>[
      'live health observation',
      'incident response authorization',
      'connector certification',
      'connector release authorization',
      'expansion authorization',
      'self-service tooling enablement',
      'sprint 119 execution authorization',
    ],
  };
  final target = File(Sprint119ReadinessContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('readiness_decision=${report.readinessDecision}');
  stdout.writeln(
    'declared_dimension_count=${report.declaredDimensions.length}',
  );
  stdout.writeln('ready_count=${report.readyCount}');
  stdout.writeln('admitted_count=${report.admittedCount}');
  stdout.writeln('passed_count=${report.passedCount}');
  stdout.writeln('verified_count=${report.verifiedCount}');
  stdout.writeln('complete_count=${report.completeCount}');
  stdout.writeln('certified_count=${report.certifiedCount}');
  stdout.writeln('released_count=${report.releasedCount}');
  stdout.writeln(
    'self_service_enabled_count=${report.selfServiceEnabledCount}',
  );
  stdout.writeln('ecosystem_ready_count=${report.ecosystemReadyCount}');
  stdout.writeln('written=${target.path}');
}
