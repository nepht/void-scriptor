/// Dependency-free contract for Sprint 114.29 P1 stability fixes.
enum P1StabilityStatus { pass, fail, blocked }

class P1StabilityFix {
  const P1StabilityFix({
    required this.issueId,
    required this.reproduction,
    required this.minimalChange,
    required this.regressionTest,
    required this.review,
    required this.riskUpdate,
    required this.releaseNote,
  });

  final String issueId;
  final String reproduction;
  final String minimalChange;
  final String regressionTest;
  final String review;
  final String riskUpdate;
  final String releaseNote;

  static List<String> requiredFields(P1StabilityFix fix) {
    final missing = <String>[];
    if (fix.issueId.trim().isEmpty) missing.add('issue_id');
    if (fix.reproduction.trim().isEmpty) missing.add('reproduction');
    if (fix.minimalChange.trim().isEmpty) missing.add('minimal_change');
    if (fix.regressionTest.trim().isEmpty) missing.add('regression_test');
    if (fix.review.trim().isEmpty) missing.add('review');
    if (fix.riskUpdate.trim().isEmpty) missing.add('risk_update');
    if (fix.releaseNote.trim().isEmpty) missing.add('release_note');
    return missing;
  }
}

class P1StabilityReport {
  const P1StabilityReport({
    required this.status,
    required this.fixCount,
    required this.limitations,
  });

  final P1StabilityStatus status;
  final int fixCount;
  final List<String> limitations;
}

class P1StabilityFixRegister {
  final List<P1StabilityFix> _fixes = <P1StabilityFix>[];

  void add(P1StabilityFix fix) => _fixes.add(fix);

  P1StabilityReport evaluate() {
    if (_fixes.isEmpty) {
      return const P1StabilityReport(
        status: P1StabilityStatus.blocked,
        fixCount: 0,
        limitations: <String>[
          'No P1 stability fix is available; no regression is claimed.',
        ],
      );
    }

    final limitations = <String>[];
    for (final fix in _fixes) {
      for (final field in P1StabilityFix.requiredFields(fix)) {
        limitations.add(
          '${fix.issueId.trim().isEmpty ? '<unknown>' : fix.issueId} missing $field',
        );
      }
    }
    return P1StabilityReport(
      status: limitations.isEmpty
          ? P1StabilityStatus.pass
          : P1StabilityStatus.fail,
      fixCount: _fixes.length,
      limitations: List<String>.unmodifiable(limitations),
    );
  }
}
