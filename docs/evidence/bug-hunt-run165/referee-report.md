# REFEREE REPORT — run165 (void-scriptor-hunt-20260910, workspace region)

**Method:** All 5 in-scope files read in full. Every quoted location re-verified. Cross-file claims checked independently: `project_persistence_providers.dart`, `selection_controller.dart`, `explorer_panel.dart` (recovery provider + `createExplorerAsset`), `void_desktop_shell.dart`, `void_app_shell.dart`, `asset_dao.dart`, `create_story_service.dart`, `create_faction_service.dart`, `faction_repository.dart`, `crash_diagnostics.dart`, `asset_browser_screen.dart`, `character_mode_section.dart`, `dashboard_screen.dart`, drift 2.34.3 backend source (pub cache). Read-only; nothing modified.

---

**BUG-01** — search race in `_GlobalSearchSheet._runSearch`
- **Hunter's claim:** Overlapping `_runSearch` calls resolve out of order; stale results overwrite newer ones (Medium).
- **Skeptic's response:** UPHELD (no token, button not disabled, 88% real).
- **Analysis:** The missing token is real, but the *out-of-order overwrite* is structurally excluded on the shipping backend. `project_database_platform_io.dart:9` uses `NativeDatabase(File(...))` — drift's in-main-isolate backend (only `createInBackground` spawns an isolate; drift 2.34.3 source verified). Each `search()` does two sequential awaits (`getAllAssets`, `listForProject`) through one FIFO channel (synchronous delegate / lock, `engines.dart` `_synchronized`). By induction, request A enqueues each of its queries before B does, completions and microtask continuations follow FIFO, so `setState` order matches press order — the newer search always wins, regardless of timing. The only ordering break is `search('')`'s synchronous early return (launcher:43), which requires a cleared-field press landing while a prior search is still mid-flight — physically implausible for sub-millisecond local SQLite, and only cosmetic even then. Runtime race claim with no runtime evidence, and the code itself disproves the mechanism.
- **VERDICT: NOT A BUG** (as claimed)
- **Confidence:** Medium
- **Note:** A request token + skipping empty queries is still cheap hardening (protects against a future `createInBackground`/WAL backend switch).

**BUG-02** — faction search hit performs no navigation
- **Analysis:** Verified: exactly two production callsites (`workspace_resolver.dart:147-151`, `void_desktop_shell.dart:154-160`), both omit `onSelectFaction`. `_openHit` (sheet:65-70): `assetType == null` → pop + `widget.onSelectFaction?.call` → no-op. The sheet's own header comment (lines 2-4) promises faction navigation. Skeptic's rejection of the id-semantics side-claim is correct: `faction.assetId` is the app-wide identifier used consistently (resolver:503, 591). Note: `hair_variant` rows (producible via character mode) also map to `assetType: null` in the launcher and hit the same no-op path — the fix should account for null-type rows generally.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Wire `onSelectFaction` at both callsites (e.g., write `SelectionModel(assetId: faction.assetId, assetType: AssetType.faction, projectId)` — the resolver already handles faction selections at lines 183-192), and route null-type non-faction rows (e.g. `hair_variant`) to a sane fallback instead of the faction callback.

**BUG-03** — `onCreateNovel` stale-session writes / mis-filing
- **Analysis:** Skeptic is right. The captured `session` pins all writes to the project the novel belongs to — the correct destination; a switch cannot retarget them. If the old DB closes mid-chain the writes throw (that is BUG-04's silent-failure claim, filed separately). The trailing selection write (resolver:130-138) is inert after a switch: `_releaseForeignSelection` (project_persistence_providers.dart:168-173) clears foreign selections on every open (runs *before* `AsyncLoading`, line 118-119), and resolver:62 / panel:26 guard intents by project id. Verified no other harm path.
- **VERDICT: NOT A BUG**
- **Confidence:** High

**BUG-04** — novel-creation chain has no error handling
- **Analysis:** Verified. `onCreateNovel` (resolver:110-143) has no try/catch; `ProjectOverview._createNovel` (277-308) shows 'Novel created.' unconditionally after the await. An exception propagates out of the unawaited button callback to `PlatformDispatcher.instance.onError` (crash_diagnostics.dart:231-234, logs and returns true) — no crash, but zero user feedback. Partial state confirmed in `create_story_service.dart`: `createStory` commits story rows transactionally (and cleans its directories), but `createChapter`/`createScene` are separate untracked inserts — a failure there strands a chapter-less/scene-less story. Contradicts the region's own "persist failure visibly" contract.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Wrap the chain in try/catch and show a failure snackbar (mirror `_createFaction`'s catch); consider making story+chapter+scene one transaction, or compensating cleanup of the story rows on failure.

**BUG-05** — creature intent renders generic WorldbuildingBody, no recovery
- **Analysis:** Verified end-to-end. `_isWorldbuildingIntent` includes `AssetType.creature` (resolver:376) → intent path (99-105) renders `WorldbuildingBody`, whose build (516-670) renders only Factions/Timeline/Lore/Locations/Relations — no creature data. `workspaceIntentProvider` is written only in `selection_controller.dart` (38, 71) and never reset on project switch (`_releaseForeignSelection` clears only the selection; `closeProject` same). Recovery provider handles only character/story/environment (`explorer_panel.dart:280-289`, `default: return`). Meanwhile the panel header via `forAssetType(creature)` shows "Creature Workspace" with Profile/Anatomy/Abilities/Modes/Ecology tabs (workspace_panel:277-284, 336) — and clicking those tabs leaves every WorldbuildingBody section hidden. User is stranded until they manually re-pick a creature in the Explorer.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Add creature to `explorerCatalogRecoveryProvider` (creature catalog + workspace-memory id restore) or render `CreatureWorkspaceScreen` from a creature intent; alternatively exclude creature from `_isWorldbuildingIntent` and show an explicit empty-state CTA so header and body agree.

**BUG-06** — `_linkCharacterToNovel` writes link into detached project
- **Analysis:** Skeptic is right. The link's target novel belongs to the captured session's project; writing there is correct even after a switch. If the old DB is closed, the write throws and is caught (resolver:875-880) with a visible 'Link gagal dibuat' snackbar (mounted-guarded). No mis-filing path exists.
- **VERDICT: NOT A BUG**
- **Confidence:** High

**BUG-07** — `_createFaction` selects after await without re-validation
- **Analysis:** The code is as quoted (no re-check after `create`, resolver:493-507), but no reachable harm: (1) there is no `await` between create completing and the synchronous `select()` (498-507), so no interleaving can split them; (2) if the switch happens first, the create throws and is caught (silent only because `mounted` is false after the switch — the user abandoned the flow); (3) if the select lands first, `_releaseForeignSelection` clears it on the switch and every intent consumer guards by project id (resolver:62, panel:26). The faction itself is created in the correct (original) project DB. Net harm in both orderings: none — cosmetic at most in a sub-second window. It is a code-smell (inconsistent with `createExplorerAsset`'s own session re-validation, explorer_panel:1113-1116), not a defect.
- **VERDICT: NOT A BUG**
- **Confidence:** Medium
- **Note:** Adding the same `valueOrNull != session` re-validation used by `createExplorerAsset` would be a cheap consistency fix, but it fixes no user-visible behavior.

**BUG-08** — search sheet keeps searching stale project database
- **Analysis:** Skeptic is right. The search executes entirely within the open modal window — unlike BUG-03/04/07 there is no post-dialog phase. No keyboard binding, deep link (`app_links` absent from pubspec), or programmatic path can switch projects under the barrier (verified all `openProject` callsites: `void_app_shell.dart:80`, `project_exit_guard.dart:42` close-only). If it somehow happened, the closed DB makes `search()` throw — `_runSearch` has no catch, the exception is logged by the global handler, `_hits` unchanged; and `search()` filters rows by `projectId` (launcher:48) anyway. No silent wrong-project results.
- **VERDICT: NOT A BUG**
- **Confidence:** High

**BUG-09** — unhandled selection type dead-ends on bare overview
- **Analysis:** Mechanism verified: the fallback overview (254) gets no `onCreateNovel`/`onOpenGlobalSearch`/key, versus the wired instance at 106-153. Hunter's examples are wrong: the only production writers of `Assets` type strings are story/character/wardrobe/weapon/prop/creature/environment services, `CreateVfxService` (zero UI callsites), and `AssetDao.createStandaloneAsset` (validated set: wardrobe/weapon/armor/accessory/hair_variant/prop/creature/vehicle — asset_dao.dart:56-65); `saveAsset` has zero callers; scenes/prompts/references go to other tables. **`vehicle` is producible**: Asset Browser create dialog offers it (asset_browser_screen.dart:627) and `_select` (542-550) writes a vehicle `SelectionModel`; the search sheet also yields vehicle hits. Resolver has no vehicle case → bare overview, while the panel header shows "Asset Workspace" (`forAssetType` default). Recoverable dead-end, needs an odd asset type first.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Handle `AssetType.vehicle` in the resolver switch (route to `SupportingAssetWorkspaceScreen` or a dedicated vehicle screen), or exclude vehicle from selectable/searchable types until a workspace exists.

**BUG-10** — faction search branch bypasses `types` filter
- **Analysis:** Hunter misread. With `types = {character}`: `isEmpty` false, `contains(faction)` false → faction branch skipped entirely. Identical gate semantics to the assets loop (line 50). No bypass.
- **VERDICT: NOT A BUG**
- **Confidence:** High

**BUG-11** — sort non-determinism across runs
- **Analysis:** Skeptic is right. Dart's `List.sort` is unstable but deterministic for a given input list and comparator. Input order is stable: full-table scan in rowid order (assets) and `ORDER BY name` (faction_repository.dart:85-90). Order is reproducible across runs for identical DB state; the comparator implements exactly the documented contract (launcher header, lines 4-6: exact > prefix > substring, lalu abjad). Residual tie-order among case-variant duplicate titles is cosmetic, not a defect.
- **VERDICT: NOT A BUG**
- **Confidence:** High

**BUG-12** — panel shows wrong workspace header while `projectId == null`
- **Analysis:** Skeptic is right, and each state was verified: (1) `_releaseForeignSelection` runs *before* `state = AsyncLoading()` (project_persistence_providers.dart:118-119); (2) `closeProject` clears the selection before `state = AsyncData(null)` (158-161); (3) cold start has no selection (`build() => null`); (4) open-failure (`AsyncError`) states cleared first; (5) a same-project re-open with same mode returns early (100-102) without ever entering `AsyncLoading`, so a same-project selection never survives a null-project window; (6) no `invalidate`/`refresh` of `projectSessionProvider` exists anywhere. With selection null and `intent?.$1 == null-projectId` false, the header falls to the neutral Novel Workspace default, matching `_EmptyWorkspace`. The short-circuit is dead-permissive code, not a reachable defect.
- **VERDICT: NOT A BUG**
- **Confidence:** High

---

## VERIFIED BUG REPORT

Stats:
- Total reported by Hunter: 12
- Dismissed as false positives: 8 (BUG-01, 03, 06, 07, 08, 10, 11, 12)
- Confirmed as real bugs: 4 (BUG-02, 04, 05, 09)
- Critical: 0 | Medium: 3 | Low: 1

Confirmed bugs (ordered by severity):

| # | Severity | File | Line(s) | Description | Suggested Fix |
|---|----------|------|---------|-------------|---------------|
| BUG-02 | Medium | global_search_sheet.dart (+ 2 callsites) | 65-70; resolver 147-151; desktop shell 154-160 | Faction search hit pops the sheet and performs no navigation — `onSelectFaction` never passed in any production entry point, contradicting the sheet's documented contract | Wire faction selection (SelectionModel with `AssetType.faction`) at both callsites; handle null-type non-faction rows (hair_variant) hitting the same path |
| BUG-04 | Medium | workspace_resolver.dart | 110-143, 277-308 | Novel-creation chain has no error handling: persist failure is invisible (global handler only) and leaves a story without Chapter 1/Scene 1; 'Novel created.' snackbar skipped | try/catch + failure snackbar; make story+chapter+scene atomic or add compensating cleanup |
| BUG-05 | Medium | workspace_resolver.dart (+ panel, recovery provider) | 99-105, 372-381; panel 277-284; explorer 280-289 | Creature intent renders generic WorldbuildingBody (no creature data, tabs render nothing) while the panel header advertises "Creature Workspace"; intent survives project switches, no creature recovery path | Add creature to catalog recovery or render CreatureWorkspaceScreen from intent; align header/body |
| BUG-09 | Low | workspace_resolver.dart | 254 | Unhandled `vehicle` selection (producible via Asset Browser + search sheet) dead-ends on a callback-less `ProjectOverview` while the header shows "Asset Workspace" | Handle vehicle in the resolver switch or exclude it from selectable types |

Low-confidence items (flagged for manual review):
- **BUG-01 (NOT A BUG, Medium confidence):** dismissal rests on verified drift 2.34.3 internals (in-main-isolate `NativeDatabase`, FIFO ordering through one channel) proving the claimed out-of-order overwrite structurally excluded; if the project ever moves to `createInBackground`/WAL read-pool or the web backend, revisit. A request token remains cheap hardening.
- **BUG-07 (NOT A BUG, Medium confidence):** dismissal rests on the no-await atomicity of the select block plus the foreign-selection release and project-id guards; a `valueOrNull != session` re-validation would match `createExplorerAsset`'s convention but changes no user-visible behavior.

**Verdict summary vs. inputs:** Referee confirms the Skeptic's disprovals (all 6) and confirms BUG-02/04/05/09 as real, but overturns the Skeptic on two of its upheld items: **BUG-01** (race mechanism unreachable on the shipping backend — downgraded to a hardening note) and **BUG-07** (missing re-validation has no reachable harm). Final: **REAL BUG 4 (BUG-02, 04, 05, 09) · NOT A BUG 8 (BUG-01, 03, 06, 07, 08, 10, 11, 12).**
