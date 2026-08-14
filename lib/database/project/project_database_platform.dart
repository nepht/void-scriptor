import 'project_database.dart';

Future<ProjectDatabase> openProjectDatabase(String databasePath) async {
  throw UnsupportedError('No database backend for this platform');
}

Future<ProjectDatabase> openProjectDatabaseReadOnly(String databasePath) async {
  throw UnsupportedError('Read-only database is unavailable on this platform');
}

Future<void> createProjectDatabase(String databasePath) async {
  throw UnsupportedError('No database backend for this platform');
}

Future<int?> readProjectDatabaseSchemaVersion(String databasePath) async =>
    null;
