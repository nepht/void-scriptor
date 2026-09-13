# SKEPTIC REPORT — vs-hunt-20260913-projects
- stage: skeptic (scan-only), model gemini/gemini-3.5-flash-lite, completed 2026-09-13 ~07:25 WIB, 39.4s
- independently read: hunter_report.md, project_controller.dart, project_persistence_providers.dart, create_project_screen.dart, callsite greps (relocateProject/closeProject/moveProject/createProject/localPath/currentProjectProvider/resolvePackageRoot/projectSessionProvider)

## PRJ-BUG-01 — DISPROVE — confidence 95
Closing the active session and clearing currentProjectProvider before ProjectRelocationService.relocateProject is an intentional architectural requirement: Windows file locking prevents renaming/moving directories containing open SQLite database files. Relocation failure propagates the underlying FileSystemException.

## PRJ-BUG-02 — KEEP — confidence 100
ProjectController.createProject accepts required localPath but the body uses await paths.root() for ProjectPackageService and assigns model localPath = package.root.path; the passed parameter is entirely unused.

## PRJ-BUG-03 — DISPROVE — confidence 90
project_persistence_providers.dart ~92-98: awaiting `pending` in try/catch when switching projects (_pendingProjectId != projectId) is standard mutex/serialization logic. The original caller of the pending operation receives its own error when awaiting pending; subsequent callers waiting for it must catch the previous project's error so they can proceed to open their own requested project.

## PRJ-BUG-04 — DISPROVE — confidence 80
resolvePackageRoot (~120-134) is a pure resolver looking up the registered package path; disk-existence verification belongs downstream because _manager.open handles initialization and error propagation when accessing the path.

SKEPTIC DONE
