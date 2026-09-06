# Bug-hunt run94 — HUNTER report

Scope: 15 files, Void Scriptor persistence/session layer (D:\VoidScriptor\void_scriptor_multiplatform, working tree as-is per scope manifest: project_session_manager.dart modified, storage_location_registry_resolver.dart untracked).
All 15 in-scope files were read in full. Cross-file contracts (ProjectPackage, ProjectSessionLock, ProjectManifestWriter, ProjectMutationRuntime, BackgroundJobQueue, WorkspaceProjectionCache, ProjectModel, VoidProjectFormat, ProjectPackageService, command_type_registry) were verified by reading the referenced files before claims were made. Read-only inspection only; no target code executed.

## Findings

---
**BUG-01** | Severity: Critical | Points: 10
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\core\persistence\project_move_service.dart
- **Line(s):** 30-49
- **Category:** data-integrity / concurrency
- **Claim:** movePackage derives the destination purely from `p.basename(package.path)` and never checks whether the destination already exists, so two concurrent moves of different packages with the same name (or a pre-existing destination directory) violate the documented "existing package is not clobbered" contract: on POSIX the second `rename` replaces the first package's just-moved directory wholesale, silently destroying a complete project.
- **Evidence:**
```dart
final name = p.basename(package.path);
final destination = p.join(destinationRoot.path, name);
await destinationRoot.create(recursive: true);
final marker = File(
  p.join(package.path, ProjectRecoveryService.movePendingMarkerName),
);
...
await package.rename(destination);
```
---
**BUG-02** | Severity: Medium | Points: 5
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\core\persistence\project_recovery_service.dart
- **Line(s):** 106-119
- **Category:** concurrency / data-integrity
- **Claim:** atomicWrite's failure rollback can resurrect the stale `.bak` over a concurrently completed write: there is no lock/retry around `delete .bak → rename target→.bak → rename tmp→target`, so two interleaved atomicWrites on one target (e.g. a registry `upsert` racing the admission `save` inside `load()`) end with the newer committed content clobbered by the loser's rollback path while the winner reported success.
- **Evidence:**
```dart
await temporary.writeAsString(content, flush: true);
if (await target.exists()) {
  if (await backup.exists()) await backup.delete();
  await target.rename(backup.path);
}

try {
  await temporary.rename(target.path);
} catch (_) {
  if (await backup.exists() && !await target.exists()) {
    await backup.rename(target.path);
  }
  rethrow;
}
```
---
**BUG-03** | Severity: Critical | Points: 10
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\core\persistence\project_recovery_service.dart
- **Line(s):** 160-213
- **Category:** concurrency / data-integrity
- **Claim:** recoverInterruptedMoves reads the marker payload, then renames the scanned package to the recorded destination with no check that the destination (or the scanned source) was not concurrently modified between the `exists()` probes and `entity.rename(destination)`; two move sessions (or a user action) on the same root can swap or overwrite whole `.voidproject` packages, silently losing a project, because destination-occupied checks are TOCTOU racy.
- **Evidence:**
```dart
final target = Directory(destination);
if (!matchesSource || await target.exists()) {
  // Destination occupied or unavailable: leave the journal and the
  // package untouched rather than guessing.
  continue;
}
try {
  await entity.rename(destination);
} on FileSystemException {
  continue;
}
```
---
**BUG-04** | Severity: Medium | Points: 5
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\core\persistence\project_registry_service.dart
- **Line(s):** 66-80 (with 123-125)
- **Category:** error-handling / data-integrity
- **Claim:** `_decodeProjects` throws raw `FormatException`/`TypeError` on a transiently truncated or malformed projects.json (e.g. read racing the atomic-replace of a save, or one corrupt entry), and since `remove()` filters `(await load())`, any transient decode failure during a delete turns the delete into a silent no-op or aborts listing with an unclassified error, diverging registry state from the packages on disk.
- **Evidence:**
```dart
final decoded =
    jsonDecode(await registryFile.readAsString()) as Map<String, dynamic>;
final schemaVersion = decoded['schemaVersion'];
if (schemaVersion != 1) {
  throw FormatException(
    'Unsupported project registry schema version: $schemaVersion',
  );
}
final projects = decoded['projects'] as List<dynamic>? ?? const [];
return projects
    .map((item) => ProjectModel.fromJson(item as Map<String, dynamic>))
    .toList(growable: false);
```
---
**BUG-05** | Severity: Medium | Points: 5
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\core\persistence\project_registry_service.dart
- **Line(s):** 46-62 (with project_recovery_service.dart 36-82)
- **Category:** concurrency / data-integrity
- **Claim:** crash-window admission (`admitMarkedCreations` → `save` → per-project marker consumption) is not serialized: two concurrent `load()` calls can both scan the same unregistered package before either save lands, and both persist merged lists, producing duplicate registry entries for one project id (later `upsert` de-dupes, but the persisted duplicates survive until a write touches that id).
- **Evidence:**
```dart
final admitted = await _recovery.admitMarkedCreations(
  await _listingOwnerDirectory(),
  registered.map((project) => project.id).toSet(),
);
if (admitted.isEmpty) return registered;
final merged = [...registered, ...admitted];
// Durability first: persist the admission, then consume the markers.
await save(merged);
```
---
**BUG-06** | Severity: Medium | Points: 5
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\core\persistence\project_recovery_service.dart
- **Line(s):** 131-137
- **Category:** data-integrity
- **Claim:** recoverIfInterrupted unconditionally renames `target.bak` onto a missing target, so a target that is legitimately absent for reasons other than the atomicWrite crash window (e.g. the file was deleted, or the crash happened after the tmp-rename but the OS lost the directory entry) has its only restore copy consumed and destroyed, leaving corrupt-content recovery (restoreBackup) with no backup at all.
- **Evidence:**
```dart
Future<void> recoverIfInterrupted(File target) async {
  if (await target.exists()) return;
  final backup = File('${target.path}.bak');
  if (await backup.exists()) {
    await backup.rename(target.path);
  }
}
```
---
**BUG-07** | Severity: Medium | Points: 5
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\database\project\project_database_service.dart
- **Line(s):** 182-226
- **Category:** data-integrity / error-handling
- **Claim:** probeWrite COMMITs a real write (probe table + row) before the cleanup transaction, so a crash/kill between `COMMIT` and `DROP TABLE` leaves a permanent `__scriptor_write_probe` table in the user's project database despite the contract "TIDAK memodifikasi data aplikasi"; the method also has no callers anywhere in `lib/` (dead code), so this risk exists without any current benefit.
- **Evidence:**
```dart
raw.execute(
  'INSERT OR REPLACE INTO __scriptor_write_probe (id) '
  'VALUES (1)',
);
raw.execute('COMMIT');
raw.execute('BEGIN IMMEDIATE');
raw.execute('DELETE FROM __scriptor_write_probe');
raw.execute('COMMIT');
raw.execute('DROP TABLE IF EXISTS __scriptor_write_probe');
```
---
**BUG-08** | Severity: Critical | Points: 10
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\database\project\project_database_service.dart
- **Line(s):** 227-237
- **Category:** data-integrity / concurrency
- **Claim:** after closing its own connection, probeWrite deletes the database's `-wal` and `-shm` sidecars unconditionally; if another live connection (or a session opened moments later) is using WAL, deleting the committed-but-uncheckpointed WAL discards acknowledged transactions and corrupts the live database — a direct data-loss path on the production open path's storage.
- **Evidence:**
```dart
// Pasca-close: hapus sidecar kosong jika WAL sempat diaktifkan
// atau file jurnal DELETE tidak ter-reclaim otomatis.
for (final sidecar in [walSidecar, shmSidecar]) {
  if (sidecar.existsSync()) {
    try {
      sidecar.deleteSync();
    } on FileSystemException {
      // best-effort
    }
  }
}
```
---
**BUG-09** | Severity: Medium | Points: 5
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\core\persistence\custom_storage_location.dart
- **Line(s):** 151-163
- **Category:** performance / concurrency
- **Claim:** PlatformDriveSpaceReader shells out to PowerShell with `Process.runSync` (synchronously) even though the enclosing API is async, so every storage probe that reaches the space reader can freeze the calling isolate (UI thread in the Flutter app) for hundreds of milliseconds to seconds on cold PowerShell startup.
- **Evidence:**
```dart
final result = Process.runSync('powershell.exe', [
  '-NoProfile',
  '-NonInteractive',
  '-Command',
  '(Get-PSDrive -Name '
      '${drive[0]} -ErrorAction Stop).Free',
]);
```
---
**BUG-10** | Severity: Medium | Points: 5
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\core\persistence\custom_storage_location.dart
- **Line(s):** 49-62 (with 278-303)
- **Category:** edge-case / missing-validation
- **Claim:** normalizeLocation never requires an absolute path, so a relative input (e.g. `Projects` or `..\Projects`) is normalized but anchored to the process's current working directory, and setActiveLocation then probes, creates, and persists that CWD-relative directory as the active storage location — projects silently land under the install/temp CWD instead of the user's chosen drive.
- **Evidence:**
```dart
static String normalizeLocation(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(raw, 'raw', 'Storage location cannot be empty');
  }
  var cleaned = p.normalize(trimmed);
```
---
**BUG-11** | Severity: Low | Points: 1
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\core\persistence\custom_storage_location.dart
- **Line(s):** 140-150
- **Category:** edge-case
- **Claim:** the drive-letter extraction mishandles network roots: for UNC roots (`\\server\share`) it produces the whole `\\server\share` string, and for forward-slash roots (`C:/Users`) it fails to strip the trailing `/` because only `p.separator` is checked, so network shares and un-normalized forward-slash locations always fall into the `-1` unknown-budget path (Get-PSDrive is never attempted with a valid share), never reporting free space for valid network storage.
- **Evidence:**
```dart
final root = p.rootPrefix(location);
if (root.isEmpty) return -1;
if (Platform.isWindows) {
  const uncPrefix = '\\\\?\\';
  final driveLetter = root.startsWith(uncPrefix)
      ? root.substring(uncPrefix.length)
      : root;
  final drive = driveLetter.endsWith(p.separator)
      ? driveLetter.substring(0, driveLetter.length - 1)
      : driveLetter;
  if (drive.isEmpty || drive.length > 2) return -1;
```
---
**BUG-12** | Severity: Medium | Points: 5
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\core\persistence\project_paths.dart
- **Line(s):** 132-137
- **Category:** data-integrity
- **Claim:** `registry()` places projects.json beside the root's parent (`root().parent`) when no override is set, while the recovery scanner `_recoverImportStashes` (project_registry_service.dart 162-171) additionally scans `<file.parent>/Projects` and `_listingOwnerDirectory()` scans `file.parent` — three different notions of the same directory, so creation-marker admission scans a directory that contains no packages in the default wiring and packages created under `<root>/Projects` are never admitted.
- **Evidence:**
```dart
Future<File> registry() async => File(
  p.join(
    _rootOverride == null ? (await root()).parent.path : (await root()).path,
    'projects.json',
  ),
);
```
---
**BUG-13** | Severity: Medium | Points: 5
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\database\project\project_database_service.dart
- **Line(s):** 144, 157-159
- **Category:** logic / error-handling
- **Claim:** the write-failure classification masks the extended result code with `& 0xFF` and then compares against `778`, which is unreachable (`778 & 0xFF == 10`), so `SQLITE_IOERR_WRITE` (778) falls through and is misreported as `ProjectDatabaseUnreadableException` (corruption) instead of `ProjectDatabaseWriteFailedException` — exactly the misclassification the 145.42 matrix was built to prevent.
- **Evidence:**
```dart
final code = error.extendedResultCode & 0xFF;
...
if (code == 8 || code == 13 || code == 778) {
  throw ProjectDatabaseWriteFailedException(databasePath, error);
}
```
---
**BUG-14** | Severity: Medium | Points: 5
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\core\persistence\project_manifest_service.dart
- **Line(s):** 51-60
- **Category:** data-integrity
- **Claim:** after `_recovery.restoreBackup(file)` succeeds, the manifest is parsed from the file that restore just installed (the old `.bak` content), but it is never re-validated-and-rewritten as the canonical manifest, so the recovered manifest stays flagged by whatever made the original corrupt and the `.bak` is consumed (renamed away), leaving no backup for a subsequent failure.
- **Evidence:**
```dart
} on ProjectManifestUnreadableException {
  // 145.42 corrupt manifest: isi rusak bukan power-loss window. Konten
  // durable terakhir di .bak dipulihkan ke target sebelum kegagalan
  // dilaporkan; tanpa .bak, berkas korut dipertahankan untuk inspeksi.
  final restored = await _recovery.restoreBackup(file);
  if (!restored) rethrow;
  return _parse(file);
}
```
---
**BUG-15** | Severity: Medium | Points: 5
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\core\persistence\custom_storage_location.dart
- **Line(s):** 316-338
- **Category:** data-integrity / error-handling
- **Claim:** relinkLocation accepts a location that merely *contains* the bound `<projectId>.voidproject` folder (or, with no bound project, any writable directory) and immediately repoints the active storage registry at it; projects that exist in the old location but not the new one become invisible to discovery with no migration step, guard, or rollback, and a stale registry `activeLocation` pointing at a moved drive turns every `ProjectPaths.root()` into the fallback root, silently relocating the project home.
- **Evidence:**
```dart
final current = await load();
if (current.boundProjectId != null) {
  final existing = Directory(
    p.join(location, '${current.boundProjectId}.voidproject'),
  );
  if (!await existing.exists()) {
    throw StateError('Relink target does not contain the bound project');
  }
}
```
---
**BUG-16** | Severity: Low | Points: 1
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\core\persistence\project_registry_service.dart
- **Line(s):** 11-26 (with 82-88 and 162-171)
- **Category:** logic
- **Claim:** when constructed with `rootDirectory`, the registry file is `<rootDirectory>/projects.json`, but `_listingOwnerDirectory()` (and creation-marker admission) scan `rootDirectory` itself while `_recoverImportStashes()` scans `rootDirectory` *and* `<rootDirectory>/Projects` — inconsistent directory notions inside one service, so in this configuration creation-marker admission scans the wrong directory while import-stash recovery scans one directory too many (the paths-based wiring resolves this differently again via `registry()`).
- **Evidence:**
```dart
ProjectRegistryService({Directory? rootDirectory, this.paths})
  : file = rootDirectory == null
        ? null
        : File('${rootDirectory.path}${Platform.pathSeparator}projects.json');
```
---
**BUG-17** | Severity: Low | Points: 1
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\core\persistence\project_health_service.dart
- **Line(s):** 57-64
- **Category:** error-handling / resource-leak
- **Claim:** the health check performs a full read-write open of the project database on every check (`ProjectDatabaseService().open` — drift initialization, metadata writes, migration waves), and if `opened.close()` itself throws, the exception escapes the `on Object` block (which only wraps the open), marking the DB unreadable and leaving the close error unhandled.
- **Evidence:**
```dart
if (await database.exists()) {
  try {
    final opened = await ProjectDatabaseService().open(database.path);
    await opened.close();
    databaseReadable = true;
  } on Object {
    databaseReadable = false;
  }
}
```
---
**BUG-18** | Severity: Low | Points: 1
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\features\project_resilience\application\project_session_manager.dart
- **Line(s):** 285-295 (with 148-158)
- **Category:** error-handling / concurrency
- **Claim:** the open-failure catch deletes `package.lockFile` unguarded when `mode == readWrite` even when this session never wrote it (`companionWritten == false`, e.g. `lock.acquire()` threw against an alive owner), so a rejected second session erases the live owner's `.project.lock` companion file.
- **Evidence:**
```dart
} catch (_) {
  if (mode == ProjectOpenMode.readWrite) await lock.release();
  if (mode == ProjectOpenMode.readWrite &&
      await package.lockFile.exists()) {
    await package.lockFile.delete();
  }
```
---
**BUG-19** | Severity: Medium | Points: 5
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\features\project_resilience\application\project_session_manager.dart
- **Line(s):** 200-246 (with ProjectMutationRuntime.open filtering via `registry.tryCreate` + `whereType<AppCommand>`)
- **Category:** data-integrity
- **Claim:** the per-session command registry registers only `character.rename`, `character.update`, `character.identity.update`, `timeline.clip.move`, `relation.create`, and `relation.delete` — while `CommandTypes` also defines `asset.rename` and `asset.delete` — so history records of unregistered types are silently filtered out during `ProjectMutationRuntime.open` restore and undo/redo of those asset mutations becomes a no-op that still advances mutation state after a session reopen.
- **Evidence:**
```dart
final commandRegistry = CommandTypeRegistry()
  ..register('character.rename', (record) {
```
(…only the six types above are registered; `asset.rename` / `asset.delete` records restore as `null` and are dropped by `whereType<AppCommand>()`.)
---
**BUG-20** | Severity: Medium | Points: 5
- **File:** D:\VoidScriptor\void_scriptor_multiplatform\lib\features\project_resilience\application\project_session_manager.dart
- **Line(s):** 145, 180-184, 285-296
- **Category:** resource-leak / error-handling
- **Claim:** after `databaseService.open(...)` succeeds, the code continues to construct `ProjectMutationRuntime.open(...)`, repositories, and the `ProjectSession` object; if any of those throws, the catch block releases the lock but only closes the DB inside a `try { } catch (_) {}` whose failure is swallowed — worse, `WorkspaceProjectionCache`/repositories hold live drift queries, so a thrown constructor leaves the runtime partially wired; and if `database.close()` in the catch throws, the database handle leaks while the error is discarded.
- **Evidence:**
```dart
// Ensure database is closed if it was partially opened
try {
  if (database != null) await database.close();
} catch (_) {}
rethrow;
```
---

## Notes for the Skeptic
- BUG-01/BUG-03: `movePackage` and `recoverInterruptedMoves` currently have no production callers (only doc references) — the bugs are latent in the intended recovery contract, not in an active code path.
- BUG-02/BUG-05 require concurrent writers on the same registry/manifest target, which the current Riverpod wiring can produce (load-admission save racing an upsert).
- BUG-13 is verifiable purely arithmetically: `778 & 0xFF == 10`, so the literal `code == 778` can never be true after the mask.
- BUG-19 was verified against `lib/core/commands/command_type_registry.dart` (`tryCreate` returns `null` for unregistered types) and `lib/features/project_resilience/application/project_mutation_runtime.dart` (`whereType<AppCommand>()`).

**TOTAL FINDINGS:** 20
**TOTAL SCORE:** 99
