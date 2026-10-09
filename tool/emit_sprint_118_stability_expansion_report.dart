// Emit the 118.44 Stability & Expansion Report record from the gate's own
// report. Run from the repository root:
//   dart run tool/emit_sprint_118_stability_expansion_report.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_stability_expansion_report.dart';

Map<String, Object?> _section(Sprint118StabilityExpansionSection section) =>
    <String, Object?>{
      'section': section.section,
      'reference_state': section.referenceState,
      'summary': section.summary,
      'evidence': section.evidence,
      'reported': section.reported,
      'published': section.published,
      'verified': section.verified,
      'complete': section.complete,
      'live': section.live,
      'certified': section.certified,
      'released': section.released,
    };

void main() {
  const gate = Sprint118StabilityExpansionGate();
  final report = gate.evaluate();
  final anchor = const Sprint118StabilityExpansionLoader().loadAnchor();
  final record = Sprint118StabilityExpansionContract.canonicalRecord;
  final manifest = <String, Object?>{
    'canonical_step': Sprint118StabilityExpansionContract.canonicalStep,
    'title': Sprint118StabilityExpansionContract.title,
    'document_role': 'stability-expansion-report-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'report_verified': report.reportVerified,
    'expansion_budget_frozen': report.expansionBudgetFrozen,
    'required_sections': Sprint118StabilityExpansionContract.requiredSections,
    'required_outputs': Sprint118StabilityExpansionContract.requiredOutputs,
    'expected_section_count':
        Sprint118StabilityExpansionContract.expectedSectionCount,
    'expected_provider_count':
        Sprint118StabilityExpansionContract.expectedProviderCount,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'charter': Sprint118StabilityExpansionContract.charterManifestPath,
      'snapshot': Sprint118StabilityExpansionContract.snapshotManifestPath,
      'approval_gate':
          Sprint118StabilityExpansionContract.approvalGateManifestPath,
      'icon_registry':
          Sprint118StabilityExpansionContract.iconRegistryManifestPath,
      'registry_reconciliation': Sprint118StabilityExpansionContract
          .registryReconciliationManifestPath,
      'snapshot_lock':
          Sprint118StabilityExpansionContract.snapshotLockManifestPath,
      'registry_evidence':
          Sprint118StabilityExpansionContract.registryEvidencePath,
      'health': Sprint118StabilityExpansionContract.healthBaselinePath,
      'incidents': Sprint118StabilityExpansionContract.incidentIntakePath,
      'fixes': Sprint118StabilityExpansionContract.stabilityFixesPath,
      'patch': Sprint118StabilityExpansionContract.patchTriagePath,
      'certified_subset':
          Sprint118StabilityExpansionContract.certificationPolicyPath,
      'expansion':
          Sprint118StabilityExpansionContract.expansionPrioritizationPath,
      'limitations':
          Sprint118StabilityExpansionContract.certificationPolicyPath,
      'risks': Sprint118StabilityExpansionContract.technicalDebtPath,
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
    'release_state_vocabulary': anchor?.releaseStateVocabulary,
    'health_vocabulary': anchor?.healthVocabulary,
    'incidents_vocabulary': anchor?.incidentsVocabulary,
    'fixes_vocabulary': anchor?.fixesVocabulary,
    'patch_vocabulary': anchor?.patchVocabulary,
    'certified_subset_vocabulary': anchor?.certifiedSubsetVocabulary,
    'expansion_vocabulary': anchor?.expansionVocabulary,
    'limitations_vocabulary': anchor?.limitationsVocabulary,
    'risks_vocabulary': anchor?.risksVocabulary,
    'reference_state_vocabulary':
        Sprint118StabilityExpansionContract.stateVocabulary(<List<String>>[
          anchor?.releaseStateVocabulary ?? const <String>[],
          anchor?.healthVocabulary ?? const <String>[],
          anchor?.incidentsVocabulary ?? const <String>[],
          anchor?.fixesVocabulary ?? const <String>[],
          anchor?.patchVocabulary ?? const <String>[],
          anchor?.certifiedSubsetVocabulary ?? const <String>[],
          anchor?.expansionVocabulary ?? const <String>[],
          anchor?.limitationsVocabulary ?? const <String>[],
          anchor?.risksVocabulary ?? const <String>[],
        ]),
    'canonical_sources': Sprint118StabilityExpansionContract.canonicalSources,
    'declared_sections': report.declaredSections,
    'declared_section_count': report.declaredSections.length,
    'reported_sections': report.reportedSections,
    'published_sections': report.publishedSections,
    'verified_sections': report.verifiedSections,
    'complete_sections': report.completeSections,
    'live_sections': report.liveSections,
    'certified_sections': report.certifiedSections,
    'released_sections': report.releasedSections,
    'reported_count': report.reportedCount,
    'published_count': report.publishedCount,
    'verified_count': report.verifiedCount,
    'complete_count': report.completeCount,
    'live_count': report.liveCount,
    'certified_count': report.certifiedCount,
    'released_count': report.releasedCount,
    'sections': record.sections.map(_section).toList(),
    'claim_boundary': <String>[
      'This record freezes the local Stability & Expansion Report over the committed 118.2 stability expansion charter, the committed 118.3 certified connector snapshot, the committed 117.45 GA approval gate, the committed 115.8 provider icon registry, the committed 116.3 provider registry reconciliation, the committed 117.4 certification snapshot lock, the committed 117.41 connector-registry evidence, and the committed 118 post-release health baseline, 118 incident support intake, 118 stability fixes, 114 severity patch triage, 116 certification policy, 118 expansion prioritization, and 114 technical debt deferred risk register witnesses. A pass does not report a section live, publish a section, verify a section, complete a section, observe live state, certify a connector, or release a connector.',
      'The stability & expansion report is written against GA_DELAYED. It enumerates all nine canonical sections exactly once (release_state, health, incidents, fixes, patch, certified_subset, expansion, limitations, risks), anchors each section to a committed witness vocabulary, claims no live report and no live health, and keeps the expansion budget frozen at zero new certified connectors.',
      'Stability is never reported and expansion is never authorized without live evidence and an authorized release: the gate refuses any section that claims a live report, a published section, a verified section, a complete section, live observed state, a certified connector, or a released connector on the delayed path, and refuses any expansion budget that is not frozen or any snapshot that certifies a connector.',
      'A report is never trusted while its anchors drift: the gate refuses a record whose icon-registry union, 116.3 reconciliation count, frozen snapshot count, charter count, 117.41 registry evidence count, and 117.4 snapshot lock count do not all reconcile to 32, or whose 117.41 registry visibility does not reconcile to 32 with zero exposed, or whose committed 118.2 charter, 118.3 snapshot, or 117.45 approval gate is not a genuine frozen pass or delay.',
      'The nine canonical sections are never invented: each section is grounded by the committed witness vocabulary for that section (the 118.3 snapshot release state, the 118 post-release health baseline required fields, the 118 incident support intake severity levels, the 118 stability fixes canonical fix areas, the 114 severity patch triage decisions, the 116 certification policy certification statuses and limitations, the 118 expansion prioritization required criteria, and the 114 technical debt deferred risk register required fields).',
      'Live health observation, incident response, patch deployment, connector certification, connector release, and expansion remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': <String>[
      'live health observation',
      'incident response authorization',
      'patch deployment authorization',
      'connector certification',
      'connector release authorization',
      'expansion authorization',
    ],
  };
  final target = File(Sprint118StabilityExpansionContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('declared_section_count=${report.declaredSections.length}');
  stdout.writeln('reported_count=${report.reportedCount}');
  stdout.writeln('published_count=${report.publishedCount}');
  stdout.writeln('verified_count=${report.verifiedCount}');
  stdout.writeln('complete_count=${report.completeCount}');
  stdout.writeln('live_count=${report.liveCount}');
  stdout.writeln('certified_count=${report.certifiedCount}');
  stdout.writeln('released_count=${report.releasedCount}');
  stdout.writeln('written=${target.path}');
}
