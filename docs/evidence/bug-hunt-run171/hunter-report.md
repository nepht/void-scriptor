# Adversarial bug hunt — Hunter report

**Run:** void-scriptor-hunt-20260910b · **Target:** D:\VoidScriptor\void_scriptor_multiplatform · HEAD `f72a26513875ffb5d6a1cdfb6f4c587a1bd52ace` (verified via git rev-parse) · All 6 in-scope files read in full; supporting files (selection_memory_snapshot.dart, selection_model.dart, asset_type.dart, project_persistence_providers.dart, workspace_panel.dart, app_navigation_registry.dart, character_model.dart, creature_model.dart, character_controller.dart, narrative_character_filter.dart) read to verify claims.

---

**void-scriptor-hunt-20260910b BUG-1** | Severity: Medium | Points: 5
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\features\explorer\presentation\explorer_panel.dart
- **Line(s):** 312–327 (with 265–271, 301–308)
- **Category:** concurrency
- **Claim:** The catalog-recovery microtask re-checks intent and selection but never re-checks the project session, so it can resurrect a selection for a project that was closed or switched in the one-microtask window between the synchronous build and the restore.
- **Evidence:** `Future<void>.microtask(() { final currentIntent = ref.read(workspaceIntentProvider); if (currentIntent == null || currentIntent.$1 != projectId || currentIntent.$2 != type) { return; } if (ref.read(selectionProvider) != null) return; ref.read(selectionProvider.notifier).selectWorkspace(...` — reachable concretely: `ProjectSessionController.closeProject` runs `ref.read(selectionProvider.notifier).clear();` (project_persistence_providers.dart:160) *synchronously before* `state = const AsyncData(null);` (line 161); the clear notifies `explorerCatalogRecoveryProvider` while the stale session is still non-null, a microtask is scheduled, and it then applies `selectWorkspace` for the just-closed project. The resolver then renders `CharacterWorkspaceScreen`/etc. for an asset of a project with no open database.

---

**void-scriptor-hunt-20260910b BUG-2** | Severity: Medium | Points: 5
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\features\explorer\presentation\explorer_panel.dart
- **Line(s):** 241–263 (with selection_controller.dart:13–14, 21–27)
- **Category:** data-integrity
- **Claim:** Hydration runs exactly once per app lifetime (`_memoryHydrated` on a non-autodispose global controller), so switching projects never loads the new project's persisted selection memory, and the next persistence overwrites the new project's `cache/selection_memory.json` with a snapshot that lacks its previous entries (permanent loss) while polluting it with other projects' entries.
- **Evidence:** `ref.listen(selectionProvider, (_, __) { persistSelectionMemorySnapshotSync(selectionMemoryFileFor(session.package), ...` re-runs per session change, but `void hydrateWorkspaceMemory(SelectionMemorySnapshot persisted) { if (_memoryHydrated) return; _memoryHydrated = true; ...}` (selection_controller.dart:21–23) is a no-op after the first project open; the merged in-RAM map (`workspaceMemorySnapshot()` returns all `(projectId, type)` entries) is then written wholesale into the current project's file via `tmp.renameSync(file.path)` (selection_memory_snapshot.dart:70–71).

---

**void-scriptor-hunt-20260910b BUG-3** | Severity: Medium | Points: 5
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\features\explorer\presentation\explorer_panel.dart
- **Line(s):** 253–262 (comment at 239–240)
- **Category:** error-handling
- **Claim:** The selection-change listener calls the synchronous persist with no try/catch, and `persistSelectionMemorySnapshotSync` performs `createSync`/`writeAsStringSync`/`renameSync` with no internal catch, so any disk failure (full disk, read-only volume, unplugged USB custom storage) throws an uncaught exception out of a Riverpod listener — directly contradicting the code's own contract comment.
- **Evidence:** Comment: "disk failures are swallowed by contract (memory is a convenience, never a blocker) but are observable via debugPrint." Actual listener body: `ref.listen(selectionProvider, (_, __) { persistSelectionMemorySnapshotSync( selectionMemoryFileFor(session.package), ref.read(selectionProvider.notifier).workspaceMemorySnapshot(), ); });` — no try/catch, and selection_memory_snapshot.dart:64–72 contains no try/catch and no debugPrint anywhere.

---

**void-scriptor-hunt-20260910b BUG-4** | Severity: Medium | Points: 5
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\app\shell\desktop\void_desktop_shell.dart
- **Line(s):** 117–131 (with explorer_panel.dart:129–134)
- **Category:** logic
- **Claim:** The desktop top-bar "Projects" button (key `'novels'`) is always intercepted by `explorerAssetTypeForMenu` → `AssetType.story`, so with an active session it focuses the Novel workspace instead of opening the projects list, making the `'novels' => AppRoutes.projects` switch entry unreachable dead code.
- **Evidence:** `final assetType = explorerAssetTypeForMenu(menu); if (assetType != null) { ... focusExplorerAsset(ref, assetType); context.push(AppRoutes.workspace); return; }` precedes `final route = switch (menu) { ... 'novels' => AppRoutes.projects, ...}`; and explorer_panel.dart:130 maps `'story' || 'novels' => AssetType.story`, so `assetType` is never null for `'novels'` (the top bar's only projects-like destination — void_top_bar.dart:59–66 filters to dashboard/novels/search).

---

**void-scriptor-hunt-20260910b BUG-5** | Severity: Medium | Points: 5
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\features\workspace\presentation\workspace_resolver.dart
- **Line(s):** 120–153
- **Category:** data-integrity
- **Claim:** `ProjectOverview.onCreateNovel` never invalidates `storyExplorerProvider`, so a novel created from the overview's "Create Novel" button never appears in the Explorer's novel list (unlike the identical creation flow in explorer_panel.dart:1061, which does invalidate it).
- **Evidence:** `ref.read(selectionProvider.notifier).select(SelectionModel(assetId: storyId, assetType: AssetType.story, projectId: session.manifest.id)); ref.invalidate(projectAssetsProvider);` — `storyExplorerProvider` (explorer_panel.dart:102–111) is invalidated nowhere in this path; the comment even cites hunt-run157 BUG-05 for the `projectAssetsProvider` invalidation but omits the explorer catalog.

---

**void-scriptor-hunt-20260910b BUG-6** | Severity: Medium | Points: 5
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\features\workspace\presentation\workspace_resolver.dart
- **Line(s):** 570–620 (state at 508–514, load at 528–568)
- **Category:** logic
- **Claim:** `_createFaction` never reloads `_factions` (and nothing invalidates `_WorldbuildingBodyState`'s cached lists), so after "Create Faction" the new faction is selected but never appears in the Factions list because the resolver's faction branch reuses the same `ValueKey('wb-<projectId>')` state.
- **Evidence:** `final faction = await const CreateFactionService().create(...); ref.read(selectionProvider.notifier).select(SelectionModel(assetId: faction.assetId, assetType: AssetType.faction, ...));` — no `_load()` call, no state reset; `_factions` is only assigned inside `_load()` (line 554), which runs once via `ref.listenManual(... fireImmediately: true)` in initState (lines 521–525).

---

**void-scriptor-hunt-20260910b BUG-7** | Severity: Medium | Points: 5
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\app\shell\mobile\void_mobile_shell.dart
- **Line(s):** 103–107
- **Category:** logic
- **Claim:** The `requiresProject` guard checks the route parameter `widget.projectId` (null on the `/workspace` route, which builds `VoidAppShell(onLogout:)` without a projectId) instead of the live `projectSessionProvider`, so tapping Characters/World with an open project wrongly pushes the Projects list.
- **Evidence:** `if (destination.requiresProject && widget.projectId == null) { context.push(AppRoutes.projects); return; }` — but `widget.projectId` is only non-null on `/studio/:projectId` (app_router.dart:301–302); on `AppRoutes.workspace` (app_router.dart:406–407) it is null while `projectSessionProvider` still holds the open session, so the character/world `focusExplorerAsset` calls at lines 108–112 are never reached.

---

**void-scriptor-hunt-20260910b BUG-8** | Severity: Medium | Points: 5
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\features\explorer\presentation\explorer_panel.dart
- **Line(s):** 301–308
- **Category:** error-handling
- **Claim:** Catalog recovery treats a failed catalog the same as "still loading" (`ids == null` → wait), and since a failed FutureProvider never re-emits until invalidated, a transient DB error permanently strands the typed intent with no retry surface for character/story/environment (creature is the only type with a retry UI, via `_CreatureEmptyState`).
- **Evidence:** `final ids = idsOf(catalog); if (ids == null || ids.isEmpty) { // Still loading, failed, or nothing to select: keep waiting; ... return; }` — nothing in the codebase invalidates `characterControllerProvider`/`storyExplorerProvider`/`environmentExplorerProvider` on error, and re-tapping the explorer header re-reads the same cached error (`focusExplorerAsset` line 181/185/191 uses `.valueOrNull` → null → `restore(null)` keeps waiting).

---

**void-scriptor-hunt-20260910b BUG-9** | Severity: Medium | Points: 5
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\features\explorer\presentation\explorer_panel.dart
- **Line(s):** 1044–1060, 1137–1147 (same pattern in workspace_resolver.dart:121–141)
- **Category:** data-integrity
- **Claim:** Story creation is a three-step non-transactional sequence (story → chapter → scene) inside a catch-all that only shows a snackbar, so a failure after `createStory` leaves an orphaned story row and the user's retry creates a duplicate story.
- **Evidence:** `assetId = await service.createStory(projectId: projectId, title: name); final chapterId = await service.createChapter(...); await service.createScene(...);` followed by `} catch (_) { ... SnackBar(content: Text('Aset gagal dibuat. ...'))` — no rollback/compensation of the already-created story; `createExplorerAsset` can be re-run freely.

---

**void-scriptor-hunt-20260910b BUG-10** | Severity: Low | Points: 1
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\features\explorer\presentation\explorer_panel.dart
- **Line(s):** 90–100, 102–111
- **Category:** performance
- **Claim:** `supportingAssetExplorerProvider` and `storyExplorerProvider` load the entire assets table (`getAllAssets()`) and filter client-side, once per family instance, instead of a type/project-scoped query.
- **Evidence:** `return (await session.database.assetDao.getAllAssets()).where((asset) => asset.projectId == key.$1 && asset.type == key.$2.name).toList(growable: false)..sort(...)` — full-table fetch repeated for armor, accessory, and story instances on every rebuild after invalidation.

---

**void-scriptor-hunt-20260910b BUG-11** | Severity: Low | Points: 1
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\features\explorer\presentation\explorer_panel.dart
- **Line(s):** 1301–1312
- **Category:** edge-case
- **Claim:** Dismissing the filter dialog without pressing anything (barrier tap / back button returns `null`) clears the active filter exactly like the explicit "Reset" button, silently discarding the user's filter.
- **Evidence:** `if (applied == true) { _role = role; ... } else { _role = null; _importance = null; _pov = null; }` — `applied` is `Future<bool>?` from `showDialog<bool>`, null on dismissal.

---

**void-scriptor-hunt-20260910b BUG-12** | Severity: Low | Points: 1
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\features\explorer\presentation\explorer_panel.dart
- **Line(s):** 1326–1347, 1401–1428
- **Category:** edge-case
- **Claim:** With an active narrative filter, while `explorerNarrativeAssignmentsProvider` is still loading, the character list is filtered against an empty assignment list and renders zero tiles with no loading indicator (distinct from the handled error path).
- **Evidence:** `final usableAssignments = assignments.valueOrNull ?? const [];` → `filtered = characters.where((item) => filter.matchesCharacter(characterId: item.assetId, assignments: usableAssignments), )` matches nobody while loading; the `data:` branch then renders `(filtered ?? items)` = `[]`.

---

**void-scriptor-hunt-20260910b BUG-13** | Severity: Low | Points: 1
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\features\explorer\presentation\explorer_panel.dart
- **Line(s):** 114, 140, 486, 503
- **Category:** edge-case
- **Claim:** `explorerAssetFocusProvider` is set on focus but never cleared or project-guarded on project switch, so the "focused" group highlight leaks into a different project's explorer.
- **Evidence:** `ref.read(explorerAssetFocusProvider.notifier).state = type;` with no reset anywhere; `focused: focusedType == AssetType.story` / `focused: focusedType == AssetType.character` compare the stale global state after `projectSessionProvider` changes.

---

**void-scriptor-hunt-20260910b BUG-14** | Severity: Low | Points: 1
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\features\explorer\presentation\explorer_panel.dart
- **Line(s):** 901–908, 1030–1034
- **Category:** error-handling
- **Claim:** `_configureSidebarModules` and `createExplorerAsset` call `ref.read(...)` after awaiting dialogs without any mounted guard, so if the ExplorerPanel unmounts while the dialog is open (project close/switch), the disposed WidgetRef throws.
- **Evidence:** After `final result = await showDialog<ProjectSidebarModulePreferences>(...)`: `final session = ref.read(projectSessionProvider).valueOrNull;` (line 902) with only a later `context.mounted` check (line 910); same pattern in `createExplorerAsset` after its dialog: `final paths = ref.read(projectPathsProvider);` (line 1033).

---

**void-scriptor-hunt-20260910b BUG-15** | Severity: Low | Points: 1
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\features\explorer\application\project_sidebar_module_preferences.dart
- **Line(s):** 236–260, 308–321
- **Category:** logic
- **Claim:** Genre matching uses raw substring containment without word boundaries, producing false-positive module recommendations (e.g. 'live-action'/'interactive fiction' contain 'action' → weapons; 'warehouse' contains 'war' → War/Military profile).
- **Evidence:** `if (normalized.contains(alias) && alias.length > bestLength) { best = entry.value; ... }` and `bool matches(Set<String> terms) => normalized.any((genre) => terms.any(genre.contains));`

---

**void-scriptor-hunt-20260910b BUG-16** | Severity: Low | Points: 1
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\features\workspace\presentation\workspace_resolver.dart
- **Line(s):** 288–291 (with explorer_panel.dart:144)
- **Category:** logic
- **Claim:** `_opensWorldbuildingCollection` omits `'Locations'`, so a restored environment selection with `activeSection == 'Locations'` (the exact section `focusExplorerAsset` activates for environments) bypasses the Locations collection view and lands directly on `EnvironmentWorkspaceScreen`.
- **Evidence:** `bool _opensWorldbuildingCollection(String? section) => switch (section) { 'Factions' || 'Relationships' || 'Timeline' || 'Lore Notes' => true, _ => false };` versus `AssetType.environment => (WorkspaceKind.worldbuilding, 'Locations')` in explorer_panel.dart:144.

---

**void-scriptor-hunt-20260910b BUG-17** | Severity: Low | Points: 1
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\features\workspace\presentation\workspace_resolver.dart
- **Line(s):** 53–62, 180–284
- **Category:** edge-case
- **Claim:** The resolver's selection branch has no "session is open" guard — with `session == null` and a non-null selection it renders `CharacterWorkspaceScreen`/`StoryWorkspaceScreen` etc. for a project with no active database (all session-derived params forced to null).
- **Evidence:** `if (selection == null || (session != null && selection.projectId != session.manifest.id))` — when `session == null` and `selection != null` the condition is false and control falls to `return switch (selection.assetType) { AssetType.character => CharacterWorkspaceScreen(characterId: selection.assetId, ...` — reached directly via BUG-1's race.

---

**void-scriptor-hunt-20260910b BUG-18** | Severity: Low | Points: 1
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\features\explorer\presentation\explorer_panel.dart
- **Line(s):** 188–194 (unused from UI), 516–530, 656–664
- **Category:** logic
- **Claim:** The newly added creature sync-restore branch in `focusExplorerAsset` is unreachable from the panel because `_CreatureGroup` (unlike Story/Character/Environment groups) exposes no `onFocused`/`focused`, so tapping the Creatures header never focuses or restores creature selection memory.
- **Evidence:** `_CreatureGroup(creatures: creatures, selectedId: ..., onSelected: ...)` — no `onFocused:` argument; class declaration `_CreatureGroup({required this.creatures, required this.selectedId, required this.onSelected})` lacks the fields, while `EnvironmentGroup(onFocused: () => focusExplorerAsset(ref, AssetType.environment), ...)` has them.

---

**void-scriptor-hunt-20260910b BUG-19** | Severity: Low | Points: 1
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\features\explorer\presentation\explorer_panel.dart
- **Line(s):** 158–172 (with selection_controller.dart:56–64)
- **Category:** data-integrity
- **Claim:** The synchronous focus-restore path calls `selectWorkspace` with an empty loaded catalog, which deletes the per-workspace memory key and persists the wipe — contradicting the recovery provider's deliberate "never write on empty catalog" contract and permanently destroying remembered selection for that workspace.
- **Evidence:** `restore(environments?.map((item) => item.assetId))` with a loaded-but-empty list → `selectWorkspace(..., availableAssetIds: [])` → `if (id == null) { _workspaceSelections.remove(key); clear(); return; }` (selection_controller.dart:61–63), then the persistence listener writes the reduced snapshot to disk; meanwhile recovery's comment at explorer_panel.dart:303–307 explicitly refuses to act on empty catalogs.

---

**void-scriptor-hunt-20260910b BUG-20** | Severity: Low | Points: 1
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\features\explorer\presentation\explorer_panel.dart
- **Line(s):** 412–423 (with project_sidebar_module_preferences.dart:331–371)
- **Category:** error-handling
- **Claim:** A `projectSidebarModulePreferencesProvider` failure (load() only catches `FormatException`; IO/DB errors propagate) is silently masked by the `valueOrNull ?? const ProjectSidebarModulePreferences(...)` fallback with no error surface or retry, leaving the user stuck with default modules until an unrelated invalidation.
- **Evidence:** `: ref.watch(projectSidebarModulePreferencesProvider(projectId)).valueOrNull ?? const ProjectSidebarModulePreferences(factions: false, relationshipMap: true)` — no `hasError` branch, unlike the narrative-assignments error handling in the same file (lines 1318–1400).

---

**TOTAL FINDINGS:** 20
**TOTAL SCORE:** 56
