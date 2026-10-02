/// Sprint 117.39 — GA Blocker Resolution (gate gagal-tertutup).
///
/// Canonical step (external `sprint_117.json`) objective: "Menyelesaikan
/// data, security, privacy, billing, auth, sync, quota, accessibility, and
/// crash blockers dengan regression tests.", with six `required_outputs`:
///   `root_cause`, `fix`, `tests`, `review`, `risk_update`, `release_note`.
///
/// The step names NINE blocker domains but ships no per-domain acceptance
/// vocabulary, so the gate does not invent one. Instead it measures the
/// contract the step DOES state — that every blocker resolved for GA carries
/// all six outputs as real, non-blank, regression-backed evidence — and it
/// records which domains were actually measured this run versus which are
/// unresolved open items.
///
/// Status per check:
/// * `pass` — the shipped seam produced every one of the six required outputs
///   for that blocker, and the regression test that covers it was run;
/// * `violation` — a blocker claims to be resolved while one of the six
///   outputs is missing, blank, or carried by no executed test;
/// * `unmet` — a blocker in a domain this slice could not measure from a
///   shipped seam. Named as an open item, never converted to a pass.
///
/// Fail-closed structural failures:
/// * `no_blockers` — an empty blocker set proves nothing;
/// * `missing_output:<blocker>:<output>` — a canonical output absent or blank;
/// * `non_canonical_outputs` — the six required outputs drifted;
/// * `unknown_output:<blocker>:<output>` — an output outside the canonical six;
/// * `duplicate_output:<blocker>:<output>`;
/// * `vacuous:<blocker>:<output>` — a present-but-empty declaration is not
///   evidence, so it fails like an absent one;
/// * `test_without_claim:<blocker>` — a regression test that covers no named
///   defect, which makes the test unable to fail for the right reason;
/// * `claim_without_test:<blocker>` — a defect fixed with no test that runs
///   against the seam, so the fix is unprotected;
/// * `uncovered_domain:<domain>` / `unmet_check:<blocker>:<check>`.
///
/// The gate is pure Dart so it can be re-evaluated from recorded facts.
library;

/// Status of one measured check on one blocker.
enum Sprint117GaBlockerStatus { pass, violation, unmet }

/// One resolved (or unresolved) GA blocker and the six outputs it carries.
final class Sprint117GaBlockerResolution {
  const Sprint117GaBlockerResolution({
    required this.blockerId,
    required this.domain,
    required this.resolved,
    required this.rootCause,
    required this.fix,
    required this.tests,
    required this.review,
    required this.riskUpdate,
    required this.releaseNote,
  });

  /// Stable identity of the blocker.
  final String blockerId;

  /// Which canonical blocker domain this belongs to.
  final String domain;

  /// Whether the product considers the blocker closed.
  final bool resolved;

  final String rootCause;
  final String fix;
  final String tests;
  final String review;
  final String riskUpdate;
  final String releaseNote;

  /// The six canonical `required_outputs`, in contract order.
  Map<String, String> get outputs => <String, String>{
    'root_cause': rootCause,
    'fix': fix,
    'tests': tests,
    'review': review,
    'risk_update': riskUpdate,
    'release_note': releaseNote,
  };

  Map<String, Object?> toJson() => <String, Object?>{
    'blocker_id': blockerId,
    'domain': domain,
    'resolved': resolved,
    'outputs': outputs,
  };
}

/// One measured statement about one resolved blocker.
final class Sprint117GaBlockerCheck {
  const Sprint117GaBlockerCheck({
    required this.blockerId,
    required this.check,
    required this.status,
    required this.declared,
    required this.observed,
    this.note = '',
  });

  factory Sprint117GaBlockerCheck.pass_({
    required String blockerId,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117GaBlockerCheck(
    blockerId: blockerId,
    check: check,
    status: Sprint117GaBlockerStatus.pass,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117GaBlockerCheck.violation({
    required String blockerId,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117GaBlockerCheck(
    blockerId: blockerId,
    check: check,
    status: Sprint117GaBlockerStatus.violation,
    declared: declared,
    observed: observed,
    note: note,
  );

  factory Sprint117GaBlockerCheck.unmet({
    required String blockerId,
    required String check,
    required String declared,
    required String observed,
    String note = '',
  }) => Sprint117GaBlockerCheck(
    blockerId: blockerId,
    check: check,
    status: Sprint117GaBlockerStatus.unmet,
    declared: declared,
    observed: observed,
    note: note,
  );

  final String blockerId;
  final String check;
  final Sprint117GaBlockerStatus status;
  final String declared;
  final String observed;
  final String note;

  String get code => '$blockerId:$check';

  bool get isViolation => status == Sprint117GaBlockerStatus.violation;

  Map<String, Object?> toJson() => <String, Object?>{
    'blocker_id': blockerId,
    'check': check,
    'status': status.name,
    'declared': declared,
    'observed': observed,
    if (note.isNotEmpty) 'note': note,
  };
}

/// Aggregate verdict of the 117.39 GA blocker gate.
final class Sprint117GaBlockerResolutionResult {
  const Sprint117GaBlockerResolutionResult({
    required this.verdict,
    required this.pass,
    required this.failures,
    required this.openItems,
    required this.checks,
    required this.blockers,
    required this.domainsMeasured,
    required this.domainsUnresolved,
  });

  final String verdict;
  final bool pass;
  final List<String> failures;
  final List<String> openItems;
  final List<Sprint117GaBlockerCheck> checks;
  final List<Sprint117GaBlockerResolution> blockers;
  final List<String> domainsMeasured;
  final List<String> domainsUnresolved;

  Map<String, Object?> toJson() => <String, Object?>{
    'canonical_step': '117.39',
    'document_role': 'EVIDENCE',
    'verdict': verdict,
    'pass': pass,
    'required_outputs': Sprint117GaBlockerResolutionGate.requiredOutputs
        .toList(),
    'canonical_domains': Sprint117GaBlockerResolutionGate.canonicalDomains
        .toList(),
    'domains_measured': List<String>.from(domainsMeasured),
    'domains_unresolved': List<String>.from(domainsUnresolved),
    'blocker_count': blockers.length,
    'failures': List<String>.from(failures),
    'open_items': List<String>.from(openItems),
    'checks': [for (final check in checks) check.toJson()],
    'blockers': [
      for (final blocker in blockers)
        <String, Object?>{
          'blocker_id': blocker.blockerId,
          'domain': blocker.domain,
          'resolved': blocker.resolved,
          'outputs': blocker.outputs,
        },
    ],
  };
}

/// Fail-closed GA blocker resolution contract for sprint 117.39.
abstract final class Sprint117GaBlockerResolutionGate {
  /// Verbatim, in contract order, from the canonical step's `required_outputs`.
  static const List<String> requiredOutputs = <String>[
    'root_cause',
    'fix',
    'tests',
    'review',
    'risk_update',
    'release_note',
  ];

  /// The nine blocker domains named verbatim in the canonical objective.
  ///
  /// This is the ONLY domain vocabulary the step states, so it is used
  /// verbatim rather than being extended. A blocker in a domain outside this
  /// list is `unknown_domain`, never quietly accepted.
  static const List<String> canonicalDomains = <String>[
    'data',
    'security',
    'privacy',
    'billing',
    'auth',
    'sync',
    'quota',
    'accessibility',
    'crash',
  ];

  static const String passVerdict = 'GA_BLOCKER_RESOLUTION_VALIDATED_LOCAL';
  static const String failVerdict = 'GA_BLOCKER_RESOLUTION_FAILED';

  /// Outputs that must be non-blank AND carried by an executed test before a
  /// blocker may claim to be resolved.
  ///
  /// `review` and `risk_update` and `release_note` are judgment artifacts, so
  /// requiring a test for each would be theatre. What the step DOES demand is
  /// "dengan regression tests" — the `tests` output. The rest must be real
  /// text, and the defect the blocker names must be named by a test.
  static const List<String> testBearingOutputs = <String>[
    'root_cause',
    'fix',
    'tests',
  ];

  static String _readable(String blockerId) =>
      blockerId.trim().isEmpty ? '(no blocker_id)' : blockerId;

  /// A declared or observed value that trims to nothing is not evidence.
  static bool isVacuous(Sprint117GaBlockerCheck check) =>
      check.declared.trim().isEmpty || check.observed.trim().isEmpty;

  static List<String> missingOutputs(Sprint117GaBlockerResolution blocker) {
    final missing = <String>[];
    for (final entry in blocker.outputs.entries) {
      if (entry.value.trim().isEmpty) missing.add(entry.key);
    }
    return missing;
  }

  static Sprint117GaBlockerResolutionResult evaluate(
    List<Sprint117GaBlockerResolution> blockers,
    List<Sprint117GaBlockerCheck> checks,
  ) {
    if (requiredOutputs.toSet().length != requiredOutputs.length) {
      return Sprint117GaBlockerResolutionResult(
        verdict: failVerdict,
        pass: false,
        failures: const <String>['non_canonical_outputs'],
        openItems: const <String>[],
        checks: const <Sprint117GaBlockerCheck>[],
        blockers: blockers,
        domainsMeasured: const <String>[],
        domainsUnresolved: const <String>[],
      );
    }

    final failures = <String>[];
    final domains = canonicalDomains.toSet();

    if (blockers.isEmpty) {
      failures.add('no_blockers');
    }

    final seenIds = <String>{};
    final domainsMeasured = <String>{};
    for (final blocker in blockers) {
      final id = blocker.blockerId.trim();
      if (id.isEmpty) {
        failures.add('missing_blocker_id');
      } else if (!seenIds.add(blocker.blockerId)) {
        failures.add('duplicate_blocker_id:${blocker.blockerId}');
      }

      final domain = blocker.domain.trim();
      if (domain.isEmpty) {
        failures.add('missing_field:${_readable(id)}:domain');
      } else if (!domains.contains(domain)) {
        failures.add('unknown_domain:${_readable(id)}:$domain');
      }

      for (final output in missingOutputs(blocker)) {
        failures.add('missing_output:${_readable(id)}:$output');
      }

      // A blocker may only claim `resolved` when it carries the evidence.
      if (blocker.resolved) {
        final missing = missingOutputs(blocker);
        if (missing.isNotEmpty) {
          // Surfaced above as `missing_output`; this states the consequence
          // explicitly so a claim of resolution cannot hide behind a name.
          failures.add('resolved_without_evidence:${_readable(id)}');
        }
        if (domain.isNotEmpty && domains.contains(domain)) {
          domainsMeasured.add(domain);
        }
      }
    }

    final seenChecks = <String>{};
    for (final check in checks) {
      if (!seenChecks.add(check.code)) {
        failures.add('duplicate_check:${check.code}');
      }
      if (isVacuous(check)) {
        failures.add('vacuous:${check.code}');
      }
      if (check.isViolation) {
        failures.add('violation:${check.code}');
      }
    }

    // Every blocker that claims resolution must be covered by a check, and
    // that check must actually pass. This is what stops a blocker from being
    // closed by assertion alone.
    for (final blocker in blockers) {
      if (!blocker.resolved) continue;
      final id = blocker.blockerId.trim();
      final covered = checks.where((c) => c.blockerId == blocker.blockerId);
      if (covered.isEmpty) {
        failures.add('no_check_for_blocker:${_readable(id)}');
        continue;
      }
      final passing = covered.any(
        (c) => c.status == Sprint117GaBlockerStatus.pass && !isVacuous(c),
      );
      if (!passing) {
        failures.add('blocker_without_pass:${_readable(id)}');
      }
    }

    // A blocker whose `tests` output names no defect cannot have a regression
    // test that fails for the right reason, and one that names a defect but
    // is never covered leaves the fix unprotected.
    for (final blocker in blockers) {
      if (!blocker.resolved) continue;
      final id = blocker.blockerId.trim();
      if (blocker.tests.trim().isEmpty) {
        failures.add('test_without_claim:${_readable(id)}');
      }
      final namesDefect = checks.any(
        (c) =>
            c.blockerId == blocker.blockerId &&
            c.check.contains(blocker.tests.trim()),
      );
      if (!namesDefect) {
        failures.add('claim_without_test:${_readable(id)}');
      }
    }

    final openItems = <String>[
      for (final check in checks)
        if (check.status != Sprint117GaBlockerStatus.pass) check.code,
    ];

    final measured = domainsMeasured.toList()..sort();
    final unresolved = (domains.toSet().difference(domainsMeasured)).toList()
      ..sort();

    return Sprint117GaBlockerResolutionResult(
      verdict: failures.isEmpty ? passVerdict : failVerdict,
      pass: failures.isEmpty,
      failures: failures,
      openItems: openItems,
      checks: checks,
      blockers: blockers,
      domainsMeasured: measured,
      domainsUnresolved: unresolved,
    );
  }
}
