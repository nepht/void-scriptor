HEAD re-verified unchanged (`f72a26513875ffb5d6a1cdfb6f4c587a1bd52ace` before and after; only untracked evidence/docs files present, nothing committed mid-hunt). All 6 scope files, both reports, and 12 supporting files read in full; Riverpod/flutter_riverpod 2.6.1 sources read directly from the pub cache to settle the timing disputes.

# REFEREE VERDICTS — void-scriptor-hunt-20260910b

---

**BUG-1** (explorer_panel.dart:312–327 — catalog-recovery microtask resurrects selection after project close)
- **Hunter's claim:** Recovery re-checks intent/selection but not the session; `closeProject`'s `clear()` notifies recovery while session is still non-null, scheduling a microtask that applies `selectWorkspace` for the just-closed project.
- **Skeptic's response:** DISPROVE — Riverpod 2.6.1 never rebuilds dependents synchronously on notify; rebuilds are vsync-deferred, so every post-close rebuild sees `AsyncData(null)` and returns.
- **Your analysis:** I verified the framework code myself. `clear()` → element `setState` → dependents go through `_markDependencyChanged → invalidateSelf → scheduleProviderRefresh` (riverpod-2.6.1 element.dart:597–603, 292–298), and the scheduler defers to vsync (scheduler.dart:8–10, 65–93: `_defaultVsync = Future(task)`; flutter side framework.dart:332–345 uses `Future.microtask(() => markNeedsBuild())` then a frame build). No synchronous dependent rebuild exists. `closeProject` (project_persistence_providers.dart:158–161) runs `clear()` and `state = AsyncData(null)` in one synchronous segment with no `await` between. Since the scheduler task is an event-queue item and await-continuations are FIFO microtasks, any recovery rebuild after the close event observes `session == null` and returns at line 269 — the restore microtask is never scheduled. A microtask scheduled while the session is still open drains in the same event, before close completes, and can only select a valid asset of the still-open project, which close then clears (benign). I walked every event-loop ordering; none produces the claimed window.
- **VERDICT: NOT A BUG**
- **Confidence:** High (framework code structurally forbids the claimed synchronous rebuild; no runtime claim left unproven)
- **True severity:** n/a

---

**BUG-2** (explorer_panel.dart:241–263 / selection_controller.dart:13–27 — hydration once per app lifetime, cross-project snapshot overwrite)
- **Hunter's claim:** `_memoryHydrated` never resets, so project switches never load the new project's persisted memory, and the next persist overwrites the new project's `selection_memory.json` with a merged cross-project map.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Verified. `selectionProvider` is a non-autoDispose `NotifierProvider` (selection_controller.dart:76–79); `_memoryHydrated` is an instance field with no reset (`hydrateWorkspaceMemory` line 21–23 early-returns forever after the first call; grep confirms the only hydrate call site is explorer_panel.dart:245–251 and only tests touch `isWorkspaceMemoryHydrated`). `workspaceMemorySnapshot()` copies all `(projectId, type)` entries (`Map.of(_workspaceSelections)`, line 32–33), and the listener writes that whole map into the *current* session's package file via `createSync/writeAsStringSync/renameSync` (selection_memory_snapshot.dart:64–72). Consequence verified: any project that is not the first opened in an app run never has its file loaded, and its file is then overwritten with a snapshot missing its prior entries plus polluted with other projects' entries. Permanent loss of persisted navigation memory plus cross-project pollution.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium (silent, permanent loss of persisted state on every multi-project session; the data is low-value navigation memory, not user content)
- **Suggested fix:** Make hydration/track per project (e.g., store `hydratedProjectId` and re-hydrate on session change, or make the controller autoDispose-per-project), and filter the persisted snapshot to the active `projectId` before writing.

---

**BUG-3** (explorer_panel.dart:253–262 — uncaught disk failure in persistence listener vs contract comment)
- **Hunter's claim:** No try/catch on the sync persist path; disk failure throws uncaught out of a Riverpod listener, contradicting the "swallowed by contract … observable via debugPrint" comment.
- **Skeptic's response:** ACCEPT, severity arguably Low — Riverpod wraps self-listeners in `Zone.current.runBinaryGuarded`, so the throw becomes an unhandled zone error, not a crash.
- **Your analysis:** Verified both halves. The listener (257–262) and `persistSelectionMemorySnapshotSync` (selection_memory_snapshot.dart:64–72) contain no try/catch and no debugPrint anywhere (grep: only the comment mentions debugPrint; the async `persistSelectionMemorySnapshot` is never used here). element.dart:235/247 confirms self-listeners run via `runBinaryGuarded`, so the error cannot propagate/crash — it surfaces as a repeated unhandled zone error on every selection change while the disk is failing, and the code's own documented contract is objectively false. Real defect, but no crash and no data loss beyond the already-convenience memory.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low (downgraded from Medium — contained zone error, contract violation, broken observability)
- **Suggested fix:** Wrap the listener body in try/catch and debugPrint the failure, matching the documented contract (mirror `loadSelectionMemorySnapshotSync`'s catch-all).

---

**BUG-4** (void_desktop_shell.dart:117–131 — desktop "Projects" button opens Novel workspace; dead switch arm)
- **Hunter's claim:** `explorerAssetTypeForMenu('novels') → AssetType.story` intercepts before the route switch, so with a session the "Projects"-labeled top-bar button focuses the Novel workspace; `'novels' => AppRoutes.projects` is unreachable.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Verified. explorer_panel.dart:129–134 maps `'story' || 'novels'` to story; void_desktop_shell.dart:118–127 intercepts first (`focusExplorerAsset` + push workspace). The desktop top bar renders only dashboard/novels/search destinations (void_top_bar.dart:59–66), and the `novels` destination is labeled "Projects" (app_navigation_registry.dart:50–55). Mobile uses the registry directly and is unaffected. So on desktop with an open project, the button labeled Projects reliably opens the Novel workspace, and the switch arm at line 130 is dead code.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium (wrong destination on a primary navigation control, always reproducible)
- **Suggested fix:** Handle `'novels'` before `explorerAssetTypeForMenu` (or remove `'novels'` from the menu→AssetType map and let the switch route it to `AppRoutes.projects`).

---

**BUG-5** (workspace_resolver.dart:120–153 — `onCreateNovel` never invalidates `storyExplorerProvider`)
- **Hunter's claim:** Novel created from ProjectOverview never appears in the Explorer's story list, unlike the panel flow which does invalidate.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Verified. `onCreateNovel` selects and invalidates only `projectAssetsProvider` (line 152). `storyExplorerProvider` (explorer_panel.dart:102–111) watches only `projectSessionProvider`; the session object is unchanged, so no rebuild. The panel path invalidates it (line 1061); this path does not (grep confirms no other invalidation). The new novel is absent from the Explorer until an unrelated invalidation (e.g., creating another asset). Same class of bug as hunt-run157 BUG-05 the comment cites — the fix was applied to `projectAssetsProvider` but the explorer catalog was missed.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium (visible feature failure on a primary creation flow)
- **Suggested fix:** Add `ref.invalidate(storyExplorerProvider(session.manifest.id));` in `onCreateNovel` (mirror explorer_panel.dart:1061).

---

**BUG-6** (workspace_resolver.dart:570–620 — `_createFaction` never reloads `_factions`)
- **Hunter's claim:** After "Create Faction", the new faction is selected but never appears in the Factions list because the resolver's cached `_WorldbuildingBodyState` lists are never refreshed.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Verified. `_createFaction` (597–613) creates + selects; `_factions` is assigned only in `_load()` (554), which runs once via the `initState` `listenManual(fireImmediately: true)` guard `next.valueOrNull != null && _factions == null && !_loading` (521–525) — after the first load `_factions != null`, so later session notifications don't reload. The `ValueKey('wb-<projectId>')` is identical before/after (grep confirms all three key sites use project id only), so the same State persists with stale lists. The selected faction is also not highlighted (not in the list). Recovery only via remount with a different key (project switch) or the error retry button.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** `await _load()` after successful creation (or optimistically append the created faction to `_factions` with `setState`).

---

**BUG-7** (void_mobile_shell.dart:103–107 — `requiresProject` guard checks `widget.projectId` instead of the live session)
- **Hunter's claim:** On `/workspace` (no projectId param) with an open session, Characters/World wrongly push the Projects list.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Verified. `widget.projectId` is non-null only via `/studio/:projectId` (app_router.dart:300–304); `AppRoutes.workspace` (405–408), `AppRoutes.studio` (409–412) and dashboard (287–289) build `VoidAppShell(onLogout:)` with projectId null, and `_openProject(null)` merely resets local flags without closing the global session (void_app_shell.dart:66–71). Reaching `/workspace` is the normal path: tapping Characters while on `/studio/:pid` navigates to `destination.route` = `AppRoutes.workspace` (the projectId-rewrite at 113–116 applies only to `write`). Once there, the guard at 104–107 fails for `characters`/`world` (requiresProject: true, registry 57–72) despite the open session, and the `focusExplorerAsset` calls at 108–112 are never reached.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Guard on the live session (e.g., `ref.read(currentProjectIdProvider) != null`) instead of `widget.projectId`.

---

**BUG-8** (explorer_panel.dart:301–308 — failed catalog strands typed intent with no retry for character/story/environment)
- **Hunter's claim:** `ids == null` treats error like loading; a failed FutureProvider never re-emits, permanently stranding the intent except for creature (which has a retry UI).
- **Skeptic's response:** ACCEPT ("permanently" slightly overstated).
- **Your analysis:** Verified. `idsOf` returns null for both loading and error; the keep-waiting branch (302–308) has no error discrimination. Nothing invalidates `characterControllerProvider`/`storyExplorerProvider`/`environmentExplorerProvider` on error (grep: invalidations only follow create flows). Re-tapping re-reads `.valueOrNull` → null → `restore(null)` keeps waiting (158–165). Story/environment group error rows are plain text with no retry (explorer_story_group.dart:41, explorer_environment_group.dart:38); only `_CreatureEmptyState` has a retry button (workspace_resolver.dart:445–457). Indirect recovery does exist (creating an asset of that type invalidates its provider; the resolver's character empty-state offers Create) — so "permanently" is overstated, but the direct tap-retry dead-ends silently after a transient DB error, and story is worst because creation doesn't even invalidate the catalog (BUG-5).
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium (functional dead-end on primary navigation after a transient error; recovery only via indirect actions)
- **Suggested fix:** Treat `catalog.hasError` distinctly in recovery (surface a retry that invalidates the failed provider), and/or add retry buttons to the story/environment group error rows.

---

**BUG-9** (explorer_panel.dart:1044–1060 + workspace_resolver.dart:121–139 — non-transactional three-step story creation)
- **Hunter's claim:** story → chapter → scene with a catch-all snackbar and no rollback; failure after `createStory` orphans a story row and retry duplicates it.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Verified. Three sequential awaits with per-call DB transactions at most (`createStory` wraps its own two inserts; chapter/scene are separate inserts — create_story_service.dart:24–66+), then a catch-all that only snackbars (1137–1147); no compensation. `createExplorerAsset` is freely re-runnable → duplicate story with a fresh UUID. Orphaned row is user-visible and manually deletable, so not Critical, but it is real data hygiene corruption on a ordinary flow, in two independent call sites.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Wrap the three inserts in one `database.transaction`, or compensate by deleting the created story (and directories) in the catch block before showing the snackbar.

---

**BUG-10** (explorer_panel.dart:90–111 — full-table fetch + client-side filter per family instance)
- **Hunter's claim:** `getAllAssets()` fetched and filtered client-side per armor/accessory/story instance.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Verified verbatim (lines 94–99, 108–110): full table load, then `.where(projectId && type)` + sort, repeated per family instance on every rebuild after invalidation. Factually accurate performance defect, small tables in practice.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Query scoped by `projectId` + `type` in the DAO (and let SQL sort) instead of `getAllAssets()`.

---

**BUG-11** (explorer_panel.dart:1301–1312 — dialog dismissal clears the filter like Reset)
- **Hunter's claim:** Barrier-tap/back returns `null`, which the `else` branch treats exactly like the explicit Reset.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Verified: `if (applied == true) { apply } else { clear all }` — `showDialog<bool>` yields null on dismissal, indistinguishable from `pop(false)`. Dismissing without intent silently discards the user's active filter (no confirmation, no way to tell Reset from accidental dismiss).
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Only mutate state when `applied != null` (true → apply, false → reset); leave the filter untouched on `null`.

---

**BUG-12** (explorer_panel.dart:1326–1347, 1401–1428 — filter against still-loading assignments renders zero tiles)
- **Hunter's claim:** With an active filter while assignments load, `valueOrNull ?? const []` filters everyone out; the data branch then renders an empty list with no loading indicator.
- **Skeptic's response:** ACCEPT (nuance: only role/explicit-value filters zero out; `unspecified` matches vacuously).
- **Your analysis:** Verified, including the nuance: `matchesCharacter` with a role filter on empty assignments returns false for everyone (narrative_character_filter.dart:41–44, `own.any` on empty), and the loading state has `assignmentError == null`, so the fail-open branch (1332–1335) is skipped; `(filtered ?? items)` renders `[]` while loading (1401–1408). Real transient edge case distinct from the handled error path.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Treat `assignments.isLoading` like the error path (fail open: `filtered = null`), or render a loading row while the filter depends on pending assignments.

---

**BUG-13** (explorer_panel.dart:114, 140, 486, 503 — focus highlight leaks across projects)
- **Hunter's claim:** `explorerAssetFocusProvider` is never cleared or project-guarded, so the "focused" tint leaks into the next project's explorer.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Verified by grep: declared (114), written (140), watched (411) — never cleared anywhere, and the `focused:` comparisons (486, 503) test the raw stale value (unlike `worldbuildingSectionIntentProvider`, which is cleared at 138 and whose consumers guard by projectId at workspace_resolver.dart:628). After focusing Story in project A, project B's story/character groups render highlighted until another focus occurs. Cosmetic.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Clear `explorerAssetFocusProvider` when `projectSessionProvider` changes (or store `(projectId, type)` and compare both, mirroring the section-intent pattern).

---

**BUG-14** (explorer_panel.dart:901–908, 1030–1034 — `ref.read` after dialog await without mounted guard)
- **Hunter's claim:** If the panel unmounts while the dialog is open, the disposed WidgetRef throws on the post-await `ref.read`.
- **Skeptic's response:** ACCEPT — framework-verified `StateError('Cannot use "ref" after the widget was disposed.')`.
- **Your analysis:** The framework part is verified: consumer.dart `_assertNotDisposed` (548–550) is called by `read` (617–619) and throws when `!context.mounted`. The repo part is verified: `_configureSidebarModules` reads `projectSessionProvider` at 902 immediately after the dialog await with `context.mounted` only checked later (910); `createExplorerAsset` reads `projectPathsProvider` at 1033 after its dialog await. However, reachability requires the panel's element to be disposed while its own dialog route is open — possible only in narrow scenarios (stack replacement underneath an open dialog, e.g., forced logout/navigation). This is a runtime-only claim without runtime evidence: per the static-analysis honesty rule it stays Low and is flagged, though the missing guard is objective (the same functions guard `context.mounted` elsewhere).
- **VERDICT: REAL BUG**
- **Confidence:** Medium
- **True severity:** Low
- **Suggested fix:** After each dialog await, check `context.mounted` before any `ref.read` (and bail out early), matching the existing guards later in the same functions.

---

**BUG-15** (project_sidebar_module_preferences.dart:236–260, 308–321 — substring genre matching false positives)
- **Hunter's claim:** Raw `contains` matching without word boundaries produces false-positive module recommendations.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Verified: `normalized.contains(alias)` (253) makes `'live-action'`/`'interactive fiction'` match the `'action'` profile (weapons=true); `terms.any(genre.contains)` (308–309) makes `'warehouse'.contains('war')` match the war/military term. Real false-positive mechanism; impact bounded because recommendations are suggestions the user confirms in the dialog.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Match on word boundaries (tokenize the normalized genre or use `RegExp(r'\b…\b')`) for aliases and genre terms.

---

**BUG-16** (workspace_resolver.dart:288–291 — `'Locations'` omitted from `_opensWorldbuildingCollection`)
- **Hunter's claim:** A restored environment selection with `activeSection == 'Locations'` bypasses the Locations collection view and lands on `EnvironmentWorkspaceScreen`.
- **Skeptic's response:** ACCEPT (76% confidence, noting it could be intended design).
- **Your analysis:** The behavior is factually as described, but I judge it designed, not buggy. Setting an environment selection lands on the dedicated screen on *every* path, not just restoration: the WorldbuildingBody Locations list itself calls `_selectAsset(environment)` (750–753) → resolver 199–207 → `EnvironmentWorkspaceScreen`. The collection switch's members ('Factions'/'Relationships'/'Timeline'/'Lore Notes') are exactly the asset types with no dedicated workspace screen (timeline selection always renders the collection at 212–221). So the omission of `'Locations'` is consistent with the app-wide selection→dedicated-screen design; the only observable divergence is the transient pre-selection render while the catalog loads, which is inherent to any async restore and self-corrects. The Hunter's framing treats the dominant designed behavior as the bug.
- **VERDICT: NOT A BUG**
- **Confidence:** Medium (behavior verified; the design-intent judgment is the residual risk)

---

**BUG-17** (workspace_resolver.dart:53–62, 180–284 — selection branch lacks a "session open" guard)
- **Hunter's claim:** With `session == null` and a non-null selection, the resolver renders workspace screens for a project with no open database; reached via BUG-1's race.
- **Skeptic's response:** DISPROVE — no live path reaches the state; even hypothetically it's a benign empty screen.
- **Your analysis:** I independently audited every way `projectSessionProvider` can become null while a selection survives. (1) `closeProject` clears the selection synchronously before `state = AsyncData(null)` (project_persistence_providers.dart:158–161, no await between; per my BUG-1 analysis no rebuild can observe the intermediate state, and any later rebuild sees both cleared — consistent). (2) Project switches run `_releaseForeignSelection` before `AsyncLoading` (118–119), clearing same-session-foreign selections; same-project re-opens short-circuit at openProject:100–102 without touching state. (3) Failed opens set `AsyncError` while the initiating `VoidAppShell` shows its `_opening/_openError` scaffold (void_app_shell.dart:99–144), unmounting the resolver for the duration. (4) Grep confirms zero `invalidate/refresh(projectSessionProvider)` and `ProjectOpenMode` is never varied (readOnly referenced once, never opened). With BUG-1's trigger disproven, the cited reachability collapses. Notably the story branch *deliberately* handles `session == null` with null journal/repository (228–276), indicating the authors anticipated this combination defensively; worst case is a benign empty screen, not a crash. This is a latent hardening gap, not a live bug.
- **VERDICT: NOT A BUG**
- **Confidence:** Medium (all null-paths audited statically; a truly exhaustive runtime proof isn't possible without execution)
- **True severity:** n/a (hardening suggestion: add an explicit `session == null` guard or assert before the selection switch)

---

**BUG-18** (explorer_panel.dart:188–194, 516–530, 656–664 — creature sync-restore branch unreachable from UI)
- **Hunter's claim:** `_CreatureGroup` exposes no `onFocused`/`focused`, so the creature branch in `focusExplorerAsset` is unreachable and tapping the Creatures header never restores creature memory.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Verified. `_CreatureGroup` (656–664) has no focus fields and its `ExpansionTile` (666) has no `onExpansionChanged`; the instantiation (518–530) passes none — unlike `StoryGroup`/`_CharacterGroup`/`EnvironmentGroup` which all pass `onFocused`. Grep of all `focusExplorerAsset` call sites shows story/character/environment/timeline only — zero creature call sites anywhere. The sync-restore branch (188–194) and its comment are therefore dead code, and creature selection memory never restores on header tap (feature parity gap with the other groups, consistent with the recovery provider's creature case being added for a flow that was never wired).
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low (dead feature path; no wrong behavior, just missing intended behavior)
- **Suggested fix:** Add `focused`/`onFocused` to `_CreatureGroup` (mirror `EnvironmentGroup`) and pass `onFocused: () => focusExplorerAsset(ref, AssetType.creature)`.

---

**BUG-19** (explorer_panel.dart:158–172 + selection_controller.dart:56–64 — sync restore on empty catalog wipes the memory key)
- **Hunter's claim:** `restore()` with a loaded-but-empty catalog deletes the per-workspace memory key and persists the wipe, "permanently destroying remembered selection," contradicting recovery's no-write-on-empty contract.
- **Skeptic's response:** DISPROVE — wiping a dead key is correct cleanup.
- **Your analysis:** I agree with the Skeptic. `restore()` only receives a non-null list when the catalog is genuinely `AsyncData` — during invalidation-reload `valueOrNull` preserves the previous non-empty value, and errors yield null (→ `restore(null)`, which preserves memory). So the wipe fires only when the same project's catalog is truly empty, which means the remembered id references a deleted asset: `ids.contains(remembered)` would reject it and `ids.firstOrNull` is null, so that entry could never produce a restore anyway. Removing it and persisting the reduced snapshot is correct maintenance of a dead key with zero user-observable loss. The comment at 303–307 documents loop-avoidance in the recovery provider, not a data-preservation guarantee binding the sync path.
- **VERDICT: NOT A BUG**
- **Confidence:** High

---

**BUG-20** (explorer_panel.dart:412–423 + project_sidebar_module_preferences.dart:331–371 — module-prefs provider errors silently fall back to defaults)
- **Hunter's claim:** `load()` catches only `FormatException`; IO/DB errors surface as `AsyncError`, silently masked by `valueOrNull ?? const defaults` with no error surface or retry.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Verified. `recoverIfInterrupted` (337) and all DB selects (349–362) sit outside the try (344 catches only `FormatException`), so failures put the FutureProvider in `AsyncError`. The panel's fallback (417–423) has no `hasError` branch and no retry, in contrast to the narrative-assignments error UI in the same file (1387–1400). The user silently gets default modules until an unrelated invalidation (e.g., project reopen). Degraded UX, no data loss — settings are untouched, just not shown/applied.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Mirror the assignments pattern: on `hasError` show an inline warning row with a retry that invalidates `projectSidebarModulePreferencesProvider(projectId)` (or catch-all in `load()` returning defaults with a debugPrint).

---

# VERIFIED BUG REPORT — Final Summary

**Stats:**
- Total reported by Hunter: 20
- Dismissed as false positives: 4 (BUG-1, BUG-16, BUG-17, BUG-19)
- Confirmed as real bugs: 16
- Critical: 0 | High: 0 | Medium: 7 | Low: 9

**Confirmed bugs (ordered by severity):**

| # | Severity | File | Line(s) | Description | Suggested Fix |
|---|----------|------|---------|-------------|---------------|
| BUG-2 | Medium | explorer_panel.dart / selection_controller.dart | 241–263 / 13–27 | Hydration once per app lifetime; project switch never loads new project's memory; persist overwrites current project's file with merged cross-project snapshot (permanent loss + pollution) | Per-project hydration; filter snapshot to active projectId before writing |
| BUG-4 | Medium | void_desktop_shell.dart | 117–131 | Desktop "Projects" button always intercepted → opens Novel workspace; `'novels' => projects` arm is dead code | Route `'novels'` before `explorerAssetTypeForMenu` |
| BUG-5 | Medium | workspace_resolver.dart | 120–153 | `onCreateNovel` doesn't invalidate `storyExplorerProvider` — new novel absent from Explorer | Add `ref.invalidate(storyExplorerProvider(projectId))` |
| BUG-6 | Medium | workspace_resolver.dart | 570–620 | `_createFaction` never reloads `_factions`; new faction invisible in Factions list (same `ValueKey` State) | `await _load()` after create, or optimistic append |
| BUG-7 | Medium | void_mobile_shell.dart | 103–107 | `requiresProject` guard uses null `widget.projectId` on `/workspace` → Characters/World push Projects despite open session | Guard on live session (`currentProjectIdProvider`) |
| BUG-8 | Medium | explorer_panel.dart | 301–308 | Failed catalog strands typed intent; no retry surface for character/story/environment | Distinguish `hasError` in recovery with retry; retry buttons on group error rows |
| BUG-9 | Medium | explorer_panel.dart / workspace_resolver.dart | 1044–1060 / 121–139 | Non-transactional story→chapter→scene creation; failure orphans story, retry duplicates | Single DB transaction or compensating delete in catch |
| BUG-3 | Low | explorer_panel.dart / selection_memory_snapshot.dart | 253–262 / 64–72 | Uncaught sync persist throws as unhandled zone error; contract comment (swallow + debugPrint) objectively false | try/catch + debugPrint in listener |
| BUG-10 | Low | explorer_panel.dart | 90–111 | Full `getAllAssets()` per family instance, client-side filter | Scoped DAO query by projectId+type |
| BUG-11 | Low | explorer_panel.dart | 1301–1312 | Dialog dismissal (null) clears filter like explicit Reset | Treat `null` as no-op |
| BUG-12 | Low | explorer_panel.dart | 1326–1347, 1401–1408 | Filter against still-loading assignments renders zero tiles, no loading indicator | Fail open while `isLoading`, or show loading row |
| BUG-13 | Low | explorer_panel.dart | 114, 140, 486, 503 | Focus highlight never cleared across projects | Clear on session change or store `(projectId, type)` |
| BUG-14 | Low | explorer_panel.dart | 901–908, 1030–1034 | `ref.read` after dialog await without mounted guard → `StateError` if panel disposed | `context.mounted` check before post-await `ref.read` |
| BUG-15 | Low | project_sidebar_module_preferences.dart | 236–260, 308–321 | Substring genre matching false positives ('live-action'→weapons, 'warehouse'→war) | Word-boundary matching |
| BUG-18 | Low | explorer_panel.dart | 188–194, 516–530, 656–664 | Creature sync-restore branch unreachable; `_CreatureGroup` lacks `onFocused` | Add focus wiring mirroring EnvironmentGroup |
| BUG-20 | Low | explorer_panel.dart / project_sidebar_module_preferences.dart | 412–423 / 331–371 | Module-prefs provider errors silently fall back to defaults, no retry | Error row + retry, mirroring assignments pattern |

**Low-confidence items (flagged for manual review):**
- BUG-14 (Medium confidence): framework throw path verified, but the unmount-while-dialog-open reachability is a runtime claim without runtime evidence — kept Low per the honesty rule.
- BUG-16, BUG-17 (Medium confidence): behavior fully verified statically; verdicts rest on design-intent (BUG-16) and exhaustive-but-static null-path audit (BUG-17). BUG-17 is worth a defensive guard regardless.

**Dispute resolutions:** BUG-1 — Skeptic correct; I independently confirmed from riverpod-2.6.1 sources (element.dart:597–603/292–298, scheduler.dart:8–10/65–93, flutter framework.dart:332–345) that dependent rebuilds are vsync-deferred and `closeProject`'s clear+null are one synchronous segment; the claimed microtask window cannot exist. BUG-17 — Skeptic correct on reachability; every session→null path clears or releases the selection first. BUG-19 — Skeptic correct; the wipe only fires on genuinely empty data, i.e., dead memory cleanup.

**HEAD tracking:** `f72a26513875ffb5d6a1cdfb6f4c587a1bd52ace` before and after review — no mid-hunt commits. No files created or modified; repo untouched (read-only inspection only).