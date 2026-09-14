# Adversarial Bug Hunt — Hunter Report

Scope: `lib/features/project_resilience` (18 files listed in `scope_files.txt`), scan-only.

---
**BUG-1** | Severity: Critical | Points: 10
- **File:** `lib/features/project_resilience/application/portable_project_service.dart`
- **Line(s):** 227-233
- **Category:** security
- **Claim:** Archive extraction can escape the destination on Windows because the traversal check normalizes only POSIX separators while the archive entry may contain Windows backslashes or drive-qualified paths.
- **Evidence:**
```dart
        final relative = p.posix.normalize(entry.name);
        if (p.isAbsolute(relative) ||
            relative == '..' ||
            relative.startsWith('../')) {
          throw const FormatException('Archive path escapes package');
        }
        final output = File(package.resolve(relative));
```
---

---
**BUG-2** | Severity: Critical | Points: 10
- **File:** `lib/features/project_resilience/application/project_recovery_services.dart`
- **Line(s):** 101-109
- **Category:** concurrency
- **Claim:** A session close can permanently consider the lock released after discovering that the marker belongs to another session, leaving the owned marker state unresolved and allowing teardown to proceed as if exclusivity had been released.
- **Evidence:**
```dart
        final marker = jsonDecode(await package.sessionFile.readAsString());
        if (marker is! Map || marker['sessionId'] != owned) return;
        await _deleteWithTransientRetry(package.sessionFile);
      }
    } on PathNotFoundException {
```
---

---
**BUG-3** | Severity: Critical | Points: 10
- **File:** `lib/features/project_resilience/application/project_recovery_services.dart`
- **Line(s):** 59-62
- **Category:** concurrency
- **Claim:** Dead-owner recovery treats any process with the recorded PID as the session owner, so PID reuse can cause a live unrelated process to be accepted as the project owner and the lock marker to be displaced.
- **Evidence:**
```dart
    final ownerPid = marker['processId'];
    if (ownerPid is! int || ownerPid <= 0 || await _isProcessAlive(ownerPid)) {
      return false;
    }
```
---

---
**BUG-4** | Severity: Critical | Points: 10
- **File:** `lib/features/project_resilience/application/project_recovery_services.dart`
- **Line(s):** 27-34
- **Category:** concurrency
- **Claim:** Lock recovery has a delete-then-create race: another opener can acquire the marker after dead-owner deletion, causing this opener's second exclusive create to fail without retrying or distinguishing the new owner.
- **Evidence:**
```dart
      await package.sessionFile.create(exclusive: true);
    } on FileSystemException {
      if (!await package.sessionFile.exists()) rethrow;
      if (!await _recoverDeadOwnerMarker()) {
        throw StateError('Project has an active or stale session');
      }
      await package.sessionFile.create(exclusive: true);
    }
```
---

---
**BUG-5** | Severity: Critical | Points: 10
- **File:** `lib/features/project_resilience/application/project_recovery_services.dart`
- **Line(s):** 711-715
- **Category:** data-integrity
- **Claim:** Trash restoration writes to the caller-provided path without validating that it is inside the project, so a crafted or corrupted trash record can restore a file outside the project and overwrite an arbitrary path.
- **Evidence:**
```dart
  Future<void> restore(File trashed, String originalPath) async {
    final target = File(originalPath);
    await target.parent.create(recursive: true);
    await trashed.rename(target.path);
  }
```
---

---
**BUG-6** | Severity: Medium | Points: 5
- **File:** `lib/features/project_resilience/application/project_resilience_controller.dart`
- **Line(s):** 37-38, 84-92
- **Category:** data-integrity
- **Claim:** The controller reports a project as portable even when orphan files exist, because the portable predicate omits the orphan-file count.
- **Evidence:**
```dart
  bool get portable =>
      manifestValid && databaseValid && missingFiles == 0 && externalFiles == 0;
```
```dart
    return ProjectResilienceSnapshot(
      integrity: integrity,
      storage: storage,
      backupItems: backupItems,
      trashItems: trashItems,
      orphanPaths: actual.difference(referencedPaths),
      backups: backupRows,
    );
```
---

---
**BUG-7** | Severity: Medium | Points: 5
- **File:** `lib/features/project_resilience/application/project_resilience_controller.dart`
- **Line(s):** 96-104, 290-297
- **Category:** logic
- **Claim:** Backups stored in a configured external root are recorded but omitted from the displayed backup-directory count because the scan only enumerates the package-internal backup directory.
- **Evidence:**
```dart
    final backupItems = (await _backupDirectories()).length;
```
```dart
  Future<List<Directory>> _backupDirectories() async {
    if (!await session.package.backupDirectory.exists()) return const [];
    return session.package.backupDirectory
        .list()
        .where((entity) => entity is Directory)
```
---

---
**BUG-8** | Severity: Medium | Points: 5
- **File:** `lib/features/project_resilience/application/project_resilience_controller.dart`
- **Line(s):** 273-280
- **Category:** data-integrity
- **Claim:** Retention pruning can delete a backup directory before removing its database row, and an interrupted failure leaves the metadata and filesystem inconsistent with no recovery path in this method.
- **Evidence:**
```dart
      final directory = _resolveBackupDirectory(row.relativePath);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
      await repository.removeBackup(victim.id);
```
---

---
**BUG-9** | Severity: Low | Points: 1
- **File:** `lib/features/project_resilience/application/project_version_control_service.dart`
- **Line(s):** 101-106
- **Category:** edge-case
- **Claim:** Version comparison uses shallow reference inequality for decoded nested JSON values, so equal nested maps or lists can be reported as changed.
- **Evidence:**
```dart
      } else if (first.data[key] != second.data[key]) {
        changed[key] = {'before': first.data[key], 'after': second.data[key]};
      }
```
---

---
**BUG-10** | Severity: Medium | Points: 5
- **File:** `lib/features/project_resilience/application/project_backup_restore_flow.dart`
- **Line(s):** 48-55
- **Category:** security
- **Claim:** A relative backup path from persisted metadata is resolved directly under the package without containment validation, allowing `..` paths to select a backup outside the project during restore.
- **Evidence:**
```dart
    final stored = backup.relativePath;
    if (p.isAbsolute(stored)) return Directory(stored);
    return Directory(session.package.resolve(stored));
```
---

**TOTAL FINDINGS:** 10
**TOTAL SCORE:** 71
