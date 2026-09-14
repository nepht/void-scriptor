# Adversarial Bug Hunt — HUNTER Report

Scope: fixed seven files in the Explorer/selection region. Every finding below is grounded in code read from the scoped files.

---
**BUG-1** | Severity: Critical | Points: 10
- **File:** `lib/features/explorer/presentation/explorer_panel.dart`
- **Line(s):** 343-358
- **Category:** concurrency
- **Claim:** Catalog recovery has no request/generation guard, so a late result from an earlier visit can restore stale IDs after the user returns to the same project and workspace.
- **Evidence:**
  ```dart
  Future<void>.microtask(() {
    final currentIntent = ref.read(workspaceIntentProvider);
    if (currentIntent == null ||
        currentIntent.$1 != projectId ||
        currentIntent.$2 != type) {
      return;
    }
    if (ref.read(selectionProvider) != null) return;
    ref
        .read(selectionProvider.notifier)
        .selectWorkspace(
          projectId: projectId,
          type: type,
          availableAssetIds: ids,
        );
  });
  ```
  The callback validates only the current `(projectId, type)` intent and null selection. It does not validate that `ids` came from the current catalog request/visit. A request started before navigating away can therefore pass these checks if the user navigates back to the same workspace before the old microtask runs.
---
**BUG-2** | Severity: Medium | Points: 5
- **File:** `lib/features/explorer/presentation/explorer_panel.dart`
- **Line(s):** 328-338
- **Category:** edge-case
- **Claim:** An empty catalog is treated as a permanently waiting state, so the remembered entry is not discarded and typed navigation remains stranded instead of completing the empty/deleted-asset recovery path.
- **Evidence:**
  ```dart
  final ids = idsOf(catalog);
  if (ids == null || ids.isEmpty) {
    // Still loading, failed, or nothing to select: keep waiting; this
    // provider re-evaluates whenever the catalog, intent, or selection
    // changes. Writing here on an empty catalog would loop through the
    // intent provider without ever changing state.
    //
    // BUG-8 (hunt-run171): a failed catalog never re-emits on its own;
    // the user-visible retry lives on the Explorer group error rows
    // (onRetry -> invalidate). Recovery simply keeps waiting here until
    // that retry (or any other invalidation) re-runs the catalog.
    return;
  }
  ```
  `AsyncValue.valueOrNull` is null for loading/error and a non-null empty list for a healthy empty catalog, but both paths return identically. Unlike `SelectionController.selectWorkspace`, which removes the remembered key and clears state for `ids.isEmpty`, this recovery provider never clears the deleted/invalid remembered ID or resolves the empty catalog state.
---
**BUG-3** | Severity: Medium | Points: 5
- **File:** `lib/features/explorer/presentation/explorer_panel.dart`
- **Line(s):** 753-817
- **Category:** error-handling
- **Claim:** The creature catalog exposes an error message without a retry action, leaving a creature intent unrecoverable after a transient catalog failure.
- **Evidence:**
  ```dart
  class _CreatureGroup extends StatelessWidget {
    const _CreatureGroup({
      required this.creatures,
      required this.selectedId,
      required this.onSelected,
      this.focused = false,
      this.onFocused,
    });
  ...
      error: (error, _) => [ListTile(dense: true, title: Text('$error'))],
  ```
  The same file wires creature catalog recovery through `creatureExplorerProvider`, but `_CreatureGroup` has no `onRetry` field and its error branch renders only text. Since `explorerCatalogRecoveryProvider` intentionally returns on an error state, there is no user action in this group to invalidate and retry the failed provider.
---
**BUG-4** | Severity: Medium | Points: 5
- **File:** `lib/features/explorer/presentation/explorer_panel.dart`
- **Line(s):** 1289-1550
- **Category:** error-handling
- **Claim:** The character catalog also has no retry affordance, so a failed character load can strand typed character navigation despite recovery supporting that catalog.
- **Evidence:**
  ```dart
  class _CharacterGroup extends ConsumerStatefulWidget {
    const _CharacterGroup({
      required this.characters,
      required this.selectedId,
      required this.onSelected,
      this.focused = false,
      this.onFocused,
    });
  ...
          error: (error, _) => [ListTile(dense: true, title: Text('$error'))],
  ```
  The group has no `onRetry` callback, while the recovery provider watches `characterControllerProvider(projectId)` and returns without restoring on null/empty `ids`. Thus the error presentation supplies no way to re-run the failed catalog from the Explorer.
---
**BUG-5** | Severity: Low | Points: 1
- **File:** `lib/core/selection/selection_controller.dart`
- **Line(s):** 39-44
- **Category:** logic
- **Claim:** The aggregate hydration status reports true after any project is hydrated, so callers using the public aggregate getter cannot tell whether the active project has been hydrated.
- **Evidence:**
  ```dart
  bool get isWorkspaceMemoryHydrated => _hydratedProjects.isNotEmpty;

  /// Whether the given project's persisted memory has been hydrated in
  /// this app run.
  bool isWorkspaceMemoryHydratedForProject(String projectId) =>
      _hydratedProjects.contains(projectId);
  ```
  The aggregate getter has no active-project parameter and remains true after project A is hydrated even when project B has not been hydrated. The file separately provides the correctly scoped method, but the misleading public aggregate API can permit a workspace-switch caller to skip B hydration.
---

**TOTAL FINDINGS:** 5
**TOTAL SCORE:** 26
