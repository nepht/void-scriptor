/// Non-Blocker Stabilization (Step 113.32).
///
/// Domain contract for approving a low-risk defect fix without scope
/// expansion, covering the six canonical requirements — risk_assessed,
/// minimal_change, tests_added, reviewed, no_schema_break, documented —
/// and the blocked/fail/pass state of the stabilization log.
///
/// The domain stays dependency-free. The test drives the log through
/// complete, incomplete, schema-breaking, and empty states and
/// cross-checks the manifest. A stabilization change is only accepted
/// when the risk was assessed, the change stayed minimal, tests were
/// added, the change was reviewed, no schema broke, and the work was
/// documented.
library;

/// Canonical requirement names of step 113.32, in ledger order.
const List<String> _requiredRequirementNames = <String>[
  'risk_assessed',
  'minimal_change',
  'tests_added',
  'reviewed',
  'no_schema_break',
  'documented',
];

/// One approved low-risk stabilization change.
class StabilizationChange {
  const StabilizationChange({
    required this.issueId,
    required this.riskAssessment,
    required this.minimalChange,
    required this.tests,
    required this.review,
    required this.noSchemaBreak,
    required this.documentation,
  });

  /// Canonical six-requirement list, exposed for contract tests.
  static const List<String> requiredRequirementNames =
      _requiredRequirementNames;

  /// Identifier of the stabilized issue (`issue_id`). Must not be blank.
  final String issueId;

  /// Recorded risk assessment of the fix (`risk_assessed`).
  final String riskAssessment;

  /// Whether the fix stayed within the approved minimal scope
  /// (`minimal_change`).
  final bool minimalChange;

  /// Tests added for the fix (`tests_added`). Must not be empty.
  final List<String> tests;

  /// Who/what reviewed the change (`reviewed`).
  final String review;

  /// Whether the change preserves the existing schema (`no_schema_break`).
  final bool noSchemaBreak;

  /// Where the change was documented — guide, changelog, or release note
  /// (`documented`).
  final String documentation;
}

/// Aggregate state of the stabilization log.
enum StabilizationState {
  /// Every change carries all six requirements.
  pass,

  /// At least one change misses a requirement or breaks the schema.
  fail,

  /// No stabilization change has been attempted yet.
  blocked,
}

/// Result of `StabilizationLog.evaluate`.
class StabilizationEvaluation {
  const StabilizationEvaluation({
    required this.state,
    required this.changeCount,
    required this.notes,
  });

  final StabilizationState state;
  final int changeCount;

  /// Per-change notes: the missing requirement names on failure, or the
  /// retained documentation on success; log-level note when blocked.
  final List<String> notes;
}

/// Append-only log of stabilization changes.
class StabilizationLog {
  final List<StabilizationChange> _changes = <StabilizationChange>[];

  /// Recorded changes in insertion order.
  List<StabilizationChange> get changes =>
      List<StabilizationChange>.unmodifiable(_changes);

  /// Records one change. Validation happens in [evaluate].
  void add(StabilizationChange change) {
    _changes.add(change);
  }

  /// Canonical names of the requirements that are unmet in [change],
  /// plus `issue_id` when the identifier is blank. A violated
  /// `no_schema_break` counts as unmet.
  List<String> missingRequirements(StabilizationChange change) {
    final missing = <String>[];
    if (change.issueId.trim().isEmpty) missing.add('issue_id');
    if (change.riskAssessment.trim().isEmpty) missing.add('risk_assessed');
    if (!change.minimalChange) missing.add('minimal_change');
    if (change.tests.isEmpty) missing.add('tests_added');
    if (change.review.trim().isEmpty) missing.add('reviewed');
    if (!change.noSchemaBreak) missing.add('no_schema_break');
    if (change.documentation.trim().isEmpty) missing.add('documented');
    return missing;
  }

  /// Evaluates the whole log:
  /// * empty log -> `blocked` (no stabilization attempted yet);
  /// * any change with unmet requirements -> `fail`;
  /// * otherwise -> `pass`, retaining every documentation reference.
  StabilizationEvaluation evaluate() {
    if (_changes.isEmpty) {
      return const StabilizationEvaluation(
        state: StabilizationState.blocked,
        changeCount: 0,
        notes: <String>[
          'Belum ada percobaan stabilisasi non-blocker, sehingga klaim '
              'perbaikan risiko rendah diblokir sampai satu perubahan '
              'lengkap tercatat.',
        ],
      );
    }

    final notes = <String>[];
    var complete = true;
    for (final change in _changes) {
      final missing = missingRequirements(change);
      if (missing.isNotEmpty) {
        complete = false;
        notes.add(
          'change ${change.issueId} incomplete: missing '
          '${missing.join(', ')}',
        );
      } else {
        notes.add(
          '${change.issueId} stabilized: ${change.documentation.trim()}',
        );
      }
    }

    return StabilizationEvaluation(
      state: complete ? StabilizationState.pass : StabilizationState.fail,
      changeCount: _changes.length,
      notes: notes,
    );
  }
}
