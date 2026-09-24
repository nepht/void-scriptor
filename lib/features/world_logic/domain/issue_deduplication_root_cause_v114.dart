/// Dependency-free contract for Sprint 114.26 issue deduplication.
class IssueRecord {
  const IssueRecord({
    required this.issueId,
    required this.duplicates,
    required this.reproduction,
    required this.affectedVersions,
    required this.rootCause,
    required this.owner,
    required this.fixPath,
  });

  static const List<String> requiredFieldNames = <String>[
    'issue_id',
    'duplicates',
    'reproduction',
    'affected_versions',
    'root_cause',
    'owner',
    'fix_path',
  ];

  final String issueId;
  final List<String> duplicates;
  final List<String> reproduction;
  final List<String> affectedVersions;
  final String rootCause;
  final String owner;
  final String fixPath;
}

enum IssueStatus { pass, fail, blocked }

class IssueDecision {
  const IssueDecision({
    required this.status,
    required this.issueCount,
    required this.limitations,
  });

  final IssueStatus status;
  final int issueCount;
  final List<String> limitations;
}

class IssueRegister {
  final Map<String, IssueRecord> _issues = <String, IssueRecord>{};
  final Set<String> _foldedIds = <String>{};

  void add(IssueRecord issue) => _issues[issue.issueId] = issue;

  static List<String> missingFields(IssueRecord issue) {
    final missing = <String>[];
    if (issue.issueId.trim().isEmpty) {
      missing.add('issue_id');
    }
    if (issue.reproduction.isEmpty) {
      missing.add('reproduction');
    }
    if (issue.affectedVersions.isEmpty) {
      missing.add('affected_versions');
    }
    if (issue.rootCause.trim().isEmpty) {
      missing.add('root_cause');
    }
    if (issue.owner.trim().isEmpty) {
      missing.add('owner');
    }
    if (issue.fixPath.trim().isEmpty) {
      missing.add('fix_path');
    }
    return missing;
  }

  IssueRecord mergeDuplicates(String canonicalId, List<String> duplicateIds) {
    final canonical = _issues[canonicalId];
    if (canonical == null) {
      throw ArgumentError('canonical issue is not registered');
    }
    final duplicates = <String>{...canonical.duplicates};
    final reproduction = <String>{...canonical.reproduction};
    final versions = <String>{...canonical.affectedVersions};
    for (final id in duplicateIds) {
      final duplicate = _issues.remove(id);
      if (duplicate == null) {
        throw ArgumentError('duplicate issue is not registered: $id');
      }
      duplicates.add(id);
      duplicates.addAll(duplicate.duplicates);
      reproduction.addAll(duplicate.reproduction);
      versions.addAll(duplicate.affectedVersions);
      _foldedIds.add(id);
    }
    final merged = IssueRecord(
      issueId: canonical.issueId,
      duplicates: duplicates.toList(),
      reproduction: reproduction.toList(),
      affectedVersions: versions.toList(),
      rootCause: canonical.rootCause,
      owner: canonical.owner,
      fixPath: canonical.fixPath,
    );
    _issues[canonicalId] = merged;
    return merged;
  }

  IssueDecision evaluate() {
    if (_issues.isEmpty) {
      return const IssueDecision(
        status: IssueStatus.blocked,
        issueCount: 0,
        limitations: <String>[
          'No issue report is available; root cause is unverified.',
        ],
      );
    }
    final limitations = <String>[];
    for (final issue in _issues.values) {
      final missing = missingFields(issue);
      if (missing.isNotEmpty) {
        limitations.add('${issue.issueId} missing ${missing.join(', ')}');
      }
      for (final duplicate in issue.duplicates) {
        if (!_issues.containsKey(duplicate) &&
            !_foldedIds.contains(duplicate)) {
          limitations.add(
            '${issue.issueId} references unknown duplicate $duplicate',
          );
        }
      }
    }
    return IssueDecision(
      status: limitations.isEmpty ? IssueStatus.pass : IssueStatus.fail,
      issueCount: _issues.length,
      limitations: limitations,
    );
  }
}
