# HUNTER REPORT — vs-hunt-20260912-autosave

- **Role:** HUNTER (adversarial bug hunt, danpeg/bug-hunt hunter prompt)
- **Vertical:** Autosave / draft persistence (145.30 / 145.27 data-safety region)
- **Repo HEAD read:** 4bc3eb9 (task context pin; instructions manifest pins head_executed 4d905ed — both read from working tree, files verified at the 1,187-line scope)
- **Files read IN FULL (6/6, 1,187 lines):**
  1. `lib/features/story/application/durable_autosave_coordinator.dart` (158)
  2. `lib/features/story/domain/draft_snapshots.dart` (230)
  3. `lib/features/project_resilience/application/durable_draft_journal.dart` (288)
  4. `lib/features/story/data/story_repository_impl.dart` (394)
  5. `lib/database/project/daos/story_dao.dart` (98)
  6. `lib/database/project/tables/scene_draft_snapshots.dart` (19)
- **Also read read-only for confirmation (not reportable except as context):** `story_workspace_screen.dart` (caller: `_count` → fire-and-forget `onDraftChanged`, `_restorePendingDraft` → `acknowledge(sceneId)` null-content, `_restoreSnapshot` → repository restore + editor overwrite, scene-switch handler with no autosave flush), `workspace_resolver.dart` (journal constructed per build), `scene_beats.dart` / `story_scenes.dart` / `create_story_service.dart` (id schemes, beat types).
- **Method:** durability-ordering, retention, race, swallowed-error, stale-write, restore, and leak analysis per hunter instructions.

---
**BUG-1** | Severity: Critical | Points: 10
- **File:** lib/features/project_resilience/application/durable_draft_journal.dart
- **Line(s):** 76–98 (`_stageUntracked`; temp path at 78, sink at 84–97, rename at 97)
- **Category:** concurrency / data-integrity
- **Claim:** Concurrent `stage()` calls for the same scene share one deterministic `.json.tmp` path, so overlapping writes can rename a half-written sink and silently corrupt the ONLY durable copy of the user's unsaved draft.
- **Evidence:** `final temp = File('${_entryFile(sceneId).path}.tmp');` — no per-call unique suffix. The class explicitly anticipates parallel stages (`_inFlightStages`, line 41: "stage() paralel tidak saling menghapus tugas"), and the coordinator awaits `stage()` per keystroke from fire-and-forget `onDraftChanged` (caller line 322), so two keystrokes in flight both write the SAME `temp`: `sink.write(payload); await sink.flush(); await sink.close();` then `await _renameWithWindowsSharingRetry(temp, _entryFile(sceneId).path);` — writer A's rename can move a file that writer B's still-open sink has partially re-truncated (FileMode.write truncates at open), producing a truncated final `.json`. `pendingEntries()` then surfaces it as `PendingDraftEntry.corrupt` — and corrupt entries are documented as "TIDAK dapat direstore ulang ke repository" (line 283–285): unsaved user text is unrecoverable data loss.
---

**BUG-2** | Severity: Critical | Points: 10
- **File:** lib/features/story/application/durable_autosave_coordinator.dart
- **Line(s):** 59–86 (stage await at 78, pending assignment at 83–85)
- **Category:** concurrency / data-integrity
- **Claim:** `onDraftChanged` awaits journal I/O BEFORE assigning `_pendingSceneId/_pendingContent`, with no sequence/generation guard, so out-of-order completion of concurrent calls makes the OLDER edit win last — newer keystrokes are lost from both journal and pending state.
- **Evidence:**
  ```dart
  if (content.trim().isNotEmpty) {
    try { await _journal?.stage(sceneId: sceneId, content: content); }
    catch (error) { onPersistError?.call(sceneId, content, error); }
  }
  _pendingSceneId = sceneId;
  _pendingContent = content;
  _schedule();
  ```
  `stage()` includes multi-step file I/O plus the rename retry ladder (journal lines 110–136: up to 630 ms of delays on errno 5/32, or slow disk). If call("A") completes its await after call("AB") — trivially possible since the caller never awaits `onDraftChanged` (screen line 322) — then `_pendingContent` ends as "A", the journal file ends as "A" (BUG-1 path aside, last rename wins), and the debounce tick persists+acknowledges "A". The user's newer text "AB" exists only in the editor widget; a crash before the next keystroke loses it with no error surfaced — a direct violation of the class's own "no silent loss" contract (lines 10–18).
---

**BUG-3** | Severity: Medium | Points: 5
- **File:** lib/features/story/application/durable_autosave_coordinator.dart
- **Line(s):** 98–103, 144–150, 153–157
- **Category:** concurrency / resource-leak
- **Claim:** `dispose()` does NOT flush pending content when a save is already in flight — `saveNow()` early-returns after merely setting `_retryRequested`, so dispose resolves "successfully" with the draft unwritten, and the retry then creates a Timer that fires AFTER disposal, keeping a dead session writing.
- **Evidence:**
  ```dart
  Future<void> saveNow() async {
    _timer?.cancel();
    if (_saving) { _retryRequested = true; return; }
  ...
  Future<void> dispose() async { _timer?.cancel(); await saveNow(); }
  ```
  and in `finally`: `if (_retryRequested) { _retryRequested = false; if (_pendingSceneId != null) _schedule(); }`. The doc promise "`dispose()` mem-flush draf yang masih menunggu debounce" (line 16) is false in this window: dispose's awaited future completes before `_persist` of the latest content ever runs; `_schedule()` arms a fresh 1.5 s Timer on the disposed coordinator (its closure pins `_persist`, the journal, and the disposed-UI callbacks). If the app/scene is torn down within that window, the flush never happens and the awaited dispose was a lie to its caller.
---

**BUG-4** | Severity: Medium | Points: 5
- **File:** lib/features/story/application/durable_autosave_coordinator.dart
- **Line(s):** 117–126 (empty-content unconditional acknowledge)
- **Category:** concurrency / data-integrity
- **Claim:** The delete-all "unconditional acknowledge" can delete a CONCURRENTLY staged non-empty newer journal entry whose content was never persisted.
- **Evidence:**
  ```dart
  if (savedContent.trim().isEmpty) {
    await _journal?.acknowledge(savedSceneId);        // content: null => blind delete
  } else {
    await _journal?.acknowledge(savedSceneId, content: savedContent);
  }
  ```
  Sequence: saveNow flushes "   " (whitespace-only delete-all) → `_persist("   ")` awaits; meanwhile user types "Chapter 2…" → `onDraftChanged` stages "Chapter 2…" to the journal (it is non-empty, so it IS staged) and sets pending. The empty-branch then calls `acknowledge` with `content: null` — journal doc line 198–199 says null is only for explicit user decisions — deleting the never-persisted "Chapter 2…" entry. Pending is still "Chapter 2…" (line 132 check fails to clear), but the durable safety net for it is gone; a crash in the debounce window loses the text with no recovery entry — exactly the silent loss this branch claims to prevent. The content-aware branch's ordering (persist first, content-matched ack) would have been safe; the empty branch skips the same content comparison.
---

**BUG-5** | Severity: Medium | Points: 5
- **File:** lib/features/story/data/story_repository_impl.dart
- **Line(s):** 351–380 (`restoreSceneDraftSnapshot`), interacting with durable_autosave_coordinator.dart 98–136
- **Category:** stale-write / data-integrity
- **Claim:** Snapshot restore does not flush or supersede the coordinator's pending autosave draft, so the still-pending PRE-restore content overwrites the just-restored draft a debounce tick later — a stale out-of-order write that silently undoes the restore at the persistence layer.
- **Evidence:** restore path: `final current = await getSceneDraft(sceneId); if (current != null) { insert restoreBackup(current); } await saveSceneDraft(sceneId, target.content);` — `current` is the last PERSISTED draft, not the editor's live text. If the user has unflushed edits (coordinator `_pendingContent = "new unsaved"`, journal staged), the restore DB-writes `target.content`, then the in-flight/debounce `saveNow()` persists `_pendingContent` ("new unsaved") over it and content-aware-acknowledges the journal — the restore is reversed in storage while the UI still shows the restored text (`_draft.value = content` at caller line 1472). On the next scene switch the user sees the pre-restore text resurrected. The backup snapshot is also wrong: it captured the stale persisted draft, not what the user was actually looking at. No coordination hook (flush/cancel) exists on either side.
---

**BUG-6** | Severity: Medium | Points: 5
- **File:** lib/features/project_resilience/application/durable_draft_journal.dart
- **Line(s):** 192–215 (`acknowledge` with null `content`)
- **Category:** api-contract / data-integrity
- **Claim:** `acknowledge(sceneId)` without a content guard blindly deletes the newest staged journal entry, and the documented sanctioned caller (restore replay) uses precisely that form while a newer edit may already be staged for the same scene.
- **Evidence:**
  ```dart
  Future<void> acknowledge(String sceneId, {String? content}) async {
    final file = _entryFile(sceneId);
    if (!await file.exists()) return;
    if (content != null) { ... if (decoded['content'] != content) return; }
    await file.delete();
  }
  ```
  The doc comment permits null for "replay restore", and the workspace replay path does `await repository.saveSceneDraft(entry.sceneId, entry.content); await widget.draftJournal?.acknowledge(entry.sceneId);` (screen line 1268–1269). If the editor for that scene holds a newer unflushed edit (staged after `pendingEntries()` was read), the blind delete removes the newer entry between its read and delete; a crash before the pending autosave persists the newer text loses it. There is no "acknowledge the entry I showed the user" (generation/stagedAt) check to make this replay safe.
---

**BUG-7** | Severity: Medium | Points: 5
- **File:** lib/features/story/data/story_repository_impl.dart
- **Line(s):** 351–380 (restore), 72–95 (`saveSceneDraft`)
- **Category:** data-integrity / error-handling
- **Claim:** The restore sequence (backup-insert then draft-update) is not wrapped in a database transaction and is not crash-atomic; each drift statement auto-commits independently.
- **Evidence:** `await database.storyDao.insertSceneDraftSnapshot(... kind: 'restoreBackup', content: current ...); await saveSceneDraft(sceneId, target.content);` — a failure/crash between the two commits leaves the backup recorded but the draft unrestored (or, on retry after partial UI state, duplicate identical `restoreBackup` rows since nothing dedupes). Same non-atomicity in `saveSceneDraft`: read (`getSingleOrNull`) → insert → later retention prune in `captureSceneDraftSnapshot` (lines 298–309) are three separate auto-committed steps; no `database.transaction(...)` anywhere in the draft write path despite the "SELALU mencadangkan teks kini lebih dulu" durability contract in the table docs.
---

**BUG-8** | Severity: Low | Points: 1
- **File:** lib/features/story/data/story_repository_impl.dart
- **Line(s):** 72–95
- **Category:** concurrency
- **Claim:** `saveSceneDraft` is a non-atomic check-then-insert (no upsert, no transaction), so two concurrent writers for the same scene (autosave flush vs restore-replay/restore) hit a primary-key collision on `'${sceneId}_draft'` instead of the second writer updating.
- **Evidence:** select `getSingleOrNull()` → `into(...).insert(SceneBeatsCompanion.insert(id: '${sceneId}_draft', ...))` → else update. Both callers can run concurrently (coordinator persist + `_restorePendingDraft`), both see `existing == null`, second insert throws SqliteException (surfaced as a spurious "Gagal menyimpan draf" even though the row exists with other content).
---

**BUG-9** | Severity: Low | Points: 1
- **File:** lib/features/story/data/story_repository_impl.dart
- **Line(s):** 313–322; story_dao.dart 72–76
- **Category:** pruning / edge-case
- **Claim:** Retention prune selects "oldest" purely by wall-clock `createdAt` with no secondary ordering key, so same-millisecond snapshots or a rolled-back system clock can make the NEWEST snapshot the prune victim.
- **Evidence:** `final all = await database.storyDao.getSceneDraftSnapshots(sceneId); ... final toDelete = all.take(excess)...` with DAO `..orderBy([(t) => OrderingTerm(expression: t.createdAt)])` only, and writers stamp `createdAt: DateTime.now()` (non-monotonic). A capture issued right after a clock adjustment sorts "oldest" and is deleted immediately; the doc's own restore error message ("mungkin sudah dipangkas retensi", line 359) shows losing that snapshot is an anticipated user experience.
---

**BUG-10** | Severity: Low | Points: 1
- **File:** lib/features/story/data/story_repository_impl.dart
- **Line(s):** 69–70, 384–393
- **Category:** retention / contract-divergence
- **Claim:** Retention limits live only in an in-memory `_retentionLimits` map, contradicting the table doc that claims retention persists across restarts, so after every restart pruning silently stops and snapshots accumulate unbounded.
- **Evidence:** `/// Batas retensi per scene (sesi berjalan; ...)` + `final Map<String, int> _retentionLimits` vs `scene_draft_snapshots.dart` lines 5–7: "Persistensi lintas restart: capture/restore/retensi mengikuti kontrak DraftSnapshotStore". A fresh `StoryRepositoryImpl` per workspace session (resolver constructs it at widget-build) re-prunes nothing until the user re-enters the retention limit.
---

**BUG-11** | Severity: Low | Points: 1
- **File:** lib/features/story/domain/draft_snapshots.dart
- **Line(s):** 89–94, 206–221
- **Category:** retention / contract-divergence
- **Claim:** The guarantee that restore backups are protected and "snapshot asli tetap dapat dipulihkan ulang" holds only until the next capture, because `restoreTo` defers no retention and the next `_enforceRetention` removes strictly from index 0 — including the pre-restore `restoreBackup` when the limit is tight.
- **Evidence:** `restoreTo` adds `DraftSnapshotKind.restoreBackup` and never enforces retention (comment "dikecualikan dari pemangkasan retensi pada saat itu"); the next `captureAuto`/`captureManual` runs `state.snapshots.removeRange(0, excess)` with no kind exemption — with limit 1, capturing once after a restore deletes the only backup of the pre-restore text.
---

**BUG-12** | Severity: Low | Points: 1
- **File:** lib/features/story/domain/draft_snapshots.dart
- **Line(s):** 168–171, 209–211
- **Category:** edge-case / error-handling
- **Claim:** `diffWithCurrent` and `restoreTo` take a raw positional `index` with no bounds validation, and any concurrent prune silently renumbers it — a stale index restores or diffs the WRONG snapshot rather than failing.
- **Evidence:** `final snapshotLines = state.snapshots[index].content.split('\n');` / `final target = state.snapshots[index];` — no length check (RangeError on out-of-range, mis-target after `removeRange`). Positional identity combined with `_enforceRetention` shifting indices has no id-based alternative in the API.
---

**BUG-13** | Severity: Low | Points: 1
- **File:** lib/features/story/domain/draft_snapshots.dart
- **Line(s):** 97–104, 168–171
- **Category:** edge-case / contract-divergence
- **Claim:** `updateCurrent` rejects empty content while `diffWithCurrent` accepts a draft with no current text and diffs against the initial `''` (and the durable/persist layer happily stores empty drafts), so domain and persistence disagree on whether empty is a legal draft state.
- **Evidence:** `if (content.isEmpty) { throw ArgumentError('current text must not be empty'); }` vs `diffWithCurrent` using `_stateFor` (creates state with `current = ''`, `hasCurrent = false`) without `_requireCurrent`; meanwhile `saveSceneDraft` persists `''` after delete-all and `_kindFromDb`/capture operate on it.
---

**BUG-14** | Severity: Low | Points: 1
- **File:** lib/features/project_resilience/application/durable_draft_journal.dart
- **Line(s):** 43–47, 244–260 (247, 252–253); 30–31 (`_clock`)
- **Category:** edge-case / resource-leak
- **Claim:** The stale-`.tmp` sweep compares an injectable wall clock against local `stat.modified` and is armed once per instance, so a UTC-injected clock (the journal itself writes `toUtc()` timestamps) disables the sweep entirely, and instances recreated per build (resolver constructs a new journal on rebuild) never carry the sweep flag across sessions with stale state.
- **Evidence:** `final now = _clock(); ... if (now.difference(stat.modified) < staleTmpThreshold) continue;` — `FileStat.modified` is local-time; a `_clock` returning `DateTime.now().toUtc()` yields a ~UTC-offset-negative difference, always `< threshold` → orphans never cleaned. `_staleTmpSwept` guards only per-instance repetition; the design comment's "instance baru" recovery relies on someone eventually constructing one AND calling `pendingEntries()`.
---

**BUG-15** | Severity: Low | Points: 1
- **File:** lib/features/project_resilience/application/durable_draft_journal.dart
- **Line(s:** 13–21, 84–97)
- **Category:** durability
- **Claim:** The "atomic" stage provides no fsync of file contents nor the directory entry before rename, so the acknowledged durable journal itself can be lost or truncated by power loss — acknowledged in the doc comment but the coordinator's entire no-silent-loss contract (and its "crash sebelum autosave tidak pernah kehilangan suntingan" promise) rests on this weakest link.
- **Evidence:** `await sink.flush(); await sink.close(); ... await _renameWithWindowsSharingRetry(temp, ...)` with the file's own note: "`flush()` dart:io tidak menjamin fsync OS-level/directory-entry, jadi kehilangan data saat power-loss total tidak sepenuhnya dapat dihilangkan di layer ini." No `File.flush`-style sync (e.g., opening with `FileMode.write` + platform sync) and no directory fsync exists at all on this path.
---

**BUG-16** | Severity: Low | Points: 1
- **File:** lib/features/project_resilience/application/durable_draft_journal.dart
- **Line(s):** 200–215 (204–212)
- **Category:** error-handling
- **Claim:** When a persist succeeded but the journal file is unreadable/corrupt, `acknowledge` silently keeps the entry forever — the DRAFT RECOVERY panel will then repeatedly offer to restore an already-saved (possibly older) draft over the user's current text.
- **Evidence:** `try { final decoded = jsonDecode(await file.readAsString()) ...; } on Object { // ... jangan hapus buta ... return; }` — there is no path (quarantine, rename-aside, timestamp check) that ever retires such an entry; the coordinator's content-aware ack will keep failing the same way on every retry.
---

**BUG-17** | Severity: Low | Points: 1
- **File:** lib/features/story/application/durable_autosave_coordinator.dart
- **Line(s):** 109–143
- **Category:** error-handling / state-reporting
- **Claim:** An exception from the post-persist `acknowledge` (or from `onSaved`) is caught by the same handler as a persist failure, so the UI reports "Gagal menyimpan draf" and skips the saved-label even though the draft IS durably saved.
- **Evidence:** `try { await _persist(...); ... await _journal?.acknowledge(...); onSaved?.call(...); ... } catch (error) { onPersistError?.call(savedSceneId, savedContent, error); }` — persist success + ack I/O error collapses into the failure branch; state (indicator, label) diverges from storage truth until the next edit.
---

**BUG-18** | Severity: Low | Points: 1
- **File:** lib/features/project_resilience/application/durable_draft_journal.dart
- **Line(s):** 49–53
- **Category:** edge-case / data-integrity
- **Claim:** `_safeSceneId` sanitization can collide distinct scene ids into one journal filename (every non-`[A-Za-z0-9_-]` char maps to `_`), letting one scene's staging overwrite or acknowledge-delete another scene's entry.
- **Evidence:** `sceneId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_')` — e.g. `a/b`, `a:b`, `a-b` all become `a_b`; the real `sceneId` inside the JSON keeps entries decodable but the FILES (and thus stage/acknowledge/pending granularity) are merged. Today's UUID ids happen not to collide; the journal silently trusts that invariant with no assertion.
---

**BUG-19** | Severity: Low | Points: 1
- **File:** lib/database/project/tables/scene_draft_snapshots.dart
- **Line(s):** 7–19
- **Category:** performance
- **Claim:** The snapshot table declares no index on `sceneId` (or `sceneId`+`createdAt`) even though every query and prune filters and sorts by them, so each autosave-adjacent capture/restore list rebuild is a growing full scan of verbatim manuscript copies.
- **Evidence:** `class SceneDraftSnapshots extends Table { TextColumn get id ...; TextColumn get sceneId => text()(); ... Set<Column<Object>> get primaryKey => {id}; }` — contrast DAO queries `where((t) => t.sceneId.equals(sceneId))..orderBy(createdAt)` (story_dao.dart 72–76) executed on every snapshot list, capture, restore, and retention pass.
---

**BUG-20** | Severity: Low | Points: 1
- **File:** lib/features/story/data/story_repository_impl.dart
- **Line(s):** 340–349
- **Category:** type-safety / data-integrity
- **Claim:** `_kindFromDb` maps ANY unrecognized `kind` string (typo, future enum member, hand-edited row) to `restoreBackup`, so an unrecognized snapshot is silently mislabeled and becomes invisible to kind-filtered listing (`getSceneDraftSnapshots(kind: …)`) instead of erroring.
- **Evidence:** `switch (dbKind) { case 'auto': ...; case 'manual': ...; default: return DraftSnapshotKind.restoreBackup; }` — combined with `write` sites using `kind.name`, an evolution of `DraftSnapshotKind` silently buckets new kinds into backup and filters drop them from `kind:` queries.
---

**TOTAL FINDINGS:** 20
**TOTAL SCORE:** 48
