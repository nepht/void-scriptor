/// Dependency-free maintenance contract for Sprint 114.34 support and
/// documentation updates.
enum SupportDocumentationMaintenanceState { pass, fail, blocked }

class SupportDocumentationMaintenancePlan {
  const SupportDocumentationMaintenancePlan({
    required this.maintenanceId,
    required this.recoveryGuide,
    required this.migrationNotes,
    required this.knownIssues,
    required this.troubleshooting,
    required this.uiGuidance,
    required this.supportMacros,
  });

  final String maintenanceId;
  final String recoveryGuide;
  final String migrationNotes;
  final String knownIssues;
  final String troubleshooting;
  final List<String> uiGuidance;
  final List<String> supportMacros;

  static List<String> requiredFields(SupportDocumentationMaintenancePlan plan) {
    final missing = <String>[];
    if (plan.maintenanceId.trim().isEmpty) missing.add('maintenance_id');
    if (plan.recoveryGuide.trim().isEmpty) missing.add('recovery_guide');
    if (plan.migrationNotes.trim().isEmpty) missing.add('migration_notes');
    if (plan.knownIssues.trim().isEmpty) missing.add('known_issues');
    if (plan.troubleshooting.trim().isEmpty) missing.add('troubleshooting');
    if (plan.uiGuidance.isEmpty ||
        plan.uiGuidance.any((value) => value.trim().isEmpty)) {
      missing.add('ui_guidance');
    }
    if (plan.supportMacros.isEmpty ||
        plan.supportMacros.any((value) => value.trim().isEmpty)) {
      missing.add('support_macros');
    }
    return missing;
  }
}

class SupportDocumentationMaintenanceReport {
  const SupportDocumentationMaintenanceReport({
    required this.state,
    required this.maintenanceCount,
    required this.limitations,
  });

  final SupportDocumentationMaintenanceState state;
  final int maintenanceCount;
  final List<String> limitations;
}

class SupportDocumentationMaintenanceRegister {
  final List<SupportDocumentationMaintenancePlan> _plans =
      <SupportDocumentationMaintenancePlan>[];

  void add(SupportDocumentationMaintenancePlan plan) => _plans.add(plan);

  String? macro(String key) {
    final normalizedKey = key.trim();
    if (normalizedKey.isEmpty) return null;
    for (final plan in _plans) {
      for (final macro in plan.supportMacros) {
        final separator = macro.indexOf(':');
        if (separator <= 0) continue;
        if (macro.substring(0, separator).trim() == normalizedKey) {
          return macro;
        }
      }
    }
    return null;
  }

  SupportDocumentationMaintenanceReport evaluate() {
    if (_plans.isEmpty) {
      return const SupportDocumentationMaintenanceReport(
        state: SupportDocumentationMaintenanceState.blocked,
        maintenanceCount: 0,
        limitations: <String>[
          'No support/documentation maintenance plan is available; '
              'no maintenance is claimed.',
        ],
      );
    }

    final limitations = <String>[];
    for (final plan in _plans) {
      final planId = plan.maintenanceId.trim().isEmpty
          ? '<unknown>'
          : plan.maintenanceId.trim();
      for (final field in SupportDocumentationMaintenancePlan.requiredFields(
        plan,
      )) {
        limitations.add('$planId missing $field');
      }
    }
    return SupportDocumentationMaintenanceReport(
      state: limitations.isEmpty
          ? SupportDocumentationMaintenanceState.pass
          : SupportDocumentationMaintenanceState.fail,
      maintenanceCount: _plans.length,
      limitations: List<String>.unmodifiable(limitations),
    );
  }
}
