// Emit the 118.18 Security Health Review record from the gate's own report.
//
// The committed 118.4 baseline, 118.2 charter, 116.45 security certification
// gate, 115.12 secure token & secret vault, 115.33 session & device management,
// 115.11 OAuth & linked identity flow, and 116.6 credential & secret test
// safety witnesses are the evidence *input*: the gate reads them and decides
// whether the declared review is well-formed. This file is the *output*: the
// gate's measured verdict plus the review's canonical fields, all derived from
// the contract constants and the gate's own report. Nothing here is typed by
// hand, so the record cannot be made to agree with itself.
//
// Run from the repository root:
//   dart run tool/emit_sprint_118_security_health_review.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_security_health_review.dart';

Map<String, Object?> _entry(Sprint118SecurityHealthEntry entry) =>
    <String, Object?>{
      'signal': entry.signal,
      'reference_state': entry.referenceState,
      'source': entry.source,
      'window': entry.window,
      'limitations': entry.limitations,
      'observed': entry.observed,
    };

void main() {
  const gate = Sprint118SecurityHealthGate();
  final report = gate.evaluate();
  final anchor = const Sprint118SecurityHealthLoader().loadAnchor();
  final review = Sprint118SecurityHealthContract.canonicalReview;

  final record = <String, Object?>{
    'canonical_step': Sprint118SecurityHealthContract.canonicalStep,
    'title': Sprint118SecurityHealthContract.title,
    'document_role': 'security-health-review-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'review_verified': report.reviewVerified,
    'required_fields': Sprint118SecurityHealthContract.requiredFields,
    'missing_fields': report.missingFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    // The committed witnesses this review is anchored to, from the contract
    // constants -- not retyped, so the record cannot cite a path the gate never
    // opens.
    'evidence_sources': <String, String>{
      'baseline': Sprint118SecurityHealthContract.baselineManifestPath,
      'charter': Sprint118SecurityHealthContract.charterManifestPath,
      'security_certification':
          Sprint118SecurityHealthContract.securityCertificationManifestPath,
      'token_vault': Sprint118SecurityHealthContract.tokenVaultManifestPath,
      'session_device':
          Sprint118SecurityHealthContract.sessionDeviceManifestPath,
      'oauth_identity':
          Sprint118SecurityHealthContract.oauthIdentityManifestPath,
      'credential_safety':
          Sprint118SecurityHealthContract.credentialSafetyManifestPath,
    },
    // Facts read from the committed witnesses, never typed.
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'baseline_release_state': anchor?.releaseState,
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_window_minutes': anchor?.charterWindowMinutes,
    'witness_security_certification': anchor?.witnessSecurityCertification,
    'witness_token_vault': anchor?.witnessTokenVault,
    'witness_session_device': anchor?.witnessSessionDevice,
    'witness_oauth_identity': anchor?.witnessOAuthIdentity,
    'witness_credential_safety': anchor?.witnessCredentialSafety,
    'readable_source_count': anchor?.readableSources.length,
    // The review itself, derived from the contract constants.
    'declared_signal_count': report.declaredSignals.length,
    'declared_signals': report.declaredSignals,
    'canonical_signals': Sprint118SecurityHealthContract.securitySignals,
    'canonical_sources': Sprint118SecurityHealthContract.canonicalSources,
    'observed_count': report.observedCount,
    'entries': review.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record is the gate verdict over committed 118.4 baseline, 118.2 charter, 116.45 security certification gate, 115.12 secure token & secret vault, 115.33 session & device management, 115.11 OAuth & linked identity flow, and 116.6 credential & secret test safety evidence. A pass means the declared review carries all five required fields for every one of the eight canonical security signals; it does not perform any live OAuth handshake, read any real vault or key custody backend, revoke any live session, enforce any runtime permission, contact any production redirect allow-list, verify any real webhook signature, run any live dependency advisory scan, or authorize any release.',
      'The review is written against the delayed release state (GA_DELAYED). No release ran, so no entry observes a live OAuth alert, a real vault read, a real session revocation, or a real dependency advisory and every entry carries at least one stated limitation.',
      'The gate reads the committed witnesses directly, derives its reference-state vocabulary from the 116.45 security certification gate acceptance areas, the 115.12 secure token & secret vault acceptance items, the 115.33 session & device management acceptance items, the 115.11 OAuth & linked identity flow acceptance items, and the 116.6 credential & secret test safety required controls, and verifies each entry cites a committed, readable evidence source; an unreadable witness or an unfrozen baseline keeps the review blocked rather than assumed.',
      'The reference-state vocabulary is the distinct union of the security-certification, token-vault, session-device, oauth-identity, and credential-safety witness vocabularies, read from the committed witnesses, so the review and the security contracts cannot drift apart silently.',
      'All eight canonical security signals have a witness state: oauth_alert, permission_denial, redirect_alert, webhook_alert, and dependency_alert draw from the 116.45 security certification gate (oauth_tests, permission_tests, redirect_tests, webhook_tests, dependency_scan), vault_health from the 115.12 secure token & secret vault (os_secure_store), session_alert from the 115.33 session & device management (security_alert), and redaction_failure from the 116.6 credential & secret test safety (redaction), so no no_reference_state marker is needed and no upstream gap is recorded.',
      'Live OAuth handshakes, real vault and key custody, live session revocation, runtime permission enforcement, production redirect allow-lists, real webhook signature verification, live dependency advisory scans, release authorization, and publication remain DEFERRED-EXTERNAL; nothing here is performed or authorized.',
    ],
    'external_gates': <String>[
      'live OAuth handshake',
      'real vault and key custody read',
      'live session revocation',
      'runtime permission enforcement',
      'production redirect allow-list',
      'real webhook signature verification',
      'live dependency advisory scan',
      'release authorization',
      'public release publication',
    ],
  };

  final target = File(Sprint118SecurityHealthContract.manifestPath);
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
