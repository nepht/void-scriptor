# Bug-hunt run197 — Hunter report (persistence/resilience/database region)

Repo: D:\VoidScriptor\void_scriptor_multiplatform · HEAD b5d8bba · mode: scan-only static analysis.
All 18 in-scope files from hunt-scope-run197.md read fully; trace-only files
(project_recovery_services.dart, project_package*.dart, project_manifest_service.dart,
project_move_service.dart, project_integrity_service.dart, project_mutation_runtime.dart,
project_persistence_providers.dart, drift 2.34.3 internals, ci.yml) read to verify
cross-file claims. No builds/tests were run.

---

**BUG-1** | Severity: Critical | Points: 10
- **File:** lib/core/persistence/project_registry_service.dart (upsert), lib/core/persistence/project_recovery_service.dart (consumeCreationMarker)
- **Line(s):** 202–206 (registry), 130–132 (recovery); verified against lib/core/project_package/project_package_service.dart:59–64
- **Category:** error-handling / data-integrity
- **Claim:** `upsert()` consumes the creation marker with an unguarded `marker.delete()` after the registry save is durable, so a transient FileSystemException (the errno-32 sharing-violation family this repo documents and retries everywhere else) propagates into `ProjectPackageService.create()`'s catch, which deletes the entire fully-created project package (`package.root.delete(recursive: true)`) — permanent loss of a complete project plus a dangling registry entry.
- **Evidence:** `await _recovery.consumeCreationMarker(\n      File(\n        p.join(project.localPath, ProjectRecoveryService.creationMarkerName),\n      ),\n    );` (no try/catch; contrast `_consumeQuietly` at 134–141: "A marker that cannot be removed must not break project listing") and recovery: `Future<void> consumeCreationMarker(File marker) async {\n    if (await marker.exists()) await marker.delete();\n  }`. Caller catch: `} catch (_) {\n      if (await package.root.exists()) {\n        await package.root.delete(recursive: true);\n      }\n      rethrow;\n    }`.
---

**BUG-2** | Severity: Medium | Points: 5
- **File:** lib/database/project/project_database_service.dart
- **Line(s):** 162–172
- **Category:** concurrency / error-handling
- **Category note:** race between the async schema probe and the sync existence re-check
- **Claim:** `open()` probes the schema asynchronously, then re-checks existence with a synchronous `File(databasePath).existsSync()`; a file deleted (or an I/O-failing path) between the two, or an `existsSync()` that swallows an I/O error, reports `ProjectDatabaseUnreadableException` (corruption) for what is actually unavailable storage — the exact misclassification the Data-Safety matrix exists to prevent — and adds synchronous disk I/O on the UI isolate.
- **Evidence:** `final onDisk = await readProjectDatabaseSchemaVersion(databasePath);` … `if (!File(databasePath).existsSync()) {\n      throw ProjectDatabaseUnavailableException(\n        databasePath,\n        StateError('database file does not exist'),\n      );\n    }` (existsSync returns false on swallowed I/O errors, routing permission/IO failures into the "missing" branch of an async/sync racy pair).
---

**BUG-3** | Severity: Medium | Points: 5
- **File:** lib/database/project/daos/asset_dao.dart
- **Line(s):** 154–163 (addTagToAssets), 112–135 (replaceTags)
- **Category:** data-integrity / concurrency
- **Claim:** `addTagToAssets` calls `replaceTags(id, [...existing, normalized])` per asset, and `replaceTags` re-reads the current tags inside the loop; for a single asset listed twice in `assetIds` (or overlapping batches), the second iteration's `getTags` snapshot plus full delete-and-reinsert clobbers the first tag write, silently dropping a tag the caller asked to add.
- **Evidence:** `for (final id in assetIds) {\n        final existing = await getTags(id);\n        await replaceTags(id, [...existing, normalized]);\n      }` combined with `await (delete(assetTagLinks)..where(...)).go(); for (final name in normalized) {...}` — read-modify-full-replace with no set-union and no serialization across the re-read.
---

**BUG-4** | Severity: Medium | Points: 5
- **File:** lib/features/project_resilience/application/durable_draft_journal.dart
- **Line(s):** 52–80 (stage), 195–197 (close)
- **Category:** concurrency / data-integrity
- **Claim:** `close()` only sets a flag and returns immediately; an in-flight `stage()` that passed the `_closed` check before `close()` completes afterwards, re-creating the journal directory and writing an entry the recovery panel then surfaces after the session/owner decided the journal is closed — a post-close resurrection window the flag cannot close.
- **Evidence:** `if (_closed) {\n      throw StateError('journal is closed');\n    }\n    await _dir.create(recursive: true);` (check happens once, before all awaited writes/rename) and `Future<void> close() async {\n    _closed = true;\n  }` — no tracking of outstanding stages, no await.
---

**BUG-5** | Severity: Medium | Points: 5
- **File:** lib/features/project_resilience/application/project_session_manager.dart
- **Line(s):** 112–128
- **Category:** error-handling / resource-leak
- **Claim:** `_close()` performs its teardown steps sequentially with no guarding, so a `lock.release()` or `jobs.dispose()` failure aborts before `database.close()` — leaking the SQLite connection — and also skips the lock-file delete, while the thrown teardown error masks the original close reason.
- **Evidence:** `await jobs.dispose();\n    await database.close();\n    if (mode == ProjectOpenMode.readWrite) {\n      await lock.release();\n      if (await package.lockFile.exists()) {\n        await package.lockFile.delete();\n      }\n    }` — any failure above `database.close()` leaves the DB open forever (session `.close()` is memoized via `_closing`, so a retry never re-runs the remaining steps either).
---

**BUG-6** | Severity: Medium | Points: 5
- **File:** lib/features/project_resilience/application/project_session_manager.dart
- **Line(s):** 319–330
- **Category:** error-handling / resource-leak
- **Claim:** the `open()` catch releases the lock and deletes the companion before closing the database with no per-step guarding, so a `lock.release()` failure (it rethrows retained-marker errors) skips `database.close()` entirely — leaking the connection on every failed open that stumbles in teardown — and the release error replaces the real open error.
- **Evidence:** `} catch (_) {\n      if (mode == ProjectOpenMode.readWrite) await lock.release();\n      if (mode == ProjectOpenMode.readWrite &&\n          companionWritten &&\n          await package.lockFile.exists()) {\n        await package.lockFile.delete();\n      }\n      // Ensure database is closed if it was partially opened\n      try {\n        if (database != null) await database.close();\n      } catch (_) {}\n      rethrow;\n    }` — a throw from `await lock.release()` jumps straight to `rethrow`, never reaching the guarded close.
---

**BUG-7** | Severity: Medium | Points: 5
- **File:** lib/core/persistence/project_recovery_service.dart (contract) / project_registry_service.dart (load path)
- **Line(s):** 200–268 (recoverInterruptedMoves) vs 50–87 (_loadUnlocked)
- **Category:** logic / data-integrity
- **Claim:** the documented move-recovery contract is only half-implemented in production: `ProjectRegistryService._loadUnlocked()` consumes landed move markers but never calls `recoverInterruptedMoves`, which has zero production callers (tests only) — a package killed inside the rename crash window stays stranded at the source, unregistered and invisible, contradicting the "rolls the package forward to the recorded destination" recovery promise.
- **Evidence:** `_loadUnlocked` calls `recoverIfInterrupted`, `_recoverImportStashes`, `_decodeProjectsWithBackupRecovery`, `_consumeLandedMoveMarkers`, and `admitMarkedCreations` — `recoverInterruptedMoves` appears nowhere in `lib/` outside its own definition and doc comments ("rename never ran -> [ProjectRecoveryService.recoverInterruptedMoves] rolls the package forward").
---

**BUG-8** | Severity: Medium | Points: 5
- **File:** lib/features/project_resilience/application/durable_draft_journal.dart
- **Line(s):** 131–164
- **Category:** error-handling
- **Claim:** `pendingEntries()` catches only `FormatException`, but the field casts raise `TypeError` for a syntactically valid JSON file whose `sceneId`/`content`/`stagedAt` hold a non-String, so one malformed entry makes the whole recovery listing throw instead of surfacing a `.corrupt` entry — breaking the no-silent-loss recovery panel for every scene.
- **Evidence:** `final sceneId = decoded['sceneId'] as String?;` / `final content = decoded['content'] as String?;` / `stagedAt: DateTime.tryParse(decoded['stagedAt'] as String? ?? '')` inside `try { ... } on FormatException { ... }` — a cast failure is a `TypeError`, not a `FormatException` (compare `acknowledge()` at 186–190 which correctly catches `on Object`).
---

**BUG-9** | Severity: Medium | Points: 5
- **File:** lib/core/persistence/custom_storage_location.dart
- **Line(s):** 353–439 (setActiveLocation / bindProject / relinkLocation)
- **Category:** concurrency / data-integrity
- **Claim:** the store's read-modify-write flows (`load()` → build state → `_save()`) run without any mutex, so overlapping calls (e.g. activation racing binding) interleave between load and save and clobber each other's field — the exact lost-update class `AsyncMutex` was written for and `ProjectRegistryService` guards against, but this store was never given one.
- **Evidence:** `final current = await load();\n    await _save(\n      CustomStorageLocationState(\n        schemaVersion: 1,\n        activeLocation: location,\n        boundProjectId: current.boundProjectId,\n      ),\n    );` (setActiveLocation) and `final current = await load();\n    await _save(... activeLocation: current.activeLocation, boundProjectId: projectId ...)` (bindProject) — two concurrent calls each save a state built from their own stale `current`, dropping the other's update.
---

**BUG-10** | Severity: Medium | Points: 5
- **File:** lib/core/persistence/project_health_service.dart
- **Line(s):** 64–72
- **Category:** logic / data-integrity
- **Claim:** the "health check" opens the project's real production database through `ProjectDatabaseService().open()`, whose first open runs drift migrations and `initialize()`'s `project_metadata` upsert — so a diagnostic read mutates the project under test, can report a healthy project as `databaseReadable=false` when the app already holds the DB open (SQLITE_BUSY), and collapses every typed failure (locked / too-new / unavailable / write-failed) into a single boolean with `on Object`.
- **Evidence:** `final opened = await ProjectDatabaseService().open(database.path);\n        await opened.close();\n        databaseReadable = true;\n      } on Object {\n        databaseReadable = false;\n      }` — `open()` is the migrating, metadata-writing production path, not a read-only probe.
---

**BUG-11** | Severity: Medium | Points: 5
- **File:** lib/database/project/project_database_service.dart
- **Line(s):** 126–155
- **Category:** logic / error-handling
- **Claim:** `classifyProjectDatabaseOpenError` compares extended result codes with unmasked equality (5/8/13/778/14) and only special-cases primary IOERR (10), so extended variants of handled families — e.g. SQLITE_BUSY_SNAPSHOT (517) / SQLITE_BUSY_RECOVERY (261), primary 5, or SQLITE_LOCKED_SHAREDCACHE (262), primary 6 which is not handled at all — fall through to `ProjectDatabaseUnreadableException` (corruption), the same class of bug run94 BUG-13 claims was fixed.
- **Evidence:** `if (error.extendedResultCode == 5) {\n    return ProjectDatabaseLockedException(databasePath, error);\n  }` … `if (error.extendedResultCode == 778 ||\n      error.resultCode == 10 /* SQLITE_IOERR */ ) {` — no `& 0xFF` family comparison and no primary-5/6/13/14 fallback despite the doc: "Family decisions use the **unmasked** extended result code".
---

**BUG-12** | Severity: Medium | Points: 5
- **File:** lib/features/project_resilience/application/project_session_manager.dart
- **Line(s):** 41–48 (type), verified zero consumers in lib/
- **Category:** logic / other (dead typed contract)
- **Claim:** `ProjectLockedException` is thrown for passphrase-locked projects with the documented promise "The caller (UI) should prompt for the passphrase and retry", but no code in `lib/` references the type — the UI cannot catch it specifically, so locked projects always surface as a generic open failure and the prompt-and-retry flow does not exist.
- **Evidence:** `class ProjectLockedException implements Exception { ... }` with `throw ProjectLockedException(package.projectId);` at line 217; repo-wide grep for `ProjectLockedException` matches only project_session_manager.dart.
---

**BUG-13** | Severity: Low | Points: 1
- **File:** lib/features/project_resilience/application/project_session_manager.dart
- **Line(s):** 199–203
- **Category:** error-handling
- **Claim:** the read-only branch calls `databaseService.openReadOnly(...)` directly, bypassing `open()`'s `FileSystemException`/`SqliteException` classification wrapper, so a missing, corrupt, or BUSY database on the read-only path leaks a raw `SqliteException` to the UI instead of the typed `ProjectDatabaseUnavailableException`/`LockedException`/`UnreadableException` family.
- **Evidence:** `database = mode == ProjectOpenMode.readOnly\n          ? await databaseService.openReadOnly(package.databaseFile.path)\n          : await databaseService.open(package.databaseFile.path);` — only the `open()` leg is wrapped by the try/catch classification; `openReadOnly` delegates straight to the platform seam.
---

**BUG-14** | Severity: Low | Points: 1
- **File:** lib/core/persistence/project_paths.dart
- **Line(s):** 174–179
- **Category:** logic / data-integrity
- **Claim:** `registry()` places projects.json beside the override root only when `_rootOverride != null`, but beside `root().parent` when a custom storage store is active — so the same `ProjectPaths` instance can resolve the registry to two different directories depending on which path was configured, splitting the registry across locations after a configuration change.
- **Evidence:** `Future<File> registry() async => File(\n    p.join(\n      _rootOverride == null ? (await root()).parent.path : (await root()).path,\n      'projects.json',\n    ),\n  );` while `root()` itself returns the custom location (not its parent) when the store is healthy.
---

**BUG-15** | Severity: Low | Points: 1
- **File:** lib/database/project/project_database_service.dart
- **Line(s):** 221–233
- **Category:** error-handling
- **Claim:** `probeWrite()` only translates `SqliteException` into the typed write-failure state, so on web — where the platform seam throws `UnsupportedError('Write probe is unavailable on web')` — the raw error escapes instead of a typed domain failure, inconsistent with every other probe surface.
- **Evidence:** `try {\n      await probeProjectDatabaseWrite(databasePath);\n    } on sqlite.SqliteException catch (error) { ... }` vs the seam's `Future<void> probeProjectDatabaseWrite(String databasePath) async {\n  throw UnsupportedError('Write probe is unavailable on web');\n}`.
---

**BUG-16** | Severity: Low | Points: 1
- **File:** lib/database/project/project_database_platform_web.dart
- **Line(s):** 7–11
- **Category:** resource-leak
- **Claim:** web `openProjectDatabase` has no close-on-initialization-failure, so a throw from `database.initialize()` leaks the opened WebDatabase connection, unlike the io counterpart's try/catch-close.
- **Evidence:** `final database = ProjectDatabase(WebDatabase('void_scriptor_$databasePath'));\n  await database.initialize();\n  return database;` — no try/catch (compare platform_io.dart lines 10–16).
---

**BUG-17** | Severity: Low | Points: 1
- **File:** lib/core/persistence/custom_storage_location.dart
- **Line(s):** 236–249
- **Category:** logic / error-handling
- **Claim:** the write probe classifies a failed `.vs_write_probe` *delete* as `permissionDenied`/not-writable even though the write succeeded, so a transient sharing violation on cleanup makes a healthy location report as unwritable.
- **Evidence:** `await probeFile.writeAsString('ok', flush: true);\n      await probeFile.delete();\n    } on FileSystemException {\n      writable = false;\n    }` — both write and delete failures share the same `writable = false` → `StorageProbeReason.permissionDenied` outcome.
---

**BUG-18** | Severity: Low | Points: 1
- **File:** lib/core/persistence/project_paths.dart
- **Line(s):** 76–97
- **Category:** logic
- **Claim:** `root()` sets a `missingDrive` fallback notice even when no custom location was ever configured (`activeLocation == null` but a store exists — the default composition in project_persistence_providers), producing a false "projects are written to fallback because the configured drive is missing" warning for a plain default setup.
- **Evidence:** `final active = state.activeLocation;\n      if (active != null && state.status == StorageLocationStatus.healthy) { ... return custom; }\n      // core-hunt-20260906 BUG-12 ...\n      lastFallbackNotice = StorageFallbackNotice(\n        reason: StorageFallbackReason.missingDrive,\n        requestedLocation: active, ...)` — the notice branch also runs when `active == null` (nothing configured), and `requestedLocation` is then null.
---

**BUG-19** | Severity: Low | Points: 1
- **File:** lib/core/persistence/project_registry_service.dart
- **Line(s):** 96–106 (with 209–213)
- **Category:** edge-case / data-integrity
- **Claim:** the corruption-recovery path restores the previous durable `.bak` before reporting, but a `.bak` written before a successful `remove()` means a deleted project is resurrected into the registry by the very recovery step designed to prevent loss — deletion is not represented anywhere in the `.bak` recovery contract.
- **Evidence:** `} on ProjectRegistryUnreadableException {\n      final restored = await _recovery.restoreBackup(file);\n      if (!restored) rethrow;\n      return _decodeProjects(file);\n    }` — `restoreBackup` unconditionally restores the last durable copy, which may predate `remove(projectId)`.
---

**BUG-20** | Severity: Low | Points: 1
- **File:** lib/main.dart (verified via trace for the in-scope platform-seam history)
- **Line(s):** 1 (and 71); .github/workflows/ci.yml:86–87
- **Category:** other / build
- **Claim:** the web entrypoint imports `dart:io` (`exit()`), while CI builds `flutter build web --release` and the in-scope commit 0c238ba (145.44) restructured the database seam specifically to "keep sqlite3 ffi behind the platform seam" for that same CI web build — either the web build is broken on master or that CI step is not gating, and the in-scope seam work protects only part of the web surface. (Not verifiable here without running a build; flagged for a one-command check.)
- **Evidence:** `import 'dart:io' show exit;` in lib/main.dart (untouched since Sprint 101 d8d5e68, incl. adoption wave 5efa2bd) alongside `- name: Build Web release\n        run: flutter build web --release` in ci.yml, and 0c238ba's commit-scoped files: project_database_platform.dart/io/web + project_database_service.dart.
---

**BUG-21** | Severity: Low | Points: 1
- **File:** lib/database/project/daos/asset_dao.dart
- **Line(s):** 158–161
- **Category:** logic
- **Claim:** `addTagToAssets` appends the new tag to the tail of the existing tag list (`[...existing, normalized]`) instead of a set union, so re-adding an already-present tag duplicates it in the list passed to `replaceTags` (which then re-normalizes via a set — masking it only because replaceTags dedupes; any consumer of the intermediate list or change in normalization silently yields duplicates).
- **Evidence:** `await replaceTags(id, [...existing, normalized]);` with no `existing.contains` guard.
---

**BUG-22** | Severity: Low | Points: 1
- **File:** lib/database/project/daos/asset_dao.dart
- **Line(s):** 121–133
- **Category:** performance
- **Claim:** `replaceTags` performs an N+1 — `await getById(assetId)` inside the per-tag loop inside the transaction — re-querying the same asset row once per tag to fetch a constant projectId.
- **Evidence:** `for (final name in normalized) {\n        final id = '${assetId}_tag_$name';\n        await into(tags).insertOnConflictUpdate(\n          TagsCompanion.insert(\n            id: id,\n            projectId: (await getById(assetId))?.projectId ?? '',\n            name: name,\n          ),\n        );` — projectId is loop-invariant.
---

**BUG-23** | Severity: Low | Points: 1
- **File:** lib/core/persistence/storage_location_registry_resolver.dart
- **Line(s):** 24–32
- **Category:** data-integrity
- **Claim:** `resolve()` copies the legacy storage_locations.json into the new location but never consumes, renames, or compares it, so edits to the legacy file after migration are silently ignored (or, if the preferred file is later deleted, recovery resurrects the stale legacy content) — a permanent dual-source divergence.
- **Evidence:** `if (await legacyFile.exists()) {\n      await const ProjectRecoveryService().atomicWrite(\n        target: preferred,\n        content: await legacyFile.readAsString(),\n      );\n    }\n    return preferred;` — no delete/rename/archive of `legacyFile`.
---

**BUG-24** | Severity: Low | Points: 1
- **File:** lib/features/project_resilience/application/project_session_manager.dart
- **Line(s):** 85–104
- **Category:** error-handling / data-integrity
- **Claim:** `save()` checkpoints the WAL, rewrites the manifest, and only then calls `markSaved()`; a manifest write failure leaves the durable `savedMutationSequence` marker behind the already-durable database state, so a reopened session reports unsaved changes for data that is actually saved and a retry loop (autosave) keeps rewriting only the manifest.
- **Evidence:** `await ProjectManifestWriter(package).write(updated);\n    await mutationRuntime.markSaved();` — no handling that decouples manifest failure from the saved-sequence marker.
---

**BUG-25** | Severity: Low | Points: 1
- **File:** lib/features/project_resilience/application/project_session_manager.dart
- **Line(s):** 149–156
- **Category:** other (telemetry)
- **Claim:** the `manifest` open metric is recorded after the manifest read with a wall-clock delta measured across adjacent statements, so it records a ~0 ms value and reports the manifest phase as free, making the metric meaningless for the open-latency budget it exists for.
- **Evidence:** `final manifestStarted = DateTime.now();\n    metrics.record(\n      'manifest',\n      Duration(\n        milliseconds: DateTime.now().difference(manifestStarted).inMilliseconds,\n      ),\n    );` — recorded immediately after `ProjectManifest.fromJson(jsonDecode(await package.manifestFile.readAsString()...))`, measuring nothing.
---

**BUG-26** | Severity: Low | Points: 1
- **File:** lib/features/project_resilience/application/project_recovery_services.dart (trace-only; exception defined and propagated by in-scope restore flow)
- **Line(s):** 167–172
- **Category:** error-handling
- **Claim:** `BackupRollbackException.toString()` omits `restoreError` — the original restore failure — so the no-data-loss diagnostic surface of the full-payload rollback reports only which areas failed to roll back and never the root cause that triggered the rollback.
- **Evidence:** `String toString() =>\n      'BackupRollbackException: restore failed and rollback is incomplete '\n      'for ${rollbackErrors.keys.join(', ')}. Emergency backup retained at '\n      '$emergencyBackupPath';` — `final Object restoreError;` is carried but never rendered.

---

**TOTAL FINDINGS:** 26
**TOTAL SCORE:** 79
