// Copyright 2026 Choirudin. All rights reserved.
//
// Sprint 117.38 — Issue Deduplication & Triage.
//
// Canonical step (external sprint_117.json) objective: "Menggabungkan issue
// dan memutus blocker, fix, flag-off, connector-disable, defer, or rollback.",
// and its six canonical decisions:
//   FIX_BEFORE_GA, FLAG_OFF, DISABLE_CONNECTOR, DEFER,
//   ROLLBACK, NOT_REPRODUCIBLE_WITH_EVIDENCE.
//
// The gate is fail-closed and evidence-gated:
//   * every canonical decision must carry at least one measured pass check;
//   * a blank string, a blank list element, or an empty declared/observed
//     value is a structural failure, never a pass;
//   * a canonical decision with no check is `missing_decision_check`;
//   * a canonical decision whose checks never pass is
//     `decision_without_pass`;
//   * `unmet` checks are contract demands this run could not satisfy from a
//     shipped seam. They are named as open items, never converted to passes
//     and never deleted.
//
// Two canonical decisions — FLAG_OFF and DISABLE_CONNECTOR — are not verdicts
// on their own: they name an ACTION taken against shipped state. An issue that
// records one is a claim that the product actually turned a capability off, or
// actually dropped a connector. So the gate requires a measured action result
// from a real seam:
//   * no result for the issue            -> `unexpressible_decision`
//   * a result that did not apply        -> `action_not_applied`
//   * a result naming a different decision -> `action_decision_mismatch`
//   * an applied result with no observation -> `vacuous_action`
// A caller that wants the verdict without performing the action gets a failure
// naming the issue, which is the fail-closed outcome.
//
// Nothing here asserts that a GA blocker was found, that a participant filed
// an issue, or that a triage decision was applied in a live release. The
// cohort has not started, so the gate validates the decision contract and
// the merge seam against measured actions.

/// Whether a check's declared contract is satisfied by this run's evidence.
enum Sprint117TriageStatus {
  /// The shipped seam measured exactly what the check declares.
  pass,

  /// The contract demand has no shipped source yet; reported as an open item.
  unmet,
}

/// Canonical decisions that name an ACTION against shipped state rather than a
/// verdict about an issue.
///
/// Recording one of these on an issue asserts that the product really turned a
/// capability off, or really dropped a connector. A verdict therefore needs a
/// measured [Sprint117TriageResolution] from the seam that performed it.
abstract final class Sprint117TriageActions {
  /// The decisions that cannot be asserted without an action result.
  static const List<String> decisionsRequiringAction = <String>[
    'FLAG_OFF',
    'DISABLE_CONNECTOR',
  ];

  /// True when [decision] may only be asserted by performing an action.
  static bool requiresAction(String decision) =>
      decisionsRequiringAction.contains(decision.trim());
}

/// What the seam observed after carrying out one triage action.
///
/// This is deliberately not a verdict: `applied` says the state changed, while
/// [observed] carries the evidence string that proves it to a reader later.
final class Sprint117TriageResolution {
  Sprint117TriageResolution({
    required this.decision,
    required this.applied,
    required this.observed,
  });

  /// The canonical decision this action carried out.
  final String decision;

  /// Whether the shipped state actually changed.
  final bool applied;

  /// Measured evidence string; blank makes the action vacuous.
  final String observed;
}

/// One measured statement about one canonical decision.
final class Sprint117TriageCheck {
  const Sprint117TriageCheck._({
    required this.decision,
    required this.check,
    required this.status,
    required this.declared,
    required this.observed,
    required this.note,
  });

  /// The shipped seam measured exactly what this check declares.
  const Sprint117TriageCheck.pass({
    required String decision,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) : this._(
         decision: decision,
         check: check,
         status: Sprint117TriageStatus.pass,
         declared: declared,
         observed: observed,
         note: note,
       );

  /// A contract demand that has no shipped source yet.
  const Sprint117TriageCheck.unmet({
    required String decision,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) : this._(
         decision: decision,
         check: check,
         status: Sprint117TriageStatus.unmet,
         declared: declared,
         observed: observed,
         note: note,
       );

  final String decision;
  final String check;
  final Sprint117TriageStatus status;
  final String declared;
  final String observed;
  final String note;

  String get code => '$decision:$check';
  bool get isPass => status == Sprint117TriageStatus.pass;

  Map<String, Object?> toJson() => <String, Object?>{
    'decision': decision,
    'check': check,
    'status': status.name,
    'declared': declared,
    'observed': observed,
    if (note.isNotEmpty) 'note': note,
  };
}

/// One triaged issue. The eight fields the decision is derived from.
final class Sprint117TriagedIssue {
  const Sprint117TriagedIssue({
    required this.issueId,
    required this.decision,
    required this.reproducible,
    required this.meetsBlockerDefinition,
    required this.duplicateIds,
    required this.rationale,
    required this.evidence,
  });

  final String issueId;
  final String decision;
  final bool reproducible;
  final bool meetsBlockerDefinition;
  final List<String> duplicateIds;
  final String rationale;
  final List<String> evidence;
}

/// Aggregate verdict of the 117.38 triage gate.
final class Sprint117TriageResult {
  Sprint117TriageResult({
    required this.verdict,
    required this.pass,
    required this.failures,
    required this.openItems,
    required this.checks,
    required this.fixtureIssues,
    required this.decisionsSeen,
  });

  final String verdict;
  final bool pass;
  final List<String> failures;
  final List<String> openItems;
  final List<Sprint117TriageCheck> checks;
  final int fixtureIssues;
  final List<String> decisionsSeen;

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': '117.38',
    'document_role': 'EVIDENCE',
    'verdict': verdict,
    'pass': pass,
    'canonical_decisions': List<String>.from(
      Sprint117IssueTriage.canonicalDecisions,
    ),
    'fixture_issues': fixtureIssues,
    'decisions_seen': List<String>.from(decisionsSeen),
    'failures': List<String>.from(failures),
    'open_items': List<String>.from(openItems),
    'checks': [for (final check in checks) check.toJson()],
  };
}

/// Fail-closed triage contract for sprint 117.38.
abstract final class Sprint117IssueTriage {
  /// Verbatim, in canonical order, from the canonical step's `decisions`.
  static const List<String> canonicalDecisions = <String>[
    'FIX_BEFORE_GA',
    'FLAG_OFF',
    'DISABLE_CONNECTOR',
    'DEFER',
    'ROLLBACK',
    'NOT_REPRODUCIBLE_WITH_EVIDENCE',
  ];

  static const String passVerdict =
      'ISSUE_DEDUPLICATION_AND_TRIAGE_VALIDATED_LOCAL';
  static const String failVerdict = 'ISSUE_DEDUPLICATION_AND_TRIAGE_FAILED';

  /// The decisions the shipped triage log (113.30) actually accepts.
  ///
  /// This is step 113.30's vocabulary, not 117.38's: the six canonical
  /// decisions of THIS step are [canonicalDecisions]. Two of them are absent
  /// here because 113.30 classifies issues against the release-blocker
  /// definition and never performed a flag-off or a connector-disable. That
  /// absence is not proof that the actions cannot be taken — [Sprint117TriageActions]
  /// names the seams that perform them.
  static const List<String> shippedTriageDecisions = <String>[
    'FIX_BEFORE_GA',
    'DEFER_NON_BLOCKER',
    'STOP_SHIP',
    'ROLLBACK_RC',
    'NOT_REPRODUCIBLE_WITH_EVIDENCE',
  ];

  static String _readable(String issueId) =>
      issueId.trim().isEmpty ? '(no issue_id)' : issueId;

  /// A check that declares nothing observable; a vacuous pass is never a pass.
  static bool isVacuous(Sprint117TriageCheck check) =>
      check.declared.trim().isEmpty || check.observed.trim().isEmpty;

  /// Canonical fields that carry no usable value in this issue.
  ///
  /// `duplicateIds` is exempt from being non-empty: a canonical issue may
  /// have no known duplicates. `evidence` is not, because every decision in
  /// this step is a claim about an issue and an unbacked claim cannot cut it.
  static List<String> missingFields(Sprint117TriagedIssue issue) {
    final missing = <String>[];
    if (issue.issueId.trim().isEmpty) missing.add('issue_id');
    if (issue.decision.trim().isEmpty) missing.add('decision');
    if (issue.rationale.trim().isEmpty) missing.add('rationale');
    if (!_hasText(issue.evidence)) missing.add('evidence');
    return missing;
  }

  /// List elements that trim to nothing: `field:index`, in field order.
  static List<String> blankListElements(Sprint117TriagedIssue issue) {
    final blanks = <String>[];
    for (final field in const <String>['duplicate_ids', 'evidence']) {
      final values = field == 'duplicate_ids'
          ? issue.duplicateIds
          : issue.evidence;
      for (var index = 0; index < values.length; index += 1) {
        if (values[index].trim().isEmpty) blanks.add('$field:$index');
      }
    }
    return blanks;
  }

  static bool _hasText(List<String> values) =>
      values.any((value) => value.trim().isNotEmpty);

  static Sprint117TriageResult evaluate({
    required List<Sprint117TriagedIssue> issues,
    required List<Sprint117TriageCheck> checks,
    Map<String, Sprint117TriageResolution> actionResults =
        const <String, Sprint117TriageResolution>{},
  }) {
    final failures = <String>[];

    final canonical = canonicalDecisions.toSet();
    if (canonical.length != canonicalDecisions.length) {
      failures.add('non_canonical_decisions');
    }

    if (issues.isEmpty) {
      failures.add('no_issues');
    }

    final seenIds = <String>{};
    final decisionsSeen = <String>{};
    for (final issue in issues) {
      final id = issue.issueId;
      for (final field in missingFields(issue)) {
        failures.add('missing_field:${_readable(id)}:$field');
      }
      for (final blank in blankListElements(issue)) {
        failures.add('blank_list_element:${_readable(id)}:$blank');
      }
      if (id.trim().isNotEmpty) {
        if (!seenIds.add(id)) failures.add('duplicate_issue_id:$id');
      }
      final decision = issue.decision.trim();
      if (decision.isNotEmpty) {
        if (!canonical.contains(decision)) {
          failures.add('unknown_decision:${_readable(id)}:$decision');
        }
        final resolution = actionResults[id];
        final hasActionResult =
            resolution != null && resolution.decision.trim() == decision;
        if (Sprint117TriageActions.requiresAction(decision)) {
          // The issue claims an action, so it must be measured. A result the
          // caller supplied is judged on its own claims rather than swallowed
          // by the generic "no result" rule.
          if (resolution == null) {
            failures.add('unexpressible_decision:${_readable(id)}:$decision');
          } else if (!hasActionResult) {
            failures.add('action_decision_mismatch:${_readable(id)}:$decision');
          } else if (!resolution.applied) {
            failures.add('action_not_applied:${_readable(id)}:$decision');
          } else if (resolution.observed.trim().isEmpty) {
            failures.add('vacuous_action:${_readable(id)}:$decision');
          }
        }
        decisionsSeen.add(decision);
      }
    }

    final seenChecks = <String>{};
    for (final check in checks) {
      if (!canonical.contains(check.decision)) {
        failures.add('unknown_decision_check:${check.decision}');
      }
      if (!seenChecks.add(check.code)) {
        failures.add('duplicate_check:${check.code}');
      }
      if (isVacuous(check)) {
        failures.add('vacuous:${check.code}');
      }
    }

    for (final decision in canonicalDecisions) {
      final decisionChecks = checks
          .where((check) => check.decision == decision)
          .toList();
      if (decisionChecks.isEmpty) {
        failures.add('missing_decision_check:$decision');
        continue;
      }
      // Fail-closed: a vacuous pass carries no observation, so it cannot
      // satisfy the decision it claims to cover.
      final satisfied = decisionChecks.any(
        (check) => check.isPass && !isVacuous(check),
      );
      if (!satisfied) {
        failures.add('decision_without_pass:$decision');
      }
    }

    final openItems = <String>[
      for (final check in checks)
        if (!check.isPass) check.code,
    ];

    return Sprint117TriageResult(
      verdict: failures.isEmpty ? passVerdict : failVerdict,
      pass: failures.isEmpty,
      failures: failures,
      openItems: openItems,
      checks: checks,
      fixtureIssues: issues.length,
      decisionsSeen: decisionsSeen.toList()..sort(),
    );
  }
}
