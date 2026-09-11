# Bug-hunt run197 — Referee verdict report

Repo: D:\VoidScriptor\void_scriptor_multiplatform · HEAD b5d8bba (verified unchanged) · read-only review.
Method: every one of the 26 findings re-derived from the actual code — all 18 in-scope files read in full,
plus trace files (project_recovery_services.dart, project_move_service.dart, project_mutation_runtime.dart,
project_persistence_providers.dart, project_controller.dart, project_local_data_source.dart,
project_repository_impl.dart, project_package_service.dart, main.dart, ci.yml) and the sqlite3-3.5.1
package source in the pub cache to settle the extended-result-code question for BUG-11. Callers,
zero-consumer claims and wiring re-verified with repo-wide grep. No builds/tests, no network, no edits
(this report is the only file written).

Static-analysis honesty rule applied: concurrency/runtime-only claims without code-provable triggers were
downgraded to Low (BUG-4, BUG-9, BUG-10, BUG-11) or dismissed (BUG-24).

---

**BUG-1**
- **Hunter's claim:** `upsert()` consumes the creation marker with an unguarded `marker.delete()` after the registry save is durable; a transient errno-32 propagates into `ProjectController.createProject`'s catch, which deletes the entire fully-created package — permanent loss of a complete project plus a dangling registry entry.
- **Skeptic's response:** ACCEPT (95%). Chain verified at all three links; the same unguarded pattern exists in `_loadUnlocked` 79–85.
- **Your analysis:** Independently verified the full chain. `project_registry_service.dart:197–206` — `_saveUnlocked(projects)` completes (registration durable), then `await _recovery.consumeCreationMarker(...)` runs with no try/catch; `project_recovery_service.dart:130–132` is a bare `if (await marker.exists()) await marker.delete();`. The repo itself documents this exact failure class as real and field-observed (errno 32 on freshly-written files, `durable_draft_journal.dart:82–91`, retry ladders built elsewhere) while this delete has neither guard nor retry — contrast `_consumeQuietly` (recovery 134–141) and `_consumeLandedMoveMarkers` (registry 225–229, `on FileSystemException { continue; }`). Caller chain re-traced: `registry.upsert` ← `ProjectLocalDataSource.createProject` (24–27) ← `ProjectRepositoryImpl.createProject` (18–19) ← `ProjectController.createProject` (project_controller.dart:50), whose catch (53–58) does `await createdRoot.delete(recursive: true)` on ANY error. Result: complete package destroyed, registry entry left pointing at it. The identical unguarded delete in `_loadUnlocked` (79–85) additionally turns a transient delete failure into a thrown project listing (non-destructive but wrong). The marker is written flush:true during `create()` and consumed milliseconds later in `upsert()` — precisely the fresh-file AV/indexer window the codebase documents.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Critical (confirmed)
- **Suggested fix:** Consume the creation marker best-effort: wrap both call sites (upsert 202–206, _loadUnlocked 79–85) in `on FileSystemException { /* marker retried by next load; membership already durable */ }`, or route through `_consumeQuietly`/`_deleteWithTransientRetry`. A stale marker is harmless — `admitMarkedCreations` treats known ids as registered.

---

**BUG-2**
- **Hunter's claim:** `open()` re-checks existence synchronously after the async schema probe; a delete race or I/O-swallowing `existsSync()` misreports unavailable storage as `ProjectDatabaseUnreadableException` (corruption), plus sync I/O on the UI isolate.
- **Skeptic's response:** DISPROVED (82%) — the quoted branch throws `ProjectDatabaseUnavailableException`, the correct non-corruption class.
- **Your analysis:** Read the branch myself (`project_database_service.dart:162–188`). Every outcome of the `existsSync() == false` path — including the delete race and an I/O error swallowed into `false` — throws `ProjectDatabaseUnavailableException`, whose own doc says "storage ... tidak lagi terjangkau ... bukan klasifikasi korup". The Hunter's claimed misclassification is the one outcome this code structurally cannot produce. The corruption class is only reachable from `classifyProjectDatabaseOpenError` on a real `SqliteException` from the open itself. The sync-`stat` prong is negligible (one stat on an already-probed path) and no async-only contract exists in the file.
- **VERDICT: NOT A BUG**
- **Confidence:** High

---

**BUG-3**
- **Hunter's claim:** `addTagToAssets` re-reads tags per asset and does a full delete-and-reinsert, so a duplicated asset id (or overlapping batches) clobbers the first tag write, silently dropping a tag.
- **Skeptic's response:** DISPROVED (72%) — tags are re-read inside the loop; `replaceTags` normalizes through a set; transactions serialize.
- **Your analysis:** Verified in `asset_dao.dart:154–163`. For an id listed twice, iteration 2's `getTags` re-reads the links table after iteration 1's write on the same connection and transaction, so it sees the first tag; `replaceTags(id, [a, t, t])` dedupes via `.toSet()` (113–116) before any write. No stale snapshot exists, so nothing is dropped. Cross-call interleaving would require two concurrent calls; drift serializes top-level transactions on one connection, and the only production caller (`asset_browser_screen.dart:537`) is a single awaited action passing a `Set<String>` (`_selectedAssetIds`) — unique ids by construction. The claimed data loss has no reachable path.
- **VERDICT: NOT A BUG**
- **Confidence:** High

---

**BUG-4**
- **Hunter's claim:** `close()` only sets a flag and returns; an in-flight `stage()` that passed the check re-creates the journal directory and writes an entry after close — a post-close resurrection window.
- **Skeptic's response:** UNCERTAIN-ACCEPT (65%) — mechanism real; recovered artifact is genuine user data; harm limited to a stale post-close write.
- **Your analysis:** Verified: the `_closed` check (durable_draft_journal.dart:56–58) precedes `_dir.create` and all awaited writes; `close()` (195–197) is flag-only with no outstanding-op tracking. The mechanism is real. However: (a) the written entry is a genuine draft the user actually staged, so surfacing it in recovery is the file's no-silent-loss contract working, not false data; (b) the only residual wrongness is `_dir.create(recursive: true)` re-creating an emptied directory after close; and (c) repo-wide grep shows `close()` is never called on any journal in production (`workspace_resolver.dart` constructs journals per story screen; no `.close()` caller exists in lib/), so the window is currently unexercised. Real API-contract defect, latent impact.
- **VERDICT: REAL BUG**
- **Confidence:** Medium
- **True severity:** Low (downgraded from Medium — no production caller of `close()`; artifact is genuine data, not corruption)
- **Suggested fix:** Track outstanding `stage()` futures and have `close()` await them (or make `stage()` re-check `_closed` after its awaits and abort the rename).

---

**BUG-5**
- **Hunter's claim:** `_close()` runs teardown sequentially with no guarding; a `lock.release()`/`jobs.dispose()` failure aborts before `database.close()` (leaking the connection), skips the lock-file delete, and the memoized close future never retries.
- **Skeptic's response:** ACCEPT (90%).
- **Your analysis:** Verified `project_session_manager.dart:112–128`: `mutationRuntime.dispose()` → transient cancel loop → `jobs.dispose()` → `database.close()` → `lock.release()` → lock-file delete, no try/finally anywhere. `close() => _closing ??= _close()` (110) memoizes the FAILED future, so remaining steps never re-run. `lock.release()` genuinely throws after 5 exhausted errno-32 retries by documented fail-closed design (project_recovery_services.dart:122–142). Consequences: a `release()` failure leaves the session marker on disk with a live owner PID, so `_recoverDeadOwnerMarker` refuses recovery and the project cannot be reopened in this process lifetime (StateError 'Project has an active or stale session'); a failure above `database.close()` leaks the SQLite connection. Trigger class is field-documented in this repo.
- **VERDICT: REAL BUG**
- **Confidence:** High (mechanism; trigger is the documented errno-32 class)
- **True severity:** Medium (confirmed)
- **Suggested fix:** Wrap teardown in per-step best-effort guards (try/catch each step, collect errors), always attempt `database.close()` and `lock.release()`; on `close()` failure, clear `_closing` so a retry can re-run remaining steps.

---

**BUG-6**
- **Hunter's claim:** `open()`'s catch releases the lock and deletes the companion before the guarded DB close with no per-step guarding; a `lock.release()` throw skips `database.close()` and replaces the original error.
- **Skeptic's response:** ACCEPT (90%).
- **Your analysis:** Verified `project_session_manager.dart:319–331`: inside the catch, `await lock.release()` (320) and the unguarded `await package.lockFile.delete()` (324) both precede the guarded close (326–329). A throw from either jumps straight past the "Ensure database is closed if it was partially opened" block — the comment is unreachable in exactly the failure case it exists for — and the release/delete error replaces the real open error. On the `ProjectLockedException` path this additionally leaves the session marker behind, blocking the immediate prompt-and-retry the flow expects. The fresh-file delete window is the same documented errno-32 class as BUG-1.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium (confirmed)
- **Suggested fix:** Guard each cleanup step in its own try/catch, run the DB close first (or in `whenComplete`), and rethrow the ORIGINAL error with cleanup failures attached/suppressed as best-effort.

---

**BUG-7**
- **Hunter's claim:** `recoverInterruptedMoves` has zero production callers; `_loadUnlocked` consumes landed move markers but never rolls forward, so a package killed inside the rename crash window stays stranded at the source, invisible, contradicting the documented recovery contract.
- **Skeptic's response:** ACCEPT (90%).
- **Your analysis:** Facts verified: repo-wide grep finds `recoverInterruptedMoves` only at its definition (project_recovery_service.dart:213) and in test `project_move_recovery_test.dart`; `_loadUnlocked` (registry 50–87) calls `recoverIfInterrupted`, `_recoverImportStashes`, `_decodeProjectsWithBackupRecovery`, `_consumeLandedMoveMarkers`, `admitMarkedCreations` — none of which acts on a source-stranded `move-pending.marker` (a stranded package is unregistered, so `_consumeLandedMoveMarkers` never sees it; `admitMarkedCreations` requires a creation marker it doesn't have). The contract at project_move_service.dart:17–18 explicitly promises roll-forward. However, severity must reflect reachability: `ProjectMoveService.movePackage` itself has NO production caller either (definition + tests + doc comments only) — the entire move protocol is dormant, so no stranded package can be produced today. The registry-side landed-marker consumption being wired while the roll-forward half is not is a genuine, test-covered-but-unwired contract gap that becomes user-visible data-invisibility the moment the move feature ships.
- **VERDICT: REAL BUG**
- **Confidence:** High (facts) / Medium (impact timing)
- **True severity:** Low (downgraded from Medium — writer and recoverer are equally dormant; no production trigger today)
- **Suggested fix:** When wiring the move feature into UI, call `recoverInterruptedMoves(root)` from `_loadUnlocked` (before `_consumeLandedMoveMarkers`) in the same change — the two halves must ship together.

---

**BUG-8**
- **Hunter's claim:** `pendingEntries()` catches only `FormatException`, but non-String `sceneId`/`content`/`stagedAt` in valid JSON raise `TypeError`, so one type-corrupt entry aborts the whole recovery listing, breaking the no-silent-loss contract for every scene.
- **Skeptic's response:** ACCEPT (90%).
- **Your analysis:** Verified `durable_draft_journal.dart:131–164`: `decoded['sceneId'] as String?` (134), `decoded['content'] as String?` (135), `decoded['stagedAt'] as String? ?? ''` (150) inside `try { ... } on FormatException`. In Dart an `as` cast failure on a decoded JSON value is a `TypeError`, not a `FormatException`; one such file throws out of the `await for` and `pendingEntries()` never returns, defeating the header contract (lines 15–17: corrupt entries "TIDAK dibuang diam-diam ... di-surface sebagai entri isCorrupt"). The adjacent `acknowledge()` (186–190) correctly uses `on Object`, and `admitMarkedCreations` had the identical bug fixed with `on Object` (project_recovery_service.dart:77–84) — the codebase's own precedent.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Medium (confirmed — recovery-critical surface; one corrupt file blinds the panel for all scenes)
- **Suggested fix:** Widen the catch to `on Object` (matching `acknowledge()`), emitting a `PendingDraftEntry.corrupt` for the offending file and continuing the scan.

---

**BUG-9**
- **Hunter's claim:** `CustomStorageLocationStore`'s read-modify-write flows (`load()` → build state → `_save()`) run without a mutex, so overlapping mutations clobber each other's field — the lost-update class `AsyncMutex`/`ProjectRegistryService` guard against elsewhere.
- **Skeptic's response:** ACCEPT (80%).
- **Your analysis:** Verified: `setActiveLocation` (383–390), `bindProject` (393–402), `relinkLocation` (404–439) each `await load()` then `_save()` a state built from their own stale `current`; the class contains no mutex and `_save` is a plain `atomicWrite`. The mechanism is exactly the lost-update class `ProjectRegistryService` serializes with `AsyncMutex`. However, repo-wide grep shows none of the three mutating methods has any production caller in lib/ (only tests) — the settings UI is not wired — so the race currently has no production trigger; the store's production use today is read-only via `ProjectPaths.root()`.
- **VERDICT: REAL BUG**
- **Confidence:** High (mechanism) / Medium (trigger timing)
- **True severity:** Low (downgraded from Medium — mutating methods have zero production callers today)
- **Suggested fix:** Add an `AsyncMutex` and run all three mutations through `_mutex.run`, mirroring `ProjectRegistryService`.

---

**BUG-10**
- **Hunter's claim:** the "health check" opens the production DB through `ProjectDatabaseService().open()` — running migrations and `initialize()`'s unconditional `project_metadata` upsert — so a diagnostic mutates the project, can report healthy as unreadable under BUSY, and collapses all typed failures into one boolean.
- **Skeptic's response:** ACCEPT (80%).
- **Your analysis:** Verified. `project_health_service.dart:64–72` calls `ProjectDatabaseService().open(database.path)` and flattens every failure with `on Object { databaseReadable = false; }`. `open()` is the full production path: drift `MigrationStrategy` (project_database.dart:353+) runs on first open and `initialize()` (project_database.dart:765–771) executes an `INSERT ... ON CONFLICT(key) DO UPDATE` — a write, every time. A second connection while the app's session holds a write lock can surface BUSY → `databaseReadable=false` for a healthy project (narrow, concurrency-dependent — downgraded per the honesty rule), and Locked/TooNew/Unavailable/WriteFailed all collapse into one boolean despite the typed matrix defined one file over. Note: repo-wide grep shows `ProjectHealthService` has no production caller in lib/ (tests only), further bounding impact.
- **VERDICT: REAL BUG**
- **Confidence:** High (mechanism) / Medium (reachability)
- **True severity:** Low (downgraded from Medium — no production caller today; write side effect real but currently test-only)
- **Suggested fix:** Probe via the read-only seam (`openReadOnly` / `readProjectDatabaseSchemaVersion`) instead of `open()`, and surface the typed failure classes instead of one boolean.

---

**BUG-11**
- **Hunter's claim:** `classifyProjectDatabaseOpenError` compares extended codes with unmasked equality (5/8/13/778/14) and only special-cases primary IOERR, so extended variants (BUSY_SNAPSHOT 517, BUSY_RECOVERY 261, LOCKED_SHAREDCACHE 262) and primary 6 fall through to the corruption classification.
- **Skeptic's response:** UNCERTAIN-ACCEPT (55%) — the run94 framing is wrong, but the 517/262/262 fall-through is a real gap; engine extended-code mode undetermined.
- **Your analysis:** Settled the engine question from package source: sqlite3-3.5.1 enables extended result codes on every opened connection (`lib/src/implementation/sqlite3.dart:95` — `sqlite3_extended_result_codes(1)`) and builds `SqliteException` from `sqlite3_extended_errcode`, so extended variants genuinely surface. Statically verified fall-throughs: 517/261 (`resultCode` 5, `extendedResultCode` 517/261 — no branch matches), 262 (`resultCode` 6 — primary LOCKED is handled nowhere), 264 (READONLY_ROLLBACK), 1034+ IOERR variants — all land on `ProjectDatabaseUnreadableException` (corruption) at line 154. The primary documented families (plain 5, 8, 13, 778, 14, primary-10) do match, and producing 517/262 requires a concurrent second connection (the dormant health service, or external tools) — the session-lock design prevents the app's own writers. Misclassification class is code-proven; the reachable trigger set is runtime-dependent.
- **VERDICT: REAL BUG**
- **Confidence:** Medium
- **True severity:** Low (downgraded from Medium — documented primary codes all classify correctly; variant misclassification needs cross-connection scenarios the app mostly precludes)
- **Suggested fix:** Classify by primary family via `error.resultCode` (`5||6 → Locked`, `8||13 → WriteFailed`, `10 → WriteFailed`, `14 → Unavailable`), keeping the extended code in the exception payload for diagnostics; update the doc block so the run94 "never mask" lesson is stated as "never compare a masked value against an extended code".

---

**BUG-12**
- **Hunter's claim:** `ProjectLockedException` is thrown with the documented promise "caller (UI) should prompt for the passphrase and retry", but nothing in lib/ references the type — locked projects always surface as a generic open failure and the prompt-and-retry flow does not exist.
- **Skeptic's response:** ACCEPT (85%).
- **Your analysis:** Verified: `ProjectLockedException` appears only in `project_session_manager.dart` (definition 41–48, throw 217); `ProjectSessionController._openProject` puts the raw error into `AsyncError` and rethrows (project_persistence_providers.dart:131–134); no catch site exists anywhere in lib/; `project_lock_screen.dart` is not wired to session-open failures. The documented contract is unimplemented. Impact is bounded, though: a working manual unlock path exists (Security Settings screen → `ProjectLockService.unlock`, verified), so this is a missing UX affordance/dead typed contract with a workaround, not a dead end and not data harm.
- **VERDICT: REAL BUG**
- **Confidence:** High (facts)
- **True severity:** Low (downgraded from Medium — manual recovery exists via Security Settings)
- **Suggested fix:** Catch `ProjectLockedException` in the session-open flow and route to the lock/prompt surface with retry, or delete the doc promise if the flow is deliberately deferred.

---

**BUG-13**
- **Hunter's claim:** the read-only branch calls `databaseService.openReadOnly(...)` directly, bypassing `open()`'s classification wrapper, so missing/corrupt/BUSY leaks a raw `SqliteException` instead of the typed family.
- **Skeptic's response:** ACCEPT (70%).
- **Your analysis:** Verified: `project_session_manager.dart:201–203` selects `openReadOnly`, which delegates to `openProjectDatabaseReadOnly` (project_database_platform_io.dart:19–26) — straight to `sqlite3.open(mode: readOnly)` with no classification (the wrapper lives only inside `ProjectDatabaseService.open`, lines 186–188). A missing file on the read-only path surfaces `SqliteException(SQLITE_CANTOPEN)` raw. Reachability of read-only opens from the UI was not found in production call sites (no caller passes `mode: readOnly`), so the surface is latent — matches the Low filing.
- **VERDICT: REAL BUG**
- **Confidence:** High (mechanism) / Medium (trigger)
- **True severity:** Low (confirmed)
- **Suggested fix:** Route the read-only leg through a classifying wrapper (reuse `classifyProjectDatabaseOpenError`), or add classification to `openReadOnly` in `ProjectDatabaseService`.

---

**BUG-14**
- **Hunter's claim:** `registry()` resolves beside the override root but beside `root().parent` when a custom store is active, so one instance can resolve two registry locations and split the registry after a configuration change.
- **Skeptic's response:** UNCERTAIN-ACCEPT (45%) — the ternary is real and internally inconsistent with `rootDirectoryFile`, but no reachable split path established.
- **Your analysis:** Verified the ternary (project_paths.dart:174–179) and the production wiring: the only `ProjectPaths` built with a store is `project_persistence_providers.dart:32` (`ProjectPaths(customStorageStore: store)`, no rootDirectory), and the only production `ProjectPaths(rootDirectory:)` (`project_session_manager.dart:230`) feeds `CharacterRepositoryImpl`, which never calls `registry()` (its only caller is `_registryFile` in the registry service). Within any one configuration the resolution is stable and single-location; switching storage homes switching the project set (and its registry) is the documented per-home design ("Host file next to the effective root", rootDirectoryFile doc). The `rootDirectoryFile` vs `registry()` placement difference (inside vs beside the active location) is cosmetic, not data-splitting.
- **VERDICT: NOT A BUG**
- **Confidence:** Medium

---

**BUG-15**
- **Hunter's claim:** `probeWrite()` translates only `SqliteException`, so on web the seam's `UnsupportedError` escapes raw instead of a typed domain failure.
- **Skeptic's response:** UNCERTAIN-ACCEPT (50%) — mechanism true; zero production callers; the proposed wrapper would arguably be the wrong family.
- **Your analysis:** Both facts verified (`project_database_service.dart:221–233` catches only `on sqlite.SqliteException`; web seam throws `UnsupportedError` at project_database_platform_web.dart:26–28). But `probeWrite` has zero production callers in lib/ (only doc-comment references), so no surface exists for the claimed inconsistency, and wrapping a platform-capability gap in `ProjectDatabaseWriteFailedException` ("media rejected a write") would be a semantic misclassification — the platform cannot probe at all, which is not a write failure. The behavior only becomes a design question when a caller is wired.
- **VERDICT: NOT A BUG**
- **Confidence:** Medium

---

**BUG-16**
- **Hunter's claim:** web `openProjectDatabase` has no close-on-initialization-failure, leaking the opened `WebDatabase`, unlike the io counterpart's try/catch-close.
- **Skeptic's response:** ACCEPT (85%).
- **Your analysis:** Verified side by side: `project_database_platform_web.dart:7–11` is `await database.initialize(); return database;` with no try/catch, while `project_database_platform_io.dart:8–17` does `catch (_) { await database.close(); rethrow; }`. A drift web initialize failure (IndexedDB open error mid-migration) leaks the constructed wrapper. Same shape as the io file's own hardening; the asymmetry is real. Web-only and leak-until-GC, so Low is right.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low (confirmed)
- **Suggested fix:** Mirror the io seam: wrap `initialize()` in try/catch, `await database.close()` on failure, rethrow.

---

**BUG-17**
- **Hunter's claim:** the write probe classifies a failed `.vs_write_probe` delete as not-writable even though the write succeeded, so a transient sharing violation on cleanup makes a healthy location report unwritable and `setActiveLocation`/`relinkLocation` reject it.
- **Skeptic's response:** ACCEPT (85%).
- **Your analysis:** Verified `custom_storage_location.dart:234–249`: `writeAsString` and `delete` share one `on FileSystemException { writable = false; }` → `StorageProbeReason.permissionDenied`; `probe()` propagates `writable:false` (136–143) and `setActiveLocation`/`relinkLocation` throw "not usable" (368–371, 419–421). A failed cleanup delete after a successful write is exactly the errno-32 fresh-file window this repo documents and field-observed. Consequence: a healthy location is rejected at activation/relink — a false negative, not data loss.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low (confirmed)
- **Suggested fix:** Give the delete its own try/catch (best-effort cleanup — a leftover probe file is harmless) and classify writability from the write result alone.

---

**BUG-18**
- **Hunter's claim:** `root()` sets a `missingDrive` fallback notice even when no custom location was configured (`activeLocation == null` but a store exists — the default composition), producing a false warning contract violation.
- **Skeptic's response:** UNCERTAIN-ACCEPT (65%) — mechanism verified; zero readers today, so latent.
- **Your analysis:** Verified: in the production wiring the store is ALWAYS present (`project_persistence_providers.dart:17–33`), so `root()` (project_paths.dart:75–97) enters the store branch on every call; with `activeLocation == null` the healthy check fails and the notice branch sets `lastFallbackNotice = StorageFallbackNotice(reason: missingDrive, requestedLocation: null, ...)` — contradicting the field's own doc ("null when no custom store is configured at all"; the notice exists because "the configured drive is missing"). The test `project_paths_fallback_notice_test.dart:83–88` only covers store == null, never store-present-but-unconfigured, so the violation is untested. Repo-wide grep confirms `lastFallbackNotice` has no readers outside the class and tests, so no user-visible false warning fires today.
- **VERDICT: REAL BUG**
- **Confidence:** High (mechanism) / Medium (impact timing)
- **True severity:** Low (confirmed — latent false-positive by contract)
- **Suggested fix:** Only set the notice when `active != null` (something configured but unreachable); with nothing configured, clear it (`lastFallbackNotice = null`) like the healthy branch does.

---

**BUG-19**
- **Hunter's claim:** the corruption-recovery path restores the pre-`remove()` `.bak` unconditionally, so a deleted project is resurrected into the registry — deletion is not represented in the `.bak` recovery contract.
- **Skeptic's response:** UNCERTAIN-ACCEPT (60%) — mechanism verified; harm softer than claimed (package folder is never deleted, so no data destroyed).
- **Your analysis:** Verified the mechanism: `remove()` (project_registry_service.dart:209–213) rewrites via `_saveUnlocked` → `atomicWrite`, which archives the PRE-remove content as `.bak` (project_recovery_service.dart:159–163); `_decodeProjectsWithBackupRecovery` (96–106) then `restoreBackup`s that copy unconditionally on corruption, and nothing in the recovery contract represents deletion. Also verified the harm bound: `deleteProject` only unregisters (project_controller.dart:61–72 → registry.remove; no folder deletion), so a resurrected entry points at an intact package — a deletion undone by an unrelated corruption event, not data loss. Bounded but real: recovery silently reverses a user decision.
- **VERDICT: REAL BUG**
- **Confidence:** Medium
- **True severity:** Low (confirmed — behavioral flaw, bounded impact)
- **Suggested fix:** Persist deletion intent (a tombstone file/list of removed ids written by `remove()`) and filter restored `.bak` entries against it during backup recovery.

---

**BUG-20**
- **Hunter's claim:** lib/main.dart imports `dart:io` (`exit()`), CI builds `flutter build web --release`, and the 0c238ba seam work was "for that same CI web build" — so either the web build is broken on master or that CI step is not gating.
- **Skeptic's response:** DISPROVED (72%) — dart:io imports compile against a stub SDK for web; only APIs throw at runtime. The dichotomy is false.
- **Your analysis:** Verified `main.dart:1,71` (import + single `exit(0)` use inside the `onResetConfig` callback, not kIsWeb-gated) and ci.yml:86–87. The Skeptic is right on the mechanism: `dart:io` is a platform-stub library for dart2js/Flutter web — the import resolves at compile time and its APIs throw `UnsupportedError` at runtime; that is exactly why 0c238ba's seam work targeted `dart:ffi` (a genuinely compile-time-unavailable library) while leaving main.dart untouched. The claimed build/CI contradiction does not exist. Residual truth: a web user triggering config-reset would hit a runtime UnsupportedError — a trivial latent edge, not the claimed build breaker.
- **VERDICT: NOT A BUG**
- **Confidence:** High

---

**BUG-21**
- **Hunter's claim:** `addTagToAssets` appends to the tail instead of a set union, so re-adding a present tag duplicates it in the list passed to `replaceTags` — masked only by replaceTags' dedupe; any consumer of the intermediate list yields duplicates.
- **Skeptic's response:** DISPROVED (80%) — `replaceTags` is the only consumer and its `.toSet()` normalization is the input to the entire write path; the duplicate is eliminated deterministically, not "masked".
- **Your analysis:** Verified: `replaceTags` normalizes `values.map(...).where(...).toSet()` (asset_dao.dart:113–116) before anything else, and repo-wide grep confirms asset_dao.dart:160 is its only call site feeding user-visible writes (the other callers pass UI-provided tag lists). There is no intermediate consumer in the repo; "any change in normalization" is speculative future-proofing, not a present bug.
- **VERDICT: NOT A BUG**
- **Confidence:** High

---

**BUG-22**
- **Hunter's claim:** `replaceTags` performs an N+1 — `await getById(assetId)` inside the per-tag loop re-queries the same asset row once per tag for a loop-invariant projectId.
- **Skeptic's response:** ACCEPT (95%).
- **Your analysis:** Verified `asset_dao.dart:121–133`: `projectId: (await getById(assetId))?.projectId ?? ''` runs once per tag inside the transaction; the value is loop-invariant. Single-row PK lookups with small tag counts make the cost negligible — a true but trivial perf nit, correctly filed as Low.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low (confirmed)
- **Suggested fix:** Hoist `final asset = await getById(assetId);` above the loop and use `asset?.projectId ?? ''`.

---

**BUG-23**
- **Hunter's claim:** `resolve()` copies the legacy `storage_locations.json` into the preferred location but never consumes/renames/compares it, so post-migration edits to the legacy file are silently ignored and a later deletion of the preferred file resurrects stale legacy content.
- **Skeptic's response:** ACCEPT (85%).
- **Your analysis:** Verified `storage_location_registry_resolver.dart:16–33`: one-way `atomicWrite` copy when preferred is absent; no delete/rename/archive of `legacyFile`. Both claimed divergences follow: post-migration legacy edits are ignored (`preferred.exists()` short-circuits at line 24), and if the preferred file is later lost (crash window where `.bak` is also gone), `resolve()` re-imports the stale legacy copy over the newer durable state. One-way copy without consuming the source is a genuine dual-source hazard, though the trigger set (legacy file edited after migration / preferred+bak both lost) is narrow.
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low (confirmed)
- **Suggested fix:** Consume the source after a successful copy: rename `legacyFile` to `storage_locations.json.imported` (best-effort, ignore failure) so the legacy file can never win a later re-import.

---

**BUG-24**
- **Hunter's claim:** `save()` checkpoints WAL, writes the manifest, then `markSaved()`; a manifest write failure leaves the saved-sequence marker behind the durable DB state, so a reopened session reports unsaved changes for data that is actually saved and retries keep rewriting only the manifest.
- **Skeptic's response:** UNCERTAIN-ACCEPT (55%) — ordering verified, but a retry re-runs the whole sequence including `markSaved()`, so the claimed persistent-retry impact does not hold.
- **Your analysis:** Verified the ordering (`project_session_manager.dart:85–104`) and that `markSaved()` writes `savedMutationSequence` (project_mutation_runtime.dart:181–191). The claimed "retry loop keeps rewriting only the manifest" is wrong: any successful retry re-executes checkpoint → manifest → `markSaved()`, so the state is self-healing. And while the manifest write is failing, reporting the session as unsaved is honest — "saved" by this system's definition includes the manifest update, which did not complete. No data loss, no permanent divergence, failure state is truthful until healed.
- **VERDICT: NOT A BUG**
- **Confidence:** Medium

---

**BUG-25**
- **Hunter's claim:** the `manifest` open metric is recorded after the manifest read with a wall-clock delta across adjacent statements, recording ~0 ms and reporting the phase as free.
- **Skeptic's response:** ACCEPT (95%).
- **Your analysis:** Verified `project_session_manager.dart:142–156`: the manifest file is read and parsed at 142–145, `manifestStarted` is created at 150, and `metrics.record('manifest', ...)` at 151–156 measures the gap between two adjacent statements — always ~0 ms. The actual read+parse cost is excluded from the open-latency budget the metric exists for. Mechanically indisputable. (Mitigating context: `openMetrics` has no consumers beyond session construction today, so the meaningless value harms no consumer yet.)
- **VERDICT: REAL BUG**
- **Confidence:** High
- **True severity:** Low (confirmed)
- **Suggested fix:** Start the clock before the manifest read/parse (line 142) and record immediately after parsing.

---

**BUG-26**
- **Hunter's claim:** `BackupRollbackException.toString()` omits `restoreError` — the original restore failure — so the no-data-loss diagnostic surface reports only which areas failed to roll back, never the root cause.
- **Skeptic's response:** ACCEPT on mechanism (90%) — but flagged the file as TRACE-ONLY in the scope manifest.
- **Your analysis:** Mechanism verified: `project_recovery_services.dart:156–172` — `final Object restoreError;` (164) is captured from the restore-failure catch (434) and passed at the throw site (456–458), but `toString()` (167–171) renders only `rollbackErrors.keys` and `$emergencyBackupPath`; `restoreError` is never rendered anywhere (grep-verified). For the no-data-loss diagnostic surface of a full-payload rollback, omitting the triggering error is a real diagnostic gap.
- **SCOPE RULING:** The Skeptic's scope-violation flag is UPHELD. `lib/features/project_resilience/application/project_recovery_services.dart` is listed TRACE-ONLY in hunt-scope-run197.md ("dibaca seperlunya untuk verifikasi klaim"), and unlike BUG-1's caller chain, this finding originates and terminates entirely inside that trace-only file — the in-scope code contributes nothing but the propagation context. The finding is real on merit, but the run's accounting must carry it as an explicit out-of-scope exception (recommend: fix it, but do not count it toward the 18-file region's coverage metrics).
- **VERDICT: REAL BUG (merit) — out-of-scope per manifest, exception recorded**
- **Confidence:** High
- **True severity:** Low (confirmed — diagnostics-only)
- **Suggested fix:** Render the cause: `'... incomplete for ${rollbackErrors.keys.join(', ')}; restore error: $restoreError. Emergency backup retained at $emergencyBackupPath'`.

---

## FINAL SUMMARY

**VERIFIED BUG REPORT — run197**

Stats:
- Total reported by Hunter: 26
- Dismissed as false positives: 7 (BUG-2, BUG-3, BUG-14, BUG-15, BUG-20, BUG-21, BUG-24)
- Confirmed as real bugs: 19
- Critical: 1 | Medium: 3 | Low: 15

Referee deltas from the Skeptic's verdicts:
- Downgraded Medium → Low: BUG-4, BUG-7, BUG-9, BUG-10, BUG-11, BUG-12 (each: mechanism verified, but the trigger is dormant/unwired in production or runtime-only per the static-analysis honesty rule)
- Overturned the Skeptic's UNCERTAIN-ACCEPT to NOT A BUG: BUG-14 (per-home registry is deliberate; no mixing path), BUG-15 (zero callers; proposed wrapper would be the wrong family), BUG-24 (self-healing + honest-state semantics)
- BUG-26: real on merit, scope violation upheld and recorded as an explicit out-of-scope exception.

Confirmed bugs (ordered by severity):

| # | Severity | File | Line(s) | Description | Suggested Fix |
|---|----------|------|---------|-------------|---------------|
| BUG-1 | Critical | lib/core/persistence/project_registry_service.dart (+ project_recovery_service.dart, project_controller.dart) | 202–206, 79–85; recovery 130–132; controller 53–58 | Unguarded creation-marker delete after durable upsert; transient errno-32 propagates into ProjectController's catch which deletes the complete package — permanent project loss + dangling registry entry | Wrap both consume sites best-effort (`on FileSystemException` ignore) or reuse `_consumeQuietly`/`_deleteWithTransientRetry` |
| BUG-5 | Medium | lib/features/project_resilience/application/project_session_manager.dart | 112–128 (close 110) | Unguarded sequential teardown; release/dispose failure skips remaining steps, leaks connection or strands the session marker (same-process reopen blocked); memoized failed close never retries | Per-step try/catch, always close DB + release lock, clear `_closing` on failure |
| BUG-6 | Medium | lib/features/project_resilience/application/project_session_manager.dart | 319–331 | Catch block: unguarded `lock.release()`/`lockFile.delete()` precede the guarded DB close; their throw skips close and replaces the original error (comment unreachable in its own target case) | Guard each cleanup step; close DB first; rethrow original error |
| BUG-8 | Medium | lib/features/project_resilience/application/durable_draft_journal.dart | 131–164 | `pendingEntries()` catches only FormatException; non-String fields raise TypeError, aborting the whole recovery listing — breaks the no-silent-loss contract for every scene | Widen catch to `on Object`, emit corrupt entry, continue scan |
| BUG-4 | Low | lib/features/project_resilience/application/durable_draft_journal.dart | 52–80, 195–197 | Flag-only `close()` cannot stop an in-flight `stage()`; post-close write re-creates the journal dir (no production close() caller today) | Track outstanding stages; await in close() |
| BUG-7 | Low | lib/core/persistence/project_recovery_service.dart / project_registry_service.dart | 213; registry 50–87 | Move roll-forward recovery has zero production callers; stranded source package invisible (move feature itself dormant — becomes Medium when it ships) | Call `recoverInterruptedMoves` from `_loadUnlocked` when wiring the move feature |
| BUG-9 | Low | lib/core/persistence/custom_storage_location.dart | 383–439 | Read-modify-write mutations with no mutex — lost-update between overlapping calls (mutations have no production callers today) | Add AsyncMutex around the three mutations |
| BUG-10 | Low | lib/core/persistence/project_health_service.dart | 64–72 | Health check uses the mutating production open path (migrations + metadata upsert) and collapses typed failures to one boolean (test-only caller today) | Probe read-only; surface typed failure classes |
| BUG-11 | Low | lib/database/project/project_database_service.dart | 126–155 | Extended-code variants (517/261/262/264/1034…) and primary 6 fall through to the corruption classification (extended codes are ON in sqlite3 3.5.1) | Classify by primary family via resultCode; keep extended code in payload |
| BUG-12 | Low | lib/features/project_resilience/application/project_session_manager.dart | 41–48, 217 | `ProjectLockedException` doc promises prompt-and-retry; zero catch sites — locked projects surface as generic open failure (manual unlock via Security Settings exists) | Catch the type in the open flow and route to the lock surface |
| BUG-13 | Low | lib/features/project_resilience/application/project_session_manager.dart | 201–203 | Read-only open bypasses the classification wrapper; raw SqliteException reaches the UI | Classify the read-only leg too |
| BUG-16 | Low | lib/database/project/project_database_platform_web.dart | 7–11 | No close-on-initialization-failure; leaks WebDatabase on init failure (io seam has the guard) | Mirror io's try/catch-close-rethrow |
| BUG-17 | Low | lib/core/persistence/custom_storage_location.dart | 234–249 | Probe delete failure after a successful write reports a writable location as permissionDenied; activation/relink reject it | Separate try/catch for the delete (best-effort cleanup) |
| BUG-18 | Low | lib/core/persistence/project_paths.dart | 75–97 | `missingDrive` notice set when nothing is configured (store always present, activeLocation null), violating the field's own contract; latent false warning | Set notice only when `active != null`, else clear |
| BUG-19 | Low | lib/core/persistence/project_registry_service.dart | 96–106 (209–213) | `.bak` restore can resurrect a deleted project's registry entry; deletion unrepresented in recovery contract (no data destroyed — folder remains) | Persist deletion tombstones; filter restored entries |
| BUG-22 | Low | lib/database/project/daos/asset_dao.dart | 121–133 | N+1: `getById(assetId)` inside the per-tag loop for a loop-invariant projectId | Hoist one query above the loop |
| BUG-23 | Low | lib/core/persistence/storage_location_registry_resolver.dart | 16–33 | One-way legacy copy never consumed; stale legacy content can resurrect if preferred file is lost | Rename legacy to `.imported` after successful copy |
| BUG-25 | Low | lib/features/project_resilience/application/project_session_manager.dart | 142–156 | 'manifest' metric measured across adjacent statements after the read — always ~0 ms, phase reported free | Start clock before the read/parse |
| BUG-26 | Low (out-of-scope per manifest) | lib/features/project_resilience/application/project_recovery_services.dart | 156–172 | `BackupRollbackException.toString()` never renders `restoreError` — root cause of the rollback invisible | Include `$restoreError` in toString |

Low-confidence / flagged-for-manual-review items (Medium confidence verdicts): BUG-4, BUG-7 (impact timing), BUG-9, BUG-10, BUG-11, BUG-18, BUG-19. Of the NOT A BUG rulings, BUG-14, BUG-15 and BUG-24 were Medium confidence — each rests on dormant production wiring or deliberate-contract reading; re-triage if the storage settings UI, the move feature, or a probeWrite caller ships.

TOTAL REAL BUGS: 19 / TOTAL NOT A BUG: 7
