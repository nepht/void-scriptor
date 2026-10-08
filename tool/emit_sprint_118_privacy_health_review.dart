// Emit the 118.19 Privacy Health Review from the gate's own report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_privacy_health_review.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_privacy_health_review.dart';

Map<String, Object?> _entry(Sprint118PrivacyHealthEntry entry) =>
    <String, Object?>{
      'signal': entry.signal,
      'reference_state': entry.referenceState,
      'source': entry.source,
      'destination': entry.destination,
      'retention_days': entry.retentionDays,
      'consent_explicit': entry.consentExplicit,
      'deletion_supported': entry.deletionSupported,
      'disconnect_supported': entry.disconnectSupported,
      'telemetry_disabled': entry.telemetryDisabled,
      'metadata_minimized': entry.metadataMinimized,
      'transfer_explicit': entry.transferExplicit,
      'limitations': entry.limitations,
      'observed': entry.observed,
    };

void main() {
  const gate = Sprint118PrivacyHealthGate();
  final report = gate.evaluate();
  final anchor = const Sprint118PrivacyHealthLoader().loadAnchor();
  final review = Sprint118PrivacyHealthContract.canonicalReview;
  final record = <String, Object?>{
    'canonical_step': Sprint118PrivacyHealthContract.canonicalStep,
    'title': Sprint118PrivacyHealthContract.title,
    'document_role': 'privacy-health-review-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'review_verified': report.reviewVerified,
    'required_fields': Sprint118PrivacyHealthContract.requiredFields,
    'missing_fields': <String>[],
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'baseline': Sprint118PrivacyHealthContract.baselineManifestPath,
      'charter': Sprint118PrivacyHealthContract.charterManifestPath,
      'privacy_observation':
          Sprint118PrivacyHealthContract.observationManifestPath,
      'privacy_compliance':
          Sprint118PrivacyHealthContract.complianceManifestPath,
      'privacy_data_flow': Sprint118PrivacyHealthContract.dataFlowManifestPath,
      'privacy_monitoring':
          Sprint118PrivacyHealthContract.monitoringManifestPath,
    },
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'baseline_release_state': anchor?.releaseState,
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_window_minutes': anchor?.charterWindowMinutes,
    'observation_state': anchor?.observationState,
    'observation_verdict': anchor?.observationVerdict,
    'observation_release_state': anchor?.observationReleaseState,
    'observation_acceptance': anchor?.observationAcceptance,
    'compliance_status': anchor?.complianceStatus,
    'data_flow_outputs': anchor?.dataFlowOutputs,
    'monitoring_signals': anchor?.monitoringSignals,
    'default_collection_off': anchor?.collectionOff,
    'consent_gate': anchor?.consentGate,
    'telemetry_executed': anchor?.telemetryExecuted,
    'readable_source_count': anchor?.readableSources.length,
    'declared_signal_count': report.declaredSignals.length,
    'declared_signals': report.declaredSignals,
    'canonical_signals': Sprint118PrivacyHealthContract.privacySignals,
    'canonical_sources': Sprint118PrivacyHealthContract.canonicalSources,
    'observed_count': report.observedCount,
    'max_retention_days': Sprint118PrivacyHealthContract.maxRetentionDays,
    'entries': review.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record freezes local privacy controls over committed 118.4, 118.2, 118.5, 116.46, 115.50, and 117.7 evidence. A pass does not execute telemetry, contact a provider, delete a live account, or authorize a transfer or release.',
      'The review is written against GA_DELAYED. All entries observe nothing live and retain the explicit deferred/synthetic limitations.',
      'The gate refuses a missing consent, destination, retention, deletion, disconnect, telemetry, metadata, or transfer control instead of assuming the control exists.',
      'External provider transfers, live subject requests, legal review, production telemetry, and publication remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': <String>[
      'live consent and subject-request execution',
      'provider destination verification',
      'production telemetry',
      'external transfer authorization',
      'public release publication',
    ],
  };
  final target = File(Sprint118PrivacyHealthContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(record)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('declared_signals=${report.declaredSignals.length}');
  stdout.writeln('observed_count=${report.observedCount}');
  stdout.writeln('written=${target.path}');
}
