// Emit the 118.8 OAuth & Reauthentication Health record from the gate's own
// report.
//
// The committed 118.4 baseline, 118.2 charter, 115.11 OAuth flow witness, and
// 115.43 reauthentication witness are the evidence *input*: the gate reads them
// and decides whether the declared review is well-formed. This file is the
// *output*: the gate's measured verdict plus the review's canonical fields, all
// derived from the contract constants and the gate's own report. Nothing here is
// typed by hand, so the record cannot be made to agree with itself.
//
// Run from the repository root:
//   dart run tool/emit_sprint_118_oauth_reauth_health.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_oauth_reauth_health.dart';

Map<String, Object?> _entry(Sprint118OAuthReauthHealthEntry entry) =>
    <String, Object?>{
      'signal': entry.signal,
      'reference_state': entry.referenceState,
      'source': entry.source,
      'window': entry.window,
      'limitations': entry.limitations,
      'observed': entry.observed,
    };

void main() {
  const gate = Sprint118OAuthReauthHealthGate();
  final report = gate.evaluate();
  final anchor = const Sprint118OAuthReauthHealthLoader().loadAnchor();
  final review = Sprint118OAuthReauthHealthContract.canonicalReview;

  final record = <String, Object?>{
    'canonical_step': Sprint118OAuthReauthHealthContract.canonicalStep,
    'title': Sprint118OAuthReauthHealthContract.title,
    'document_role': 'oauth-reauth-health-review-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'review_verified': report.reviewVerified,
    'required_fields': Sprint118OAuthReauthHealthContract.requiredFields,
    'missing_fields': report.missingFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    // The committed witnesses this review is anchored to, from the contract
    // constants -- not retyped, so the record cannot cite a path the gate never
    // opens.
    'evidence_sources': <String, String>{
      'baseline': Sprint118OAuthReauthHealthContract.baselineManifestPath,
      'charter': Sprint118OAuthReauthHealthContract.charterManifestPath,
      'oauth_flow': Sprint118OAuthReauthHealthContract.oauthFlowManifestPath,
      'reauth': Sprint118OAuthReauthHealthContract.reauthManifestPath,
    },
    // Facts read from the committed witnesses, never typed.
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'baseline_release_state': anchor?.releaseState,
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_window_minutes': anchor?.charterWindowMinutes,
    'witness_oauth_surfaces': anchor?.witnessOAuthSurfaces,
    'witness_reauth_acceptance': anchor?.witnessReauthAcceptance,
    'readable_source_count': anchor?.readableSources.length,
    // The review itself, derived from the contract constants.
    'declared_signal_count': report.declaredSignals.length,
    'declared_signals': report.declaredSignals,
    'canonical_signals': Sprint118OAuthReauthHealthContract.oauthHealthSignals,
    'canonical_sources': Sprint118OAuthReauthHealthContract.canonicalSources,
    'observed_count': report.observedCount,
    'entries': review.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record is the gate verdict over committed 118.4 baseline, 118.2 charter, 115.11 OAuth flow, and 115.43 reauthentication evidence. A pass means the declared review carries all five required fields for every one of the six canonical OAuth signals; it does not perform a live OAuth exchange, probe any provider, access any credential, or authorize any release.',
      'The review is written against the delayed release state (GA_DELAYED). No release ran, so no entry observes an authentication and every entry carries at least one stated limitation.',
      'The gate reads the committed witnesses directly, derives its reference-state vocabulary from the 115.11 OAuth flow surfaces and the 115.43 reauthentication acceptance items, and verifies each entry cites a committed, readable evidence source; an unreadable witness or an unfrozen baseline keeps the review blocked rather than assumed.',
      'The reference-state vocabulary is the distinct union of the OAuth flow protocol surfaces and the reauthentication acceptance items, read from the committed witnesses, so the review and the OAuth/reauthentication contracts cannot drift apart silently.',
      'Live OAuth exchange, provider probing, credential access, connector certification, provider exposure, and publication remain DEFERRED-EXTERNAL; nothing here is performed or authorized.',
    ],
    'external_gates': <String>[
      'live OAuth authorization-code exchange',
      'provider probing',
      'credential and token access',
      'connector certification evidence',
      'provider exposure',
      'public release publication',
    ],
  };

  final target = File(Sprint118OAuthReauthHealthContract.manifestPath);
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
