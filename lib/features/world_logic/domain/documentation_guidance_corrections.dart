/// Documentation & Guidance Corrections (Step 113.33).
///
/// Domain contract for recording validation-driven corrections to guides,
/// UI copy, error messages, recovery steps, known limits, and
/// accessibility notes, covering the six canonical outputs —
/// corrected_guides, ui_copy, error_guidance, recovery_steps,
/// known_limits, accessibility_notes — and the blocked/fail/pass state
/// of the corrections log.
///
/// The domain stays dependency-free. The test drives the log through
/// complete, incomplete, mixed, and empty states and cross-checks the
/// manifest. A correction is only accepted when every output is present.
library;

/// Canonical output names of step 113.33, in ledger order.
const List<String> _requiredOutputNames = <String>[
  'corrected_guides',
  'ui_copy',
  'error_guidance',
  'recovery_steps',
  'known_limits',
  'accessibility_notes',
];

/// One documentation/guidance correction driven by validation findings.
class DocumentationCorrection {
  const DocumentationCorrection({
    required this.issueId,
    required this.correctedGuides,
    required this.uiCopy,
    required this.errorGuidance,
    required this.recoverySteps,
    required this.knownLimits,
    required this.accessibilityNotes,
  });

  /// Canonical six-output list, exposed for contract tests.
  static const List<String> requiredOutputNames = _requiredOutputNames;

  /// Identifier of the corrected issue (`issue_id`). Must not be blank.
  final String issueId;

  /// Guide documents corrected (`corrected_guides`). Must not be empty.
  final List<String> correctedGuides;

  /// Corrected user-facing copy (`ui_copy`). Must not be empty.
  final List<String> uiCopy;

  /// Corrected error/recovery message shown to the user
  /// (`error_guidance`).
  final String errorGuidance;

  /// Corrected recovery steps (`recovery_steps`). Must not be empty.
  final List<String> recoverySteps;

  /// Corrected known-limits documentation (`known_limits`). Must not be
  /// empty.
  final List<String> knownLimits;

  /// Corrected accessibility notes (`accessibility_notes`).
  final String accessibilityNotes;
}

/// Aggregate state of the corrections log.
enum DocumentationCorrectionState {
  /// Every correction carries all six outputs.
  pass,

  /// At least one correction is missing required outputs.
  fail,

  /// No correction has been attempted yet.
  blocked,
}

/// Result of `DocumentationCorrectionLog.evaluate`.
class DocumentationCorrectionEvaluation {
  const DocumentationCorrectionEvaluation({
    required this.state,
    required this.correctionCount,
    required this.notes,
  });

  final DocumentationCorrectionState state;
  final int correctionCount;

  /// Per-correction notes: the missing output names on failure, or the
  /// retained error guidance on success; log-level note when blocked.
  final List<String> notes;
}

/// Append-only log of documentation/guidance corrections.
class DocumentationCorrectionLog {
  final List<DocumentationCorrection> _corrections =
      <DocumentationCorrection>[];

  /// Recorded corrections in insertion order.
  List<DocumentationCorrection> get corrections =>
      List<DocumentationCorrection>.unmodifiable(_corrections);

  /// Records one correction. Validation happens in [evaluate].
  void add(DocumentationCorrection correction) {
    _corrections.add(correction);
  }

  /// Canonical names of the required outputs that are blank or empty in
  /// [correction], plus `issue_id` when the identifier is blank.
  List<String> missingOutputs(DocumentationCorrection correction) {
    final missing = <String>[];
    if (correction.issueId.trim().isEmpty) missing.add('issue_id');
    if (correction.correctedGuides.isEmpty) missing.add('corrected_guides');
    if (correction.uiCopy.isEmpty) missing.add('ui_copy');
    if (correction.errorGuidance.trim().isEmpty) {
      missing.add('error_guidance');
    }
    if (correction.recoverySteps.isEmpty) missing.add('recovery_steps');
    if (correction.knownLimits.isEmpty) missing.add('known_limits');
    if (correction.accessibilityNotes.trim().isEmpty) {
      missing.add('accessibility_notes');
    }
    return missing;
  }

  /// Evaluates the whole log:
  /// * empty log -> `blocked` (no correction attempted yet);
  /// * any incomplete correction -> `fail`;
  /// * otherwise -> `pass`, retaining every error guidance string.
  DocumentationCorrectionEvaluation evaluate() {
    if (_corrections.isEmpty) {
      return const DocumentationCorrectionEvaluation(
        state: DocumentationCorrectionState.blocked,
        correctionCount: 0,
        notes: <String>[
          'Belum ada percobaan koreksi dokumentasi/panduan, sehingga klaim '
              'perbaikan teks diblokir sampai satu koreksi lengkap '
              'tercatat.',
        ],
      );
    }

    final notes = <String>[];
    var complete = true;
    for (final correction in _corrections) {
      final missing = missingOutputs(correction);
      if (missing.isNotEmpty) {
        complete = false;
        notes.add(
          'correction ${correction.issueId} incomplete: missing '
          '${missing.join(', ')}',
        );
      } else {
        notes.add(
          '${correction.issueId} corrected: '
          '${correction.errorGuidance.trim()}',
        );
      }
    }

    return DocumentationCorrectionEvaluation(
      state: complete
          ? DocumentationCorrectionState.pass
          : DocumentationCorrectionState.fail,
      correctionCount: _corrections.length,
      notes: notes,
    );
  }
}
