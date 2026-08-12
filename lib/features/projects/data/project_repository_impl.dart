import '../domain/project_model.dart';
import '../domain/project_repository.dart';
import 'project_local_data_source.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  ProjectRepositoryImpl(this.dataSource);

  final ProjectLocalDataSource dataSource;

  @override
  Future<List<ProjectModel>> getProjects() => dataSource.getProjects();

  @override
  Future<ProjectModel?> getProject(String projectId) =>
      dataSource.getProject(projectId);

  @override
  Future<void> createProject(ProjectModel project) =>
      dataSource.createProject(project);

  @override
  Future<void> updateProject(ProjectModel project) =>
      dataSource.updateProject(project);

  @override
  Future<void> deleteProject(String projectId) =>
      dataSource.deleteProject(projectId);
}
