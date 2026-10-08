// Emit the 118.4 Post-Release Health Baseline record from the gate's own report.
//
// The committed 118.3 snapshot and 118.2 charter are the evidence *input*: the
// gate reads them and decides whether the baseline is a faithful freeze of the
// declared health references. This file is the *output*: the gate's measured
// verdict plus the baseline's canonical fields, all derived from the contract
// constants and the gate's own report. Nothing here is typed by hand, so the
// record cannot be made to agree with itself.
//
// Run from the repository root:
//   dart run tool/emit_sprint_118_post_release_health_baseline.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_post_release_health_baseline.dart';

Map<String, Object?> _entry(Sprint118HealthBaselineEntry entry) =>
    <String, Object?>{
      'signal': entry.signal,
      'baseline': entry.baseline,
      'threshold': entry.threshold,
      'source': entry.source,
      'window': entry.window,
      'limitations': entry.limitations,
      'observed': entry.observed,
    };

void main() {
  const gate = Sprint118PostReleaseHealthBaselineGate();
  final report = gate.evaluate();
  final anchor = const Sprint118HealthBaselineLoader().loadAnchor();
  final baseline = Sprint118BaselineContract.canonicalBaseline;

  final record = <String, Object?>{
    'canonical_step': Sprint118BaselineContract.canonicalStep,
    'title': Sprint118BaselineContract.title,
    'document_role': 'health-baseline-evaluation-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'baseline_frozen': report.baselineFrozen,
    'required_fields': Sprint118BaselineContract.requiredFields,
    'missing_fields': report.missingFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    // The committed witnesses this baseline is anchored to, from the contract
    // constants -- not retyped, so the record cannot cite a path the gate never
    // opens.
    'evidence_sources': <String, String>{
      'snapshot': Sprint118BaselineContract.snapshotManifestPath,
      'charter': Sprint118BaselineContract.charterManifestPath,
    },
    // Facts read from the committed witnesses, never typed.
    'snapshot_state': anchor?.snapshotState,
    'snapshot_verdict': anchor?.snapshotVerdict,
    'snapshot_release_state': anchor?.releaseState,
    'charter_window_minutes': anchor?.charterWindowMinutes,
    'readable_source_count': anchor?.readableSources.length,
    // The baseline itself, derived from the contract constants.
    'canonical_areas': Sprint118BaselineContract.canonicalAreas,
    'baseline_signal_count': report.baselineSignals.length,
    'baseline_signals': report.baselineSignals,
    'observed_count': report.observedCount,
    'entries': baseline.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record is the gate verdict over committed 118.3 snapshot and 118.2 charter evidence. A pass means the baseline faithfully freezes the declared reference for each canonical health area; it does not observe any live signal, certify any connector, or authorize any release.',
      'The baseline is written against the delayed release state (GA_DELAYED). No release ran, so no entry claims an observed value and the observation window remains declared and unexecuted.',
      'The gate reads the committed snapshot and charter directly and verifies each entry source is a committed, readable file; an unreadable witness or an unfrozen snapshot keeps the baseline blocked rather than assumed.',
      'Live observation, telemetry scraping, connector certification, provider exposure, quota, cost, and credential state remain DEFERRED-EXTERNAL; nothing here is performed or authorized.',
    ],
    'external_gates': <String>[
      'live observation execution',
      'external telemetry scraping',
      'connector certification evidence',
      'provider exposure authorization',
      'public release publication',
    ],
  };

  final target = File(Sprint118BaselineContract.manifestPath);
  target.parent.createSync(recursive: true);
  target.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(record)}\n',
  );

  stdout.writeln('state=${report.state.name}');
  stdout.writeln('verdict=${report.verdict}');
  stdout.writeln('release_state=${report.releaseState}');
  stdout.writeln('baseline_signal_count=${report.baselineSignals.length}');
  stdout.writeln('observed_count=${report.observedCount}');
  stdout.writeln('blockers=${report.blockers.length}');
  stdout.writeln('violations=${report.violations.length}');
  stdout.writeln('written=${target.path}');
}
