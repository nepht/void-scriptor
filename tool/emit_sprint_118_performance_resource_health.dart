// Emit the 118.16 Performance & Resource Health record from the gate's own
// report.
//
// The committed 118.4 baseline, 118.2 charter, 114.16 performance &
// responsiveness health, 114.17 memory, storage & cache health, and 115.53
// performance & provider resilience witnesses are the evidence *input*: the gate
// reads them and decides whether the declared review is well-formed. This file
// is the *output*: the gate's measured verdict plus the review's canonical
// fields, all derived from the contract constants and the gate's own report.
// Nothing here is typed by hand, so the record cannot be made to agree with
// itself.
//
// Run from the repository root:
//   dart run tool/emit_sprint_118_performance_resource_health.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_performance_resource_health.dart';

Map<String, Object?> _entry(Sprint118PerformanceResourceHealthEntry entry) =>
    <String, Object?>{
      'signal': entry.signal,
      'reference_state': entry.referenceState,
      'source': entry.source,
      'window': entry.window,
      'limitations': entry.limitations,
      'observed': entry.observed,
    };

void main() {
  const gate = Sprint118PerformanceResourceHealthGate();
  final report = gate.evaluate();
  final anchor = const Sprint118PerformanceResourceHealthLoader().loadAnchor();
  final review = Sprint118PerformanceResourceHealthContract.canonicalReview;

  final record = <String, Object?>{
    'canonical_step': Sprint118PerformanceResourceHealthContract.canonicalStep,
    'title': Sprint118PerformanceResourceHealthContract.title,
    'document_role': 'performance-resource-health-review-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'review_verified': report.reviewVerified,
    'required_fields':
        Sprint118PerformanceResourceHealthContract.requiredFields,
    'missing_fields': report.missingFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    // The committed witnesses this review is anchored to, from the contract
    // constants -- not retyped, so the record cannot cite a path the gate never
    // opens.
    'evidence_sources': <String, String>{
      'baseline':
          Sprint118PerformanceResourceHealthContract.baselineManifestPath,
      'charter': Sprint118PerformanceResourceHealthContract.charterManifestPath,
      'performance_responsiveness': Sprint118PerformanceResourceHealthContract
          .performanceResponsivenessManifestPath,
      'memory_storage_cache': Sprint118PerformanceResourceHealthContract
          .memoryStorageCacheManifestPath,
      'performance_resilience': Sprint118PerformanceResourceHealthContract
          .performanceResilienceManifestPath,
    },
    // Facts read from the committed witnesses, never typed.
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'baseline_release_state': anchor?.releaseState,
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_window_minutes': anchor?.charterWindowMinutes,
    'witness_performance_responsiveness':
        anchor?.witnessPerformanceResponsiveness,
    'witness_memory_storage_cache': anchor?.witnessMemoryStorageCache,
    'witness_performance_resilience': anchor?.witnessPerformanceResilience,
    'readable_source_count': anchor?.readableSources.length,
    // The review itself, derived from the contract constants.
    'declared_signal_count': report.declaredSignals.length,
    'declared_signals': report.declaredSignals,
    'canonical_signals':
        Sprint118PerformanceResourceHealthContract.performanceSignals,
    'canonical_sources':
        Sprint118PerformanceResourceHealthContract.canonicalSources,
    'observed_count': report.observedCount,
    'entries': review.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record is the gate verdict over committed 118.4 baseline, 118.2 charter, 114.16 performance & responsiveness health, 114.17 memory, storage & cache health, and 115.53 performance & provider resilience evidence. A pass means the declared review carries all five required fields for every one of the eight canonical performance signals; it does not run any profile-mode FrameTiming capture, measure any cold-start wall clock, read any live process heap/RSS, measure any native disk growth, observe any live network egress, or authorize any release.',
      'The review is written against the delayed release state (GA_DELAYED). No release ran, so no entry observes a live profile-mode run, a real frame timing, or a real resource reading and every entry carries at least one stated limitation.',
      'The gate reads the committed witnesses directly, derives its reference-state vocabulary from the 114.16 performance & responsiveness health required evidence, the 114.17 memory, storage & cache health required evidence, and the 115.53 performance & provider resilience required outputs, and verifies each entry cites a committed, readable evidence source; an unreadable witness or an unfrozen baseline keeps the review blocked rather than assumed.',
      'The reference-state vocabulary is the distinct union of the performance & responsiveness, memory/storage/cache, and performance & provider resilience witness vocabularies, read from the committed witnesses, so the review and the performance contracts cannot drift apart silently.',
      'The 118.16 objective names charts and network use explicitly, but the committed performance witnesses declare no chart-specific latency state or network-use state; rather than widen the gate silently or drop the requirement, the review carries the declared no_reference_state marker for chart_latency and network and the gate records the upstream omission as an open item (upstream_state_vocabulary_gap:chart_latency, upstream_state_vocabulary_gap:network).',
      'Live profile-mode FrameTiming, cold-start native GUI timing, real process heap/RSS, native disk growth, real network egress, release authorization, and publication remain DEFERRED-EXTERNAL; nothing here is performed or authorized.',
    ],
    'external_gates': <String>[
      'profile-mode FrameTiming capture',
      'cold-start native GUI timing',
      'real process heap/RSS measurement',
      'native disk growth measurement',
      'live network egress observation',
      'release authorization',
      'public release publication',
    ],
  };

  final target = File(Sprint118PerformanceResourceHealthContract.manifestPath);
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
