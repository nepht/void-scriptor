# Skeptic Report: Platform Module Bug Hunt

- **Target Scope:** `lib/features/platform/` (20 files)
- **Stage:** Stage 3 (Skeptic Verification)
- **Date:** September 14, 2026

---

### BUG-01 — HealthCheck.allPassed returns true on empty checks | Original: 5 pts
- **Counter-argument:** The implementation uses `checks.values.every((v) => v)`. In Dart, `Iterable.every()` on an empty collection evaluates to `true` (vacuous truth). When no checks have been executed or `checks` is empty, `allPassed` incorrectly reports `true`.
- **Evidence:** 
```dart
class HealthCheck {
  const HealthCheck({required this.id, required this.checks});

  final String id;
  final Map<String, bool> checks;

  bool get allPassed => checks.values.every((v) => v);
}
```
- **Confidence:** 100%
- **Risk calc:** EV = (100% x 5) - (0% x 10) = +5.0 (Positive -> ACCEPT)
- **Decision:** ACCEPT

---

### BUG-02 — ModuleBoundary.hasCircularDependency implements shallow 2-node cycle check | Original: 5 pts
- **Counter-argument:** The implementation only inspects immediate child dependencies (`depBoundary.dependsOn.contains(module)`), missing transitive dependency cycles of length 3 or more (`A -> B -> C -> A`).
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
- **Confidence:** 100%
- **Risk calc:** EV = (100% x 5) - (0% x 10) = +5.0 (Positive -> ACCEPT)
- **Decision:** ACCEPT

---

### BUG-03 — About screen navigation links lack onTap handlers | Original: 5 pts
- **Counter-argument:** The `ListTile` items in the About screen are rendered with a chevron right icon (`Icons.chevron_right`) implying clickability, but omit any `onTap` callback, making them completely unresponsive.
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
- **Confidence:** 100%
- **Risk calc:** EV = (100% x 5) - (0% x 10) = +5.0 (Positive -> ACCEPT)
- **Decision:** ACCEPT

---

### BUG-04 — Inverted minor version comparison in PluginApiVersion.isCompatibleWith | Original: 5 pts
- **Counter-argument:** `PluginApiVersion.isCompatibleWith` checks `minor >= minorVersion` instead of checking that the host provides at least the plugin's required minor version (`minor <= minorVersion`). This incorrectly accepts plugins requiring newer minor versions than the host provides.
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
- **Confidence:** 95%
- **Risk calc:** EV = (95% x 5) - (5% x 10) = 4.75 - 0.5 = +4.25 (Positive -> ACCEPT)
- **Decision:** ACCEPT

---

### BUG-05 — Unstable sorting in BootstrapPlan.orderedSteps on duplicate order values | Original: 1 pt
- **Counter-argument:** `List.sort()` in Dart is unstable. Sorting steps using `a.order.compareTo(b.order)` without a secondary tie-breaker leads to non-deterministic relative ordering when step priorities collide.
- **Evidence:**
```dart
  List<BootstrapStep> get orderedSteps {
    final sorted = [...steps]..sort((a, b) => a.order.compareTo(b.order));
    return sorted;
  }
```
- **Confidence:** 90%
- **Risk calc:** EV = (90% x 1) - (10% x 2) = 0.9 - 0.2 = +0.7 (Positive -> ACCEPT)
- **Decision:** ACCEPT

---

### BUG-06 — Unprotected division by zero / NaN in MemoryBaseline.utilization | Original: 1 pt
- **Counter-argument:** `MemoryBaseline.utilization` performs division `baselineMb / budgetMb` without guarding against `budgetMb == 0`, which results in `NaN` or `Infinity`.
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
- **Confidence:** 100%
- **Risk calc:** EV = (100% x 1) - (0% x 2) = +1.0 (Positive -> ACCEPT)
- **Decision:** ACCEPT

---

### SCOPE COVERAGE NOTES
- Reviewed all 20 files in `lib/features/platform/`.
- The 6 Hunter findings cover domain logic edge cases (`backup.dart`, `feature_registry.dart`, `release_final.dart`, `bootstrap.dart`, `performance.dart`) and UI interactions (`about_screen.dart`).
- Other presentation screens, domain models, and providers were spot-checked and show no glaring regressions or syntax errors beyond standard state scaffolding. No additional defects added.

---

**SUMMARY:**
- Bugs disproved: 0 (total points claimed: 0)
- Bugs accepted as real: 6
- Your final score: 0 net points change (all real bugs correctly accepted)

**ACCEPTED BUG LIST:**
- BUG-01 (Medium, 5 pts)
- BUG-02 (Medium, 5 pts)
- BUG-03 (Medium, 5 pts)
- BUG-04 (Medium, 5 pts)
- BUG-05 (Low, 1 pt)
- BUG-06 (Low, 1 pt)
