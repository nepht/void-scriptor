// Emit the 118.20 Novel-Character Permission Boundary Health record from the
// gate's own report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_permission_boundary_health.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_permission_boundary_health.dart';

Map<String, Object?> _entry(Sprint118PermissionBoundaryEntry entry) =>
    <String, Object?>{
      'evidence': entry.evidence,
      'reference_state': entry.referenceState,
      'source': entry.source,
      'detail': entry.detail,
      'limitations': entry.limitations,
      'automatic_access': entry.automaticAccess,
      'explicit_transfer': entry.explicitTransfer,
      'boundary_separate': entry.boundarySeparate,
      'observed': entry.observed,
    };

void main() {
  const gate = Sprint118PermissionBoundaryGate();
  final report = gate.evaluate();
  final anchor = const Sprint118PermissionBoundaryLoader().loadAnchor();
  final review = Sprint118PermissionBoundaryContract.canonicalReview;
  final record = <String, Object?>{
    'canonical_step': Sprint118PermissionBoundaryContract.canonicalStep,
    'title': Sprint118PermissionBoundaryContract.title,
    'document_role': 'permission-boundary-health-review-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'review_verified': report.reviewVerified,
    'required_evidence': Sprint118PermissionBoundaryContract.requiredEvidence,
    'missing_evidence': <String>[],
    'required_fields': Sprint118PermissionBoundaryContract.requiredFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'baseline': Sprint118PermissionBoundaryContract.baselineManifestPath,
      'charter': Sprint118PermissionBoundaryContract.charterManifestPath,
      'boundary_contract':
          Sprint118PermissionBoundaryContract.boundaryContractManifestPath,
      'boundary_validation':
          Sprint118PermissionBoundaryContract.boundaryValidationManifestPath,
      'novel_character':
          Sprint118PermissionBoundaryContract.novelCharacterManifestPath,
      'audit': Sprint118PermissionBoundaryContract.auditManifestPath,
    },
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'baseline_release_state': anchor?.releaseState,
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_window_minutes': anchor?.charterWindowMinutes,
    'boundary_state': anchor?.boundaryState,
    'boundary_verdict': anchor?.boundaryVerdict,
    'boundary_coverage': anchor?.boundaryCoverage,
    'boundary_checks': anchor?.boundaryChecks,
    'boundary_unmet': anchor?.boundaryUnmet,
    'co_ownership_allowed': anchor?.coOwnershipAllowed,
    'boundary_acceptance': anchor?.boundaryAcceptance,
    'novel_character_evidence': anchor?.novelCharacterEvidence,
    'audit_acceptance': anchor?.auditAcceptance,
    'readable_source_count': anchor?.readableSources.length,
    'declared_evidence_count': report.declaredEvidence.length,
    'declared_evidence': report.declaredEvidence,
    'canonical_evidence': Sprint118PermissionBoundaryContract.requiredEvidence,
    'canonical_sources': Sprint118PermissionBoundaryContract.canonicalSources,
    'observed_count': report.observedCount,
    'entries': review.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record freezes the local Novel-Character permission boundary over committed 118.4 baseline, 118.2 charter, 115.4 workspace boundary contract, 117.11 global-scope validation, 114.13 novel-character boundary health, and 115.31 activity & audit evidence. A pass does not grant a connector access, transfer workspace data, run an unlink, restore a backup, or authorize a release.',
      'The review is written against GA_DELAYED. All entries observe nothing live and retain the explicit deferred/synthetic limitations.',
      'The gate refuses automatic Novel/Character access, a missing explicit transfer, a collapsed backup boundary, or a live observation claim instead of assuming the boundary holds.',
      'Live connector access, provider transfer, real unlink, workspace backup/restore, release authorization, and publication remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': <String>[
      'live connector Novel/Character access',
      'provider cross-workspace transfer',
      'real workspace unlink',
      'workspace backup and restore execution',
      'public release publication',
    ],
  };
  final target = File(Sprint118PermissionBoundaryContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(record)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('declared_evidence=${report.declaredEvidence.length}');
  stdout.writeln('observed_count=${report.observedCount}');
  stdout.writeln('written=${target.path}');
}
