import '../../database/project/project_database_service.dart';
import '../project_package/void_project_format.dart';
import 'project_manifest_service.dart';
import 'project_paths.dart';

class ProjectHealthReport {
  const ProjectHealthReport({
    required this.projectDirectoryExists,
    required this.manifestExists,
    required this.manifestReadable,
    required this.databaseExists,
    required this.databaseReadable,
    required this.schemaSupported,
  });

  final bool projectDirectoryExists;
  final bool manifestExists;
  final bool manifestReadable;
  final bool databaseExists;
  final bool databaseReadable;
  final bool schemaSupported;

  bool get isHealthy =>
      projectDirectoryExists &&
      manifestExists &&
      manifestReadable &&
      databaseExists &&
      databaseReadable &&
      schemaSupported;
}

class ProjectHealthService {
  ProjectHealthService({ProjectPaths? paths})
    : _paths = paths ?? ProjectPaths();

  final ProjectPaths _paths;

  Future<ProjectHealthReport> check(String projectId) async {
    final project = await _paths.project(projectId);
    final manifest = await _paths.manifest(projectId);
    final database = await _paths.database(projectId);
    var manifestReadable = false;
    var schemaSupported = false;
    var databaseReadable = false;

    if (await manifest.exists()) {
      try {
        final value = await ProjectManifestService(
          paths: _paths,
        ).read(projectId);
        manifestReadable = true;
        // core-hunt-20260906 BUG-01: the app itself writes
        // VoidProjectFormat.currentSchema, so "healthy" must accept the
        // supported range, not just the legacy schema 1 (every current
        // package otherwise reports unhealthy).
        schemaSupported =
            value.schemaVersion >= 1 &&
            value.schemaVersion <= VoidProjectFormat.currentSchema;
      } on Object {
        manifestReadable = false;
      }
    }

    if (await database.exists()) {
      try {
        final opened = await ProjectDatabaseService().open(database.path);
        await opened.close();
        databaseReadable = true;
      } on Object {
        databaseReadable = false;
      }
    }

    return ProjectHealthReport(
      projectDirectoryExists: await project.exists(),
      manifestExists: await manifest.exists(),
      manifestReadable: manifestReadable,
      databaseExists: await database.exists(),
      databaseReadable: databaseReadable,
      schemaSupported: schemaSupported,
    );
  }
}
