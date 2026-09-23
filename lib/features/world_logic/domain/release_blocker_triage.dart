/// Release Blocker Triage (Step 113.30).
///
/// Domain contract for classifying issues against the release-blocker
/// definition and choosing one of the five canonical triage decisions:
/// FIX_BEFORE_GA, DEFER_NON_BLOCKER, STOP_SHIP, ROLLBACK_RC, and
/// NOT_REPRODUCIBLE_WITH_EVIDENCE — plus the consistency rules that keep a
/// decision honest and the stop-ship/rollback release gate.
///
/// The domain stays dependency-free. The test drives the triage through
/// empty, consistent, contradictory, and gated states and cross-checks the
/// manifest. Consistency rules:
/// * a blank rationale fails the entry;
/// * an issue that meets the blocker definition cannot be deferred as
///   DEFER_NON_BLOCKER;
/// * STOP_SHIP/ROLLBACK_RC require an issue that meets the blocker
///   definition;
/// * NOT_REPRODUCIBLE_WITH_EVIDENCE must carry evidence.
library;

/// One classified issue in the triage log.
class TriageEntry {
  const TriageEntry({
    required this.issueId,
    required this.meetsBlockerDefinition,
    required this.reproducible,
    required this.decision,
    required this.rationale,
    required this.evidence,
  });

  /// Stable identifier of the issue (`issue_id`).
  final String issueId;

  /// Whether the issue matches the canonical release-blocker definition.
  final bool meetsBlockerDefinition;

  /// Whether the issue reproduces on the verification machine.
  final bool reproducible;

  /// The chosen triage decision.
  final TriageDecision decision;

  /// Why this decision was chosen; blank fails the entry.
  final String rationale;

  /// Artifacts backing the decision (reproduction log, evidence meta, …).
  final List<String> evidence;
}

/// The five canonical triage decisions of step 113.30.
enum TriageDecision {
  /// Issue meets the blocker definition and must be fixed before GA.
  fixBeforeGa('FIX_BEFORE_GA'),

  /// Issue does not meet the blocker definition; fix may be deferred.
  deferNonBlocker('DEFER_NON_BLOCKER'),

  /// Release must stop until the blocker is resolved.
  stopShip('STOP_SHIP'),

  /// The release candidate must be rolled back.
  rollbackRc('ROLLBACK_RC'),

  /// Issue does not reproduce, backed by recorded evidence.
  notReproducibleWithEvidence('NOT_REPRODUCIBLE_WITH_EVIDENCE');

  const TriageDecision(this.wireName);

  /// Canonical wire name used in manifests and reports.
  final String wireName;
}

/// Aggregate state of the triage log.
enum TriageState {
  /// Every entry is consistent and evidence-backed.
  pass,

  /// At least one entry violates a consistency rule.
  fail,

  /// No issues have been triaged yet.
  blocked,
}

/// Result of `ReleaseBlockerTriage.evaluate`.
class TriageEvaluation {
  const TriageEvaluation({
    required this.state,
    required this.entryCount,
    required this.limitations,
  });

  final TriageState state;
  final int entryCount;

  /// Per-entry notes: consistency failures, or the retained rationale when
  /// the entry passes; log-level note when blocked.
  final List<String> limitations;
}

/// Append-only triage log for release issues.
class ReleaseBlockerTriage {
  final List<TriageEntry> _entries = <TriageEntry>[];

  /// Triaged entries in insertion order.
  List<TriageEntry> get entries => List<TriageEntry>.unmodifiable(_entries);

  /// Records one triage entry. Validation happens in [evaluate].
  void add(TriageEntry entry) {
    _entries.add(entry);
  }

  /// True when any entry decides STOP_SHIP or ROLLBACK_RC, gating the
  /// release regardless of triage consistency.
  bool get releaseBlocked => _entries.any(
    (e) =>
        e.decision == TriageDecision.stopShip ||
        e.decision == TriageDecision.rollbackRc,
  );

  /// Evaluates the whole log:
  /// * empty log -> `blocked` (nothing triaged yet);
  /// * any consistency violation -> `fail`;
  /// * otherwise -> `pass`, retaining every entry's rationale.
  TriageEvaluation evaluate() {
    if (_entries.isEmpty) {
      return const TriageEvaluation(
        state: TriageState.blocked,
        entryCount: 0,
        limitations: <String>[
          'Belum ada issue yang diklasifikasikan terhadap definisi release '
              'blocker, sehingga keputusan triage diblokir sampai issue masuk.',
        ],
      );
    }

    final limitations = <String>[];
    var consistent = true;
    for (final entry in _entries) {
      final problems = <String>[];
      if (entry.rationale.trim().isEmpty) {
        problems.add('missing rationale');
      }
      if (entry.meetsBlockerDefinition &&
          entry.decision == TriageDecision.deferNonBlocker) {
        problems.add('meets blocker definition cannot use DEFER_NON_BLOCKER');
      }
      if (!entry.meetsBlockerDefinition &&
          (entry.decision == TriageDecision.stopShip ||
              entry.decision == TriageDecision.rollbackRc)) {
        problems.add(
          '${entry.decision.wireName} requires an issue that '
          'meets the blocker definition',
        );
      }
      if (entry.decision == TriageDecision.notReproducibleWithEvidence &&
          entry.evidence.isEmpty) {
        problems.add('NOT_REPRODUCIBLE_WITH_EVIDENCE requires evidence');
      }

      if (problems.isEmpty) {
        limitations.add('${entry.issueId}: ${entry.rationale.trim()}');
      } else {
        consistent = false;
        limitations.add('${entry.issueId} ${problems.join('; ')}');
      }
    }

    return TriageEvaluation(
      state: consistent ? TriageState.pass : TriageState.fail,
      entryCount: _entries.length,
      limitations: limitations,
    );
  }
}
