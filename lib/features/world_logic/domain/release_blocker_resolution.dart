/// Release Blocker Resolution (Step 113.31).
///
/// Domain contract for closing a release blocker with the six canonical
/// required_outputs — fix_refs, root_cause, tests, review, risk_update,
/// release_note — and the blocked/fail/pass state of the resolution log.
///
/// The domain stays dependency-free. The test drives the log through
/// complete, incomplete, and empty states and cross-checks the manifest.
/// A resolution is only accepted when every output is present: the fix is
/// referenced by commit, the root cause is stated, regression tests are
/// named, the review is recorded, the release risk is updated, and the
/// release note exists.
library;

/// Canonical required output names of step 113.31, in ledger order.
const List<String> _requiredOutputNames = <String>[
  'fix_refs',
  'root_cause',
  'tests',
  'review',
  'risk_update',
  'release_note',
];

/// One blocker resolution attempt.
class BlockerResolution {
  const BlockerResolution({
    required this.issueId,
    required this.fixRefs,
    required this.rootCause,
    required this.tests,
    required this.review,
    required this.riskUpdate,
    required this.releaseNote,
  });

  /// Canonical six-output list, exposed for contract tests.
  static const List<String> requiredOutputNames = _requiredOutputNames;

  /// Identifier of the resolved blocker (`issue_id`).
  final String issueId;

  /// References to the fix (commit SHAs / PR links) (`fix_refs`). Must not
  /// be empty.
  final List<String> fixRefs;

  /// Determined root cause of the blocker (`root_cause`).
  final String rootCause;

  /// Regression tests added or rerun for the fix (`tests`). Must not be
  /// empty.
  final List<String> tests;

  /// Who/what reviewed the change (`review`).
  final String review;

  /// Updated release-risk statement (`risk_update`).
  final String riskUpdate;

  /// User-facing release note for the fix (`release_note`).
  final String releaseNote;
}

/// Aggregate state of the resolution log.
enum BlockerResolutionState {
  /// Every resolution carries all six outputs.
  pass,

  /// At least one resolution is missing required outputs.
  fail,

  /// No resolution has been attempted yet.
  blocked,
}

/// Result of `BlockerResolutionLog.evaluate`.
class BlockerResolutionEvaluation {
  const BlockerResolutionEvaluation({
    required this.state,
    required this.resolutionCount,
    required this.notes,
  });

  final BlockerResolutionState state;
  final int resolutionCount;

  /// Per-resolution notes: the missing output names on failure, or the
  /// retained release note on success; log-level note when blocked.
  final List<String> notes;
}

/// Append-only log of blocker resolutions.
class BlockerResolutionLog {
  final List<BlockerResolution> _resolutions = <BlockerResolution>[];

  /// Recorded resolutions in insertion order.
  List<BlockerResolution> get resolutions =>
      List<BlockerResolution>.unmodifiable(_resolutions);

  /// Records one resolution. Validation happens in [evaluate].
  void add(BlockerResolution resolution) {
    _resolutions.add(resolution);
  }

  /// Canonical names of the required outputs that are blank or empty in
  /// [resolution], plus `issue_id` when the identifier is blank.
  List<String> missingOutputs(BlockerResolution resolution) {
    final missing = <String>[];
    if (resolution.issueId.trim().isEmpty) missing.add('issue_id');
    if (resolution.fixRefs.isEmpty) missing.add('fix_refs');
    if (resolution.rootCause.trim().isEmpty) missing.add('root_cause');
    if (resolution.tests.isEmpty) missing.add('tests');
    if (resolution.review.trim().isEmpty) missing.add('review');
    if (resolution.riskUpdate.trim().isEmpty) missing.add('risk_update');
    if (resolution.releaseNote.trim().isEmpty) missing.add('release_note');
    return missing;
  }

  /// Evaluates the whole log:
  /// * empty log -> `blocked` (no resolution attempted yet);
  /// * any incomplete resolution -> `fail`;
  /// * otherwise -> `pass`, retaining every release note.
  BlockerResolutionEvaluation evaluate() {
    if (_resolutions.isEmpty) {
      return const BlockerResolutionEvaluation(
        state: BlockerResolutionState.blocked,
        resolutionCount: 0,
        notes: <String>[
          'Belum ada percobaan resolusi blocker, sehingga klaim perbaikan '
              'diblokir sampai satu resolusi lengkap tercatat.',
        ],
      );
    }

    final notes = <String>[];
    var complete = true;
    for (final resolution in _resolutions) {
      final missing = missingOutputs(resolution);
      if (missing.isNotEmpty) {
        complete = false;
        notes.add(
          'resolution ${resolution.issueId} incomplete: missing '
          '${missing.join(', ')}',
        );
      } else {
        notes.add(
          '${resolution.issueId} resolved: '
          '${resolution.releaseNote.trim()}',
        );
      }
    }

    return BlockerResolutionEvaluation(
      state: complete
          ? BlockerResolutionState.pass
          : BlockerResolutionState.fail,
      resolutionCount: _resolutions.length,
      notes: notes,
    );
  }
}
