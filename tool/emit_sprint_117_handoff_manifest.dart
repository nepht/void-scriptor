// Emit the 117.47 handoff manifest from the gate's own report.
//
// The manifest is generated, never hand-written: if the gate is what decides
// the step is complete, then the record of that decision has to come from the
// same code path. A hand-written manifest would be free to disagree with the
// gate, which is exactly the drift the evidence contract forbids.
//
// Run from the repository root:
//   dart run tool/emit_sprint_117_handoff_manifest.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_117_post_release_observation_handoff.dart';

void main() {
  final report = const Sprint117HandoffGate().evaluate();
  final anchor = report.anchor;

  final manifest = <String, Object?>{
    'canonical_step': Sprint117HandoffContract.canonicalStep,
    'title': 'Post-Release Observation Handoff',
    'document_role': 'handoff-contract-manifest',
    'state': report.state.name,
    'verdict': report.verdict,
    'live_release_executed': report.liveReleaseObserved,
    'live_release_observed': report.liveReleaseObserved,
    'required_outputs': Sprint117HandoffContract.requiredOutputs,
    'resolved_outputs': report.resolvedOutputCount,
    'output_coverage': report.outputCoverage,
    'missing_outputs': report.missingOutputs,
    'undetermined_outputs': report.undeterminedOutputs,
    'violations': report.violations,
    'source_manifests': Sprint117HandoffContract.sourceManifests,
    'connector_health': <String, Object?>{
      'status_counts': anchor?.registryStatusCounts,
      'registry_verdict': anchor?.registryVerdict,
      'certified_subset': anchor?.certifiedSubset,
      'unverified_count': anchor?.unverifiedSubset.length,
      'enabled_subset': anchor?.enabledSubset,
    },
    'incident_queue': <String, Object?>{
      'owners': anchor?.incidentOwners,
      'escalation_providers': anchor?.escalationProviders,
      'support_verdict': anchor?.supportVerdict,
      'live_incident_executed': false,
    },
    'health_baseline': <String, Object?>{
      'monitoring_verdict': anchor?.monitoringVerdict,
      'resilience_verdict': anchor?.resilienceVerdict,
      'privacy_signals': anchor?.privacySignals,
      'telemetry_executed': false,
    },
    'billing_health': <String, Object?>{
      'usage_verdict': anchor?.billingVerdict,
      'usage_areas': anchor?.usageAreas,
      'live_billing_provider_contacted': false,
    },
    'quota_health': <String, Object?>{
      'quota_verdict': anchor?.quotaVerdict,
      'storage_quota_areas': anchor?.storageQuotaAreas,
      'live_quota_queried': false,
    },
    'risk_register': <String, Object?>{
      'security_verdict': anchor?.securityVerdict,
      'privacy_verdict': anchor?.privacyVerdict,
      'surfaces': anchor?.riskSurfaces,
      'external_audit_performed': false,
    },
    'recertification_schedule': <String, Object?>{
      'cohort_verdict': anchor?.cohortVerdict,
      'verified_participant_count': anchor?.verifiedCohortSize,
      'calendar_date': null,
      'note':
          'A schedule is not produced: no cohort exists to recertify and no '
          'calendar was consulted.',
    },
    'external_gates': Sprint117HandoffContract.externalGates,
    'open_items': report.openItems,
    'limitations': report.limitations,
    'claim_boundary': <String>[
      'This manifest defines the handoff contract locally. It observes no live release: no provider was queried, no metric was scraped, no incident was triaged, and no billing or quota endpoint was contacted.',
      'Connector health is reported from 117.41 as 0 CERTIFIED / 32 UNVERIFIED. A handoff reporting verified connector health would describe a release that never happened.',
      'Recertification is a precondition, not a schedule: 117.3 records a failed cohort consent verification with 0 verified participants.',
      'The eight canonical outputs are resolved against committed manifests only. An absent or malformed source yields blocked, never pass.',
    ],
  };

  final target = File(Sprint117HandoffContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
  );

  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln(
    'resolved_outputs=${report.resolvedOutputCount}/'
    '${Sprint117HandoffContract.requiredOutputs.length}',
  );
  stdout.writeln('violations=${report.violations.length}');
  stdout.writeln('written=${target.path}');
}
