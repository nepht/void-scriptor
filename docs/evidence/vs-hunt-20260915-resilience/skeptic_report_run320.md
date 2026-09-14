# Adversarial Bug Hunt — Skeptic Report

Scope: `lib/features/project_resilience`. Each finding was checked against the cited implementation and relevant `lib/` callers. DISPROVE is used only where confidence exceeds 67%.

---
**BUG-1** | Original: 10 pts
- **Counter-argument:** The cited importer does not itself replace backslashes before normalization, but every emitted path is passed through `ProjectPackage.resolve`, which does replace Windows backslashes and rejects normalized parent traversal. Drive-qualified and other absolute POSIX-form paths are rejected by the explicit absolute check; a Windows-style traversal becomes `../...` in `resolve` and is rejected there.
- **Evidence:** Importer evidence: `final output = File(package.resolve(relative));`. `ProjectPackage.resolve` states: `final normalized = p.posix.normalize(relativePath.replaceAll('\\\\', '/'));` followed by `if (normalized == '..' || normalized.startsWith('../')) { throw ArgumentError.value(..., 'escapes package'); }`.
- **Confidence:** 97%
- **Risk calc:** EV = (97% x 10) - (3% x 20) = 9.1
- **Decision:** DISPROVE
---

**BUG-2** | Original: 10 pts
- **Counter-argument:** The session release deliberately refuses to delete a marker whose session ID no longer matches the releasing session. That is the required ownership guard: deleting it would be more dangerous because the marker may belong to a newer session. The method then clears only this instance's local ownership state; it does not claim or delete the other session's marker. The report's wording treats loss of the marker as an unresolved owned marker, but the code demonstrates that this session no longer has a marker it may safely release.
- **Evidence:** `final marker = jsonDecode(await package.sessionFile.readAsString());` then `if (marker is! Map || marker['sessionId'] != owned) return;`. The caller's teardown sets `_lockReleased = true` only after `await lock.release()` returns, and `ProjectSession.close()` serializes concurrent shutdown via `Future<void> close() => _closing ??= _close();`.
- **Confidence:** 72%
- **Risk calc:** EV = (72% x 10) - (28% x 20) = 1.6
- **Decision:** DISPROVE
---

**BUG-3** | Original: 10 pts
- **Counter-argument:** Dead-owner recovery validates only that the recorded PID is not currently alive. It has no process-start identity, executable identity, or session-generation proof, so a reused PID can be mistaken for the dead recorded owner. Recovery then copies and deletes the marker, allowing a new writer to take the project lock while the unrelated process is alive.
- **Evidence:** `final ownerPid = marker['processId'];` and `if (ownerPid is! int || ownerPid <= 0 || await _isProcessAlive(ownerPid)) { return false; }`, followed by `await package.sessionFile.copy(...); await package.sessionFile.delete();`.
- **Confidence:** 99%
- **Risk calc:** EV = (99% x 10) - (1% x 20) = 9.7
- **Decision:** ACCEPT
---

**BUG-4** | Original: 10 pts
- **Counter-argument:** Recovery is a delete-then-create sequence with no retry or post-failure ownership reconciliation. Between `_recoverDeadOwnerMarker()` deleting the stale marker and the second exclusive create, another opener can create the marker. This opener then receives a failure and reports an active/stale session even though its own recovery already established a dead owner; this is a real availability/race defect, even though it fails closed rather than granting two owners.
- **Evidence:** The recovery branch is exactly `if (!await _recoverDeadOwnerMarker()) { throw StateError('Project has an active or stale session'); } await package.sessionFile.create(exclusive: true);`. `_recoverDeadOwnerMarker` performs `await package.sessionFile.delete();` before returning `true`.
- **Confidence:** 96%
- **Risk calc:** EV = (96% x 10) - (4% x 20) = 8.8
- **Decision:** ACCEPT
---

**BUG-5** | Original: 10 pts
- **Counter-argument:** The public controller path does not pass an unvalidated caller path into this method. It reads persisted metadata, resolves `latest.trashPath` through `package.resolve`, and resolves `latest.originalPath` through the same containment-checking package helper before calling `restore`. A crafted relative traversal therefore throws before `ProjectTrashService.restore` is reached. The low-level method is unsafe in isolation, but the reported application path is guarded by its caller.
- **Evidence:** Caller code: `final trashed = File(session.package.resolve(latest.trashPath));` and `).restore(trashed, session.package.resolve(latest.originalPath));`. `ProjectPackage.resolve` rejects `normalized == '..' || normalized.startsWith('../')` with `'escapes package'`.
- **Confidence:** 98%
- **Risk calc:** EV = (98% x 10) - (2% x 20) = 9.4
- **Decision:** DISPROVE
---

**BUG-6** | Original: 5 pts
- **Counter-argument:** The report is correct: the integrity report computes `orphanFiles`, but its `portable` getter does not include that field. The controller separately computes and exposes `orphanPaths`, but the UI's Portable status reads `snapshot.integrity.portable`, so orphan assets do not change the displayed portability result.
- **Evidence:** `orphanFiles: orphans.length,` is populated in `ProjectIntegrityService`, while the getter is `manifestValid && databaseValid && missingFiles == 0 && externalFiles == 0;`. The presentation reads `snapshot.integrity.portable ? 'yes' : 'needs attention'`.
- **Confidence:** 99%
- **Risk calc:** EV = (99% x 5) - (1% x 10) = 4.85
- **Decision:** ACCEPT
---

**BUG-7** | Original: 5 pts
- **Counter-argument:** Custom backups are intentionally stored outside the package and recorded with an absolute path. The scan's `backupItems` count only enumerates `session.package.backupDirectory`, while the snapshot separately returns database backup rows. Thus the package-internal directory count omits valid external backup directories, making that displayed count incomplete under the configured external-root feature.
- **Evidence:** Recording chooses `relativePath: ... ? backup.path : ...`, where the external branch stores `backup.path`. Scanning uses `final backupItems = (await _backupDirectories()).length;`, and `_backupDirectories` lists only `session.package.backupDirectory`.
- **Confidence:** 95%
- **Risk calc:** EV = (95% x 5) - (5% x 10) = 4.25
- **Decision:** ACCEPT
---

**BUG-8** | Original: 5 pts
- **Counter-argument:** Pruning performs the filesystem deletion before deleting the corresponding repository row. If directory deletion succeeds and `repository.removeBackup` fails, the row remains pointing at a missing backup. The loop has no compensating action, transaction, or retry in this method, so an interruption can leave inconsistent metadata and filesystem state.
- **Evidence:** The order is `if (await directory.exists()) { await directory.delete(recursive: true); } await repository.removeBackup(victim.id);`. The method then proceeds to the next victim; there is no catch or recovery around either operation.
- **Confidence:** 97%
- **Risk calc:** EV = (97% x 5) - (3% x 10) = 4.55
- **Decision:** ACCEPT
---

**BUG-9** | Original: 1 pt
- **Counter-argument:** `data` comes from separately decoded JSON snapshots. Nested maps and lists therefore have distinct object identities even when structurally equal, and Dart's `!=` on those values is not deep JSON equality. Equal nested content can consequently be classified as changed.
- **Evidence:** The comparison branch is `} else if (first.data[key] != second.data[key]) { changed[key] = {'before': first.data[key], 'after': second.data[key]}; }`. There is no recursive comparison or canonical JSON normalization.
- **Confidence:** 99%
- **Risk calc:** EV = (99% x 1) - (1% x 2) = 0.97
- **Decision:** ACCEPT
---

**BUG-10** | Original: 5 pts
- **Counter-argument:** Relative backup paths are resolved through `ProjectPackage.resolve`, not joined blindly. That helper normalizes slash styles and rejects `..` paths escaping the package. Absolute paths are an intentional representation for custom external backup roots, as shown by the backup-location policy and the controller's external-path recording; treating that supported case as traversal does not establish the claimed relative-path vulnerability.
- **Evidence:** Restore flow: `if (p.isAbsolute(stored)) return Directory(stored); return Directory(session.package.resolve(stored));`. The helper explicitly does `replaceAll('\\\\', '/')` and throws when normalized paths equal or start with `..`. External recording is explicit: `BackupLocationPolicy.isExternalBackup(...) ? backup.path : p.relative(...)`.
- **Confidence:** 98%
- **Risk calc:** EV = (98% x 5) - (2% x 10) = 4.7
- **Decision:** DISPROVE
---

**SUMMARY:**
- Bugs disproved: 4 (total points claimed: 30)
- Bugs accepted as real: 6
- Your final score: 30 points

**ACCEPTED BUG LIST:**
- BUG-3 — Critical
- BUG-4 — Critical
- BUG-6 — Medium
- BUG-7 — Medium
- BUG-8 — Medium
- BUG-9 — Low
