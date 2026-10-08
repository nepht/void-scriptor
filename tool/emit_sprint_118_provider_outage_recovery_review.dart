// Emit the 118.17 Provider Outage & Recovery Review record from the gate's own
// report.
//
// The committed 118.4 baseline, 118.2 charter, 116.43 retry, backoff & circuit
// breaker certification, 114.25 provider & external dependency health, 114.18
// offline & local-first health, 117.8 provider rollback drill, and 116.44
// offline & cached metadata certification witnesses are the evidence *input*:
// the gate reads them and decides whether the declared review is well-formed.
// This file is the *output*: the gate's measured verdict plus the review's
// canonical fields, all derived from the contract constants and the gate's own
// report. Nothing here is typed by hand, so the record cannot be made to agree
// with itself.
//
// Run from the repository root:
//   dart run tool/emit_sprint_118_provider_outage_recovery_review.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_provider_outage_recovery_review.dart';

Map<String, Object?> _entry(Sprint118ProviderOutageRecoveryEntry entry) =>
    <String, Object?>{
      'signal': entry.signal,
      'reference_state': entry.referenceState,
      'source': entry.source,
      'window': entry.window,
      'limitations': entry.limitations,
      'observed': entry.observed,
    };

void main() {
  const gate = Sprint118ProviderOutageRecoveryGate();
  final report = gate.evaluate();
  final anchor = const Sprint118ProviderOutageRecoveryLoader().loadAnchor();
  final review = Sprint118ProviderOutageRecoveryContract.canonicalReview;

  final record = <String, Object?>{
    'canonical_step': Sprint118ProviderOutageRecoveryContract.canonicalStep,
    'title': Sprint118ProviderOutageRecoveryContract.title,
    'document_role': 'provider-outage-recovery-review-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'review_verified': report.reviewVerified,
    'required_fields': Sprint118ProviderOutageRecoveryContract.requiredFields,
    'missing_fields': report.missingFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    // The committed witnesses this review is anchored to, from the contract
    // constants -- not retyped, so the record cannot cite a path the gate never
    // opens.
    'evidence_sources': <String, String>{
      'baseline': Sprint118ProviderOutageRecoveryContract.baselineManifestPath,
      'charter': Sprint118ProviderOutageRecoveryContract.charterManifestPath,
      'retry_backoff_circuit_breaker': Sprint118ProviderOutageRecoveryContract
          .retryBackoffCircuitBreakerManifestPath,
      'provider_dependency': Sprint118ProviderOutageRecoveryContract
          .providerDependencyManifestPath,
      'offline_local_first':
          Sprint118ProviderOutageRecoveryContract.offlineLocalFirstManifestPath,
      'rollback_drill':
          Sprint118ProviderOutageRecoveryContract.rollbackDrillManifestPath,
      'offline_cached_metadata': Sprint118ProviderOutageRecoveryContract
          .offlineCachedMetadataManifestPath,
    },
    // Facts read from the committed witnesses, never typed.
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'baseline_release_state': anchor?.releaseState,
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_window_minutes': anchor?.charterWindowMinutes,
    'witness_retry_backoff_circuit_breaker':
        anchor?.witnessRetryBackoffCircuitBreaker,
    'witness_provider_dependency': anchor?.witnessProviderDependency,
    'witness_offline_local_first': anchor?.witnessOfflineLocalFirst,
    'witness_rollback_drill': anchor?.witnessRollbackDrill,
    'witness_offline_cached_metadata': anchor?.witnessOfflineCachedMetadata,
    'readable_source_count': anchor?.readableSources.length,
    // The review itself, derived from the contract constants.
    'declared_signal_count': report.declaredSignals.length,
    'declared_signals': report.declaredSignals,
    'canonical_signals':
        Sprint118ProviderOutageRecoveryContract.outageRecoverySignals,
    'canonical_sources':
        Sprint118ProviderOutageRecoveryContract.canonicalSources,
    'observed_count': report.observedCount,
    'entries': review.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record is the gate verdict over committed 118.4 baseline, 118.2 charter, 116.43 retry, backoff & circuit breaker certification, 114.25 provider & external dependency health, 114.18 offline & local-first health, 117.8 provider rollback drill, and 116.44 offline & cached metadata certification evidence. A pass means the declared review carries all five required fields for every one of the seven canonical outage/recovery signals; it does not inject any provider outage, trip any circuit breaker, read any live retry-after header, drain or restart any queue, engage any kill switch, or authorize any release.',
      'The review is written against the delayed release state (GA_DELAYED). No release ran, so no entry observes a live outage, a real breaker trip, a real retry-after header, or a real queue drain and every entry carries at least one stated limitation.',
      'The gate reads the committed witnesses directly, derives its reference-state vocabulary from the 116.43 retry, backoff & circuit breaker certification acceptance areas, the 114.25 provider & external dependency health signals, the 114.18 offline & local-first health required evidence, the 117.8 provider rollback drill required controls, and the 116.44 offline & cached metadata certification acceptance areas, and verifies each entry cites a committed, readable evidence source; an unreadable witness or an unfrozen baseline keeps the review blocked rather than assumed.',
      'The reference-state vocabulary is the distinct union of the retry/backoff/circuit-breaker, provider/external-dependency, offline/local-first, rollback-drill, and offline/cached-metadata witness vocabularies, read from the committed witnesses, so the review and the outage/recovery contracts cannot drift apart silently.',
      'All seven canonical outage/recovery signals have a witness state: timeout and provider_recovery draw from the 114.25 provider & external dependency health (timeout, fallback_success), circuit_breaker and retry_after from the 116.43 retry, backoff & circuit breaker certification, queue_recovery from the 114.18 offline & local-first health, cached_state from the 116.44 offline & cached metadata certification (stale_state), and kill_switch from the 117.8 provider rollback drill, so no no_reference_state marker is needed and no upstream gap is recorded.',
      'Live provider outage injection, real circuit-breaker trips, live retry-after header reads, real queue drain/restart, live kill-switch engagement, release authorization, and publication remain DEFERRED-EXTERNAL; nothing here is performed or authorized.',
    ],
    'external_gates': <String>[
      'live provider outage injection',
      'real circuit-breaker trip',
      'live retry-after header read',
      'real queue drain/restart',
      'live kill-switch engagement',
      'release authorization',
      'public release publication',
    ],
  };

  final target = File(Sprint118ProviderOutageRecoveryContract.manifestPath);
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
