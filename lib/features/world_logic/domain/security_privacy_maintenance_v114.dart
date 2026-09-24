/// Dependency-free contract for Sprint 114.32 security/privacy maintenance.
enum SecurityPrivacyMaintenanceState { pass, fail, blocked }

class SecurityPrivacyMaintenancePlan {
  const SecurityPrivacyMaintenancePlan({
    required this.maintenanceId,
    required this.fixes,
    required this.securityTests,
    required this.privacyTests,
    required this.threatUpdate,
    required this.dataFlowUpdate,
    required this.dependencyUpdate,
    required this.advisory,
  });

  final String maintenanceId;
  final List<String> fixes;
  final List<String> securityTests;
  final List<String> privacyTests;
  final String threatUpdate;
  final String dataFlowUpdate;
  final String dependencyUpdate;
  final String advisory;

  static List<String> requiredFields(SecurityPrivacyMaintenancePlan plan) {
    final missing = <String>[];
    if (plan.maintenanceId.trim().isEmpty) missing.add('maintenance_id');
    if (plan.fixes.isEmpty) missing.add('fixes');
    if (plan.securityTests.isEmpty) missing.add('security_tests');
    if (plan.privacyTests.isEmpty) missing.add('privacy_tests');
    if (plan.threatUpdate.trim().isEmpty) missing.add('threat_update');
    if (plan.dataFlowUpdate.trim().isEmpty) {
      missing.add('data_flow_update');
    }
    if (plan.dependencyUpdate.trim().isEmpty) {
      missing.add('dependency_update');
    }
    if (plan.advisory.trim().isEmpty) missing.add('advisory');
    return missing;
  }
}

class SecurityPrivacyMaintenanceReport {
  const SecurityPrivacyMaintenanceReport({
    required this.state,
    required this.maintenanceCount,
    required this.limitations,
  });

  final SecurityPrivacyMaintenanceState state;
  final int maintenanceCount;
  final List<String> limitations;
}

class SecurityPrivacyMaintenanceRegister {
  final List<SecurityPrivacyMaintenancePlan> _plans =
      <SecurityPrivacyMaintenancePlan>[];

  void add(SecurityPrivacyMaintenancePlan plan) => _plans.add(plan);

  SecurityPrivacyMaintenanceReport evaluate() {
    if (_plans.isEmpty) {
      return const SecurityPrivacyMaintenanceReport(
        state: SecurityPrivacyMaintenanceState.blocked,
        maintenanceCount: 0,
        limitations: <String>[
          'No security/privacy maintenance plan is available; no maintenance is claimed.',
        ],
      );
    }

    final limitations = <String>[];
    for (final plan in _plans) {
      for (final field in SecurityPrivacyMaintenancePlan.requiredFields(plan)) {
        limitations.add(
          '${plan.maintenanceId.trim().isEmpty ? '<unknown>' : plan.maintenanceId} missing $field',
        );
      }
    }
    return SecurityPrivacyMaintenanceReport(
      state: limitations.isEmpty
          ? SecurityPrivacyMaintenanceState.pass
          : SecurityPrivacyMaintenanceState.fail,
      maintenanceCount: _plans.length,
      limitations: List<String>.unmodifiable(limitations),
    );
  }
}
