import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final repository = ref.read(projectRepositoryProvider);
    final paths = ref.read(projectPathsProvider);
    final now = DateTime.now();
    ProjectModel? project;
    Directory? createdRoot;

    try {
      final package = await ProjectPackageService(
        rootDirectory: await paths.root(),
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

  Future<void> deleteProject(String projectId) async {
    final repository = ref.read(projectRepositoryProvider);
    await repository.deleteProject(projectId);
    state = AsyncData(await repository.getProjects());
  }
}

final projectControllerProvider =
    AsyncNotifierProvider<ProjectController, List<ProjectModel>>(
      ProjectController.new,
    );

final currentProjectProvider = StateProvider<ProjectModel?>((ref) => null);
