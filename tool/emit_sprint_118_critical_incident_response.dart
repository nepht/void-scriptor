// Emit the 118.23 Critical Incident Response record from the gate's own report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_critical_incident_response.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_critical_incident_response.dart';

Map<String, Object?> _entry(Sprint118IncidentResponseEntry entry) =>
    <String, Object?>{
      'incident_class': entry.incidentClass,
      'incident_id': entry.incidentId,
      'containment': entry.containment,
      'connector_disable': entry.connectorDisable,
      'user_protection': entry.userProtection,
      'root_cause': entry.rootCause,
      'fix': entry.fix,
      'tests': entry.tests,
      'advisory': entry.advisory,
      'rollback': entry.rollback,
      'owner': entry.owner,
      'evidence': entry.evidence,
      'live_incident_claimed': entry.liveIncidentClaimed,
    };

void main() {
  const gate = Sprint118IncidentResponseGate();
  final report = gate.evaluate();
  final anchor = const Sprint118IncidentResponseLoader().loadAnchor();
  final plan = Sprint118IncidentResponseContract.canonicalPlan;
  final record = <String, Object?>{
    'canonical_step': Sprint118IncidentResponseContract.canonicalStep,
    'title': Sprint118IncidentResponseContract.title,
    'document_role': 'critical-incident-response-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'plan_verified': report.planVerified,
    'required_outputs': Sprint118IncidentResponseContract.requiredOutputs,
    'missing_outputs': report.missingOutputs,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'baseline': Sprint118IncidentResponseContract.baselineManifestPath,
      'charter': Sprint118IncidentResponseContract.charterManifestPath,
      'readiness': Sprint118IncidentResponseContract.readinessManifestPath,
      'p0_response': Sprint118IncidentResponseContract.p0ManifestPath,
      'rollout_monitoring':
          Sprint118IncidentResponseContract.rolloutManifestPath,
    },
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'baseline_release_state': anchor?.releaseState,
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'readiness_state': anchor?.readinessState,
    'readiness_verdict': anchor?.readinessVerdict,
    'live_incident_executed': anchor?.liveIncidentExecuted,
    'owner_vocabulary': anchor?.owners,
    'p0_output_vocabulary': anchor?.p0Outputs,
    'connector_disable_vocabulary': anchor?.connectorDisableScopes,
    'readable_source_count': anchor?.readableSources.length,
    'canonical_incident_classes':
        Sprint118IncidentResponseContract.incidentClasses,
    'canonical_sources': Sprint118IncidentResponseContract.canonicalSources,
    'declared_classes': report.declaredClasses,
    'response_count': report.responseCount,
    'entries': plan.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record freezes the local Critical Incident Response plan over the committed 118.4 post-release health baseline, the committed 118.2 stability expansion charter, the committed 117.6 support incident readiness witness, the committed 114.28 P0 critical security response witness, and the committed 116.50 staged-beta rollout monitoring witness. A pass does not execute a live incident response, contain a live incident, disable a live connector, notify a user, ship a fix, run a test, publish an advisory, roll back a release, certify a connector, expose a provider, authorize a release, or publish.',
      'The plan is written against GA_DELAYED. Every record registers a reference response, claims no live incident, and stops short of confirming a root cause or a live response.',
      'A response is never claimed live without a release: the gate refuses any record that treats its reference response as a live incident response, and any record that claims a live impact through the readiness witness.',
      'Live incident execution, containment, connector disabling, user notification, fix shipping, advisory publication, rollback execution, connector certification, provider exposure, release authorization, and publication remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': <String>[
      'live incident execution',
      'live containment',
      'live connector disabling',
      'live user notification',
      'advisory publication',
      'rollback execution',
      'connector certification',
      'provider exposure',
      'public release publication',
    ],
  };
  final target = File(Sprint118IncidentResponseContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(record)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('response_count=${report.responseCount}');
  stdout.writeln('written=${target.path}');
}
