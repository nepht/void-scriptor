import '../../../core/persistence/project_registry_service.dart';
import '../domain/project_model.dart';

class ProjectLocalDataSource {
  ProjectLocalDataSource({this.registry});

  final ProjectRegistryService? registry;
  final List<ProjectModel> _memoryProjects = [];

  Future<List<ProjectModel>> getProjects() async {
    final registry = this.registry;
    if (registry != null) return registry.load();
    return List.unmodifiable(_memoryProjects);
  }

  Future<ProjectModel?> getProject(String projectId) async {
    final projects = await getProjects();
    for (final project in projects) {
      if (project.id == projectId) return project;
    }
    return null;
  }

  Future<void> createProject(ProjectModel project) async {
    final registry = this.registry;
    if (registry != null) {
      await registry.upsert(project);
    } else {
      final index = _memoryProjects.indexWhere((item) => item.id == project.id);
      if (index == -1) {
        _memoryProjects.add(project);
      } else {
        _memoryProjects[index] = project;
      }
    }
  }

  Future<void> updateProject(ProjectModel project) async {
    final registry = this.registry;
    if (registry != null) {
      await registry.upsert(project);
      return;
    }
    // vs-hunt-20260913-projects BUG-1: registry mode upserts, so the memory
    // fallback must apply the same contract — an unknown id is added rather
    // than silently dropped.
    final index = _memoryProjects.indexWhere((item) => item.id == project.id);
    if (index != -1) {
      _memoryProjects[index] = project;
    } else {
      _memoryProjects.add(project);
    }
  }

  Future<void> deleteProject(String projectId) async {
    final registry = this.registry;
    if (registry != null) {
      await registry.remove(projectId);
    } else {
      _memoryProjects.removeWhere((project) => project.id == projectId);
    }
  }
}
