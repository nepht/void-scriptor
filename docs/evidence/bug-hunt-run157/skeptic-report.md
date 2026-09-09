# Skeptic Report — Hunter findings review (Void Scriptor narrative-assignment region)

Repo: D:\VoidScriptor\void_scriptor_multiplatform — verified HEAD `2317894d4149c3cf49a32401cf5dfe58eabe666c`, branch `master` (matches Hunter's claim).
Method: every reported location re-read with `read_file` (narrative_assignment_card.dart, narrative_assignment_repository.dart, narrative_assignment.dart, narrative_character_filter.dart, support_relationship_section.dart, character_narrative_assignments.dart table, plus traced files: explorer_panel.dart, project_persistence_providers.dart, character_mode_controller.dart, character_repository_impl.dart, character_controller.dart, workspace_character_deletion_service.dart, project_session_manager.dart, workspace_resolver.dart, scene_workspace_screen.dart, asset_type.dart, character_workspace_screen.dart). Greps re-run independently for all "no callers" claims. Read-only; no edits, no network.

Verdict scale: DISPROVEN / UPHELD / UPHELD-WITH-CAVEAT. Rule: only DISPROVE at >67% confidence (EV = conf×pts − (100−conf)×2×pts must be positive).

---

**BUG-01** | Original: 10 pts (High) — `_loadFor` stale-response race
- **Counter-argument:** Searched for any cancellation or sequence guard. None exists. State is also not keyed per character (`NarrativeAssignmentCard(characterId: ...)` has no `Key`, character_workspace_screen.dart:224/264), so the same `State` survives character switches and `didUpdateWidget` (card 61–71) resets fields without cancelling the in-flight future.
- **Evidence:** `_loadFor` (82–109): the only guard is `if (!mounted) return;` (line 94) after `await repo.getAssignment(...)`; no `_selectedNovelId != novel.id` check, no request token. Two overlapping loads complete in arbitrary order and the loser's `setState` wins. `_save` (111–131) then writes `NarrativeAssignment(novelWorkspaceId: novel.id, characterId: widget.characterId, roles: _roles, ...)` — current novel/character coordinates with the stale loser's `_roles`/`_importance`/`_pov`. A fresh load IS auto-triggered after a character switch (build → postFrame `_selectNovel(options.first)`, 217–223), which makes the old-character in-flight response the classic late-arriving loser. Confirmed cross-character and cross-novel write path.
- **Confidence:** 95%
- **Risk calc:** EV(disprove) = (5% × 10) − (95% × 20) = −18.5 → must accept.
- **Decision:** **UPHELD** — High confirmed. Genuine corruption path, not display-only.

---

**BUG-02** | Original: 5 pts (Medium) — `deleteForCharacter` never called in production → orphaned narrative rows
- **Counter-argument:** Checked for FK cascades that would clean orphans: `lib/database/project/tables/character_narrative_assignments.dart` declares NO foreign keys on either table (plain TextColumns + composite PKs; no `customConstraint`, no `references`), so nothing cascades or blocks. Checked the full deletion chain: `character_controller.delete` (94–110) → `session.characterDeletion.deleteCharacterWorkspace` (unlink links + `deleteCharacterSource`) → `characterRepository.deleteCharacter` (character_repository_impl.dart 102–117) — removes references, scope rows, modes, asset data, identity profiles, characters, assets; never touches `characterNarrativeAssignments`/`characterSupportRelationships`.
- **Evidence:** Independent grep for `deleteForCharacter`: definition (repo:131) + one test call (narrative_assignment_persistence_test.dart:295). Zero lib callers. Orphan display path verified: other characters' sections render `supportedId` of a deleted character as a raw UUID via `_characterNames[support.supportedId] ?? support.supportedId` (support_relationship_section.dart:172–173).
- **Confidence:** 93%
- **Risk calc:** EV(disprove) = (7% × 5) − (93% × 10) = −8.95 → accept.
- **Decision:** **UPHELD** — Medium confirmed. Dead cleanup API + permanent orphans (assignments, supports as source, supports as supported target).

---

**BUG-03** | Original: 5 pts (Medium) — `_editSupport` non-transactional remove-then-save
- **Counter-argument:** Mechanism verified, but reachability is thin: the remove branch (support_relationship_section.dart:217–226) only fires when coordinates changed, and the edit dialog locks both pickers (`onChanged: widget.initial == null ? ... : null`, lines 392–394/413–415), so the UI cannot change coordinates. Only a state desync or a `saveSupport` failure after a successful `removeSupport` loses the row — a narrow window in a branch the code itself labels "defensive".
- **Evidence:** `await repository.removeSupport(...)` then `await repository.saveSupport(result)` — two independent calls, no `database.transaction` wrapper (verified 211–236). A throw between them permanently drops the old row (delete auto-committed) with the new row absent.
- **Confidence:** 88% that the defect exists as described, but with materially reduced practical exposure.
- **Risk calc:** EV(disprove) = (12% × 5) − (88% × 10) = −8.2 → accept (with caveat).
- **Decision:** **UPHELD-WITH-CAVEAT** — real non-atomicity; corrected severity: **Low** (near-unreachable defensive branch; failure window tiny).

---

**BUG-04** | Original: 5 pts (Medium) — repository captured before dialog await; project switch writes into previous project's DB
- **Counter-argument:** The staleness pattern is real (repo captured at `_repository()` before `showDialog`, never re-validated after the await — verified 194–209, 211–236, 238–281), but the claimed harm ("cross-project contamination") does not hold: (1) the captured repository is immutable — bound to project A's database AND A's projectId, so any write lands in project A with A's asset ids, i.e. the project the data semantically belongs to; it can never write A's ids under B's projectId. (2) `ProjectSessionController._openProject` (project_persistence_providers.dart:114–135) always closes the previous session (`await _session?.close()`; `_close()` does `await database.close()`, project_session_manager.dart:112–128), so the realistic switch-then-save outcome is drift throwing on a closed database → caught → "Failed to save support relationship" SnackBar — a loud failure, not silent contamination. (3) Reachability is additionally limited by the modal barrier (`showDialog` default) blocking project-switch UI while the dialog is open.
- **Evidence:** Residual real defects: a save/delete racing an in-flight session close surfaces as a raw error SnackBar instead of graceful cancellation; and if the old DB were somehow still open, the write succeeds in A while the UI shows B (the follow-up `_load()` reads the current session, so the user doesn't see their row).
- **Confidence:** 80% that the pattern exists but the Medium-severity contamination claim is wrong.
- **Risk calc:** EV(disprove) = (20% × 5) − (80% × 10) = −7 → accept (with caveat).
- **Decision:** **UPHELD-WITH-CAVEAT** — stale-capture confirmed; corrected severity: **Low**; corrected impact: loud closed-DB error or semantically-correct write into the previous project — no wrong-project data corruption.

---

**BUG-05** | Original: 5 pts (Medium) — novel dropdowns stale after novel creation
- **Counter-argument:** Searched all story-creation paths for any invalidation of `projectAssetsProvider`, `narrativeNovelOptionsProvider`, or `supportNovelOptionsProvider`. None. Verified: explorer_panel.dart:1032–1049 invalidates only `storyExplorerProvider(projectId)`; workspace_resolver.dart:110–137 (`onCreateNovel`) invalidates nothing (it only re-selects). Note: the Hunter's citation "scene_workspace_screen.dart:139–159" is wrong — those lines are beat add/delete/reorder, not story creation — but the two verified paths suffice.
- **Evidence:** Both providers are non-autoDispose FutureProviders. Card: `narrativeNovelOptionsProvider` = `ref.watch(projectSessionProvider)` + `ref.watch(projectAssetsProvider.future)` filtered to `type == 'story'` (narrative_assignment_card.dart:21–30). Section: `supportNovelOptionsProvider` = session + `session.database.assetDao.getAllAssets()` (support_relationship_section.dart:19–29). `projectAssetsProvider` is only invalidated by unrelated actions (asset browser:357, standalone-asset creation character_mode_controller.dart:125, references card 43/87) — never by story creation. The Add-Support dialog reads the cached provider via `ref.read(supportNovelOptionsProvider.future)` (line 290). So within one project session, a novel created after these providers first resolved is absent from both dropdowns until an unrelated invalidation or a project switch. Confirmed.
- **Confidence:** 90%
- **Risk calc:** EV(disprove) = (10% × 5) − (90% × 10) = −8.5 → accept.
- **Decision:** **UPHELD** — Medium confirmed (one citation error, does not affect the verdict).

---

**BUG-06** | Original: 5 pts (Medium) — one corrupt row breaks `listAssignments()` wholesale; explorer filter silently collapses
- **Counter-argument:** The fail-loud policy is intentional and documented ("unknown tokens fail loudly via `fromWire`", repository comment line 11), and today no code path writes unknown tokens (all writes go through enum `wireName`s). However a concrete corruption vector exists: portable project import preserves rows as-is (Hunter's cross-cutting note; portable_project_service rewrites only `project_id`), so a project exported from a newer schema/vocabulary imported into an older build plants unknown tokens. And the consumer swallows the resulting provider error.
- **Evidence:** `_assignmentFromRow` (182–202) maps tokens via `NarrativeRole.fromWire`, which throws `ArgumentError` (domain 25–32; same for importance 46–53, pov 66–73). `listAssignments` (62–67) has no per-row tolerance. Consumer: explorer_panel.dart:1301–1313 uses `.watch(...).valueOrNull` then `assignments ?? const []` — provider error becomes an empty list with no error UI; with a role filter active, `own.any(...)` over empty is false for every character → list collapses to zero, silently. Mechanism fully verified.
- **Confidence:** 85%
- **Risk calc:** EV(disprove) = (15% × 5) − (85% × 10) = −7.75 → accept.
- **Decision:** **UPHELD** — Medium defensible via the portable-import version-skew vector; the silent `valueOrNull` swallow (no error surfacing in the explorer) is the core verified defect.

---

**BUG-07** | Original: 1 pt (Low) — session-loading renders "No support relationships yet" (fake empty)
- **Counter-argument:** Code conflation is real (`_load()` stores `_supports = const []` when `session == null`, lines 60–71; build renders `supports.isEmpty` → "No support relationships yet", 160–164), directly contradicting the section's own comment (91–92: "never render a fake empty list"). But reachability is narrow: `_openProject` releases a foreign selection BEFORE setting `state = AsyncLoading()` (project_persistence_providers.dart:118–119), so the project-switch path unmounts the section before a null-session `_load()` can run; the window survives mainly for same-project re-opens or initial-open timing edges.
- **Evidence:** Verified as quoted. The build guard (113–123) self-corrects once the session appears.
- **Confidence:** 78%
- **Risk calc:** EV(disprove) = (22% × 1) − (78% × 2) = −1.34 → accept (with caveat).
- **Decision:** **UPHELD-WITH-CAVEAT** — real conflation, narrow reachability; Low stands.

---

**BUG-08** | Original: 1 pt (Low) — load failure shows error text plus eternal "Loading assignment...", no retry
- **Counter-argument:** Verified. The catch branch (102–107) sets `_error`/`_loading=false` but leaves `_loadedForCurrentNovel` false; build (280–288) renders both the error text and the `if (_loading || !_loadedForCurrentNovel)` Loading line forever; the card has no Retry control (unlike the support section's ActionChip). Caveat on the sub-claim about `didUpdateWidget` never clearing `_error`: a character switch triggers postFrame `_selectNovel` → `_loadFor`, which sets `_error = null` (line 87), so the stale-error-into-next-selection window is small.
- **Evidence:** Verified as quoted. Note `getAssignment` failures include corrupt-row `ArgumentError`s (BUG-06 family), making the branch reachable beyond infra errors.
- **Confidence:** 92%
- **Risk calc:** EV(disprove) = (8% × 1) − (92% × 2) = −1.76 → accept.
- **Decision:** **UPHELD** — Low confirmed (with the didUpdateWidget sub-claim noted as largely mitigated).

---

**BUG-09** | Original: 1 pt (Low) — `_loadFor` early return on missing repo leaves eternal loading
- **Counter-argument:** Code path is real (`if (repo == null) return;` before any state change, 82–84, after `_selectNovel` already cleared `_loadedForCurrentNovel`), but nearly unreachable: when the session is null, `narrativeNovelOptionsProvider` returns `const []` and the card renders the "No novels yet" branch (192–213) — the dropdown and postFrame `_selectNovel` never run, so `_loadFor` is never called. The stuck state requires the session to vanish between a successful provider build and the user's novel pick (or during the postFrame callback).
- **Evidence:** Verified as quoted; reachability analysis above.
- **Confidence:** 75% (real path, near-unreachable)
- **Risk calc:** EV(disprove) = (25% × 1) − (75% × 2) = −1.25 → accept (with caveat).
- **Decision:** **UPHELD-WITH-CAVEAT** — Low; latent edge-case with a narrow timing window.

---

**BUG-10** | Original: 1 pt (Low) — `SupportRelationship.copyWith` cannot null `purpose`/`separationReason`
- **Counter-argument:** The limitation is code-true (`purpose: purpose ?? this.purpose`, domain 303–318) — the null sentinel collides with "clear". But no production code calls `SupportRelationship.copyWith` (grep: only narrative_assignment_test.dart:176); the dialog constructs fresh `SupportRelationship` instances (498–518), so nothing today attempts to clear these fields. Zero current user-visible impact; latent API flaw.
- **Evidence:** Verified as quoted.
- **Confidence:** 85% (fact certain; impact latent)
- **Risk calc:** EV(disprove) = (15% × 1) − (85% × 2) = −1.55 → accept (with caveat).
- **Decision:** **UPHELD-WITH-CAVEAT** — Low; latent, no production caller needs clearing today.

---

**BUG-11** | Original: 1 pt (Low) — `NarrativeAssignment.fromJson` strict casts, no production caller
- **Counter-argument:** None that matters. Verified: hard casts (`role as String`, `json['novel_workspace_id'] as String`) + strict `fromWire` (domain 139–153); grep shows callers only in tests (narrative_assignment_test.dart:96/108/119). Fully dead in lib/ — strictness is latent, not a runtime defect today.
- **Evidence:** Verified as quoted.
- **Confidence:** 88%
- **Risk calc:** EV(disprove) = (12% × 1) − (88% × 2) = −1.64 → accept (with caveat).
- **Decision:** **UPHELD-WITH-CAVEAT** — Low; dead-code/latent type-safety issue, contingent on future adoption.

---

**BUG-12** | Original: 1 pt (Low) — `matchesCharacter` O(characters × assignments)
- **Counter-argument:** Complexity claim is code-true (filter scans the full iterable per character, narrative_character_filter.dart:38–40; called per character from `characters.where(...)` at explorer_panel.dart:1310–1316). But both sets are project-scoped; at realistic scale (hundreds of characters, low thousands of assignments) C×A ≈ 10⁵–10⁶ cheap comparisons per rebuild of an ExpansionTile — sub-millisecond to low-millisecond. Theoretical inefficiency, not an observable problem.
- **Evidence:** Verified as quoted.
- **Confidence:** 85% (fact true; impact negligible)
- **Risk calc:** EV(disprove) = (15% × 1) − (85% × 2) = −1.55 → accept (with caveat).
- **Decision:** **UPHELD-WITH-CAVEAT** — Low; correct analysis, negligible at realistic scale.

---

**BUG-13** | Original: 1 pt (Low) — `listSupportsFor` lacks deterministic ordering
- **Counter-argument:** Inconsistency is code-true (`listSupports` orders by story then supportedId, 79–82; `listSupportsFor` has no `orderBy`, 87–98). But `listSupportsFor` has zero production callers (independent grep: definition only) — no user-visible instability is possible today.
- **Evidence:** Verified as quoted.
- **Confidence:** 88%
- **Risk calc:** EV(disprove) = (12% × 1) − (88% × 2) = −1.64 → accept (with caveat).
- **Decision:** **UPHELD-WITH-CAVEAT** — Low; latent (dead code path).

---

**BUG-14** | Original: 1 pt (Low) — Add-Support dialog opens with empty dropdowns, silently disabled Save
- **Counter-argument:** None. `_showEditDialog` (283–314) has no empty-list guard; `_SupportEditDialog` disables Save when `_supportedId == null || _novelId == null` (492) with no explanation. The sibling card handles the analogous case with an explicit "No novels yet" message (card 192–213) — the inconsistency confirms this is an oversight, not a design choice.
- **Evidence:** Verified as quoted.
- **Confidence:** 92%
- **Risk calc:** EV(disprove) = (8% × 1) − (92% × 2) = −1.76 → accept.
- **Decision:** **UPHELD** — Low confirmed.

---

**BUG-15** | Original: 1 pt (Low) — `deleteForCharacter` two deletes outside a transaction
- **Counter-argument:** Code-true (repo 131–145: two sequential `.go()` deletes, no `database.transaction`), and the codebase convention clearly uses transactions for multi-table cleanup (`character_repository_impl.deleteCharacter` wraps its deletes in `database.transaction`, 103–117). Caveat: the method is currently dead in production (BUG-02), so there is no runtime exposure until it gains a caller.
- **Evidence:** Verified as quoted.
- **Confidence:** 90%
- **Risk calc:** EV(disprove) = (10% × 1) − (90% × 2) = −1.7 → accept (with caveat).
- **Decision:** **UPHELD-WITH-CAVEAT** — Low; real non-atomicity in currently-dead code.

---

**BUG-16** | Original: 1 pt (Low) — stale cross-project `_load()` completion renders previous project's rows for a frame
- **Counter-argument:** This is where the Hunter's trace fails. The claimed "one frame of foreign-project data" cannot render, because the build guard executes in the SAME build pass that would render the stale data, before the render read: the stale completion's `setState` schedules a build; in that build, lines 111–123 run first — `sessionId (current, B) != _loadedSessionId (just set to A by the stale completion)` → the guard sets `_supports = null` synchronously — and only THEN does line 124 read `final supports = _supports;` for rendering. There is no build pass between the setState and the guard, so the widget tree renders `Loading...`, never the foreign rows. The "duplicate reload" is inherent to the guard's design (it schedules a reload on every mismatch), not an added cost of the race. Residual corner: A→B→A switching can land pre-switch data for the same project with no refresh trigger (guard sees matching ids) — but that is same-project staleness, a materially different and weaker claim than the one made.
- **Evidence:** support_relationship_section.dart lines 111–124: guard (111–123) precedes `final supports = _supports;` (124) in the same synchronous build; `_load()`'s completion path (79–88) has indeed no session-identity check, but the guard absorbs it before render.
- **Confidence:** 88%
- **Risk calc:** EV(disprove) = (88% × 1) − (12% × 2) = +0.64 > 0 → disprove allowed.
- **Decision:** **DISPROVEN** — as stated ("briefly rendering the previous project's relationships"). The guard-before-read ordering makes the foreign-data frame impossible; the duplicate-reload claim is by-design behavior of the guard.

---

**BUG-17** | Original: 1 pt (Low) — group targets not selectable in the support picker
- **Counter-argument:** Fact-true: `_showEditDialog` filters `asset.type == 'character'` only (292–296); domain docs say "character or group" (193, 258) and the backlog scope says "supported character/group". `AssetType` (lib/core/domain/asset_type.dart) has `faction` but no character-group type, so no group source exists to consult. Caveat: the phase_one UI checklist (docs/backlog/character-roles-support.json) lists only edit/filter/reuse items — it never explicitly requires a group-target picker, so this may be an accepted phase-one scope cut rather than a defect; it is a vocabulary/spec-vs-UI gap.
- **Evidence:** Verified as quoted, including the backlog JSON.
- **Confidence:** 80%
- **Risk calc:** EV(disprove) = (20% × 1) − (80% × 2) = −1.4 → accept (with caveat).
- **Decision:** **UPHELD-WITH-CAVEAT** — Low; genuine spec/vocabulary gap, possibly intentional phase-one scope.

---

**BUG-18** | Original: 1 pt (Low) — support rows/dropdowns show raw wire tokens
- **Counter-argument:** None. `subtitle: Text('${support.type.wireName} · ${support.duration.wireName} · ${support.status.wireName}')` (179–183); the dialog dropdowns also render `.wireName` (426/441/457). Repo-wide grep finds no `supportTypeLabel`/`supportDurationLabel`/`supportStatusLabel` (or any equivalent) anywhere, while the narrative card maps every enum through `roleLabel`/`importanceLabel`/`povLabel` (card 366–384). Verified inconsistency.
- **Evidence:** Verified as quoted.
- **Confidence:** 93%
- **Risk calc:** EV(disprove) = (7% × 1) − (93% × 2) = −1.79 → accept.
- **Decision:** **UPHELD** — Low (cosmetic/consistency) confirmed.

---

**BUG-19** | Original: 1 pt (Low) — `roleTokensToRoles` dead code duplicating decode logic
- **Counter-argument:** None — and the evidence is stronger than the Hunter claimed: independent grep shows `roleTokensToRoles` has NO callers anywhere — not in lib/ AND not in tests (the Hunter said "exists only for the test suite"; tests don't reference it either). It is fully dead, exported, and duplicates `_assignmentFromRow`'s token-decoding as a second source of truth.
- **Evidence:** repo 221–222; grep across lib/test/tool: definition only.
- **Confidence:** 92%
- **Risk calc:** EV(disprove) = (8% × 1) − (92% × 2) = −1.76 → accept.
- **Decision:** **UPHELD** — Low (dead code) confirmed; test-suite claim corrected to fully dead.

---

## SUMMARY

- **Bugs disproved:** 1 (BUG-16; 1 pt claimed)
- **Bugs accepted as real:** 18 — 8 UPHELD outright, 10 UPHELD-WITH-CAVEAT (47 of 48 pts confirmed)
- **Severity corrections:** BUG-03 Medium→Low (defensive near-dead branch); BUG-04 Medium→Low (no wrong-project corruption; loud closed-DB failure or semantically-correct write)
- **Citation corrections (verdict unaffected):** BUG-05's scene_workspace_screen.dart:139–159 citation is beat mutations, not story creation (explorer_panel + workspace_resolver paths carry the claim); BUG-08's didUpdateWidget sub-claim largely mitigated by `_loadFor` clearing `_error`; BUG-19's method is dead in tests too, not "only for the test suite"
- **Skeptic final score (per skeptic.md scoring):** +1 (disproven points) − 0 (nothing wrongly dismissed) = **+1**

**ACCEPTED BUG LIST:**
- BUG-01 (High, 10) — stale `_loadFor` race → cross-character/novel assignment corruption on Save
- BUG-02 (Medium, 5) — orphaned narrative rows on character deletion; `deleteForCharacter` dead
- BUG-03 (Low, 5→caveat) — non-atomic remove-then-save in `_editSupport` (defensive branch)
- BUG-04 (Low, 5→caveat) — stale repository capture across dialog await (no contamination; loud failure)
- BUG-05 (Medium, 5) — novel dropdowns stale after story creation (no invalidation)
- BUG-06 (Medium, 5) — one corrupt row silently collapses the explorer narrative filter
- BUG-07 (Low, 1, caveat) — fake-empty "No support relationships yet" during null session
- BUG-08 (Low, 1) — load failure renders error + eternal "Loading assignment...", no retry
- BUG-09 (Low, 1, caveat) — `_loadFor` early return leaves eternal loading (narrow window)
- BUG-10 (Low, 1, caveat) — `copyWith` cannot clear purpose/separationReason (latent)
- BUG-11 (Low, 1, caveat) — strict `NarrativeAssignment.fromJson`, dead in production
- BUG-12 (Low, 1, caveat) — O(C×A) filter scan (negligible at scale)
- BUG-13 (Low, 1, caveat) — `listSupportsFor` unordered (dead path)
- BUG-14 (Low, 1) — empty-dropdown Add-Support dialog, silently disabled Save
- BUG-15 (Low, 1, caveat) — non-transactional `deleteForCharacter` (dead code)
- BUG-17 (Low, 1, caveat) — group targets unselectable (spec/vocabulary gap)
- BUG-18 (Low, 1) — raw wire tokens shown to users
- BUG-19 (Low, 1) — `roleTokensToRoles` fully dead exported duplicate decode
