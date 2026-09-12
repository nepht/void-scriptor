# REFEREE REPORT — vs-hunt-20260912-autosave

- **Role:** REFEREE (adversarial bug hunt adjudication)
- **Target:** Autosave & Draft Persistence subsystem (`lib/features/story/`, `lib/features/project_resilience/`)
- **Repo HEAD Context:** Adjudicated at HEAD 86a96da (files byte-identical to 4d905ed; project_resilience restore wiring feat 321de25 committed).

---

## Bug-by-Bug Adjudication

---
**BUG-1**
- **Hunter's claim:** Concurrent `stage()` calls for the same scene share one deterministic `.json.tmp` path, causing data corruption via truncated writes and failed renames.
- **Skeptic's response:** ACCEPT. Multi-step I/O await without mutex/unique temp path allows interleaving `FileMode.write` truncation and rename failures.
- **Your analysis:** Code inspection of `durable_draft_journal.dart` line 78 (`final temp = File('${_entryFile(sceneId).path}.tmp');`) confirms a single static temp file per scene. Parallel saves interleave writes and renames.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Critical
- **Suggested fix:** Use a per-call unique temp filename (e.g., UUID or timestamp suffix) before renaming to target.
---

---
**BUG-2**
- **Hunter's claim:** `onDraftChanged` awaits journal I/O before assigning pending state without sequence guard, allowing older out-of-order completions to overwrite newer edits.
- **Skeptic's response:** ACCEPT. Fire-and-forget callers without await/seq-guard permit interleaving completion of concurrent edits.
- **Your analysis:** `durable_autosave_coordinator.dart` lines 78–85 await `stage()` before updating `_pendingSceneId` and `_pendingContent`. Slower earlier requests completing after faster later requests overwrite pending state with stale data.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Critical
- **Suggested fix:** Introduce a generation/sequence counter or timestamp check so only the latest in-flight draft updates `_pendingContent`.
---

---
**BUG-3**
- **Hunter's claim:** `dispose()` does not flush pending content when a save is in flight, and schedules a post-dispose timer.
- **Skeptic's response:** ACCEPT. `saveNow()` early returns when `_saving` is true, and `finally` schedules a retry after `dispose()` has already finished.
- **Your analysis:** `durable_autosave_coordinator.dart` lines 50–55 and 144–157 confirm `dispose()` returns while a save is running, leaving a dangling timer referencing a disposed coordinator.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Track `_disposed` flag, await active save in `dispose()`, and suppress timer scheduling if disposed.
---

---
**BUG-4**
- **Hunter's claim:** Empty-content / delete-all acknowledge can delete a concurrently staged newer journal entry.
- **Skeptic's response:** ACCEPT. Unconditional acknowledge (`content: null`) deletes the entry file without checking if a newer stage arrived.
- **Your analysis:** `durable_draft_journal.dart` lines 192–215 show `acknowledge(sceneId)` without content performs blind deletion. If a non-empty stage arrived concurrently, it gets wiped.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Critical
- **Suggested fix:** Require content matching or generation checks for all acknowledge calls, or guard against staging concurrency.
---

---
**BUG-5**
- **Hunter's claim:** Snapshot restore does not flush or supersede the coordinator's pending autosave draft, causing stale pre-restore pending state to overwrite the restored draft.
- **Skeptic's response:** ACCEPT. `restoreSceneDraftSnapshot` interacts zero with the autosave coordinator, leaving `_pendingContent` intact to overwrite the DB on the next debounce tick.
- **Your analysis:** Code inspection confirms `story_repository_impl.dart` restore method updates DB directly without notifying `DurableAutosaveCoordinator`, creating a race where un-flushed pending edits overwrite the restore.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Critical
- **Suggested fix:** Have the repository or coordinator cancel/flush pending state and clear journal entries upon explicit snapshot restore.
---

---
**BUG-6**
- **Hunter's claim:** Acknowledge without content guard in replay/restore paths can delete newer staged entries.
- **Skeptic's response:** ACCEPT. Replay restore calls `acknowledge(entry.sceneId)` without content validation.
- **Your analysis:** Story workspace screen lines 1268–1269 invoke blind `acknowledge` after saving restored drafts, risking deletion of concurrent user edits.
- **VERDICT: REAL BUG**
- **Confidence:** Medium
- **True severity:** Medium
- **Suggested fix:** Pass the restored content to `acknowledge` for content validation.
---

---
**BUG-7**
- **Hunter's claim:** The restore sequence (backup-insert then draft-update) is not wrapped in a database transaction and is not crash-atomic.
- **Skeptic's response:** DISPROVE. Claimed duplicate beat creation assumes `beatType='draft'` which is never written in production codebase (verified via grep).
- **Your analysis:** Skeptic is correct that the specific duplicate-beat vulnerability relies on unwritten paths, but non-atomicity between backup and save remains a resilience flaw. However, without transaction wrapping, partial failures can occur. Let's uphold Skeptic's disprove on the primary multi-writer scenario, but note the lack of transaction.
- **VERDICT: NOT A BUG** (due to unreached production path for duplicate beats)
- **Confidence:** Medium
- **True severity:** Low
- **Suggested fix:** Wrap snapshot backup and draft update in `database.transaction(...)`.
---

---
**BUG-8**
- **Hunter's claim:** `saveSceneDraft` is a non-atomic check-then-insert causing PK collision under concurrent writers.
- **Skeptic's response:** ACCEPT. Select then insert without transaction or upsert throws `SqliteException` on concurrent saves.
- **Your analysis:** `story_repository_impl.dart` lines 72–95 perform `getSingleOrNull()` followed by `insert(...)` without transaction or conflict handling.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Use `insertOnConflictUpdate` or wrap in a transaction with upsert semantics.
---

---
**BUG-9**
- **Hunter's claim:** Retention prune selects oldest purely by wall-clock `createdAt` with no monotonic tie-breaker, risking pruning newer snapshots under clock shifts.
- **Skeptic's response:** ACCEPT. `createdAt` sorting without tie-breaker (`id` or rowid) permits wall-clock vulnerability.
- **Your analysis:** `story_dao.dart` orders solely by `createdAt`. System clock adjustments can misidentify snapshots.
- **VERDICT: REAL BUG**
- **Confidence:** Medium
- **True severity:** Low
- **Suggested fix:** Add secondary ordering term (e.g., `id` or primary key descending) to snapshot queries.
---

---
**BUG-10**
- **Hunter's claim:** Retention limits live only in an in-memory map per instance, lost on rebuild, so pruning stops after restart.
- **Skeptic's response:** ACCEPT. `WorkspaceResolver` rebuilds `StoryRepositoryImpl` on every build, resetting `_retentionLimits`.
- **Your analysis:** Code inspection of `workspace_resolver.dart` and `story_repository_impl.dart` confirms `_retentionLimits` is ephemeral instance state.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Store retention limits persistently in settings/database or manage them at a persistent service layer.
---

---
**BUG-11**
- **Hunter's claim:** Restore backup protected initially but deleted by subsequent retention enforcement.
- **Skeptic's response:** DISPROVE. `DraftSnapshotStore` domain model is never instantiated in production `lib/` (test-only).
- **Your analysis:** Skeptic correctly identifies that `DraftSnapshotStore` is test-only domain logic not wired in production `lib/`.
- **VERDICT: NOT A BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** N/A (Test-only domain class).
---

---
**BUG-12**
- **Hunter's claim:** `diffWithCurrent` and `restoreTo` take raw positional index with no bounds validation.
- **Skeptic's response:** DISPROVE. Domain model `DraftSnapshotStore` is test-only.
- **Your analysis:** Same as BUG-11; unreferenced domain store.
- **VERDICT: NOT A BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** N/A.
---

---
**BUG-13**
- **Hunter's claim:** `updateCurrent` rejects empty content while `diffWithCurrent`/persistence accepts empty.
- **Skeptic's response:** DISPROVE. Test-only domain store.
- **Your analysis:** Unreferenced domain store.
- **VERDICT: NOT A BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** N/A.
---

---
**BUG-14**
- **Hunter's claim:** Stale `.tmp` sweep uses local vs UTC clock mismatch and per-instance flag, disabling sweep.
- **Skeptic's response:** ACCEPT. `FileStat.modified` is local time while injected clock might be UTC, and per-instance flag resets on rebuild.
- **Your analysis:** `durable_draft_journal.dart` clock comparison and `_staleTmpSwept` instance scope confirm the logic flaws.
- **VERDICT: REAL BUG**
- **Confidence:** Medium
- **True severity:** Low
- **Suggested fix:** Normalize datetimes to UTC before comparison and perform sweep robustly or remove per-instance flag.
---

---
**BUG-15**
- **Hunter's claim:** Atomic stage provides no fsync of file contents or directory entry.
- **Skeptic's response:** ACCEPT. `flush()` in Dart IO does not guarantee OS-level fsync or directory entry persistence.
- **Your analysis:** Journal staging uses standard file sink without low-level OS sync, acknowledging power-loss vulnerability in doc comment.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Document limitation clearly or implement platform-specific file/directory sync if feasible.
---

---
**BUG-16**
- **Hunter's claim:** Unreadable/corrupt journal file in `acknowledge` keeps entry forever without quarantine.
- **Skeptic's response:** ACCEPT. Catch block returns without deleting or quarantining corrupt journal files.
- **Your analysis:** `durable_draft_journal.dart` lines 200–215 catch decode errors and return without retiring the corrupt file, causing infinite recovery loop attempts.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Move corrupt/unparseable journal entries to a quarantine directory upon read failure.
---

---
**BUG-17**
- **Hunter's claim:** Exception from post-persist acknowledge caught as persist failure ("Gagal menyimpan draf").
- **Skeptic's response:** ACCEPT. Persist and acknowledge share a single try-catch block.
- **Your analysis:** `durable_autosave_coordinator.dart` lines 110–142 wrap both DB/journal write and post-persist acknowledgment in one try-catch, misreporting acknowledge I/O errors as draft save failures.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Separate try-catch blocks for persist vs. journal acknowledgment.
---

---
**BUG-18**
- **Hunter's claim:** `_safeSceneId` sanitization can collide distinct scene ids into one journal filename.
- **Skeptic's response:** DISPROVE. Scene IDs are UUIDv4 (`[a-f0-9-]`), which are fully matched by `[A-Za-z0-9_-]`, so sanitization is an identity function for valid scene IDs.
- **Your analysis:** Skeptic's verification of UUIDv4 charset is correct; `_safeSceneId` produces identity output for standard UUIDs, making collisions impossible in production.
- **VERDICT: NOT A BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** N/A.
---

---
**BUG-19**
- **Hunter's claim:** Snapshot table declares no index on `sceneId` or `sceneId`+`createdAt`.
- **Skeptic's response:** ACCEPT. `SceneDraftSnapshots` table lacks secondary indexes.
- **Your analysis:** `scene_draft_snapshots.dart` defines only primary key `id`. Queries filtering and sorting by `sceneId` and `createdAt` lack index coverage.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Add an index on `(sceneId, createdAt)` in Drift table definition.
---

---
**BUG-20**
- **Hunter's claim:** `_kindFromDb` maps any unrecognized `kind` string silently to `restoreBackup`.
- **Skeptic's response:** ACCEPT. Switch default arm maps unknown strings to backup without error.
- **Your analysis:** `story_repository_impl.dart` lines 340–349 use a default case returning `DraftSnapshotKind.restoreBackup`, masking data corruption or migration typos.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Throw an exception or log a warning on unrecognized snapshot kinds rather than silent fallback.
---

---
**BUG-21**
- **Hunter's / Skeptic's check on stale temp file sweep:**
- **Skeptic's response:** DISPROVE. Stale `.tmp` sweep is a best-effort background check with negligible real-world impact and visible error handling.
- **Your analysis:** Agree with Skeptic that the stale tmp sweep logic is defensive best-effort and does not constitute a reproducible bug under normal usage.
- **VERDICT: NOT A BUG**
- **Confidence:** Medium
- **True severity:** Low
- **Suggested fix:** N/A.
---

---

## Final Report

**VERIFIED BUG REPORT**

Stats:
- Total reported by Hunter: 21
- Dismissed as false positives: 6 (BUG-7, BUG-11, BUG-12, BUG-13, BUG-18, BUG-21)
- Confirmed as real bugs: 15 (BUG-1, BUG-2, BUG-3, BUG-4, BUG-5, BUG-6, BUG-8, BUG-9, BUG-10, BUG-14, BUG-15, BUG-16, BUG-17, BUG-19, BUG-20)
- Critical: 4 | Medium: 6 | Low: 5

Confirmed bugs (ordered by severity):

| # | Severity | File | Line(s) | Description | Suggested Fix |
|---|----------|------|---------|-------------|---------------|
| BUG-1 | Critical | durable_draft_journal.dart | 76-98 | Shared temp file path (`.json.tmp`) causes concurrent write corruption | Per-call unique temp filename |
| BUG-2 | Critical | durable_autosave_coordinator.dart | 59-86 | Await journal I/O before pending assignment without seq-guard allows older overwriting newer | Sequence/generation counter |
| BUG-4 | Critical | durable_draft_journal.dart | 192-215 | Empty-content blind acknowledge deletes newer concurrent staged entry | Require content matching or concurrency lock |
| BUG-5 | Critical | story_repository_impl.dart | 351-380 | Snapshot restore does not flush coordinator pending autosave state | Flush/cancel pending state on restore |
| BUG-3 | Medium | durable_autosave_coordinator.dart | 98-157 | `dispose()` doesn't flush when save in-flight, schedules post-dispose timer | Track `_disposed` and await active save |
| BUG-6 | Medium | story_workspace_screen.dart | 1268-1269 | Replay restore calls blind acknowledge without content guard | Pass content for validation |
| BUG-8 | Medium | story_repository_impl.dart | 72-94 | Non-atomic check-then-insert `saveSceneDraft` causes PK collision | Use `insertOnConflictUpdate` or transaction |
| BUG-10 | Medium | story_repository_impl.dart & workspace_resolver.dart | 69-70 | Retention limits stored in ephemeral per-instance map lost on rebuild | Store limits persistently |
| BUG-15 | Medium | durable_draft_journal.dart | 13-21 | Atomic stage lacks low-level fsync / directory sync | Document or add platform fsync |
| BUG-16 | Medium | durable_draft_journal.dart | 200-215 | Corrupt journal file in acknowledge keeps entry forever | Quarantine corrupt files |
| BUG-9 | Low | story_dao.dart | 72-76 | Retention prune sorts by wall-clock `createdAt` without monotonic tie-breaker | Add secondary ordering term (`id`) |
| BUG-14 | Low | durable_draft_journal.dart | 43-260 | Stale `.tmp` sweep clock/instance guard flaws | Normalize to UTC / remove per-instance flag |
| BUG-17 | Low | durable_autosave_coordinator.dart | 109-142 | Acknowledge I/O error misreported as draft save failure | Separate try-catch for persist vs acknowledge |
| BUG-19 | Low | scene_draft_snapshots.dart | 7-19 | Snapshot table lacks index on `sceneId` and `createdAt` | Add Drift table index |
| BUG-20 | Low | story_repository_impl.dart | 340-349 | Unrecognized snapshot kind silently mapped to `restoreBackup` | Throw or log on unknown kind |

Low-confidence items (flagged for manual review):
- BUG-14 (Low confidence on real-world timing impact of stale tmp sweep)
- BUG-9 (Clock shift vulnerability is edge case)

---
## Fix Queue (Ordered by Priority)

1. **BUG-1 & BUG-2 (Critical Concurrency & Race Conditions)**
   - *Severity:* Critical
   - *Owning Files:* `lib/features/project_resilience/application/durable_draft_journal.dart`, `lib/features/story/application/durable_autosave_coordinator.dart`
   - *Reproduction Sketch (RED Assertion):* Test concurrent rapid keystrokes (`onDraftChanged` called simultaneously without await) and assert that neither the journal `.tmp` file corruption occurs nor does the older completion overwrite `_pendingContent`.

2. **BUG-4 & BUG-5 (Critical Data Loss & Restore Overwrite)**
   - *Severity:* Critical
   - *Owning Files:* `lib/features/project_resilience/application/durable_draft_journal.dart`, `lib/features/story/data/story_repository_impl.dart`
   - *Reproduction Sketch (RED Assertion):* Test triggering a snapshot restore while an autosave debounce or in-flight save is pending, and assert that the pending autosave does not overwrite the restored text.

3. **BUG-8 & BUG-10 (Repository Integrity & Retention Persistence)**
   - *Severity:* Medium
   - *Owning Files:* `lib/features/story/data/story_repository_impl.dart`, `lib/features/workspace/presentation/workspace_resolver.dart`
   - *Reproduction Sketch (RED Assertion):* Test concurrent `saveSceneDraft` calls and verify no `SqliteException` PK violation occurs; test setting retention limits and rebuilding resolver, verifying retention limits persist.

4. **BUG-3 & BUG-16 (Lifecycle & Corrupt Journal Resilience)**
   - *Severity:* Medium
   - *Owning Files:* `lib/features/story/application/durable_autosave_coordinator.dart`, `lib/features/project_resilience/application/durable_draft_journal.dart`
   - *Reproduction Sketch (RED Assertion):* Test calling `dispose()` during an active save and assert no timer fires post-disposal; test placing a corrupted JSON file in the journal directory and verify it is quarantined rather than failing infinitely.

5. **BUG-6, BUG-9, BUG-14, BUG-15, BUG-17, BUG-19, BUG-20 (Low/Medium Hygiene & Indexing)**
   - *Severity:* Low to Medium
   - *Owning Files:* Various DAO, table, and screen files.
   - *Reproduction Sketch (RED Assertion):* Add unit tests verifying index presence, distinct error reporting for acknowledge vs persist, and tie-breaker sorting in snapshot pruning.
