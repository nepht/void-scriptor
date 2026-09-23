/// Final Scope & Known Issues (Step 113.36).
///
/// Domain contract for documenting what the release candidate contains, what
/// is deferred, the known issues, the workarounds, the residual risks, and
/// the support notes — the six canonical outputs release_scope,
/// deferred_scope, known_issues, workarounds, residual_risks, support_notes
/// — plus the blocked/fail/pass state of that document.
///
/// The domain stays dependency-free. Every output is a nullable recorded
/// list: `null` means the section was never documented and is reported as
/// missing; an empty list is a recorded answer (there genuinely is nothing
/// to defer or no residual risk) except for `release_scope` and
/// `support_notes`, which cannot document a release while empty. A blank
/// item is treated as missing so whitespace cannot pass as documentation.
library;

/// Canonical output names of step 113.36, in ledger order.
const List<String> _requiredOutputNames = <String>[
  'release_scope',
  'deferred_scope',
  'known_issues',
  'workarounds',
  'residual_risks',
  'support_notes',
];

/// Outputs that cannot be empty when recorded: a release with no scope, or
/// with no support notes, is not documented.
const List<String> _outputsNeedingItems = <String>[
  'release_scope',
  'support_notes',
];

/// The documented final scope of the release candidate.
class FinalScopeDocument {
  const FinalScopeDocument({
    this.releaseScope,
    this.deferredScope,
    this.knownIssues,
    this.workarounds,
    this.residualRisks,
    this.supportNotes,
  });

  /// Canonical six-output list, exposed for contract tests.
  static const List<String> requiredOutputNames = _requiredOutputNames;

  /// Outputs whose recorded list must contain at least one item.
  static const List<String> outputsNeedingItems = _outputsNeedingItems;

  /// What ships in this release (`release_scope`). Must be recorded and
  /// non-empty.
  final List<String>? releaseScope;

  /// What is intentionally out of this release (`deferred_scope`). Empty
  /// list is a recorded answer meaning nothing is deferred.
  final List<String>? deferredScope;

  /// Open defects and documentation mismatches (`known_issues`). Empty list
  /// is a recorded answer meaning no known issue.
  final List<String>? knownIssues;

  /// Safe fallbacks for the known issues (`workarounds`).
  final List<String>? workarounds;

  /// Risks that remain after mitigation (`residual_risks`).
  final List<String>? residualRisks;

  /// Triage and escalation guidance (`support_notes`). Must be recorded and
  /// non-empty.
  final List<String>? supportNotes;

  /// Canonical names of the outputs missing from [document]: never
  /// recorded, blank-itemed, or (for [outputsNeedingItems]) empty. The
  /// output order follows [requiredOutputNames].
  static List<String> missingOutputs(FinalScopeDocument? document) {
    if (document == null) return _requiredOutputNames;
    final missing = <String>[];
    if (!_recorded(document.releaseScope, 'release_scope')) {
      missing.add('release_scope');
    }
    if (!_recorded(document.deferredScope, 'deferred_scope')) {
      missing.add('deferred_scope');
    }
    if (!_recorded(document.knownIssues, 'known_issues')) {
      missing.add('known_issues');
    }
    if (!_recorded(document.workarounds, 'workarounds')) {
      missing.add('workarounds');
    }
    if (!_recorded(document.residualRisks, 'residual_risks')) {
      missing.add('residual_risks');
    }
    if (!_recorded(document.supportNotes, 'support_notes')) {
      missing.add('support_notes');
    }
    return missing;
  }

  static bool _recorded(List<String>? items, String name) {
    if (items == null) return false;
    if (items.any((item) => item.trim().isEmpty)) return false;
    if (items.isEmpty && _outputsNeedingItems.contains(name)) return false;
    return true;
  }

  /// True while no section has been documented at all.
  static bool _isBlankDocument(FinalScopeDocument document) {
    return document.releaseScope == null &&
        document.deferredScope == null &&
        document.knownIssues == null &&
        document.workarounds == null &&
        document.residualRisks == null &&
        document.supportNotes == null;
  }

  /// Evaluates the document:
  /// * no document or no recorded section -> `blocked`;
  /// * any output missing/blank/empty-where-required -> `fail`;
  /// * otherwise -> `pass`, retaining the per-output counts and every
  ///   support note.
  static FinalScopeEvaluation evaluate(FinalScopeDocument? document) {
    if (document == null || _isBlankDocument(document)) {
      return const FinalScopeEvaluation(
        state: FinalScopeState.blocked,
        notes: <String>[
          'Belum ada isi rilis yang terdokumentasi, sehingga klaim final '
              'scope and known issues diblokir sampai satu dokumen scope '
              'lengkap tercatat.',
        ],
      );
    }

    final missing = missingOutputs(document);
    if (missing.isNotEmpty) {
      return FinalScopeEvaluation(
        state: FinalScopeState.fail,
        notes: <String>['scope incomplete: missing ${missing.join(', ')}'],
      );
    }

    final notes = <String>[
      'release_scope: ${document.releaseScope!.length} item',
      'deferred_scope: ${document.deferredScope!.length} item',
      'known_issues: ${document.knownIssues!.length} item',
      'workarounds: ${document.workarounds!.length} item',
      'residual_risks: ${document.residualRisks!.length} item',
      'support_notes: ${document.supportNotes!.length} item',
      for (final note in document.supportNotes!) 'support_note: ${note.trim()}',
    ];
    return FinalScopeEvaluation(state: FinalScopeState.pass, notes: notes);
  }
}

/// Aggregate state of the final scope document.
enum FinalScopeState {
  /// All six outputs are recorded with real items.
  pass,

  /// At least one output is missing, blank, or empty where it cannot be.
  fail,

  /// Nothing has been documented yet.
  blocked,
}

/// Result of `FinalScopeDocument.evaluate`.
class FinalScopeEvaluation {
  const FinalScopeEvaluation({required this.state, required this.notes});

  final FinalScopeState state;

  /// Notes: the missing output names on failure, or the per-output counts
  /// plus every support note on success; a document-level note when blocked.
  final List<String> notes;
}
