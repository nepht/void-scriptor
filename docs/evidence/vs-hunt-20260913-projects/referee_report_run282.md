# Referee Report: Adversarial Bug Hunt (Projects Feature)

**Target:** `D:\VoidScriptor\void_scriptor_multiplatform\lib\features\projects`  
**Date:** September 13, 2026  
**Referee:** Independent Code Reviewer / Arbiter  

---

## Individual Bug Evaluations

---
**BUG-1**
- **Hunter's claim:** `updateProject` in memory fallback mode silently ignores updates to projects whose IDs are not found in `_memoryProjects`, whereas registry mode performs an upsert.
- **Skeptic's response:** ACCEPT. The claim is valid. In memory fallback mode, `updateProject` uses `_memoryProjects.indexWhere` and only updates if `index != -1`, silently dropping updates for projects not already present in the list, whereas `registry.upsert` performs an upsert. This is a real data-integrity mismatch.
- **Your analysis:** Independent code inspection of `ProjectLocalDataSource.updateProject` in `lib/features/projects/data/project_local_data_source.dart` confirms that when `registry == null`, it checks `_memoryProjects.indexWhere((item) => item.id == project.id)`. If not found (`index == -1`), it takes no action and returns silently. In contrast, `registry.upsert` performs an upsert (insert or update). This creates an inconsistent data-integrity contract between memory fallback mode and registry mode.
- **VERDICT:** REAL BUG
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Update memory fallback mode in `updateProject` to behave as an upsert (i.e., if not found in `_memoryProjects`, add it, matching `createProject`'s memory handling).
---

---
**BUG-2**
- **Hunter's claim:** `openProject` allows concurrent opening requests with differing modes for the same project ID to re-trigger opening operations after awaiting a pending future without proper mutual exclusion.
- **Skeptic's response:** ACCEPT. When `openProject` awaits a pending open and finds that the resulting session's mode does not match the requested mode, it recursively invokes `openProject(projectId, mode: mode)` without proper synchronization across asynchronous boundaries, causing potential race conditions and redundant open/close cycles.
- **Your analysis:** Independent code inspection of `ProjectSessionController.openProject` in `lib/features/projects/presentation/project_persistence_providers.dart` reveals that if `pending != null`, callers await `pending`. If the resulting session's mode does not match the requested mode (e.g., readOnly vs. readWrite), it invokes `openProject(projectId, mode: mode)` recursively after `pending` has cleared. Because `_pendingOpen` is reset in the `finally` block of the first operation, concurrent requests with differing modes can race to re-open the project, leading to redundant open/close cycles and potential state corruption.
- **VERDICT:** REAL BUG
- **Confidence:** High
- **True severity:** Medium
- **Suggested fix:** Implement proper serialization / mutual exclusion for concurrent mode requests or queue conflicting mode requests instead of recursive un-synchronized re-entry.
---

---
**BUG-3**
- **Hunter's claim:** `createdRoot` is assigned after `ProjectPackageService.create` completes, leaving a partially created directory uncleaned if an exception occurs during package initialization prior to assignment.
- **Skeptic's response:** DISPROVE. `ProjectPackageService.create` wraps its directory creation and file initialization in its own `try/catch` block that cleans up `package.root` if any exception occurs. Thus, partial directories are automatically cleaned up inside `ProjectPackageService.create` before any assignment to `createdRoot` in `ProjectController`.
- **Your analysis:** Code inspection of `ProjectPackageService.create` in `lib/core/project_package/project_package_service.dart` shows that directory creation, manifest creation, database creation, and marker writing are all wrapped in a `try / catch (_) { if (await package.root.exists()) { await package.root.delete(recursive: true); } rethrow; }` block. Thus, `ProjectPackageService.create` reliably cleans up its own directory on failure before any return or assignment in `ProjectController`. The Skeptic is correct.
- **VERDICT:** NOT A BUG
- **Confidence:** High
---

---
**BUG-4**
- **Hunter's claim:** `session.close()` is called unawaited within `ref.onDispose`, discarding asynchronous completion and error handling during provider disposal.
- **Skeptic's response:** DISPROVE. In Riverpod, `ref.onDispose` callbacks are strictly synchronous (`void Function()`) and cannot `await` asynchronous functions. Calling `session.close()` unawaited within `ref.onDispose` is standard and correct Riverpod disposal practice.
- **Your analysis:** Code inspection of `ProjectSessionController.build` in `lib/features/projects/presentation/project_persistence_providers.dart` shows `ref.onDispose(() { final session = _session; if (session != null) { session.close(); } });`. In Riverpod 2.x, `ref.onDispose` callbacks are strictly synchronous (`void Function()`) and cannot be asynchronous or `await` futures. Calling `session.close()` unawaited in `ref.onDispose` is standard, idiomatically correct Riverpod disposal practice. The Skeptic is correct.
- **VERDICT:** NOT A BUG
- **Confidence:** High
---

## Final Report Summary

**VERIFIED BUG REPORT**

Stats:
- Total reported by Hunter: 4
- Dismissed as false positives: 2
- Confirmed as real bugs: 2
- Critical: 0 | Medium: 2 | Low: 0

Confirmed bugs (ordered by severity):

| # | Severity | File | Line(s) | Description | Suggested Fix |
|---|----------|------|---------|-------------|---------------|
| BUG-1 | Medium | lib/features/projects/data/project_local_data_source.dart | 38-46 | `updateProject` in memory fallback mode silently ignores updates for projects not already present in `_memoryProjects`. | Implement upsert logic in memory fallback mode (add if not found). |
| BUG-2 | Medium | lib/features/projects/presentation/project_persistence_providers.dart | 86-100 | `openProject` allows concurrent opening requests with differing modes to race and re-trigger opening without mutual exclusion. | Implement proper request serialization or synchronization for concurrent mode requests. |

Low-confidence items (flagged for manual review):
None.
