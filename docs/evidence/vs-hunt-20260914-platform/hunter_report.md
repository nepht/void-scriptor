# Adversarial Bug Hunt Report: Platform Module

- **Target Scope:** `lib/features/platform/` (20 files)
- **Stage:** Stage 1 (Hunter)
- **Date:** September 14, 2026

---

### BUG-01 — HealthCheck.allPassed returns true on empty checks
- **File:** `lib/features/platform/domain/backup.dart`
- **Line(s):** 32
- **Category:** edge-case
- **Claim:** `HealthCheck.allPassed` returns `true` when the `checks` map is empty, falsely reporting a healthy system when no checks have been executed.
- **Evidence:**
```dart
class HealthCheck {
  const HealthCheck({required this.id, required this.checks});

  final String id;
  final Map<String, bool> checks;

  bool get allPassed => checks.values.every((v) => v);
}
```
- **Mechanism:** In Dart, `Iterable.every()` returns `true` for empty collections due to vacuous truth. If a `HealthCheck` instance is initialized with an empty `checks` map (e.g., before execution or during error states), `allPassed` evaluates to `true`.
- **Impact:** Automated diagnostic and repair systems may skip necessary remediation steps, falsely assuming system health when health data is unpopulated.
- **Severity:** Medium
- **Confidence:** 1.0
- **Points:** 5

---

### BUG-02 — ModuleBoundary.hasCircularDependency implements shallow 2-node cycle check
- **File:** `lib/features/platform/domain/feature_registry.dart`
- **Line(s):** 37–45
- **Category:** logic
- **Claim:** `ModuleBoundary.hasCircularDependency` only detects direct two-node circular dependencies (`A -> B -> A`) and fails to detect multi-node circular dependencies of length greater than two (`A -> B -> C -> A`).
- **Evidence:**
```dart
  bool hasCircularDependency(Map<String, ModuleBoundary> all) {
    for (final dep in dependsOn) {
      final depBoundary = all[dep];
      if (depBoundary != null && depBoundary.dependsOn.contains(module)) {
        return true;
      }
    }
    return false;
  }
```
- **Mechanism:** The implementation only inspects immediate child dependencies for a back-edge to the starting module (`depBoundary.dependsOn.contains(module)`), missing transitive dependency cycles across 3 or more modules.
- **Impact:** Architectural dependency audits fail to catch complex circular coupling between modules, risking initialization deadlocks or hard-to-debug circular references.
- **Severity:** Medium
- **Confidence:** 1.0
- **Points:** 5

---

### BUG-03 — About screen navigation links lack onTap handlers
- **File:** `lib/features/platform/presentation/about_screen.dart`
- **Line(s):** 68–77
- **Category:** logic
- **Claim:** The navigation action items in the About screen (`Licenses`, `Privacy`, `Open Source Notices`, `Check for Updates`) are rendered without any `onTap` handler, rendering the UI controls unresponsive.
- **Evidence:**
```dart
              for (final (label, icon) in _links)
                Card(
                  color: context.palette.surface,
                  margin: const EdgeInsets.only(bottom: VoidSpacing.sm),
                  child: ListTile(
                    leading: Icon(icon, color: context.palette.primary),
                    title: Text(label),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                ),
```
- **Mechanism:** The `ListTile` widget inside each `Card` omits the `onTap` callback. Although a chevron icon (`Icons.chevron_right`) is displayed to signal navigation, clicking the item executes no action.
- **Impact:** Users are unable to access legal notices, privacy details, or trigger update checks from the About screen.
- **Severity:** Medium
- **Confidence:** 1.0
- **Points:** 5

---

### BUG-04 — Inverted minor version comparison in PluginApiVersion.isCompatibleWith
- **File:** `lib/features/platform/domain/release_final.dart`
- **Line(s):** 60–61
- **Category:** logic
- **Claim:** `PluginApiVersion.isCompatibleWith` incorrectly requires host minor version to be greater than or equal to plugin minor version (`minor >= minorVersion`), which represents the reverse of correct API version compatibility logic.
- **Evidence:**
```dart
class PluginApiVersion {
  const PluginApiVersion({required this.major, required this.minor});

  final int major;
  final int minor;

  bool isCompatibleWith(int majorVersion, int minorVersion) =>
      major == majorVersion && minor >= minorVersion;
}
```
- **Mechanism:** Assuming `PluginApiVersion` represents the plugin's required API version and parameters represent the host version, checking `minor >= minorVersion` enforces that the plugin version requires a higher minor version than the host provides (`plugin.minor >= host.minor`). If host is 1.1 and plugin requires 1.2, this condition evaluates to true (`2 >= 1`), incorrectly accepting an incompatible plugin.
- **Impact:** Older host environments can load plugins requiring newer API features, causing runtime crashes or missing symbol exceptions.
- **Severity:** Medium
- **Confidence:** 0.9
- **Points:** 5

---

### BUG-05 — Unstable sorting in BootstrapPlan.orderedSteps on duplicate order values
- **File:** `lib/features/platform/domain/bootstrap.dart`
- **Line(s):** 26–29
- **Category:** edge-case
- **Claim:** `BootstrapPlan.orderedSteps` sorts steps using `a.order.compareTo(b.order)` without a secondary tie-breaker, which is unstable when step order integers collide.
- **Evidence:**
```dart
  List<BootstrapStep> get orderedSteps {
    final sorted = [...steps]..sort((a, b) => a.order.compareTo(b.order));
    return sorted;
  }
```
- **Mechanism:** Dart's `List.sort()` is unstable. When multiple bootstrap steps share the same order priority, their relative execution ordering can vary unpredictably across runs.
- **Impact:** Intermittent startup race conditions or initialization failures when multiple startup steps share the same priority order.
- **Severity:** Low
- **Confidence:** 0.8
- **Points:** 1

---

### BUG-06 — Unprotected division by zero / NaN in MemoryBaseline.utilization
- **File:** `lib/features/platform/domain/performance.dart`
- **Line(s):** 22–23
- **Category:** edge-case
- **Claim:** `MemoryBaseline.utilization` computes `baselineMb / budgetMb` without guarding against `budgetMb` being zero, resulting in `NaN` or infinity values.
- **Evidence:**
```dart
class MemoryBaseline {
  const MemoryBaseline({required this.baselineMb, required this.budgetMb});

  final int baselineMb;
  final int budgetMb;

  double get utilization => baselineMb / budgetMb;
  bool get withinBudget => baselineMb <= budgetMb;
}
```
- **Mechanism:** If `budgetMb` is initialized to 0 (e.g., unconfigured or mock performance metrics), division yields `NaN` or `Infinity`, corrupting calculations or UI progress representations.
- **Impact:** Performance dashboards or monitoring logs display `NaN` or crash during layout when memory budget is unconfigured.
- **Severity:** Low
- **Confidence:** 0.9
- **Points:** 1

---

**TOTAL FINDINGS:** 6
**TOTAL SCORE:** 22
