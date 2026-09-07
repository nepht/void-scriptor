# SKEPTIC REPORT — run128 (target: master @ e5b26ab)

Method: for every BUG-1..25 I independently read the cited code with read_file (all 6 in-scope files fully), plus out-of-scope code/tests cited as evidence (story_dao.dart, character_dao.dart, characters.dart, scene_characters.dart, create_story_service.dart, ai_context_resolver.dart, workspace_resolver.dart, writing_room_focus_test.dart, durable_autosave_coordinator_test.dart, save_coordinator_test.dart) and repo-wide searches (`.tmp` sweep, `SaveCoordinator` usage, `didUpdateWidget`, retention persistence, scene-member writers). Verdicts: CONFIRMED (accept as real), UNCONFIRMED (partially supported / cannot accept at >67% confidence), DISPROVED (refuted with cited code). DISPROVE only when EV > 0 (confidence > 67%).

---

**BUG-1** | Original: 5 pts
- **Counter-argument:** Checked whether Dart's `flush()`/`close()` actually provides durability, and whether a truncated `<scene>.json` can really enter `pendingEntries()` silently.
- **Evidence:** durable_draft_journal.dart:46-59 — `sink.write(payload); await sink.flush(); await sink.close(); ... await temp.rename(...)`. dart:io `flush()` flushes Dart buffers to the OS page cache; no fsync exists in the file API, and no directory sync follows the rename. pendingEntries() (lines 66-88) accepts anything `path.endsWith('.json')` — which matches a crash-truncated `<scene>.json` (comment at 84-85 even admits corruption happens) — and `on FormatException { continue; }` drops it with no signal. The class doc (lines 12-14) promises "no silent loss"; the crash/power-loss window breaks it. Repo-wide search for a `.tmp` recovery/sweep path: none.
- **Confidence:** 85%
- **Risk calc:** EV = (85% x 5) - (15% x 2 x 5) = 4.25 - 1.5 = +2.75
- **Decision:** ACCEPT → **CONFIRMED**

---

**BUG-2** | Original: 5 pts
- **Counter-argument:** Searched for any catch/guard between the editor's `onChanged` and `stage()`. None exists.
- **Evidence:** durable_draft_journal.dart:33-35 `throw ArgumentError('journal content must not be blank')` on blank content; durable_autosave_coordinator.dart:67-70 `await _journal?.stage(...); _pendingSceneId = sceneId; _pendingContent = content; _schedule();` — no try/catch. Screen path: TextField.onChanged → `_onDraftChanged` → `_count` (line 251) calls `_autosave.onDraftChanged(...)` unawaited, so the ArgumentError becomes an uncaught async exception and `_pending*`/`_schedule()` are skipped. Delete-all is a normal editing action. Previous pending/journal entry survives (good), but the exception is real and unhandled.
- **Confidence:** 90%
- **Risk calc:** EV = (90% x 5) - (10% x 2 x 5) = 4.5 - 1.0 = +3.5
- **Decision:** ACCEPT → **CONFIRMED**

---

**BUG-3** | Original: 1 pt
- **Counter-argument:** Looked for any `.tmp` cleanup/sweep. `pendingEntries()` skips `.json.tmp` (`'x.json.tmp'.endsWith('.json')` is false), `acknowledge()` deletes only `_entryFile(sceneId)` (`<scene>.json`), and a repo-wide search for `.tmp` handling in lib/ finds nothing else. A crash between write and `rename()` (line 59) orphans the file forever.
- **Evidence:** durable_draft_journal.dart:59, 66-68, 94-97; no other code touches `.tmp`.
- **Confidence:** 90%
- **Risk calc:** EV = (90% x 1) - (10% x 2 x 1) = 0.9 - 0.2 = +0.7
- **Decision:** ACCEPT → **CONFIRMED**

---

**BUG-4** | Original: 5 pts
- **Counter-argument:** Checked whether markDirty's `_schedule()` mitigates. It does not: the timer's `saveNow()` later sees `_dirty == false` (cleared by the finishing save) and no-ops. A mutation recorded between the in-flight `_persist()`'s state read and `_dirty = false` is silently unpersisted until an unrelated `markDirty()`. Note: repo-wide search shows `SaveCoordinator` is currently instantiated only in test/features/project_resilience/save_coordinator_test.dart — no production wiring found (docs call it the old Step 24.35 path superseded by DurableAutosaveCoordinator), so live impact today is limited, but the race in the class contract is real and the sibling coordinator explicitly handles the same case.
- **Evidence:** save_coordinator.dart:56-67 (`_dirty = false` inside try, only `_saving = false` in finally, no reschedule); contrast durable_autosave_coordinator.dart:100-105, 115-118.
- **Confidence:** 80%
- **Risk calc:** EV = (80% x 5) - (20% x 2 x 5) = 4.0 - 2.0 = +2.0
- **Decision:** ACCEPT → **CONFIRMED** (severity note: test-only class at HEAD)

---

**BUG-5** | Original: 5 pts
- **Counter-argument:** The umbrella observation is code-true (no try/catch separates `_persist()` and `_journal()`; a throw from a timer-driven saveNow escapes uncaught). But headline scenario (a) is factually wrong: if `_persist()` throws, `_dirty` stays true and the NEXT saveNow re-runs BOTH steps in the same try block — `_journal()` is NOT "skipped on every retry attempt"; it runs as soon as persist succeeds. Scenario (b) (journal throws after successful persist) leads to a retry that re-persists (redundant but idempotent for full-state persists) and then journals; "the durable journal never records the sequence" only holds while the failure persists. What remains is a robustness weakness (uncaught async error on timer path, double-persist), below the claimed Medium data-loss framing.
- **Evidence:** save_coordinator.dart:60-66 — both awaits in one try; no per-step catch; retry path re-enters the same block.
- **Confidence in the claim as stated:** 45% (core fact true, both concrete scenarios wrong/overstated)
- **Risk calc:** EV = (45% x 5) - (55% x 2 x 5) = 2.25 - 5.5 = -3.25
- **Decision:** **UNCONFIRMED** (no-isolation fact accepted; claimed failure semantics refuted)

---

**BUG-6** | Original: 5 pts
- **Counter-argument:** The early-return-with-retry-flag behavior is explicitly documented design, not an implied contract violation: durable_autosave_coordinator.dart:78-82 — "Jika dipanggil saat sebuah save masih berjalan, draf terbaru tidak dibuang: save yang berjalan diselesaikan dulu, lalu retry dijadwalkan". Outcome IS observed: onSaved/onPersistError fire when the in-flight save completes regardless of the early return, so the retry banner and save label update. No in-scope caller awaits `saveNow()` for its outcome: the retry button is `onPressed: () => _autosave.saveNow()` (unawaited by nature) and the State's `dispose()` calls `_autosave.dispose();` without await (a void override cannot await). "The controller can be garbage while its flush is still writing" is false in Dart — a running async chain keeps its closures reachable. Post-dispose behavior is even loss-safe: the retry finally arms a timer that persists the pending draft, and until then the journal entry survives for recovery.
- **Evidence:** lines 83-88 (early return + `_retryRequested`), 113-118 (finally re-arms), doc 78-82; screen lines 233 (`_autosave.dispose();` unawaited), 1438 (retry button unawaited).
- **Confidence in the claim as stated:** 40%
- **Risk calc:** EV = (40% x 5) - (60% x 2 x 5) = 2.0 - 6.0 = -4.0
- **Decision:** **UNCONFIRMED** (behavior exists as documented; claimed harms do not materialize)

---

**BUG-7** | Original: 5 pts
- **Counter-argument:** Traced every path that can leave a cross-scene pending draft. `_pendingSceneId` is ONLY set in `onDraftChanged`, which always ends with `_schedule()` (lines 68-70) — a pending draft can never exist without an armed timer. If the onDraftChanged(B) timer fires while save A is in flight, saveNow returns early with `_retryRequested = true`, and A's finally (115-118) schedules because `_pendingSceneId == B != null`. If it fires after A completes, it saves B directly. If B is staged mid-flight and A completes first, B's own timer is still armed and untouched (the finally only schedules on the retry flag; the timer itself was never cancelled after being created). The claim "no timer scheduled and no retry path unless _retryRequested happens to be set" is false in all interleavings. The stale `_autosaveError` sub-point is cosmetic and orthogonal (banner clears on next successful save, which B gets).
- **Evidence:** durable_autosave_coordinator.dart:59-71 (set pending ⇒ schedule), 83-91, 113-118; every interleaving terminates in either T_B firing post-save or `_retryRequested` → `_schedule()`.
- **Confidence:** 90%
- **Risk calc:** EV = (90% x 5) - (10% x 2 x 5) = 4.5 - 1.0 = +3.5
- **Decision:** **DISPROVED**

---

**BUG-8** | Original: 1 pt
- **Counter-argument:** Verified the overwrite semantics: `stage()` writes to the same per-scene filename (`_entryFile(sceneId)`), so staging v2 while the v1 save is in flight REPLACES the journal file; on v1 success `acknowledge(savedSceneId)` deletes the file that now holds v2, which was never persisted. This directly contradicts the coordinator's own contract comment (lines 34-35: "entri journal durable tidak di-acknowledge sehingga konten terbaru tidak pernah hilang"). The in-memory pending v2 still autosaves in normal operation, so the loss window is a crash before the next debounce — exactly the window the journal exists to protect.
- **Evidence:** durable_draft_journal.dart:23-24, 40, 94-97 (delete by sceneId only, no content/stagedAt check); durable_autosave_coordinator.dart:96-98.
- **Confidence:** 85%
- **Risk calc:** EV = (85% x 1) - (15% x 2 x 1) = 0.85 - 0.3 = +0.55
- **Decision:** ACCEPT → **CONFIRMED**

---

**BUG-9** | Original: 5 pts
- **Counter-argument:** None that survives — the set semantics are plainly in the code. Reproduced the hunter's algebra: snapshot `[A,A,B]` vs current `[A,B,B]` → `currentSet = {A,B}` → unchanged=3, removed=[], added=[] (100% "unchanged"); `[B,A]` vs `[A,B]` → zero diff. Reordering and duplicate rewrites are invisible to the diff while the doc (draft_snapshots.dart:8-9) sells diff_view as the canonical hapus/tambah/tetap comparison.
- **Evidence:** draft_snapshots.dart:163-186 (`toSet()` membership for removed/added/unchanged).
- **Confidence:** 88%
- **Risk calc:** EV = (88% x 5) - (12% x 2 x 5) = 4.4 - 1.2 = +3.2
- **Decision:** ACCEPT → **CONFIRMED**

---

**BUG-10** | Original: 1 pt
- **Counter-argument:** The described output is real (snapshot `[X,X,Y]` vs current `[Y,Y,Z]` → `removed = ['X','X']`), but the "contract violation" reading is weak: the doc (line 60) says "Baris yang ada di snapshot tapi hilang di teks kini (urut kemunculan)" — it promises occurrence ORDER, not uniqueness; two missing X lines yielding two entries ordered by occurrence is a defensible reading. The multiplicity-blindness that makes this odd is BUG-9's root cause counted a second time.
- **Evidence:** draft_snapshots.dart:60-64, 169-172.
- **Confidence in the claim as stated:** 55%
- **Risk calc:** EV = (55% x 1) - (45% x 2 x 1) = 0.55 - 0.9 = -0.35
- **Decision:** **UNCONFIRMED** (duplicate of BUG-9's mechanism; doc does not promise dedup)

---

**BUG-11** | Original: 10 pts (Critical)
- **Counter-argument (partial):** Two parts. TRUE: story_repository_impl.dart:346-347 `snapshots.firstWhere((s) => s.id == snapshotId)` without `orElse`; retention purges oldest rows on capture (lines 300-313, deleteSceneDraftSnapshotByIds at 312), so a listed id can vanish (capture from another surface, retention set while panel open, import replacing rows) and the tap handler has no catch → uncaught StateError, restore intent dropped, zero user feedback. FALSE: the claimed amplifier — "skips _restoreSnapshot's finally, leaving _restoringSnapshotId set ... permanently disables every Restore button" — is wrong Dart semantics. `finally` ALWAYS runs on throw; `_restoringSnapshotId = ''` (line 1192) executes, and the finally's `await _loadSnapshotsFor(sceneId)` (line 1193) calls `setState` on success+mounted (lines 1048-1049), rebuilding and re-enabling the buttons. There is no lockout.
- **Evidence:** story_repository_impl.dart:346-347, 304-313; story_workspace_screen.dart:1182-1194 (`try/finally`, no catch), 1044-1050, 876-881.
- **Confidence:** 78% that a real (lesser) bug exists — unhandled StateError on a user action with recoverable-cause
- **Risk calc:** EV = (78% x 10) - (22% x 2 x 10) = 7.8 - 4.4 = +3.4
- **Decision:** ACCEPT → **CONFIRMED** with severity correction: Critical(10) overstated; the lockout mechanism is refuted; real severity ≈ Low/Medium (uncaught error + no feedback). Accepted at the disputed severity, not 10 pts.

---

**BUG-12** | Original: 5 pts
- **Counter-argument:** The behavior is verified (limits live only in `_retentionLimits`, line 70; `_enforceRetention` no-ops without it, 305-306; nothing persists the limit; map never cleaned for deleted scenes), and the restart gap vs the 109.22 contract (draft_snapshots.dart:12-13) is real. But "silently" is rebutted twice in-repo: the repository's own doc comment (line 69) says "sesi berjalan" and the screen's retention dialog comment (story_workspace_screen.dart:1097-1099) says "batas session-scoped mengikuti domain store". This is a documented, apparently deliberate scope cut (the domain store is equally session-scoped), not a hidden defect; whether the canonical contract permits session-scoped limits is a product call, not a code-level bug I can confirm at >67%.
- **Evidence:** story_repository_impl.dart:69-70, 304-306, 369-378; story_workspace_screen.dart:1097-1099; draft_snapshots.dart:12-13.
- **Confidence in the claim as stated:** 55%
- **Risk calc:** EV = (55% x 5) - (45% x 2 x 5) = 2.75 - 4.5 = -1.75
- **Decision:** **UNCONFIRMED** (documented session-scoping; contract-persistence gap is a product decision)

---

**BUG-13** | Original: 5 pts
- **Counter-argument:** Three refutations. (1) The `default → restoreBackup` arm is REQUIRED for correctness: restore backups are inserted with the raw string `'restoreBackup'` (line 356), so the default case is how legitimate backup rows map — removing it would break them. (2) No writer in the repo produces any other kind string (`captureSceneDraftSnapshot` writes `kind.name` ∈ {auto, manual}); "corrupt or future-version rows" are hypothetical. (3) The cited UI harm is factually wrong: the panel prints the RAW DB string — `'${snapshot.kind} · ...'` (story_workspace_screen.dart:873) where `snapshot` is the DB row `SceneDraftSnapshot` — not the mapped enum. The only consumer of `_kindFromDb` is the `kind:` filter in `getSceneDraftSnapshots` (325-327), and no in-scope caller passes `kind`.
- **Evidence:** story_repository_impl.dart:288, 331-340, 356; story_workspace_screen.dart:873; screen call sites (1128, 1047) pass no `kind`.
- **Confidence:** 78%
- **Risk calc:** EV = (78% x 5) - (22% x 2 x 5) = 3.9 - 2.2 = +1.7
- **Decision:** **DISPROVED**

---

**BUG-14** | Original: 5 pts
- **Counter-argument (partial):** The performance claim is confirmed: chapterNodes maps over chapters, and for EVERY chapter re-scans all sceneNodes with `scenes.firstWhere((x) => x.id == s.id)` inside the `where` predicate (lines 149-163) — O(chapters × scenes²) with the same pattern repeated for arcs (169-177), executed per hierarchy fetch (which BUG-17 shows is per keystroke). The StateError sub-claim is refuted: `sceneNodes` is built directly FROM `scenes` (lines 137-148), so `scenes.firstWhere` cannot miss, and `chapterNodes` from `chapters` — the fragility is unreachable by construction.
- **Evidence:** story_repository_impl.dart:137-177.
- **Confidence:** 85% (perf half)
- **Risk calc:** EV = (85% x 5) - (15% x 2 x 5) = 4.25 - 1.5 = +2.75
- **Decision:** ACCEPT → **CONFIRMED** (performance claim; StateError sub-claim refuted as unreachable)

---

**BUG-15** | Original: 1 pt
- **Counter-argument:** None — `chapter.title` is loop-invariant across the per-scene loop, so one chapter-title hit adds +1 to every scene row of that chapter (`matchCount: existing == null ? count : existing.matchCount + count` also accumulates across stories). The badge renders the inflated number (screen line 1486).
- **Evidence:** story_repository_impl.dart:210-233; story_workspace_screen.dart:1485-1487.
- **Confidence:** 85%
- **Risk calc:** EV = (85% x 1) - (15% x 2 x 1) = 0.85 - 0.3 = +0.55
- **Decision:** ACCEPT → **CONFIRMED**

---

**BUG-16** | Original: 1 pt
- **Counter-argument:** The claimed id-space mismatch is impossible in this schema: the Characters table's ONLY key is `assetId` (characters.dart:4,19 — `primaryKey => {assetId}`; there is no separate internal row id), so any reference to a character is necessarily its assetId. The repo-wide convention is consistent: `CreateStoryService.addCharacter(characterId: ...)` (create_story_service.dart:123-138) and `ai_context_resolver.dart:41-44` perform the identical `characterId → getCharacter(assetId)` join. The `continue`-on-null is defensive handling of a dangling membership row (no FK constraints on SceneCharacters), not silent corruption. Sequential awaits are true but trivial (members of one scene).
- **Evidence:** characters.dart:4,19; character_dao.dart:29-31; create_story_service.dart:123-138; ai_context_resolver.dart:41-44; story_repository_impl.dart:243-247.
- **Confidence:** 88%
- **Risk calc:** EV = (88% x 1) - (12% x 2 x 1) = 0.88 - 0.24 = +0.64
- **Decision:** **DISPROVED**

---

**BUG-17** | Original: 5 pts
- **Counter-argument:** None that survives. `FutureBuilder(future: repository.getStoryHierarchy(widget.storyId))` is created inline in `_buildLiveChapters`, called unconditionally from `build` (line 1370, inside `!_isFocusActive`). `_count` runs `setState` on every keystroke (lines 238-244) and onSaved/onSaveStarted/onPersistError setState per autosave tick (183-204) — each rebuild constructs a brand-new Future, restarting the full hierarchy fetch (arcs + chapters + scenes + per-scene characters/environment/beats). Classic FutureBuilder-in-build anti-pattern with a heavy N+1 query behind it.
- **Evidence:** story_workspace_screen.dart:892-894, 1370, 238-244, 183-204; story_repository_impl.dart:129-148.
- **Confidence:** 95%
- **Risk calc:** EV = (95% x 5) - (5% x 2 x 5) = 4.75 - 0.5 = +4.25
- **Decision:** ACCEPT → **CONFIRMED**

---

**BUG-18** | Original: 5 pts
- **Counter-argument (partial):** Sub-claims that are wrong: (a) "pending autosave draft may reference a different scene" in the typed-before-hierarchy branch — false, because with `_selectedSceneId == null` the `_count` guard (line 247) never called `onDraftChanged`, so no pending draft exists; (b) `_loadDraftFor` clobber in that branch — guarded by `if (_draft.text.isEmpty)` (line 917). Sub-claims that are RIGHT: mutating State fields (`_selectedSceneId`, `_selectedSceneTitle`) inside a builder during build is a real anti-pattern (lines 914-916), and the stale-async clobber is REAL via rapid scene switching: `_loadDraftFor(A)` (slow) then tap B → `_loadDraftFor(B)` completes → A's await resolves later, `mounted` is still true, and line 968 unconditionally `_draft.value = TextEditingValue(text: content)` — clobbering text typed for B (with B's text already pending in the autosave, the editor and the pending save diverge). No request versioning exists.
- **Evidence:** story_workspace_screen.dart:914-929, 964-970, 942-952/1496-1506 (unconditional `_loadDraftFor` per selection), 246-252.
- **Confidence:** 75%
- **Risk calc:** EV = (75% x 5) - (25% x 2 x 5) = 3.75 - 2.5 = +1.25
- **Decision:** ACCEPT → **CONFIRMED** (build-phase mutation + verified stale-draft clobber race; two cited sub-scenarios refuted)

---

**BUG-19** | Original: 1 pt
- **Counter-argument:** The failure path DOES rebuild: `_restoreSnapshot`'s finally (lines 1191-1194) resets `_restoringSnapshotId = ''` and awaits `_loadSnapshotsFor(sceneId)`, which calls `setState` on success+mounted (lines 1048-1049). On the realistic single-failure case (restore throws, e.g. vanished snapshot) the reload succeeds → setState → rebuild → buttons re-enabled with current data. Stale buttons require the reload to ALSO fail — at which point the original error is already an uncaught exception (BUG-11 overlap), and the "no visible recovery" framing adds nothing distinct.
- **Evidence:** story_workspace_screen.dart:1182-1194, 1044-1050, 876-881.
- **Confidence:** 80%
- **Risk calc:** EV = (80% x 1) - (20% x 2 x 1) = 0.8 - 0.4 = +0.4
- **Decision:** **DISPROVED**

---

**BUG-20** | Original: 1 pt
- **Counter-argument:** The only call site is `_focusToggle`'s `onPressed: active ? _exitFocusMode : _enterFocusMode` (line 687) — `_exitFocusMode` is unreachable while inactive, so the "redundant rebuild" never occurs, and a setState in a button callback is always legal; nothing invokes it from build (repo search: single call site). The speculative "illegal setState-during-build hazard" is unreachable code path speculation, not a bug.
- **Evidence:** story_workspace_screen.dart:674-677, 680-692 (only call site, gated by `active`).
- **Confidence:** 85%
- **Risk calc:** EV = (85% x 1) - (15% x 2 x 1) = 0.85 - 0.3 = +0.55
- **Decision:** **DISPROVED**

---

**BUG-21** | Original: 1 pt
- **Counter-argument:** The algebra refutes it: `_loreQuery` is produced by `LoreLinkSyntax.activeQueryAt(text, caret)`, whose returned body length satisfies `query.length == caret - anchorStart - 2`; therefore `start = caret - query.length - 2 == anchorStart ≥ 0` whenever the query matches a real anchor at the current caret. A `[[a` anchored at offset 0 gives start = 0, which passes the `start < 0` check and is accepted. Negative start can only arise when `_loreQuery` is stale/mismatched relative to the current caret (user moved/deleted) — i.e., there is genuinely no `[[query` before the caret — and tearing down is then CORRECT. The claimed "genuine [[query at the very start cannot be accepted" scenario does not exist.
- **Evidence:** story_workspace_screen.dart:374-385; lore_link_suggester.dart:92-108 (`activeQueryAt` returns `text.substring(start + 2, end)` ⇒ the identity above).
- **Confidence:** 88%
- **Risk calc:** EV = (88% x 1) - (12% x 2 x 1) = 0.88 - 0.24 = +0.64
- **Decision:** **DISPROVED**

---

**BUG-22** | Original: 1 pt
- **Counter-argument:** Verified: no `didUpdateWidget`/`didChangeDependencies` in the State (repo search), `_draftJournal = widget.draftJournal` captured once (line 171), `_selectedSceneId = widget.sceneId` once (line 170), and the resolver instantiates `StoryWorkspaceScreen` with NO key (workspace_resolver.dart:188-202) while creating a fresh `StoryRepositoryImpl` and per-session `DurableDraftJournal` each build — so a same-element widget swap (story→story selection, or session/package switch under the resolver) reuses the State. Mitigant found: the persist closure reads `widget.repository` LIVE (line 178), so the repository is NOT stale — but the journal IS captured once, and stale `_selectedSceneId` after a story→story element reuse routes typed text into the previous story's scene (data-integrity hazard). Mechanism verified at code level; triggering depends on runtime navigation specifics, hence confidence < 100%.
- **Evidence:** story_workspace_screen.dart:92, 97, 167-171, 177-181; workspace_resolver.dart:188-202 (no key, per-session journal dir).
- **Confidence:** 72%
- **Risk calc:** EV = (72% x 1) - (28% x 2 x 1) = 0.72 - 0.56 = +0.16
- **Decision:** ACCEPT → **CONFIRMED** (lifecycle hazard; repository-staleness sub-claim refuted — it is read live)

---

**BUG-23** | Original: 1 pt
- **Counter-argument:** The code fact is verified — the DRAFT RECOVERY block (lines 1344-1350) sits outside the `if (!_isFocusActive)` gate at line 1359 while all enumerated chrome is inside. But the "documented contract" cited (writing_room_focus_test.dart:11-13) enumerates exactly "CHAPTERS, STORY BIBLE, NOVEL SEARCH, SCENE SNAPSHOTS, CHARACTER QUICK REF" — DRAFT RECOVERY is not in the list — and the screen's own comment (1341-1343) states the recovery prompt is deliberately placed near the top for startup visibility. Keeping a pending-data-loss warning visible during focus is as plausibly intentional as it is an oversight; a contract violation I can assert at >67% is not established.
- **Evidence:** story_workspace_screen.dart:1341-1359; writing_room_focus_test.dart:11-13.
- **Confidence in the claim as stated:** 55%
- **Risk calc:** EV = (55% x 1) - (45% x 2 x 1) = 0.55 - 0.9 = -0.35
- **Decision:** **UNCONFIRMED** (gating inconsistency is real; contract breach not established)

---

**BUG-24** | Original: 1 pt
- **Counter-argument:** The code reads exactly as quoted (lines 294-296). But the user-visible harm is negligible and arguably intended: `_syncLoreMenu` re-runs per keystroke; when the query CHANGES, both highlight and hover reset (consistent); when it is unchanged, clearing `_loreHoverIndex` only means the mouse must move again to re-hover — a cosmetic nit in an ephemeral autocomplete overlay, with no state corruption. Not a demonstrable bug at >67%.
- **Evidence:** story_workspace_screen.dart:294-296, 413-416 (`_setLoreHover` re-arms on any mouse movement).
- **Confidence in the claim as stated:** 55%
- **Risk calc:** EV = (55% x 1) - (45% x 2 x 1) = 0.55 - 0.9 = -0.35
- **Decision:** **UNCONFIRMED**

---

**BUG-25** | Original: 1 pt
- **Counter-argument:** None that survives. `_showSnapshotDialog` awaits `repository.captureSceneDraftSnapshot(sceneId, label: label.trim())` (line 1172) with no try/catch; the repository throws `StateError('no draft content for scene $sceneId')` when `getSceneDraft` is null (lines 283-286) — and a never-saved scene has no draft row (rows are only written by `saveSceneDraft` via autosave; `_loadDraftFor` only fills the TextEditingValue). Tapping Snapshot right after selecting a fresh scene therefore throws an unhandled async exception with zero user feedback that the labeled snapshot was not recorded.
- **Evidence:** story_workspace_screen.dart:1171-1173; story_repository_impl.dart:283-286, 72-95.
- **Confidence:** 90%
- **Risk calc:** EV = (90% x 1) - (10% x 2 x 1) = 0.9 - 0.2 = +0.7
- **Decision:** ACCEPT → **CONFIRMED**

---

## SUMMARY

- Bugs disproved: 6 (BUG-7, BUG-13, BUG-16, BUG-19, BUG-20, BUG-21) — total points claimed: 14
- Bugs confirmed as real: 13 (BUG-1, BUG-2, BUG-3, BUG-4, BUG-8, BUG-9, BUG-11*, BUG-14*, BUG-15, BUG-17, BUG-18*, BUG-22*, BUG-25) — accepted points: 50 (with severity corrections on *: BUG-11 Critical→real mechanism is an uncaught StateError, no lockout; BUG-14 StateError sub-claim unreachable; BUG-18 two sub-scenarios refuted; BUG-22 repository-read-live refuted)
- Unconfirmed (partially supported / cannot accept at >67%): 6 (BUG-5, BUG-6, BUG-10, BUG-12, BUG-23, BUG-24) — 18 pts claimed
- Hunter's accepted-vs-skeptic delta: 25 findings → 13 stand, 6 refuted, 6 unproven
- Skeptic net score (per skeptic.md scoring): +14 pts (14 claimed points successfully disproved; no wrong dismissals counted)

**ACCEPTED BUG LIST (with original severity):**
- BUG-1 (Medium, 5) — journal durability: no fsync; corrupted `<scene>.json` silently dropped by pendingEntries()
- BUG-2 (Medium, 5) — blank-content stage() throws uncaught through onDraftChanged chain
- BUG-3 (Low, 1) — orphaned `.tmp` files, no sweep
- BUG-4 (Medium, 5; test-only class at HEAD) — SaveCoordinator mid-save markDirty lost-update race
- BUG-8 (Low, 1) — acknowledge() deletes newer never-persisted staging (same-file overwrite)
- BUG-9 (Medium, 5) — diffWithCurrent set semantics: duplicates/reorders report 100% unchanged
- BUG-11 (Critical→corrected Low/Medium; 10 claimed) — restoreSceneDraftSnapshot firstWithout-orElse → uncaught StateError, no user feedback (lockout sub-claim refuted)
- BUG-14 (Medium, 5) — O(chapters × scenes²) hierarchy join per fetch (StateError sub-claim unreachable)
- BUG-15 (Low, 1) — chapter-title match counted once per scene in searchNovel
- BUG-17 (Medium, 5) — inline FutureBuilder future in build: full hierarchy query per keystroke
- BUG-18 (Medium, 5) — build-phase state mutation + stale-async _loadDraftFor clobber via rapid scene switch
- BUG-22 (Low, 1) — no didUpdateWidget/key: State reuse carries stale _draftJournal/_selectedSceneId across element reuse
- BUG-25 (Low, 1) — captureSceneDraftSnapshot StateError escapes with no user feedback
