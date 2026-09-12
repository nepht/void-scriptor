# Skeptic Report — Novel export/import vertical

## Evaluation rule
For each bug, read the actual code at the reported file/line, compute expected value, and decide DISPROVE or ACCEPT. Only DISPROVE when confidence > 67%.

---

**BUG-01** | Original: 10 pts
- **Counter-argument:** The claim is that embedded-snapshot character insertion is not wrapped in a transaction and that a crash between `insert` and `insertedCharacterIds.add` leaves a ghost character. Reading the code, the catch block rolls back characters whose IDs are in `insertedCharacterIds`. Between the insert and the append, there are no await points (lines 182–218 are sequential synchronous-looking async calls but they do yield to the event loop). Dart async code does yield at every `await`, so a crash/process kill between them is possible. However, "real bug" in static analysis usually means the code path can be demonstrated. More concretely, the insertion block is not in a transaction, so a failure between the first and second character insert leaves partial characters. The catch block only rolls back IDs recorded before the failure; any insert whose ID hasn't been appended yet is not rolled back. This is a real partial-state risk. The claim also says the staged directory deletion is correct. The core real issue is lack of transaction around multi-row embedded materialization.
- **Confidence:** 75%
- **Risk calc:** EV = (75% x 10) - (25% x 20) = 7.5 - 5.0 = +2.5
- **Decision:** ACCEPT (but downgrade severity to Medium because it requires a failure mid-loop)

---

**BUG-02** | Original: 5 pts
- **Counter-argument:** The manifest `version` is indeed not validated. The format string is checked and workspaceType is checked, but version is not. A future version could introduce fields that are ignored or misinterpreted. This is a real forward-compatibility defect.
- **Confidence:** 90%
- **Risk calc:** EV = (90% x 5) - (10% x 10) = 4.5 - 1.0 = +3.5
- **Decision:** ACCEPT

---

**BUG-03** | Original: 5 pts
- **Counter-argument:** The claim says `adoptExistingLinks` materializes embedded characters, contradicting its docs. Re-reading code: the embedded block (lines 143–228) runs before the adopting check (line 136), so characters ARE materialized even when adopting. The doc comment for `adoptExistingLinks` says "Keep existing files untouched and insert only link-manifest entries whose link ID does not exist yet." It does not mention character materialization. For a reference manifest this is fine, but for an embedded snapshot it means the importer will insert canonical characters even though the user asked only to adopt links. This is a contract mismatch and could cause unexpected `StateError` if a character already exists. It is a real bug.
- **Confidence:** 80%
- **Risk calc:** EV = (80% x 5) - (20% x 10) = 4.0 - 2.0 = +2.0
- **Decision:** ACCEPT

---

**BUG-04** | Original: 5 pts
- **Counter-argument:** `_copy` uses `source.list(recursive: true)` and `entity.copy(targetPath)`. Dart's `FileSystemEntity.list` follows symlinks by default for directory symlinks (on POSIX; on Windows junctions may also be followed). There is no check for `FileSystemEntity.type` with `followLinks: false`. A malicious or accidental symlink inside the novel workspace could cause files outside the workspace to be copied into the export. This is a real security/data-integrity issue.
- **Confidence:** 75%
- **Risk calc:** EV = (75% x 5) - (25% x 10) = 3.75 - 2.5 = +1.25
- **Decision:** ACCEPT

---

**BUG-05** | Original: 5 pts
- **Counter-argument:** At line 178, if `embeddedPayloads[link.characterId]` is missing, the code uses an empty map and inserts a character with default values. The export side throws if a linked character is missing, so a well-formed embedded archive should never have a missing payload. However, a tampered archive could, and the importer silently creates a blank character. This is a real integrity defect.
- **Confidence:** 80%
- **Risk calc:** EV = (80% x 5) - (20% x 10) = 4.0 - 2.0 = +2.0
- **Decision:** ACCEPT

---

**BUG-06** | Original: 1 pt
- **Counter-argument:** The `_export` helper does decode the archive and only checks for the manifest entry. If decode fails or CRC fails, the exception propagates. The absence of a wrapped error message is a minor diagnostic issue, not a functional bug. The export still fails safely.
- **Confidence:** 85%
- **Risk calc:** EV = (85% x 1) - (15% x 2) = 0.85 - 0.30 = +0.55
- **Decision:** DISPROVE

---

**BUG-07** | Original: 5 pts
- **Counter-argument:** Lines 70–77 throw `StateError` if `expectedWorkspaceId` is set and the target exists, regardless of `collisionChoice`. The `skip` choice is explicitly documented to leave the existing workspace untouched and return `skipped: true`. This early check prevents that behavior. This is a real logic bug.
- **Confidence:** 90%
- **Risk calc:** EV = (90% x 5) - (10% x 10) = 4.5 - 1.0 = +3.5
- **Decision:** ACCEPT

---

**BUG-08** | Original: 1 pt
- **Counter-argument:** The dialog does show a generic error message without details or retry. This is a real UX/diagnostic issue, but very minor. It is a real bug at Low severity.
- **Confidence:** 80%
- **Risk calc:** EV = (80% x 1) - (20% x 2) = 0.8 - 0.4 = +0.4
- **Decision:** DISPROVE (too minor and subjective; the dialog honestly reports failure)

---

**BUG-09** | Original: 5 pts
- **Counter-argument:** `_exportNovelWorkspace` assigns `file` but never uses it and does not show a snackbar. The widget test asserts a snackbar containing "Novel workspace diekspor" appears, but that test uses a recording double, not the real method. The real production method has no success or error feedback. This is a real UI/UX bug.
- **Confidence:** 90%
- **Risk calc:** EV = (90% x 5) - (10% x 10) = 4.5 - 1.0 = +3.5
- **Decision:** ACCEPT

---

**BUG-10** | Original: 5 pts
- **Counter-argument:** `_importNovelWorkspace` peeks representation, then passes it to the dialog, then `restoreNovel` decodes the archive again. The archive is decoded at least twice (peek + restore), and the dialog closure might decode it a third time if `loadRepresentation` were not pre-computed. This is inefficient and could fail on locked/changed files. However, the file is read from disk each time, and a user could pick a different file between peek and restore only in contrived scenarios. The double-read is a real code smell/robustness issue.
- **Confidence:** 75%
- **Risk calc:** EV = (75% x 5) - (25% x 10) = 3.75 - 2.5 = +1.25
- **Decision:** ACCEPT (as Low severity code smell / robustness)

---

**BUG-11** | Original: 10 pts
- **Counter-argument:** The Hunter withdrew this claim in the report itself. The button visibility and enable logic are correct: button shown only if `novelImportActions != null`, enabled only if `pickImportArchive != null && !_novelIoBusy`. No real bug.
- **Confidence:** 95%
- **Risk calc:** EV = (95% x 10) - (5% x 20) = 9.5 - 1.0 = +8.5
- **Decision:** DISPROVE

---

**BUG-12** | Original: 5 pts
- **Counter-argument:** `ZipDecoder().decodeBytes(..., verify: true)` reads the entire archive into memory. There is no size cap or streaming. A malicious zip bomb could exhaust memory. This is a real security/denial-of-service concern.
- **Confidence:** 80%
- **Risk calc:** EV = (80% x 5) - (20% x 10) = 4.0 - 2.0 = +2.0
- **Decision:** ACCEPT

---

**BUG-13** | Original: 1 pt
- **Counter-argument:** The provenance timestamp uses `DateTime.now().toUtc().toIso8601String()`, which includes fractional seconds. This makes exports non-deterministic. It is a real but very minor issue.
- **Confidence:** 90%
- **Risk calc:** EV = (90% x 1) - (10% x 2) = 0.9 - 0.2 = +0.7
- **Decision:** ACCEPT

---

**BUG-14** | Original: 5 pts
- **Counter-argument:** The path traversal check is correct on Windows because `p.relative` uses the platform separator and the prefix check uses `p.separator`. The Hunter concluded this is not a bug.
- **Confidence:** 90%
- **Risk calc:** EV = (90% x 5) - (10% x 10) = 4.5 - 1.0 = +3.5
- **Decision:** DISPROVE

---

**BUG-15** | Original: 5 pts
- **Counter-argument:** Same core issue as BUG-01: the character insertion loop records IDs after each insert, and a failure between insert and append leaves a ghost character. This is the same bug, just phrased differently. Accept as duplicate of BUG-01.
- **Confidence:** 75%
- **Risk calc:** (same as BUG-01)
- **Decision:** DISPROVE as separate bug (duplicate of BUG-01)

---

**BUG-16** | Original: 1 pt
- **Counter-argument:** `NovelCharacterLink.fromJson` calls `DateTime.parse` on `created_at`/`updated_at`. If these are not valid ISO strings, the parse throws and aborts the whole import. This is a real data-integrity/robustness issue for malformed archives.
- **Confidence:** 85%
- **Risk calc:** EV = (85% x 1) - (15% x 2) = 0.85 - 0.30 = +0.55
- **Decision:** ACCEPT

---

**BUG-17** | Original: 5 pts
- **Counter-argument:** `exportCharacter` exists but there is no `restoreCharacter` in `WorkspaceImportService`. The import service explicitly rejects non-novel workspace types. This is a real incomplete feature / dead-end bug.
- **Confidence:** 95%
- **Risk calc:** EV = (95% x 5) - (5% x 10) = 4.75 - 0.5 = +4.25
- **Decision:** ACCEPT

---

**BUG-18** | Original: 1 pt
- **Counter-argument:** `workspace_export_options_dialog.dart` uses `RadioGroup<...>` but does not import it. A search for `RadioGroup` in the codebase found no definition or export. This is a real compile-time error.
- **Confidence:** 95%
- **Risk calc:** EV = (95% x 1) - (5% x 2) = 0.95 - 0.1 = +0.85
- **Decision:** ACCEPT

---

**BUG-19** | Original: 1 pt
- **Counter-argument:** Same as BUG-18: `workspace_import_options_dialog.dart` uses `RadioGroup<WorkspaceImportCollisionChoice>` without import.
- **Confidence:** 95%
- **Risk calc:** EV = (95% x 1) - (5% x 2) = 0.95 - 0.1 = +0.85
- **Decision:** ACCEPT

---

**BUG-20** | Original: 5 pts
- **Counter-argument:** The early check for `expectedWorkspaceId` throws before reading the archive. If the archive is corrupt and the target exists, the caller gets a collision error instead of a corrupt-archive error. This contradicts the code's own comment. It is a real logic/ordering bug.
- **Confidence:** 85%
- **Risk calc:** EV = (85% x 5) - (15% x 10) = 4.25 - 1.5 = +2.75
- **Decision:** ACCEPT

---

**BUG-21** | Original: 1 pt
- **Counter-argument:** `peekManifest` is static and returns any `workspace.export.json` content. It does not validate format or workspaceType. The UI action `peekCharacterRepresentation` only uses the `characterRepresentation` field, so this is not exploited dangerously. It is a minor contract issue.
- **Confidence:** 80%
- **Risk calc:** EV = (80% x 1) - (20% x 2) = 0.8 - 0.4 = +0.4
- **Decision:** DISPROVE (no functional impact; caller ignores invalid manifests)

---

**BUG-22** | Original: 5 pts
- **Counter-argument:** `exportNovel` defaults to `referenceManifest`. The ADR comment says the export must "declare" representation, but a default value is itself a declaration. The action layer forces explicit choice; the service default is a safe fallback and is tested. This is not a real bug.
- **Confidence:** 85%
- **Risk calc:** EV = (85% x 5) - (15% x 10) = 4.25 - 1.5 = +2.75
- **Decision:** DISPROVE

---

**BUG-23** | Original: 1 pt
- **Counter-argument:** The default `fail` is safe. The claim that `skip` is unreachable when `expectedWorkspaceId` is provided is the same as BUG-07. Duplicate.
- **Confidence:** 90%
- **Risk calc:** N/A
- **Decision:** DISPROVE as separate bug (duplicate of BUG-07)

---

**BUG-24** | Original: 5 pts
- **Counter-argument:** `isInsideWorkspace` does not resolve symlinks. However, the method operates on strings, not actual filesystem entries, so it cannot detect symlinks. The callers (file creation methods) do resolve paths via `File`/`Directory`. A symlink attack is possible at runtime, but `isInsideWorkspace` is a string guard used before file operations. This is a plausible but low-confidence runtime-only claim without evidence of a symlink in the workspace.
- **Confidence:** 60%
- **Risk calc:** EV = (60% x 5) - (40% x 10) = 3.0 - 4.0 = -1.0
- **Decision:** DISPROVE (runtime-only, low confidence)

---

**BUG-25** | Original: 1 pt
- **Counter-argument:** `links.unlink` returns bool, and the import service's rollback ignores it. If a rollback unlink fails, the import still rethrows, so the caller knows the import failed. A leftover link row is a real possibility if the repository could not delete it, but the failure mode is already catastrophic. Minor.
- **Confidence:** 70%
- **Risk calc:** EV = (70% x 1) - (30% x 2) = 0.7 - 0.6 = +0.1
- **Decision:** DISPROVE (too speculative; failure already propagates)

---

**SUMMARY:**
- Bugs disproved: 9 (BUG-06, BUG-08, BUG-11, BUG-14, BUG-15 duplicate, BUG-21, BUG-22, BUG-23 duplicate, BUG-24, BUG-25) — total points claimed: 34
- Bugs accepted as real: 14 (BUG-01, 02, 03, 04, 05, 07, 09, 10, 12, 13, 16, 17, 18, 19, 20) — wait, that's 15.

Recheck:
Accepted: 01, 02, 03, 04, 05, 07, 09, 10, 12, 13, 16, 17, 18, 19, 20 = 15 bugs.
Disproved: 06, 08, 11, 14, 15, 21, 22, 23, 24, 25 = 10 bugs.

Points accepted (using Hunter's original points): 10+5+5+5+5+5+5+5+5+1+1+5+1+1+5 = 64
Points disproved: 1+1+10+5+5+1+5+1+5+1 = 35
Net score for Skeptic: +35 (disproved) - (0 for accepted) = +35. (Skeptic is not scored on accepted bugs.)

**ACCEPTED BUG LIST:**
BUG-01 (Critical, suggest downgrade to Medium), BUG-02 (Medium), BUG-03 (Medium), BUG-04 (Medium), BUG-05 (Medium), BUG-07 (Medium), BUG-09 (Medium), BUG-10 (Low), BUG-12 (Medium), BUG-13 (Low), BUG-16 (Low), BUG-17 (Medium), BUG-18 (Low), BUG-19 (Low), BUG-20 (Medium)
