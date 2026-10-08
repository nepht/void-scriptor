/// Fail-closed Sync, Backup & Recovery health review for roadmap step 118.10 --
/// Sync, Backup & Recovery Health.
///
/// Objective (external canonical `sprint_118.json`): monitor queue, transfer,
/// retry, conflict, encrypted backup, restore, workspace boundaries, and data
/// integrity. The canonical signal list is exactly eight items:
/// `queue_age`, `transfer_failure`, `retry_success`, `conflict_rate`,
/// `backup_success`, `restore_success`, `boundary_issue`, and `integrity_issue`.
///
/// This is the review the delayed corrective path (Sprint 118 on `GA_DELAYED`)
/// registers *before* any live observation runs. The gate answers a single
/// question: does the declared review carry, for every canonical
/// sync/backup/recovery signal, a reference state drawn from the committed
/// sync/backup/integrity/boundary witnesses, a committed readable evidence
/// source, a positive window bounded by the charter, and a stated limitation --
/// while claiming no live observation?
///
/// The gate is fail-closed on these families of rules:
///
/// * The committed 118.4 baseline anchor must be a genuine frozen baseline
///   (`pass` on `POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL`). A review built on
///   a baseline that did not freeze describes sync/backup readings nobody
///   measured.
/// * The committed 118.2 charter anchor must be complete
///   (`CHARTER_COMPLETE_LOCAL`); the review is bound to the charter's declared
///   observation window.
/// * The review's release state must agree with the baseline anchor.
/// * On the delayed path no signal may claim an observation: with no release, an
///   observation describes a sync queue, transfer, or restore that never ran.
///   Refused by name, per signal.
/// * Every canonical signal must be present exactly once, must carry a
///   non-blank reference state, a committed readable source, a positive window
///   no larger than the charter window, and at least one stated limitation.
/// * Every reference state must be drawn from the committed 114.15 cloud sync
///   conflict health, 114.14 backup & restore health, and 114.12 data integrity
///   health required-evidence vocabularies, plus the committed 115.4 workspace
///   boundary acceptance items, so the review and the sync/backup contracts
///   cannot drift apart.
///
/// Live sync, transfer, retry, conflict resolution, encrypted backup, restore,
/// credential access, connector certification, provider exposure, release
/// authorization, and publication remain `DEFERRED-EXTERNAL`; this review
/// freezes local declared state and executes none of it.
library;

import 'dart:convert';
import 'dart:io';

/// The three states a sync/backup/recovery review can rest in. `blocked` is the
/// honest resting state for "this review cannot yet be trusted", and it is
/// distinct from `fail`, which means the review contradicts its own evidence.
enum Sprint118SyncBackupRecoveryHealthState { pass, fail, blocked }

/// One sync/backup/recovery entry: the declared reference for a single
/// canonical signal, with the boundary it was frozen under.
class Sprint118SyncBackupRecoveryHealthEntry {
  const Sprint118SyncBackupRecoveryHealthEntry({
    required this.signal,
    required this.referenceState,
    required this.source,
    required this.window,
    required this.limitations,
    this.observed = false,
  });

  /// The sync/backup/recovery signal, drawn from the canonical vocabulary.
  final String signal;

  /// The declared reference state, drawn from the committed sync/backup
  /// witness vocabulary.
  final String referenceState;

  /// The committed evidence file this reference is anchored to.
  final String source;

  /// The measurement window in minutes.
  final int window;

  /// The limitations the reference was frozen under. At least one is required so
  /// the review cannot imply live sync/backup activity.
  final List<String> limitations;

  /// Whether the entry claims an observed value. On the delayed path this must
  /// stay `false`.
  final bool observed;
}

/// The declared review. `entries` is the review surface for the delayed
/// corrective path; on that path no entry may claim an observation.
class Sprint118SyncBackupRecoveryHealthReview {
  const Sprint118SyncBackupRecoveryHealthReview({
    required this.releaseState,
    required this.entries,
  });

  final String releaseState;
  final List<Sprint118SyncBackupRecoveryHealthEntry> entries;

  List<String> get signals => <String>[
    for (final entry in entries) entry.signal,
  ];

  int get observedCount => entries.where((entry) => entry.observed).length;
}

/// What the committed 118.4 baseline, 118.2 charter, and sync/backup witnesses
/// actually say. A review is only as honest as the witnesses it reads.
class Sprint118SyncBackupRecoveryHealthAnchor {
  const Sprint118SyncBackupRecoveryHealthAnchor({
    required this.baselineState,
    required this.baselineVerdict,
    required this.releaseState,
    required this.charterState,
    required this.charterVerdict,
    required this.charterWindowMinutes,
    required this.witnessSyncEvidence,
    required this.witnessBackupEvidence,
    required this.witnessIntegrityEvidence,
    required this.witnessBoundaryAcceptance,
    required this.readableSources,
  });

  final String baselineState;
  final String baselineVerdict;
  final String releaseState;
  final String charterState;
  final String charterVerdict;
  final int charterWindowMinutes;

  /// The required-evidence signals the committed 114.15 cloud sync & conflict
  /// health contract declares.
  final List<String> witnessSyncEvidence;

  /// The required-evidence signals the committed 114.14 backup & restore health
  /// contract declares.
  final List<String> witnessBackupEvidence;

  /// The required-evidence signals the committed 114.12 data integrity health
  /// contract declares.
  final List<String> witnessIntegrityEvidence;

  /// The acceptance items the committed 115.4 workspace boundary contract
  /// declares.
  final List<String> witnessBoundaryAcceptance;

  /// The committed evidence paths present and readable on disk.
  final List<String> readableSources;
}

/// The measured result. `pass` means the review is well-formed; `blocked` means
/// it cannot yet be trusted; `fail` means it contradicts its evidence.
class Sprint118SyncBackupRecoveryHealthReport {
  const Sprint118SyncBackupRecoveryHealthReport({
    required this.state,
    required this.verdict,
    required this.releaseState,
    this.missingFields = const <String>[],
    this.violations = const <String>[],
    this.blockers = const <String>[],
    this.openItems = const <String>[],
    this.declaredSignals = const <String>[],
    this.observedCount = 0,
  });

  final Sprint118SyncBackupRecoveryHealthState state;
  final String verdict;
  final String releaseState;
  final List<String> missingFields;
  final List<String> violations;
  final List<String> blockers;
  final List<String> openItems;
  final List<String> declaredSignals;
  final int observedCount;

  /// Whether the review may be treated as well-formed. Only a genuine `pass`
  /// allows it.
  bool get reviewVerified =>
      state == Sprint118SyncBackupRecoveryHealthState.pass;

  String get externalGates =>
      Sprint118SyncBackupRecoveryHealthContract.externalGates;
}

/// The fixed vocabulary of step 118.10, kept in one place so the loader, the
/// gate, and the emitter cannot drift apart about what the step is made of.
abstract final class Sprint118SyncBackupRecoveryHealthContract {
  const Sprint118SyncBackupRecoveryHealthContract._();

  static const String canonicalStep = '118.10';
  static const String title = 'Sync, Backup & Recovery Health';

  static const String manifestPath =
      'docs/planning/v1.3/sprint_118_sync_backup_recovery_health.json';
  static const String ledgerPath =
      'docs/sprints/sprint-118-account-cloud-center-stability.md';

  /// The committed 118.4 baseline this review is anchored to.
  static const String baselineManifestPath =
      'docs/planning/v1.3/sprint_118_post_release_health_baseline.json';

  /// The committed 118.2 charter that declares the observation window.
  static const String charterManifestPath =
      'docs/planning/v1.3/sprint_118_stability_expansion_charter.json';

  /// The committed 114.15 cloud sync & conflict health contract that declares
  /// the sync required-evidence signals this review references.
  static const String syncHealthManifestPath =
      'docs/planning/v1.2/sprint_114_cloud_sync_conflict_health.json';

  /// The committed 114.14 backup & restore health contract that declares the
  /// backup required-evidence signals this review references.
  static const String backupHealthManifestPath =
      'docs/planning/v1.2/sprint_114_backup_restore_health.json';

  /// The committed 114.12 data integrity health contract that declares the
  /// integrity required-evidence signals this review references.
  static const String integrityHealthManifestPath =
      'docs/planning/v1.2/sprint_114_data_integrity_health.json';

  /// The committed 115.4 workspace boundary contract that declares the boundary
  /// acceptance items this review references.
  static const String workspaceBoundaryManifestPath =
      'docs/planning/v1.2/sprint_115_workspace_boundary_contract.json';

  static const String externalGates = 'DEFERRED-EXTERNAL';

  /// The verdict and state the 118.4 baseline anchor must carry.
  static const String requiredBaselineVerdict =
      'POST_RELEASE_HEALTH_BASELINE_FROZEN_LOCAL';
  static const String requiredBaselineState = 'pass';

  /// The verdict and state the 118.2 charter anchor must carry.
  static const String requiredCharterVerdict = 'CHARTER_COMPLETE_LOCAL';
  static const String requiredCharterState = 'pass';

  static const String delayedReleaseState = 'GA_DELAYED';

  /// The five canonical entry fields from `sprint_118.json` step 118.10.
  static const List<String> requiredFields = <String>[
    'signal',
    'reference_state',
    'source',
    'window',
    'limitations',
  ];

  /// The eight canonical sync/backup/recovery signals the objective names.
  static const List<String> syncBackupSignals = <String>[
    'queue_age',
    'transfer_failure',
    'retry_success',
    'conflict_rate',
    'backup_success',
    'restore_success',
    'boundary_issue',
    'integrity_issue',
  ];

  /// The charter's declared observation window, in minutes: 42 days.
  static const int charterWindowMinutes = 42 * 24 * 60;

  /// The committed evidence source registered for each canonical signal, in
  /// canonical-signal order.
  static const List<String> canonicalSources = <String>[
    'docs/planning/v1.2/sprint_114_cloud_sync_conflict_health.json',
    'docs/planning/v1.2/sprint_115_cloud_transfer_sync_controls.json',
    'docs/planning/v1.2/sprint_116_retry_backoff_circuit_breaker_certification.json',
    'docs/planning/v1.2/sprint_115_sync_conflict_center.json',
    'docs/planning/v1.2/sprint_115_backup_policies_destinations.json',
    'docs/planning/v1.2/sprint_114_backup_restore_health.json',
    'docs/planning/v1.2/sprint_115_workspace_boundary_contract.json',
    'docs/planning/v1.2/sprint_114_data_integrity_health.json',
  ];

  /// The distinct union of the committed sync/backup/integrity/boundary witness
  /// vocabularies, in witness order.
  static List<String> stateVocabulary(List<List<String>> vocabularies) {
    final seen = <String>{};
    final result = <String>[];
    for (final vocabulary in vocabularies) {
      for (final state in vocabulary) {
        if (seen.add(state)) result.add(state);
      }
    }
    return result;
  }

  /// The evidence source registered for a canonical signal.
  static String sourceFor(String signal) {
    final index = syncBackupSignals.indexOf(signal);
    if (index < 0) return '';
    return canonicalSources[index];
  }

  /// The canonical review, declared here as the single source of truth. The gate
  /// evaluates exactly this object, and the emitter writes exactly this object,
  /// so the record cannot be made to agree with itself. With the release
  /// delayed, every entry declares a reference and observes nothing. Each
  /// reference state is drawn from the committed 114.15 cloud sync & conflict
  /// health contract, the committed 114.14 backup & restore health contract, the
  /// committed 114.12 data integrity health contract, or the committed 115.4
  /// workspace boundary contract.
  static const Sprint118SyncBackupRecoveryHealthReview
  canonicalReview = Sprint118SyncBackupRecoveryHealthReview(
    releaseState: delayedReleaseState,
    entries: <Sprint118SyncBackupRecoveryHealthEntry>[
      Sprint118SyncBackupRecoveryHealthEntry(
        signal: 'queue_age',
        referenceState: 'queue_age',
        source: 'docs/planning/v1.2/sprint_114_cloud_sync_conflict_health.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118SyncBackupRecoveryHealthEntry(
        signal: 'transfer_failure',
        referenceState: 'transfer_failure',
        source:
            'docs/planning/v1.2/sprint_115_cloud_transfer_sync_controls.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118SyncBackupRecoveryHealthEntry(
        signal: 'retry_success',
        referenceState: 'retry_success',
        source:
            'docs/planning/v1.2/sprint_116_retry_backoff_circuit_breaker_certification.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118SyncBackupRecoveryHealthEntry(
        signal: 'conflict_rate',
        referenceState: 'conflict_rate',
        source: 'docs/planning/v1.2/sprint_115_sync_conflict_center.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118SyncBackupRecoveryHealthEntry(
        signal: 'backup_success',
        referenceState: 'backup_success',
        source:
            'docs/planning/v1.2/sprint_115_backup_policies_destinations.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118SyncBackupRecoveryHealthEntry(
        signal: 'restore_success',
        referenceState: 'restore_success',
        source: 'docs/planning/v1.2/sprint_114_backup_restore_health.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118SyncBackupRecoveryHealthEntry(
        signal: 'boundary_issue',
        referenceState: 'separate_backup_boundaries',
        source:
            'docs/planning/v1.2/sprint_115_workspace_boundary_contract.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
      Sprint118SyncBackupRecoveryHealthEntry(
        signal: 'integrity_issue',
        referenceState: 'checksum_failure',
        source: 'docs/planning/v1.2/sprint_114_data_integrity_health.json',
        window: 1440,
        limitations: <String>['live_observation_deferred'],
      ),
    ],
  );
}

/// Reads the committed 118.4 baseline, 118.2 charter, and sync/backup
/// witnesses. Never invents: an unreadable witness yields `null`, which the gate
/// reports as blocked rather than as a pass.
class Sprint118SyncBackupRecoveryHealthLoader {
  const Sprint118SyncBackupRecoveryHealthLoader();

  Sprint118SyncBackupRecoveryHealthAnchor? loadAnchor() {
    final baseline = _readJsonObject(
      Sprint118SyncBackupRecoveryHealthContract.baselineManifestPath,
    );
    if (baseline == null) return null;
    final charter = _readJsonObject(
      Sprint118SyncBackupRecoveryHealthContract.charterManifestPath,
    );
    if (charter == null) return null;
    final sync = _readJsonObject(
      Sprint118SyncBackupRecoveryHealthContract.syncHealthManifestPath,
    );
    if (sync == null) return null;
    final backup = _readJsonObject(
      Sprint118SyncBackupRecoveryHealthContract.backupHealthManifestPath,
    );
    if (backup == null) return null;
    final integrity = _readJsonObject(
      Sprint118SyncBackupRecoveryHealthContract.integrityHealthManifestPath,
    );
    if (integrity == null) return null;
    final boundary = _readJsonObject(
      Sprint118SyncBackupRecoveryHealthContract.workspaceBoundaryManifestPath,
    );
    if (boundary == null) return null;

    final window = charter['window'];
    final windowMap = window is Map<String, dynamic>
        ? window
        : const <String, dynamic>{};
    final durationDays = _int(windowMap['duration_days']);
    final charterWindowMinutes = durationDays > 0
        ? durationDays * 24 * 60
        : Sprint118SyncBackupRecoveryHealthContract.charterWindowMinutes;

    final readable = <String>[
      for (final source
          in Sprint118SyncBackupRecoveryHealthContract.canonicalSources)
        if (File(source).existsSync()) source,
    ];

    return Sprint118SyncBackupRecoveryHealthAnchor(
      baselineState: _text(baseline['state']),
      baselineVerdict: _text(baseline['verdict']),
      releaseState: _text(baseline['release_state']),
      charterState: _text(charter['state']),
      charterVerdict: _text(charter['verdict']),
      charterWindowMinutes: charterWindowMinutes,
      witnessSyncEvidence: _stringList(sync['required_evidence']),
      witnessBackupEvidence: _stringList(backup['required_evidence']),
      witnessIntegrityEvidence: _stringList(integrity['required_evidence']),
      witnessBoundaryAcceptance: _mapKeys(boundary['acceptance']),
      readableSources: readable,
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is List) {
      return <String>[
        for (final item in value)
          if (item is String) item,
      ];
    }
    return const <String>[];
  }

  static List<String> _mapKeys(Object? value) {
    if (value is Map) {
      return <String>[
        for (final key in value.keys)
          if (key is String) key,
      ];
    }
    return const <String>[];
  }

  static Map<String, dynamic>? _readJsonObject(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;
    try {
      final decoded = jsonDecode(file.readAsStringSync());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  static String _text(Object? value) {
    if (value == null) return '';
    if (value is String) return value.trim();
    return value.toString().trim();
  }

  static int _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }
}

class Sprint118SyncBackupRecoveryHealthGate {
  const Sprint118SyncBackupRecoveryHealthGate();

  /// Evaluate the canonical review against committed evidence. This is the entry
  /// point that makes the answer trustworthy: the verdict is bound to the
  /// witnesses on disk.
  Sprint118SyncBackupRecoveryHealthReport evaluate() => evaluateWith(
    const Sprint118SyncBackupRecoveryHealthLoader().loadAnchor(),
    Sprint118SyncBackupRecoveryHealthContract.canonicalReview,
  );

  Sprint118SyncBackupRecoveryHealthReport evaluateWith(
    Sprint118SyncBackupRecoveryHealthAnchor? anchor,
    Sprint118SyncBackupRecoveryHealthReview review,
  ) {
    if (anchor == null) {
      return Sprint118SyncBackupRecoveryHealthReport(
        state: Sprint118SyncBackupRecoveryHealthState.blocked,
        verdict: 'SPRINT_118_SYNC_BACKUP_RECOVERY_HEALTH_EVIDENCE_UNREADABLE',
        releaseState: review.releaseState,
        missingFields: List<String>.from(
          Sprint118SyncBackupRecoveryHealthContract.requiredFields,
        ),
        blockers: const <String>[
          'committed_sync_backup_recovery_evidence_unreadable',
        ],
        openItems: const <String>[
          'committed_sync_backup_recovery_evidence_unreadable',
        ],
      );
    }

    final violations = <String>[];
    final blockers = <String>[];
    final openItems = <String>[];

    // (1) The 118.4 baseline anchor must be a genuine frozen pass. A review
    // written against an unfrozen baseline describes sync/backup readings nobody
    // measured.
    if (anchor.baselineState !=
            Sprint118SyncBackupRecoveryHealthContract.requiredBaselineState ||
        anchor.baselineVerdict !=
            Sprint118SyncBackupRecoveryHealthContract.requiredBaselineVerdict) {
      blockers.add('baseline_not_frozen:${anchor.baselineVerdict}');
    }

    // (2) The 118.2 charter anchor must be complete. A review bound to an
    // incomplete charter has no declared window to respect.
    if (anchor.charterState !=
            Sprint118SyncBackupRecoveryHealthContract.requiredCharterState ||
        anchor.charterVerdict !=
            Sprint118SyncBackupRecoveryHealthContract.requiredCharterVerdict) {
      blockers.add('charter_not_complete:${anchor.charterVerdict}');
    }

    // (3) The release state must agree with the baseline anchor.
    if (anchor.releaseState != review.releaseState) {
      violations.add(
        'release_state_mismatch:anchor=${anchor.releaseState}:'
        'review=${review.releaseState}',
      );
    }

    // (4) On the delayed path no signal may claim an observation: with no
    // release, an observation describes a sync queue, transfer, or restore never
    // run.
    final delayed =
        review.releaseState ==
        Sprint118SyncBackupRecoveryHealthContract.delayedReleaseState;
    if (delayed) {
      for (final entry in review.entries) {
        if (entry.observed) {
          violations.add(
            'sync_claims_observation_without_release:${entry.signal}',
          );
        }
      }
    }

    // (5) The committed witness vocabulary must be present, so the review has
    // something to draw its reference states from.
    final witnessIncomplete =
        anchor.witnessSyncEvidence.isEmpty ||
        anchor.witnessBackupEvidence.isEmpty ||
        anchor.witnessIntegrityEvidence.isEmpty ||
        anchor.witnessBoundaryAcceptance.isEmpty;
    if (witnessIncomplete) {
      blockers.add('upstream_sync_vocabulary_missing');
    }
    final vocabulary =
        Sprint118SyncBackupRecoveryHealthContract.stateVocabulary(
          <List<String>>[
            anchor.witnessSyncEvidence,
            anchor.witnessBackupEvidence,
            anchor.witnessIntegrityEvidence,
            anchor.witnessBoundaryAcceptance,
          ],
        );

    // (6) Every canonical signal must be present exactly once, and each entry
    // must carry its declared fields.
    final declared = <String, int>{};
    for (final entry in review.entries) {
      declared[entry.signal] = (declared[entry.signal] ?? 0) + 1;
    }
    for (final entry in review.entries) {
      final signal = entry.signal;
      if (!Sprint118SyncBackupRecoveryHealthContract.syncBackupSignals.contains(
        signal,
      )) {
        violations.add('signal_unknown:$signal');
      }
      if (entry.referenceState.trim().isEmpty) {
        violations.add('entry_blank_reference_state:$signal');
      }
      if (entry.source.trim().isEmpty) {
        violations.add('entry_blank_source:$signal');
      }
      if (entry.limitations.isEmpty) {
        violations.add('entry_no_limitations:$signal');
      }
      if (entry.window <= 0) {
        violations.add('entry_nonpositive_window:$signal:${entry.window}');
      } else if (entry.window > anchor.charterWindowMinutes) {
        violations.add(
          'entry_window_exceeds_charter:$signal:${entry.window}:'
          '${anchor.charterWindowMinutes}',
        );
      }
      // A reference state is judged against the witness vocabulary unless the
      // witness is silent, in which case the review is blocked upstream rather
      // than failed.
      if (entry.referenceState.trim().isNotEmpty && !witnessIncomplete) {
        if (!vocabulary.contains(entry.referenceState)) {
          violations.add(
            'entry_unknown_reference_state:$signal:${entry.referenceState}',
          );
        }
      }
      if (entry.source.trim().isNotEmpty &&
          !anchor.readableSources.contains(entry.source)) {
        violations.add('entry_unreadable_source:$signal:${entry.source}');
      }
    }
    for (final signal in declared.keys) {
      if (declared[signal]! > 1) {
        violations.add('signal_duplicate:$signal');
      }
    }
    for (final signal
        in Sprint118SyncBackupRecoveryHealthContract.syncBackupSignals) {
      if (!declared.containsKey(signal)) {
        violations.add('signal_missing:$signal');
      }
    }

    // (7) Every committed review-evidence source must be readable.
    for (final source
        in Sprint118SyncBackupRecoveryHealthContract.canonicalSources) {
      if (!anchor.readableSources.contains(source)) {
        violations.add('unreadable_source:$source');
      }
    }

    final allOpen = <String>[...violations, ...blockers, ...openItems];
    final signals = review.signals;

    if (violations.isNotEmpty) {
      return Sprint118SyncBackupRecoveryHealthReport(
        state: Sprint118SyncBackupRecoveryHealthState.fail,
        verdict: 'SPRINT_118_SYNC_BACKUP_RECOVERY_HEALTH_EVIDENCE_VIOLATION',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredSignals: signals,
        observedCount: review.observedCount,
      );
    }
    if (blockers.isNotEmpty) {
      return Sprint118SyncBackupRecoveryHealthReport(
        state: Sprint118SyncBackupRecoveryHealthState.blocked,
        verdict: 'SPRINT_118_SYNC_BACKUP_RECOVERY_HEALTH_BLOCKED_UPSTREAM',
        releaseState: review.releaseState,
        violations: violations,
        blockers: blockers,
        openItems: allOpen,
        declaredSignals: signals,
        observedCount: review.observedCount,
      );
    }
    return Sprint118SyncBackupRecoveryHealthReport(
      state: Sprint118SyncBackupRecoveryHealthState.pass,
      verdict: 'SYNC_BACKUP_RECOVERY_HEALTH_VERIFIED_LOCAL',
      releaseState: review.releaseState,
      openItems: allOpen,
      declaredSignals: signals,
      observedCount: review.observedCount,
    );
  }
}
