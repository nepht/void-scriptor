// ignore_for_file: deprecated_member_use

import 'package:drift/web.dart';

import 'project_database.dart';

Future<ProjectDatabase> openProjectDatabase(String databasePath) async {
  final database = ProjectDatabase(WebDatabase('void_scriptor_$databasePath'));
  await database.initialize();
  return database;
}

Future<ProjectDatabase> openProjectDatabaseReadOnly(String databasePath) async {
  throw UnsupportedError('Read-only database is unavailable on web');
}

Future<void> createProjectDatabase(String databasePath) async {
  final database = ProjectDatabase(WebDatabase('void_scriptor_$databasePath'));
  await database.initialize();
  await database.close();
}

Future<int?> readProjectDatabaseSchemaVersion(String databasePath) async =>
    null;

Future<void> probeProjectDatabaseWrite(String databasePath) async {
  throw UnsupportedError('Write probe is unavailable on web');
}
