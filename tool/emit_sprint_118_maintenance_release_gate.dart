// Emit the 118.28 Maintenance Release Gate record from the gate's own report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_maintenance_release_gate.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_maintenance_release_gate.dart';

Map<String, Object?> _entry(Sprint118MaintenanceReleaseEntry entry) =>
    <String, Object?>{
      'item': entry.item,
      'reference_state': entry.referenceState,
      'source': entry.source,
      'detail': entry.detail,
      'limitations': entry.limitations,
      'artifact_built': entry.artifactBuilt,
      'upgrade_executed': entry.upgradeExecuted,
      'rollback_executed': entry.rollbackExecuted,
      'notes_published': entry.notesPublished,
      'emergency_claimed': entry.emergencyClaimed,
      'observed': entry.observed,
    };

void main() {
  const gate = Sprint118MaintenanceReleaseGate();
  final report = gate.evaluate();
  final anchor = const Sprint118MaintenanceReleaseLoader().loadAnchor();
  final record = Sprint118MaintenanceReleaseContract.canonicalRecord;
  final manifest = <String, Object?>{
    'canonical_step': Sprint118MaintenanceReleaseContract.canonicalStep,
    'title': Sprint118MaintenanceReleaseContract.title,
    'document_role': 'maintenance-release-gate-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'selected_decision': report.selectedDecision,
    'release_verified': report.releaseVerified,
    'required_decisions': Sprint118MaintenanceReleaseContract.requiredDecisions,
    'required_validations':
        Sprint118MaintenanceReleaseContract.requiredValidations,
    'required_fields': Sprint118MaintenanceReleaseContract.requiredFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'baseline': Sprint118MaintenanceReleaseContract.baselineManifestPath,
      'charter': Sprint118MaintenanceReleaseContract.charterManifestPath,
      'rollout_decision':
          Sprint118MaintenanceReleaseContract.rolloutDecisionManifestPath,
      'approval_gate':
          Sprint118MaintenanceReleaseContract.approvalGateManifestPath,
      'maintenance_scope':
          Sprint118MaintenanceReleaseContract.maintenanceScopeManifestPath,
      'maintenance_artifact':
          Sprint118MaintenanceReleaseContract.maintenanceArtifactManifestPath,
      'artifact_reproducibility':
          Sprint118MaintenanceReleaseContract.artifactEvidenceManifestPath,
      'packaging': Sprint118MaintenanceReleaseContract.packagingManifestPath,
      'rollback_drill':
          Sprint118MaintenanceReleaseContract.rollbackDrillManifestPath,
    },
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'release_state_anchor': anchor?.releaseState,
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_window_minutes': anchor?.charterWindowMinutes,
    'rollout_state': anchor?.rolloutState,
    'rollout_verdict': anchor?.rolloutVerdict,
    'rollout_decision': anchor?.rolloutDecision,
    'approval_decision': anchor?.approvalDecision,
    'approval_state': anchor?.approvalState,
    'execution_authorized': anchor?.executionAuthorized,
    'release_blocked': anchor?.releaseBlocked,
    'approved_fix_count': anchor?.approvedFixCount,
    'emergency_release_recorded': anchor?.emergencyReleaseRecorded,
    'readable_source_count': anchor?.readableSources.length,
    'reference_state_vocabulary':
        Sprint118MaintenanceReleaseContract.stateVocabulary(<List<String>>[
          anchor?.maintenanceEvidence ?? const <String>[],
          anchor?.artifactOutputs ?? const <String>[],
          anchor?.packagingOutputs ?? const <String>[],
          anchor?.deferredChecks ?? const <String>[],
          anchor?.drillControls ?? const <String>[],
        ]),
    'canonical_sources': Sprint118MaintenanceReleaseContract.canonicalSources,
    'declared_validations': report.declaredValidations,
    'observed_count': report.observedCount,
    'entries': record.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record freezes the local Maintenance Release Gate over the committed 118.4 post-release health baseline, the committed 118.2 stability expansion charter, the committed 118.27 rollout progression decision, the committed 117.45 approval gate, and the committed 114.39 maintenance scope, 114.40 maintenance artifact gate, 117.43 GA artifact reproducibility evidence, 113.38 packaging manifest, and 117.8 rollback drill. A pass does not build an artifact, execute an upgrade, execute a rollback, publish checksums, publish release notes, authorize a release, or publish.',
      'The gate is written against GA_DELAYED. It enumerates all five canonical validation domains (artifact, upgrade, rollback, checksums, notes), claims no built artifact, no executed upgrade, no executed rollback, no published release note, no emergency release, and observes nothing live, and selects NO_PATCH as the only decision the evidence supports.',
      'A maintenance release is never built without an approved fix scope and an authorized release: when no approved fix requires a patch and no release is authorized, the gate refuses any selected decision other than NO_PATCH, and refuses BUILD_1_3_1 without an approved fix and an authorized release and EMERGENCY_RELEASE_ALREADY_ISSUED without a recorded emergency.',
      'An artifact is never built, an upgrade is never executed, a rollback is never executed, a release note is never published, and an emergency release is never claimed on the delayed path: the gate refuses each claim by name.',
      'Artifact build, signing, upgrade execution, rollback execution, checksum publication, release-note publication, release authorization, and publication remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': <String>[
      'maintenance artifact build',
      'artifact signing',
      'upgrade execution',
      'rollback execution',
      'checksum publication',
      'release-note publication',
      'release authorization',
      'public release publication',
    ],
  };
  final target = File(Sprint118MaintenanceReleaseContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('selected_decision=${report.selectedDecision}');
  stdout.writeln('written=${target.path}');
}
