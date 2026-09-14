# Skeptic Report — Void Scriptor Workspaces

Independent review of Hunter report `hunter_report_run308.md` at HEAD `141e86e`. The cited production excerpts were checked against the actual files, with caller/domain/test searches performed under `lib/` and `test/`. Per the expected-value rule, a finding is DISPROVED only when confidence exceeds 67%; none met that threshold for dismissal.

---

**BUG-1** | Original: Critical | 10 pts
- **Counter-argument:** The claim is supported. `migrate()` validates inputs before mutation, but after the backup it performs filesystem copies and database link inserts as separate operations. No transaction or compensation encloses Phases 4–5. The backup is created, but the migration does not restore from it on a later exception.
- **Evidence:** `workspace_migration_runner.dart:122-140` copies stories and characters; `:143-158` calls `links.create()` in a loop; `:160-181` validates and runs the drill only afterward. `NovelCharacterLinkRepository.create()` (`novel_character_link_repository.dart:15-34`) performs one insert and exposes no encompassing transaction to the runner. The migration test (`test/features/workspaces/workspace_migration_runner_test.dart:43-86`) verifies the successful path only; no failure-compensation test was found.
- **Quoted excerpt check:** Hunter's cited copy/link excerpt is line-exact in the actual file (`:122-158`).
- **Confidence:** 97%
- **Risk calc:** EV = (97% x 10) - (3% x 20) = 9.1 pts
- **Decision:** CONFIRMED
- **Corrected severity:** High data-integrity issue rather than automatically Critical: the failure requires a later mutation error, but the residue is directly provable and there is no automatic recovery.

---

**BUG-2** | Original: Critical | 10 pts
- **Counter-argument:** The claim is supported for nested links in an otherwise valid legacy directory. `_copyInto` uses `Directory.list(recursive: true)` without `followLinks: false`, and only skips entities that are not `File`; it does not reject `Link`. A symlinked nested file can therefore be read/copied from its resolved external target. The app's top-level inventory does not eliminate this path: `_listChildDirectories()` only controls which top-level character directories are assigned, while nested links remain traversed by `_copyInto`.
- **Evidence:** `workspace_migration_runner.dart:196-204` lists top-level directories; `:206-217` uses `source.list(recursive: true)`, checks only `entity is! File`, then reads through `entity.copy()`. No `followLinks` argument or `Link` rejection exists. The target namespace validates identifier syntax only (`workspace_file_namespace.dart:70-76,112-123`), not filesystem link targets. No symlink-specific guard/test was found.
- **Quoted excerpt check:** Hunter's cited excerpt is line-exact at `workspace_migration_runner.dart:209-214`.
- **Confidence:** 91%
- **Risk calc:** EV = (91% x 10) - (9% x 20) = 7.3 pts
- **Decision:** CONFIRMED
- **Corrected severity:** High security/data-boundary issue, not necessarily Critical in every deployment: exploitation requires a link in legacy package contents, but the external-byte copy path is reachable.

---

**BUG-3** | Original: Critical | 10 pts
- **Counter-argument:** The claim is supported. The migration input type is explicitly a list of assignments, and each assignment is validated against a novel mapping. The uniqueness set is keyed only by `characterId`, so reusing one character ID for a second mapped novel is rejected even though the link model is novel-scoped.
- **Evidence:** `workspace_migration_runner.dart:60-62` accepts `List<CharacterNovelAssignment>`; `:73-93` rejects a repeated `assignment.characterId`; `:145-155` creates links with both `novelWorkspaceId` and `characterId`. Existing domain tests document the allowed case: `test/features/workspaces/narrative_assignment_persistence_test.dart:140-162` says the same character has independent assignments in two novels, and `narrative_character_filter_test.dart:9-13` documents OR semantics across novels. No caller-level guard was found that changes the migration's global set into a `(novel, character)` key.
- **Quoted excerpt check:** Hunter's cited excerpt is line-exact at `workspace_migration_runner.dart:73-93`.
- **Confidence:** 96%
- **Risk calc:** EV = (96% x 10) - (4% x 20) = 8.8 pts
- **Decision:** CONFIRMED
- **Corrected severity:** High compatibility/data-integrity issue. Critical is inflated absent evidence that migration is the only way to perform the legitimate cross-novel reuse or that existing data is destroyed.

---

**BUG-4** | Original: Critical | 10 pts
- **Counter-argument:** The claim is supported. The input is a `Map<String, String>`, which guarantees unique source keys but not unique target values. Validation checks each key and value independently and never checks duplicate values. The copy loop then targets `_files.novelDirectory(entry.value)`, so two sources with the same target are merged. Deterministic link IDs also collide when both assignments share the same novel target and character ID; the repository insert has no preflight uniqueness handling.
- **Evidence:** `workspace_migration_runner.dart:60-71` validates identifiers only; `:123-131` copies each source into the target derived from `entry.value`; `:143-157` derives IDs from novel and character IDs. `novel_character_link_repository.dart:15-33` directly inserts `linkId`. The cited domain model keeps novel and character IDs as separate fields (`novel_character_link.dart:5-30`) but does not repair duplicate migration targets.
- **Quoted excerpt check:** Hunter's cited excerpts are line-exact at `workspace_migration_runner.dart:64-71`, `:123-130`, and `:146-150`.
- **Confidence:** 95%
- **Risk calc:** EV = (95% x 10) - (5% x 20) = 8.5 pts
- **Decision:** CONFIRMED
- **Corrected severity:** High data-integrity issue. Critical is plausible for a destructive/ambiguous migration, but the current code copies without deleting sources, so the immediate effect is merged target data and likely link failure rather than irreversible source loss.

---

**BUG-5** | Original: Medium | 5 pts
- **Counter-argument:** The claim is supported as an error-reporting/acceptance bug. `_verifyCopy` failures only flip `validatedCounts` to false; the runner still invalidates projections, runs the rollback drill, and returns a report with `projectionRebuilt: true` and `backupCreated: true`. There is no throw, abort, or recovery based on the failed validation. The report does expose `validatedCounts: false`, so it does not literally hide the failed check, but normal return makes the operation appear completed to callers unless they inspect that field.
- **Evidence:** `workspace_migration_runner.dart:160-173` accumulates a boolean; `:175-192` proceeds and returns normally with `validatedCounts` and other success-like fields. No caller handling for `validatedCounts` was found in the searched `lib/` references. Existing migration tests cover only `isTrue` (`workspace_migration_runner_test.dart:59-67`).
- **Quoted excerpt check:** Hunter's cited excerpt is line-exact at `workspace_migration_runner.dart:160-192`.
- **Confidence:** 94%
- **Risk calc:** EV = (94% x 5) - (6% x 10) = 4.1 pts
- **Decision:** CONFIRMED
- **Corrected severity:** Medium as reported; the false status is observable in the report, so this is not a fully silent success, but it is still an unsafe success-path contract.

---

**BUG-6** | Original: Medium | 5 pts
- **Counter-argument:** The claim is supported. The backup creation call's return value/identity is discarded. `_runRollbackDrill()` enumerates all direct backup directories and chooses the lexicographically greatest path, not the backup made by the current invocation. Project recovery creates backup directories using random UUIDs (`project_recovery_services.dart:271-274`), so lexical order is not a reliable recency or identity relation. Multiple backups are therefore sufficient to produce a drill against the wrong snapshot.
- **Evidence:** `workspace_migration_runner.dart:96-101` creates the backup without retaining an ID; `:277-286` collects and sorts all roots and chooses `last`; `:287-303` restores that selected backup. `project_recovery_services.dart:271-274` constructs the backup directory from `const Uuid().v4()`. No caller or test binds the drill to the newly created backup.
- **Quoted excerpt check:** Hunter's cited excerpts are line-exact at `workspace_migration_runner.dart:97-101` and `:285-286`.
- **Confidence:** 94%
- **Risk calc:** EV = (94% x 5) - (6% x 10) = 4.1 pts
- **Decision:** CONFIRMED
- **Corrected severity:** Medium. This is a reliability/validation defect; it creates a false signal only when another backup exists and differs, rather than corrupting the production migration directly.

---

**BUG-7** | Original: Medium | 5 pts
- **Counter-argument:** The claim is supported. The export contract defines exactly three representation tokens, but import reduces the decision to “non-null and not `reference_manifest`.” Thus arbitrary values such as `bogus` select the embedded materialization branch. The later code validates embedded payload structure and database conflicts, but never validates the representation token itself, so an unknown token is not rejected as an unknown format.
- **Evidence:** `workspace_export_service.dart:17-20` defines `reference_manifest`, `embedded_snapshot`, and `fork`. `workspace_import_service.dart:355-360` computes `embedded` from only a null/reference comparison; `:407-489` enters embedded payload parsing/materialization when true. The import tests use declared supported values; no unknown-token rejection test or guard was found.
- **Quoted excerpt check:** Hunter's cited excerpt is line-exact at `workspace_import_service.dart:355-360`.
- **Confidence:** 96%
- **Risk calc:** EV = (96% x 5) - (4% x 10) = 4.4 pts
- **Decision:** CONFIRMED
- **Corrected severity:** Medium is somewhat inflated for ordinary UI-generated archives because the exporter emits only enum values; retain Medium for untrusted/imported archives, otherwise Low validation robustness.

---

**SUMMARY:**
- Bugs disproved: 0 (total points claimed: 0)
- Bugs accepted as real / confirmed: 7 (total points accepted: 55)
- Final skeptic score under the supplied scoring rule: 55 pts

**ACCEPTED BUG LIST:**
- BUG-1 — Critical (corrected to High)
- BUG-2 — Critical (corrected to High)
- BUG-3 — Critical (corrected to High)
- BUG-4 — Critical (corrected to High)
- BUG-5 — Medium
- BUG-6 — Medium
- BUG-7 — Medium (Low for trusted UI-generated archives)
