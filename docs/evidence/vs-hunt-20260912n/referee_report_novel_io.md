# Referee Report — Novel export/import vertical

For each Hunter finding, I independently read the actual code and the Skeptic's response, then issued a verdict.

---

**BUG-01**
- **Hunter's claim:** Embedded-snapshot character insertion is not transactional; a failure between insert and ID recording can leave a ghost canonical character.
- **Skeptic's response:** ACCEPT (downgrade to Medium).
- **Your analysis:** Reading `workspace_import_service.dart` lines 163–227, characters are inserted one at a time and their IDs are appended to `insertedCharacterIds` after each insert. The rollback catch block (lines 220–226) only deletes IDs in that list. There is no `database.transaction(...)` wrapping the materialization. In Dart, every `await` yields control, so a process kill, unhandled async exception, or even a disk failure between `insert` and `add` can leave a character row with no link. This is a real data-integrity bug. The impact is medium because it requires an import failure mid-loop, but the consequence is a ghost canonical character.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Wrap the entire embedded-snapshot materialization (pre-existence check, inserts, and link inserts) in a single `await database.transaction(() async { ... })` so Drift rolls back all rows on any failure.

---

**BUG-02**
- **Hunter's claim:** Manifest `version` is not validated.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Lines 98–104 check `format` and `workspaceType` but never assert `manifest['version'] == 1`. A future archive with `version: 2` would be processed with version-1 semantics. Real forward-compatibility bug.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Add `if (manifest['version'] != 1) throw const FormatException('Unsupported Novel workspace export version');`.

---

**BUG-03**
- **Hunter's claim:** `adoptExistingLinks` still materializes embedded characters, contradicting its documented "insert only link-manifest entries" behavior.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** The embedded-character block (lines 143–228) runs before the `adopting` flag is tested (line 136). Therefore, even when the caller chose `adoptExistingLinks`, canonical characters are inserted if not present, and a pre-existing character triggers a hard `StateError`. The doc comment on the enum says "Keep existing files untouched and insert only link-manifest entries whose link ID does not exist yet." Character materialization is not mentioned and can abort an otherwise safe adopt operation. Real bug.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Skip embedded character materialization when `adopting` is true, or document and reject `adoptExistingLinks` for non-reference archives.

---

**BUG-04**
- **Hunter's claim:** `_copy` follows symlinks and could include files outside the workspace.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** `_export` copies the source directory using `_copy` (lines 180–192), which calls `source.list(recursive: true)` and `entity.copy(targetPath)`. Dart's directory listing follows directory symlinks by default; there is no `followLinks: false` or `FileSystemEntity.type` check. A symlink inside the novel workspace would cause external files to be archived. Real security/data-integrity bug.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Use `source.list(recursive: true, followLinks: false)` and skip symlinked files/directories, or resolve with `FileSystemEntity.type(..., followLinks: false)`.

---

**BUG-05**
- **Hunter's claim:** Missing embedded payload silently creates a blank canonical character.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Line 178 uses `embeddedPayloads[link.characterId] ?? const <String, dynamic>{}`. If a tampered archive declares a link but omits its `workspace/characters/<id>.json` payload, the importer inserts a character with only defaults. The export side correctly fails on missing characters, but the importer does not enforce the same contract. Real bug.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Throw `FormatException('Missing embedded character payload for ${link.characterId}')` when the payload is absent for a non-reference archive.

---

**BUG-06**
- **Hunter's claim:** `_export` verification throws generic error without context.
- **Skeptic's response:** DISPROVE.
- **Your analysis:** The verification decodes the archive and throws `StateError('Workspace export verification failed')` only when the manifest entry is missing. Other exceptions propagate as-is. This is a diagnostic limitation, not a functional defect. The export fails safely.
- **VERDICT: NOT A BUG**

---

**BUG-07**
- **Hunter's claim:** `expectedWorkspaceId` early check ignores `collisionChoice == skip`.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Lines 70–77 throw `StateError` whenever `expectedWorkspaceId` is set and the target exists, even if `collisionChoice` is `skip`. The `skip` choice is documented to return `WorkspaceRestoreResult(skipped: true)`. This makes `skip` unreachable with `expectedWorkspaceId`. Real logic bug.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Move the `expectedWorkspaceId` collision check after the archive is validated and respect `collisionChoice == skip`.

---

**BUG-08**
- **Hunter's claim:** Import dialog error state is generic with no retry.
- **Skeptic's response:** DISPROVE.
- **Your analysis:** Line 109 shows `const Text('Failed to read the archive.')`. This is a minor UX issue, not a functional bug. The confirm button remains disabled, which is correct.
- **VERDICT: NOT A BUG**

---

**BUG-09**
- **Hunter's claim:** `_exportNovelWorkspace` does not show success/error feedback.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** `story_workspace_screen.dart` lines 774–798 assign the exported file to a local variable and do nothing with it; no snackbar is shown on success or failure. The widget test only verifies behavior with recording doubles. In production, the user gets no confirmation. Real UI bug.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Show a `ScaffoldMessenger` snackbar with the exported path on success and an error message on exception.

---

**BUG-10**
- **Hunter's claim:** Archive is decoded multiple times during import.
- **Skeptic's response:** ACCEPT as Low.
- **Your analysis:** `_importNovelWorkspace` (lines 801–815) calls `actions.peekCharacterRepresentation(archive)`, which decodes the archive. Then `restoreNovel` decodes it again. This is inefficient and fragile on Windows. However, the user cannot swap files between the two reads in normal operation, so the functional impact is low. Accept as Low code-quality/robustness issue.
- **VERDICT: REAL BUG**
- **Confidence:** Medium
- **True severity:** Low
- **Suggested fix:** Decode the archive once and pass the decoded `Archive`/manifest object into the import service.

---

**BUG-11**
- **Hunter's claim:** Button enable logic flawed / duplicate database instances.
- **Skeptic's response:** DISPROVE.
- **Your analysis:** The button visibility and enable conditions are correct. No real issue.
- **VERDICT: NOT A BUG**

---

**BUG-12**
- **Hunter's claim:** No size limit / zip-bomb protection.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** `ZipDecoder().decodeBytes(await archive.readAsBytes(), verify: true)` reads the entire file into memory and decodes it without any size cap. A small malicious archive could expand to fill memory. This is a real DoS/security concern.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Reject archives over a configurable size before decoding, or stream/decode with bounds.

---

**BUG-13**
- **Hunter's claim:** Export provenance timestamp makes archive non-deterministic.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Line 107 uses `DateTime.now().toUtc().toIso8601String()`. This is a real reproducibility issue but very minor. Low severity.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Truncate to seconds or omit fractional seconds; optionally accept an explicit `exportedAt` parameter for tests.

---

**BUG-14**
- **Hunter's claim:** Path traversal check is flawed on Windows.
- **Skeptic's response:** DISPROVE.
- **Your analysis:** The check uses `p.relative(resolved, from: stagingRoot)` with the platform separator; on Windows it will correctly catch `..\` prefixes. No bug.
- **VERDICT: NOT A BUG**

---

**BUG-15**
- **Hunter's claim:** Duplicate of BUG-01 (crash between insert and append).
- **Skeptic's response:** DISPROVE as duplicate.
- **Your analysis:** Same root cause as BUG-01.
- **VERDICT: NOT A BUG** (duplicate of BUG-01)

---

**BUG-16**
- **Hunter's claim:** `NovelCharacterLink.fromJson` does not tolerate invalid timestamps.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** `novel_character_link.dart` lines 82–83 call `DateTime.parse` on `created_at` and `updated_at`. A malformed archive will throw `FormatException` and abort the entire import, even though other link fields are validated with `ArgumentError`. Real robustness bug.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Validate timestamps before parsing or wrap parse errors in a descriptive `FormatException`.

---

**BUG-17**
- **Hunter's claim:** `exportCharacter` exists but no `restoreCharacter`.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** `workspace_export_service.dart` has `exportCharacter` (lines 127–140), but `workspace_import_service.dart` only has `restoreNovel` and rejects non-novel `workspaceType`. Character workspace exports cannot be imported. Real incomplete-feature bug.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Add `restoreCharacter` to `WorkspaceImportService` or remove `exportCharacter` until import is implemented.

---

**BUG-18**
- **Hunter's claim:** `workspace_export_options_dialog.dart` uses `RadioGroup` without importing it.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** I searched the entire repository for a `RadioGroup` definition or export. No `class RadioGroup`, `typedef RadioGroup`, `extension RadioGroup`, or `part`/`export` of it exists. `workspace_export_options_dialog.dart` only imports `flutter/material.dart` and `workspace_export_service.dart`. The same `RadioGroup` widget is used in `theme_settings_screen.dart` and `character_deletion_review_dialog.dart`, also without an import. This would normally be a compile-time error, unless it is provided by `material.dart` or an auto-import. `RadioGroup` is not part of Flutter's Material library (Flutter uses `Radio`/`RadioListTile` directly). Therefore this is a real compile-time bug across multiple files.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Define or import a `RadioGroup` widget, or replace with explicit `RadioListTile` widgets using a common `groupValue`/`onChanged`.

---

**BUG-19**
- **Hunter's claim:** `workspace_import_options_dialog.dart` uses `RadioGroup` without importing it.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Same as BUG-18. No definition found; the file only imports Material and `workspace_import_service.dart`. Real compile-time bug.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Same as BUG-18.

---

**BUG-20**
- **Hunter's claim:** `expectedWorkspaceId` collision check happens before archive validation.
- **Skeptic's response:** ACCEPT.
- **Your analysis:** Lines 62–77 perform the collision pre-check before decoding the archive. If the archive is corrupt and the target exists, the caller gets a collision `StateError` instead of a corrupt-archive error. This contradicts the code's own comment. Real logic bug.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Validate the archive manifest before checking collisions, or reorder the early check to respect `skip` after validation.

---

**BUG-21**
- **Hunter's claim:** `peekManifest` returns any manifest without validation.
- **Skeptic's response:** DISPROVE.
- **Your analysis:** `peekManifest` is used only to read `characterRepresentation`. A non-novel or invalid manifest would simply return null or an unexpected map, and the UI would display "Not declared". No functional defect.
- **VERDICT: NOT A BUG**

---

**BUG-22**
- **Hunter's claim:** `exportNovel` defaults to `referenceManifest`.
- **Skeptic's response:** DISPROVE.
- **Your analysis:** The service default is a safe fallback. The presentation layer (options dialog + actions) forces an explicit choice, and tests verify this. Not a real bug.
- **VERDICT: NOT A BUG**

---

**BUG-23**
- **Hunter's claim:** Duplicate of BUG-07.
- **Skeptic's response:** DISPROVE as duplicate.
- **Your analysis:** Same root cause as BUG-07.
- **VERDICT: NOT A BUG** (duplicate of BUG-07)

---

**BUG-24**
- **Hunter's claim:** `isInsideWorkspace` does not resolve symlinks.
- **Skeptic's response:** DISPROVE.
- **Your analysis:** This is a runtime-only claim without evidence that the workspace contains symlinks. The string-level guard is correct for normal paths. Static analysis cannot prove this is a real bug.
- **VERDICT: NOT A BUG**

---

**BUG-25**
- **Hunter's claim:** Rollback ignores `unlink` return value.
- **Skeptic's response:** DISPROVE.
- **Your analysis:** The import already rethrows on any failure, so a failed rollback link is part of a catastrophic failure. No separate functional defect.
- **VERDICT: NOT A BUG**

---

## VERIFIED BUG REPORT

Stats:
- Total reported by Hunter: 25
- Dismissed as false positives / duplicates: 11 (BUG-06, 08, 11, 14, 15 duplicate, 21, 22, 23 duplicate, 24, 25, and BUG-10 accepted as Low instead of Medium)
- Confirmed as real bugs: 14
- Critical: 0 | Medium: 9 | Low: 5

Confirmed bugs (ordered by severity):

| # | Severity | File | Line(s) | Description | Suggested Fix |
|---|----------|------|---------|-------------|---------------|
| BUG-18 | Medium | `lib/features/workspaces/presentation/workspace_export_options_dialog.dart` | 71–88 | Uses undefined `RadioGroup` widget; compile-time error. | Define/import `RadioGroup` or replace with `RadioListTile` group. |
| BUG-19 | Medium | `lib/features/workspaces/presentation/workspace_import_options_dialog.dart` | 124–140 | Uses undefined `RadioGroup` widget; compile-time error. | Define/import `RadioGroup` or replace with `RadioListTile` group. |
| BUG-17 | Medium | `lib/features/workspaces/application/workspace_export_service.dart` | 127–140 | `exportCharacter` exists but `WorkspaceImportService` has no `restoreCharacter`. | Add `restoreCharacter` or remove `exportCharacter`. |
| BUG-07 | Medium | `lib/features/workspaces/application/workspace_import_service.dart` | 62–76 | `expectedWorkspaceId` collision check ignores `skip` choice. | Respect `collisionChoice` after archive validation. |
| BUG-20 | Medium | `lib/features/workspaces/application/workspace_import_service.dart` | 62–76 | Collision pre-check runs before archive validation, masking corrupt-archive errors. | Validate archive before collision checks. |
| BUG-01 | Medium | `lib/features/workspaces/application/workspace_import_service.dart` | 163–227 | Embedded-snapshot character insertion not transactional; partial rollback possible. | Wrap materialization in a database transaction. |
| BUG-03 | Medium | `lib/features/workspaces/application/workspace_import_service.dart` | 136, 143–228 | `adoptExistingLinks` still materializes embedded characters, violating its contract. | Skip character materialization when adopting or reject non-reference adopt. |
| BUG-04 | Medium | `lib/features/workspaces/application/workspace_export_service.dart` | 180–192 | `_copy` follows directory symlinks, risking external file inclusion. | Use `followLinks: false` and skip symlinks. |
| BUG-05 | Medium | `lib/features/workspaces/application/workspace_import_service.dart` | 176–178 | Missing embedded character payload silently creates blank character. | Throw if payload missing for non-reference archive. |
| BUG-12 | Medium | `lib/features/workspaces/application/workspace_import_service.dart` | 90–93 | No archive size / zip-bomb protection. | Add size cap before decoding. |
| BUG-02 | Medium | `lib/features/workspaces/application/workspace_import_service.dart` | 98–104 | Manifest `version` not validated. | Reject unsupported versions. |
| BUG-09 | Medium | `lib/features/story/presentation/story_workspace_screen.dart` | 774–798 | No success/error feedback after novel export. | Show snackbar with result or error. |
| BUG-10 | Low | `lib/features/story/presentation/story_workspace_screen.dart` | 801–815 | Archive decoded multiple times during import. | Decode once and pass manifest/decoded archive. |
| BUG-13 | Low | `lib/features/workspaces/application/workspace_export_service.dart` | 107 | Provenance timestamp includes fractional seconds; non-deterministic export. | Truncate to seconds or parameterize. |
| BUG-16 | Low | `lib/features/workspaces/domain/novel_character_link.dart` | 82–83 | `DateTime.parse` on malformed timestamp aborts whole import. | Validate/tolerate timestamp strings. |

Low-confidence items (flagged for manual review):
- None of the confirmed bugs had Medium or Low confidence; all are High except BUG-10 (Medium confidence).

---

Transparency — dismissed Hunter findings:
- BUG-06, BUG-08, BUG-11, BUG-14, BUG-15 (duplicate), BUG-21, BUG-22, BUG-23 (duplicate), BUG-24, BUG-25: disproved by reading actual code.
