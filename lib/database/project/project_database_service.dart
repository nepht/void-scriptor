import 'dart:io';

import 'package:drift/native.dart';

import 'project_database.dart';

class ProjectDatabaseService {
  Future<void> create(String databasePath) async {
    final database = ProjectDatabase(NativeDatabase(File(databasePath)));
    try {
      await database.initialize();
    } finally {
      await database.close();
    }
  }

  Future<ProjectDatabase> open(String databasePath) async {
    final database = ProjectDatabase(NativeDatabase(File(databasePath)));
    await database.initialize();
    return database;
  }
}
