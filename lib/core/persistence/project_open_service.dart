import 'project_manifest.dart';
import 'project_manifest_service.dart';
import 'project_paths.dart';
import '../../database/project/project_database.dart';
import '../../database/project/project_database_service.dart';

class OpenProject {
  const OpenProject({required this.manifest, required this.database});

  final ProjectManifest manifest;
  final ProjectDatabase database;

  Future<void> close() => database.close();
}

class ProjectOpenService {
  ProjectOpenService({ProjectPaths? paths}) : _paths = paths ?? ProjectPaths();

  final ProjectPaths _paths;

  Future<OpenProject> open(String projectId) async {
    final manifest = await ProjectManifestService(
      paths: _paths,
    ).read(projectId);
    if (manifest.id != projectId) {
      throw StateError(
        'Project manifest ID does not match requested project ID',
      );
    }
    final databasePath = await _paths.database(projectId);
    final database = await ProjectDatabaseService().open(databasePath.path);
    return OpenProject(manifest: manifest, database: database);
  }
}
