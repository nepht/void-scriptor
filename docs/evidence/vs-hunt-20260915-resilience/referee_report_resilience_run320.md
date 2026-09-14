# Adversarial Bug Hunt — Referee Report

- **Target:** `lib/features/project_resilience`
- **Authority:** Independent referee review of the Hunter and Skeptic reports plus the implementation and relevant callers.
- **Hunter report:** `docs/evidence/vs-hunt-20260915-resilience/hunter_report_run320.md`
- **Skeptic report:** `docs/evidence/vs-hunt-20260915-resilience/skeptic_report_run320.md`

## Per-finding verdicts

---
**BUG-1**
- **Hunter's claim:** Portable archive extraction can escape the destination on Windows through backslash traversal or drive-qualified archive names.
- **Skeptic's response:** DISPROVE — `ProjectPackage.resolve` converts backslashes to `/` and rejects normalized parent traversal; the importer also rejects absolute paths.
- **Your analysis:** The cited importer first normalizes archive names with `p.posix.normalize` and rejects `p.isAbsolute(relative)`, `..`, and `../` prefixes. Every accepted name is then passed to `ProjectPackage.resolve`, whose second normalization converts Windows backslashes and rejects `..` and `../` escapes before joining to the package root. Thus `..\\foo` is rejected by `resolve`; a drive-qualified form such as `C:\\foo` is rejected by the importer's platform-aware absolute-path check. Archive entry names are not URL-decoded by this code, so `%2e%2e%2ffoo` remains a literal filename rather than becoming traversal. The evidence does not establish an escaping path through this call chain.
- **VERDICT: NOT A BUG**
- **Confidence:** High

---
**BUG-2**
- **Hunter's claim:** Closing a session after discovering a marker for another session leaves owned-marker state unresolved while teardown proceeds as though the lock was released.
- **Skeptic's response:** DISPROVE — the ownership guard deliberately refuses to delete a marker whose session ID no longer matches; `ProjectSession.close` marks release only after `release` returns, and close is serialized.
- **Your analysis:** `release` returns without deleting a mismatched marker, then clears only this lock object's local `_ownedSessionId`. In `ProjectSession._close`, `_lockReleased` is set to true only after `lock.release()` returns, so this behavior is intentionally treated as a completed safe release attempt, not as permission to delete a newer owner's marker. The companion lock cleanup still runs, and `close()` serializes callers. The code does not prove that the current session still owns the marker after a mismatch; it proves the opposite and fails closed against deleting another session's marker. The remaining concern is semantic ambiguity around losing ownership, not an established exclusivity defect.
- **VERDICT: NOT A BUG**
- **Confidence:** Medium

---
**BUG-3**
- **Hunter's claim:** Dead-owner recovery accepts any currently dead recorded PID, so PID reuse can displace a live unrelated process's marker.
- **Skeptic's response:** ACCEPT — recovery has no process-start identity, executable identity, or session-generation validation.
- **Your analysis:** `_recoverDeadOwnerMarker` trusts only `marker['processId']` and `_isProcessAlive(ownerPid)`. A PID that belonged to the original owner can be reused; if the replacement process is not alive at the probe, or if the PID identity changes during the check/recovery window, the stale marker can be copied and deleted. There is no start-time token, executable identity, or OS process handle tying the PID to the recorded owner. This breaks the lock's exclusivity proof and can permit a new writer to proceed while the actual unrelated process is alive. The code itself establishes the missing identity check; no runtime race evidence is needed to confirm the design flaw.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Critical
- **Suggested fix:** Record and validate an owner identity stronger than a bare PID (for example process start time plus executable identity, or an OS-level process handle/identity where available), and treat identity uncertainty as active-owner/fail-closed. Keep stale-marker archival and acquisition atomic or otherwise reconcile ownership after recovery.

---
**BUG-4**
- **Hunter's claim:** Delete-then-create lock recovery has a race in which another opener can acquire the marker and cause this opener's retry to fail without retry/reconciliation.
- **Skeptic's response:** ACCEPT — `_recoverDeadOwnerMarker` deletes the marker before the second exclusive create, and the caller has no retry or ownership reconciliation.
- **Your analysis:** The recovery branch deletes the stale marker and returns true; the original opener then performs a separate exclusive create. Another opener can create the marker between those operations. The original opener then throws `StateError('Project has an active or stale session')`, even though it had observed a dead marker and could have retried or reported the competing owner distinctly. This is a real availability defect and a lock-recovery race, but the shown sequence fails closed rather than granting two owners. No runtime evidence is present, so the concurrency aspect is code-proven but any frequency estimate is not.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Replace delete-then-create with an atomic compare-and-replace/claim protocol, or retry acquisition after a competing create while re-reading and validating the current marker. Preserve the fail-closed behavior if ownership cannot be established.

---
**BUG-5**
- **Hunter's claim:** `ProjectTrashService.restore` can rename a trashed file to an arbitrary caller-provided path outside the project.
- **Skeptic's response:** DISPROVE — the production controller resolves both metadata paths with `ProjectPackage.resolve`, and no other `ProjectTrashService.restore` caller was found.
- **Your analysis:** The method is unsafe as an isolated public method because it does not validate `originalPath`, but the reported application path has one reachable caller: `ProjectResilienceController.restoreLatestTrash`. That caller passes both `latest.trashPath` and `latest.originalPath` through `session.package.resolve`. `resolve` normalizes slash styles and rejects paths that normalize to `..` or begin with `../`. The repository-wide search found no other caller of `ProjectTrashService.restore`; `moveToTrash` itself records package-relative, normalized metadata paths. A crafted relative traversal therefore fails before `restore` is invoked. The low-level defense-in-depth omission is not the claimed reachable application vulnerability.
- **VERDICT: NOT A BUG**
- **Confidence:** High

---
**BUG-6**
- **Hunter's claim:** The project is displayed as portable when orphan asset files exist because `ProjectIntegrityReport.portable` omits `orphanFiles`.
- **Skeptic's response:** ACCEPT — `orphanFiles` is computed, but the getter and the presentation status omit it.
- **Your analysis:** `ProjectIntegrityService.scan` computes `orphans` and sets `orphanFiles: orphans.length`. The `portable` getter checks manifest validity, database validity, missing files, and external files, but not orphan files. The controller separately exposes `orphanPaths`, yet the production screen reads `snapshot.integrity.portable` for the Portable diagnostic. The existing controller test confirms orphan detection but does not make the portable predicate false. Consequently an orphan-only project can display `Portable: yes` while requiring repair.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Include `orphanFiles == 0` in the portable predicate, and add a presentation/controller regression test asserting that an orphan asset yields `needs attention`.

---
**BUG-7**
- **Hunter's claim:** Backups in a configured external root are recorded but omitted from the displayed backup-directory count.
- **Skeptic's response:** ACCEPT — external paths are deliberately persisted as absolute paths, while `_backupDirectories` scans only the package-internal directory.
- **Your analysis:** `createBackup` selects the configured custom root when it exists and records an external backup's absolute `backup.path` in the database. `scan` computes `backupItems` solely from `session.package.backupDirectory.list()`. The screen displays that scalar as `Available backups`, while the separately loaded `backups` rows are not used for that count. A valid external backup can therefore be present in the recorded list and restore flow but absent from the displayed count. This is a real observability/UI correctness bug, not a security issue; the external location is intentional.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Define the count from validated recorded backup rows, or scan both internal and configured external roots with deduplication and existence checks. Keep the database row as the source of truth for backups created outside the package.

---
**BUG-8**
- **Hunter's claim:** Retention pruning deletes backup data before its database row, so an interrupted failure leaves inconsistent state.
- **Skeptic's response:** ACCEPT — filesystem deletion precedes `removeBackup`, with no transaction, compensation, or recovery in the method.
- **Your analysis:** `_enforceBackupRetention` deletes each resolved backup directory first and only then removes its database row. If the deletion succeeds and the database operation fails, the row remains while its directory is gone. If deletion fails, the row remains and the exception aborts the loop. The method has no catch/repair or durable reconciliation. The inconsistency scenario follows directly from the irreversible ordering, although the actual occurrence rate depends on runtime I/O/database failures.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Use a recoverable deletion protocol (mark pending deletion, remove/transactionally update metadata, then delete with startup reconciliation), or make pruning retry and reconcile missing directories and rows. Do not claim atomicity across filesystem and database without a journal.

---
**BUG-9**
- **Hunter's claim:** Version comparison uses shallow inequality, so equal nested decoded JSON maps/lists appear changed.
- **Skeptic's response:** ACCEPT — snapshots are separately decoded and Dart collection inequality is not structural JSON equality.
- **Your analysis:** `compare` iterates matching keys and uses `first.data[key] != second.data[key]`. The snapshots are read from separate JSON files, so nested maps/lists have distinct identities even with identical contents. Dart's default collection equality is not recursive JSON equality. Equal nested data is therefore reported in `changed`, producing a false diff. Impact is limited to version-diff accuracy.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low
- **Suggested fix:** Compare JSON values structurally (recursive map/list equality or canonical JSON encoding with deterministic map-key ordering) before adding a changed entry.

---
**BUG-10**
- **Hunter's claim:** A persisted relative backup path can traverse outside the package during restore.
- **Skeptic's response:** DISPROVE — relative paths go through `ProjectPackage.resolve`, which rejects parent traversal; absolute paths intentionally represent custom external backup roots.
- **Your analysis:** Both the restore flow's preview path and the controller's restore path use `_resolveBackupDirectory`; relative values are passed through `session.package.resolve`, which converts backslashes and rejects normalized parent traversal. Absolute values are deliberately supported because `BackupLocationPolicy` records custom-root backups as absolute paths and documents that policy. Therefore `../...` and Windows-backslash traversal are rejected on the relative branch, while an absolute path is not a relative traversal but an intentional external-backup representation. The separate trust question of tampered absolute metadata is outside the finding as stated and is not enough to establish this bug.
- **VERDICT: NOT A BUG**
- **Confidence:** High

## VERIFIED BUG REPORT

### Stats

- **Total reported by Hunter:** 10
- **Dismissed as false positives:** 4
- **Confirmed as real bugs:** 6
- **Critical:** 1 | **Medium:** 4 | **Low:** 1

### Confirmed bugs (ordered by severity)

| # | Severity | File | Line(s) | Description | Suggested Fix |
|---|---|---|---|---|---|
| BUG-3 | Critical | `lib/features/project_resilience/application/project_recovery_services.dart` | 50-73 | Dead-owner recovery trusts a bare PID and can misidentify a reused PID as the recorded owner. | Validate process identity beyond PID; fail closed on uncertainty and use an atomic/reconciled claim. |
| BUG-4 | Medium | `lib/features/project_resilience/application/project_recovery_services.dart` | 22-34, 50-73 | Stale-marker delete followed by exclusive create has a competing-opener race and no retry/reconciliation. | Atomic claim or retry/re-read after competing creation. |
| BUG-6 | Medium | `lib/features/project_resilience/application/project_resilience_repository.dart`, `project_resilience_controller.dart` | repository 24-39; controller 71-92 | Portable status omits orphan files even though orphan files are computed and shown as a repair condition elsewhere. | Require `orphanFiles == 0` and add regression coverage. |
| BUG-7 | Medium | `lib/features/project_resilience/application/project_resilience_controller.dart` | 96-127, 290-297 | Available-backup count scans only package-internal directories and omits valid external-root backups. | Count validated recorded rows or scan/deduplicate all configured roots. |
| BUG-8 | Medium | `lib/features/project_resilience/application/project_resilience_controller.dart` | 261-280 | Retention can leave a database row pointing to a deleted directory after a metadata-write failure. | Journal/mark pending deletion and reconcile, or otherwise add retry/compensation. |
| BUG-9 | Low | `lib/features/project_resilience/application/project_version_control_service.dart` | 95-111 | Nested JSON values are compared by identity instead of structural equality. | Recursive/canonical JSON equality. |

### Low-confidence items flagged for manual review

- **BUG-2 — NOT A BUG, Medium confidence:** The ownership guard and serialized close support the dismissal, but the exact intended semantics of clearing local ownership after a mismatched marker are contract-sensitive. Add an explicit test/comment if the project requires a mismatch to keep the session in a retryable state.

### Dismissed list

| Bug | Verdict | Reason |
|---|---|---|
| BUG-1 | NOT A BUG | Backslash traversal is normalized and rejected by `ProjectPackage.resolve`; drive-qualified paths are rejected by the importer absolute-path check; archive names are not URL-decoded. |
| BUG-2 | NOT A BUG | A mismatched marker is intentionally not deleted; `_lockReleased` is set only after release returns, and close callers are serialized. |
| BUG-5 | NOT A BUG | The only production restore caller resolves metadata paths through `ProjectPackage.resolve`, which rejects escaping relative paths. |
| BUG-10 | NOT A BUG | Relative paths are containment-checked by `ProjectPackage.resolve`; absolute paths are the documented representation for external custom backups. |

verified at HEAD 762ed7f5b5af9a1dce8d867ed1ce395a75295b27
