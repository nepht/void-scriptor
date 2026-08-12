import '../domain/project_model.dart';

class ProjectLocalDataSource {
  final List<ProjectModel> _projects = [];

  Future<List<ProjectModel>> getProjects() async {
    return List.unmodifiable(_projects);
  }

  Future<ProjectModel?> getProject(String projectId) async {
    for (final project in _projects) {
      if (project.id == projectId) return project;
    }
    return null;
  }

  Future<void> createProject(ProjectModel project) async {
    _projects.add(project);
  }

  Future<void> updateProject(ProjectModel project) async {
    final index = _projects.indexWhere((item) => item.id == project.id);
    if (index == -1) return;
    _projects[index] = project;
  }

  Future<void> deleteProject(String projectId) async {
    _projects.removeWhere((project) => project.id == projectId);
  }
}
