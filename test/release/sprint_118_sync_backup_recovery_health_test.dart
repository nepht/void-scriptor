import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world_logic/domain/sprint_118_sync_backup_recovery_health.dart';

/// A single sync/backup/recovery health entry. Each test flips exactly the one
/// thing it is about, so a test that flips nothing proves the pass path exists
/// and every other test proves one way the gate refuses to take it.
Sprint118SyncBackupRecoveryHealthEntry _entry({
  String signal = 'queue_age',
  String referenceState = 'queue_age',
  String source =
      'docs/planning/v1.2/sprint_114_cloud_sync_conflict_health.json',
  int window = 1440,
  List<String>? limitations,
  bool observed = false,
}) {
  return Sprint118SyncBackupRecoveryHealthEntry(
    signal: signal,
    referenceState: referenceState,
    source: source,
    window: window,
    limitations: limitations ?? const <String>['live_observation_deferred'],
    observed: observed,
  );
}

Sprint118SyncBackupRecoveryHealthReview _review({
  String releaseState =
      Sprint118SyncBackupRecoveryHealthContract.delayedReleaseState,
  List<Sprint118SyncBackupRecoveryHealthEntry>? entries,
}) {
  return Sprint118SyncBackupRecoveryHealthReview(
    releaseState: releaseState,
    entries:
        entries ??
        Sprint118SyncBackupRecoveryHealthContract.canonicalReview.entries,
  );
}

/// The canonical entries with exactly one signal replaced, so a test can flip a
/// single field without rebuilding the whole review.
List<Sprint118SyncBackupRecoveryHealthEntry> _replacing(
  String signal,
  Sprint118SyncBackupRecoveryHealthEntry replacement,
) {
  return <Sprint118SyncBackupRecoveryHealthEntry>[
    for (final e
        in Sprint118SyncBackupRecoveryHealthContract.canonicalReview.entries)
      if (e.signal == signal) replacement else e,
  ];
}

Sprint118SyncBackupRecoveryHealthAnchor _anchor({
  String baselineState = 'pass',
  String baselineVerdict =
      Sprint118SyncBackupRecoveryHealthContract.requiredBaselineVerdict,
  String releaseState =
      Sprint118SyncBackupRecoveryHealthContract.delayedReleaseState,
  String charterState = 'pass',
  String charterVerdict =
      Sprint118SyncBackupRecoveryHealthContract.requiredCharterVerdict,
  int charterWindowMinutes =
      Sprint118SyncBackupRecoveryHealthContract.charterWindowMinutes,
  List<String>? witnessSyncEvidence,
  List<String>? witnessBackupEvidence,
  List<String>? witnessIntegrityEvidence,
  List<String>? witnessBoundaryAcceptance,
  List<String>? readableSources,
}) {
  return Sprint118SyncBackupRecoveryHealthAnchor(
    baselineState: baselineState,
    baselineVerdict: baselineVerdict,
    releaseState: releaseState,
    charterState: charterState,
    charterVerdict: charterVerdict,
    charterWindowMinutes: charterWindowMinutes,
    witnessSyncEvidence:
        witnessSyncEvidence ??
        const <String>[
          'sync_success',
          'queue_age',
          'transfer_failure',
          'retry_success',
          'conflict_rate',
          'resolution_success',
          'duplicate_effect',
        ],
    witnessBackupEvidence:
        witnessBackupEvidence ??
        const <String>[
          'backup_success',
          'encryption_success',
          'restore_success',
          'media_integrity',
          'link_integrity',
          'recovery_time',
        ],
    witnessIntegrityEvidence:
        witnessIntegrityEvidence ??
        const <String>[
          'broken_links',
          'orphan_records',
          'index_mismatch',
          'checksum_failure',
          'silent_loss_report',
          'repair_success',
        ],
    witnessBoundaryAcceptance:
        witnessBoundaryAcceptance ??
        const <String>[
          'global_user_scope',
          'no_workspace_co_ownership',
          'explicit_workspace_permission',
          'explicit_transfer_consent',
          'separate_backup_boundaries',
        ],
    readableSources:
        readableSources ??
        Sprint118SyncBackupRecoveryHealthContract.canonicalSources,
  );
}

Sprint118SyncBackupRecoveryHealthReport _run(
  Sprint118SyncBackupRecoveryHealthReview review, {
  Sprint118SyncBackupRecoveryHealthAnchor? anchor,
}) {
  return const Sprint118SyncBackupRecoveryHealthGate().evaluateWith(
    anchor ?? _anchor(),
    review,
  );
}

void main() {
  group('118.10 Sync, Backup & Recovery Health', () {
    test('declares the canonical step, title, fields, and paths', () {
      expect(Sprint118SyncBackupRecoveryHealthContract.canonicalStep, '118.10');
      expect(
        Sprint118SyncBackupRecoveryHealthContract.title,
        'Sync, Backup & Recovery Health',
      );
      expect(
        Sprint118SyncBackupRecoveryHealthContract.manifestPath,
        'docs/planning/v1.3/sprint_118_sync_backup_recovery_health.json',
      );
      expect(Sprint118SyncBackupRecoveryHealthContract.requiredFields, <String>[
        'signal',
        'reference_state',
        'source',
        'window',
        'limitations',
      ]);
      expect(
        Sprint118SyncBackupRecoveryHealthContract.externalGates,
        'DEFERRED-EXTERNAL',
      );
    });

    test('vocabularies are internally consistent', () {
      expect(
        Sprint118SyncBackupRecoveryHealthContract.requiredFields.length,
        5,
      );
      expect(
        Sprint118SyncBackupRecoveryHealthContract.syncBackupSignals.length,
        8,
      );
      expect(
        Sprint118SyncBackupRecoveryHealthContract.canonicalSources.length,
        8,
      );
      // Every canonical signal maps to a committed evidence source.
      final sources = <String>{
        for (final s
            in Sprint118SyncBackupRecoveryHealthContract.syncBackupSignals)
          Sprint118SyncBackupRecoveryHealthContract.sourceFor(s),
      };
      expect(sources.length, 8);
      // The reference-state vocabulary is the distinct union of the witness
      // vocabularies, in witness order.
      final vocab = Sprint118SyncBackupRecoveryHealthContract.stateVocabulary(
        const <List<String>>[
          <String>['queue_age', 'retry_success'],
          <String>['restore_success', 'queue_age'],
          <String>['checksum_failure', 'retry_success'],
          <String>['separate_backup_boundaries', 'restore_success'],
        ],
      );
      expect(vocab, <String>[
        'queue_age',
        'retry_success',
        'restore_success',
        'checksum_failure',
        'separate_backup_boundaries',
      ]);
    });

    test('canonical review covers the eight signals and claims no live '
        'observation', () {
      final review = Sprint118SyncBackupRecoveryHealthContract.canonicalReview;
      expect(review.signals.length, 8);
      expect(review.signals.toSet(), <String>{
        'queue_age',
        'transfer_failure',
        'retry_success',
        'conflict_rate',
        'backup_success',
        'restore_success',
        'boundary_issue',
        'integrity_issue',
      });
      for (final entry in review.entries) {
        expect(entry.observed, isFalse);
        expect(entry.window, greaterThan(0));
        expect(entry.limitations, isNotEmpty);
      }
      expect(review.observedCount, 0);
    });

    test('passes on the canonical review', () {
      final report = _run(_review());
      expect(report.state, Sprint118SyncBackupRecoveryHealthState.pass);
      expect(report.verdict, 'SYNC_BACKUP_RECOVERY_HEALTH_VERIFIED_LOCAL');
      expect(report.reviewVerified, isTrue);
      expect(report.declaredSignals.length, 8);
      expect(report.observedCount, 0);
      expect(report.violations, isEmpty);
      expect(report.blockers, isEmpty);
      expect(report.openItems, isEmpty);
    });

    test('blocks when the committed evidence is unreadable', () {
      final report = const Sprint118SyncBackupRecoveryHealthGate().evaluateWith(
        null,
        _review(),
      );
      expect(report.state, Sprint118SyncBackupRecoveryHealthState.blocked);
      expect(
        report.verdict,
        'SPRINT_118_SYNC_BACKUP_RECOVERY_HEALTH_EVIDENCE_UNREADABLE',
      );
      expect(
        report.blockers,
        contains('committed_sync_backup_recovery_evidence_unreadable'),
      );
    });

    test('blocks when the 118.4 baseline did not freeze', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          baselineVerdict: 'SPRINT_118_BASELINE_EVIDENCE_VIOLATION',
        ),
      );
      expect(report.state, Sprint118SyncBackupRecoveryHealthState.blocked);
      expect(
        report.blockers,
        contains('baseline_not_frozen:SPRINT_118_BASELINE_EVIDENCE_VIOLATION'),
      );
    });

    test('blocks when the 118.2 charter is not complete', () {
      final report = _run(
        _review(),
        anchor: _anchor(charterVerdict: 'CHARTER_INCOMPLETE'),
      );
      expect(report.state, Sprint118SyncBackupRecoveryHealthState.blocked);
      expect(
        report.blockers,
        contains('charter_not_complete:CHARTER_INCOMPLETE'),
      );
    });

    test('fails when the release state disagrees with the baseline', () {
      final report = _run(
        _review(releaseState: 'GA_RELEASED'),
        anchor: _anchor(releaseState: 'GA_DELAYED'),
      );
      expect(report.state, Sprint118SyncBackupRecoveryHealthState.fail);
      expect(
        report.violations.any((v) => v.startsWith('release_state_mismatch:')),
        isTrue,
      );
    });

    test('fails when a signal claims observation on the delayed path', () {
      final report = _run(
        _review(
          entries: _replacing(
            'restore_success',
            _entry(
              signal: 'restore_success',
              referenceState: 'restore_success',
              observed: true,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118SyncBackupRecoveryHealthState.fail);
      expect(
        report.violations,
        contains('sync_claims_observation_without_release:restore_success'),
      );
    });

    test('fails when an entry carries an unknown reference state', () {
      final report = _run(
        _review(
          entries: _replacing(
            'integrity_issue',
            _entry(signal: 'integrity_issue', referenceState: 'SOMETHING_ELSE'),
          ),
        ),
      );
      expect(report.state, Sprint118SyncBackupRecoveryHealthState.fail);
      expect(
        report.violations,
        contains(
          'entry_unknown_reference_state:integrity_issue:SOMETHING_ELSE',
        ),
      );
    });

    test('fails when an entry cites unreadable evidence', () {
      final report = _run(
        _review(
          entries: _replacing(
            'conflict_rate',
            _entry(
              signal: 'conflict_rate',
              referenceState: 'conflict_rate',
              source: 'docs/planning/missing.json',
            ),
          ),
        ),
      );
      expect(report.state, Sprint118SyncBackupRecoveryHealthState.fail);
      expect(
        report.violations,
        contains(
          'entry_unreadable_source:conflict_rate:docs/planning/missing.json',
        ),
      );
    });

    test('fails when a required field is blank', () {
      final report = _run(
        _review(
          entries: _replacing(
            'queue_age',
            _entry(signal: 'queue_age', referenceState: '   '),
          ),
        ),
      );
      expect(report.state, Sprint118SyncBackupRecoveryHealthState.fail);
      expect(
        report.violations,
        contains('entry_blank_reference_state:queue_age'),
      );
    });

    test('fails when an entry has no limitation', () {
      final report = _run(
        _review(
          entries: _replacing(
            'transfer_failure',
            _entry(signal: 'transfer_failure', limitations: const <String>[]),
          ),
        ),
      );
      expect(report.state, Sprint118SyncBackupRecoveryHealthState.fail);
      expect(
        report.violations,
        contains('entry_no_limitations:transfer_failure'),
      );
    });

    test('fails when a window is non-positive', () {
      final report = _run(
        _review(
          entries: _replacing(
            'backup_success',
            _entry(
              signal: 'backup_success',
              referenceState: 'backup_success',
              window: 0,
            ),
          ),
        ),
      );
      expect(report.state, Sprint118SyncBackupRecoveryHealthState.fail);
      expect(
        report.violations,
        contains('entry_nonpositive_window:backup_success:0'),
      );
    });

    test('fails when a window exceeds the charter window', () {
      final report = _run(
        _review(
          entries: _replacing(
            'boundary_issue',
            _entry(
              signal: 'boundary_issue',
              referenceState: 'separate_backup_boundaries',
              window: 999999,
            ),
          ),
        ),
        anchor: _anchor(charterWindowMinutes: 60480),
      );
      expect(report.state, Sprint118SyncBackupRecoveryHealthState.fail);
      expect(
        report.violations,
        contains('entry_window_exceeds_charter:boundary_issue:999999:60480'),
      );
    });

    test('fails on a duplicate signal', () {
      final entries = <Sprint118SyncBackupRecoveryHealthEntry>[
        ...Sprint118SyncBackupRecoveryHealthContract.canonicalReview.entries,
        _entry(signal: 'queue_age'),
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118SyncBackupRecoveryHealthState.fail);
      expect(report.violations, contains('signal_duplicate:queue_age'));
    });

    test('fails when a canonical signal is missing', () {
      final entries = <Sprint118SyncBackupRecoveryHealthEntry>[
        for (final e
            in Sprint118SyncBackupRecoveryHealthContract
                .canonicalReview
                .entries)
          if (e.signal != 'retry_success') e,
      ];
      final report = _run(_review(entries: entries));
      expect(report.state, Sprint118SyncBackupRecoveryHealthState.fail);
      expect(report.violations, contains('signal_missing:retry_success'));
    });

    test('fails when an entry names an unknown signal', () {
      final report = _run(
        _review(
          entries: _replacing(
            'queue_age',
            _entry(signal: 'unknown_signal', referenceState: 'queue_age'),
          ),
        ),
      );
      expect(report.state, Sprint118SyncBackupRecoveryHealthState.fail);
      // The replacement also removes the real 'queue_age' entry, so both the
      // unknown-signal and the missing-signal violations are expected.
      expect(report.violations, contains('signal_unknown:unknown_signal'));
      expect(report.violations, contains('signal_missing:queue_age'));
    });

    test('fails when a committed source is not readable', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          readableSources: <String>[
            'docs/planning/v1.2/sprint_114_cloud_sync_conflict_health.json',
          ],
        ),
      );
      expect(report.state, Sprint118SyncBackupRecoveryHealthState.fail);
      expect(
        report.violations.any((v) => v.startsWith('unreadable_source:')),
        isTrue,
      );
    });

    test('blocks when the witness vocabulary is empty', () {
      final report = _run(
        _review(),
        anchor: _anchor(
          witnessSyncEvidence: const <String>[],
          witnessBackupEvidence: const <String>[],
          witnessIntegrityEvidence: const <String>[],
          witnessBoundaryAcceptance: const <String>[],
        ),
      );
      expect(report.state, Sprint118SyncBackupRecoveryHealthState.blocked);
      expect(report.blockers, contains('upstream_sync_vocabulary_missing'));
    });

    test('sourceFor maps each signal to its committed evidence source', () {
      expect(
        Sprint118SyncBackupRecoveryHealthContract.sourceFor('queue_age'),
        'docs/planning/v1.2/sprint_114_cloud_sync_conflict_health.json',
      );
      expect(
        Sprint118SyncBackupRecoveryHealthContract.sourceFor('integrity_issue'),
        'docs/planning/v1.2/sprint_114_data_integrity_health.json',
      );
      expect(
        Sprint118SyncBackupRecoveryHealthContract.sourceFor('unknown'),
        '',
      );
    });
  });
}
