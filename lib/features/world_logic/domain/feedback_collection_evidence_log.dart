/// Feedback Collection & Evidence Log (Step 113.28).
///
/// Domain contract for recording real feedback together with its context:
/// source, consent, workflow, observation, impact, supporting evidence, and
/// the limitations of the observation — the eight canonical required_fields
/// of the step.
///
/// The domain stays dependency-free. The test drives the log through
/// complete, incomplete, and empty states and cross-checks the manifest.
/// Real pilot feedback depends on the validation cohort (step 113.3), which
/// has not started; until entries exist, the honest decision is `blocked`
/// (see manifest limits).
library;

/// Canonical required field names of step 113.28, in ledger order.
const List<String> _requiredFieldNames = <String>[
  'feedback_id',
  'source',
  'consent',
  'workflow',
  'observation',
  'impact',
  'evidence',
  'limitations',
];

/// One feedback observation recorded in the evidence log.
class FeedbackEntry {
  const FeedbackEntry({
    required this.feedbackId,
    required this.source,
    required this.consent,
    required this.workflow,
    required this.observation,
    required this.impact,
    required this.evidence,
    required this.limitations,
  });

  /// Canonical eight-field list, exposed for contract tests.
  static const List<String> requiredFieldNames = _requiredFieldNames;

  /// Stable identifier of the feedback item (`feedback_id`).
  final String feedbackId;

  /// Where the feedback came from: participant session, internal dogfood,
  /// issue tracker, support thread (`source`).
  final String source;

  /// Recorded consent basis for collecting and retaining this feedback
  /// (`consent`). Blank means consent was not recorded.
  final String consent;

  /// The workflow being exercised when the feedback was produced
  /// (`workflow`).
  final String workflow;

  /// What was actually observed (`observation`).
  final String observation;

  /// Assessed impact of the observation (`impact`).
  final String impact;

  /// References to the artifacts backing the observation (`evidence`).
  final List<String> evidence;

  /// Known limitations of this observation (`limitations`).
  final List<String> limitations;
}

/// Outcome of evaluating the evidence log.
enum FeedbackDecision {
  /// Every recorded entry is complete.
  pass,

  /// At least one recorded entry is missing required fields.
  fail,

  /// No feedback has been recorded yet, so no real claim can be made.
  blocked,
}

/// Result of `FeedbackCollectionLog.evaluate`.
class FeedbackLogDecision {
  const FeedbackLogDecision({
    required this.decision,
    required this.entryCount,
    required this.limitations,
  });

  final FeedbackDecision decision;
  final int entryCount;

  /// Human-readable limitations carried by the decision (log-level for
  /// `blocked`, per-entry for `pass`/`fail`).
  final List<String> limitations;
}

/// Append-only evidence log for collected feedback.
class FeedbackCollectionLog {
  final List<FeedbackEntry> _entries = <FeedbackEntry>[];

  /// Recorded entries in insertion order.
  List<FeedbackEntry> get entries => List<FeedbackEntry>.unmodifiable(_entries);

  /// Records one feedback entry. Validation happens in [evaluate] so the
  /// log never silently drops observations.
  void add(FeedbackEntry entry) {
    _entries.add(entry);
  }

  /// Canonical names of the required fields that are blank or empty in
  /// [entry], in `_requiredFieldNames` order.
  List<String> missingFields(FeedbackEntry entry) {
    final missing = <String>[];
    if (entry.feedbackId.trim().isEmpty) missing.add('feedback_id');
    if (entry.source.trim().isEmpty) missing.add('source');
    if (entry.consent.trim().isEmpty) missing.add('consent');
    if (entry.workflow.trim().isEmpty) missing.add('workflow');
    if (entry.observation.trim().isEmpty) missing.add('observation');
    if (entry.impact.trim().isEmpty) missing.add('impact');
    if (entry.evidence.isEmpty) missing.add('evidence');
    if (entry.limitations.isEmpty) missing.add('limitations');
    return missing;
  }

  /// Evaluates the whole log:
  /// * empty log -> `blocked` (no real feedback yet; cohort pending, 113.3);
  /// * any incomplete entry -> `fail`;
  /// * otherwise -> `pass`, retaining every entry's limitations.
  FeedbackLogDecision evaluate() {
    if (_entries.isEmpty) {
      return const FeedbackLogDecision(
        decision: FeedbackDecision.blocked,
        entryCount: 0,
        limitations: <String>[
          'Belum ada feedback partisipan nyata: kohort dan persetujuan '
              'partisipan belum dimulai (step 113.3), sehingga klaim '
              'dampak diblokir sampai bukti nyata terkumpul.',
        ],
      );
    }

    final limitations = <String>[];
    var complete = true;
    for (final entry in _entries) {
      final missing = missingFields(entry);
      if (missing.isNotEmpty) {
        complete = false;
        limitations.add(
          'entry ${entry.feedbackId.trim().isEmpty ? '(tanpa id)' : entry.feedbackId} '
          'incomplete: missing ${missing.join(', ')}',
        );
      }
      limitations.addAll(entry.limitations);
    }

    return FeedbackLogDecision(
      decision: complete ? FeedbackDecision.pass : FeedbackDecision.fail,
      entryCount: _entries.length,
      limitations: limitations,
    );
  }
}
