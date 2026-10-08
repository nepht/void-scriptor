// Emit the 118.10 Sync, Backup & Recovery Health record from the gate's own
// report.
//
// The committed 118.4 baseline, 118.2 charter, 114.15 cloud sync & conflict
// health, 114.14 backup & restore health, 114.12 data integrity health, and
// 115.4 workspace boundary witnesses are the evidence *input*: the gate reads
// them and decides whether the declared review is well-formed. This file is the
// *output*: the gate's measured verdict plus the review's canonical fields, all
// derived from the contract constants and the gate's own report. Nothing here is
// typed by hand, so the record cannot be made to agree with itself.
//
// Run from the repository root:
//   dart run tool/emit_sprint_118_sync_backup_recovery_health.dart
import 'dart:convert';
import 'dart:io';

import 'package:void_scriptor/features/world_logic/domain/sprint_118_sync_backup_recovery_health.dart';

Map<String, Object?> _entry(Sprint118SyncBackupRecoveryHealthEntry entry) =>
    <String, Object?>{
      'signal': entry.signal,
      'reference_state': entry.referenceState,
      'source': entry.source,
      'window': entry.window,
      'limitations': entry.limitations,
      'observed': entry.observed,
    };

void main() {
  const gate = Sprint118SyncBackupRecoveryHealthGate();
  final report = gate.evaluate();
  final anchor = const Sprint118SyncBackupRecoveryHealthLoader().loadAnchor();
  final review = Sprint118SyncBackupRecoveryHealthContract.canonicalReview;

  final record = <String, Object?>{
    'canonical_step': Sprint118SyncBackupRecoveryHealthContract.canonicalStep,
    'title': Sprint118SyncBackupRecoveryHealthContract.title,
    'document_role': 'sync-backup-recovery-health-review-record',
    'state': report.state.name,
    'verdict': report.verdict,
    'release_state': report.releaseState,
    'review_verified': report.reviewVerified,
    'required_fields': Sprint118SyncBackupRecoveryHealthContract.requiredFields,
    'missing_fields': report.missingFields,
    'violations': report.violations,
    'blockers': report.blockers,
    'open_items': report.openItems,
    // The committed witnesses this review is anchored to, from the contract
    // constants -- not retyped, so the record cannot cite a path the gate never
    // opens.
    'evidence_sources': <String, String>{
      'baseline':
          Sprint118SyncBackupRecoveryHealthContract.baselineManifestPath,
      'charter': Sprint118SyncBackupRecoveryHealthContract.charterManifestPath,
      'sync_health':
          Sprint118SyncBackupRecoveryHealthContract.syncHealthManifestPath,
      'backup_health':
          Sprint118SyncBackupRecoveryHealthContract.backupHealthManifestPath,
      'integrity_health':
          Sprint118SyncBackupRecoveryHealthContract.integrityHealthManifestPath,
      'workspace_boundary': Sprint118SyncBackupRecoveryHealthContract
          .workspaceBoundaryManifestPath,
    },
    // Facts read from the committed witnesses, never typed.
    'baseline_state': anchor?.baselineState,
    'baseline_verdict': anchor?.baselineVerdict,
    'baseline_release_state': anchor?.releaseState,
    'charter_state': anchor?.charterState,
    'charter_verdict': anchor?.charterVerdict,
    'charter_window_minutes': anchor?.charterWindowMinutes,
    'witness_sync_evidence': anchor?.witnessSyncEvidence,
    'witness_backup_evidence': anchor?.witnessBackupEvidence,
    'witness_integrity_evidence': anchor?.witnessIntegrityEvidence,
    'witness_boundary_acceptance': anchor?.witnessBoundaryAcceptance,
    'readable_source_count': anchor?.readableSources.length,
    // The review itself, derived from the contract constants.
    'declared_signal_count': report.declaredSignals.length,
    'declared_signals': report.declaredSignals,
    'canonical_signals':
        Sprint118SyncBackupRecoveryHealthContract.syncBackupSignals,
    'canonical_sources':
        Sprint118SyncBackupRecoveryHealthContract.canonicalSources,
    'observed_count': report.observedCount,
    'entries': review.entries.map(_entry).toList(),
    'claim_boundary': <String>[
      'This record is the gate verdict over committed 118.4 baseline, 118.2 charter, 114.15 cloud sync & conflict health, 114.14 backup & restore health, 114.12 data integrity health, and 115.4 workspace boundary evidence. A pass means the declared review carries all five required fields for every one of the eight canonical sync/backup/recovery signals; it does not run any sync, transfer, retry, conflict resolution, encrypted backup, restore, or credential access, and it does not authorize any release.',
      'The review is written against the delayed release state (GA_DELAYED). No release ran, so no entry observes a sync/backup/recovery reading and every entry carries at least one stated limitation.',
      'The gate reads the committed witnesses directly, derives its reference-state vocabulary from the 114.15 sync required-evidence, the 114.14 backup required-evidence, the 114.12 integrity required-evidence, and the 115.4 boundary acceptance items, and verifies each entry cites a committed, readable evidence source; an unreadable witness or an unfrozen baseline keeps the review blocked rather than assumed.',
      'The reference-state vocabulary is the distinct union of the sync, backup, integrity, and boundary witness vocabularies, read from the committed witnesses, so the review and the sync/backup/recovery contracts cannot drift apart silently.',
      'Live sync, transfer, retry, conflict resolution, encrypted backup, restore, credential access, connector certification, provider exposure, and publication remain DEFERRED-EXTERNAL; nothing here is performed or authorized.',
    ],
    'external_gates': <String>[
      'live cloud sync and transfer',
      'bounded retry and circuit-breaker execution',
      'conflict resolution execution',
      'encrypted backup execution',
      'clean-install restore execution',
      'credential and token access',
      'connector certification evidence',
      'provider exposure',
      'public release publication',
    ],
  };

  final target = File(Sprint118SyncBackupRecoveryHealthContract.manifestPath);
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
