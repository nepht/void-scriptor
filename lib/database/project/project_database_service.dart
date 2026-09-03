import 'project_database.dart';
import 'project_database_platform.dart'
    if (dart.library.io) 'project_database_platform_io.dart'
    if (dart.library.js_interop) 'project_database_platform_web.dart';

/// Sprint 145.33 future-schema guard: opening a database whose user_version
/// is NEWER than [ProjectDatabase.currentSchemaVersion] would let the drift
/// migration wave rewrite and silently downgrade a file produced by a newer
/// schema. The production open path therefore refuses the file outright so
/// the user can upgrade the application first.
class SchemaVersionTooNewException implements Exception {
  SchemaVersionTooNewException(this.actualVersion, this.supportedVersion);

  final int actualVersion;
  final int supportedVersion;

  @override
  String toString() =>
      'SchemaVersionTooNewException: database schema v$actualVersion is '
      'newer than the supported v$supportedVersion; upgrade the '
      'application before opening this project';
}

class ProjectDatabaseService {
  Future<void> create(String databasePath) =>
      createProjectDatabase(databasePath);

  Future<ProjectDatabase> open(String databasePath) async {
    final onDisk = await readProjectDatabaseSchemaVersion(databasePath);
    if (onDisk != null && onDisk > ProjectDatabase.currentSchemaVersion) {
      throw SchemaVersionTooNewException(
        onDisk,
        ProjectDatabase.currentSchemaVersion,
      );
    }
    return openProjectDatabase(databasePath);
  }

  Future<ProjectDatabase> openReadOnly(String databasePath) =>
      openProjectDatabaseReadOnly(databasePath);

  Future<int?> schemaVersion(String databasePath) =>
      readProjectDatabaseSchemaVersion(databasePath);
}
