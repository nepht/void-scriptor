# Bug-hunt run197 — Skeptic verdict report

Repo: D:\VoidScriptor\void_scriptor_multiplatform · HEAD b5d8bba · mode: read-only adversarial review.
Method: every reported location independently re-read via read_file (no reliance on Hunter quotes); every
cross-file claim (callers, zero-consumer claims, contract docs) re-verified with repo-wide grep and git log.
No builds/tests run, no network, no edits (this report is the only file written).

EV rule applied per skeptic.md: DISPROVE only when confidence > 67% (EV = conf×pts − (1−conf)×2×pts > 0).
Verdict mapping: DISPROVE → DISPROVED; ACCEPT → CONFIRMED (confidence ≥ ~67% the mechanism/impact is real)
or UNCERTAIN (accepted because disproving carried negative EV, i.e. below the 67% bar).

Scope note on BUG-26: project_recovery_services.dart is trace-only in hunt-scope-run197.md. The finding was
judged on mechanism merit as instructed; the scope violation is flagged separately at the end.

---

**BUG-1** | Original: 10 pts | Verdict: **CONFIRMED**
- **Counter-argument:** None found. I tried to break the chain at three points and could not.
- **Evidence:** (1) `project_registry_service.dart:202-206` — after `_saveUnlocked(projects)` the call
  `await _recovery.consumeCreationMarker(File(p.join(project.localPath, ...)))` is unguarded; contrast the
  same class's own best-effort contract at `project_recovery_service.dart:134-141` (`_consumeQuietly`:
  "A marker that cannot be removed must not break project listing") and `_consumeLandedMoveMarkers`
  (registry lines 225-229) which wrap `marker.delete()` in `on FileSystemException { continue; }`.
  `consumeCreationMarker` (recovery 130-132) is a bare `if (await marker.exists()) await marker.delete();`.
  (2) The failure class is documented as real in this repo: `project_recovery_services.dart:116-121` ("Windows
  can transiently refuse a marker delete with a sharing violation (errno 32) while another closer, antivirus
  scan, or indexer still holds a read handle") and the bounded-retry ladders built for exactly this
  (`_deleteWithTransientRetry`, `durable_draft_journal.dart:92-118`). The creation-marker delete has no such
  retry. (3) Caller chain: `ProjectRegistryService.upsert` ← `ProjectLocalDataSource.createProject`
  (project_local_data_source.dart:24-27) ← `ProjectRepositoryImpl.createProject` ←
  `ProjectController.createProject` (project_controller.dart:50) whose catch (lines 53-58) does
  `await createdRoot.delete(recursive: true)` on ANY error. The registry save already completed before the
  marker delete throws, so the result is a fully-created package destroyed plus a dangling registry entry.
  The identical unguarded pattern also exists in `_loadUnlocked` lines 79-85.
- **Confidence:** 95%
- **Risk calc:** EV = (95% × 10) − (5% × 2 × 10) = 9.5 − 1.0 = +8.5
- **Decision:** ACCEPT (Critical, 10 pts)
---

**BUG-2** | Original: 5 pts | Verdict: **DISPROVED**
- **Counter-argument:** The claim's central harm — "reports `ProjectDatabaseUnreadableException` (corruption)
  for what is actually unavailable storage" — is contradicted by the code the Hunter himself quoted.
  `project_database_service.dart:167-172` throws `ProjectDatabaseUnavailableException`, which is precisely
  the non-corruption class created for unreachable storage ("Database pada storage yang terjangkau bisa saja
  sehat - ini bukan klasifikasi korup", lines 71-75). The misclassification the claim asserts is the one
  outcome the code structurally cannot produce on this branch.
- **Evidence:** The two residual prongs also fail. (a) Async/sync race (file deleted between
  `readProjectDatabaseSchemaVersion` and `existsSync()`): the outcome is
  `ProjectDatabaseUnavailableException` — the correct classification for a now-missing file; no corruption is
  claimed. (b) `existsSync()` swallowing an I/O error and returning false: again routes to
  Unavailable, not Unreadable — for a path whose stat fails, "storage not reachable" is the right family.
  (c) "synchronous disk I/O on the UI isolate": one `stat` on a path the flow already probed asynchronously
  is negligible and no contract in the file promises async-only access.
- **Confidence:** 82%
- **Risk calc:** EV = (82% × 5) − (18% × 2 × 5) = 4.1 − 1.8 = +2.3
- **Decision:** DISPROVE
---

**BUG-3** | Original: 5 pts | Verdict: **DISPROVED**
- **Counter-argument:** The claimed clobber mechanism cannot occur for the claim's lead scenario, because the
  tags are RE-READ inside the loop on every iteration — there is no stale snapshot. The Hunter's own quoted
  evidence shows it: `for (final id in assetIds) { final existing = await getTags(id); await
  replaceTags(id, [...existing, normalized]); }`. For an asset listed twice: iteration 1 writes {a, t};
  iteration 2's `getTags` re-read returns {a, t} (not the pre-call state), `replaceTags(id, [a, t, t])`
  normalizes through a `toSet()` (asset_dao.dart:113-116) → {a, t}. Nothing is dropped.
- **Evidence:** The cross-call variant is also not reachable as claimed: (a) `addTagToAssets` takes ONE tag
  for all ids (asset_dao.dart:154), so two overlapping calls write the same or different tags per asset, and
  (b) each call wraps the whole read-modify-write in `transaction()` (lines 157-162); drift serializes
  top-level transactions on a single connection, so an interleaved read-modify-write clobber would require
  two concurrent calls that the only production caller (`asset_browser_screen.dart:537`, awaited, one
  selection list of unique ids) never produces. The "silently dropping a tag the caller asked to add" harm
  has no reachable path.
- **Confidence:** 72%
- **Risk calc:** EV = (72% × 5) − (28% × 2 × 5) = 3.6 − 2.8 = +0.8
- **Decision:** DISPROVE
---

**BUG-4** | Original: 5 pts | Verdict: **UNCERTAIN (accepted per EV rule)**
- **Counter-argument:** `close()` (durable_draft_journal.dart:195-197) contains no awaits, so the flag takes
  effect synchronously; the race window is only "stage passed its check before close() ran and is still
  awaiting writes". The recovered artifact is a genuine draft the user actually staged, so the surfaced entry
  is not false data — the harm is limited to a stale post-close write recreating `recovery/draft-journal/`
  (line 59) after the session ended.
- **Evidence:** Verified: `_closed` checked once at lines 56-58 before `_dir.create` and all awaited
  write/rename work; `close()` is flag-only with no outstanding-stage tracking. The mechanism is real; I
  could not verify a production path where the post-close write causes user-visible wrongness beyond a
  stale recovery entry.
- **Confidence:** 65% (real bug)
- **Risk calc:** EV = (65% × 5) − (35% × 2 × 5) = 3.25 − 3.5 = −0.25 → disprove is EV-negative
- **Decision:** ACCEPT (Medium, 5 pts)
---

**BUG-5** | Original: 5 pts | Verdict: **CONFIRMED**
- **Counter-argument:** None found.
- **Evidence:** `project_session_manager.dart:112-128` — `await mutationRuntime.dispose()`, the
  transient-job cancel loop, `await jobs.dispose()`, then `await database.close()`, then
  `lock.release()`/lock-file delete, all sequential with no try/finally. Any throw above
  `database.close()` leaks the SQLite connection. The memoization aggravates it:
  `close() => _closing ??= _close()` (line 110) — a retry reuses the FAILED future, so remaining steps
  never re-run. `lock.release()` can genuinely throw: `_deleteWithTransientRetry`
  (project_recovery_services.dart:122-142) rethrows after 5 failed attempts by design ("release stays
  fail-closed").
- **Confidence:** 90%
- **Risk calc:** EV = (90% × 5) − (10% × 2 × 5) = 4.5 − 1.0 = +3.5
- **Decision:** ACCEPT (Medium, 5 pts)
---

**BUG-6** | Original: 5 pts | Verdict: **CONFIRMED**
- **Counter-argument:** None found.
- **Evidence:** `project_session_manager.dart:319-330` — inside the catch, `await lock.release()` (line 320)
  precedes the guarded close (lines 326-329). A throw from `release()` propagates out of the catch block,
  skipping both the companion delete and `database.close()`, and replaces the original open error.
  `lock.release()` throwing is realistic for the same errno-32 delete-retry exhaustion documented in the
  lock class itself. The comment "Ensure database is closed if it was partially opened" (line 326) is
  unreachable in exactly the failure case it exists for.
- **Confidence:** 90%
- **Risk calc:** EV = (90% × 5) − (10% × 2 × 5) = 4.5 − 1.0 = +3.5
- **Decision:** ACCEPT (Medium, 5 pts)
---

**BUG-7** | Original: 5 pts | Verdict: **CONFIRMED**
- **Counter-argument:** I searched for any production caller and any alternate recovery path that rolls
  moves forward; there is none.
- **Evidence:** Repo-wide grep for `recoverInterruptedMoves(` in lib/ matches only its definition
  (project_recovery_service.dart:213). `_loadUnlocked` (project_registry_service.dart:50-87) calls
  `recoverIfInterrupted`, `_recoverImportStashes`, `_decodeProjectsWithBackupRecovery`,
  `_consumeLandedMoveMarkers`, `admitMarkedCreations` — a package stranded at the move SOURCE is invisible
  to all of them (source marker `move-pending.marker` is only deleted, never acted on, by
  `_consumeLandedMoveMarkers`). The roll-forward contract documented at project_move_service.dart:17-18
  ("rename never ran -> [ProjectRecoveryService.recoverInterruptedMoves] rolls the package forward") is
  test-only (test/core/persistence/project_move_recovery_test.dart).
- **Confidence:** 90%
- **Risk calc:** EV = (90% × 5) − (10% × 2 × 5) = 4.5 − 1.0 = +3.5
- **Decision:** ACCEPT (Medium, 5 pts)
---

**BUG-8** | Original: 5 pts | Verdict: **CONFIRMED**
- **Counter-argument:** None found.
- **Evidence:** durable_draft_journal.dart:131-164 — `decoded['sceneId'] as String?` (line 134),
  `decoded['content'] as String?` (135), `decoded['stagedAt'] as String? ?? ''` (150) run inside
  `try { ... } on FormatException { ... }`. A syntactically valid JSON file with a non-String field raises
  `TypeError` in Dart, which is not caught; the exception escapes `pendingEntries()` and aborts the whole
  recovery listing. The file's own header contract promises malformed entries "TIDAK dibuang diam-diam ...
  di-surface-nya sebagai entri isCorrupt" (lines 15-17) — one type-corrupt entry breaks that contract for
  every scene. Note the adjacent `admitMarkedCreations` had the identical bug fixed with `on Object`
  (project_recovery_service.dart:77-84, "core-hunt-20260906 BUG-02 ... throws TypeError, not
  FormatException").
- **Confidence:** 90%
- **Risk calc:** EV = (90% × 5) − (10% × 2 × 5) = 4.5 − 1.0 = +3.5
- **Decision:** ACCEPT (Medium, 5 pts)
---

**BUG-9** | Original: 5 pts | Verdict: **CONFIRMED**
- **Counter-argument:** None found.
- **Evidence:** custom_storage_location.dart — `setActiveLocation` (383-390), `bindProject` (393-402),
  `relinkLocation` (404-439) all do `final current = await load(); ... await _save(state built from
  current)`. The class has no mutex: `load()`/`_save()` (284-315, 441-455) are plain async reads/writes
  through `_recovery.atomicWrite`. Interleaving two calls (each awaits between load and save) loses the
  other's field, exactly the lost-update class `AsyncMutex` was written for and which
  `ProjectRegistryService` applies to every mutation (`_mutex.run`, registry lines 48, 173-174, 189, 209).
- **Confidence:** 80%
- **Risk calc:** EV = (80% × 5) − (20% × 2 × 5) = 4.0 − 2.0 = +2.0
- **Decision:** ACCEPT (Medium, 5 pts)
---

**BUG-10** | Original: 5 pts | Verdict: **CONFIRMED**
- **Counter-argument:** None found.
- **Evidence:** project_health_service.dart:64-72 calls `ProjectDatabaseService().open(database.path)` and
  collapses every failure with `on Object { databaseReadable = false; }`. `open()` is the full production
  path: drift `MigrationStrategy` (project_database.dart:353+) runs on first open, and
  `initialize()` (project_database.dart:765-771) executes
  `INSERT INTO project_metadata ... ON CONFLICT(key) DO UPDATE` — a WRITE, unconditionally, on every open
  (the upsert always updates). So a diagnostic check mutates the user's project database every time. The
  busy-misreport scenario is real though narrow (requires the app's own connection to hold the write lock
  mid-transaction at probe time), and typed outcomes (Locked/TooNew/Unavailable/WriteFailed) are all
  flattened to one boolean, defeating the Data-Safety matrix classes the service itself defines.
- **Confidence:** 80%
- **Risk calc:** EV = (80% × 5) − (20% × 2 × 5) = 4.0 − 2.0 = +2.0
- **Decision:** ACCEPT (Medium, 5 pts)
---

**BUG-11** | Original: 5 pts | Verdict: **UNCERTAIN (accepted per EV rule)**
- **Counter-argument:** The claim's framing ("the same class of bug run94 BUG-13 claims was fixed") is wrong
  in kind: run94 BUG-13 was about MASKING extended codes with 0xFF (comparison never matching); the current
  code deliberately compares unmasked exact codes per the documented contract
  (project_database_service.dart:114-125). If the sqlite3 engine returns PRIMARY codes (extended result
  codes not enabled), the current branches (5/8/13/14 exact, primary-10 via `resultCode == 10`) cover the
  documented families and only primary 6 (SQLITE_LOCKED) is missing.
- **Evidence:** What survives: IF extended codes are enabled (sqlite3 dart package generally surfaces
  `extendedResultCode`), variants like 517/261 (BUSY_SNAPSHOT/RECOVERY) or 262 (LOCKED_SHAREDCACHE) fall
  through to `ProjectDatabaseUnreadableException` (corruption) at line 154 — a real misclassification gap
  for those codes. I could not determine the engine's extended-code mode without running code, and the
  session-lock design already prevents the app's own concurrent-writer scenarios that produce these codes,
  so the reachable trigger set is unclear.
- **Confidence:** 55% (real bug)
- **Risk calc:** EV = (55% × 5) − (45% × 2 × 5) = 2.75 − 4.5 = −1.75 → disprove is EV-negative
- **Decision:** ACCEPT (Medium, 5 pts)
---

**BUG-12** | Original: 5 pts | Verdict: **CONFIRMED**
- **Counter-argument:** I checked whether the UI routes session-open failures by some other mechanism; it
  does not.
- **Evidence:** Repo-wide grep: `ProjectLockedException` appears only in project_session_manager.dart
  (definition 41-48, throw 217). The session controller (project_persistence_providers.dart:131-134) puts
  the raw error into `AsyncError` and rethrows; nothing in lib/ catches the type, and the passphrase UI
  (core/security/presentation/project_lock_screen.dart) is not wired to session-open failures. The doc
  promise at lines 38-40 ("The caller (UI) should prompt for the passphrase and retry") is unimplemented:
  a locked project surfaces as a generic open failure with no retry path.
- **Confidence:** 85%
- **Risk calc:** EV = (85% × 5) − (15% × 2 × 5) = 4.25 − 1.5 = +2.75
- **Decision:** ACCEPT (Medium, 5 pts)
---

**BUG-13** | Original: 1 pt | Verdict: **CONFIRMED**
- **Counter-argument:** The read-only call IS inside the open() try block, so the error does not escape
  unhandled — but it also passes unclassified, which is the claim.
- **Evidence:** project_session_manager.dart:201-203 selects `openReadOnly` directly; the classification
  wrapper (`on sqlite.SqliteException → classifyProjectDatabaseOpenError`) exists only inside
  `ProjectDatabaseService.open` (project_database_service.dart:186-188), which the read-only leg bypasses
  (`openReadOnly` → `openProjectDatabaseReadOnly`, platform_io.dart:19-26, straight to the platform seam).
  A missing/corrupt/BUSY database on the read-only path leaks a raw `SqliteException` instead of the typed
  family the Data-Safety matrix defines. Real but Low.
- **Confidence:** 70%
- **Risk calc:** EV = (70% × 1) − (30% × 2 × 1) = 0.7 − 0.6 = +0.1
- **Decision:** ACCEPT (Low, 1 pt)
---

**BUG-14** | Original: 1 pt | Verdict: **UNCERTAIN (accepted per EV rule)**
- **Counter-argument:** The override branch (registry inside root) vs store/default branch (registry beside
  root) is internally consistent per configuration; production wiring never mixes them
  (project_persistence_providers.dart:30-37 builds `ProjectPaths(customStorageStore: ...)` without
  rootDirectory, and the only production `ProjectPaths(rootDirectory:)` — project_session_manager.dart:230 —
  feeds CharacterRepositoryImpl, which never calls registry()). "Beside the effective root" is the
  documented convention (project_paths.dart:149-151), so registry relocation on switching storage homes
  looks deliberate rather than a split.
- **Evidence:** The ternary at project_paths.dart:174-179 is real, and the store-active branch resolves
  `(await root()).parent` — e.g. `E:/projects.json` beside `E:/VSProjects/` — diverging from
  `rootDirectoryFile` (lines 152-160) which places wiring files INSIDE the active location. The internal
  inconsistency exists; whether any reachable path turns it into the claimed "split registry" harm is not
  established.
- **Confidence:** 45% (real bug)
- **Risk calc:** EV = (45% × 1) − (55% × 2 × 1) = 0.45 − 1.1 = −0.65 → disprove is EV-negative
- **Decision:** ACCEPT (Low, 1 pt)
---

**BUG-15** | Original: 1 pt | Verdict: **UNCERTAIN (accepted per EV rule)**
- **Counter-argument:** `probeWrite` has zero production callers in lib/ (grep: only the contract comment in
  project_database_platform_io.dart:59), so no UI surface currently exists for the claimed inconsistency;
  and `ProjectDatabaseWriteFailedException` would arguably be the WRONG wrapper for a platform-capability
  gap (media did not reject a write; the platform cannot probe at all).
- **Evidence:** Both quoted facts verified: probeWrite catches only `on sqlite.SqliteException`
  (project_database_service.dart:221-233); the web seam throws `UnsupportedError('Write probe is
  unavailable on web')` (project_database_platform_web.dart:26-28). Mechanism true, impact currently
  hypothetical.
- **Confidence:** 50% (real bug)
- **Risk calc:** EV = (50% × 1) − (50% × 2 × 1) = 0.5 − 1.0 = −0.5 → disprove is EV-negative
- **Decision:** ACCEPT (Low, 1 pt)
---

**BUG-16** | Original: 1 pt | Verdict: **CONFIRMED**
- **Counter-argument:** None found.
- **Evidence:** project_database_platform_web.dart:7-11 — `await database.initialize(); return database;`
  with no try/catch-close, side by side with platform_io.dart:8-17 which does
  `catch (_) { await database.close(); rethrow; }`. A drift web initialize failure (e.g. IndexedDB open
  error mid-migration) leaks the constructed WebDatabase wrapper. Same-shape claim, same-shape evidence as
  the io file's own hardening; the asymmetry is real.
- **Confidence:** 85%
- **Risk calc:** EV = (85% × 1) − (15% × 2 × 1) = 0.85 − 0.3 = +0.55
- **Decision:** ACCEPT (Low, 1 pt)
---

**BUG-17** | Original: 1 pt | Verdict: **CONFIRMED**
- **Counter-argument:** None found.
- **Evidence:** custom_storage_location.dart:236-249 — `writeAsString` and `delete` share one
  `on FileSystemException { writable = false; }` → `StorageProbeReason.permissionDenied`. If the write
  succeeded and only the cleanup delete fails (the errno-32 sharing-violation window this repo documents
  for freshly-written files), a writable location is reported unwritable, and `setActiveLocation` /
  `relinkLocation` then reject it (lines 367-371, 418-421). Failure semantics are conflated as claimed.
- **Confidence:** 85%
- **Risk calc:** EV = (85% × 1) − (15% × 2 × 1) = 0.85 − 0.3 = +0.55
- **Decision:** ACCEPT (Low, 1 pt)
---

**BUG-18** | Original: 1 pt | Verdict: **UNCERTAIN (accepted per EV rule)**
- **Counter-argument:** Currently harmless in production: repo-wide grep shows `lastFallbackNotice` has zero
  readers outside project_paths.dart itself (no status-bar/settings consumer yet), so no user-visible false
  warning can be emitted today.
- **Evidence:** The mechanism is nonetheless verified: in the default composition the store is ALWAYS
  present (project_persistence_providers.dart:17-33) with `activeLocation == null`, and
  `root()` (project_paths.dart:75-97) falls into the notice branch whenever
  `active != null && healthy` is false — so every default root() call sets a `missingDrive` notice with
  `requestedLocation: null`, contradicting the field's own doc ("null when no custom store is configured at
  all" / the notice is for "the configured drive is missing"). Latent false-positive by design contract.
- **Confidence:** 65% (real bug)
- **Risk calc:** EV = (65% × 1) − (35% × 2 × 1) = 0.65 − 0.7 = −0.05 → disprove is EV-negative
- **Decision:** ACCEPT (Low, 1 pt)
---

**BUG-19** | Original: 1 pt | Verdict: **UNCERTAIN (accepted per EV rule)**
- **Counter-argument:** The practical harm is softer than claimed: `deleteProject` only unregisters
  (ProjectController.deleteProject → registry.remove; the package folder is never deleted), so a
  .bak-resurrected entry points at a still-existing folder and no data was destroyed — the user-visible
  effect is a deletion being undone by an unrelated corruption recovery, not lost data.
- **Evidence:** Mechanism verified: `remove()` (project_registry_service.dart:209-213) rewrites
  projects.json via `_saveUnlocked` → `atomicWrite`, which archives the PRE-remove content as `.bak`
  (project_recovery_service.dart:159-163); the corruption path
  (`_decodeProjectsWithBackupRecovery`, registry lines 96-106) then `restoreBackup`s that pre-remove copy
  unconditionally. Nothing anywhere represents deletion in the recovery contract. Real behavioral flaw,
  bounded impact.
- **Confidence:** 60% (real bug)
- **Risk calc:** EV = (60% × 1) − (40% × 2 × 1) = 0.6 − 0.8 = −0.2 → disprove is EV-negative
- **Decision:** ACCEPT (Low, 1 pt)
---

**BUG-20** | Original: 1 pt | Verdict: **DISPROVED**
- **Counter-argument:** The claim's central dichotomy — "either the web build is broken on master or that CI
  step is not gating" — is false. dart2js/Flutter web compiles `dart:io` imports against a stub SDK
  library: the import resolves at compile time and individual dart:io APIs throw `UnsupportedError` at
  RUNTIME (the well-known Flutter-web "Unsupported operation: Platform._operatingSystem" class of errors
  comes from exactly this stub). `import 'dart:io' show exit;` therefore does not break
  `flutter build web --release`.
- **Evidence:** lib/main.dart:1,71 — the import and its single use sit inside the `onResetConfig` callback;
  all dart:io-dependent boot paths are gated by `!kIsWeb` (lines 31-39). If the import broke the web build,
  CI's `flutter build web --release` (ci.yml:86-87) would have been red since Sprint 101 (d8d5e68), which
  is inconsistent with 0c238ba being framed as a targeted web-compile fix for dart:ffi (a genuinely
  compile-time-unavailable library) while main.dart was deliberately left untouched. Residual truth: a web
  user hitting the config-reset callback would get a runtime UnsupportedError — a trivial latent edge, not
  the claimed build/CI contradiction. (Cannot run a build to demonstrate; confidence rests on the documented
  dart2js dart:io stub behavior plus the repo's own commit-archaeology evidence.)
- **Confidence:** 72%
- **Risk calc:** EV = (72% × 1) − (28% × 2 × 1) = 0.72 − 0.56 = +0.16
- **Decision:** DISPROVE
---

**BUG-21** | Original: 1 pt | Verdict: **DISPROVED**
- **Counter-argument:** The claimed bug — "re-adding an already-present tag duplicates it" — cannot
  materialize: `replaceTags` is the only consumer of the appended list and it normalizes through
  `.toSet()` before any write, so the duplicate is eliminated deterministically, not "masked" by accident.
- **Evidence:** asset_dao.dart:112-116 — `final normalized = values.map(...).where(...).toSet();` — the set
  is the input to the entire write path (loop at 121-133 iterates `normalized`). There is no intermediate
  consumer in the repo (`replaceTags` call sites: asset_dao only). The finding's own text concedes the
  duplicate is removed; what remains is speculative future-proofing ("any change in normalization"),
  which is not a present bug.
- **Confidence:** 80%
- **Risk calc:** EV = (80% × 1) − (20% × 2 × 1) = 0.8 − 0.4 = +0.4
- **Decision:** DISPROVE
---

**BUG-22** | Original: 1 pt | Verdict: **CONFIRMED**
- **Counter-argument:** None found (impact is trivial; the mechanism is exactly as claimed).
- **Evidence:** asset_dao.dart:121-133 — `projectId: (await getById(assetId))?.projectId ?? ''` re-queries
  the assets table once per tag inside the transaction; the value is loop-invariant and could be read once
  before the loop. Real N+1, negligible in practice (single-row PK lookups, tag counts are small) —
  correctly filed as Low.
- **Confidence:** 95%
- **Risk calc:** EV = (95% × 1) − (5% × 2 × 1) = 0.95 − 0.1 = +0.85
- **Decision:** ACCEPT (Low, 1 pt)
---

**BUG-23** | Original: 1 pt | Verdict: **CONFIRMED**
- **Counter-argument:** None found.
- **Evidence:** storage_location_registry_resolver.dart:16-33 — when the preferred file is absent and the
  legacy file exists, content is COPIED via `atomicWrite` into the preferred location and the legacy file
  is never deleted, renamed, or compared. Both halves of the claimed divergence follow: later edits to the
  legacy file are silently ignored (preferred.exists() short-circuits at line 24), and if the preferred
  file is later deleted, `resolve()` re-imports the stale legacy content over the newer durable state.
  One-way copy without consuming the source is a genuine dual-source hazard.
- **Confidence:** 85%
- **Risk calc:** EV = (85% × 1) − (15% × 2 × 1) = 0.85 − 0.3 = +0.55
- **Decision:** ACCEPT (Low, 1 pt)
---

**BUG-24** | Original: 1 pt | Verdict: **UNCERTAIN (accepted per EV rule)**
- **Counter-argument:** The inconsistency points in the safe direction (data durable in SQLite, marker
  behind) and is self-healing: a retry `save()` re-runs the whole sequence — wal_checkpoint, manifest
  write, then `markSaved()` (project_session_manager.dart:85-104) — so "a retry loop keeps rewriting only
  the manifest" is inaccurate; a successful retry also re-marks. The residue is a stale manifest/unsaved
  flag only while manifest writes keep failing, during which reporting "unsaved" is arguably correct.
- **Evidence:** Ordering verified: `await ProjectManifestWriter(package).write(updated);` precedes
  `await mutationRuntime.markSaved();` with no decoupling handling. Mechanism true; claimed persistent-retry
  impact does not hold.
- **Confidence:** 55% (real bug)
- **Risk calc:** EV = (55% × 1) − (45% × 2 × 1) = 0.55 − 0.9 = −0.35 → disprove is EV-negative
- **Decision:** ACCEPT (Low, 1 pt)
---

**BUG-25** | Original: 1 pt | Verdict: **CONFIRMED**
- **Counter-argument:** None found.
- **Evidence:** project_session_manager.dart:142-156 — the manifest file is READ and parsed at lines 142-144
  (`ProjectManifest.fromJson(jsonDecode(await package.manifestFile.readAsString()...))`) BEFORE
  `final manifestStarted = DateTime.now();` at line 150; the metric is then recorded immediately at
  151-156. The 'manifest' phase therefore always records ~0 ms — the actual read+parse cost is excluded
  from the open-latency budget the metric exists for. Mechanically indisputable.
- **Confidence:** 95%
- **Risk calc:** EV = (95% × 1) − (5% × 2 × 1) = 0.95 − 0.1 = +0.85
- **Decision:** ACCEPT (Low, 1 pt)
---

**BUG-26** | Original: 1 pt | Verdict: **CONFIRMED** (mechanism) — **SCOPE VIOLATION flagged**
- **Counter-argument:** None found on mechanism.
- **Evidence:** project_recovery_services.dart:156-172 — `BackupRollbackException` carries
  `final Object restoreError;` (line 164) but `toString()` (167-171) renders only
  `rollbackErrors.keys.join(', ')` and `$emergencyBackupPath`; `restoreError` — the root cause that
  triggered the rollback — is never rendered anywhere. Verified against the class's construction sites in
  the same file (restore failure path passes `restoreError` and incomplete-rollback `rollbackErrors`).
  For a no-data-loss diagnostic surface, omitting the original restore failure is a real diagnostic gap.
- **SCOPE FLAG:** project_recovery_services.dart is listed as TRACE-ONLY in hunt-scope-run197.md (read
  "seperlunya untuk verifikasi klaim"), not among the 18 scanned files. The finding is reported against a
  file outside the declared scan scope. Judged here on mechanism merit as instructed; the run's accounting
  should carry the scope exception explicitly.
- **Confidence:** 90%
- **Risk calc:** EV = (90% × 1) − (10% × 2 × 1) = 0.9 − 0.2 = +0.7
- **Decision:** ACCEPT (Low, 1 pt) + scope violation noted
---

## SUMMARY

- Bugs disproved: 4 (BUG-2, BUG-3, BUG-20, BUG-21 — total points claimed: 12)
- Bugs accepted as real: 22 (BUG-1, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 22, 23, 24, 25, 26)
- Of the accepted, flagged UNCERTAIN (accepted only because disproof was EV-negative, not because I could confirm): BUG-4, BUG-11, BUG-14, BUG-15, BUG-18, BUG-19, BUG-24
- Your final score: +12 (all four disproves landed positive EV)

**ACCEPTED BUG LIST (by original severity):**
- Critical (10): BUG-1
- Medium (5 each): BUG-4, BUG-5, BUG-6, BUG-7, BUG-8, BUG-9, BUG-10, BUG-11, BUG-12
- Low (1 each): BUG-13, BUG-14, BUG-15, BUG-16, BUG-17, BUG-18, BUG-19, BUG-22, BUG-23, BUG-24, BUG-25, BUG-26

**Key skeptic notes for the fix queue:**
1. BUG-1 is the highest-value find of the run and survives full adversarial review: the codebase already
   documents the exact errno-32 delete-failure class and built retry ladders for it elsewhere — only the
   creation-marker delete (registry upsert path AND _loadUnlocked admission path, lines 79-85 and 202-206)
   is unguarded, and its caller deletes the entire package on any throw.
2. BUG-2 and BUG-21 were disproven largely by the Hunter's own quoted evidence: the quoted throw is the
   correct non-corruption class, and the quoted loop re-reads tags per iteration so no stale-snapshot
   clobber exists.
3. BUG-20 should not be actioned as a build breaker; at most wrap the web-reachable `exit(0)` callback.
4. BUG-26 counts, but log the scope exception: its file is trace-only in the manifest.

TOTAL REVIEWED: 26
TOTAL DISPROVED: 4
TOTAL CONFIRMED: 15
TOTAL UNCERTAIN: 7
