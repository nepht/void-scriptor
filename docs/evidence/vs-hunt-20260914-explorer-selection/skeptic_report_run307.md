# Adversarial Bug Hunt — SKEPTIC Report

Scope: independent review of the five findings in `hunter_report_run307.md`. I read each reported production location with surrounding context, the complete relevant recovery/group sections, `SelectionController.selectWorkspace`, the requested Explorer tests, and all production references to `isWorkspaceMemoryHydrated`.

---
**BUG-1** | Original: 10 pts
- **Counter-argument:** The race is real. `explorerCatalogRecoveryProvider` watches the typed intent, current selection, current session, and a catalog provider. Once the catalog has a non-empty value, it captures `ids` in the provider evaluation and schedules a microtask. The microtask rechecks only the current `(projectId, type)` and null selection. A same-project/same-type navigate-away-then-back changes the intent back to the same tuple but does not identify the visit or catalog generation, so a result captured from the earlier visit can restore the old IDs. Dart's single isolate prevents simultaneous mutation, but it does not prevent an async Future from completing later or a queued microtask from running after intervening navigation; the missing generation/visit guard is therefore still consequential. The stale restore can select the old remembered ID (or the old catalog's first ID) for the newly requested visit, and `selectWorkspace` also updates the intent, making the stale action sticky until another navigation/selection.
- **Evidence:** Independent read of `explorer_panel.dart` shows the provider obtains the catalog through `ref.watch(...)` for each supported type (lines 312-323), returns early only for null/empty IDs (327-338), then captures and uses `ids` in a later microtask (343-357). The only guards are:
  ```dart
  final currentIntent = ref.read(workspaceIntentProvider);
  if (currentIntent == null ||
      currentIntent.$1 != projectId ||
      currentIntent.$2 != type) {
    return;
  }
  if (ref.read(selectionProvider) != null) return;
  ...availableAssetIds: ids,
  ```
  There is no request, Future identity, or visit/generation token. `focusWorkspace` only writes `(projectId, type)` and clears incompatible selection:
  ```dart
  ref.read(workspaceIntentProvider.notifier).state = (projectId, type);
  if (state?.projectId != projectId || state?.assetType != type) clear();
  ```
  Thus returning to the same tuple is indistinguishable from the old visit. The recovery tests independently confirm only the weaker protections: a user pick wins (`explorer_catalog_recovery_unit_test.dart`, lines 89-108), while the requested same-tuple stale-visit case is not covered.
- **Confidence:** 88%
- **Risk calc:** EV = (88% x 10) - (12% x 2 x 10) = 6.4
- **Decision:** ACCEPT
---
**BUG-2** | Original: 5 pts
- **Counter-argument:** Confirmed. The recovery provider deliberately conflates loading/error with a healthy empty catalog and returns for both. For a healthy empty catalog, no provider change necessarily follows, so the remembered key is never removed and `selectionProvider` is never cleared by this recovery path. `SelectionController.selectWorkspace` has the correct empty handling, but the recovery provider does not call it in this branch. `focusExplorerAsset` can handle an already-available catalog synchronously, but that does not repair the async typed-navigation case where the catalog transitions from loading/error to empty after the focus action. The comment's claim that the provider will keep waiting is not sufficient: a failed Future also does not re-emit without invalidation, and an empty successful Future has no later catalog event at all.
- **Evidence:** Independent read of `explorer_panel.dart` lines 327-338:
  ```dart
  final ids = idsOf(catalog);
  if (ids == null || ids.isEmpty) {
    // Still loading, failed, or nothing to select: keep waiting;
    return;
  }
  ```
  Independent read of `selection_controller.dart` lines 77-92 shows the omitted behavior:
  ```dart
  final id = ids.contains(remembered) ? remembered : ids.firstOrNull;
  if (id == null) {
    _workspaceSelections.remove(key);
    clear();
    return;
  }
  ```
  The recovery provider never reaches this call for `ids.isEmpty`. The Explorer retry test itself describes recovery as waiting for retry after failure (`explorer_catalog_error_retry_test.dart`, lines 15-26), which supports the distinction: retry can recover an error, but it cannot make a successful empty result re-emit. The unit test covers non-empty restoration only (`explorer_catalog_recovery_unit_test.dart`, lines 54-86).
- **Confidence:** 95%
- **Risk calc:** EV = (95% x 5) - (5% x 2 x 5) = 4.25
- **Decision:** ACCEPT
---
**BUG-3** | Original: 5 pts
- **Counter-argument:** Confirmed. The creature catalog is an active recovery-supported typed destination, but `_CreatureGroup` exposes only loading, error text, and data states. Its error row has no action, and the parent invocation supplies no retry callback. Since `explorerCatalogRecoveryProvider` returns on error (`valueOrNull` is null), no selection restoration occurs until some unrelated invalidation. Creature creation invalidates the provider, but that is not a reliable recovery affordance for a transient read failure and is unavailable when the user merely needs to retry.
- **Evidence:** Independent read of `explorer_panel.dart` lines 602-619 shows `_CreatureGroup` is rendered with `creatures`, focus, selection, and `onSelected`, but no `onRetry`. Lines 753-817 define no retry field:
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
  In contrast, independently read `explorer_story_group.dart` lines 7-25 and 44-61 has `final VoidCallback? onRetry` and an IconButton with tooltip `Coba lagi`; `explorer_environment_group.dart` lines 7-24 and 41-57 has the same. The failure branch is reachable because `creatureExplorerProvider` directly awaits `CreatureRepository(...).listForProject(projectId)` (panel lines 83-88), which can return an AsyncValue error.
- **Confidence:** 99%
- **Risk calc:** EV = (99% x 5) - (1% x 2 x 5) = 4.85
- **Decision:** ACCEPT
---
**BUG-4** | Original: 5 pts
- **Counter-argument:** Confirmed. Character rendering has a separate narrative-assignment error warning, but that is not the character catalog error and has no bearing on retrying `widget.characters`. The character group receives no `onRetry`, and its catalog error branch is only a text ListTile. The recovery provider watches `characterControllerProvider(projectId)` and returns when IDs are null, so a failed character catalog strands the typed intent absent an unrelated invalidation or a new user action that invokes another path.
- **Evidence:** Independent read of `explorer_panel.dart` lines 584-601 shows `_CharacterGroup` is constructed without `onRetry`. Lines 1289-1301 show its constructor has only `characters`, `selectedId`, `onSelected`, `focused`, and `onFocused`. Lines 1505-1524 separately render assignment failure and then the catalog state; the catalog branch is:
  ```dart
  error: (error, _) => [ListTile(dense: true, title: Text('$error'))],
  ```
  The recovery code at lines 314-315 watches `characterControllerProvider(projectId)`, and lines 327-338 return for null IDs, including the error case. Story/environment groups independently provide retry fields and error-row buttons, establishing a real inconsistency rather than an intentional common error design.
- **Confidence:** 98%
- **Risk calc:** EV = (98% x 5) - (2% x 2 x 5) = 4.8
- **Decision:** ACCEPT
---
**BUG-5** | Original: 1 pt
- **Counter-argument:** Disproved as an active production bug. The aggregate getter is semantically broad and could mislead a future caller, but the hunter's claim is about callers using it to skip hydration for the active project. A complete production search shows no `lib/` caller of `isWorkspaceMemoryHydrated`; the only uses are tests. The actual persistence provider hydrates with `hydrateWorkspaceMemory(..., projectId: projectId)` and the production contract exposes/uses the project-scoped method where needed. Therefore there is no current workspace-switch path that can skip project B hydration because of this getter. This is at most a latent API footgun, not a present explorer/selection defect.
- **Evidence:** Independent read of `selection_controller.dart` lines 39-44 confirms the getter and correctly scoped method:
  ```dart
  bool get isWorkspaceMemoryHydrated => _hydratedProjects.isNotEmpty;
  bool isWorkspaceMemoryHydratedForProject(String projectId) =>
      _hydratedProjects.contains(projectId);
  ```
  A repository production search for `isWorkspaceMemoryHydrated` returned only `lib/core/selection/selection_controller.dart`; all other matches were in `test/features/explorer/selection_memory_per_project_test.dart` and `test/features/explorer/selection_memory_restart_persistence_test.dart`. The production persistence wiring independently reads the active session ID and calls:
  ```dart
  .hydrateWorkspaceMemory(..., projectId: projectId);
  ```
  at `explorer_panel.dart` lines 256-271. The tests' aggregate assertions (restart test lines 240-244; hydration test lines 125-149) are not production callers.
- **Confidence:** 99%
- **Risk calc:** EV = (99% x 1) - (1% x 2 x 1) = 0.97
- **Decision:** DISPROVE
---

**SUMMARY:**
- Bugs disproved: 1 (total points claimed: 1)
- Bugs accepted as real: 4
- Your final score: 19 points accepted minus 1 point disproved = 18 net points

**ACCEPTED BUG LIST:**
- BUG-1 — Critical
- BUG-2 — Medium
- BUG-3 — Medium
- BUG-4 — Medium

**TOTAL CONFIRMED:** 4
**TOTAL DISPROVED:** 1
