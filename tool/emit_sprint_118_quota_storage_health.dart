// Emit the 118.9 Quota & Storage Health record from the gate's own report.
//
// The committed 118.4 baseline, 118.2 charter, 116.41 quota contract, and the
// 115 provider quota adapter / local storage summary / cloud storage
// aggregation witnesses are the evidence *input*: the gate reads them and
// decides whether the declared review is well-formed. This file is the
// *output*: the gate's measured verdict plus the review's canonical fields, all
// derived from the contract constants and the gate's own report. Nothing here is
// typed by hand, so the record cannot be made to agree with itself.
//
// Run from the repository root:
//   dart run tool/emit_sprint_118_quota_storage_health.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_quota_storage_health.dart';

Map<String, Object?> _entry(Sprint118QuotaStorageHealthEntry entry) =>
    <String, Object?>{
      'signal': entry.signal,
      'reference_state': entry.referenceState,
      'source': entry.source,
      'window': entry.window,
      'limitations': entry.limitations,
      'observed': entry.observed,
    };

void main() {
  const gate = Sprint118QuotaStorageHealthGate();
  final report = gate.evaluate();
  final anchor = const Sprint118QuotaStorageHealthLoader().loadAnchor();
  final review = Sprint118QuotaStorageHealthContract.canonicalReview;

  final record = <String, Object?>{
    'canonical_step': Sprint118QuotaStorageHealthContract.canonicalStep,
    'title': Sprint118QuotaStorageHealthContract.title,
    'document_role': 'quota-storage-health-review-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'review_verified': report.reviewVerified,
    'required_fields': Sprint118QuotaStorageHealthContract.requiredFields,
    'missing_fields': report.missingFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    // The committed witnesses this review is anchored to, from the contract
    // constants -- not retyped, so the record cannot cite a path the gate never
    // opens.
    'evidence_sources': <String, String>{
      'baseline': Sprint118QuotaStorageHealthContract.baselineManifestPath,
      'charter': Sprint118QuotaStorageHealthContract.charterManifestPath,
      'quota_contract':
          Sprint118QuotaStorageHealthContract.quotaContractManifestPath,
      'quota_adapter':
          Sprint118QuotaStorageHealthContract.quotaAdapterManifestPath,
      'local_storage':
          Sprint118QuotaStorageHealthContract.localStorageManifestPath,
      'aggregation':
          Sprint118QuotaStorageHealthContract.aggregationManifestPath,
    },
    // Facts read from the committed witnesses, never typed.
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'baseline_release_state': anchor?.releaseState,
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_window_minutes': anchor?.charterWindowMinutes,
    'witness_quota_acceptance': anchor?.witnessQuotaAcceptance,
    'witness_adapter_acceptance': anchor?.witnessAdapterAcceptance,
    'witness_local_acceptance': anchor?.witnessLocalAcceptance,
    'witness_aggregation_acceptance': anchor?.witnessAggregationAcceptance,
    'readable_source_count': anchor?.readableSources.length,
    // The review itself, derived from the contract constants.
    'declared_signal_count': report.declaredSignals.length,
    'declared_signals': report.declaredSignals,
    'canonical_signals':
        Sprint118QuotaStorageHealthContract.quotaStorageSignals,
    'canonical_sources': Sprint118QuotaStorageHealthContract.canonicalSources,
    'observed_count': report.observedCount,
    'entries': review.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record is the gate verdict over committed 118.4 baseline, 118.2 charter, 116.41 quota cross-provider contract, and 115 provider quota adapter / local storage summary / cloud storage aggregation evidence. A pass means the declared review carries all five required fields for every one of the seven canonical quota/storage signals; it does not read any live provider quota, scan any device, access any credential, or authorize any release.',
      'The review is written against the delayed release state (GA_DELAYED). No release ran, so no entry observes a quota reading and every entry carries at least one stated limitation.',
      'The gate reads the committed witnesses directly, derives its reference-state vocabulary from the 116.41 quota acceptance items and the 115 adapter / local storage / aggregation acceptance items, and verifies each entry cites a committed, readable evidence source; an unreadable witness or an unfrozen baseline keeps the review blocked rather than assumed.',
      'The reference-state vocabulary is the distinct union of the quota and storage witness acceptance items, read from the committed witnesses, so the review and the quota/storage contracts cannot drift apart silently.',
      'Live provider quota reads, storage scans, credential access, connector certification, provider exposure, and publication remain DEFERRED-EXTERNAL; nothing here is performed or authorized.',
    ],
    'external_gates': <String>[
      'live provider quota and usage reads',
      'device storage scans',
      'credential and token access',
      'connector certification evidence',
      'provider exposure',
      'public release publication',
    ],
  };

  final target = File(Sprint118QuotaStorageHealthContract.manifestPath);
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
