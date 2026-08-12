import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/project_local_data_source.dart';
import '../data/project_repository_impl.dart';
import '../domain/project_model.dart';
import '../domain/project_repository.dart';

final projectLocalDataSourceProvider = Provider<ProjectLocalDataSource>(
  (ref) => ProjectLocalDataSource(),
);

final projectRepositoryProvider = Provider<ProjectRepository>(
  (ref) => ProjectRepositoryImpl(ref.watch(projectLocalDataSourceProvider)),
);

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
    final now = DateTime.now();
    final id = const Uuid().v4();
    final project = ProjectModel(
      id: id,
      name: name,
      description: description,
      createdAt: now,
      updatedAt: now,
      lastOpenedAt: now,
      localPath: '$localPath/$id',
      version: '0.1.0',
    );

    final projectDirectory = Directory(project.localPath);
    await projectDirectory.create(recursive: true);
    await Directory('${project.localPath}/assets').create(recursive: true);
    await Directory('${project.localPath}/characters').create(recursive: true);
    await Directory('${project.localPath}/story').create(recursive: true);
    await File('${project.localPath}/project.json').writeAsString(
      jsonEncode({
        'schemaVersion': 1,
        'id': project.id,
        'name': project.name,
        'description': project.description,
        'version': project.version,
        'createdAt': project.createdAt.toIso8601String(),
        'updatedAt': project.updatedAt.toIso8601String(),
        'application': {'name': 'Void Scriptor', 'version': '0.1.0'},
      }),
    );
    await repository.createProject(project);
    state = AsyncData(await repository.getProjects());
    return project;
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
