import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/persistence/project_file_service.dart';
import '../../../core/persistence/project_manifest.dart';
import '../../../core/persistence/project_manifest_service.dart';
import '../../../database/project/project_database_service.dart';
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
    final id = const Uuid().v4();
    final now = DateTime.now();
    ProjectModel? project;

    try {
      final directory = await ProjectFileService(
        paths: paths,
      ).createStructure(id);
      project = ProjectModel(
        id: id,
        name: name,
        description: description,
        createdAt: now,
        updatedAt: now,
        lastOpenedAt: now,
        localPath: directory.path,
        version: '0.1.0',
      );

      await ProjectManifestService(paths: paths).write(
        ProjectManifest(
          schemaVersion: 1,
          id: id,
          name: name,
          description: description,
          projectVersion: project.version,
          createdAt: now,
          updatedAt: now,
          appVersion: '0.1.0',
        ),
      );
      final database = await paths.database(id);
      await ProjectDatabaseService().create(database.path);
      await repository.createProject(project);
      state = AsyncData(await repository.getProjects());
      return project;
    } catch (_) {
      final directory = await paths.project(id);
      if (await directory.exists()) await directory.delete(recursive: true);
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
