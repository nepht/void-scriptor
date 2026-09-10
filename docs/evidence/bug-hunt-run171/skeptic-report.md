# Adversarial bug hunt — Skeptic report (void-scriptor-hunt-20260910b)

All 20 findings verified against the live code (all 6 scope files read in full, plus 10 supporting files and the actual flutter_riverpod 2.6.1 / riverpod 2.6.1 sources in the pub cache to settle the two timing/throw claims). Verdicts:

---

**BUG-1** | Original: 5 pts — **DISPROVE**
- **Counter-argument:** The claimed window cannot exist. `closeProject` runs `clear()` and `state = const AsyncData(null)` in one synchronous segment (project_persistence_providers.dart:160–161, no `await` between them), and Riverpod 2.6.1 never rebuilds a dependent provider synchronously on notify: `_markDependencyChanged → invalidateSelf → scheduler.scheduleProviderRefresh` (riverpod-2.6.1 framework/element.dart:597–603, 292–308), and the scheduler defers to vsync = `Future(task)`/frame callback (framework/scheduler.dart:8–10, 65–93). So every rebuild of `explorerCatalogRecoveryProvider` happens strictly after the close tail: it re-executes its closure, re-reads `projectSessionProvider` (now `AsyncData(null)`), and returns at `if (intent == null || session == null) return;` — no microtask is ever scheduled post-close. A microtask scheduled pre-close (flush while session stale during `await _session?.close()`) drains at the end of that same event, before the close-completion event, so it can only run while the project is still open (selecting a valid asset that close then clears — benign). `Future.microtask` callbacks cannot run between `clear()` and `state=null` (no event boundary) or after the tail (flush sees null session).
- **Evidence:** riverpod-2.6.1 scheduler.dart `_scheduleTask`: `vsync(_task)` with `_defaultVsync = Future(task)`; element.dart `flush()` re-runs `_performBuild` on `_mustRecomputeState`; explorer_panel.dart:268–269 re-watches session on every rebuild.
- **Confidence:** 85% — **Risk calc:** EV = (85%×5) − (15%×10) = +2.75 — **Decision: DISPROVE**

---

**BUG-2** | Original: 5 pts — **ACCEPT**
- **Counter-argument:** None — verified. `_memoryHydrated` is an instance field on a non-autodispose `SelectionController` (selection_controller.dart:14, 21–27); `build()` never resets it, and the only hydrate call (explorer_panel.dart:245–251) becomes a no-op after the first project open. `workspaceMemorySnapshot()` returns *all* `(projectId, type)` entries and the listener writes them wholesale into the *current* project's file.
- **Evidence:** selection_controller.dart:32–33 `Map.of(_workspaceSelections)`; selection_memory_snapshot.dart:68–71 `createSync/writeAsStringSync/renameSync` overwrites `cache/selection_memory.json` of the active package with the merged cross-project map.
- **Confidence:** 95% — **Risk calc:** n/a (accept) — **Decision: ACCEPT**

---

**BUG-3** | Original: 5 pts — **ACCEPT** (severity arguably Low)
- **Counter-argument:** Only nit: in Riverpod 2.6.1 self-listeners run via `Zone.current.runBinaryGuarded` (framework/element.dart:230–255), so the throw doesn't propagate to a caller — it becomes an unhandled zone error on *every* selection change. The substance stands: no try/catch anywhere on the write path and no debugPrint, directly contradicting the code's own contract comment.
- **Evidence:** explorer_panel.dart:237–240 comment "disk failures are swallowed by contract … observable via debugPrint" vs listener at 257–262 with no catch; selection_memory_snapshot.dart:64–72 has no try/catch (unlike `loadSelectionMemorySnapshotSync`:81–106 which does).
- **Confidence:** 90% — **Decision: ACCEPT** (recommend downgrade Medium→Low: noisy unhandled errors, no crash/data loss)

---

**BUG-4** | Original: 5 pts — **ACCEPT**
- **Counter-argument:** None. `explorerAssetTypeForMenu('novels')` returns `AssetType.story` (explorer_panel.dart:130), so the intercept at void_desktop_shell.dart:118–127 always fires first with an open session; the `'novels' => AppRoutes.projects` arm (line 130) is dead code. The desktop top bar really does show only dashboard/novels/search (void_top_bar.dart:59–66), and the `novels` destination is labeled "Projects" (app_navigation_registry.dart:50–55) — so the button labeled Projects opens the Novel workspace.
- **Confidence:** 95% — **Decision: ACCEPT**

---

**BUG-5** | Original: 5 pts — **ACCEPT**
- **Counter-argument:** None. `onCreateNovel` (workspace_resolver.dart:140–152) invalidates only `projectAssetsProvider`; `storyExplorerProvider` depends only on `projectSessionProvider` (explorer_panel.dart:102–111) so nothing re-runs it. Contrast the panel flow which does `ref.invalidate(storyExplorerProvider(projectId))` (explorer_panel.dart:1061). New novel stays absent from the Explorer until an unrelated invalidation.
- **Confidence:** 92% — **Decision: ACCEPT**

---

**BUG-6** | Original: 5 pts — **ACCEPT**
- **Counter-argument:** None. `_createFaction` (workspace_resolver.dart:597–613) creates + selects but never calls `_load()`; `_factions` is only assigned in `_load()` (line 554), driven solely by the initState `listenManual` (521–525) and the error retry button. The `ValueKey('wb-<projectId>')` (lines 101/217) is identical before/after, so the same State persists with stale lists.
- **Confidence:** 93% — **Decision: ACCEPT**

---

**BUG-7** | Original: 5 pts — **ACCEPT**
- **Counter-argument:** None. Guard at void_mobile_shell.dart:104–107 uses `widget.projectId`, which is null for the `VoidAppShell()` built on `AppRoutes.workspace` (app_router.dart:79) and only non-null on `/studio/:projectId` (app_router.dart:300–304). `projectSessionProvider` is global and stays open (VoidAppShell `_openProject(null)` merely resets local flags, void_app_shell.dart:66–71), so Characters/World (requiresProject: true, registry 57–72) push the Projects list despite an open session once the user is on `/workspace`.
- **Confidence:** 90% — **Decision: ACCEPT**

---

**BUG-8** | Original: 5 pts — **ACCEPT**
- **Counter-argument:** "Permanently" is slightly overstated (creating an asset of that type via the panel invalidates the catalog and unstrands recovery), but the core is verified: `ids == null` treats error like loading (explorer_panel.dart:301–308); failed FutureProviders never re-emit; `focusExplorerAsset` re-reads `.valueOrNull` → null → keep-waiting; only `_CreatureEmptyState` has a retry button (workspace_resolver.dart:445–457). Character/story/environment intents have create buttons but no reload surface, and story's create path doesn't even invalidate the catalog (BUG-5).
- **Confidence:** 88% — **Decision: ACCEPT**

---

**BUG-9** | Original: 5 pts — **ACCEPT**
- **Counter-argument:** None. Three sequential awaits (explorer_panel.dart:1049–1060; same in workspace_resolver.dart:125–139) inside a catch-all that only snackbars; no rollback, and `createExplorerAsset` re-runs freely → orphaned story + duplicate on retry.
- **Confidence:** 90% — **Decision: ACCEPT**

---

**BUG-10** | Original: 1 pt — **ACCEPT**
- **Evidence:** explorer_panel.dart:90–100 and 102–111: both providers call `getAllAssets()` then client-side filter, per family instance (armor + accessory + story = 3 full-table loads per refresh). Factually accurate performance claim.
- **Confidence:** 95% — **Decision: ACCEPT**

---

**BUG-11** | Original: 1 pt — **ACCEPT**
- **Evidence:** explorer_panel.dart:1303–1311: `if (applied == true) {…} else { clear all }` — `showDialog<bool>` returns null on barrier tap/back, treated identically to the explicit Reset (`pop(false)`). Verified.
- **Confidence:** 95% — **Decision: ACCEPT**

---

**BUG-12** | Original: 1 pt — **ACCEPT**
- **Evidence:** explorer_panel.dart:1326, 1336–1344, 1408: `valueOrNull ?? const []` + `matchesCharacter` with empty assignments → role filter matches nobody (`own.any` → false, narrative_character_filter.dart:41–44) → `(filtered ?? items)` renders `[]` with no loading row. (Minor nuance: `unspecified` importance/POV filters vacuously match everyone; zero-tiles occurs with role or explicit value filters.) Real transient edge-case.
- **Confidence:** 90% — **Decision: ACCEPT**

---

**BUG-13** | Original: 1 pt — **ACCEPT**
- **Evidence:** Repo-wide grep: `explorerAssetFocusProvider` is only declared (114), written (140), and watched (411) — never cleared or project-guarded (`worldbuildingSectionIntentProvider` *is* cleared at 138, this one isn't). Highlight tint leaks into the next project's explorer. Real, cosmetic.
- **Confidence:** 92% — **Decision: ACCEPT**

---

**BUG-14** | Original: 1 pt — **ACCEPT**
- **Evidence:** Verified in flutter_riverpod-2.6.1 consumer.dart:618–620 — `ref.read` calls `_assertNotDisposed()` which throws `StateError('Cannot use "ref" after the widget was disposed.')`. explorer_panel.dart:902 (`ref.read(projectSessionProvider)` right after the dialog await, `context.mounted` only checked at 910) and 1033 (`ref.read(projectPathsProvider)` after the dialog await) are both exposed. Reachability is rare (shell unmount while dialog open, e.g., forced logout), but the defect is objective.
- **Confidence:** 85% — **Decision: ACCEPT**

---

**BUG-15** | Original: 1 pt — **ACCEPT**
- **Evidence:** project_sidebar_module_preferences.dart:253 and 308–309: raw `normalized.contains(alias)` / `terms.any(genre.contains)`. Verified examples: `'live-action'.contains('action')` → weapons=true; `'warehouse'.contains('war')` → War/Military weapons match. Real false-positive mechanism in a recommendation (user stays in control) — Low is right.
- **Confidence:** 90% — **Decision: ACCEPT**

---

**BUG-16** | Original: 1 pt — **ACCEPT**
- **Evidence:** workspace_resolver.dart:288–291 omits `'Locations'`; explorer_panel.dart:144 activates `(worldbuilding, 'Locations')` for environments. Observable inconsistency: the same World tap renders WorldbuildingBody (collection) when the catalog is still loading, but EnvironmentWorkspaceScreen when a remembered/first environment was restored. Could be intended design, but the timing-dependent divergence is real.
- **Confidence:** 76% — **Decision: ACCEPT**

---

**BUG-17** | Original: 1 pt — **DISPROVE**
- **Counter-argument:** The branch exists, but no live path reaches it with a broken render. Every session→null transition goes through `closeProject`, which clears the selection synchronously *before* `state = AsyncData(null)` (project_persistence_providers.dart:160–161 — no event can interleave); `_releaseForeignSelection` (168–173) clears foreign selections on every open; failed opens surface only via the initiating `VoidAppShell`, whose `_opening || _openError != null` Scaffold replaces the entire shell (void_app_shell.dart:99–144) so the resolver isn't mounted during opens; and nothing else ever nulls or invalidates the session (grep: zero `invalidate/refresh(projectSessionProvider)`). The Hunter's only cited trigger is BUG-1's race, which is disproved above. Even hypothetically, the story branch deliberately passes null session params (workspace_resolver.dart:228–240) and downstream providers guard `session == null → const []` — a benign empty screen, not a crash.
- **Confidence:** 74% — **Risk calc:** EV = (74%×1) − (26%×2) = +0.22 — **Decision: DISPROVE** (latent defensive gap, not a live bug)

---

**BUG-18** | Original: 1 pt — **ACCEPT**
- **Evidence:** `_CreatureGroup` constructor (explorer_panel.dart:656–664) has no `onFocused`/`focused` and its `ExpansionTile` has no `onExpansionChanged`; the instantiation (518–530) passes none — vs `EnvironmentGroup` which has `onFocused` (explorer_environment_group.dart:13, 23). Grep confirms `focusExplorerAsset(AssetType.creature)` has zero call sites (mobile: character/world; desktop menu: story/character/environment only; panel: story/character/environment/timeline). The creature sync-restore branch (188–194) is unreachable from all UI.
- **Confidence:** 90% — **Decision: ACCEPT**

---

**BUG-19** | Original: 1 pt — **DISPROVE**
- **Counter-argument:** The wipe fires only when the typed catalog is loaded-and-**empty** (`valueOrNull` is null while loading *or* on error, so a genuine `data([])` is required). An empty catalog for the same projectId means the remembered id necessarily references a deleted asset — dead memory that could never be restored anyway (recovery's `ids.contains(remembered)` would reject it and pick `firstOrNull` regardless, selection_controller.dart:59). Wiping + persisting is correct cleanup of a stale key with zero user-observable loss; the recovery comment (explorer_panel.dart:303–307) documents loop-avoidance, not a data-preservation guarantee.
- **Confidence:** 76% — **Risk calc:** EV = (76%×1) − (24%×2) = +0.28 — **Decision: DISPROVE**

---

**BUG-20** | Original: 1 pt — **ACCEPT**
- **Evidence:** `load()` catches only `FormatException` around the JSON decode (project_sidebar_module_preferences.dart:339–347); `recoverIfInterrupted` and all DB selects are outside the try → IO/DB errors put the FutureProvider in AsyncError, and the panel's `.valueOrNull ?? const ProjectSidebarModulePreferences(…)` (explorer_panel.dart:417–423) silently shows defaults with no `hasError` branch (contrast the assignments error UI at 1387–1400). Verified.
- **Confidence:** 88% — **Decision: ACCEPT**

---

**SUMMARY:**
- Bugs disproved: 3 (BUG-1, BUG-17, BUG-19 — total points claimed: 7)
- Bugs accepted as real: 17 (points: 49)
- Your final score: +7 net points
- Notes: BUG-3 accepted with a severity caveat (Riverpod's `runBinaryGuarded` contains the throw as an unhandled zone error rather than propagating it — contract violation stands, suggest Medium→Low). BUG-1's disproof rests on verified Riverpod 2.6.1 scheduler semantics (dependency-change rebuilds are vsync-deferred, and `closeProject`'s clear+null are one synchronous segment).

**ACCEPTED BUG LIST:**
BUG-2 (Medium 5), BUG-3 (Medium 5, suggest Low), BUG-4 (Medium 5), BUG-5 (Medium 5), BUG-6 (Medium 5), BUG-7 (Medium 5), BUG-8 (Medium 5), BUG-9 (Medium 5), BUG-10 (Low 1), BUG-11 (Low 1), BUG-12 (Low 1), BUG-13 (Low 1), BUG-14 (Low 1), BUG-15 (Low 1), BUG-16 (Low 1), BUG-18 (Low 1), BUG-20 (Low 1)
