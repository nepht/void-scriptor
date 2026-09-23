/// Issue Deduplication & Root Cause (Step 113.29).
///
/// Domain contract for merging duplicate issue reports into one canonical
/// report and for pinning the root cause, component, affected versions,
/// reproduction steps, and owner — the seven canonical required_fields of
/// the step.
///
/// The domain stays dependency-free. The test drives the registry through
/// complete, incomplete, merged, and empty states and cross-checks the
/// manifest. Deduplication semantics:
/// * `duplicates` may be empty on a fresh report (no duplicates known yet);
/// * folding a report via [IssueRegistry.mergeDuplicates] records the target
///   in the registry's folded set and the canonical report's `duplicates`;
/// * a `duplicates` entry that resolves to neither a live report nor a
///   folded target fails the decision (unknown reference).
library;

/// Canonical required field names of step 113.29, in ledger order.
const List<String> _requiredFieldNames = <String>[
  'issue_id',
  'duplicates',
  'reproduction',
  'component',
  'root_cause',
  'affected_versions',
  'owner',
];

/// One issue report with its root-cause attribution.
class IssueReport {
  const IssueReport({
    required this.issueId,
    required this.duplicates,
    required this.reproduction,
    required this.component,
    required this.rootCause,
    required this.affectedVersions,
    required this.owner,
  });

  /// Canonical seven-field list, exposed for contract tests.
  static const List<String> requiredFieldNames = _requiredFieldNames;

  /// Stable identifier of the report (`issue_id`).
  final String issueId;

  /// Identifiers of reports folded into this one (`duplicates`). Empty is
  /// valid: a canonical report may start without duplicates.
  final List<String> duplicates;

  /// Ordered reproduction steps (`reproduction`). Must not be empty.
  final List<String> reproduction;

  /// Component the root cause lives in (`component`).
  final String component;

  /// Determined cause of the issue (`root_cause`).
  final String rootCause;

  /// Versions the issue was observed in (`affected_versions`). Must not be
  /// empty.
  final List<String> affectedVersions;

  /// Who owns the follow-up (`owner`).
  final String owner;

  /// Returns a copy with [duplicates], [reproduction], and
  /// [affectedVersions] folded together (receiver first, extra items
  /// appended without duplicates).
  IssueReport mergeWith(IssueReport other) {
    return IssueReport(
      issueId: issueId,
      duplicates: <String>{...duplicates, ...other.duplicates}.toList(),
      reproduction: <String>{...reproduction, ...other.reproduction}.toList(),
      component: component,
      rootCause: rootCause,
      affectedVersions: <String>{
        ...affectedVersions,
        ...other.affectedVersions,
      }.toList(),
      owner: owner,
    );
  }
}

/// Outcome of evaluating the registry.
enum IssueDecision {
  /// Every live report is complete and every duplicate reference resolves.
  pass,

  /// At least one report is incomplete or references an unknown duplicate.
  fail,

  /// No reports recorded yet, so no deduplication claim can be made.
  blocked,
}

/// Result of `IssueRegistry.evaluate`.
class IssueRegistryDecision {
  const IssueRegistryDecision({
    required this.decision,
    required this.reportCount,
    required this.limitations,
  });

  final IssueDecision decision;
  final int reportCount;

  /// Human-readable limitations (log-level for `blocked`, per-report notes
  /// for `pass`/`fail`).
  final List<String> limitations;
}

/// Registry of issue reports with deduplication bookkeeping.
class IssueRegistry {
  final Map<String, IssueReport> _reports = <String, IssueReport>{};
  final List<String> _duplicateTargets = <String>[];

  /// Live reports in insertion order.
  List<IssueReport> get reports =>
      List<IssueReport>.unmodifiable(_reports.values);

  /// Identifiers folded into a canonical report so far, in fold order.
  List<String> get duplicateTargets =>
      List<String>.unmodifiable(_duplicateTargets);

  /// Whether a report with [id] is live in the registry.
  bool contains(String id) => _reports.containsKey(id);

  /// Records one report. Validation happens in [evaluate].
  void add(IssueReport report) {
    _reports[report.issueId] = report;
  }

  /// Folds [duplicateIds] into the live report [canonicalId]: each target is
  /// removed from the live set, recorded in [duplicateTargets], appended to
  /// the canonical report's `duplicates`, and its reproduction steps and
  /// affected versions are merged in. Returns the updated canonical report.
  IssueReport mergeDuplicates(String canonicalId, List<String> duplicateIds) {
    final canonical = _reports[canonicalId];
    if (canonical == null) {
      throw ArgumentError.value(
        canonicalId,
        'canonicalId',
        'not a live report',
      );
    }

    var merged = canonical;
    for (final id in duplicateIds) {
      final target = _reports.remove(id);
      if (target == null) {
        throw ArgumentError.value(id, 'duplicateIds', 'not a live report');
      }
      _duplicateTargets.add(id);
      merged = IssueReport(
        issueId: merged.issueId,
        duplicates: <String>{
          ...merged.duplicates,
          ...target.duplicates,
          id,
        }.toList(),
        reproduction: <String>{
          ...merged.reproduction,
          ...target.reproduction,
        }.toList(),
        component: merged.component,
        rootCause: merged.rootCause,
        affectedVersions: <String>{
          ...merged.affectedVersions,
          ...target.affectedVersions,
        }.toList(),
        owner: merged.owner,
      );
    }
    _reports[canonicalId] = merged;
    return merged;
  }

  /// Canonical names of the required fields that are blank or empty in
  /// [report]. `duplicates` is exempt: empty means "no duplicates known".
  List<String> missingFields(IssueReport report) {
    final missing = <String>[];
    if (report.issueId.trim().isEmpty) missing.add('issue_id');
    if (report.reproduction.isEmpty) missing.add('reproduction');
    if (report.component.trim().isEmpty) missing.add('component');
    if (report.rootCause.trim().isEmpty) missing.add('root_cause');
    if (report.affectedVersions.isEmpty) missing.add('affected_versions');
    if (report.owner.trim().isEmpty) missing.add('owner');
    return missing;
  }

  /// Evaluates the whole registry:
  /// * empty registry -> `blocked` (no reports collected yet);
  /// * any incomplete report or unresolvable duplicate reference -> `fail`;
  /// * otherwise -> `pass`.
  IssueRegistryDecision evaluate() {
    if (_reports.isEmpty) {
      return const IssueRegistryDecision(
        decision: IssueDecision.blocked,
        reportCount: 0,
        limitations: <String>[
          'Belum ada laporan isu terkumpul, sehingga klaim deduplikasi '
              'dan akar masalah diblokir sampai laporan nyata masuk.',
        ],
      );
    }

    final limitations = <String>[];
    var complete = true;
    for (final report in _reports.values) {
      final missing = missingFields(report);
      if (missing.isNotEmpty) {
        complete = false;
        limitations.add(
          'report ${report.issueId} incomplete: missing ${missing.join(', ')}',
        );
      }
      for (final dup in report.duplicates) {
        final known =
            _reports.containsKey(dup) || _duplicateTargets.contains(dup);
        if (!known) {
          complete = false;
          limitations.add(
            'report ${report.issueId} references unknown duplicate $dup',
          );
        }
      }
    }

    return IssueRegistryDecision(
      decision: complete ? IssueDecision.pass : IssueDecision.fail,
      reportCount: _reports.values.length,
      limitations: limitations,
    );
  }
}
