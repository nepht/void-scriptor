# Bug-hunt run94 — SKEPTIC report

Scope: 15 files, Void Scriptor persistence/session layer (D:\VoidScriptor\void_scriptor_multiplatform, working tree as-is). Every reported location was re-read independently before judging; cross-file contracts verified by reading project_recovery_services.dart (ProjectSessionLock/ProjectBackupService), command_type_registry.dart, project_mutation_runtime.dart (filtered lines), project_package.dart (lockFile), and project_database_service.dart in full. Caller searches confirmed probeWrite / movePackage / recoverInterruptedMoves have no production callers in lib/ (doc references only). Two `search_files` regex calls failed (paren escaping); production wiring of ProjectRegistryService and any producers of `asset.rename`/`asset.delete` history records could NOT be verified before the time budget cut — those findings are marked UNCERTAIN rather than guessed.

Verdict vocabulary: CONFIRMED (= ACCEPT as real), DISPROVED, UNCERTAIN.

---
**BUG-01** | Original: 10 pts | movePackage destination clobber — **DISPROVED**
- **Counter-argument:** The claimed destruction mechanism ("the second `rename` replaces the first package's just-moved directory wholesale, silently destroying a complete project") contradicts OS rename semantics. POSIX `rename(2)` on directory→existing-directory succeeds only when the target is an **empty** directory; a non-empty target (a complete `.voidproject` package) fails with ENOTEMPTY, which surfaces here as `FileSystemException` → caught at project_move_service.dart:50 → marker consumed → `rethrow` to the caller. On Windows, `Directory.rename` (MoveFile) fails outright when the destination exists. So a pre-existing non-empty destination or a concurrently landed package is never silently replaced — the error propagates. Only an *empty* pre-existing directory could be replaced, which destroys no project data. Verified additionally: `movePackage` has no production callers (search: definition + doc references only), matching the Hunter's own note.
- **Evidence:** project_move_service.dart:48-60 — `try { await package.rename(destination); } on FileSystemException { ... marker.delete(); rethrow; }`; and search across lib/ showing `movePackage` referenced only in docstrings.
- **Confidence:** 78%
- **Risk calc:** EV = (78% × 10) − (22% × 20) = +3.4
- **Decision:** DISPROVED
---
**BUG-02** | Original: 5 pts | atomicWrite rollback resurrects stale .bak — **CONFIRMED**
- **Counter-argument:** The *exact* resurrect mechanism as stated is partially guarded — the loser's rollback path checks `await backup.exists() && !await target.exists()`, and the winner's successful commit creates the target, so a plain two-writer race does not restore .bak over a live target. However, the finding's essence is correct and demonstrable from the code: `atomicWrite` (project_recovery_service.dart:98-120) uses a **shared** temp name (`'${target.path}.tmp'`) and has zero serialization, so two interleaved writers on one target (exactly the registry `upsert`-vs-`load()`-admission `save` pair inside `ProjectRegistryService`) produce genuinely wrong outcomes: loser's `temporary.rename(target.path)` fails with PathNotFound because the winner consumed the shared .tmp, the winner's content wins by accident, and the loser throws despite its content having been persisted — plus classic lost-update windows. The method is not safe under the concurrent writers the Hunter says the Riverpod wiring can produce.
- **Evidence:** project_recovery_service.dart:103-104 (`final temporary = File('${target.path}.tmp')` — one shared path per target), 106-119 (no lock/mutex/retry anywhere), project_registry_service.dart:104+111 (`upsert` = `load()` then `save()` → `atomicWrite`) and 55 (`load()` itself calls `save(merged)`).
- **Confidence:** 68%
- **Risk calc:** n/a (accept)
- **Decision:** CONFIRMED (mechanism corrected: unsynchronized shared-.tmp write, not .bak resurrection)
---
**BUG-03** | Original: 10 pts | recoverInterruptedMoves TOCTOU swaps/overwrites packages — **DISPROVED**
- **Counter-argument:** Same rename-semantics flaw as BUG-01. The probe→rename gap (project_recovery_service.dart:194-203) is real as a time-of-check window, but the claimed outcome — "two move sessions … can swap or overwrite whole `.voidproject` packages, silently losing a project" — cannot occur: POSIX rename never replaces a non-empty destination directory and Windows rename fails on any existing destination. Two concurrent recovery scans of the same root: the first `entity.rename(destination)` succeeds, the second fails (source already gone) → `on FileSystemException { continue; }` — no loss. The marker identity checks (`matchesSource`/`matchesDestination` at 182-192) further pin each journal to exactly one package. Verified: `recoverInterruptedMoves` has no production callers (search: definition + doc references only), as the Hunter itself notes.
- **Evidence:** project_recovery_service.dart:199-203 (`on FileSystemException { continue; }` — failures are skipped, never destructive), 182-187 (source/destination identity match required), and the no-caller search result.
- **Confidence:** 75%
- **Risk calc:** EV = (75% × 10) − (25% × 20) = +2.5
- **Decision:** DISPROVED
---
**BUG-04** | Original: 5 pts | _decodeProjects throws raw errors; remove() aborts — **CONFIRMED**
- **Counter-argument:** None that survives the code. `_decodeProjects` (project_registry_service.dart:66-80) performs `jsonDecode(...) as Map<String, dynamic>` (TypeError if the file is a JSON array), throws raw `FormatException` on `schemaVersion != 1`, and `ProjectModel.fromJson(item as Map<String, dynamic>)` throws TypeError on one corrupt entry — all propagate unclassified. `remove()` (123-125) is `save((await load()).where(...))`, so any decode failure aborts the delete after the caller may already have removed the package on disk, diverging registry from disk. The one overstated sub-claim: a read "racing the atomic-replace" cannot see a truncated file (rename-based replace is atomic; readers see old or new). The corrupt-content path stands on its own. Note `recoverIfInterrupted` only restores a *missing* target — it never falls back to .bak on a decode failure, so corrupt content has no second chance.
- **Evidence:** project_registry_service.dart:68-79 (raw casts + `throw FormatException(...)`), 123-125 (`remove` composes directly on `load()`), 131-137 (`recoverIfInterrupted` gated on `target.exists()` only).
- **Confidence:** 78%
- **Risk calc:** n/a (accept)
- **Decision:** CONFIRMED
---
**BUG-05** | Original: 5 pts | crash-window admission not serialized — **CONFIRMED**
- **Counter-argument:** The stated outcome ("producing duplicate registry entries for one project id") is misderived — each `save(merged)` writes a list that is internally deduped because `admitMarkedCreations` filters against the ids decoded in that same call, so persisted duplicates do not materialize. But the core claim — admission is not serialized — is true, and it yields a *worse* sibling failure I verified by walking the interleaving: load#1 decodes registered=[] , admits X, saves [X], consumes X's marker; load#2 decodes registered=[] before load#1's save, admits Y, saves [Y] — the last writer overwrites [X] out of the file while X's creation marker has already been consumed, so X is never admitted again and becomes permanently invisible to the only discovery mechanism. A real, unserialized concurrency hazard on the exact lines cited.
- **Evidence:** project_registry_service.dart:28-63 (`load()` has no lock/mutex: decode → admit → save → consume markers), 46-55 (`admitMarkedCreations` + `save(merged)`), project_recovery_service.dart:85-87 (`consumeCreationMarker` deletes unconditionally).
- **Confidence:** 70%
- **Risk calc:** n/a (accept)
- **Decision:** CONFIRMED (mechanism corrected: lost admission via last-writer-wins, not duplicate entries)
---
**BUG-06** | Original: 5 pts | recoverIfInterrupted consumes .bak on legitimately missing target — **CONFIRMED**
- **Counter-argument:** None found. `atomicWrite` deliberately **leaves the .bak in place after a successful write** (project_recovery_service.dart:106-119 never deletes it on success), so a `.bak` coexisting with a deliberately deleted target is steady-state, not only a crash signature. `recoverIfInterrupted` (131-137) renames any existing `.bak` onto any missing target with no discrimination — `load()` (registry) and `read()` (manifest) call it unconditionally — so a deleted `projects.json` or `manifest/project.json` with a stale `.bak` is resurrected as the pre-save content instead of surfacing as missing. The "only restore copy consumed" part is also true: after the rename the `.bak` is gone, so a subsequent failure has no backup.
- **Evidence:** project_recovery_service.dart:131-137 (`if (await target.exists()) return; ... await backup.rename(target.path);`), 106-119 (no post-success `.bak` cleanup), project_registry_service.dart:32 and project_manifest_service.dart:50 (unconditional invocation).
- **Confidence:** 70%
- **Risk calc:** n/a (accept)
- **Decision:** CONFIRMED
---
**BUG-07** | Original: 5 pts | probeWrite commits probe table before cleanup; dead code — **CONFIRMED**
- **Counter-argument:** None. Verified directly: `probeWrite` (project_database_service.dart:182-226) runs `CREATE TABLE IF NOT EXISTS __scriptor_write_probe` + `INSERT` + `COMMIT` (lines 192-201) before the separate cleanup transaction and `DROP TABLE` (202-205). A crash/kill between the COMMIT and the DROP leaves the probe table permanently in the user's project database, contradicting the doc contract "TIDAK memodifikasi data aplikasi" (the header even still claims a ROLLBACK design the implementation abandoned). The Hunter's caller search matches mine: `probeWrite` has no callers anywhere in lib/ — dead code carrying the risk.
- **Evidence:** project_database_service.dart:191-205 (COMMIT at 201 precedes DROP at 205; two separate transactions), and the lib/-wide search returning only the definition and doc comments.
- **Confidence:** 85%
- **Risk calc:** n/a (accept)
- **Decision:** CONFIRMED
---
**BUG-08** | Original: 10 pts | probeWrite deletes -wal/-shm unconditionally — **CONFIRMED**
- **Counter-argument:** The mechanism is real and dangerous: after closing its own raw connection, `probeWrite` (project_database_service.dart:227-237) deletes `-wal` and `-shm` whenever they exist, with no check for other live connections. If a drift connection (or any WAL user) is open on the same database, deleting the WAL discards committed-but-uncheckpointed transactions — textbook SQLite data loss/corruption. One severity correction: since `probeWrite` has no production callers (verified), the phrase "a direct data-loss path on the production open path's storage" overstates reachability — the flaw is latent in the method, not on an active path. The code defect itself stands.
- **Evidence:** project_database_service.dart:229-237 (`for (final sidecar in [walSidecar, shmSidecar]) { if (sidecar.existsSync()) { try { sidecar.deleteSync(); }` — unconditional, best-effort only), plus the verified absence of callers.
- **Confidence:** 78%
- **Risk calc:** n/a (accept)
- **Decision:** CONFIRMED (severity tempered by dead-code status)
---
**BUG-09** | Original: 5 pts | Process.runSync blocks the isolate — **CONFIRMED**
- **Counter-argument:** None. `PlatformDriveSpaceReader.freeBytes` is declared `Future<int> ... async` but shells out with `Process.runSync('powershell.exe', ...)` (custom_storage_location.dart:152-158). PowerShell cold start is routinely hundreds of ms; every default probe (`CustomStorageLocation.probe` → `DefaultStorageProbe.check` → `freeBytes`) hits this synchronously on the calling isolate — the UI isolate in the Flutter app. `setActiveLocation`/`relinkLocation` await `probe(...)`, so the async signature provides no benefit; the sync process spawn freezes the isolate exactly as claimed.
- **Evidence:** custom_storage_location.dart:139 (`Future<int> freeBytes(String location) async {`) vs 152 (`final result = Process.runSync('powershell.exe', [`).
- **Confidence:** 90%
- **Risk calc:** n/a (accept)
- **Decision:** CONFIRMED
---
**BUG-10** | Original: 5 pts | normalizeLocation accepts relative paths → CWD-anchored storage — **CONFIRMED**
- **Counter-argument:** None at the API level. `normalizeLocation` (custom_storage_location.dart:49-62) only trims and `p.normalize`s — no `p.isAbsolute` check — and `setActiveLocation` (278-303) then `exists()`/`create()`s the relative path (resolved against the process CWD), probes it, and persists the relative string as `activeLocation`. `ProjectPaths.root()` later re-creates it relative to whatever the CWD is at that time (project_paths.dart:50-53), so projects can silently land under the install/temp directory. Whether the settings UI happens to always pass absolute paths is outside this scope; the in-scope API contract does not enforce it.
- **Evidence:** custom_storage_location.dart:49-61 (no isAbsolute rejection), 280-287 (`Directory(location).exists()` / `Directory(location).create(recursive: true)` on the unanchored string), 295-302 (persists it).
- **Confidence:** 75%
- **Risk calc:** n/a (accept)
- **Decision:** CONFIRMED
---
**BUG-11** | Original: 1 pt | drive-letter extraction mishandles UNC / forward-slash roots — **DISPROVED**
- **Counter-argument:** The mechanics described are accurate (a plain `\\server\share` root fails the `length > 2` guard and an un-normalized `C:/Users` root keeps its trailing slash), but the consequence is the **documented** behavior, not a malfunction: the `HostDriveSpaceReader` interface contract states "Implementations return -1 when the host cannot be queried; callers treat that as an unknown-budget signal," and `_Probe.checkWith` maps -1 to the conservative 1 GiB standing offer (custom_storage_location.dart:197-218). Returning -1 for unqueryable roots is the designed fallback, not wrong free-space reporting. The forward-slash case is additionally neutralized on every store path because `setActiveLocation`/`relinkLocation` run `normalizeLocation` first, and `p.normalize` on Windows converts separators, so `p.rootPrefix` yields `C:\`.
- **Evidence:** custom_storage_location.dart:124-126 (interface doc defining -1 as the unknown-budget signal), 213 (`final effective = freeBytes < 0 ? 1 << 30 : freeBytes;`), 279/317 (both callers normalize before probing).
- **Confidence:** 70%
- **Risk calc:** EV = (70% × 1) − (30% × 2) = +0.1
- **Decision:** DISPROVED
---
**BUG-12** | Original: 5 pts | registry()/scan directories — three different notions — **UNCERTAIN**
- **Reason not fully verified:** The paths-wiring internal claim is contradicted by the code I read — `_listingOwnerDirectory()` returns `paths.root()` (project_registry_service.dart:84), which is exactly the package directory in the default wiring (project_paths.dart:63-81 builds `<Documents>/VoidScriptor/Projects` and `project()` places packages inside it), so "admission scans a directory that contains no packages in the default wiring" appears false, and the registry *file* living one level up is not a scan directory. But the production construction sites of `ProjectRegistryService` could not be inspected (both paren-regex searches errored) before the time budget cut, so the "default wiring" premise is unconfirmed. Time budget: stopped here.
- **Confidence:** 55%
- **Decision:** UNCERTAIN
---
**BUG-13** | Original: 5 pts | `code == 778` unreachable after `& 0xFF` mask — **CONFIRMED**
- **Counter-argument:** None — arithmetically certain from the code as read. Line 144 masks: `final code = error.extendedResultCode & 0xFF;` → 778 (0x30A) & 0xFF = 10 (0x0A, primary SQLITE_IOERR). Line 157 then tests `if (code == 8 || code == 13 || code == 778)` — comparing a masked primary code against an extended literal can never match 778, so SQLITE_IOERR_WRITE falls through to `ProjectDatabaseUnreadableException` (line 165), i.e. reported as corruption instead of write failure. Exactly the misclassification the 145.42 matrix exists to prevent. (Masking to the primary code is itself defensible for 8/13/5/14 — the bug is testing an extended code against the masked value.)
- **Evidence:** project_database_service.dart:144 (`& 0xFF`), 157 (`code == 8 || code == 13 || code == 778`), 165 (fall-through to Unreadable).
- **Confidence:** 95%
- **Risk calc:** n/a (accept)
- **Decision:** CONFIRMED
---
**BUG-14** | Original: 5 pts | manifest restored from .bak never re-validated/rewritten; .bak consumed — **CONFIRMED**
- **Counter-argument:** The behavioral facts all check out in project_manifest_service.dart:46-60: on `ProjectManifestUnreadableException`, `restoreBackup(file)` renames the `.bak` onto the target (consuming it — project_recovery_service.dart:139-145), then `return _parse(file)` parses the restored content with no write-back of a canonical manifest. If the restored content is itself corrupt, the second `_parse` throws with no `.bak` remaining, so the manifest is a one-shot restore with zero remaining recovery material. The claim's "stays flagged by whatever made the original corrupt" is loosely worded (valid .bak content parses fine), but the no-rewrite + .bk-consumed substance is real. Whether rewrite-on-restore is contractually required is arguable; the fragility is not.
- **Evidence:** project_manifest_service.dart:53-59 (`final restored = await _recovery.restoreBackup(file); if (!restored) rethrow; return _parse(file);` — no write-back), project_recovery_service.dart:139-145 (`restoreBackup` renames the .bak away).
- **Confidence:** 70%
- **Risk calc:** n/a (accept)
- **Decision:** CONFIRMED
---
**BUG-15** | Original: 5 pts | relinkLocation accepts any containing directory, no migration — **UNCERTAIN**
- **Reason not fully verified:** The code behavior is exactly as quoted (custom_storage_location.dart:316-338: bound-project containment check or, unbound, any writable directory; probe; save). What I could not establish within budget is the intended contract of "relink" — repointing storage at a moved drive with the bound project present is arguably the feature working as designed, and the downstream "stale activeLocation → fallback root" behavior is `ProjectPaths.root()`'s documented pre-existing fallback, not something relink introduces. Whether unlisted old-location projects constitute a bug or a product decision needs the settings/discovery wiring outside this scope. Time budget: stopped here.
- **Confidence:** 55%
- **Decision:** UNCERTAIN
---
**BUG-16** | Original: 1 pt | rootDirectory wiring: admission scans one dir, stash recovery two — **CONFIRMED**
- **Counter-argument:** None — all three cited locations read directly. Constructor stores `File('<rootDirectory>/projects.json')` (project_registry_service.dart:11-14); `_listingOwnerDirectory()` returns `configuredFile.parent` only (82-88) and feeds `admitMarkedCreations` (46-49); `_recoverImportStashes()` scans `configuredFile.parent` **and** `<parent>/Projects` (160-171). So in the `rootDirectory` configuration a package carrying a creation marker under `<rootDirectory>/Projects` is never admitted while stash recovery would find it — a genuine internal inconsistency in one service, correctly rated Low.
- **Evidence:** project_registry_service.dart:11-14, 46-49, 82-88, 162-171 as quoted.
- **Confidence:** 80%
- **Risk calc:** n/a (accept)
- **Decision:** CONFIRMED
---
**BUG-17** | Original: 1 pt | health check: close() throw escapes the on-Object block — **DISPROVED**
- **Counter-argument:** The central error-handling claim is factually wrong about the code. In project_health_service.dart:57-65, `await opened.close()` is **inside** the same `try` block as `open` — the `on Object` handler wraps both statements, so a `close()` throw is caught, `databaseReadable` is set to false, and nothing escapes. The residual observation (a full read-write drift open, including metadata writes/migrations, on every health check) is a design/cost choice of "health = can we actually open it," not the claimed exception-escape/resource-leak defect.
- **Evidence:** project_health_service.dart:58-64: `try { final opened = await ProjectDatabaseService().open(database.path); await opened.close(); databaseReadable = true; } on Object { databaseReadable = false; }` — both calls share the one handler.
- **Confidence:** 85%
- **Risk calc:** EV = (85% × 1) − (15% × 2) = +0.55
- **Decision:** DISPROVED
---
**BUG-18** | Original: 5 pts | open-failure catch deletes the live owner's .project.lock — **CONFIRMED**
- **Counter-argument:** None — verified end to end. `companionWritten` (project_session_manager.dart:146, set true only at 157 after the write at 150) is never consulted in the catch (285-290): on any failure with `mode == readWrite` — including `lock.acquire()` throwing `StateError('Project has an active or stale session')` against an alive owner (project_recovery_services.dart:30) — the catch runs `lock.release()` (a no-op when `_ownedSessionId` is null) and then unconditionally deletes `package.lockFile` (`.project.lock`, project_package.dart:21) if it exists — i.e., the **owner's** companion file, written by the owner's own successful open. A rejected second session erases the live owner's companion. The guard exists in the variable and is simply not used.
- **Evidence:** project_session_manager.dart:285-290 (`catch (_) { if (mode == ProjectOpenMode.readWrite) await lock.release(); if (mode == ProjectOpenMode.readWrite && await package.lockFile.exists()) { await package.lockFile.delete(); }`) vs 146/157 (`companionWritten` set only on own write).
- **Confidence:** 85%
- **Risk calc:** n/a (accept)
- **Decision:** CONFIRMED
---
**BUG-19** | Original: 5 pts | asset.rename/asset.delete unregistered → filtered from history restore — **UNCERTAIN**
- **Reason not fully verified:** Verified halves: the session manager registers exactly six types (project_session_manager.dart:200-246) and `ProjectMutationRuntime.open` filters via `registry.tryCreate` + `whereType<AppCommand>()` (project_mutation_runtime.dart:70-79, command_type_registry.dart:24-26), so unregistered types would indeed be silently dropped. Unverified half: whether any production code ever appends `asset.rename`/`asset.delete` history records — my lib/-wide search for those literals returned a suspicious zero (the same query pattern demonstrably contains `asset.rename` in command_type_registry.dart:7,10), so the search result is unreliable and no producer could be confirmed before the time budget cut. Without a producer, the finding is theoretical; with one, it is real. Time budget: stopped here.
- **Confidence:** 55%
- **Decision:** UNCERTAIN
---
**BUG-20** | Original: 5 pts | partially-wired open: swallowed close, undisposed runtime — **UNCERTAIN**
- **Reason not fully verified:** The catch block is exactly as quoted (project_session_manager.dart:285-296): lock released, lockFile deleted, then `try { if (database != null) await database.close(); } catch (_) {}` — a close failure is swallowed and the handle's fate unexamined; `rethrow` preserves the original error. Also verified: the catch never calls `mutationRuntime.dispose()`, so a throw after `ProjectMutationRuntime.open` (e.g., during `ProjectSession` construction at 261-284) leaves the runtime undisposed. What I could not verify in budget is `ProjectMutationRuntime.dispose()`'s actual resource surface and whether drift's `close()` failing still releases the underlying handle — the "leak" conclusion depends on those internals. The visible hygiene gaps are real; the concrete leak mechanism is unproven. Time budget: stopped here.
- **Confidence:** 58%
- **Decision:** UNCERTAIN
---

## SUMMARY

- Verdicts: 12 CONFIRMED, 4 DISPROVED, 4 UNCERTAIN (20/20 judged).
- Bugs disproved: BUG-01 (10 pts), BUG-03 (10 pts), BUG-11 (1 pt), BUG-17 (1 pt) — 22 points claimed.
- Bugs accepted as real: BUG-02, BUG-04, BUG-05, BUG-06, BUG-07, BUG-08, BUG-09, BUG-10, BUG-13, BUG-14, BUG-16, BUG-18.
- Uncertain (insufficient verification within budget — referee should weigh evidence, not treat as confirmed): BUG-12, BUG-15, BUG-19, BUG-20.
- Mechanism corrections on accepted findings: BUG-02 (shared-.tmp lost-update, not .bak resurrection), BUG-05 (lost admission / lost update, not persisted duplicates).
- Skeptic score per prompt scoring: +22 if all four disproofs are correct; −(2×22) if all four are wrong.

**ACCEPTED BUG LIST (with original severity):** BUG-02 (Medium), BUG-04 (Medium), BUG-05 (Medium), BUG-06 (Medium), BUG-07 (Medium), BUG-08 (Critical, tempered by dead-code status), BUG-09 (Medium), BUG-10 (Medium), BUG-13 (Medium), BUG-14 (Medium), BUG-16 (Low), BUG-18 (Medium)

TOTAL CONFIRMED: 12
TOTAL DISPROVED: 4
