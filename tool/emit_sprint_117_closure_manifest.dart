// Emit the 117.48 sprint closure manifest from the gate's own report.
//
// The manifest is generated, never hand-written: if the gate is what decides
// whether the sprint closes, then the record of that decision has to come from
// the same code path. A hand-written closure would be free to disagree with the
// gate, which is exactly the drift the evidence contract forbids.
//
// Run from the repository root:
//   dart run tool/emit_sprint_117_closure_manifest.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_117_sprint_closure.dart';

void main() {
  final report = const Sprint117SprintClosureGate().evaluate();
  final anchor = report.anchor;

  final manifest = <String, Object?>{
    'canonical_step': Sprint117ClosureContract.canonicalStep,
    'title': 'Sprint Closure',
    'document_role': 'sprint-closure-manifest',
    'state': report.state.name,
    'decision': report.decision.name,
    'verdict': report.verdict,
    'release_decision': report.releaseDecision,
    'release_decision_owner': report.releaseDecisionOwner,
    'live_release_executed': report.liveReleaseExecuted,
    'criteria': <Map<String, Object?>>[
      for (final criterion in report.criteria) criterion.toJson(),
    ],
    'satisfied_count': report.satisfiedCount,
    'deferred_count': report.deferredCount,
    'unmet_criteria': report.unmetCriteria,
    'deferred_criteria': report.deferredCriteria,
    'missing_evidence': report.missingEvidence,
    'violations': report.violations,
    'source_manifests': Sprint117ClosureContract.sourceManifests,
    'ledger': anchor?.ledgerPath,
    'evidence_anchor': <String, Object?>{
      'entry_gate': <String, Object?>{
        'state': anchor?.entryState,
        'verdict': anchor?.entryVerdict,
        'canonical_entry_readiness': anchor?.canonicalEntryReadiness,
        'canonical_entry_block_resolved': anchor?.canonicalEntryBlockResolved,
        'live_beta_executed': anchor?.entryLiveBetaExecuted,
        'registry_provider_count': anchor?.entryRegistryProviderCount,
      },
      'beta_charter': <String, Object?>{
        'state': anchor?.charterState,
        'verdict': anchor?.charterVerdict,
        'window_start_epoch_ms': anchor?.betaWindowStartMs,
        'window_end_epoch_ms': anchor?.betaWindowEndMs,
        'window_days': anchor?.betaWindowDays,
        'window_phases': anchor?.betaWindowPhaseCount,
        'window_executed': false,
      },
      'cohort': <String, Object?>{
        'state': anchor?.cohortState,
        'verdict': anchor?.cohortVerdict,
        'verified_participant_count': anchor?.verifiedCohortSize,
        'live_beta_executed': anchor?.cohortLiveBetaExecuted,
      },
      'certification': <String, Object?>{
        'verdict': anchor?.certificationVerdict,
        'status_scope': anchor?.certificationScope,
        'locked_provider_count': anchor?.lockedProviderCount,
        'certified_count': anchor?.lockedCertifiedCount,
        'limited_count': anchor?.lockedLimitedCount,
        'blocked_count': anchor?.lockedBlockedCount,
      },
      'exposure_matrix': <String, Object?>{
        'verdict': anchor?.matrixVerdict,
        'master_flag': anchor?.masterFlag,
        'recorded_default': anchor?.matrixDefault,
        'row_count': anchor?.matrixRowCount,
        'consent_gate_verified': anchor?.consentGateVerified,
        'enabled_subset': anchor?.enabledSubset,
        'determined_exposed': anchor?.determinedExposed,
      },
      'registry': <String, Object?>{
        'verdict': anchor?.registryVerdict,
        'provider_count': anchor?.registryProviderCount,
        'certified_count': anchor?.registryCertifiedCount,
        'unverified_count': anchor?.registryUnverifiedCount,
        'withheld_count': anchor?.registryWithheldCount,
        'exposed_count': anchor?.registryExposedCount,
      },
      'rollout': <String, Object?>{
        'state': anchor?.rolloutState,
        'verdict': anchor?.rolloutVerdict,
        'stage_count': anchor?.rolloutStageCount,
        'recorded_default': anchor?.rolloutDefault,
        'enabled_subset': anchor?.rolloutEnabledSubset,
        'kill_switches': anchor?.rolloutKillSwitchCount,
        'kill_switches_drilled': anchor?.rolloutKillSwitchDrilledCount,
        'rollback_controls': anchor?.rolloutRollbackCount,
        'rollback_verified': anchor?.rolloutRollbackVerifiedCount,
      },
      'ga_approval': <String, Object?>{
        'status': anchor?.gaStatus,
        'decision': anchor?.gaDecision,
        'approval_state': anchor?.gaApprovalState,
        'execution_authorized': anchor?.gaExecutionAuthorized,
        'release_blocked': anchor?.gaReleaseBlocked,
        'quality_gates_present': anchor?.gaQualityGatesPresent,
        'quality_gate_sources': anchor?.gaQualityGateSources,
      },
      'observation_handoff': <String, Object?>{
        'state': anchor?.handoffState,
        'verdict': anchor?.handoffVerdict,
        'resolved_outputs': anchor?.handoffResolvedOutputs,
        'required_outputs': anchor?.handoffRequiredOutputs,
        'violations': anchor?.handoffViolationCount,
        'live_release_observed': anchor?.handoffLiveReleaseObserved,
      },
      'visible_providers': anchor?.visibleProviders,
      'live_claim_recorded': anchor?.liveClaimRecorded,
      'certification_sources_disagree': anchor?.certificationSourcesDisagree,
    },
    'external_gates': Sprint117ClosureContract.externalGates,
    'open_items': report.openItems,
    'limitations': report.limitations,
    'summary': report.summary,
    'claim_boundary': <String>[
      'This closes Sprint 117 locally. It records a delay decision: it releases nothing, publishes nothing, tags nothing, and pushes nothing.',
      'No live beta ran and no release was executed. 117.1 and 117.3 record live_beta_executed false and 117.45 records execution_authorized false, so the beta window is carried as an external gate, never as a completed window.',
      'Certification is reported from two committed sources side by side: 117.4 froze the local certification chain while 117.41 reconciled the shipped registry. The disagreement is recorded by name and never averaged.',
      'The seven canonical definition-of-done items are read from committed manifests only. A criterion with no evidence or a source that cannot be read yields blocked, never pass.',
      'A closure that reported verified connector health or a completed beta window would describe a release that never happened.',
    ],
  };

  final target = File(Sprint117ClosureContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );

  stdout.writeln('state=${report.state.name}');
  stdout.writeln('decision=${report.decision.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln(
    'satisfied=${report.satisfiedCount}/'
    '${Sprint117ClosureContract.criteriaNames.length}',
  );
  stdout.writeln('deferred=${report.deferredCount}');
  stdout.writeln('unmet=${report.unmetCriteria.length}');
  stdout.writeln('violations=${report.violations.length}');
  stdout.writeln('written=${target.path}');
}
