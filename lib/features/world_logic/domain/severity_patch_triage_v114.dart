/// Dependency-free contract for Sprint 114.27 severity and patch triage.
enum TriageDecision {
  emergencyFix,
  maintenanceFix,
  documentationFix,
  defer,
  flagOff,
  rollback,
}

enum TriageStatus { pass, fail, blocked }

class TriageCase {
  const TriageCase({
    required this.issueId,
    required this.severity,
    required this.decision,
    required this.rationale,
    required this.evidence,
  });

  final String issueId;
  final String severity;
  final TriageDecision decision;
  final String rationale;
  final List<String> evidence;
}

class TriageReport {
  const TriageReport({
    required this.status,
    required this.caseCount,
    required this.limitations,
  });

  final TriageStatus status;
  final int caseCount;
  final List<String> limitations;
}

class SeverityPatchTriage {
  final List<TriageCase> _cases = <TriageCase>[];

  void add(TriageCase triageCase) => _cases.add(triageCase);

  static List<String> missingFields(TriageCase triageCase) {
    final missing = <String>[];
    if (triageCase.issueId.trim().isEmpty) missing.add('issue_id');
    if (triageCase.severity.trim().isEmpty) missing.add('severity');
    if (triageCase.rationale.trim().isEmpty) missing.add('rationale');
    if (triageCase.evidence.isEmpty) missing.add('evidence');
    return missing;
  }

  TriageReport evaluate() {
    if (_cases.isEmpty) {
      return const TriageReport(
        status: TriageStatus.blocked,
        caseCount: 0,
        limitations: <String>[
          'No triage case is available; no severity or patch decision is claimed.',
        ],
      );
    }

    final limitations = <String>[];
    for (final triageCase in _cases) {
      for (final field in missingFields(triageCase)) {
        limitations.add(
          '${triageCase.issueId.isEmpty ? '<unknown>' : triageCase.issueId} missing $field',
        );
      }
    }
    return TriageReport(
      status: limitations.isEmpty ? TriageStatus.pass : TriageStatus.fail,
      caseCount: _cases.length,
      limitations: List<String>.unmodifiable(limitations),
    );
  }
}
