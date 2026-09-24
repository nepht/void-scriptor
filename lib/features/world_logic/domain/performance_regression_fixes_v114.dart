/// Dependency-free contract for Sprint 114.30 performance regression fixes.
enum PerformanceRegressionStatus { pass, fail, blocked }

class PerformanceRegressionFix {
  const PerformanceRegressionFix({
    required this.issueId,
    required this.profile,
    required this.rootCause,
    required this.budget,
    required this.fix,
    required this.beforeAfter,
    required this.regressionTest,
  });

  final String issueId;
  final String profile;
  final String rootCause;
  final String budget;
  final String fix;
  final String beforeAfter;
  final String regressionTest;

  static List<String> requiredFields(PerformanceRegressionFix fix) {
    final missing = <String>[];
    if (fix.issueId.trim().isEmpty) missing.add('issue_id');
    if (fix.profile.trim().isEmpty) missing.add('profile');
    if (fix.rootCause.trim().isEmpty) missing.add('root_cause');
    if (fix.budget.trim().isEmpty) missing.add('budget');
    if (fix.fix.trim().isEmpty) missing.add('fix');
    if (fix.beforeAfter.trim().isEmpty) missing.add('before_after');
    if (fix.regressionTest.trim().isEmpty) missing.add('regression_test');
    return missing;
  }
}

class PerformanceRegressionReport {
  const PerformanceRegressionReport({
    required this.status,
    required this.fixCount,
    required this.limitations,
  });

  final PerformanceRegressionStatus status;
  final int fixCount;
  final List<String> limitations;
}

class PerformanceRegressionFixRegister {
  final List<PerformanceRegressionFix> _fixes = <PerformanceRegressionFix>[];

  void add(PerformanceRegressionFix fix) => _fixes.add(fix);

  PerformanceRegressionReport evaluate() {
    if (_fixes.isEmpty) {
      return const PerformanceRegressionReport(
        status: PerformanceRegressionStatus.blocked,
        fixCount: 0,
        limitations: <String>[
          'No performance regression fix is available; no improvement is claimed.',
        ],
      );
    }

    final limitations = <String>[];
    for (final fix in _fixes) {
      for (final field in PerformanceRegressionFix.requiredFields(fix)) {
        limitations.add(
          '${fix.issueId.trim().isEmpty ? '<unknown>' : fix.issueId} missing $field',
        );
      }
    }
    return PerformanceRegressionReport(
      status: limitations.isEmpty
          ? PerformanceRegressionStatus.pass
          : PerformanceRegressionStatus.fail,
      fixCount: _fixes.length,
      limitations: List<String>.unmodifiable(limitations),
    );
  }
}
