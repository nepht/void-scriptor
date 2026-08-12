// ignore_for_file: deprecated_member_use

import 'package:drift/web.dart';

import 'project_database.dart';

Future<ProjectDatabase> openProjectDatabase(String databasePath) async {
  final database = ProjectDatabase(WebDatabase('void_scriptor_$databasePath'));
  await database.initialize();
  return database;
}

Future<void> createProjectDatabase(String databasePath) async {
  final database = ProjectDatabase(WebDatabase('void_scriptor_$databasePath'));
  await database.initialize();
  await database.close();
}
