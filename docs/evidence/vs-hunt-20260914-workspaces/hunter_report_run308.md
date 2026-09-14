# Hunter Report — Void Scriptor Workspaces

---
**BUG-1** | Severity: Critical | Points: 10
- **File:** `lib/features/workspaces/application/workspace_migration_runner.dart`
- **Line(s):** 122-158
- **Category:** data-integrity
- **Claim:** Migration mutates the filesystem and inserts links without an enclosing rollback boundary, so a later link failure leaves copied workspace files behind while the migration aborts.
- **Evidence:**
  ```dart
  // Phase 4: copy into typed namespaces without deleting legacy sources.
  var copiedStoryFiles = 0;
  ...
  copiedCharacterFiles += await _copyInto(
    source,
    _files.characterDirectory(assignment.characterId),
  );

  // Phase 5: explicit links only, deterministic IDs, reference mode.
  var createdLinks = 0;
  for (final assignment in characterAssignments) {
    await links.create(
      NovelCharacterLink.create(
        linkId:
            'migration-${assignment.novelWorkspaceId}-${assignment.characterId}',
  ```
  There is no transaction/compensation around the copy phases and link phase; `_runRollbackDrill()` is only executed after all mutation phases complete.
---

**BUG-2** | Severity: Critical | Points: 10
- **File:** `lib/features/workspaces/application/workspace_migration_runner.dart`
- **Line(s):** 206-215
- **Category:** security
- **Claim:** Migration recursively copies through filesystem links without disabling link following, allowing a symlinked legacy entry to import bytes from outside the legacy workspace into the project workspace.
- **Evidence:**
  ```dart
  await for (final entity in source.list(recursive: true)) {
    if (entity is! File) continue;
    final relative = p.relative(entity.path, from: source.path);
    final destination = File(p.join(target.path, 'legacy', relative));
    await destination.parent.create(recursive: true);
    await entity.copy(destination.path);
    count++;
  }
  ```
  The traversal does not pass `followLinks: false` and does not reject `Link` entities before copying.
---

**BUG-3** | Severity: Critical | Points: 10
- **File:** `lib/features/workspaces/application/workspace_migration_runner.dart`
- **Line(s):** 73-93, 143-158
- **Category:** data-integrity
- **Claim:** Validation incorrectly rejects a character assigned to more than one novel, despite assignments being novel-scoped, and the migration cannot migrate legitimate cross-novel character reuse.
- **Evidence:**
  ```dart
  final seenCharacters = <String>{};
  for (final assignment in characterAssignments) {
    ...
    if (!seenCharacters.add(assignment.characterId)) {
      throw ArgumentError.value(
        assignment.characterId,
        'characterId',
        'duplicated assignment',
      );
    }
  }
  ```
  The same character ID is intentionally used with independent novel assignments elsewhere in the scoped domain/repository model; this check treats the character as globally single-assignment.
---

**BUG-4** | Severity: Critical | Points: 10
- **File:** `lib/features/workspaces/application/workspace_migration_runner.dart`
- **Line(s):** 64-71, 123-130, 175-177
- **Category:** data-integrity
- **Claim:** Migration does not reject two legacy story IDs mapping to the same target Novel ID, so it merges their files and eventually generates colliding deterministic link IDs.
- **Evidence:**
  ```dart
  for (final entry in storyWorkspaceIds.entries) {
    if (!WorkspaceFileNamespace.isValidWorkspaceIdentifier(entry.key)) {
      throw ArgumentError.value(entry.key, 'storyWorkspaceIds key');
    }
    if (!WorkspaceFileNamespace.isValidWorkspaceIdentifier(entry.value)) {
      throw ArgumentError.value(entry.value, 'storyWorkspaceIds value');
    }
  }
  ```
  ```dart
  for (final entry in storyWorkspaceIds.entries) {
    final source = Directory(p.join(storiesRoot.path, entry.key));
    final target = _files.novelDirectory(entry.value);
    await target.create(recursive: true);
    copiedStoryFiles += await _copyInto(source, target);
  }
  ```
  ```dart
  linkId:
      'migration-${assignment.novelWorkspaceId}-${assignment.characterId}',
  ```
  Values are validated individually but their uniqueness is never checked; duplicate target values therefore share a directory and link-ID namespace.
---

**BUG-5** | Severity: Medium | Points: 5
- **File:** `lib/features/workspaces/application/workspace_migration_runner.dart`
- **Line(s):** 160-192
- **Category:** error-handling
- **Claim:** A failed checksum/count validation is returned as a migration report that otherwise claims success instead of throwing or rolling back.
- **Evidence:**
  ```dart
  var validatedCounts = true;
  ...
  validatedCounts &= await _verifyCopy(
    Directory(p.join(storiesRoot.path, entry.key)),
    _files.novelDirectory(entry.value),
  );
  ...
  return WorkspaceMigrationReport(
    ...
    validatedCounts: validatedCounts,
    projectionRebuilt: true,
    rollbackDrillPassed: rollbackDrillPassed,
  );
  ```
  The false validation result is only stored in the returned report; execution proceeds through projection invalidation and returns normally.
---

**BUG-6** | Severity: Medium | Points: 5
- **File:** `lib/features/workspaces/application/workspace_migration_runner.dart`
- **Line(s):** 96-101, 180-192, 277-303
- **Category:** error-handling
- **Claim:** The migration's rollback drill can validate a different, lexicographically latest backup rather than the backup created for this migration, producing a false rollback signal.
- **Evidence:**
  ```dart
  await backups.create(
    package: package,
    type: 'pre-workspace-migration',
    note: 'Automatic backup before ADR-WS-001 mixed-storage migration',
  );
  ```
  ```dart
  backupRoots.sort((left, right) => left.path.compareTo(right.path));
  final backup = backupRoots.last;
  ```
  The backup creation result/identity is not retained; the drill later selects whichever backup directory sorts last.
---

**BUG-7** | Severity: Medium | Points: 5
- **File:** `lib/features/workspaces/application/workspace_import_service.dart`
- **Line(s):** 355-360
- **Category:** validation
- **Claim:** Import accepts any non-reference character representation as embedded data, so an unknown manifest token is silently interpreted with snapshot/fork semantics instead of being rejected.
- **Evidence:**
  ```dart
  final representation = manifest['characterRepresentation'] as String?;
  final embedded =
      representation != null && representation != 'reference_manifest';
  ```
  No check restricts the token to `reference_manifest`, `embedded_snapshot`, or `fork`; any arbitrary non-reference value enters the embedded materialization path.
---

**TOTAL FINDINGS:** 7
**TOTAL SCORE:** 55
