/// Final Feature Evidence Reconciliation (Step 113.35).
///
/// Domain contract that reconciles every one of the 29 unique release
/// features (F1-F29; F30 is an alias of F24 and never a separate entry)
/// against the eight canonical required fields — feature, status, evidence,
/// flag, documentation, owner, known_issues, release_decision — and yields
/// the blocked/fail/pass state of the reconciliation.
///
/// The domain stays dependency-free. It does not decide the release: the
/// per-feature `release_decision` is an evidence-based recommendation whose
/// derivation rule is recorded in the manifest, and the final go/no-go stays
/// with the charter decision owner (Choirudin). A feature is only reconciled
/// when its identifier, status, evidence references, flag, documentation,
/// owner, known-issue answer, and release recommendation are all present and
/// the F1-F29 coverage is complete without duplicates or alias entries.
library;

/// Canonical required-field names of step 113.35, in ledger order.
const List<String> _requiredFieldNames = <String>[
  'feature',
  'status',
  'evidence',
  'flag',
  'documentation',
  'owner',
  'known_issues',
  'release_decision',
];

/// Canonical release-decision wire names, in ledger order.
const List<String> _releaseDecisionWireNames = <String>[
  'RECOMMEND_INCLUDE',
  'RECOMMEND_DEFER',
  'BLOCKS_RELEASE',
];

/// One reconciled feature record.
class FeatureEvidenceEntry {
  const FeatureEvidenceEntry({
    required this.feature,
    required this.status,
    required this.evidence,
    required this.flag,
    required this.documentation,
    required this.owner,
    required this.knownIssues,
    required this.releaseDecision,
  });

  /// Canonical eight-field list, exposed for contract tests.
  static const List<String> requiredFieldNames = _requiredFieldNames;

  /// Canonical decision wire names, exposed for contract tests.
  static const List<String> releaseDecisionWireNames =
      _releaseDecisionWireNames;

  /// Feature identifier (`feature`), canonical form `F1`-`F29`.
  final String feature;

  /// Reconciled status (`status`), e.g. `EVIDENCED_LOCAL` or `PARTIAL`.
  final String status;

  /// Implementation and test references backing the status (`evidence`).
  /// Must not be empty.
  final List<String> evidence;

  /// Feature flag identifier guarding the feature (`flag`). Must not be
  /// blank: a feature without a recorded flag has no rollout control.
  final String flag;

  /// Documentation references (`documentation`). Must not be empty.
  final List<String> documentation;

  /// Owning workstream (`owner`). Must not be blank.
  final String owner;

  /// Known-issue answer (`known_issues`). `null` means the source record
  /// never carried the field — that is a missing required field. An empty
  /// list is a recorded answer meaning the feature has no known issue.
  final List<String>? knownIssues;

  /// Release recommendation wire name (`release_decision`). Must be one of
  /// [releaseDecisionWireNames].
  final String releaseDecision;
}

/// Aggregate state of the reconciliation log.
enum FeatureReconciliationState {
  /// All 29 features carry every required field with valid decisions.
  pass,

  /// At least one feature is incomplete, duplicated, unknown, blocking, or
  /// the F1-F29 coverage is incomplete/contaminated by an alias id.
  fail,

  /// No feature has been reconciled yet.
  blocked,
}

/// Result of `FeatureReconciliationLog.evaluate`.
class FeatureReconciliationEvaluation {
  const FeatureReconciliationEvaluation({
    required this.state,
    required this.featureCount,
    required this.notes,
  });

  final FeatureReconciliationState state;

  /// Number of entries carried by the log at evaluation time.
  final int featureCount;

  /// Per-feature notes: the missing field names on failure, the retained
  /// decision and status on success, plus coverage/duplicate/blocking notes;
  /// a log-level note when blocked.
  final List<String> notes;
}

/// Append-only log of reconciled feature records.
class FeatureReconciliationLog {
  final List<FeatureEvidenceEntry> _entries = <FeatureEvidenceEntry>[];

  /// Recorded entries in insertion order.
  List<FeatureEvidenceEntry> get entries =>
      List<FeatureEvidenceEntry>.unmodifiable(_entries);

  /// Canonical coverage contract: exactly `F1`..`F29`.
  static final List<String> expectedFeatureIds = List<String>.generate(
    29,
    (index) => 'F${index + 1}',
  );

  /// Records one feature. Validation happens in [evaluate].
  void add(FeatureEvidenceEntry entry) {
    _entries.add(entry);
  }

  /// Records several features in order.
  void addAll(Iterable<FeatureEvidenceEntry> featureEntries) {
    _entries.addAll(featureEntries);
  }

  /// Canonical names of the required fields missing from [entry]. The field
  /// order follows [FeatureEvidenceEntry.requiredFieldNames]. An empty
  /// `knownIssues` list is a recorded answer and is never reported.
  List<String> missingFields(FeatureEvidenceEntry entry) {
    final missing = <String>[];
    if (entry.feature.trim().isEmpty) missing.add('feature');
    if (entry.status.trim().isEmpty) missing.add('status');
    if (entry.evidence.every((ref) => ref.trim().isEmpty) ||
        entry.evidence.isEmpty) {
      missing.add('evidence');
    }
    if (entry.flag.trim().isEmpty) missing.add('flag');
    if (entry.documentation.every((ref) => ref.trim().isEmpty) ||
        entry.documentation.isEmpty) {
      missing.add('documentation');
    }
    if (entry.owner.trim().isEmpty) missing.add('owner');
    if (entry.knownIssues == null) missing.add('known_issues');
    if (entry.releaseDecision.trim().isEmpty) missing.add('release_decision');
    return missing;
  }

  /// True when [entry] records a decision outside the canonical wire names.
  bool hasUnknownDecision(FeatureEvidenceEntry entry) {
    final decision = entry.releaseDecision.trim();
    if (decision.isEmpty) return false;
    return !FeatureEvidenceEntry.releaseDecisionWireNames.contains(decision);
  }

  /// Evaluates the whole log:
  /// * empty log -> `blocked` (no reconciliation attempted yet);
  /// * any incomplete/unknown/duplicate entry, coverage gap, alias id, or
  ///   `BLOCKS_RELEASE` decision -> `fail`;
  /// * otherwise -> `pass`, retaining every feature decision.
  FeatureReconciliationEvaluation evaluate() {
    if (_entries.isEmpty) {
      return const FeatureReconciliationEvaluation(
        state: FeatureReconciliationState.blocked,
        featureCount: 0,
        notes: <String>[
          'Belum ada fitur yang direkonsiliasi, sehingga klaim evidence '
              '29 fitur unik diblokir sampai satu rekonsiliasi penuh '
              'tercatat.',
        ],
      );
    }

    final notes = <String>[];
    var complete = true;
    final seen = <String>{};

    for (final entry in _entries) {
      final id = entry.feature.trim();
      final missing = missingFields(entry);
      if (missing.isNotEmpty) {
        complete = false;
        final label = id.isEmpty ? 'entry' : id;
        notes.add('$label incomplete: missing ${missing.join(', ')}');
        continue;
      }
      if (hasUnknownDecision(entry)) {
        complete = false;
        notes.add(
          '$id invalid release_decision: ${entry.releaseDecision.trim()}',
        );
        continue;
      }
      if (!seen.add(id)) {
        complete = false;
        notes.add('duplicate feature: $id');
        continue;
      }
      final decision = entry.releaseDecision.trim();
      if (decision == 'BLOCKS_RELEASE') {
        complete = false;
        notes.add(
          '$id blocks release: release_decision BLOCKS_RELEASE, '
          'status ${entry.status.trim()}',
        );
        continue;
      }
      notes.add('$id $decision (${entry.status.trim()})');
    }

    final missingCoverage = expectedFeatureIds
        .where((id) => !seen.contains(id))
        .toList(growable: false);
    if (missingCoverage.isNotEmpty) {
      complete = false;
      notes.add('coverage incomplete: missing ${missingCoverage.join(', ')}');
    }
    final unexpected = seen
        .where((id) => !expectedFeatureIds.contains(id))
        .toList(growable: false);
    if (unexpected.isNotEmpty) {
      complete = false;
      notes.add(
        'unexpected feature id: ${unexpected.join(', ')} '
        '(F30 is an alias of F24, not a separate feature)',
      );
    }

    return FeatureReconciliationEvaluation(
      state: complete
          ? FeatureReconciliationState.pass
          : FeatureReconciliationState.fail,
      featureCount: _entries.length,
      notes: notes,
    );
  }
}
