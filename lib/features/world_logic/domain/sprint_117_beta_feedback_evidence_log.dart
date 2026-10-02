// Copyright 2026 Choirudin. All rights reserved.
//
// Sprint 117.37 — Beta Feedback Evidence Log.
//
// Contract from the canonical step (external sprint_117.json, required_fields):
//   feedback_id, consent, provider, workflow, outcome, impact, evidence,
//   limitations.
//
// The gate is fail-closed and evidence-gated:
//   * every required field must carry at least one measured pass check;
//   * a blank string, a blank list element, or an empty observed/declared
//     value is a structural failure, never a pass;
//   * a required field without any check is missing_field_check;
//   * a required field whose checks never pass is field_without_pass;
//   * `unmet` checks are contract demands this run could not satisfy from a
//     shipped seam. They are named as open items, never converted to passes
//     and never deleted. Only violations and structural failures fail the gate.
//
// Nothing here asserts that a beta participant left feedback. The cohort has
// not started, so real entries remain zero and the verdict says the log
// contract was validated, not that feedback was recorded.

/// Whether a check's declared contract is satisfied by this run's evidence.
enum Sprint117FeedbackStatus {
  /// The shipped seam measured exactly what the check declares.
  pass,

  /// The contract demand has no shipped source yet; reported as an open item.
  unmet,
}

/// One measured statement about one required field.
///
/// `observed` must come from a probe this run actually executed. Empty
/// `declared` or `observed` is rejected as `vacuous` by the gate.
final class Sprint117FeedbackCheck {
  const Sprint117FeedbackCheck._({
    required this.field,
    required this.check,
    required this.status,
    required this.declared,
    required this.observed,
    required this.note,
  });

  /// The shipped seam measured exactly what this check declares.
  const Sprint117FeedbackCheck.pass({
    required String field,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) : this._(
         field: field,
         check: check,
         status: Sprint117FeedbackStatus.pass,
         declared: declared,
         observed: observed,
         note: note,
       );

  /// A contract demand that has no shipped source yet.
  const Sprint117FeedbackCheck.unmet({
    required String field,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) : this._(
         field: field,
         check: check,
         status: Sprint117FeedbackStatus.unmet,
         declared: declared,
         observed: observed,
         note: note,
       );

  final String field;
  final String check;
  final Sprint117FeedbackStatus status;
  final String declared;
  final String observed;
  final String note;

  String get code => '$field:$check';
  bool get isPass => status == Sprint117FeedbackStatus.pass;

  Map<String, Object?> toJson() => <String, Object?>{
    'field': field,
    'check': check,
    'status': status.name,
    'declared': declared,
    'observed': observed,
    if (note.isNotEmpty) 'note': note,
  };
}

/// One log entry. Exactly the eight canonical fields, no more, no fewer.
final class Sprint117BetaFeedbackEntry {
  const Sprint117BetaFeedbackEntry({
    required this.feedbackId,
    required this.consent,
    required this.provider,
    required this.workflow,
    required this.outcome,
    required this.impact,
    required this.evidence,
    required this.limitations,
  });

  final String feedbackId;
  final String consent;
  final String provider;
  final String workflow;
  final String outcome;
  final String impact;
  final List<String> evidence;
  final List<String> limitations;
}

/// Aggregate verdict of the 117.37 log gate.
final class Sprint117FeedbackResult {
  Sprint117FeedbackResult({
    required this.verdict,
    required this.pass,
    required this.failures,
    required this.openItems,
    required this.checks,
    required this.fixtureEntries,
  });

  final String verdict;
  final bool pass;
  final List<String> failures;
  final List<String> openItems;
  final List<Sprint117FeedbackCheck> checks;
  final int fixtureEntries;

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': '117.37',
    'document_role': 'EVIDENCE',
    'verdict': verdict,
    'pass': pass,
    'required_fields': List<String>.from(
      Sprint117BetaFeedbackLog.requiredFields,
    ),
    'fixture_entries': fixtureEntries,
    'failures': List<String>.from(failures),
    'open_items': List<String>.from(openItems),
    'checks': [for (final check in checks) check.toJson()],
  };
}

/// Fail-closed log contract for sprint 117.37.
abstract final class Sprint117BetaFeedbackLog {
  /// Verbatim from the canonical step's required_fields.
  static const List<String> requiredFields = <String>[
    'feedback_id',
    'consent',
    'provider',
    'workflow',
    'outcome',
    'impact',
    'evidence',
    'limitations',
  ];

  static const String passVerdict =
      'BETA_FEEDBACK_LOG_CONTRACT_VALIDATED_LOCAL';
  static const String failVerdict = 'BETA_FEEDBACK_LOG_CONTRACT_FAILED';

  static String _readable(String feedbackId) =>
      feedbackId.trim().isEmpty ? '(no feedback_id)' : feedbackId;

  /// A check that declares nothing observable; a vacuous pass is never a pass.
  static bool isVacuous(Sprint117FeedbackCheck check) =>
      check.declared.trim().isEmpty || check.observed.trim().isEmpty;

  /// Required fields that carry no usable value in this entry.
  ///
  /// A list field counts only when at least one element survives trimming, so
  /// `evidence: ['  ']` is missing evidence, not present evidence.
  static List<String> missingFields(Sprint117BetaFeedbackEntry entry) {
    final missing = <String>[];
    if (entry.feedbackId.trim().isEmpty) missing.add('feedback_id');
    if (entry.consent.trim().isEmpty) missing.add('consent');
    if (entry.provider.trim().isEmpty) missing.add('provider');
    if (entry.workflow.trim().isEmpty) missing.add('workflow');
    if (entry.outcome.trim().isEmpty) missing.add('outcome');
    if (entry.impact.trim().isEmpty) missing.add('impact');
    if (!_hasText(entry.evidence)) missing.add('evidence');
    if (!_hasText(entry.limitations)) missing.add('limitations');
    return missing;
  }

  /// List elements that trim to nothing: `field:0` style, in field order.
  static List<String> blankListElements(Sprint117BetaFeedbackEntry entry) {
    final blanks = <String>[];
    for (final field in const <String>['evidence', 'limitations']) {
      final values = field == 'evidence' ? entry.evidence : entry.limitations;
      for (var index = 0; index < values.length; index += 1) {
        if (values[index].trim().isEmpty) blanks.add('$field:$index');
      }
    }
    return blanks;
  }

  static bool _hasText(List<String> values) =>
      values.any((value) => value.trim().isNotEmpty);

  static Sprint117FeedbackResult evaluate({
    required List<Sprint117BetaFeedbackEntry> entries,
    required List<Sprint117FeedbackCheck> checks,
  }) {
    final failures = <String>[];

    final canonical = requiredFields.toSet();
    if (canonical.length != requiredFields.length) {
      failures.add('non_canonical_required_fields');
    }

    if (entries.isEmpty) {
      failures.add('no_entries');
    }

    final seenIds = <String>{};
    for (final entry in entries) {
      final id = entry.feedbackId;
      for (final field in missingFields(entry)) {
        failures.add('missing_field:${_readable(id)}:$field');
      }
      for (final blank in blankListElements(entry)) {
        failures.add('blank_list_element:${_readable(id)}:$blank');
      }
      if (id.trim().isNotEmpty) {
        if (!seenIds.add(id)) failures.add('duplicate_feedback_id:$id');
      }
    }

    final seenChecks = <String>{};
    for (final check in checks) {
      if (!canonical.contains(check.field)) {
        failures.add('unknown_field:${check.field}');
      }
      if (!seenChecks.add(check.code)) {
        failures.add('duplicate_check:${check.code}');
      }
      if (isVacuous(check)) {
        failures.add('vacuous:${check.code}');
      }
    }

    for (final field in requiredFields) {
      final fieldChecks = checks
          .where((check) => check.field == field)
          .toList();
      if (fieldChecks.isEmpty) {
        failures.add('missing_field_check:$field');
        continue;
      }
      // Fail-closed: a vacuous pass carries no observation, so it cannot
      // satisfy the field it claims to cover.
      final satisfied = fieldChecks.any(
        (check) => check.isPass && !isVacuous(check),
      );
      if (!satisfied) {
        failures.add('field_without_pass:$field');
      }
    }

    final openItems = <String>[
      for (final check in checks)
        if (!check.isPass) check.code,
    ];

    return Sprint117FeedbackResult(
      verdict: failures.isEmpty ? passVerdict : failVerdict,
      pass: failures.isEmpty,
      failures: failures,
      openItems: openItems,
      checks: checks,
      fixtureEntries: entries.length,
    );
  }
}
