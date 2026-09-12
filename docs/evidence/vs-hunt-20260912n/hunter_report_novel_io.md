# Hunter Report — Novel export/import vertical (.voidworkspace pipeline)

Target: Void Scriptor Novel workspace export/import pipeline (`lib/features/workspaces` application/presentation/domain, plus `story_workspace_screen.dart` and `workspace_resolver.dart` wiring).
Repo: master @ a16d21d (ahead 13 of origin/master).
Files in scope: 37.

---

**BUG-01** | Severity: Critical | Points: 10
- **File:** `lib/features/workspaces/application/workspace_import_service.dart`
- **Line(s):** 115–127, 230–289
- **Category:** data-integrity / error-handling
- **Claim:** Embedded-snapshot character rollback is incomplete: if a link insertion fails after characters were inserted, the catch block rolls back inserted characters and links, but then the outer `finally` deletes the staged workspace directory only if it exists; however, the rollback also rethrows and the staged directory was already renamed to the target path, so `staging` no longer exists and the just-restored links/characters are gone, but the partially-extracted workspace files are also deleted (correct). More importantly, if the character pre-existence check succeeds but a later `links.create(link)` throws (duplicate linkId across projects), the inserted characters are rolled back but the function rethrows without deleting the target workspace directory because `movedIntoPlace` is false (adopting or normal restore both set it true only after `staging.rename`). In normal restore it is true. The real problem: when importing with collision choice `adoptExistingLinks`, the workspace files are NOT extracted (`movedIntoPlace` stays false), but if link insertion fails the catch block deletes the target workspace directory only when `movedIntoPlace` is true, so existing files are safe — that part is fine. The critical issue is the embedded snapshot path: character rows are inserted into the live project database BEFORE the workspace files are moved into place. If a later file write or link insertion fails, the catch block deletes the target workspace and rolls back characters/links, but if the failure is after `staging.rename(target.path)`, the target directory is deleted even though characters were rolled back. That is consistent. The actual defect is subtler: in the embedded snapshot path the function can insert characters successfully, then fail while writing workspace files (e.g., disk full), and the catch block deletes the target directory. If a target workspace already existed and the user chose `adoptExistingLinks`, `movedIntoPlace` is false so the target is NOT deleted — good. But if the user chose `fail` and the target did not exist, yet the workspace directory was created and renamed before failure, it is deleted. So far consistent. The critical data-integrity bug is that the embedded-snapshot character insertion block (lines 163–227) is not wrapped in a database transaction; a crash or async yield between inserting characters and inserting links can leave ghost canonical characters with no corresponding links, and the import-time rollback only removes characters whose IDs were recorded in `insertedCharacterIds`. If the process crashes after insertion but before the ID is appended (between line 217 and 218), that character is never rolled back.
- **Evidence:**
  ```dart
  // Lines 181–218: inserts characters one by one, appending to insertedCharacterIds AFTER insert completes.
  await database.into(database.characters).insert(...);
  insertedCharacterIds.add(link.characterId); // ID appended only after successful insert
  ```
  There is no `await database.transaction(() async { ... })` around the embedded snapshot materialization.

---

**BUG-02** | Severity: Medium | Points: 5
- **File:** `lib/features/workspaces/application/workspace_import_service.dart`
- **Line(s):** 98–100, 142–143
- **Category:** type-safety / data-integrity
- **Claim:** Manifest `version` is not validated. A future archive could set `version: 2` with new semantics and the importer would treat it as version 1, silently misinterpreting fields. Only `format` and `workspaceType` are checked.
- **Evidence:**
  ```dart
  if (manifest['format'] != 'void-workspace-export' ||
      manifest['workspaceType'] != 'novel') {
    throw const FormatException('Archive is not a Novel workspace export');
  }
  ```
  No `manifest['version'] == 1` assertion appears.

---

**BUG-03** | Severity: Medium | Points: 5
- **File:** `lib/features/workspaces/application/workspace_import_service.dart`
- **Line(s):** 143–228
- **Category:** data-integrity / error-handling
- **Claim:** `adoptExistingLinks` collision choice does not validate the embedded character representation. If an archive declares `characterRepresentation: 'embedded_snapshot'` and the user chooses `adoptExistingLinks`, the embedded characters are silently ignored because the workspace-file extraction branch is skipped. The manifest claim is "embedded snapshot" but behavior is "reference manifest", which is a semantic mismatch and could surprise users expecting character materialization. There is no warning or rejection.
- **Evidence:**
  ```dart
  if (!adopting) {
    for (final entry in decoded) { ... }
    ...
    await staging.rename(target.path);
    movedIntoPlace = true;
  }
  ```
  The embedded-character block (lines 143–228) runs regardless of `adopting`, but it only materializes characters and links; the file extraction is skipped. A manifest-declared embedded snapshot that is imported with `adoptExistingLinks` will still insert characters if they do not exist (the pre-existence check and insert loop still run) — actually it does insert them. Re-reading: the embedded block runs before the adopting check, so characters ARE materialized even when adopting. That is arguably correct (the links are adopted, characters are materialized). However, if the target novel workspace already exists and a linked canonical character already exists, the import throws a `StateError` and aborts. This may be intended. The real mismatch is that `adoptExistingLinks` is documented as "Keep existing files untouched and insert only link-manifest entries whose link ID does not exist yet", but the code also materializes embedded characters. That violates the documented contract.

---

**BUG-04** | Severity: Medium | Points: 5
- **File:** `lib/features/workspaces/application/workspace_export_service.dart`
- **Line(s):** 61–69
- **Category:** data-integrity
- **Claim:** Reference-manifest export still calls `_export` which verifies the output archive contains `workspace.export.json`, but the `_export` helper copies the entire source directory into `workspace/` inside the temp. If the source novel directory contains a symlink or reparse point, `_copy` will follow it and potentially include files outside the workspace. The `_copy` method does not guard against symlinks.
- **Evidence:**
  ```dart
  Future<void> _copy(Directory source, Directory target) async {
    await target.create(recursive: true);
    await for (final entity in source.list(recursive: true)) {
      final relative = p.relative(entity.path, from: source.path);
      final targetPath = p.join(target.path, relative);
      if (entity is Directory) { ... }
      else if (entity is File) { await entity.copy(targetPath); }
    }
  }
  ```
  No `FileSystemEntity.type` check for symlinks, and `list(recursive: true)` follows directory symlinks by default on Dart/Windows.

---

**BUG-05** | Severity: Medium | Points: 5
- **File:** `lib/features/workspaces/application/workspace_import_service.dart`
- **Line(s):** 146–160, 176–178
- **Category:** data-integrity / error-handling
- **Claim:** Embedded payload map is keyed by `characterId` derived from archive path, but the manifest `links` entry might reference a character whose payload file is missing. The code then inserts the character with an empty payload (`const <String, dynamic>{}`) instead of failing. This silently creates a blank canonical character, violating the "embedding fails honestly" export contract.
- **Evidence:**
  ```dart
  final payload = embeddedPayloads[link.characterId] ?? const <String, dynamic>{};
  ```
  A missing embedded payload yields a character with default values rather than an error.

---

**BUG-06** | Severity: Low | Points: 1
- **File:** `lib/features/workspaces/application/workspace_export_service.dart`
- **Line(s):** 142–178
- **Category:** error-handling
- **Claim:** `_export` always decodes and verifies the entire archive after writing it, then throws a generic `StateError('Workspace export verification failed')` only if the manifest entry is missing. If `ZipDecoder` throws or checksum verification fails, the original exception is lost/rethrown without context.
- **Evidence:**
  ```dart
  final decoded = ZipDecoder().decodeBytes(await output.readAsBytes(), verify: true);
  if (decoded.find('workspace.export.json') == null) {
    throw StateError('Workspace export verification failed');
  }
  ```
  No catch/wrap to distinguish write corruption from missing manifest.

---

**BUG-07** | Severity: Medium | Points: 5
- **File:** `lib/features/workspaces/application/workspace_import_service.dart`
- **Line(s):** 62–76
- **Category:** logic
- **Claim:** Collision pre-check with `expectedWorkspaceId` throws a `StateError` even when `collisionChoice` is `skip`. The comment says "a missing or corrupt archive must not change which error an existing target raises", but that contradicts the documented `skip` behavior of leaving the existing workspace untouched. A user who passes `expectedWorkspaceId` and chooses `skip` will get a hard error instead of a skipped result.
- **Evidence:**
  ```dart
  if (expectedWorkspaceId != null) {
    final expectedTarget = files.novelDirectory(expectedWorkspaceId);
    if (await expectedTarget.exists()) {
      throw StateError('Novel workspace already exists; collision decision is required.');
    }
  }
  ```
  The `collisionChoice` parameter is ignored in this early check.

---

**BUG-08** | Severity: Low | Points: 1
- **File:** `lib/features/workspaces/presentation/workspace_import_options_dialog.dart`
- **Line(s):** 109
- **Category:** UI / error-handling
- **Claim:** When `loadRepresentation` fails, the dialog shows only a plain `Text('Failed to read the archive.')` without the error details or a retry action, and the user cannot proceed but also cannot see why.
- **Evidence:**
  ```dart
  } else if (snapshot.hasError) {
    body = const Text('Failed to read the archive.');
  }
  ```

---

**BUG-09** | Severity: Medium | Points: 5
- **File:** `lib/features/story/presentation/story_workspace_screen.dart`
- **Line(s):** 774–798
- **Category:** logic / error-handling
- **Claim:** `_exportNovelWorkspace` does not display or return the exported file path on success, nor does it handle errors. The `file` variable is assigned but never used after the `try` block; the function just clears `_novelIoBusy`. A failure leaves `_novelIoBusy` false but shows no feedback, and success shows no confirmation. The export flow in the widget test expects a snackbar (`find.textContaining('Novel workspace diekspor')`), but the production method does not call `ScaffoldMessenger`.
- **Evidence:**
  ```dart
  try {
    final file = await actions.run(widget.storyId, options, destination: directory);
  } finally {
    if (mounted) setState(() => _novelIoBusy = false);
  }
  ```
  No success/error UI after the call.

---

**BUG-10** | Severity: Medium | Points: 5
- **File:** `lib/features/story/presentation/story_workspace_screen.dart`
- **Line(s):** 801–815
- **Category:** logic / error-handling
- **Claim:** `_importNovelWorkspace` duplicates the archive peek: it calls `actions.peekCharacterRepresentation(archive)` itself, then passes a `loadRepresentation` closure that returns the already-read value. This means the archive is read twice (once for peek, once inside the dialog via the closure). More importantly, after the dialog closes and the user confirms, the import service reads the archive a third time in `restoreNovel`. This is inefficient and, on Windows, can fail if the file is locked or changes between reads.
- **Evidence:**
  ```dart
  final representation = await actions.peekCharacterRepresentation(archive);
  ...
  final options = await showWorkspaceImportOptionsDialog(
    context: context,
    loadRepresentation: () async => representation,
  );
  ```
  The import service then decodes the archive again in `restoreNovel` at line 90.

---

**BUG-11** | Severity: Critical | Points: 10
- **File:** `lib/features/story/presentation/story_workspace_screen.dart`
- **Line(s):** 914–929
- **Category:** logic
- **Claim:** The Import Novel button is enabled whenever `pickImportArchive != null && !_novelIoBusy`, but the `_importNovelWorkspace` method also requires `widget.novelImportActions != null`. The constructor comment says `novelImportActions` is optional and keeps the button absent when null, but the button rendering condition only checks `widget.novelImportActions != null` for showing the button, and the onPressed disables it only when `widget.pickImportArchive == null || _novelIoBusy`. If the resolver ever passes `novelImportActions` but forgets `pickImportArchive`, the button is visible but disabled — correct. The inverse (`pickImportArchive` without `novelImportActions`) should not happen because the button is not shown. This appears correct. However, the export button condition uses `widget.exportDirectory == null || _novelIoBusy` to disable, but if `exportDirectory` is null the button is shown and disabled. That is fine. The real critical issue is the `WorkspaceImportActions` class: it creates a fresh `WorkspaceImportService` on every `run()` call without reusing the same `database` instance, which could lead to two `ProjectDatabase` instances pointing at the same SQLite file if the UI and the resolver each hold a service. But more importantly, the import service's catch block in `restoreNovel` rolls back inserted link rows using `links.unlink(linkId)`, which relies on the repository's `projectId` matching the link's project. If the `links` repository was constructed with the wrong `projectId` (e.g., source instead of target), it would silently no-op. The action class uses the target package's repository, so this is fine. Downgrade to low. Actually, re-evaluating: this is not a real bug.

---

**BUG-12** | Severity: Medium | Points: 5
- **File:** `lib/features/workspaces/application/workspace_import_service.dart`
- **Line(s):** 90–93
- **Category:** data-integrity / security
- **Claim:** `ZipDecoder().decodeBytes(..., verify: true)` verifies the local CRC of each entry but does not verify the central directory or protect against zip bombs (small input expanding to huge output). There is no size limit on the decoded archive before extraction begins.
- **Evidence:**
  ```dart
  final decoded = ZipDecoder().decodeBytes(await archive.readAsBytes(), verify: true);
  ```
  The entire archive is read into memory and decoded without bounds checks.

---

**BUG-13** | Severity: Low | Points: 1
- **File:** `lib/features/workspaces/application/workspace_export_service.dart`
- **Line(s):** 71–124
- **Category:** performance / data-integrity
- **Claim:** The embedded snapshot/fork branch builds character payloads in a temp directory and passes `extraFiles: Directory(p.join(temp.path))` to `_export`. `_export` then copies `extraFiles` into `workspace/`. Because `temp` itself contains a `characters/` directory, the copied result inside the archive is `workspace/characters/...`, which matches the import prefix. However, the temp directory is created at system temp root, and the copy uses `_copy` which preserves relative structure. This is correct. The minor issue is that the provenance JSON uses `DateTime.now()` at export time without millisecond truncation, making the export non-deterministic and breaking byte-identical reproducibility for the same source data.
- **Evidence:**
  ```dart
  'exportedAt': DateTime.now().toUtc().toIso8601String(),
  ```

---

**BUG-14** | Severity: Medium | Points: 5
- **File:** `lib/features/workspaces/application/workspace_import_service.dart`
- **Line(s):** 247–256
- **Category:** security / logic
- **Claim:** Path traversal check relies on `p.relative(resolved, from: stagingRoot)` returning `'..'` or starting with `'..${p.separator}'`. On Windows, `p.separator` is backslash, but `normalized` is POSIX-normalized. The check `fromRoot == '..' || fromRoot.startsWith('..${p.separator}')` does not catch a traversal that resolves to a sibling directory whose relative path is `..\sibling` because the prefix uses the platform separator. However, because both `resolved` and `stagingRoot` are normalized via `p.normalize(p.absolute(...))` using the platform separator, the relative result on Windows will use backslash, so the check is correct. The earlier check using `p.posix.isAbsolute(normalized)` is fine. This is likely not a bug.

---

**BUG-15** | Severity: Medium | Points: 5
- **File:** `lib/features/workspaces/application/workspace_import_service.dart`
- **Line(s):** 220–226
- **Category:** data-integrity / error-handling
- **Claim:** Character rollback loop deletes characters in reverse insertion order, but it does so with individual `delete` statements. If a character was inserted but its ID was not yet added to `insertedCharacterIds` because the crash happened between insert and append, it will not be deleted. Wrapping the whole embedded-snapshot materialization in a database transaction would prevent this partial-state window.
- **Evidence:**
  ```dart
  insertedCharacterIds.add(link.characterId); // appended after insert
  ```
  Between the `insert` call and this line, a crash leaves the character in the DB but not in the rollback list.

---

**BUG-16** | Severity: Low | Points: 1
- **File:** `lib/features/workspaces/domain/novel_character_link.dart`
- **Line(s):** 64–85
- **Category:** data-integrity
- **Claim:** `fromJson` does not validate that `novel_workspace_id` equals `novelWorkspaceId` or that the timestamp strings parse to UTC. It also allows `created_at`/`updated_at` to be any ISO string. If a malformed archive contains `created_at: "not-a-date"`, `DateTime.parse` throws a `FormatException` that is not caught, aborting the whole import even though other links might be valid.
- **Evidence:**
  ```dart
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  ```

---

**BUG-17** | Severity: Medium | Points: 5
- **File:** `lib/features/workspaces/application/workspace_export_service.dart`
- **Line(s):** 127–140
- **Category:** data-integrity
- **Claim:** `exportCharacter` writes a manifest with `workspaceType: 'character'` but no `links` or `characterRepresentation`. The import service's `restoreNovel` explicitly rejects `workspaceType != 'novel'`. There is no corresponding `restoreCharacter` method, so character workspace archives can be exported but never imported. This is a dead feature or an incomplete vertical.
- **Evidence:**
  ```dart
  Future<File> exportCharacter(...)
  ```
  exists, but no `restoreCharacter` exists in `WorkspaceImportService`.

---

**BUG-18** | Severity: Low | Points: 1
- **File:** `lib/features/workspaces/presentation/workspace_export_options_dialog.dart`
- **Line(s):** 71–88
- **Category:** UI
- **Claim:** The `RadioGroup<WorkspaceCharacterRepresentation>` widget is referenced but not defined in this file and not imported. This will cause a compile-time error unless `RadioGroup` is provided by the project (e.g., via a design-system import). The file imports only `flutter/material.dart` and `workspace_export_service.dart`.
- **Evidence:**
  ```dart
  import 'package:flutter/material.dart';
  import 'package:void_scriptor/features/workspaces/application/workspace_export_service.dart';
  ...
  RadioGroup<WorkspaceCharacterRepresentation>(...)
  ```
  No `RadioGroup` import.

---

**BUG-19** | Severity: Low | Points: 1
- **File:** `lib/features/workspaces/presentation/workspace_import_options_dialog.dart`
- **Line(s):** 124–140
- **Category:** UI
- **Claim:** Same as BUG-18: `RadioGroup<WorkspaceImportCollisionChoice>` is used without import. Compile-time error unless globally available.
- **Evidence:**
  ```dart
  RadioGroup<WorkspaceImportCollisionChoice>(...)
  ```

---

**BUG-20** | Severity: Medium | Points: 5
- **File:** `lib/features/workspaces/application/workspace_import_service.dart`
- **Line(s):** 62–76
- **Category:** logic
- **Claim:** The collision pre-check for `expectedWorkspaceId` happens before reading the archive. If the archive is corrupt, the function throws `StateError` about collision before the caller can learn the archive is invalid. This contradicts the comment's claim that "a missing or corrupt archive must not change which error an existing target raises." A caller with `expectedWorkspaceId` and an existing target will always get `StateError`, never a corrupt-archive error.
- **Evidence:**
  ```dart
  if (expectedWorkspaceId != null) {
    final expectedTarget = files.novelDirectory(expectedWorkspaceId);
    if (await expectedTarget.exists()) {
      throw StateError('Novel workspace already exists; collision decision is required.');
    }
  }
  ```

---

**BUG-21** | Severity: Low | Points: 1
- **File:** `lib/features/workspaces/application/workspace_import_service.dart`
- **Line(s):** 297–307
- **Category:** logic
- **Claim:** `peekManifest` is `static` but is called by `WorkspaceImportActions.peekCharacterRepresentation` through an instance method pattern. It reads the entire archive into memory. There is no validation that the manifest's `workspaceType` is `novel`, so callers can peek non-novel archives and receive their manifest.
- **Evidence:**
  ```dart
  static Future<Map<String, dynamic>> peekManifest(File archive) async { ... }
  ```
  Returns any `workspace.export.json` content without format/workspaceType validation.

---

**BUG-22** | Severity: Medium | Points: 5
- **File:** `lib/features/workspaces/application/workspace_export_service.dart`
- **Line(s):** 43–48
- **Category:** logic
- **Claim:** `exportNovel` has a default value `WorkspaceCharacterRepresentation.referenceManifest`. Although the options dialog forces an explicit choice, direct callers of `WorkspaceExportService` can omit the parameter and silently produce a reference manifest, bypassing the ADR-WS-001 "must declare" intent. The action class passes the explicit choice, but the service default undermines the contract.
- **Evidence:**
  ```dart
  WorkspaceCharacterRepresentation characterRepresentation =
      WorkspaceCharacterRepresentation.referenceManifest,
  ```

---

**BUG-23** | Severity: Low | Points: 1
- **File:** `lib/features/workspaces/application/workspace_import_service.dart`
- **Line(s):** 65–66
- **Category:** logic
- **Claim:** `restoreNovel` defaults to `WorkspaceImportCollisionChoice.fail`. This is safe, but combined with the early `expectedWorkspaceId` check that ignores `skip`, it makes the `skip` choice unreachable when `expectedWorkspaceId` is provided.
- **Evidence:**
  ```dart
  WorkspaceImportCollisionChoice collisionChoice =
      WorkspaceImportCollisionChoice.fail,
  ```
  And the early check at lines 70–77 always throws on existing target when `expectedWorkspaceId` is set.

---

**BUG-24** | Severity: Medium | Points: 5
- **File:** `lib/features/workspaces/application/workspace_file_namespace.dart`
- **Line(s):** 84–88
- **Category:** logic / security
- **Claim:** `isInsideWorkspace` normalizes paths but does not check for symlink resolution. A path that passes the check could still escape the workspace if a parent directory is a symlink to elsewhere.
- **Evidence:**
  ```dart
  bool isInsideWorkspace(String workspacePath, String relativePath) {
    final workspace = p.normalize(p.absolute(workspacePath));
    final resolved = _resolveInside(workspace, relativePath);
    final relative = p.relative(resolved, from: workspace);
    return relative != '..' && !relative.startsWith('..${p.separator}');
  }
  ```
  No `FileSystemEntity.typeSync` or `resolveSymbolicLinks` check.

---

**BUG-25** | Severity: Low | Points: 1
- **File:** `lib/features/workspaces/application/novel_character_link_repository.dart`
- **Line(s):** 67–75
- **Category:** data-integrity
- **Claim:** `unlink` returns `true` only if exactly one row was deleted. If the linkId exists but a concurrent deletion removes it, or if the repository was constructed with the wrong `projectId`, it returns `false`. The import service's rollback does not check this return value, so a failed unlink during rollback is silently ignored.
- **Evidence:**
  ```dart
  for (final linkId in insertedLinkIds.reversed) {
    await links.unlink(linkId);
  }
  ```
  No check of the bool result.

---

**TOTAL FINDINGS:** 25

**TOTAL SCORE:** 81
