# HUNTER REPORT — vs-hunt-20260913-projects
- repo: D:\VoidScriptor\void_scriptor_multiplatform, branch master, HEAD 648d9bff034eab678fbab3b7109e2f41db20995b
- scope: 10 files lib/features/projects/ (1037 lines), fingerprints in scope_hashes.txt
- stage: hunter (scan-only), model gemini/gemini-3.5-flash-lite, completed 2026-09-13 07:2x WIB

TOTAL FINDINGS: 4
TOTAL SCORE: 12

## PRJ-BUG-01 — data-integrity — Medium — 5 pts
- file: lib/features/projects/presentation/project_controller.dart, lines 76-88
- claim: moveProject closes the active session and clears currentProjectProvider BEFORE ProjectRelocationService.relocateProject executes, leaving the project detached if relocation fails.
- evidence quote:
  final activeSession = ref.read(projectSessionProvider).valueOrNull;
  if (activeSession?.package.projectId == projectId) {
    await ref.read(projectSessionProvider.notifier).closeProject();
  }
  if (ref.read(currentProjectProvider)?.id == projectId) {
    ref.read(currentProjectProvider.notifier).state = null;
  }
  final registry = ref.read(projectRegistryServiceProvider);
  final moved = await ProjectRelocationService(
    registry: registry,
  ).relocateProject(projectId: projectId, destinationRoot: destinationRoot);

## PRJ-BUG-02 — logic — Low — 1 pt
- file: lib/features/projects/presentation/project_controller.dart, lines 20-27
- claim: The localPath parameter passed to ProjectController.createProject is completely ignored in favor of await paths.root().
- evidence quote:
  Future<ProjectModel> createProject({
    required String name,
    required String description,
    required String localPath,
  }) async {
    ...
    final package = await ProjectPackageService(
      rootDirectory: await paths.root(),
    ).create(name: name, description: description);

## PRJ-BUG-03 — error-handling — Medium — 5 pts
- file: lib/features/projects/presentation/project_persistence_providers.dart, lines 96-105
- claim: openProject catches and swallows errors from a pending open of a DIFFERENT project, masking concurrency errors.
- evidence quote:
  try {
    await pending;
  } catch (_) {
    /* The caller receives its error. */
  }

## PRJ-BUG-04 — edge-case — Low — 1 pt
- file: lib/features/projects/presentation/project_persistence_providers.dart, lines 136-146
- claim: resolvePackageRoot returns entry.localPath from the registry without verifying whether the directory actually exists on disk.
- evidence quote:
  for (final entry in entries) {
    if (entry.id == projectId && entry.localPath.isNotEmpty) {
      return entry.localPath;
    }
  }
