// Emit the 118.5 Privacy-Safe Observation record from the gate's own report.
//
// The committed 118.4 baseline and 117.7 privacy-safe monitoring witness are the
// evidence *input*: the gate reads them and decides whether the observation is
// privacy-safe. This file is the *output*: the gate's measured verdict plus the
// observation's canonical fields, all derived from the contract constants and
// the gate's own report. Nothing here is typed by hand, so the record cannot be
// made to agree with itself.
//
// Run from the repository root:
//   dart run tool/emit_sprint_118_privacy_safe_observation.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_privacy_safe_observation.dart';

Map<String, Object?> _signal(Sprint118ObservationSignal signal) =>
    <String, Object?>{
      'signal': signal.signal,
      'collected_fields': signal.collectedFields,
      'requires_explicit_consent': signal.requiresExplicitConsent,
      'minimized': signal.minimized,
      'retention_days': signal.retentionDays,
      'disable_control': signal.disableControl,
    };

void main() {
  const gate = Sprint118PrivacyObservationGate();
  final report = gate.evaluate();
  final anchor = const Sprint118PrivacyObservationLoader().loadAnchor();
  final observation = Sprint118PrivacyObservationContract.canonicalObservation;

  final record = <String, Object?>{
    'canonical_step': Sprint118PrivacyObservationContract.canonicalStep,
    'title': Sprint118PrivacyObservationContract.title,
    'document_role': 'privacy-observation-evaluation-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'observation_verified': report.observationVerified,
    'acceptance_fields': Sprint118PrivacyObservationContract.acceptanceFields,
    'missing_fields': report.missingFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    // The committed witnesses this verification is anchored to, from the
    // contract constants -- not retyped, so the record cannot cite a path the
    // gate never opens.
    'evidence_sources': <String, String>{
      'baseline': Sprint118PrivacyObservationContract.baselineManifestPath,
      'privacy_safe_monitoring':
          Sprint118PrivacyObservationContract.privacySafeMonitoringManifestPath,
    },
    // Facts read from the committed witnesses, never typed.
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'baseline_release_state': anchor?.releaseState,
    'consent_gate': anchor?.consentGate,
    'default_collection': anchor?.defaultCollection,
    'telemetry_executed': anchor?.telemetryExecuted,
    'upstream_excluded_category_count': anchor?.excludedCategories.length,
    'readable_source_count': anchor?.readableSources.length,
    // The observation itself, derived from the contract constants.
    'signal_count': report.declaredSignals.length,
    'declared_signals': report.declaredSignals,
    'collected_field_count': report.collectedFieldCount,
    'max_retention_days': Sprint118PrivacyObservationContract.maxRetentionDays,
    'signals': observation.signals.map(_signal).toList(),
    'claim_boundary': <String>[
      'This record is the gate verdict over committed 118.4 baseline and 117.7 privacy-safe monitoring evidence. A pass means the declared observation is privacy-safe; it does not execute any observation, collect any live signal, certify any connector, or authorize any release.',
      'The observation is written against the delayed release state (GA_DELAYED). No release ran, so no signal observes a live reading and the consent gate remains opt-in default OFF.',
      'The gate reads the committed witnesses directly, classifies every collected field against the full creative/secret/payment/media exclusion vocabulary, and verifies each committed privacy-evidence source is readable; an unreadable witness or an unfrozen baseline keeps the verification blocked rather than assumed.',
      'The committed 117.7 witness carries media and raw payment in its excluded_categories; the gate owns the full vocabulary and keeps any future omission visible as an open item.',
      'Live observation execution, external telemetry, connector certification, provider exposure, quota, cost, and credential state remain DEFERRED-EXTERNAL; nothing here is performed or authorized.',
    ],
    'external_gates': <String>[
      'live observation execution',
      'external telemetry',
      'connector certification evidence',
      'provider exposure authorization',
      'public release publication',
    ],
  };

  final target = File(Sprint118PrivacyObservationContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(record)}\n',
  );

  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('release_state=${report.releaseState}');
  stdout.writeln('signal_count=${report.declaredSignals.length}');
  stdout.writeln('collected_field_count=${report.collectedFieldCount}');
  stdout.writeln('blockers=${report.blockers.length}');
  stdout.writeln('violations=${report.violations.length}');
  stdout.writeln('open_items=${report.openItems.length}');
  stdout.writeln('written=${target.path}');
}
