# HUNTER REPORT — Void Scriptor draft-safety/autosave path (run128)

- Target: D:\VoidScriptor\void_scriptor_multiplatform (master @ e5b26ab8d12d48c5c9a91be778d9127af0e7f11e)
- Scope: 6 files (each read fully): durable_draft_journal.dart, save_coordinator.dart, durable_autosave_coordinator.dart, draft_snapshots.dart, story_workspace_screen.dart, story_repository_impl.dart
- Out-of-scope evidence used only to confirm claims (cited): lib/database/project/daos/story_dao.dart, lib/database/project/daos/character_dao.dart, lib/database/project/tables/characters.dart, lib/features/workspace/presentation/workspace_resolver.dart, test/features/story/writing_room_focus_test.dart, test/features/story/durable_autosave_coordinator_test.dart, lib/features/story/domain/lore_link_suggester.dart

---

## File 1: lib/features/project_resilience/application/durable_draft_journal.dart

---
**BUG-1** | Severity: Medium | Points: 5
- **File:** lib/features/project_resilience/application/durable_draft_journal.dart
- **Line(s):** 7-14, 46-59, 66-87
- **Category:** data-integrity
- **Claim:** `stage()` relies on `flush()` + `rename()` without fsync of file or directory, and `pendingEntries()` silently discards any `.json` entry that fails `jsonDecode`, so a power-loss can truncate the journal file and the staged draft is lost with no surfaced signal — contradicting the class's own "crash/power-loss tidak meninggalkan file setengah jadi" / no-silent-loss contract.
- **Evidence:**
```dart
/// ke `<scene>.json` sehingga crash/power-loss tidak meninggalkan file
/// setengah jadi.
...
      sink.write(payload);
      await sink.flush();          // flush() is Dart-buffer -> OS page cache, NOT fsync
      await sink.close();
...
    await temp.rename(_entryFile(sceneId).path);   // rename can persist before data blocks
...
      } on FormatException {
        // Entri korup (crash sebelum rename selesai) diabaikan: file
        // .tmp setengah jadi tidak pernah dianggap sumber pemulihan.
        continue;
```
The filter at lines 66-68 accepts any `*.json` (not only `.tmp`), so a crash-truncated `<scene>.json` matches the filter, fails `jsonDecode`, and is silently dropped by `continue` — invisible to recovery.
---

---
**BUG-2** | Severity: Medium | Points: 5
- **File:** lib/features/project_resilience/application/durable_draft_journal.dart
- **Line(s):** 32-38 (with durable_autosave_coordinator.dart:67-70)
- **Category:** error-handling / edge-case
- **Claim:** `stage()` throws `ArgumentError` for blank content, but clearing the editor is a normal user flow and `onDraftChanged` awaits `stage()` before registering the pending draft — so a delete-all keystroke throws through the unawaited async chain, the new pending state is never registered, and the exception escapes uncaught.
- **Evidence:**
```dart
  Future<void> stage({required String sceneId, required String content}) async {
    if (content.trim().isEmpty) {
      throw ArgumentError('journal content must not be blank');
    }
```
Caller (durable_autosave_coordinator.dart:67-70, in scope):
```dart
    await _journal?.stage(sceneId: sceneId, content: content);
    _pendingSceneId = sceneId;
    _pendingContent = content;
    _schedule();
```
No catch anywhere in the chain; on the throw, `_pendingSceneId/_pendingContent/_schedule()` are skipped and the error becomes an uncaught async exception.
---

---
**BUG-3** | Severity: Low | Points: 1
- **File:** lib/features/project_resilience/application/durable_draft_journal.dart
- **Line(s):** 59, 63-101
- **Category:** edge-case
- **Claim:** `.tmp` files that finished writing but crashed before `rename()` are orphaned forever: `pendingEntries()` ignores them, `acknowledge()` deletes only `<scene>.json`, and no code path sweeps the directory — the recovery folder grows without bound and stale `.tmp` payloads are never reclaimed.
- **Evidence:**
```dart
    await temp.rename(_entryFile(sceneId).path);
...
  Future<void> acknowledge(String sceneId) async {
    final file = _entryFile(sceneId);
    if (await file.exists()) await file.delete();
  }
```
No `.tmp` cleanup exists anywhere in the class (lines 63-101).
---

## File 2: lib/features/project_resilience/application/save_coordinator.dart

---
**BUG-4** | Severity: Medium | Points: 5
- **File:** lib/features/project_resilience/application/save_coordinator.dart
- **Line(s):** 46-49, 56-67
- **Category:** concurrency
- **Claim:** A `markDirty()` that arrives while `saveNow()` is in flight sets `_dirty = true` but the in-flight save then clears `_dirty` when it finishes, and nothing reschedules — the mid-save mutation is silently never persisted.
- **Evidence:**
```dart
  void markDirty() {
    _dirty = true;
    _schedule();
  }

  Future<void> saveNow() async {
    if (!_dirty || _saving) return;
    _saving = true;
    _timer?.cancel();
    try {
      await _persist();
      await _journal();
      _dirty = false;        // clears dirty flag set by markDirty() during _persist()
    } finally {
      _saving = false;       // no reschedule if _dirty became true mid-save
    }
  }
```
Contrast with the sibling coordinator (durable_autosave_coordinator.dart:100-105, 115-118), which explicitly preserves a mid-save pending draft and reschedules.
---

---
**BUG-5** | Severity: Medium | Points: 5
- **File:** lib/features/project_resilience/application/save_coordinator.dart
- **Line(s):** 60-66
- **Category:** error-handling
- **Claim:** The two-phase `saveNow()` has no failure isolation between `_persist()` and `_journal()`: if `_persist()` throws, `_dirty` stays true but `_journal()` is skipped on every retry attempt; if `_journal()` throws after a successful persist, the state remains dirty while the durable journal never records the sequence.
- **Evidence:**
```dart
      await _persist();
      await _journal();
      _dirty = false;
```
No try/catch separates the two steps; the doc comment (lines 6-8) claims the durable source of truth is the DB's `mutationSequence`/`savedMutationSequence` markers while this journal "only tracks the in-flight window" — but the in-flight window itself is never updated on any failure path.
---

## File 3: lib/features/story/application/durable_autosave_coordinator.dart

---
**BUG-6** | Severity: Medium | Points: 5
- **File:** lib/features/story/application/durable_autosave_coordinator.dart
- **Line(s):** 83-88 (with story_workspace_screen.dart:228-236, 1438)
- **Category:** concurrency
- **Claim:** `saveNow()` called while a save is in flight returns immediately without chaining onto the running save, so callers that `await` it (retry button, `dispose()`) resolve before the in-flight save completes and never observe its outcome.
- **Evidence:**
```dart
  Future<void> saveNow() async {
    _timer?.cancel();
    if (_saving) {
      _retryRequested = true;
      return;                 // resolves the caller's await immediately
    }
```
Callers in scope:
```dart
  @override
  void dispose() {
    _disposeStarted = true;
    _teardownLoreMenu();
    _autosave.dispose();      // not awaited; returns early if save in flight
    _draft.dispose();
    super.dispose();
  }
```
and the retry button (story_workspace_screen.dart:1438): `onPressed: () => _autosave.saveNow()`. If the debounce fires concurrently with a retry tap or dispose flush, the caller's `await` completes while `_persist` is still running — the ordering the API shape implies does not hold, and the controller can be garbage while its flush is still writing.
---

---
**BUG-7** | Severity: Medium | Points: 5
- **File:** lib/features/story/application/durable_autosave_coordinator.dart
- **Line(s):** 84, 100-118
- **Category:** edge-case
- **Claim:** When a save for scene A finishes and finds a pending draft for scene B (typed during the save), B's draft is left unsaved with no timer scheduled and no retry path unless `_retryRequested` happens to be set — B's content is only persisted by a later unrelated event (new keystroke or dispose flush).
- **Evidence:**
```dart
        if (_pendingSceneId == savedSceneId) {
          _pendingSceneId = null;
          _pendingContent = null;
        }
...
    } finally {
      _saving = false;
      if (_retryRequested) {
        _retryRequested = false;
        if (_pendingSceneId != null) _schedule();   // only reschedule path
      }
    }
```
On the normal (non-retry) path with a cross-scene pending draft, `_timer` was cancelled at line 84 and nothing reschedules; the stale `_autosaveError` banner from A also stays visible while B is pending.
---

---
**BUG-8** | Severity: Low | Points: 1
- **File:** lib/features/story/application/durable_autosave_coordinator.dart
- **Line(s):** 33-41, 96-98 (with durable_draft_journal.dart:94-97)
- **Category:** other (contract drift)
- **Claim:** `acknowledge` is keyed only by `sceneId` with no content/stagedAt check, so a successful retry acknowledges and deletes the scene-wide journal entry even if the entry currently on disk is a newer staging that was never persisted — the newest staged payload is silently lost.
- **Evidence:**
```dart
  /// Kontrak no-silent-loss: draf tetap pending dan entri journal durable
  /// tidak di-acknowledge sehingga konten terbaru tidak pernah hilang;
...
        await _persist(savedSceneId, savedContent);
        // Acknowledge hanya setelah persist sukses (no silent loss).
        await _journal?.acknowledge(savedSceneId);
```
```dart
  Future<void> acknowledge(String sceneId) async {
    final file = _entryFile(sceneId);
    if (await file.exists()) await file.delete();
  }
```
There is no verification that the acknowledged entry matches the content that was persisted.
---

## File 4: lib/features/story/domain/draft_snapshots.dart

---
**BUG-9** | Severity: Medium | Points: 5
- **File:** lib/features/story/domain/draft_snapshots.dart
- **Line(s):** 163-186
- **Category:** logic
- **Claim:** `diffWithCurrent` compares line *sets*, so duplicate lines inflate `unchangedCount` and pure reorderings report as 100% unchanged — the diff misrepresents real edits.
- **Evidence:**
```dart
    final snapshotLines = state.snapshots[index].content.split('\n');
    final currentLines = state.current.split('\n');
    final currentSet = currentLines.toSet();
    final snapshotSet = snapshotLines.toSet();
...
    var unchanged = 0;
    for (final line in snapshotLines) {
      if (currentSet.contains(line)) unchanged++;
    }
```
Snapshot `"A\nA\nB"` vs current `"A\nB\nB"` → `unchanged = 3`, `removed = []`, `added = []` despite 3 changed line slots; snapshot `"B\nA"` vs current `"A\nB"` → `unchanged = 2` with no diff at all.
---

---
**BUG-10** | Severity: Low | Points: 1
- **File:** lib/features/story/domain/draft_snapshots.dart
- **Line(s):** 60-64, 169-176
- **Category:** logic / data-integrity
- **Claim:** The documented contract "Baris yang ada di snapshot tapi hilang di teks kini (urut kemunculan)" is violated: multiplicity is handled inconsistently, so `removedLines`/`addedLines` can repeat a line that is logically one removal while the same line counts as unchanged elsewhere.
- **Evidence:**
```dart
  /// Baris yang ada di snapshot tapi hilang di teks kini (urut kemunculan).
  final List<String> removedLines;
...
    final removed = <String>[
      for (final line in snapshotLines)
        if (!currentSet.contains(line)) line,
    ];
```
Snapshot `"X\nX\nY"` vs current `"Y\nY\nZ"` yields `removed = ['X','X']` (two entries for one logical removal), while a current containing two `"X"` would mark both snapshot `X` lines unchanged — set membership ignores count for one list but the emitted list keeps duplicates.
---

## File 5: lib/features/story/data/story_repository_impl.dart

---
**BUG-11** | Severity: Critical | Points: 10
- **File:** lib/features/story/data/story_repository_impl.dart
- **Line(s):** 342-347 (with story_workspace_screen.dart:876-881, 1178-1195)
- **Category:** error-handling / data-integrity
- **Claim:** `restoreSceneDraftSnapshot` uses `firstWhere` without `orElse`, so restoring a snapshot id that no longer exists (retention-purged between listing and tap) throws an uncaught `StateError` that also skips `_restoreSnapshot`'s `finally`, leaving `_restoringSnapshotId` set — which permanently disables every Restore button until an unrelated successful restore.
- **Evidence:**
```dart
    final snapshots = await database.storyDao.getSceneDraftSnapshots(sceneId);
    final target = snapshots.firstWhere((s) => s.id == snapshotId);
```
Retention purges oldest rows on capture (lines 304-313), so a listed id can vanish while still on screen. Caller in scope (story_workspace_screen.dart:1178-1195):
```dart
    _restoringSnapshotId = snapshotId;
    try {
      final content = await repository.restoreSceneDraftSnapshot(
        sceneId,
        snapshotId: snapshotId,
      );
      if (!mounted) return;
      _draft.value = TextEditingValue(text: content);
      setState(() => _updateWordCount(content));
    } finally {
      _restoringSnapshotId = '';
      await _loadSnapshotsFor(sceneId);
    }
```
No `catch`; the `StateError` propagates out of the tap handler, `finally` never runs, and the button gate (line 877: `_restoringSnapshotId.isEmpty ? ... : null`) locks all Restore buttons with no recovery path. Data-integrity overlap: the user's restore intent is silently dropped.
---

---
**BUG-12** | Severity: Medium | Points: 5
- **File:** lib/features/story/data/story_repository_impl.dart
- **Line(s):** 69-70, 304-313, 369-378 (with draft_snapshots.dart:12-13)
- **Category:** data-integrity
- **Claim:** Snapshot retention limits live only in an in-memory `_retentionLimits` map on the repository, so the user-set limit is silently unenforced after app restart (snapshots accumulate past the limit again) and the map grows unboundedly for scenes that are later deleted.
- **Evidence:**
```dart
  /// Batas retensi per scene (sesi berjalan; snapshot itu sendiri persisten).
  final Map<String, int> _retentionLimits = <String, int>{};
...
  Future<void> _enforceRetention(String sceneId) async {
    final limit = _retentionLimits[sceneId];
    if (limit == null || limit <= 0) return;
```
The screen presents this as the 109.22 `retention_controls` contract (story_workspace_screen.dart:1097-1099) whose canonical rule is "batas jumlah snapshot per draf memangkas yang tertua" (draft_snapshots.dart:12-13); here enforcement dies with the process while snapshots persist — the promised trimming breaks across restarts with no user-visible caveat.
---

---
**BUG-13** | Severity: Medium | Points: 5
- **File:** lib/features/story/data/story_repository_impl.dart
- **Line(s):** 331-340
- **Category:** data-integrity
- **Claim:** `_kindFromDb` silently maps every unknown snapshot `kind` string to `DraftSnapshotKind.restoreBackup`, so corrupt or future-version rows are misclassified as restore backups instead of being surfaced or preserved.
- **Evidence:**
```dart
  DraftSnapshotKind _kindFromDb(String dbKind) {
    switch (dbKind) {
      case 'auto':
        return DraftSnapshotKind.auto;
      case 'manual':
        return DraftSnapshotKind.manual;
      default:
        return DraftSnapshotKind.restoreBackup;
    }
  }
```
An unknown/auto-derived kind written by another code path or newer version re-emerges as `restoreBackup` — corrupting `getSceneDraftSnapshots(kind: ...)` filtering (lines 325-327) and the UI label at story_workspace_screen.dart:873.
---

---
**BUG-14** | Severity: Medium | Points: 5
- **File:** lib/features/story/data/story_repository_impl.dart
- **Line(s):** 149-163
- **Category:** performance
- **Claim:** `getStoryHierarchy` builds chapter→scene mapping with a nested linear scan (`scenes.firstWhere` inside a `.where` over `sceneNodes` for every chapter), making hierarchy assembly O(chapters × scenes²)-shaped with repeated full-list rescans, and `firstWhere` without `orElse` throws `StateError` if `sceneNodes` ever contains an id absent from `scenes`.
- **Evidence:**
```dart
    final chapterNodes = chapters
        .map(
          (chapter) => StoryChapterNode(
            chapter.id,
            chapter.title,
            sceneNodes
                .where(
                  (s) =>
                      scenes.firstWhere((x) => x.id == s.id).chapterId ==
                      chapter.id,
                )
                .toList(),
          ),
        )
        .toList();
```
For every scene node it rescans the full `scenes` list via `firstWhere`, and the whole expression runs once per chapter; the same fragility pattern repeats for `chapters.firstWhere` in the arc mapping (lines 169-175).
---

---
**BUG-15** | Severity: Low | Points: 1
- **File:** lib/features/story/data/story_repository_impl.dart
- **Line(s):** 210-219 (with story_workspace_screen.dart:1485-1487)
- **Category:** logic
- **Claim:** In `searchNovel`, a chapter-title match is counted once per scene of that chapter, so a single chapter-title hit inflates `matchCount` by the scene count for the same one string occurrence.
- **Evidence:**
```dart
        for (final scene in scenes) {
          var count = 0;
          if (scene.title.toLowerCase().contains(needle)) count++;
          if (chapter.title.toLowerCase().contains(needle)) count++;
```
`chapter.title` is loop-invariant across the scene loop; the badge renders the inflated number (`'${result.matchCount}'`, screen line 1486).
---

---
**BUG-16** | Severity: Low | Points: 1
- **File:** lib/features/story/data/story_repository_impl.dart
- **Line(s):** 241-247
- **Category:** data-integrity
- **Claim:** `quickReferenceForScene` looks up characters by `member.characterId` against the Characters `assetId` key and silently drops misses via `continue`, so any id-space mismatch (internal row id vs assetId) makes characters vanish from quick-ref without any signal, and the per-member awaits are sequential (N round-trips).
- **Evidence:**
```dart
      final character = await database.characterDao.getCharacter(
        member.characterId,
      );
      if (character == null) continue;
```
Confirmed join target (lib/database/project/daos/character_dao.dart:29-31, out-of-scope confirmation): `getCharacter(String assetId) => ... row.assetId.equals(assetId)`; `Characters.assetId` is the key column (lib/database/project/tables/characters.dart:4). The in-scope code never validates that `characterId` belongs to the assetId id-space.
---

## File 6: lib/features/story/presentation/story_workspace_screen.dart

---
**BUG-17** | Severity: Medium | Points: 5
- **File:** lib/features/story/presentation/story_workspace_screen.dart
- **Line(s):** 892-894, 1370 (with 238-244)
- **Category:** performance
- **Claim:** `_buildLiveChapters` creates `FutureBuilder(future: repository.getStoryHierarchy(widget.storyId))` inline in `build`, so every rebuild — including every keystroke's `setState` from `_count` and every autosave callback — launches a fresh full hierarchy query; combined with BUG-14's quadratic join, typing re-fetches and re-joins the entire story per keystroke.
- **Evidence:**
```dart
    return FutureBuilder<StoryHierarchy>(
      future: repository.getStoryHierarchy(widget.storyId),
      builder: (context, snapshot) {
```
Invoked from `build` (line 1370: `_Panel(title: 'CHAPTERS', child: _buildLiveChapters(p))`); `_count` (lines 238-244) calls `setState` on every keystroke, and `onSaved`/`onSaveStarted`/`onPersistError` (lines 183-204) each `setState` per autosave tick.
---

---
**BUG-18** | Severity: Medium | Points: 5
- **File:** lib/features/story/presentation/story_workspace_screen.dart
- **Line(s):** 903-929, 965-970
- **Category:** logic / other
- **Claim:** The `FutureBuilder` builder mutates State (`_selectedSceneId`, `_selectedSceneTitle`) and kicks off async loads from inside `build` without `setState`, relying on side-effect ordering; the "user typed before hierarchy loaded" branch reschedules `_count(_draft.text)` via post-frame callback while the pending autosave draft may reference a different scene, and any rebuild re-entry can re-trigger the branch logic.
- **Evidence:**
```dart
        if (_selectedSceneId == null && firstScene != null) {
          _selectedSceneId = firstScene.id;
          _selectedSceneTitle = firstScene.title;
          if (_draft.text.isEmpty) {
            _loadDraftFor(firstScene.id);
            _loadSnapshotsFor(firstScene.id);
            _loadQuickRefsFor(firstScene.id);
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _count(_draft.text);
            });
          }
        }
```
State mutation during build is a Flutter anti-pattern; `_loadDraftFor` (965-970) unconditionally overwrites `_draft.value = TextEditingValue(text: content ?? '')`, so a late-loading draft for a stale scene id can clobber text the user already typed for the newly selected scene.
---

---
**BUG-19** | Severity: Low | Points: 1
- **File:** lib/features/story/presentation/story_workspace_screen.dart
- **Line(s):** 1182-1194
- **Category:** error-handling / UI state
- **Claim:** `_restoreSnapshot` resets `_restoringSnapshotId` in `finally` but never calls `setState` on the failure path, so a thrown restore leaves the widget un-rebuilt — stale buttons and no visible recovery until an unrelated rebuild.
- **Evidence:**
```dart
    _restoringSnapshotId = snapshotId;
    try {
      ...
    } finally {
      _restoringSnapshotId = '';
      await _loadSnapshotsFor(sceneId);
    }
```
`_loadSnapshotsFor` calls `setState` only on success+mounted (1044-1050); no `catch`, no `mounted` guard in the failure path.
---

---
**BUG-20** | Severity: Low | Points: 1
- **File:** lib/features/story/presentation/story_workspace_screen.dart
- **Line(s):** 674-677
- **Category:** logic
- **Claim:** `_exitFocusMode` calls `setState` unconditionally even when there is no active focus session, producing a redundant rebuild (and an illegal setState-during-build hazard if ever invoked from build).
- **Evidence:**
```dart
  void _exitFocusMode() {
    _focusSession?.exit();
    setState(() => _focusSession = null);
  }
```
Compare `_handleFocusEscape` (1537-1542), which correctly gates on `_isFocusActive`.
---

---
**BUG-21** | Severity: Low | Points: 1
- **File:** lib/features/story/presentation/story_workspace_screen.dart
- **Line(s):** 374-385
- **Category:** edge-case
- **Claim:** `_completeLoreLink` computes the `[[query` anchor as `start = caret - query.length - 2` and treats `start < 0` as an anchor failure, so a genuine `[[query` typed at the very start of the text (with caret still inside the first token) cannot be accepted via keyboard/enter and the menu silently dies.
- **Evidence:**
```dart
    final start = caret - query.length - 2;
    final expected = '[[$query';
    if (start < 0 || value.text.substring(start, caret) != expected) {
      _teardownLoreMenu();
      return;
    }
```
Negative `start` can only mean "the token would begin at offset 0 but is shorter than `[[$query`" — conflated with "no anchor"; the accept path dies even though `[[a` sits at offset 0.
---

---
**BUG-22** | Severity: Low | Points: 1
- **File:** lib/features/story/presentation/story_workspace_screen.dart
- **Line(s):** 92, 97, 168-182, 983-985
- **Category:** other (widget lifecycle)
- **Claim:** `_autosave`, `_draftJournal`, and `_selectedSceneId` are captured once in `initState` and the State never implements `didUpdateWidget`, so a parent that swaps `draftJournal`/`repository`/`sceneId` on an existing element (hot reload, resolver re-wrap) leaves the coordinator staging into the stale journal directory and the stale repository.
- **Evidence:**
```dart
  late final DurableAutosaveCoordinator _autosave;
...
  DurableDraftJournal? _draftJournal;
...
  @override
  void initState() {
    super.initState();
    _selectedSceneId = widget.sceneId;
    _draftJournal = widget.draftJournal;
```
Production wiring passes a per-package-directory journal (workspace_resolver.dart:188-194, out-of-scope confirmation):
```dart
      AssetType.story => StoryWorkspaceScreen(
        storyId: selection.assetId,
        draftJournal: session == null
            ? null
            : DurableDraftJournal(
                dir: Directory(
                  '${session.package.root.path}/recovery/draft-journal',
```
A session/package switch under the same element therefore stages drafts into the previous package's recovery folder.
---

---
**BUG-23** | Severity: Low | Points: 1
- **File:** lib/features/story/presentation/story_workspace_screen.dart
- **Line(s):** 1344-1350 vs 1359
- **Category:** logic
- **Claim:** The DRAFT RECOVERY panel is not gated by `!_isFocusActive` (unlike every other chrome panel), so entering focus mode with pending recovery entries keeps that panel rendered — contradicting the documented focus contract that side chrome disappears during an active session.
- **Evidence:**
```dart
                  if (_pendingRecovery.isNotEmpty) ...[
                    _Panel(
                      title: 'DRAFT RECOVERY',
                      child: _buildRecoveryPanel(p),
                    ),
```
vs the focus gate at line 1359: `if (!_isFocusActive) ...[`. Documented contract (test/features/story/writing_room_focus_test.dart:11-13, out-of-scope confirmation): "panel chrome (CHAPTERS, STORY BIBLE, NOVEL SEARCH, SCENE SNAPSHOTS, CHARACTER QUICK REF) tidak lagi dirender saat sesi aktif" — DRAFT RECOVERY is chrome but sits outside the gate.
---

---
**BUG-24** | Severity: Low | Points: 1
- **File:** lib/features/story/presentation/story_workspace_screen.dart
- **Line(s):** 294-296
- **Category:** logic
- **Claim:** `_loreHoverIndex = null` runs unconditionally on every keystroke while the `_loreHighlight = 0` reset is guarded by `_loreQuery != query`, so an unchanged mouse hover selection is force-cleared as the user types even though the pointer never moved — inconsistent state invalidation in the same block.
- **Evidence:**
```dart
    if (_loreQuery != query) _loreHighlight = 0;
    _loreHoverIndex = null;
    _loreQuery = query;
```
---

---
**BUG-25** | Severity: Low | Points: 1
- **File:** lib/features/story/presentation/story_workspace_screen.dart
- **Line(s):** 1171-1173 (with story_repository_impl.dart:283-286)
- **Category:** error-handling
- **Claim:** `_showSnapshotDialog` awaits `captureSceneDraftSnapshot` with no try/catch or error surface, so the repository's documented `StateError('no draft content for scene ...')` (the exact case of tapping Snapshot on a never-saved scene) escapes as an unhandled async exception and the user gets no feedback that their labeled snapshot was not recorded.
- **Evidence:**
```dart
    if (label == null || label.trim().isEmpty || !mounted) return;
    await repository.captureSceneDraftSnapshot(sceneId, label: label.trim());
    await _loadSnapshotsFor(sceneId);
```
```dart
    final draft = await getSceneDraft(sceneId);
    if (draft == null) {
      throw StateError('no draft content for scene $sceneId');
    }
```
---

## Cleared suspicions (checked, NOT bugs)

- Focus-mode chrome gating does exist (line 1359 `if (!_isFocusActive)`) — only DRAFT RECOVERY placement is inconsistent (BUG-23).
- `onSaved` callback guards `mounted` and clears `_autosaveError`/`_isSaving` correctly (lines 183-190).
- `onSaveStarted` correctly guards both `mounted` and `_disposeStarted` (lines 191-194).
- `durable_autosave_coordinator.saveNow` correctly preserves a same-scene pending draft typed mid-save (lines 100-105) — the gap is only cross-scene (BUG-7) and non-chaining await (BUG-6).
- `deleteSceneDraftSnapshotByIds` exists in the DAO (story_dao.dart:96-97) — BUG-12 is a lifecycle issue, not a missing API.
- `getStoryTitle` correctly rejects cross-project rows (repository lines 121-127).
- First-scene default selection (Run62) does route the first edit into the autosave path (lines 903-928).
- `LoreLinkSuggester.suggest` dedupes by normalized name and returns candidates in deterministic order (lore_link_suggester.dart:41-59) — screen consumption is consistent.

---

**TOTAL FINDINGS:** 25
**TOTAL SCORE:** 82

Breakdown: Critical 1 (BUG-11 = 10 pts) · Medium 12 (BUG-1, BUG-2, BUG-4, BUG-5, BUG-6, BUG-7, BUG-9, BUG-12, BUG-13, BUG-14, BUG-17, BUG-18 = 60 pts) · Low 12 (BUG-3, BUG-8, BUG-10, BUG-15, BUG-16, BUG-19, BUG-20, BUG-21, BUG-22, BUG-23, BUG-24, BUG-25 = 12 pts).
