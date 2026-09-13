---
**BUG-1** | Severity: [Medium] | Points: [5]
- **File:** lib/features/projects/data/project_local_data_source.dart
- **Line(s):** 38-46
- **Category:** data-integrity
- **Claim:** `updateProject` in memory fallback mode silently ignores updates to projects whose IDs are not found in `_memoryProjects`, whereas registry mode performs an upsert.
- **Evidence:** 
```dart
  Future<void> updateProject(ProjectModel project) async {
    final registry = this.registry;
    if (registry != null) {
      await registry.upsert(project);
      return;
    }
    final index = _memoryProjects.indexWhere((item) => item.id == project.id);
    if (index != -1) _memoryProjects[index] = project;
  }
```
---

---
**BUG-2** | Severity: [Medium] | Points: [5]
- **File:** lib/features/projects/presentation/project_persistence_providers.dart
- **Line(s):** 86-100
- **Category:** concurrency
- **Claim:** `openProject` allows concurrent opening requests with differing modes for the same project ID to re-trigger opening operations after awaiting a pending future without proper mutual exclusion.
- **Evidence:** 
```dart
  Future<ProjectSession> openProject(
    String projectId, {
    ProjectOpenMode mode = ProjectOpenMode.readWrite,
  }) async {
    final pending = _pendingOpen;
    if (pending != null) {
      if (_pendingProjectId == projectId) {
        final session = await pending;
        if (session.mode == mode) return session;
      } else {
        // Serialize project switches; never open two writers concurrently.
        try {
          await pending;
        } catch (_) {
          /* The caller receives its error. */
        }
      }
      return openProject(projectId, mode: mode);
    }
```
---

---
**BUG-3** | Severity: [Low] | Points: [1]
- **File:** lib/features/projects/presentation/project_controller.dart
- **Line(s):** 36-41
- **Category:** error-handling
- **Claim:** `createdRoot` is assigned after `ProjectPackageService.create` completes, leaving a partially created directory uncleaned if an exception occurs during package initialization prior to assignment.
- **Evidence:** 
```dart
      final package = await ProjectPackageService(
        rootDirectory: localPath.isEmpty
            ? await paths.root()
            : Directory(localPath),
      ).create(name: name, description: description);
      createdRoot = package.root;
```
---

---
**BUG-4** | Severity: [Low] | Points: [1]
- **File:** lib/features/projects/presentation/project_persistence_providers.dart
- **Line(s):** 73-78
- **Category:** error-handling
- **Claim:** `session.close()` is called unawaited within `ref.onDispose`, discarding asynchronous completion and error handling during provider disposal.
- **Evidence:** 
```dart
    ref.onDispose(() {
      final session = _session;
      if (session != null) {
        session.close();
      }
    });
```
---

**TOTAL FINDINGS:** 4
**TOTAL SCORE:** 12
