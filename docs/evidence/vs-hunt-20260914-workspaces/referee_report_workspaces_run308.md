# Referee Report — Void Scriptor Workspaces

- hunt: `vs-hunt-20260914-workspaces`
- head_at_verdict: `141e86e`
- verdict authority: independent static inspection by referee
- scope: workspace migration and import behavior; read-only review (no target code executed)

## Files read

Primary scope:

- `lib/features/workspaces/application/workspace_migration_runner.dart`
- `lib/features/workspaces/application/workspace_import_service.dart`

Collaborators and evidence:

- `lib/features/workspaces/application/novel_character_link_repository.dart`
- `lib/features/workspaces/application/workspace_export_service.dart`
- `lib/features/workspaces/application/workspace_file_namespace.dart`
- `lib/features/project_resilience/application/project_recovery_services.dart`
- `test/features/workspaces/workspace_migration_runner_test.dart`
- `test/features/workspaces/workspace_migration_empty_scaffold_test.dart`
- `test/features/workspaces/workspace_import_version_test.dart`
- `test/features/workspaces/workspace_import_single_decode_test.dart`
- `test/features/workspaces/workspace_import_service_test.dart`
- `test/features/workspaces/workspace_import_atomicity_test.dart`
- `test/features/workspaces/workspace_import_adopt_embedded_test.dart`
- `test/features/workspaces/workspace_import_embedded_test.dart`
- `test/features/workspaces/workspace_export_representation_test.dart`
- `AGENTS.md`

The supplied reports were also read:

- `docs/evidence/vs-hunt-20260914-workspaces/hunter_report_run308.md`
- `docs/evidence/vs-hunt-20260914-workspaces/skeptic_report_run308.md`

## Verdicts

### BUG-1 — REAL BUG

**True severity: High — data integrity / recovery.** Hunter called this Critical; Skeptic corrected it to High. I agree with High: migration mutates both filesystem and database state after the backup, but no transaction or compensation spans the copy phases and link-insert loop. If a later copy, checksum operation, or `links.create()` throws, earlier copied directories/files and earlier inserted links remain. The pre-migration backup is created but is not automatically restored on failure. `_runRollbackDrill()` is a post-mutation diagnostic and cannot repair the live package.

**Minimal fix direction:** Make the migration all-or-fail: retain the backup directory returned by `backups.create`, perform database link writes in one database transaction, stage filesystem output and atomically install it, and on any failure restore/delete staged or installed filesystem state and restore the database (or use a transaction covering the DB portion plus explicit filesystem compensation).

**Existing tests:** `workspace_migration_runner_test.dart` pins only the successful path and unsafe pre-mutation validation. No test pins behavior when a copy or link insert fails, so no existing test contradicts this finding.

### BUG-2 — REAL BUG

**True severity: High — security/data boundary.** Hunter called this Critical; Skeptic corrected it to High. I agree with High. `_copyInto` calls `source.list(recursive: true)` with the default link-following behavior, then copies every entity that is a `File`. A nested symlink/file link can resolve outside the legacy workspace and `entity.copy()` imports those external bytes into the project package. Top-level directory inventory does not protect nested entries. The identifier validator is irrelevant to filesystem link targets.

**Minimal fix direction:** Traverse with `followLinks: false`, explicitly reject `Link` entities (including links encountered in both copy and verification), and preferably verify canonical source and destination paths remain inside the intended legacy/typed roots before copying.

**Existing tests:** The migration tests cover normal files and unsafe identifiers only. No symlink/link-following test or guard was found; no test contradicts the finding. Static review does not establish exploitability by a remote attacker, but a locally supplied legacy package is a reachable input for this desktop app.

### BUG-3 — REAL BUG

**True severity: High — compatibility/data integrity.** Hunter called this Critical; Skeptic corrected it to High. I agree with High. Validation stores only `characterId` in `seenCharacters`, although the accepted assignment is a pair of `characterId` and `novelWorkspaceId`, and the created link is novel-scoped. Reusing one character across two different mapped novels is therefore rejected before mutation. The check is not guarded by a caller that narrows assignments to one novel.

**Minimal fix direction:** Key duplicate detection by the pair `(novelWorkspaceId, characterId)` (or a canonical composite key), while separately validating any domain-level uniqueness requirements that actually exist.

**Existing tests:** The cited cross-novel domain tests document that the same character may have independent assignments in two novels. The migration test has only one assignment and therefore does not pin the allowed cross-novel case. No existing test contradicts the finding.

### BUG-4 — REAL BUG

**True severity: High — data integrity.** Hunter called this Critical; Skeptic corrected it to High. I agree with High. A `Map<String, String>` prevents duplicate source keys but permits multiple legacy story IDs to map to one target Novel ID. The copy loop writes both sources into the same target directory under `legacy`, merging independent workspaces. The later projection invalidation deduplicates target values, so it does not undo the merge. Link IDs also collide when assignments produce the same target novel and character combination; the repository inserts directly without migration preflight or conflict handling. Sources are retained, so the immediate impact is ambiguous merged output and possible partial failure rather than guaranteed irreversible source loss.

**Minimal fix direction:** Reject duplicate target values during Phase 1, before backup/mutation, unless an explicit merge policy is designed and implemented. Also preflight deterministic link-ID uniqueness and existing DB conflicts.

**Existing tests:** `workspace_migration_empty_scaffold_test.dart` covers a single source-to-different-target mapping only. The normal migration test covers one mapping. No duplicate-target or link-collision test was found; no test contradicts the finding.

### BUG-5 — REAL BUG

**True severity: Medium — unsafe success-path contract.** The Hunter and Skeptic both called this Medium; I retain Medium. `_verifyCopy` failures only set `validatedCounts` false. The runner then invalidates projections, executes the rollback drill, and returns normally with success-like fields including `projectionRebuilt: true` and `backupCreated: true`. The failed check is observable if a caller inspects the report, so this is not a completely silent success, but the runner does not enforce its own integrity gate and the searched callers do not handle `validatedCounts == false`.

**Minimal fix direction:** Treat a failed verification as failure: throw a dedicated migration validation exception and compensate/restore before returning, or return an explicitly unsuccessful result type that callers are required to handle and do not mark migration complete.

**Existing tests:** The migration tests assert `validatedCounts == true` only on successful fixtures. No test creates a checksum/count mismatch or asserts that a mismatch aborts and leaves no partial state. No existing test contradicts the finding.

### BUG-6 — REAL BUG

**True severity: Medium — rollback validation reliability.** Hunter and Skeptic both called this Medium; I retain Medium. The result of `backups.create` is discarded. `_runRollbackDrill` enumerates all direct backup directories, sorts their paths lexicographically, and chooses the last one. Backup IDs are UUID v4 values, so path ordering is neither creation order nor identity. If another backup exists and differs, the drill can restore the wrong snapshot and report a result unrelated to this migration's pre-state.

**Minimal fix direction:** Capture the exact `Directory`/backup ID returned by `backups.create` and pass it to `_runRollbackDrill`; do not rediscover a backup by lexicographic path ordering. Add an existence/manifest identity check.

**Existing tests:** Current migration tests assert the drill passes with one newly created backup, which cannot expose wrong-selection behavior. No multiple-backup/different-snapshot test was found; no test contradicts the finding.

### BUG-7 — REAL BUG

**True severity: Low for exporter-generated archives; Medium for untrusted/hand-edited archives.** Hunter called this Medium; Skeptic retained Medium but qualified it as Low for trusted UI-generated archives. I make that qualification explicit and rate the ordinary product path Low, with Medium risk at the import boundary. `workspace_export_service.dart` defines exactly `reference_manifest`, `embedded_snapshot`, and `fork`. Import instead defines `embedded` as any non-null representation other than `reference_manifest`; an arbitrary token such as `bogus` therefore enters embedded payload materialization. The later payload and conflict checks validate content but never reject the unknown representation token, violating the export contract and potentially assigning unintended snapshot/fork semantics.

**Minimal fix direction:** Validate `characterRepresentation` against the three allowed manifest values before any mutation; reject missing/unknown values according to the versioned format contract (or explicitly define missing as reference mode if backward compatibility requires it). Branch behavior from the validated enum/token, not a negated comparison.

**Existing tests:** Export representation tests pin the three supported exporter values; import tests use supported values and do not include an unknown-token archive. No unknown-token rejection test or guard was found, and no existing test contradicts the finding.

## Severity disagreement summary

- BUG-1 through BUG-4: Hunter rated Critical; Skeptic and referee independently downgrade to High because the mechanisms are real but the cited paths do not by themselves establish universal irreversibility or the migration being the sole route to the affected data.
- BUG-5 and BUG-6: all reports rate Medium; referee agrees.
- BUG-7: Hunter rates Medium; Skeptic qualifies Medium for untrusted archives and Low for exporter-generated archives. Referee uses Low for trusted generated archives and Medium at the untrusted import boundary.

## Evidence contract

- target: workspaces region (`workspace_migration_runner.dart`, `workspace_import_service.dart` and named collaborators)
- repo: `D:\VoidScriptor\void_scriptor_multiplatform`, branch `master`, HEAD `141e86e`
- files in primary scope: 2; collaborators/tests listed above
- agents run: hunter 7 findings → referee 7 REAL; skeptic 7 confirmed / 0 disproved → referee 7 REAL
- commands run: `git status --short --branch`; `git rev-parse --short HEAD`; read-only file reads and searches via repository inspection tools
- status: VERIFIED (all findings carry file:line mechanisms and were checked against on-disk code at stamped HEAD); no target code executed

7 REAL / 0 dismissed
