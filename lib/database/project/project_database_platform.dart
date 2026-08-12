import 'project_database.dart';

Future<ProjectDatabase> openProjectDatabase(String databasePath) async {
  throw UnsupportedError('No database backend for this platform');
}

Future<void> createProjectDatabase(String databasePath) async {
  throw UnsupportedError('No database backend for this platform');
}
