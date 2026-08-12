import 'dart:io';

import 'package:drift/native.dart';

import 'project_database.dart';

Future<ProjectDatabase> openProjectDatabase(String databasePath) async {
  final database = ProjectDatabase(NativeDatabase(File(databasePath)));
  await database.initialize();
  return database;
}

Future<void> createProjectDatabase(String databasePath) async {
  final database = ProjectDatabase(NativeDatabase(File(databasePath)));
  try {
    await database.initialize();
  } finally {
    await database.close();
  }
}
