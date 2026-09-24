/// Dependency-free emergency response contract for Sprint 114.28.
enum CriticalResponseStatus { pass, fail, blocked }

class CriticalResponseCase {
  const CriticalResponseCase({
    required this.incidentId,
    required this.containment,
    required this.userProtection,
    required this.rootCause,
    required this.fix,
    required this.tests,
    required this.advisory,
    required this.rollbackOrPatch,
  });

  final String incidentId;
  final String containment;
  final String userProtection;
  final String rootCause;
  final String fix;
  final List<String> tests;
  final String advisory;
  final String rollbackOrPatch;
}

class CriticalResponseReport {
  const CriticalResponseReport({
    required this.status,
    required this.caseCount,
    required this.limitations,
  });

  final CriticalResponseStatus status;
  final int caseCount;
  final List<String> limitations;
}

class CriticalSecurityResponseRegister {
  final List<CriticalResponseCase> _cases = <CriticalResponseCase>[];

  void add(CriticalResponseCase response) => _cases.add(response);

  static List<String> missingFields(CriticalResponseCase response) {
    final missing = <String>[];
    if (response.incidentId.trim().isEmpty) missing.add('incident_id');
    if (response.containment.trim().isEmpty) missing.add('containment');
    if (response.userProtection.trim().isEmpty) missing.add('user_protection');
    if (response.rootCause.trim().isEmpty) missing.add('root_cause');
    if (response.fix.trim().isEmpty) missing.add('fix');
    if (response.tests.isEmpty) missing.add('tests');
    if (response.advisory.trim().isEmpty) missing.add('advisory');
    if (response.rollbackOrPatch.trim().isEmpty) {
      missing.add('rollback_or_patch');
    }
    return missing;
  }

  CriticalResponseReport evaluate() {
    if (_cases.isEmpty) {
      return const CriticalResponseReport(
        status: CriticalResponseStatus.blocked,
        caseCount: 0,
        limitations: <String>[
          'No critical response case is available; no incident is claimed.',
        ],
      );
    }

    final limitations = <String>[];
    for (final response in _cases) {
      for (final field in missingFields(response)) {
        limitations.add(
          '${response.incidentId.trim().isEmpty ? '<unknown>' : response.incidentId} missing $field',
        );
      }
    }
    return CriticalResponseReport(
      status: limitations.isEmpty
          ? CriticalResponseStatus.pass
          : CriticalResponseStatus.fail,
      caseCount: _cases.length,
      limitations: List<String>.unmodifiable(limitations),
    );
  }
}
