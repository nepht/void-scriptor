// Emit the 118.25 Connector Disable & Safe Degradation record from the gate's
// own report.
// Run from the repository root:
//   dart run tool/emit_sprint_118_connector_disable_safe_degradation.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_connector_disable_safe_degradation.dart';

Map<String, Object?> _entry(Sprint118ConnectorDisableEntry entry) =>
    <String, Object?>{
      'acceptance': entry.acceptance,
      'reference_state': entry.referenceState,
      'source': entry.source,
      'detail': entry.detail,
      'limitations': entry.limitations,
      'connector_disabled': entry.connectorDisabled,
      'local_data_touched': entry.localDataTouched,
      'message_sent': entry.messageSent,
      'observed': entry.observed,
    };

void main() {
  const gate = Sprint118ConnectorDisableGate();
  final report = gate.evaluate();
  final anchor = const Sprint118ConnectorDisableLoader().loadAnchor();
  final review = Sprint118ConnectorDisableContract.canonicalReview;
  final record = <String, Object?>{
    'canonical_step': Sprint118ConnectorDisableContract.canonicalStep,
    'title': Sprint118ConnectorDisableContract.title,
    'document_role': 'connector-disable-safe-degradation-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'review_verified': report.reviewVerified,
    'required_acceptance': Sprint118ConnectorDisableContract.requiredAcceptance,
    'required_fields': Sprint118ConnectorDisableContract.requiredFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    'evidence_sources': <String, String>{
      'baseline': Sprint118ConnectorDisableContract.baselineManifestPath,
      'charter': Sprint118ConnectorDisableContract.charterManifestPath,
      'rollback_drill': Sprint118ConnectorDisableContract.drillManifestPath,
      'rollout': Sprint118ConnectorDisableContract.rolloutManifestPath,
      'outage_review':
          Sprint118ConnectorDisableContract.outageReviewManifestPath,
      'token_expiry': Sprint118ConnectorDisableContract.tokenExpiryManifestPath,
      'cached_metadata':
          Sprint118ConnectorDisableContract.cachedMetadataManifestPath,
      'readiness': Sprint118ConnectorDisableContract.readinessManifestPath,
    },
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'baseline_release_state': anchor?.releaseState,
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_window_minutes': anchor?.charterWindowMinutes,
    'drill_state': anchor?.drillState,
    'drill_verdict': anchor?.drillVerdict,
    'drill_control_vocabulary': anchor?.drillControls,
    'rollout_live_executed': anchor?.rolloutLiveExecuted,
    'outage_signal_vocabulary': anchor?.outageSignals,
    'reauth_acceptance_vocabulary': anchor?.reauthAcceptance,
    'cached_acceptance_vocabulary': anchor?.cachedAcceptance,
    'rollout_field_vocabulary': anchor?.rolloutFields,
    'readable_source_count': anchor?.readableSources.length,
    'reference_state_vocabulary':
        Sprint118ConnectorDisableContract.stateVocabulary(<List<String>>[
          anchor?.drillControls ?? const <String>[],
          anchor?.outageSignals ?? const <String>[],
          anchor?.reauthAcceptance ?? const <String>[],
          anchor?.cachedAcceptance ?? const <String>[],
          anchor?.rolloutFields ?? const <String>[],
        ]),
    'canonical_sources': Sprint118ConnectorDisableContract.canonicalSources,
    'declared_acceptance': report.declaredAcceptance,
    'observed_count': report.observedCount,
    'entries': review.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record freezes the local Connector Disable & Safe Degradation review over the committed 118.4 post-release health baseline, the committed 118.2 stability expansion charter, the committed 117.8 provider rollback drill, the committed 116.50 staged beta rollout monitoring witness, the committed 118.17 provider outage recovery review, the committed 115.43 token-expiry UX witness, the committed 116.44 offline cached-metadata certification witness, and the committed 117.6 support incident readiness witness. A pass does not disable a connector, stop a queue, invalidate a cache, touch local data, send a user message, execute a recovery, certify a connector, expose a provider, authorize a release, or publish.',
      'The review is written against GA_DELAYED. Every entry registers a reference for one of the six canonical acceptance items (per_connector_kill_switch, safe_queue_stop, cached_state, local_data_preserved, user_message, recovery_path), claims no live connector disable, touches no local data, sends no message, and observes nothing live.',
      'A connector is never claimed disabled without a release: the gate refuses any entry that claims a live connector disable.',
      'A disable never touches local data: the gate refuses any entry that claims local data was touched by the disable.',
      'Live connector disable, queue stop, cache invalidation, user messaging, recovery execution, connector certification, provider exposure, release authorization, and publication remain DEFERRED-EXTERNAL.',
    ],
    'external_gates': <String>[
      'live connector disable',
      'live queue stop',
      'live cache invalidation',
      'live local data scan',
      'live user message send',
      'live recovery execution',
      'connector certification',
      'provider exposure',
      'public release publication',
    ],
  };
  final target = File(Sprint118ConnectorDisableContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(record)}\n',
  );
  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('observed_count=${report.observedCount}');
  stdout.writeln('written=${target.path}');
}
