# Adversarial Bug Hunt — REFEREE Report

Scope: independent verification of the five Explorer/selection findings against the production code and the four supplied tests at HEAD `fea57bab3a4c8eed7ab7e28344c080cbe93db432`.

## BUG-1
- **Hunter's claim:** A catalog result captured on an earlier visit can restore stale IDs after navigating away and back to the same `(projectId, AssetType)` because the recovery microtask has no request/visit generation guard.
- **Skeptic's response:** ACCEPT. The microtask rechecks only the tuple and null selection, so a same-tuple visit is indistinguishable from the old one.
- **Your analysis:** The code does lack a generation token: at `explorer_panel.dart:343-357` the queued callback rechecks `workspaceIntentProvider` and `selectionProvider`, then passes the captured `ids`. However, the reported async race is not established by this code. The callback is a `Future<void>.microtask`; Dart drains queued microtasks before the next user-event turn, so ordinary user navigation away and back cannot occur between scheduling and execution. In addition, the catalog is obtained through Riverpod's watched provider (`:312-323`), and invalidated/recomputed async providers are responsible for ignoring obsolete completions rather than delivering an old completion as the current provider value. The supplied unit test proves only that a user selection wins (`explorer_catalog_recovery_unit_test.dart:89-108`); it does not demonstrate an older Future completing after a newer one. A contrived same-stack sequence could change the intent twice before the microtask drains, but that is not the claimed late-Future runtime path and is not evidence of a production race. The missing token is a defensive improvement, not proof of a Critical defect.
- **VERDICT: NOT A BUG**
- **Confidence:** Medium
- **True severity:** N/A
- **Suggested fix:** No mandatory fix for this finding. If stronger defense is desired, stamp a visit/generation when focus changes and require the stamp in the microtask; add a deterministic regression test that drives the actual provider invalidation/completion ordering before treating it as a bug.

## BUG-2
- **Hunter's claim:** `ids == null || ids.isEmpty` treats a healthy empty catalog as loading/error, so remembered or deleted selection state is never resolved.
- **Skeptic's response:** ACCEPT. Empty data never reaches `SelectionController.selectWorkspace`, whose empty branch removes the memory key and clears selection.
- **Your analysis:** Confirmed. `explorer_panel.dart:327-338` returns for both `valueOrNull == null` and a non-null empty list. The comment says the provider will keep waiting, but a successful empty Future has no subsequent catalog event that would cause another evaluation. This bypasses the explicit empty handling in `selection_controller.dart:83-90`: `ids.firstOrNull` becomes null, the workspace key is removed, and `clear()` is called. The synchronous `focusExplorerAsset` path (`explorer_panel.dart:172-185`) can handle an already-available empty catalog, but it does not repair the typed-navigation case where the catalog becomes empty after the initial loading state. This violates the empty-catalog/deleted-asset recovery contract.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Distinguish loading/error from successful empty data. Once the catalog is a successful empty list and the intent still matches, invoke the controller's empty-catalog handling (or an equivalent method) so the `(projectId, type)` remembered entry is removed and selection is cleared. Keep returning for loading and error, and add a regression test for loading -> successful empty.

## BUG-3
- **Hunter's claim:** Creature catalog errors render text only and provide no retry action, stranding creature typed navigation after a transient failure.
- **Skeptic's response:** ACCEPT. Creature recovery watches the failed provider and returns while `valueOrNull` is null; no Explorer action invalidates it.
- **Your analysis:** Confirmed. The parent constructs `_CreatureGroup` at `explorer_panel.dart:604-619` without a retry callback. Its constructor at `:753-760` has no `onRetry`, and the error branch at `:788-790` is only `ListTile(dense: true, title: Text('$error'))`. The catalog provider is a real async repository call (`:83-88`), so an error state is reachable. Recovery explicitly returns for null IDs at `:327-338`, meaning the failed typed intent cannot restore until an unrelated invalidation or another action happens. Story and environment establish the intended pattern: their groups expose `onRetry` and render an IconButton (`explorer_story_group.dart:15-25, 46-60`; `explorer_environment_group.dart:14-24, 43-57`).
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Add `VoidCallback? onRetry` to `_CreatureGroup`, render the same refresh affordance in its error row, and pass a callback from `ExplorerPanel` that invalidates `creatureExplorerProvider(projectId)`. Verify that a successful retry re-evaluates recovery and restores the typed intent.

## BUG-4
- **Hunter's claim:** Character catalog errors likewise have no retry affordance, stranding typed character navigation.
- **Skeptic's response:** ACCEPT. The character catalog error branch is separate from narrative-assignment warnings and renders only text.
- **Your analysis:** Confirmed. `_CharacterGroup` is instantiated at `explorer_panel.dart:585-601` with no retry callback. Its constructor at `:1289-1301` has no `onRetry`, and the catalog error branch at `:1520-1525` is `error: (error, _) => [ListTile(dense: true, title: Text('$error'))]`. The separate assignment error UI at `:1506-1519` does not retry the character catalog and cannot resolve a failed `widget.characters` value. The recovery provider watches `characterControllerProvider(projectId)` at `:314-315` and returns when IDs are null at `:327-338`; therefore a transient character-load failure has no direct recovery action in the Explorer. This is inconsistent with the working Story/Environment retry pattern.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Add an optional `onRetry` to `_CharacterGroup`, attach a refresh IconButton to the character catalog error row, and invalidate `characterControllerProvider(projectId)` from the parent. Preserve the assignment warning as a separate concern and test failure -> retry -> typed restoration.

## BUG-5
- **Hunter's claim:** `SelectionController.isWorkspaceMemoryHydrated` becomes true after any project hydrates and may let a caller skip hydration for the active project.
- **Skeptic's response:** DISPROVE. No production caller uses the aggregate getter; current project persistence wiring hydrates with the project ID, and the project-scoped method exists.
- **Your analysis:** The getter is broad by design (`selection_controller.dart:39`): it reports whether any project has hydrated, not whether a specified project has. That could be a future API footgun, but the claimed present behavior is not a production defect. Repository search found no `lib/` caller of `isWorkspaceMemoryHydrated`; the only non-definition uses are tests. The production persistence provider hydrates explicitly with `projectId` (`explorer_panel.dart:256-271`), while the correct method `isWorkspaceMemoryHydratedForProject` is available at `selection_controller.dart:41-44`. Consequently there is no current workspace-switch path in this code that skips project B hydration because of the aggregate getter. The tests' aggregate assertions are not production callers.
- **VERDICT: NOT A BUG**
- **Confidence:** High
- **True severity:** N/A
- **Suggested fix:** No bug fix required. For API clarity, deprecate/rename the aggregate getter or make callers use the project-scoped method; add an API documentation comment explicitly stating that the aggregate value is not active-project status.

# VERIFIED BUG REPORT

## Stats
- **Total reported by Hunter:** 5
- **Dismissed as false positives:** 2
- **Confirmed as real bugs:** 3
- **Critical:** 0 | **Medium:** 3 | **Low:** 0

## Confirmed bugs

| # | Severity | File | Line(s) | Description | Suggested Fix |
|---|---|---|---|---|---|
| BUG-2 | Medium | `lib/features/explorer/presentation/explorer_panel.dart` | 327-338 | Successful empty catalogs are conflated with loading/error and never clear stale/deleted remembered selection. | Handle successful empty separately; remove the workspace key and clear selection. |
| BUG-3 | Medium | `lib/features/explorer/presentation/explorer_panel.dart` | 604-619, 753-817 | Creature catalog error row has no retry action. | Add `onRetry` and invalidate `creatureExplorerProvider(projectId)`. |
| BUG-4 | Medium | `lib/features/explorer/presentation/explorer_panel.dart` | 585-601, 1289-1301, 1520-1525 | Character catalog error row has no retry action. | Add `onRetry` and invalidate `characterControllerProvider(projectId)`. |

## Low-confidence items

- BUG-1 was dismissed with **Medium confidence** because the missing guard is visible, but the specific late-Future/same-tuple race is not structurally demonstrated in the supplied runtime path. It should not be reported as Critical without a deterministic reproduction.

## Final counts

**REAL: 3**  
**DISMISSED: 2**
