# REFEREE REPORT — run128 adversarial bug hunt (Void Scriptor, draft-safety/autosave path)

- Target: D:\VoidScriptor\void_scriptor_multiplatform (branch master). Reports cite e5b26ab / task cites 3464cbf; actual HEAD is a575572. `git diff` across all three commits shows the 6 in-scope files differ only by ONE moved blank line in story_workspace_screen.dart — all verdicts below apply identically to all three commits. Line numbers cited are from HEAD as read.
- Method: all 6 in-scope files read fully by the referee; every BUG-1..25 re-derived from the code. Out-of-scope evidence re-verified where load-bearing: character_dao.dart, tables/characters.dart, workspace_resolver.dart (lines 188–202: `StoryWorkspaceScreen` built with NO key, fresh journal+repository per build), lore_link_suggester.dart (`activeQueryAt`), story_dao.dart, durable_autosave_coordinator_test.dart, save_coordinator_test.dart, writing_room_focus_test.dart header, plus repo-wide searches (`SaveCoordinator` usage, `didUpdateWidget`, `.tmp` handling, retention persistence, `diffWithCurrent` consumers, `deleteSceneDraftSnapshots*` callers).

---

**BUG-1**
- **Hunter's claim:** `stage()` uses `flush()`+`rename()` without fsync of file or directory, and `pendingEntries()` silently discards any corrupt `.json` entry — a power-loss can truncate the journal and the staged draft is lost with no signal, contradicting the class's own "crash/power-loss tidak meninggalkan file setengah jadi" / no-silent-loss contract.
- **Skeptic's response:** CONFIRMED (85%). dart:io `flush()` does not fsync; no directory sync after rename; `pendingEntries()` accepts any `*.json` (matches a crash-truncated `<scene>.json`) and `on FormatException { continue; }` drops it silently; no `.tmp` sweep exists.
- **Your analysis:** Read directly: durable_draft_journal.dart:46–59 (`sink.write; await sink.flush(); await sink.close(); await temp.rename(...)`) and 66–88 (`endsWith('.json')` filter, `on FormatException { continue; }`). Both facts are code-provable. dart:io offers no fsync, so the doc comment (lines 10–14) promises more than the API can deliver; worse, the recovery reader cannot distinguish a legitimate `.tmp` leftover from a truncated final `<scene>.json` — both fail decode, and the latter is the only durable copy of the user's unsaved draft, dropped with zero signal. The silent-drop half is the actionable defect; the fsync half is a doc-contract overstatement (pure Dart cannot fully close it).
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** In `pendingEntries()`, silently skip only names ending `.json.tmp`; for a corrupt `<scene>.json`, surface it (e.g., return a corrupt-flagged entry or expose a `corruptCount` the DRAFT RECOVERY panel can render) instead of `continue`. Temper the doc comment to state the real guarantees; optionally jsonDecode-verify the temp file before `rename()` to narrow the truncated-final-file window.

---

**BUG-2**
- **Hunter's claim:** `stage()` throws `ArgumentError` for blank content, but clearing the editor is normal; `onDraftChanged` awaits `stage()` before registering the pending draft, so a delete-all keystroke throws uncaught through the unawaited async chain and skips pending registration.
- **Skeptic's response:** CONFIRMED (90%). No catch anywhere between TextField.onChanged and `stage()`; `_count` (screen:251) calls `onDraftChanged` unawaited.
- **Your analysis:** Verified: journal lines 33–35 throw; coordinator lines 67–70 `await _journal?.stage(...); _pendingSceneId = sceneId; _pendingContent = content; _schedule();` with no try/catch; screen line 251 fire-and-forget. Select-all+delete fires `onChanged` with `''` on a routine basis → guaranteed uncaught async exception per occurrence, and `_schedule()` is skipped. No data is lost (previous pending survives and its timer still fires), but this is a recurring unhandled error on the hottest user path.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Treat blank content as a state transition, not an error: in `onDraftChanged`, branch on `content.trim().isEmpty` (keep/clear pending without staging and without throwing), or make `stage()` accept blanks as a tombstone. Additionally wrap the `stage()` await in try/catch and route failures to `onPersistError` so no journal failure can ever escape the unawaited chain.

---

**BUG-3**
- **Hunter's claim:** `.tmp` files that finished writing but crashed before `rename()` are orphaned forever — `pendingEntries()` ignores them, `acknowledge()` deletes only `<scene>.json`, nothing sweeps.
- **Skeptic's response:** CONFIRMED (90%). Repo-wide `.tmp` search: no other handling.
- **Your analysis:** Verified in code: line 40/59 create+rename; line 68 filter excludes `.json.tmp`; `acknowledge` (94–97) deletes only `_entryFile`. My own search for `.tmp` handling across lib/ confirms no sweep. A crash between close and rename strands the file permanently; growth is slow (requires a crash inside a millisecond window) but unbounded and never reclaimed.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Sweep stale `*.json.tmp` files once at journal construction / first `pendingEntries()` call — the journal is a single writer, so a startup sweep is safe.

---

**BUG-4**
- **Hunter's claim:** A `markDirty()` arriving while `saveNow()` is in flight sets `_dirty = true`, but the finishing save clears `_dirty` and nothing reschedules — the mid-save mutation is silently never persisted.
- **Skeptic's response:** CONFIRMED with severity note (80%): race is real; but `SaveCoordinator` is instantiated only in tests at HEAD (superseded by DurableAutosaveCoordinator).
- **Your analysis:** Code-verified: save_coordinator.dart:56–67 — `_dirty = false` inside `try`, only `_saving = false` in `finally`, no reschedule; `markDirty` during the `await _persist()` window is a provable event-loop interleaving (unlocked shared flag on an async path). The timer armed by the mid-save `markDirty()` later no-ops because `_dirty` was cleared. My search confirms the class has no production wiring (only test/features/project_resilience/save_coordinator_test.dart). The sibling coordinator handles the same case correctly (115–118).
- **VERDICT: REAL BUG**
- **Confidence:** High (mechanism provable from code; concurrency rule satisfied — unlocked shared mutation on an async path)
- **True severity:** Low (no production caller at HEAD)
- **Suggested fix:** In `finally` (or after `_journal()`), reschedule if still dirty: `finally { _saving = false; if (_dirty) _schedule(); }`; or clear `_dirty` before `await _persist()` so mutations during the save re-mark it.

---

**BUG-5**
- **Hunter's claim:** No failure isolation between `_persist()` and `_journal()`: if `_persist()` throws, `_journal()` is "skipped on every retry attempt"; if `_journal()` throws after a successful persist, "the durable journal never records the sequence"; the in-flight window is "never updated on any failure path".
- **Skeptic's response:** UNCONFIRMED (45%): umbrella fact true, but both concrete scenarios refuted — a retry re-enters the same try block and runs BOTH steps; failure paths correctly preserve the in-memory journal entries.
- **Your analysis:** I verified the refutations. saveNow (56–67) has one try block: on `_persist()` throw, `_dirty` stays true and the NEXT saveNow re-runs both steps — the journal is not permanently skipped. The in-memory `AutosaveJournal._sequences` is only cleared via the `_journal()` callback, so on failure the pending window is correctly preserved, not lost. What remains is a robustness nit: a throw from the timer-driven path is uncaught, and retries re-persist (idempotent for full-state persists). The claimed failure semantics — the substance of the finding — do not occur.
- **VERDICT: NOT A BUG** (residual uncaught-timer-error is a minor robustness item, not the claimed data-integrity defect)
- **Confidence:** High

---

**BUG-6**
- **Hunter's claim:** `saveNow()` while saving returns immediately, so callers that `await` it (retry button, `dispose()`) resolve before the in-flight save completes and never observe its outcome; "controller can be garbage while its flush is still writing".
- **Skeptic's response:** UNCONFIRMED (40%): early-return+retry is explicitly documented (lines 78–82); outcome IS observed via onSaved/onPersistError; no in-scope caller awaits it; "garbage while writing" is false in Dart; post-dispose retry is loss-safe.
- **Your analysis:** I verified: no production caller awaits `saveNow()` — the retry button (screen:1438) is an unawaited `onPressed`, and `dispose()` (screen:233) is void and cannot await. Outcome observation is by design via callbacks, which fire when the in-flight save completes. A running async chain keeps its closures reachable, so the GC claim is false. Post-dispose, the finally (115–118) re-arms and persists the pending draft; callbacks guard `mounted`/`_disposeStarted`. The documented early-return is intentional and loss-safe; the claimed harms do not materialize.
- **VERDICT: NOT A BUG**
- **Confidence:** High

---

**BUG-7**
- **Hunter's claim:** When a save for scene A finishes and finds a pending draft for scene B typed during the save, B is left unsaved with no timer scheduled and no retry path unless `_retryRequested` is set; A's stale error banner also stays visible.
- **Skeptic's response:** DISPROVED (90%): `_pendingSceneId` is only set in `onDraftChanged`, which always ends with `_schedule()` — a pending draft can never exist without an armed timer; every interleaving terminates in B's own timer firing or `_retryRequested` → `_schedule()`.
- **Your analysis:** I traced all interleavings and agree with the skeptic. If B is staged mid-save, B's `onDraftChanged` re-arms the timer AFTER A's saveNow cancelled it (A's cancellation happened before B's staging); A's completion keeps B pending (`_pendingSceneId != savedSceneId`) and B's armed timer fires and saves it. If B's timer fires during A, `_retryRequested` routes through the finally reschedule — exactly what test `durable_autosave_coordinator_test.dart:103–130` proves (`persistedScenes == ['scene-a', 'scene-b']`). The stale-banner point is cosmetic: the banner accurately reports A's failed save and clears on B's success.
- **VERDICT: NOT A BUG**
- **Confidence:** High

---

**BUG-8**
- **Hunter's claim:** `acknowledge` is keyed only by `sceneId` with no content/stagedAt check, so a successful retry acknowledges and deletes the scene-wide journal entry even if it holds a newer staging that was never persisted — newest staged payload silently lost.
- **Skeptic's response:** CONFIRMED (85%): `stage()` overwrites the same per-scene file; acknowledging v1's save deletes the file now holding v2; contradicts the coordinator's own contract comment; loss window = crash before next debounce.
- **Your analysis:** Verified, and the defect is broader than the hunter stated. Journal `stage()` (line 40/59) overwrites `<scene>.json`; coordinator lines 96–98 acknowledge the sceneId unconditionally after persisting v1. Worse, lines 102–105 clear the pending draft when `_pendingSceneId == savedSceneId` — i.e., same-scene typing mid-save is cleared even though only v1 was persisted — directly contradicting the comment at 100–101 ("draf yang di-set oleh onDraftChanged saat save berjalan TIDAK dihapus") and the class contract (lines 34–35). Consequence: content typed during an in-flight save of the same scene loses BOTH its durable entry (deleted by acknowledge) and its in-memory pending (cleared); the armed debounce timer then no-ops (pending is null). A user who types/pastes during a save and closes the app without a further keystroke permanently loses that burst — no crash required — and a crash in the same window loses it too. The interleaving is code-proven (the coordinator's own test demonstrates mid-save `onDraftChanged` execution).
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium (upgraded from Low: silent data loss in the exact window the journal exists to protect, contradicting the documented no-silent-loss contract)
- **Suggested fix:** Make acknowledgement content-aware: stamp each staged payload with a version token (e.g., stagedAt+hash) and have `acknowledge(sceneId, token)` delete only if the on-disk entry still matches the persisted version. Change the pending-clear to compare content (`_pendingSceneId == savedSceneId && _pendingContent == savedContent`) so mid-save same-scene typing survives; the armed timer then persists v2. Correct the 100–105 comment to match the actual semantics.

---

**BUG-9**
- **Hunter's claim:** `diffWithCurrent` compares line sets — duplicates inflate `unchangedCount` and pure reorderings report 100% unchanged; snapshot `[A,A,B]` vs current `[A,B,B]` reports zero diff.
- **Skeptic's response:** CONFIRMED (88%): algebra reproduced.
- **Your analysis:** Code-verified (draft_snapshots.dart:163–186): membership via `toSet()`, `unchanged` counts per snapshot line in `currentSet`. `[A,A,B]`→`[A,B,B]` yields unchanged=3, removed=[], added=[] — a real single-line replacement is reported as no change; duplicate lines inflate `unchangedCount`. (The pure-reorder half is weaker — a positional/LCS line diff would also report reordered identical lines as unchanged — but the multiplicity blindness is unambiguous.) My search shows `diffWithCurrent` has no production consumer yet (domain class + its test only), which caps today's impact.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low (downgraded from Medium: no production consumer at HEAD; becomes Medium once a diff UI ships)
- **Suggested fix:** Use multiset (bag) semantics: count occurrences per line in both sides; removed = max(0, snapCount−curCount) occurrences per line, added symmetric, unchanged = Σ min(counts). Use LCS only if positional edits are required.

---

**BUG-10**
- **Hunter's claim:** The documented contract "Baris yang ada di snapshot tapi hilang di teks kini (urut kemunculan)" is violated — `removedLines`/`addedLines` can repeat a line that is logically one removal.
- **Skeptic's response:** UNCONFIRMED (55%): the doc promises occurrence ORDER, not uniqueness; duplicate-of-BUG-9 mechanism.
- **Your analysis:** The doc text (draft_snapshots.dart:60–64) promises ordering, not dedup. Snapshot `[X,X,Y]` vs current `[Y,Y,Z]` producing `removed = ['X','X']` — one entry per missing occurrence, in occurrence order — is a consistent reading of the contract, not a violation. The underlying multiplicity blindness is BUG-9's mechanism counted a second time.
- **VERDICT: NOT A BUG** (duplicate of BUG-9's root cause; the claimed contract breach is refuted by the doc's own wording)
- **Confidence:** High

---

**BUG-11**
- **Hunter's claim:** `restoreSceneDraftSnapshot` uses `firstWhere` without `orElse`; restoring a retention-purged id throws an uncaught `StateError` that also skips `_restoreSnapshot`'s `finally`, leaving `_restoringSnapshotId` set and permanently disabling every Restore button.
- **Skeptic's response:** CONFIRMED with correction (78%): the throw is real but the lockout amplifier is false — `finally` always runs on throw.
- **Your analysis:** Both halves verified. story_repository_impl.dart:346–347 has no `orElse`, and retention purges on capture (304–313) can remove a listed id. But the claimed lockout is impossible Dart semantics: `_restoreSnapshot` (screen:1178–1195) uses try/finally — on throw, `finally` executes, resets `_restoringSnapshotId = ''`, and `_loadSnapshotsFor` calls `setState` on success+mounted (1048–1049), re-enabling the buttons. What remains: an uncaught `StateError` from a user action with a recoverable cause and zero user feedback. Trigger is narrow (list goes stale between render and tap).
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low (downgraded from Critical: no lockout, no data loss; restore intent dropped with no feedback)
- **Suggested fix:** `snapshots.firstWhere((s) => s.id == snapshotId, orElse: () => null)`; on miss, refresh the snapshot list and surface a SnackBar ("Snapshot tidak ditemukan"). Add a catch in `_restoreSnapshot` to report any restore failure visibly.

---

**BUG-12**
- **Hunter's claim:** Retention limits live only in the in-memory `_retentionLimits` map, so the user-set limit is silently unenforced after restart and the map grows unboundedly for deleted scenes — contradicting the 109.22 `retention_controls` contract with no user-visible caveat.
- **Skeptic's response:** UNCONFIRMED (55%): behavior verified but the session scope is documented twice in-repo (repository line 69 "sesi berjalan"; screen 1097–1099 "batas session-scoped mengikuti domain store") — a documented product decision, not a code defect at >67%.
- **Your analysis:** The behavior is real (line 70; `_enforceRetention` no-ops without an entry at 305–306; nothing persists the limit). But the scoping is explicitly documented at BOTH implementation layers and matches the canonical domain store, whose `retentionLimit` is equally session-scoped (`_DraftState.retentionLimit`). Deliberate, consistent, disclosed-in-code limitations are design decisions, not defects introduced unnoticed; the unbounded map is bounded by scene count and trivial. The genuine residue is product-level: the retention dialog's hint text (screen:1114) never tells the user the limit is session-scoped — a disclosure gap, not a code bug.
- **VERDICT: NOT A BUG** (documented session-scoped design; recommend persisting the limit as a product follow-up)
- **Confidence:** Medium

---

**BUG-13**
- **Hunter's claim:** `_kindFromDb` silently maps every unknown kind string to `restoreBackup`, misclassifying corrupt/future-version rows and corrupting the kind filter and UI label.
- **Skeptic's response:** DISPROVED (78%): the default arm is REQUIRED — restore backups are written as raw `'restoreBackup'` (line 356); no writer produces other strings; the UI prints the RAW DB row kind (screen:873), not the mapped enum; no in-scope caller passes `kind:`.
- **Your analysis:** Verified all three refutations. The only writers are `captureSceneDraftSnapshot` (`kind.name` ∈ {auto, manual}) and the restore backup (literal `'restoreBackup'`), so the default arm is what makes legitimate backups map correctly — removing it would break them. The screen at line 873 renders `snapshot.kind` from the DB row, so `_kindFromDb` never touches the label. The only consumer of the mapping is the `kind:` filter (325–327), which no in-scope caller uses. The "corrupt/future-version row" scenario is hypothetical and would be equally mishandled by any mapping choice.
- **VERDICT: NOT A BUG**
- **Confidence:** High

---

**BUG-14**
- **Hunter's claim:** `getStoryHierarchy` builds chapter→scene mapping with a nested linear scan — O(chapters × scenes²) with repeated full-list rescans — and `firstWhere` without `orElse` throws if `sceneNodes` ever contains an id absent from `scenes`.
- **Skeptic's response:** CONFIRMED (perf half, 85%); StateError sub-claim refuted as unreachable by construction.
- **Your analysis:** Perf half verified: lines 149–163 run `scenes.firstWhere` inside a `.where` over `sceneNodes` for EVERY chapter (O(C·S²)), repeated for arcs (164–177). The StateError sub-claim is refuted: `sceneNodes` is built 1:1 FROM `scenes` (137–148) and `chapterNodes` from `chapters`, so the lookups cannot miss. Realistic magnitudes (tens of chapters, hundreds of scenes → ~10⁵–10⁷ string comparisons per fetch) make this a wasteful-but-tolerable hotspot; the DB N+1 queries in the same method dominate. It compounds with BUG-17's per-keystroke refetch.
- **VERDICT: REAL BUG** (performance half only)
- **Confidence:** High
- **True severity:** Low (downgraded from Medium)
- **Suggested fix:** Precompute `Map<String,ChapterRow> sceneChapterById = {for (final s in scenes) s.id: s}` and `Map<String,ArcRow> chapterArcById` before the mapping; filter with map lookups — O(C·S + A·Ch).

---

**BUG-15**
- **Hunter's claim:** In `searchNovel`, a chapter-title match is counted once per scene of that chapter, inflating `matchCount` by the scene count for one string occurrence; the badge renders the inflated number.
- **Skeptic's response:** CONFIRMED (85%).
- **Your analysis:** Verified: story_repository_impl.dart:212–219 — `chapter.title` is loop-invariant across the per-scene loop, so one chapter-title hit adds +1 to every scene row of the chapter; the badge (screen:1486) renders it. Cosmetic but plainly wrong counts.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Compute the chapter-title contribution once per chapter (outside the scene loop) and either add it to a single representative row or report chapter matches separately from per-scene counts.

---

**BUG-16**
- **Hunter's claim:** `quickReferenceForScene` joins `member.characterId` against Characters `assetId` and silently drops misses — any id-space mismatch makes characters vanish without signal; per-member awaits are sequential (N round-trips).
- **Skeptic's response:** DISPROVED (88%): Characters' ONLY key is `assetId` (characters.dart:4,19) — no separate internal row id exists, so the join is the only possible one and matches the repo-wide convention (create_story_service, ai_context_resolver); `continue` handles dangling membership rows; sequential awaits are trivial.
- **Your analysis:** I verified tables/characters.dart: the primary key IS `assetId`; there is no alternate id-space for the claimed mismatch to occur in. The `continue` on null is defensive handling of a dangling SceneCharacters row (no FK), which has no data to display anyway. Sequential awaits over a scene's handful of members are negligible.
- **VERDICT: NOT A BUG**
- **Confidence:** High

---

**BUG-17**
- **Hunter's claim:** `_buildLiveChapters` creates `FutureBuilder(future: repository.getStoryHierarchy(widget.storyId))` inline in `build`, so every rebuild — every keystroke's setState, every autosave callback — launches a fresh full hierarchy query; combined with BUG-14's quadratic join, typing re-fetches and re-joins the entire story per keystroke.
- **Skeptic's response:** CONFIRMED (95%).
- **Your analysis:** Verified: screen:892–894 allocate a brand-new Future inside the builder, called from build (1370, and 1224 for the dedicated Outline section). `_count` (238–244) runs up to two `setState` per keystroke; onSaved/onSaveStarted/onPersistError setState per autosave tick. `getStoryHierarchy` issues arcs+chapters+scenes plus three queries per scene (N+1). Each rebuild also resets the FutureBuilder to the waiting state, so the CHAPTERS panel flashes "Memuat struktur story..." on every keystroke. Classic FutureBuilder-in-build anti-pattern on the hottest path.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Hold the hierarchy Future in State (created once per storyId, refreshed explicitly on structural changes or via an explicit reload method/refresh key) and pass the cached Future to FutureBuilder; never allocate a Future inside `build`.

---

**BUG-18**
- **Hunter's claim:** The FutureBuilder builder mutates State and kicks off async loads from inside `build`; the typed-before-hierarchy branch reschedules `_count` while a pending autosave may reference a different scene; `_loadDraftFor` can clobber typed text.
- **Skeptic's response:** CONFIRMED with corrections (75%): the typed-before-hierarchy sub-scenarios are refuted (no pending draft can exist with `_selectedSceneId == null`; the clobber there is guarded by `_draft.text.isEmpty`), but build-phase mutation is real and a genuine stale-async clobber exists via rapid scene switching.
- **Your analysis:** I verified the skeptic's corrections: with `_selectedSceneId == null`, `_count`'s guard (247) never called `onDraftChanged`, so no pending draft exists in that branch, and line 917 guards the reload. The real defects stand: (a) `_selectedSceneId/_selectedSceneTitle` are mutated inside the builder (914–916, 934–935) — a Flutter anti-pattern; (b) `_loadDraftFor` (965–970) has no request versioning — rapid scene switch A→B where A's `getSceneDraft` resolves after B's leaves the editor showing A's content under B's selection, and the next keystroke autosaves that mixed text into scene B (cross-scene content corruption path). Same unconditional pattern at 949–951 and 1503–1505.
- **VERDICT: REAL BUG** (build-phase mutation + stale-draft clobber; two cited sub-scenarios refuted)
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Add a monotonically increasing load sequence: `final seq = ++_sceneLoadSeq;` before the await; `if (seq != _sceneLoadSeq || !mounted) return;` after (apply to `_loadDraftFor`, `_loadSnapshotsFor`, `_loadQuickRefsFor`). Move first-scene default selection out of the builder into `initState`/post-frame or a guarded `didChangeDependencies`.

---

**BUG-19**
- **Hunter's claim:** `_restoreSnapshot` resets `_restoringSnapshotId` in `finally` but never calls `setState` on the failure path, leaving stale buttons and no visible recovery until an unrelated rebuild.
- **Skeptic's response:** DISPROVED (80%): the finally's `_loadSnapshotsFor` calls `setState` on success+mounted — the failure path does rebuild.
- **Your analysis:** Verified: on restore throw, finally (1191–1194) resets the flag and awaits `_loadSnapshotsFor(sceneId)`, which setStates (1048–1049) — buttons re-enable with fresh data. Stale buttons require the reload to ALSO fail, at which point the original error is already the uncaught-exception problem tracked under BUG-11. No distinct defect here.
- **VERDICT: NOT A BUG**
- **Confidence:** High

---

**BUG-20**
- **Hunter's claim:** `_exitFocusMode` calls `setState` unconditionally even with no active focus session — redundant rebuild and a hypothetical illegal setState-during-build.
- **Skeptic's response:** DISPROVED (85%): the only call site (line 687) is gated by `active`; nothing invokes it from build.
- **Your analysis:** Verified: `_focusToggle` (680–692) wires `onPressed: active ? _exitFocusMode : _enterFocusMode` — `_exitFocusMode` is unreachable while inactive, so the unconditional setState never fires spuriously, and a setState in a button callback is always legal. The during-build scenario has no caller.
- **VERDICT: NOT A BUG**
- **Confidence:** High

---

**BUG-21**
- **Hunter's claim:** `_completeLoreLink` computes `start = caret - query.length - 2` and treats `start < 0` as anchor failure, so a genuine `[[query` typed at the very start of the text cannot be accepted and the menu silently dies.
- **Skeptic's response:** DISPROVED (88%): `activeQueryAt` guarantees `query.length == caret - anchorStart - 2`, so `start == anchorStart ≥ 0` whenever the query matches a real anchor at the caret; negative start only means a stale query, where teardown is correct.
- **Your analysis:** I verified the algebra against lore_link_suggester.dart:92–108: `body = text.substring(start + 2, end)` with `end == caret` implies `caret - body.length - 2 == anchorStart`. For `[[a` at offset 0, `start == 0`, which passes the `start < 0` check and is accepted — the claimed scenario cannot occur. Negative start arises only when `_loreQuery` is stale relative to the caret (caret moved with left/right, which the menu doesn't intercept), and tearing down is then the correct behavior.
- **VERDICT: NOT A BUG**
- **Confidence:** High

---

**BUG-22**
- **Hunter's claim:** `_autosave`, `_draftJournal`, `_selectedSceneId` are captured once in `initState` with no `didUpdateWidget`, so a parent that swaps `draftJournal`/`repository`/`sceneId` on an existing element leaves the coordinator staging into the stale journal directory and stale repository.
- **Skeptic's response:** CONFIRMED with correction (72%): mechanism verified (no `didUpdateWidget`, resolver builds the screen with NO key, per-session journal dir), but the repository is NOT stale — the persist closure reads `widget.repository` live (line 178).
- **Your analysis:** Verified: `_selectedSceneId = widget.sceneId` (170), `_draftJournal = widget.draftJournal` (171), no `didUpdateWidget`/`didChangeDependencies` anywhere in the State; workspace_resolver.dart:188–202 constructs `StoryWorkspaceScreen` without a key and a fresh `DurableDraftJournal`+`StoryRepositoryImpl` each build — a story→story selection under the same element reuses the State with the previous story's scene id and the previous package's journal directory. The repository sub-claim is refuted (read live at 178). Residual hazard: between a story switch and the user selecting a scene in the new story, typed text routes into the OLD story's sceneId against the NEW repository, and journal staging goes to the old package's folder. Trigger depends on navigation specifics I cannot fully prove statically.
- **VERDICT: REAL BUG**
- **Confidence:** Medium (mechanism certain at code level; runtime trigger navigation-dependent)
- **True severity:** Low
- **Suggested fix:** Key the screen per story+session at the resolver call site (`key: ValueKey('${session.manifest.id}-${selection.assetId}')`), or implement `didUpdateWidget` to rebuild the journal/coordinator and reset scene state when `widget.storyId`/`widget.draftJournal` change.

---

**BUG-23**
- **Hunter's claim:** The DRAFT RECOVERY panel is not gated by `!_isFocusActive` (unlike every other chrome panel), contradicting the documented focus contract that side chrome disappears during an active session.
- **Skeptic's response:** UNCONFIRMED (55%): the placement fact is real, but the cited contract (writing_room_focus_test.dart:11–13) enumerates exactly "CHAPTERS, STORY BIBLE, NOVEL SEARCH, SCENE SNAPSHOTS, CHARACTER QUICK REF" — DRAFT RECOVERY is not among them — and the screen's own comment (1341–1343) says the recovery prompt is deliberately near the top for startup visibility.
- **Your analysis:** Verified both facts: the recovery block (1344–1350) sits outside the gate at 1359, and the documented chrome list does not include DRAFT RECOVERY. Keeping a pending-data-loss warning visible during focus is as plausibly intentional as an oversight; the cited contract cannot be breached by a panel it does not enumerate. A gating inconsistency exists, but not an established contract violation.
- **VERDICT: NOT A BUG** (inconsistency worth a deliberate product decision; no contract breach provable)
- **Confidence:** Medium

---

**BUG-24**
- **Hunter's claim:** `_loreHoverIndex = null` runs unconditionally per keystroke while the `_loreHighlight = 0` reset is guarded by `_loreQuery != query` — inconsistent state invalidation force-clears an unchanged mouse hover.
- **Skeptic's response:** UNCONFIRMED (55%): code reads as quoted, but the harm is a cosmetic re-hover requirement in an ephemeral autocomplete overlay; arguably intended reset semantics.
- **Your analysis:** Verified (294–296). In practice the active query changes on nearly every text change inside the link body (both resets fire together); unchanged-query syncs are rare, and `_setLoreHover` (413–416) re-arms on any mouse movement. No state corruption, no user-visible defect beyond a possible single re-hover.
- **VERDICT: NOT A BUG**
- **Confidence:** Medium

---

**BUG-25**
- **Hunter's claim:** `_showSnapshotDialog` awaits `captureSceneDraftSnapshot` with no try/catch or error surface, so the repository's `StateError('no draft content for scene ...')` (tapping Snapshot on a never-saved scene) escapes as an unhandled async exception with no user feedback.
- **Skeptic's response:** CONFIRMED (90%).
- **Your analysis:** Verified: screen:1171–1173 has no try/catch; repository:283–286 throws when `getSceneDraft` is null; a draft row exists only after the first autosave persist (`saveSceneDraft`), so tapping Snapshot on a fresh scene before the first debounce fires is an easily reached path: uncaught async exception, dialog silently produces nothing.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Wrap the capture in try/catch and surface a SnackBar ("Belum ada draf tersimpan — ketik atau tunggu autosave dahulu"); optionally disable the Snapshot button until a draft row exists.

---

## FINAL SUMMARY

**Stats:**
- Total reported by Hunter: 25
- Dismissed as false positives: 12 (BUG-5, 6, 7, 10, 12, 13, 16, 19, 20, 21, 23, 24)
- Confirmed as real bugs: 13
- **Critical: 0 | Medium: 5 (BUG-1, 2, 8, 17, 18) | Low: 8 (BUG-3, 4, 9, 11, 14, 15, 22, 25)**

**Confirmed bugs (ordered by severity):**

| # | Severity | File | Line(s) | Description | Suggested Fix |
|---|----------|------|---------|-------------|---------------|
| BUG-8 | Medium | durable_autosave_coordinator.dart (+durable_draft_journal.dart) | 96–105; journal 40/59/94–97 | acknowledge + same-scene pending clear drop content typed during an in-flight save (durable entry deleted, pending cleared, timer no-ops) — contradicts the class's own no-silent-loss contract | content-aware acknowledge (version token) + compare content before clearing pending |
| BUG-17 | Medium | story_workspace_screen.dart | 892–894, 1370, 1224, 238–244 | inline FutureBuilder future: full N+1 hierarchy query + loading flash per keystroke | cache the hierarchy Future in State; never allocate inside build |
| BUG-18 | Medium | story_workspace_screen.dart | 914–929, 964–970, 942–952, 1496–1506 | build-phase state mutation + unversioned `_loadDraftFor` clobber: stale scene draft overwrites editor, next keystroke autosaves mixed text into the wrong scene | load-sequence guards; move first-scene selection out of build |
| BUG-1 | Medium | durable_draft_journal.dart | 46–59, 66–88 | no fsync (doc overpromises) + `pendingEntries()` silently drops a crash-truncated `<scene>.json` — recovery loses the only unsaved copy with zero signal | surface corrupt `.json` entries; skip only `.json.tmp`; verify-before-rename; fix doc |
| BUG-2 | Medium | durable_draft_journal.dart (+durable_autosave_coordinator.dart:67–70, screen:251) | 33–35 | blank-content `ArgumentError` escapes uncaught through the unawaited `onDraftChanged` chain on every delete-all keystroke | handle blank as state transition; never throw through the unawaited chain |
| BUG-3 | Low | durable_draft_journal.dart | 40, 59, 68, 94–97 | orphaned `.json.tmp` after crash-before-rename; no sweep anywhere | startup sweep of stale `.json.tmp` |
| BUG-4 | Low | save_coordinator.dart | 46–49, 56–67 | mid-save `markDirty()` lost-update (clears `_dirty`, no reschedule); class is test-only at HEAD | reschedule in `finally` if still dirty |
| BUG-9 | Low | draft_snapshots.dart | 163–186 | set-based diff hides single-line replacements and inflates `unchangedCount` (no production consumer yet) | multiset (bag) counting per line |
| BUG-11 | Low | story_repository_impl.dart (+screen:1178–1195) | 346–347 | `firstWhere` without `orElse` → uncaught StateError on restore of a purged id; no user feedback (lockout claim refuted — finally always runs) | `orElse` + refresh + SnackBar |
| BUG-14 | Low | story_repository_impl.dart | 149–177 | O(chapters×scenes²) nested-scan hierarchy join (StateError sub-claim unreachable by construction) | precompute id→row maps |
| BUG-15 | Low | story_repository_impl.dart | 210–233 | chapter-title match counted once per scene → inflated `matchCount` badge | compute chapter contribution once per chapter |
| BUG-22 | Low | story_workspace_screen.dart (+workspace_resolver.dart:188–202) | 92, 97, 167–171 | no `didUpdateWidget`/key: element reuse carries stale `_draftJournal`/`_selectedSceneId` across story switches (repository sub-claim refuted — read live) | ValueKey per story+session, or `didUpdateWidget` reset |
| BUG-25 | Low | story_workspace_screen.dart (+story_repository_impl.dart:283–286) | 1171–1173 | `captureSceneDraftSnapshot` StateError on a never-saved scene escapes with no feedback | try/catch + SnackBar; disable button until draft exists |

**Low-confidence / flagged for manual review (verdict Medium confidence):**
- BUG-22 (REAL, Low) — mechanism code-certain; whether story→story switching reuses the element depends on runtime navigation specifics.
- BUG-12 (NOT A BUG) — documented session-scoped design; recommend persisting the limit as a product follow-up regardless.
- BUG-23 (NOT A BUG) — recovery-panel placement outside the focus gate is a real inconsistency; the cited contract does not enumerate DRAFT RECOVERY, so intent is unverifiable.
- BUG-24 (NOT A BUG) — cosmetic; unverifiable user impact.

**Ranked fix priority (highest impact / lowest risk first):**
1. **BUG-8** — silent data loss in the journal's core scenario; fix acknowledge+pending-clear semantics (moderate care needed around concurrency, but the class is small and well-tested).
2. **BUG-2** — one-line blank-content guard removes a guaranteed uncaught exception on a routine, hot path.
3. **BUG-17** — cache the hierarchy Future: large perf/UX win (per-keystroke N+1 query + panel flash), low risk.
4. **BUG-18** — load-sequence guards eliminate the stale-draft clobber (cross-scene text mixing) and the build-phase mutation.
5. **BUG-1** — surface corrupt journal entries instead of silent drop; temper the durability doc.
6. **BUG-11** — `orElse` + user feedback on missing snapshot.
7. **BUG-25** — try/catch + feedback on snapshot capture.
8. **BUG-15** — trivial search-count correction.
9. **BUG-14** — map-based hierarchy join (trivial, also softens BUG-17's cost).
10. **BUG-3** — startup `.tmp` sweep.
11. **BUG-9** — multiset diff before any diff UI ships.
12. **BUG-4** — reschedule-if-dirty in `SaveCoordinator.finally` (test-only class).
13. **BUG-22** — key/didUpdateWidget; verify navigation reuse first.

**Commit note:** hunter cited e5b26ab, the task cited 3464cbf, actual HEAD is a575572; the 6 in-scope files are byte-identical across all three except one moved blank line — verdicts apply to all three commits.
