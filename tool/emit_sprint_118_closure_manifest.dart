// Emit the 118.46 Sprint 118 closure manifest from the gate's own report.
//
// Run from the repository root:
//   dart run tool/emit_sprint_118_closure_manifest.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_sprint_closure.dart';

void main() {
  final report = const Sprint118SprintClosureGate().evaluate();
  final anchor = report.anchor;
  final manifest = <String, Object?>{
    'canonical_step': Sprint118ClosureContract.canonicalStep,
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
    'deferred_criteria': [
      for (final criterion in report.criteria)
        if (criterion.deferred) criterion.name,
    ],
    'missing_evidence': report.missingEvidence,
    'violations': report.violations,
    'source_manifests': Sprint118ClosureContract.sourceManifests,
    'ledger': anchor?.ledgerPath,
    'evidence_anchor': <String, Object?>{
      'entry_gate': <String, Object?>{
        'state': anchor?.entryState,
        'execution_allowed': anchor?.entryExecutionAllowed,
        'corrective_scope_approved': anchor?.correctiveScopeApproved,
      },
      'release_state': anchor?.releaseState,
      'provider_snapshot': <String, Object?>{
        'snapshot_state': anchor?.snapshotState,
        'snapshot_frozen': anchor?.snapshotFrozen,
        'registered_provider_count': anchor?.registeredProviderCount,
        'certified_provider_count': anchor?.certifiedProviderCount,
      },
      'incident_and_degradation': <String, Object?>{
        'incident_state': anchor?.incidentState,
        'live_incident_executed': anchor?.liveIncidentExecuted,
        'disable_state': anchor?.disableState,
      },
      'maintenance': <String, Object?>{
        'fixes_state': anchor?.fixesState,
        'maintenance_state': anchor?.maintenanceState,
        'decision': anchor?.maintenanceDecision,
      },
      'expansion_certification': <String, Object?>{
        'certification_state': anchor?.certificationState,
        'acceptance_state': anchor?.expansionAcceptanceState,
      },
      'report': <String, Object?>{
        'state': anchor?.reportState,
        'verified': anchor?.reportVerified,
        'declared_section_count': anchor?.reportDeclaredSectionCount,
        'expected_section_count': anchor?.reportExpectedSectionCount,
      },
      'next_direction': <String, Object?>{
        'state': anchor?.readinessState,
        'verified': anchor?.readinessVerified,
        'decision': anchor?.readinessDecision,
        'all_prior_steps_resolved': anchor?.allLedgerStepsResolved,
      },
      'readable_source_count': anchor?.readableSourceCount,
    },
    'external_gates': Sprint118ClosureContract.externalGates,
    'open_items': report.openItems,
    'limitations': report.limitations,
    'summary': report.summary,
    'claim_boundary': <String>[
      'This closes Sprint 118 locally on the GA_DELAYED corrective path. It releases nothing, publishes nothing, tags nothing, and pushes nothing.',
      'The seven canonical definition-of-done items are derived from the committed 118.1-118.45 evidence and the active ledger; missing evidence, violations, or unresolved prior steps block closure.',
      'The provider snapshot and expansion gates record 0 certified providers of 32 registered providers. This is certification evidence, not connector certification or visibility.',
      'The maintenance decision is recorded locally. A build, publication, signing, hosted CI run, or live observation is never inferred from this manifest.',
      'Sprint 119 remains CORRECTIVE_STABILIZATION and requires its own entry gate and explicit authorization.',
    ],
  };
  final target = File(Sprint118ClosureContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );

  stdout.writeln('state=${report.state.name}');
  stdout.writeln('decision=${report.decision.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln(
    'satisfied=${report.satisfiedCount}/'
    '${Sprint118ClosureContract.criteriaNames.length}',
  );
  stdout.writeln('deferred=${report.deferredCount}');
  stdout.writeln('unmet=${report.unmetCriteria.length}');
  stdout.writeln('violations=${report.violations.length}');
  stdout.writeln('written=${target.path}');
}
