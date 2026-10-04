import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../platform/domain/platform_capability.dart';
import '../../platform/platform_capability_providers.dart';
import '../../../core/persistence/project_move_service.dart';
import '../../../core/project_package/project_package_service.dart';
import '../domain/project_model.dart';
import 'project_persistence_providers.dart';

class ProjectController extends AsyncNotifier<List<ProjectModel>> {
  @override
  Future<List<ProjectModel>> build() {
    return ref.watch(projectRepositoryProvider).getProjects();
  }

  Future<ProjectModel> createProject({
    required String name,
    required String description,
    required String localPath,
  }) async {
    ref
        .read(platformCapabilitiesProvider)
        .require(
          PlatformCapability.localFileSystem,
          action: 'Membuat proyek baru',
        );
    final repository = ref.read(projectRepositoryProvider);
    final paths = ref.read(projectPathsProvider);
    final now = DateTime.now();
    ProjectModel? project;
    Directory? createdRoot;

    try {
      final package = await ProjectPackageService(
        rootDirectory: localPath.isEmpty
            ? await paths.root()
            : Directory(localPath),
      ).create(name: name, description: description);
      createdRoot = package.root;
      project = ProjectModel(
        id: package.projectId,
        name: name,
        description: description,
        createdAt: now,
        updatedAt: now,
        lastOpenedAt: now,
        localPath: package.root.path,
        version: '0.1.0',
      );

      await repository.createProject(project);
      state = AsyncData(await repository.getProjects());
      return project;
    } catch (_) {
      if (createdRoot != null && await createdRoot.exists()) {
        await createdRoot.delete(recursive: true);
      }
      rethrow;
    }
  }

  /// Wiring sprint Task 3 (BUG-7 both halves): first production move path.
  /// Closes the active session for this project first (Windows cannot rename
  /// an open package), relocates the package behind the durable move journal,
  /// and repoints the registry entry via [ProjectRelocationService].
  Future<Directory> moveProject({
    required String projectId,
    required Directory destinationRoot,
  }) async {
    ref
        .read(platformCapabilitiesProvider)
        .require(
          PlatformCapability.localFileSystem,
          action: 'Memindahkan proyek',
        );
    final activeSession = ref.read(projectSessionProvider).value;
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
    final repository = ref.read(projectRepositoryProvider);
    state = AsyncData(await repository.getProjects());
    return moved;
  }

  Future<void> deleteProject(String projectId) async {
    final activeSession = ref.read(projectSessionProvider).value;
    if (activeSession?.package.projectId == projectId) {
      await ref.read(projectSessionProvider.notifier).closeProject();
    }
    final repository = ref.read(projectRepositoryProvider);
    await repository.deleteProject(projectId);
    if (ref.read(currentProjectProvider)?.id == projectId) {
      ref.read(currentProjectProvider.notifier).state = null;
    }
    state = AsyncData(await repository.getProjects());
  }
}

final projectControllerProvider =
    AsyncNotifierProvider<ProjectController, List<ProjectModel>>(
      ProjectController.new,
    );

final currentProjectProvider = StateProvider<ProjectModel?>((ref) => null);
