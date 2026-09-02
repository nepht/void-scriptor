import 'dart:io';

import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'project_database.dart';

Future<ProjectDatabase> openProjectDatabase(String databasePath) async {
  final database = ProjectDatabase(NativeDatabase(File(databasePath)));
  try {
    await database.initialize();
    return database;
  } catch (_) {
    await database.close();
    rethrow;
  }
}

Future<ProjectDatabase> openProjectDatabaseReadOnly(String databasePath) async {
  final raw = sqlite.sqlite3.open(databasePath, mode: sqlite.OpenMode.readOnly);
  final database = ProjectDatabase(
    NativeDatabase.opened(raw, enableMigrations: false),
  );
  await database.customSelect('SELECT 1').getSingle();
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

Future<int?> readProjectDatabaseSchemaVersion(String databasePath) async {
  final file = File(databasePath);
  if (!await file.exists()) return null;
  final database = sqlite.sqlite3.open(
    databasePath,
    mode: sqlite.OpenMode.readOnly,
  );
  try {
    return database.select('PRAGMA user_version').single['user_version']
        as int?;
  } on sqlite.SqliteException {
    // Sprint 145.40: a corrupt database is reported as unreadable
    // (null) instead of crashing the caller that only probes the
    // schema version.
    return null;
  } finally {
    database.close();
  }
}
