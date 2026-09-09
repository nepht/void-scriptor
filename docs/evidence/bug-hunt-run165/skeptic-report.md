# SKEPTIC REPORT — run165 adversarial bug hunt (Void Scriptor workspace region)

- Hunt: void-scriptor-hunt-20260910 (cron run165) · Repo HEAD verified `51ca455` (master). Read-only throughout: read_file / search_files / `git log --show` only. No files created or modified; dirty theme region untouched.
- Method: all 5 in-scope files read fully; every quoted location re-read in source. Supporting reads: selection_controller/model, project_persistence_providers, explorer_panel (recovery provider + creature creation), void_app_shell/void_desktop_shell, app_router, create_story_service, create_faction_service, create_novel_character_link_service, faction_repository, asset_dao, drift_asset_repository, asset_browser_screen, character_mode_controller, crash_diagnostics, project_session_manager, plus searches for all `openProject` callsites, all keyboard shortcuts, deep links, and every writer to the `Assets` table.

---

**BUG-01** | Original: 5 pts — search race in `_GlobalSearchSheet._runSearch`
- **Counter-argument:** None found. The code matches the quote exactly (global_search_sheet.dart 56–63): no request token, `mounted` is the only guard, and the `FilledButton` (line 115) is never disabled during flight. Two overlapping searches can complete out of order and the stale `_hits` overwrite is real.
- **Confidence:** 88% real.
- **Decision:** UPHELD.

**BUG-02** | Original: 5 pts — faction hit performs no navigation
- **Counter-argument:** Core claim verified: both production callsites omit `onSelectFaction` (workspace_resolver.dart 144–152 and void_desktop_shell.dart 154–160 — confirmed by repo-wide search; no other callers exist). A faction hit (assetType null) pops the sheet and calls a null callback → pure no-op, contradicting the sheet's own doc comment. However, the sub-claim about `faction.assetId` semantics is wrong: `assetId` is the app-wide faction identifier used consistently everywhere (resolver `_createFaction` line 503, WorldItem line 591), so "any future consumer assuming the PK" is speculative.
- **Confidence:** 85% real (core); id-semantics side-claim rejected.
- **Decision:** UPHELD WITH CAVEAT.

**BUG-03** | Original: 5 pts — `onCreateNovel` stale-session writes / mis-filing
- **Counter-argument:** The claimed harm mechanism is incorrect. The captured `session` pins writes to the project the user was working in when they clicked Create Novel — that is the **correct destination**, not a mis-filing. A project switch cannot retarget the writes into another project's database; worst case the old DB is closed mid-chain and the writes **throw** (silent failure — which is exactly BUG-04, separately filed and upheld). The trailing selection write for the old project is inert: resolver lines 60–62 guard by `session.manifest.id`, and `_releaseForeignSelection` (project_persistence_providers.dart:118,168–173) clears foreign selections on every open. Note the Hunter's own precedent (337b821) guards the *opposite* pattern — live-session reads that mis-file into the new project; captured-session writes here already prevent that. Trigger-wise, the title dialog is modal (blocks navigation) and no keyboard/deep-link switch path exists; only a sub-second post-dialog race remains.
- **Confidence:** 74% not a real bug as claimed.
- **EV:** (74% × 5) − (26% × 10) = +1.1
- **Decision:** DISPROVEN (data-integrity/mis-filing framing wrong; residual silent-failure is BUG-04's claim).

**BUG-04** | Original: 5 pts — no error handling on novel-creation chain
- **Counter-argument:** None found. `onCreateNovel` (resolver 110–143) has no try/catch; `_createNovel` awaits it then shows 'Novel created.' unconditionally on success of the await — any throw skips the snackbar and propagates to the global `PlatformDispatcher.instance.onError` logger (crash_diagnostics.dart:231–234), so no crash but zero user feedback. Partial state is real: `createStory` commits story+stories transactionally but Chapter 1/Scene 1 are separate awaits, and even a directory-creation failure only deletes folders and rethrows — the story rows remain.
- **Confidence:** 88% real.
- **Decision:** UPHELD.

**BUG-05** | Original: 5 pts — creature intent renders generic WorldbuildingBody, no recovery
- **Counter-argument:** None found; the full chain verifies. `_isWorldbuildingIntent` includes `AssetType.creature` (resolver 376) → creature intent (no assetId) renders generic `WorldbuildingBody` (100–105), which renders only Factions/Timeline/Lore/Locations/Relations — no creature data. Intent `(projectId, creature)` is written by `SelectionController.select` (selection_controller.dart:38–43) and never cleared on switch (only selection is cleared — `_releaseForeignSelection`; `workspaceIntentProvider` has no reset). Re-entering the project: recovery provider's switch handles only character/story/environment (`default: return;`, explorer_panel.dart:280–289), so the remembered creature is never restored; meanwhile WorkspacePanel's header via `forAssetType(creature)` advertises "Creature Workspace" with Profile/Anatomy/Abilities/Modes/Ecology tabs (workspace_panel.dart 277–284, 336). Header/body mismatch confirmed; the panel is even worse than claimed — clicking a creature tab leaves every WorldbuildingBody section hidden. The user can recover only by manually re-picking a creature in the Explorer.
- **Confidence:** 92% real.
- **Decision:** UPHELD.

**BUG-06** | Original: 5 pts — `_linkCharacterToNovel` writes link into detached project
- **Counter-argument:** Writing with the captured session is correct here, not harmful: the novel being linked belongs to the captured session's project, so the service targets the link's own project database — the right destination even if the user has since switched. If the old DB is already closed, the write throws and is **caught** (resolver 875–880) with a visible 'Link gagal dibuat' snackbar — a visible failure, not silent corruption. The title "writes the link into the detached project" describes correct behavior (that detached project *is* the novel's project). Trigger is a sub-second post-dialog race at best.
- **Confidence:** 78% not a real bug.
- **EV:** (78% × 5) − (22% × 10) = +1.7
- **Decision:** DISPROVEN.

**BUG-07** | Original: 1 pt — `_createFaction` selects after await without re-validation
- **Counter-argument:** Code verified as quoted (resolver 492–513): no project re-check after `CreateFactionService().create`, and the creation itself goes to the correct (original) project. The claimed residual harm is thin — a foreign selection is guarded at resolver 60–61 and released on the next open; the intent write is guarded at line 62 — so the practical effect in the tight post-dialog race window is negligible. But the missing re-validation is real code, the race is not strictly impossible (dialog closes before the await), and at 1 point the EV math favors accepting.
- **Confidence:** 70% real (borderline).
- **Decision:** UPHELD (Low).

**BUG-08** | Original: 1 pt — search sheet keeps searching stale project database
- **Counter-argument:** The factual observations are true (constructor-captured `launcher`/`projectId`, no provider watch), but the trigger cannot occur: staleness requires the session to change **while the modal sheet is open**, and the sheet's barrier blocks all navigation for its entire lifetime. Unlike BUG-03/06/07 (dialog closes before its awaits, leaving a race window), the search executes entirely within the open modal window — there is no unprotected phase. No keyboard shortcut, deep link, or programmatic switch trigger exists (verified: all `openProject` callsites, all `SingleActivator` bindings, no `app_links`). If a switch somehow occurred, the old DB is closed and the search throws (logged, list simply unchanged) — no silent wrong-project results are returned, since `search` filters rows by `projectId` anyway (launcher line 48).
- **Confidence:** 80% not a real bug.
- **EV:** (80% × 1) − (20% × 2) = +0.4
- **Decision:** DISPROVEN.

**BUG-09** | Original: 1 pt — unhandled selection type dead-ends on bare overview
- **Counter-argument:** The mechanism is real but the examples are wrong. Resolver line 254 `_ => const ProjectOverview()` is confirmed: callback-less, key-less. However, `scene`, `prompt`, and `reference` are **not producible** in the `Assets` table: the only production writers are `createStory` ('story'), `CreateCharacterService` ('character'), and `AssetDao.createStandaloneAsset` (validated set: wardrobe/weapon/armor/accessory/hair_variant/prop/creature/vehicle — asset_dao.dart:56–70); `DriftAssetRepository.saveAsset` has zero production callers, and the AssetBrowser create dialog offers exactly the standalone set. The producible unhandled enum type is **vehicle**: user creates it in the Asset Browser (or picks it from the search sheet) → `_select` writes `SelectionModel(type: vehicle)` → resolver falls to bare `ProjectOverview()` while the panel header shows "Asset Workspace".
- **Confidence:** 85% real (core mechanism); examples corrected.
- **Decision:** UPHELD WITH CAVEAT (dead-end exists via `vehicle`; cited types scene/prompt/reference are unreachable).

**BUG-10** | Original: 1 pt — faction branch bypasses `types` filter
- **Counter-argument:** The Hunter misread the condition. `if (types.isEmpty || types.contains(AssetType.faction))` **enforces** the filter, exactly mirroring the Assets loop semantics: with `types = {character}`, `contains(faction)` is false and the faction branch is skipped entirely. Faction hits return only when no filter is requested or factions are requested — identical to every other branch. There is no bypass.
- **Confidence:** 97% not a real bug.
- **EV:** +0.91
- **Decision:** DISPROVEN.

**BUG-11** | Original: 1 pt — sort non-determinism across runs
- **Counter-argument:** Factually incorrect on the key claim. Dart's `List.sort` is unstable but **deterministic** for a given input list. Input order is stable too: Assets come from a full-table scan (rowid order, stable for a given DB state) and factions are explicitly `ORDER BY name` (faction_repository.dart:85–90). So the result order is deterministic across runs, not random. The comparator implements exactly the documented contract in the file header. Residual concern is a cosmetic tie-order among case-variant duplicate titles — not a defect against the stated contract.
- **Confidence:** 74% not a real bug.
- **EV:** +0.22
- **Decision:** DISPROVEN.

**BUG-12** | Original: 1 pt — panel shows wrong workspace header while `projectId == null`
- **Counter-argument:** The `projectId == null` short-circuit exists in code, but every reachable `projectId == null` state has a **null selection**, so no foreign header can render: (1) `_releaseForeignSelection` runs *before* `state = const AsyncLoading()` (project_persistence_providers.dart:118–119); (2) `closeProject` clears selection too (line 160); (3) cold start has no selection; (4) open-failure states clear it first as well; (5) while a session stays open, `projectId` is that session's id, not null. With selection null the header falls through the intent check (`intent?.$1 == projectId` is `String == null` → false) to the neutral Novel Workspace default, matching the `_EmptyWorkspace` body.
- **Confidence:** 78% not a real bug.
- **EV:** +0.34
- **Decision:** DISPROVEN.

---

**SUMMARY:**
- Bugs disproved: 6 (BUG-03, 06, 08, 10, 11, 12 — 14 points claimed)
- Bugs upheld as real: 6 (BUG-01, 02, 04, 05, 07, 09 — 22 points)
- Skeptic final score: **+14**

**VERDICT COUNTS: UPHELD 4 (BUG-01, 04, 05, 07) · UPHELD WITH CAVEAT 2 (BUG-02, 09) · DISPROVEN 6 (BUG-03, 06, 08, 10, 11, 12)**

**ACCEPTED BUG LIST (for fixing):**
- BUG-01 (Medium) — search-sheet race: add a request token to `_runSearch`, disable the button in flight.
- BUG-02 (Medium) — faction hit is a dead no-op: wire `onSelectFaction` at both callsites (id-semantics side-claim rejected).
- BUG-04 (Medium) — novel-creation chain: wrap in try/catch, show failure feedback; consider making chapter/scene creation atomic with the story.
- BUG-05 (Medium) — creature intent → generic WorldbuildingBody + header/body mismatch: add creature to recovery or render `CreatureWorkspaceScreen` from intent.
- BUG-07 (Low) — `_createFaction` post-await selection: re-validate project before selecting.
- BUG-09 (Low) — resolver `_` fallback renders a callback-less overview for `vehicle` selections (vehicle is producible via AssetBrowser + search sheet; scene/prompt/reference are not).

**Notes for the referee/parent:** Recurring Hunter weaknesses this run: (1) mis-reading filter conditions (BUG-10), (2) claiming nondeterminism from an unstable-but-deterministic sort (BUG-11), (3) data-integrity framing for captured-session writes that actually target the correct project (BUG-03/06), and (4) examples of "producible" states that no production writer can create (BUG-09). The genuinely strong findings were the UI-state ones (BUG-01/02/04/05).
