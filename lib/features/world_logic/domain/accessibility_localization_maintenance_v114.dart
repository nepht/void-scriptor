/// Dependency-free contract for Sprint 114.33 accessibility/localization
/// maintenance.
enum MaintenanceState { pass, fail, blocked }

class AccessibilityLocalizationMaintenancePlan {
  const AccessibilityLocalizationMaintenancePlan({
    required this.maintenanceId,
    required this.fixes,
    required this.keyboardTests,
    required this.screenReaderTests,
    required this.scalingTests,
    required this.localeTests,
    required this.multiscriptTests,
  });

  final String maintenanceId;
  final List<String> fixes;
  final List<String> keyboardTests;
  final List<String> screenReaderTests;
  final List<String> scalingTests;
  final List<String> localeTests;
  final List<String> multiscriptTests;

  static List<String> requiredFields(
    AccessibilityLocalizationMaintenancePlan plan,
  ) {
    final missing = <String>[];
    if (plan.maintenanceId.trim().isEmpty) missing.add('maintenance_id');
    if (plan.fixes.isEmpty || plan.fixes.any((value) => value.trim().isEmpty)) {
      missing.add('fixes');
    }
    if (plan.keyboardTests.isEmpty ||
        plan.keyboardTests.any((value) => value.trim().isEmpty)) {
      missing.add('keyboard_tests');
    }
    if (plan.screenReaderTests.isEmpty ||
        plan.screenReaderTests.any((value) => value.trim().isEmpty)) {
      missing.add('screen_reader_tests');
    }
    if (plan.scalingTests.isEmpty ||
        plan.scalingTests.any((value) => value.trim().isEmpty)) {
      missing.add('scaling_tests');
    }
    if (plan.localeTests.isEmpty ||
        plan.localeTests.any((value) => value.trim().isEmpty)) {
      missing.add('locale_tests');
    }
    if (plan.multiscriptTests.isEmpty ||
        plan.multiscriptTests.any((value) => value.trim().isEmpty)) {
      missing.add('multiscript_tests');
    }
    return missing;
  }
}

class AccessibilityLocalizationMaintenanceReport {
  const AccessibilityLocalizationMaintenanceReport({
    required this.state,
    required this.planCount,
    required this.limitations,
  });

  final MaintenanceState state;
  final int planCount;
  final List<String> limitations;
}

class AccessibilityLocalizationMaintenanceRegister {
  final List<AccessibilityLocalizationMaintenancePlan> _plans =
      <AccessibilityLocalizationMaintenancePlan>[];

  void add(AccessibilityLocalizationMaintenancePlan plan) => _plans.add(plan);

  AccessibilityLocalizationMaintenanceReport evaluate() {
    if (_plans.isEmpty) {
      return const AccessibilityLocalizationMaintenanceReport(
        state: MaintenanceState.blocked,
        planCount: 0,
        limitations: <String>[
          'No accessibility/localization maintenance plan is available; '
              'no maintenance is claimed.',
        ],
      );
    }

    final limitations = <String>[];
    for (final plan in _plans) {
      final planId = plan.maintenanceId.trim().isEmpty
          ? '<unknown>'
          : plan.maintenanceId;
      for (final field
          in AccessibilityLocalizationMaintenancePlan.requiredFields(plan)) {
        limitations.add('$planId missing $field');
      }
    }
    return AccessibilityLocalizationMaintenanceReport(
      state: limitations.isEmpty
          ? MaintenanceState.pass
          : MaintenanceState.fail,
      planCount: _plans.length,
      limitations: List<String>.unmodifiable(limitations),
    );
  }
}
