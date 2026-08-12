import 'project_model.dart';

abstract interface class ProjectRepository {
  Future<List<ProjectModel>> getProjects();
  Future<ProjectModel?> getProject(String projectId);
  Future<void> createProject(ProjectModel project);
  Future<void> updateProject(ProjectModel project);
  Future<void> deleteProject(String projectId);
}
