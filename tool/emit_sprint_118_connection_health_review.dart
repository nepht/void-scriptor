// Emit the 118.7 Connection Health Review record from the gate's own report.
//
// The committed 118.4 baseline, 118.2 charter, and 115.10 connection & health
// state machine are the evidence *input*: the gate reads them and decides
// whether the declared review is well-formed. This file is the *output*: the
// gate's measured verdict plus the review's canonical fields, all derived from
// the contract constants and the gate's own report. Nothing here is typed by
// hand, so the record cannot be made to agree with itself.
//
// Run from the repository root:
//   dart run tool/emit_sprint_118_connection_health_review.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_connection_health_review.dart';

Map<String, Object?> _entry(Sprint118ConnectionHealthEntry entry) =>
    <String, Object?>{
      'signal': entry.signal,
      'reference_state': entry.referenceState,
      'source': entry.source,
      'window': entry.window,
      'limitations': entry.limitations,
      'observed': entry.observed,
    };

void main() {
  const gate = Sprint118ConnectionHealthGate();
  final report = gate.evaluate();
  final anchor = const Sprint118ConnectionHealthLoader().loadAnchor();
  final review = Sprint118ConnectionHealthContract.canonicalReview;

  final record = <String, Object?>{
    'canonical_step': Sprint118ConnectionHealthContract.canonicalStep,
    'title': Sprint118ConnectionHealthContract.title,
    'document_role': 'connection-health-review-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'review_verified': report.reviewVerified,
    'required_fields': Sprint118ConnectionHealthContract.requiredFields,
    'missing_fields': report.missingFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    // The committed witnesses this review is anchored to, from the contract
    // constants -- not retyped, so the record cannot cite a path the gate never
    // opens.
    'evidence_sources': <String, String>{
      'baseline': Sprint118ConnectionHealthContract.baselineManifestPath,
      'charter': Sprint118ConnectionHealthContract.charterManifestPath,
      'state_machine':
          Sprint118ConnectionHealthContract.stateMachineManifestPath,
    },
    // Facts read from the committed witnesses, never typed.
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'baseline_release_state': anchor?.releaseState,
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_window_minutes': anchor?.charterWindowMinutes,
    'witness_connection_states': anchor?.witnessConnectionStates,
    'witness_health_states': anchor?.witnessHealthStates,
    'witness_transitions': anchor?.witnessTransitions,
    'readable_source_count': anchor?.readableSources.length,
    // The review itself, derived from the contract constants.
    'declared_signal_count': report.declaredSignals.length,
    'declared_signals': report.declaredSignals,
    'canonical_signals':
        Sprint118ConnectionHealthContract.connectionHealthSignals,
    'canonical_sources': Sprint118ConnectionHealthContract.canonicalSources,
    'no_reference_state': Sprint118ConnectionHealthContract.noReferenceState,
    'observed_count': report.observedCount,
    'entries': review.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record is the gate verdict over committed 118.4 baseline, 118.2 charter, and 115.10 connection & health state machine evidence. A pass means the declared review carries all five required fields for every one of the seven canonical connection signals; it does not probe any provider, certify any connector, or authorize any release.',
      'The review is written against the delayed release state (GA_DELAYED). No release ran, so no entry observes a connection and every entry carries at least one stated limitation.',
      'The gate reads the committed witnesses directly, derives its reference-state vocabulary from the 115.10 state machine, and verifies each entry cites a committed, readable evidence source; an unreadable witness or an unfrozen baseline keeps the review blocked rather than assumed.',
      'The reference-state vocabulary is the distinct union of the state machine connection states, health states, and transitions, read from the committed witness, so the review and the state machine cannot drift apart silently.',
      'The committed 115.10 state machine declares LATENCY and DISCONNECT_CLEANUP for the two signals; the review derives those reference states from the witness and keeps no_reference_state available for future omissions.',
      'Live connection observation, provider probing, connector certification, provider exposure, and publication remain DEFERRED-EXTERNAL; nothing here is performed or authorized.',
    ],
    'external_gates': <String>[
      'live connection observation',
      'provider probing',
      'connector certification evidence',
      'provider exposure',
      'public release publication',
    ],
  };

  final target = File(Sprint118ConnectionHealthContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(record)}\n',
  );

  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('release_state=${report.releaseState}');
  stdout.writeln('declared_signals=${report.declaredSignals.length}');
  stdout.writeln('observed_count=${report.observedCount}');
  stdout.writeln(
    'readable_source_count=${anchor?.readableSources.length ?? 0}',
  );
  stdout.writeln('blockers=${report.blockers.length}');
  stdout.writeln('violations=${report.violations.length}');
  stdout.writeln('open_items=${report.openItems.length}');
  stdout.writeln('written=${target.path}');
}
