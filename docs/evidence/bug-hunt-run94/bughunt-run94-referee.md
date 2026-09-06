# Bug-hunt run94 — REFEREE report (final verdicts)

Scope: 15 files, Void Scriptor persistence/session layer (D:\VoidScriptor\void_scriptor_multiplatform, master, working tree as-is; HEAD 074c5a1).
Method: every finding re-verified against the code I read myself. Cross-file contracts read in full: project_recovery_service.dart, project_registry_service.dart, project_paths.dart, project_session_manager.dart, project_mutation_runtime.dart, command_type_registry.dart, project_package.dart, project_recovery_services.dart (lock/backup), custom_storage_location.dart, project_database_service.dart, project_move_service.dart, project_health_service.dart, project_manifest_service.dart, project_persistence_providers.dart, project_local_data_source.dart, project_repository_impl.dart, storage_location_registry_resolver.dart. Caller searches run lib-wide (probeWrite, movePackage, recoverInterruptedMoves, setActiveLocation/relinkLocation/bindProject, lockFile/sessionFile, asset.* literals, CommandTypes.* references). Working-tree diff of project_session_manager.dart inspected. Git history (`git log -S`) checked for asset.rename producers.

---

**BUG-01** — movePackage destination clobber (Hunter: Critical)
- **Hunter's claim:** movePackage derives destination from basename and never checks existence; concurrent same-name moves or a pre-existing destination silently replace a complete package (POSIX rename replaces wholesale).
- **Skeptic's response:** DISPROVED — POSIX rename onto a non-empty directory fails (ENOTEMPTY); Windows Directory.rename fails on any existing destination; the FileSystemException is caught (line 50), marker consumed, rethrown. Also no production callers.
- **Your analysis:** The Skeptic is right on rename semantics. On Windows (the canonical target) `Directory.rename` cannot replace an existing directory at all; on POSIX it fails with ENOTEMPTY for a non-empty package. The only replaceable case is an empty pre-existing directory, which destroys no project data. The failure path is `on FileSystemException { marker.delete(); rethrow; }` (project_move_service.dart:48-60), so the error surfaces exactly as the docstring's "rename failed → error surfaces to the caller" contract states. Caller search confirms movePackage has no production callers (doc references only). The claimed silent destruction cannot occur.
- **VERDICT: NOT A BUG** | Confidence: High
---

**BUG-02** — atomicWrite unsynchronized concurrent writers (Hunter: Medium, ".bak resurrection")
- **Hunter's claim:** failure rollback can resurrect the stale .bak over a concurrently completed write; no lock around delete-bak → rename-target→bak → rename-tmp→target.
- **Skeptic's response:** CONFIRMED with corrected mechanism — .bak resurrection is mostly guarded (`!await target.exists()` check), but the shared `.tmp` name + zero serialization produces lost updates and spurious failures.
- **Your analysis:** The corrected mechanism is what the code proves. project_recovery_service.dart:103 uses one shared temp path per target (`'${target.path}.tmp'`) and there is no mutex/lock/retry anywhere in atomicWrite (98-120). I walked the interleavings: literal .bak-over-live-target resurrection is indeed guarded, but with two concurrent writers (a) the loser's `temporary.rename(target.path)` fails because the winner consumed the shared .tmp, so the loser throws despite the operation being arguably fine; (b) a loser's rollback can fire inside the winner's target→.bak window (target momentarily absent), installing stale content transiently; (c) combined with the registry's read-modify-write callers (load/upsert/remove, all unsynchronized) this yields durable lost updates. Concurrent registry operations are reachable from a single isolate (await-point interleaving of a projects-list refresh and a create/update/delete flow) and worse across processes. This is a code-proven unlocked shared mutation on the registry/manifest durability path — the method's entire purpose is crash-safe writing, and it is not concurrency-safe.
- **VERDICT: REAL BUG** | Confidence: Medium (concurrency-dependent; mechanism code-proven) | **True severity: Medium**
- **Suggested fix:** Serialize writes per target (async mutex/lock-file around atomicWrite, or unique tmp names + validated retry), and better: serialize all registry read-modify-write operations behind one queue.
---

**BUG-03** — recoverInterruptedMoves TOCTOU (Hunter: Critical)
- **Hunter's claim:** exists()-probe → rename gap lets two move sessions swap/overwrite whole packages, silently losing a project.
- **Skeptic's response:** DISPROVED — same rename-semantics flaw as BUG-01; failures are skipped (`on FileSystemException { continue; }`), identity checks pin each journal to one package; no production callers.
- **Your analysis:** Confirmed by reading project_recovery_service.dart:182-203. The probe→rename window exists, but every failure mode lands in `continue`: Windows rename fails on any existing destination, POSIX on non-empty; a second scanner whose source vanished gets PathNotFound → FileSystemException → continue. `matchesSource`/`matchesDestination` (182-187) bind each journal to exactly one package. No code path in the method deletes or overwrites package content. Dead code (no production callers), matching the Hunter's own note. The claimed data loss is impossible under actual rename semantics.
- **VERDICT: NOT A BUG** | Confidence: High
---

**BUG-04** — _decodeProjects raw throws; remove()/listing abort on corruption (Hunter: Medium)
- **Hunter's claim:** jsonDecode casts and schema-version check throw raw FormatException/TypeError on a malformed projects.json; remove() composes on load(), so a transient/corrupt decode aborts deletes and listing, diverging registry from disk.
- **Skeptic's response:** CONFIRMED (one overstatement removed: a rename-based replace cannot be observed truncated by a reader).
- **Your analysis:** Code as claimed (project_registry_service.dart:66-80): `as Map<String, dynamic>` throws TypeError for a JSON array; `schemaVersion != 1` throws raw FormatException; one corrupt entry throws TypeError. None are classified, while sibling services define typed exceptions (ProjectManifestUnreadableException). Worse, recoverIfInterrupted only restores a *missing* target — corrupt content never falls back to the .bak that atomicWrite deliberately keeps — so a single corrupt entry bricks getProjects() permanently for that user, and remove() (123-125) aborts, leaving registry/disk divergence. The "racing the atomic-replace" sub-claim is invalid (rename is atomic), but the corrupt-content path stands on its own and is the registry — the only project discovery mechanism.
- **VERDICT: REAL BUG** | Confidence: High | **True severity: Medium**
- **Suggested fix:** Wrap decode in a typed exception, fall back to .bak (then rename aside the corrupt file for inspection) on decode failure, and let remove() tolerate/repair a failed decode.
---

**BUG-05** — crash-window admission not serialized (Hunter: Medium, "duplicate entries")
- **Hunter's claim:** concurrent load()s both admit the same package and persist duplicates.
- **Skeptic's response:** CONFIRMED with corrected mechanism — each save list is internally deduped, but the unsynchronized sequence yields last-writer-wins *lost admission*: load#2 decoding the pre-save list overwrites load#1's save while load#1 already consumed the marker, so the admitted project becomes permanently invisible.
- **Your analysis:** The corrected mechanism is verified by the code: load() (project_registry_service.dart:28-63) does decode → admit → save → consume markers with no synchronization; consumeCreationMarker deletes unconditionally (project_recovery_service.dart:85-87). The lost-admission interleaving requires the crash-window state (a creation marker) plus two concurrent loads admitting different projects, or a concurrent upsert/remove clobbering an admission save — the same unsynchronized read-modify-write family as BUG-02. Consequence is the exact failure the admission logic exists to prevent ("a complete project never becomes invisible"). Narrow trigger, durable consequence.
- **VERDICT: REAL BUG** | Confidence: Medium (concurrency-dependent) | **True severity: Medium**
- **Suggested fix:** Serialize registry mutations (single async mutex around load/upsert/remove/save) so admit→save→consume is atomic per registry.
---

**BUG-06** — recoverIfInterrupted consumes .bak on legitimately missing target (Hunter: Medium)
- **Hunter's claim:** unconditional .bak→target rename resurrects files deleted for non-crash reasons and destroys the only restore copy.
- **Skeptic's response:** CONFIRMED — atomicWrite never deletes .bak on success, so .bak coexisting with a deliberately deleted target is steady-state.
- **Your analysis:** The mechanics are real (project_recovery_service.dart:131-137; .bak retained after success at 106-119), but the harmful scenario requires a flow that deletes projects.json or manifest/project.json while leaving the .bak — and no such flow exists anywhere in lib/ (remove() rewrites rather than deletes; package deletion removes the whole directory including its .bak; restoreBackup immediately reinstalls). For every state the current code can actually produce, "missing target + .bak present" is precisely the documented crash window, and restoring last durable content is the designed behavior (docstring 122-130). This is a latent design tradeoff, not a demonstrable defect in any reachable path.
- **VERDICT: NOT A BUG** | Confidence: Medium | (If a future flow ever deletes these targets in place, revisit: gate recovery on a crash-tombstone written before target→.bak.)
---

**BUG-07** — probeWrite commits probe table before cleanup; dead code (Hunter: Medium)
- **Hunter's claim:** COMMIT of the probe write precedes the cleanup transaction, so a crash between them leaves `__scriptor_write_probe` in the user's database despite the "TIDAK memodifikasi data aplikasi" contract; no callers.
- **Skeptic's response:** CONFIRMED.
- **Your analysis:** Verified (project_database_service.dart:182-226): CREATE+INSERT+`COMMIT` (201) then a separate cleanup transaction and `DROP TABLE` (205); the doc comment (175-181) still describes a ROLLBACK design the implementation abandoned, and the code comment itself admits "rollback tidak berguna di sini". A kill between COMMIT and DROP permanently leaves a probe table in the project database — a contract violation, though the residue is an empty table, not app data. Caller search confirms zero production callers. Real but minor.
- **VERDICT: REAL BUG** | Confidence: High | **True severity: Low** (downgraded: dead code, cosmetic residue)
- **Suggested fix:** Delete probeWrite, or do the probe in a single savepoint/transaction and drop the table in the same transaction; fix the stale doc comment.
---

**BUG-08** — probeWrite deletes -wal/-shm unconditionally (Hunter: Critical)
- **Hunter's claim:** after closing its own connection it deletes the WAL/SHM sidecars; with another live WAL connection this discards committed-but-uncheckpointed transactions — data loss on the production open path.
- **Skeptic's response:** CONFIRMED, severity tempered by dead-code status.
- **Your analysis:** Verified (project_database_service.dart:227-237): both sidecars are deleted unconditionally with only FileSystemException swallowed. The mechanism is the textbook SQLite data-loss footgun: with a concurrent live connection in WAL mode, deleting -wal destroys acknowledged transactions. In the single-connection case the clean close + `wal_checkpoint(TRUNCATE)` normally leaves no sidecars, so the catastrophic case is precisely "another connection is open" — i.e., whenever the probe is used against a live session database. However, probeWrite has no production callers (verified), so "direct data-loss path on the production open path" overstates reachability. Latent, but any future caller on an open session causes data loss; the code as written is a loaded gun.
- **VERDICT: REAL BUG** | Confidence: High (mechanism) | **True severity: Medium** (downgraded from Critical: dead code; catastrophic if ever wired)
- **Suggested fix:** Remove the sidecar deletion entirely (a closed, checkpointed WAL is reclaimed by SQLite), or only reclaim after proving exclusive access.
---

**BUG-09** — Process.runSync blocks the calling isolate (Hunter: Medium)
- **Hunter's claim:** async-signatured freeBytes shells out synchronously to PowerShell, freezing the isolate for hundreds of ms to seconds on every default probe.
- **Skeptic's response:** CONFIRMED.
- **Your analysis:** Verified (custom_storage_location.dart:139-158): `Future<int> freeBytes(String location) async` calls `Process.runSync('powershell.exe', ...)`. Unlike BUG-02/05 this needs no race to prove — the synchronous spawn is in the code by construction. Every default probe (probe → _Probe → DefaultStorageProbe → PlatformDriveSpaceReader) hits it; PowerShell cold start is routinely 200-1000 ms. The callers today are setActiveLocation/relinkLocation (no lib/ production callers yet — the settings surface is not wired), but the API is the designated probe path and freezes the UI isolate deterministically whenever used.
- **VERDICT: REAL BUG** | Confidence: High | **True severity: Medium**
- **Suggested fix:** Use `Process.run` (the method is already async); consider caching per-drive results.
---

**BUG-10** — normalizeLocation accepts relative paths → CWD-anchored storage (Hunter: Medium)
- **Hunter's claim:** no absolute-path requirement, so a relative input is probed, created, and persisted CWD-relative; ProjectPaths.root() later resolves it against whatever the CWD is.
- **Skeptic's response:** CONFIRMED.
- **Your analysis:** Verified (custom_storage_location.dart:49-62: only trim + p.normalize; 278-303: exists/create/probe/persist on the unanchored string; project_paths.dart:50-53 re-resolves `Directory(active)` at read time). A relative activeLocation makes the project home depend on the process CWD — projects silently land elsewhere than the user chose. The defect is one missing validation on a public API explicitly built for user-entered paths. Today no lib/ code calls setActiveLocation/relinkLocation (verified), so it is not yet reachable in production — hence the downgrade.
- **VERDICT: REAL BUG** | Confidence: High | **True severity: Low** (downgraded: no production caller yet; deterministic mislocation once wired)
- **Suggested fix:** Reject non-absolute input in normalizeLocation (`p.isAbsolute`), and store the absolute resolved path.
---

**BUG-11** — drive-letter extraction mishandles UNC / forward-slash roots (Hunter: Low)
- **Hunter's claim:** UNC roots yield the whole `\\server\share` (fails length guard) and forward-slash roots keep the trailing slash, so valid network storage never reports free space.
- **Skeptic's response:** DISPROVED — returning -1 for unqueryable roots is the documented unknown-budget signal mapped to a conservative 1 GiB standing offer; both store paths normalize separators first.
- **Your analysis:** The Skeptic is right. The interface contract (custom_storage_location.dart:124-126) defines -1 as the designed unknown-budget signal, and _Probe.checkWith maps it to the conservative standing offer (213) — a network share simply doesn't get free-space reporting, which is the documented fallback, not wrong reporting. The forward-slash case is neutralized because both setActiveLocation and relinkLocation normalize first (p.normalize on Windows converts separators), and load() re-normalizes on read. No incorrect value is ever produced.
- **VERDICT: NOT A BUG** | Confidence: High
---

**BUG-12** — registry()/scan directory mismatch in default wiring (Hunter: Medium; Skeptic: UNCERTAIN)
- **Hunter's claim:** registry() places projects.json at root().parent while admission scans root() and stash recovery scans another set — "admission scans a directory that contains no packages in the default wiring".
- **Skeptic's response:** UNCERTAIN — internal claim contradicted (paths.root() IS the package directory); production construction sites unverified within budget.
- **Your analysis:** Resolved on my own evidence. The production construction site is project_persistence_providers.dart:34-36 — `ProjectRegistryService(paths: projectPathsProvider)`; no lib/ code constructs the rootDirectory variant. In that wiring: `_listingOwnerDirectory()` returns `paths.root()` (registry_service:84), and ProjectPaths.project() places packages at `root()/<id>.voidproject` (project_paths.dart:104-105) — admission scans exactly the package directory. The paths-branch of _recoverImportStashes scans the same `paths.root()` (152-154). The registry *file* at root().parent (132-137) is deliberate and documented ("Host file next to the effective root... beside the default Projects folder", rootDirectoryFile docstring 107-109) and is not a scan directory. The claimed default-wiring breakage is false; the residual two-dir scan exists only in the file-wired branch and is BUG-16's finding.
- **VERDICT: NOT A BUG** | Confidence: High
---

**BUG-13** — `code == 778` unreachable after `& 0xFF` mask (Hunter: Medium)
- **Hunter's claim:** the extended result code is masked to the primary code, then compared to 778 — unreachable, so SQLITE_IOERR_WRITE is misreported as corruption.
- **Skeptic's response:** CONFIRMED (arithmetically certain).
- **Your analysis:** Verified: project_database_service.dart:144 `final code = error.extendedResultCode & 0xFF;` → 778 (0x30A) & 0xFF = 10; line 157 `if (code == 8 || code == 13 || code == 778)` can never match 778. SQLITE_IOERR_WRITE therefore falls through every branch to `ProjectDatabaseUnreadableException` (165) — reported as corruption on the production open() path, exactly the misclassification the 145.42 matrix and the exception's own doc ("778 = SQLITE_IOERR_WRITE", line 105) were built to prevent. The same fall-through silently swallows every other IOERR extension (266/522/1034...) into "corruption". Arithmetic-certain, on the live open path.
- **VERDICT: REAL BUG** | Confidence: High | **True severity: Medium**
- **Suggested fix:** Classify on the unmasked extended code for IOERR (e.g. `(error.extendedResultCode == 778 || code == 10)` → WriteFailed, since primary 10 is IOERR), keeping 8/13 on the masked comparison.
---

**BUG-14** — manifest restored from .bak never re-validated/rewritten; .bak consumed (Hunter: Medium)
- **Hunter's claim:** after restoreBackup succeeds, the restored content is never re-validated-and-rewritten as canonical, stays "flagged", and the consumed .bak leaves no backup for a subsequent failure.
- **Skeptic's response:** CONFIRMED (no-rewrite + consumed .bak real; "stays flagged" loosely worded).
- **Your analysis:** The factual core is smaller than claimed. The restored content IS re-validated — `return _parse(file)` (project_manifest_service.dart:59) throws if the .bak content is itself unusable. The .bak consumption is inherent to restore-by-rename and is presented as deliberate design in the code comment (54-56: restore last durable content; without .bak, keep the corrupt file for inspection). The "no fresh .bak" window is short: the next manifest save goes through atomicWrite, which recreates the .bak — and session save writes the manifest routinely. A valid .bak restores a valid manifest; nothing "stays flagged". This is a hardening nicety (copy-then-restore, or rewrite-after-restore), not a correctness defect in any reachable flow.
- **VERDICT: NOT A BUG** | Confidence: Medium
---

**BUG-15** — relinkLocation accepts any containing directory, no migration (Hunter: Medium; Skeptic: UNCERTAIN)
- **Hunter's claim:** relink repoints storage at any directory containing the bound project (or any writable dir when unbound); old-location projects become invisible with no migration/rollback; stale activeLocation turns root() into the fallback root.
- **Skeptic's response:** UNCERTAIN — code behavior as quoted, but whether this violates the intended contract of "relink" was unverifiable in budget.
- **Your analysis:** Weighed on the code: relink's contract is "repoint the storage home at a (moved) location". The bound-project containment check (custom_storage_location.dart:319-326) is precisely the designed guard against pointing at an arbitrary directory, and probe+writability is checked. When the user genuinely moved the storage folder, all packages moved with it and the check suffices; when they point at a partial copy, old-location packages remain on disk (nothing is deleted) and are recoverable by relinking back — discoverability follows the storage root by construction in this architecture. The "stale activeLocation → fallback root" behavior is ProjectPaths.root()'s documented pre-existing fallback (project_paths.dart:46-61, rootOverride docstring), driven by _read()'s missingDrive status — not something relink introduces. Repointing semantics, reversible, guarded, no data loss: a product decision, not a bug. (One noteworthy oddity found while checking: registry() writes projects.json at the *parent* of a nested custom location while rootDirectoryFile writes inside it — inconsistent but functional, and not part of this claim.)
- **VERDICT: NOT A BUG** | Confidence: Medium
---

**BUG-16** — rootDirectory wiring: admission scans one directory, stash recovery two (Hunter: Low)
- **Hunter's claim:** in the rootDirectory configuration the registry file is `<root>/projects.json`, admission scans `<root>` only, while stash recovery scans `<root>` and `<root>/Projects` — inconsistent directory notions in one service.
- **Skeptic's response:** CONFIRMED.
- **Your analysis:** Verified at all cited lines: constructor (11-14), `_listingOwnerDirectory` (82-88), `_recoverImportStashes` file-branch (162-171). A creation-marked package under `<rootDirectory>/Projects` would be found by stash recovery but never admitted — a genuine internal inconsistency implying the author believes packages can live one level down in this wiring. Production wiring is the paths variant (consistent), so impact is confined to the rootDirectory configuration (tests/legacy layouts). Low is the right severity.
- **VERDICT: REAL BUG** | Confidence: High | **True severity: Low**
- **Suggested fix:** Make admission and stash recovery iterate the same directory set (share one `_ownerDirectories()` helper).
---

**BUG-17** — health check: close() throw escapes the on-Object block (Hunter: Low)
- **Hunter's claim:** if opened.close() throws, the exception escapes the `on Object` block (which "only wraps the open").
- **Skeptic's response:** DISPROVED — both open and close are inside the same try; the handler wraps both.
- **Your analysis:** The Skeptic is factually right: project_health_service.dart:58-64 has `open` and `close` in one try block with `on Object { databaseReadable = false; }` — a close() throw is caught, nothing escapes. The residual observation (a full read-write drift open, including metadata writes/migration, on every health check) is the designed meaning of "health = can we actually open it", a cost/design choice rather than the claimed exception-escape defect.
- **VERDICT: NOT A BUG** | Confidence: High
---

**BUG-18** — open-failure catch deletes the live owner's .project.lock (Hunter: Medium)
- **Hunter's claim:** the catch deletes package.lockFile whenever mode == readWrite, even when this session never wrote it (companionWritten == false), erasing the live owner's companion file.
- **Skeptic's response:** CONFIRMED.
- **Your analysis:** Verified end-to-end, including the working-tree diff: `companionWritten` (line 146) is set true only after this session's own write (157) but is never consulted in the catch (285-290). A second session whose `lock.acquire()` throws `StateError('Project has an active or stale session')` (project_recovery_services.dart:30) against an alive owner reaches the catch, `lock.release()` no-ops (`_ownedSessionId == null`), and `package.lockFile` — the owner's `.project.lock` — is deleted. The guard variable exists and is simply unused. Impact is bounded today: nothing in lib/ *reads* .project.lock (grep: written/deleted only), and the real ownership guard is session.lock, which release() verifies by sessionId — so no functional breakage in current code. The deletion is nonetheless wrong by construction and becomes harmful the moment any consumer trusts the companion.
- **VERDICT: REAL BUG** | Confidence: High | **True severity: Low** (downgraded: no in-scope reader of the companion; ownership state intact)
- **Suggested fix:** Gate the delete on `companionWritten` in the catch (`if (mode == readWrite && companionWritten && await package.lockFile.exists())`).
---

**BUG-19** — asset.rename/asset.delete unregistered → filtered from history restore (Hunter: Medium; Skeptic: UNCERTAIN)
- **Hunter's claim:** the session registry registers six command types while CommandTypes also defines asset.rename/asset.delete; unregistered history records are silently dropped by whereType<AppCommand>() during restore.
- **Skeptic's response:** UNCERTAIN — filtering mechanism verified; no producer of such records could be confirmed before budget.
- **Your analysis:** I closed the producer question. (1) Literal search: `asset.rename`/`asset.delete` occur only in command_type_registry.dart:7,10. (2) Constant references: `CommandTypes.renameAsset`/`deleteAsset` (and indeed any `CommandTypes.*`) are referenced nowhere outside their definitions. (3) History records are only ever written in ProjectMutationRuntime._persist with `commandType: command.commandType` — i.e., the type of an AppCommand that went through the bus; no AppCommand class with those type strings exists in lib/. (4) `git log -S 'asset.rename' --all` shows exactly one commit (ec94180, the feature commit that introduced the constants); no producer ever shipped. With zero possible producers, the silent-drop path can never trigger on real data. The constants are dead vocabulary (defensive placeholders), and the six registered factories match the six command classes that exist. The mechanism would matter only if a future asset command is persisted without registering a factory — a hazard to note, not a current bug.
- **VERDICT: NOT A BUG** | Confidence: High
---

**BUG-20** — partially-wired open: swallowed close, undisposed runtime (Hunter: Medium; Skeptic: UNCERTAIN)
- **Hunter's claim:** on failure after databaseService.open, the catch closes the DB inside a swallowing try/catch (handle leak if close throws), and WorkspaceProjectionCache/repositories hold live drift queries leaving the runtime partially wired; mutationRuntime is never disposed.
- **Skeptic's response:** UNCERTAIN — visible hygiene gaps real; the concrete leak mechanism unproven.
- **Your analysis:** Weighed on the code. (a) The `try { if (database != null) await database.close(); } catch (_) {} rethrow;` pattern is deliberate best-effort cleanup that preserves the original error — the standard alternative (letting close() mask the open error) is worse, and a "drift close failure still leaks the handle" claim is a runtime-only assertion with no evidence, which per the honesty rule cannot stand as a bug. (b) The undisposed-runtime scenario requires a throw *after* `ProjectMutationRuntime.open` — but everything after it (line 247) is synchronous plain construction: NovelCharacterLinkRepository, WorkspaceProjectionCache (a closure), ProjectSession (field assignment only) — no realistic throw path; and even the narrow window inside runtime.open itself (historyRepository.list throwing) would leak only one unclosed StreamController + ValueNotifier, transient and GC-eligible, with database.close() still reached by the catch. No reachable path produces the claimed leak.
- **VERDICT: NOT A BUG** | Confidence: Medium
---

## VERIFIED BUG REPORT

**Stats:**
- Total reported by Hunter: 20
- Dismissed as false positives: 10 (BUG-01, 03, 06, 11, 12, 14, 15, 17, 19, 20)
- Confirmed as real bugs: 10
- Critical: 0 | Medium: 6 | Low: 4

**Confirmed bugs (ordered by severity):**

| # | Severity | File | Line(s) | Description | Suggested Fix |
|---|----------|------|---------|-------------|---------------|
| BUG-08 | Medium | lib/database/project/project_database_service.dart | 227-237 | probeWrite deletes live -wal/-shm sidecars unconditionally; with a concurrent WAL connection this discards committed transactions (dead code today, catastrophic if wired) | Remove the sidecar deletion; never reclaim WAL files of a possibly-open database |
| BUG-13 | Medium | lib/database/project/project_database_service.dart | 144, 157-165 | `code == 778` unreachable after `& 0xFF` mask (778&0xFF=10): SQLITE_IOERR_WRITE misreported as corruption (Unreadable) on the production open path | Classify IOERR on the unmasked extended code (778, or primary 10 → WriteFailed) |
| BUG-02 | Medium | lib/core/persistence/project_recovery_service.dart | 98-120 | atomicWrite uses a shared `.tmp` name with zero serialization: concurrent writers on one target produce spurious failures and, with the registry's unsynchronized read-modify-write, durable lost updates | Serialize writes per target (mutex/lock-file or unique tmp names + retry); single-writer discipline at registry level |
| BUG-05 | Medium | lib/core/persistence/project_registry_service.dart | 28-63 | load()'s admit→save→consume-marker sequence is unsynchronized; last-writer-wins can permanently lose an admitted project (marker already consumed) | Async mutex around registry load/upsert/remove so admission is atomic |
| BUG-04 | Medium | lib/core/persistence/project_registry_service.dart | 66-80, 123-125 | Corrupt projects.json throws raw FormatException/TypeError, permanently bricking listing; remove() aborts → registry/disk divergence; no .bak fallback on decode failure | Typed decode errors + .bak fallback with corrupt-file quarantine; make remove() tolerate decode failure |
| BUG-09 | Medium | lib/core/persistence/custom_storage_location.dart | 139-158 | `Process.runSync('powershell.exe', ...)` inside an async API freezes the calling (UI) isolate for hundreds of ms on every default storage probe | Use Process.run; cache per-drive results |
| BUG-07 | Low | lib/database/project/project_database_service.dart | 182-226 | probeWrite COMMITs a probe table before cleanup: crash between COMMIT and DROP leaves `__scriptor_write_probe` in the user's DB, violating the stated no-modification contract (dead code; stale ROLLBACK doc) | Drop the method or make probe+cleanup one transaction; fix doc |
| BUG-10 | Low | lib/core/persistence/custom_storage_location.dart | 49-62, 278-303 | normalizeLocation accepts relative paths: storage is probed/created/persisted CWD-relative, and ProjectPaths.root() re-resolves it against a changing CWD (no production caller yet) | Reject non-absolute input (`p.isAbsolute`); persist absolute paths |
| BUG-16 | Low | lib/core/persistence/project_registry_service.dart | 11-14, 46-49, 82-88, 162-171 | rootDirectory wiring: admission scans `<root>` but stash recovery also scans `<root>/Projects` — creation markers in the legacy subdir are never admitted | Share one owner-directory set between admission and stash recovery |
| BUG-18 | Low | lib/features/project_resilience/application/project_session_manager.dart | 285-290 | Catch deletes `package.lockFile` without checking `companionWritten`, so a rejected second session erases the live owner's `.project.lock` (no in-scope reader today) | Gate the delete on `companionWritten` |

**Low-confidence items (flagged for manual review):**
- BUG-02 (Medium confidence — concurrency structure code-proven; runtime frequency unproven)
- BUG-05 (Medium confidence — requires crash-window state plus concurrent registry operations)
- BUG-06 (NOT A BUG at Medium confidence — latent tradeoff; revisit if any flow ever deletes the registry/manifest targets in place)
- BUG-14 (NOT A BUG at Medium confidence — one-shot restore is deliberate and self-heals on next save)
- BUG-15 (NOT A BUG at Medium confidence — relink semantics judged a product decision; registry-at-parent inconsistency noted for the team)
- BUG-20 (NOT A BUG at Medium confidence — leak claims are runtime-only speculation per the honesty rule)

**TOTAL REAL BUGS: 10**
**TOTAL NOT A BUG: 10**
