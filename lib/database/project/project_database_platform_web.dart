// ignore_for_file: deprecated_member_use

import 'package:drift/web.dart';

import 'project_database.dart';

Future<ProjectDatabase> openProjectDatabase(String databasePath) async {
  // core-hunt run197 BUG-16: initialize used to run without the close-on-
  // failure guard the io seam already had, leaking the WebDatabase wrapper
  // when a drift web initialize (IndexedDB open error mid-migration) threw.
  // The contract now lives once in initializeDatabaseOrClose, shared with io.
  final database = ProjectDatabase(WebDatabase('void_scriptor_$databasePath'));
  return await initializeDatabaseOrClose(database);
}

Future<ProjectDatabase> openProjectDatabaseReadOnly(String databasePath) async {
  throw UnsupportedError('Read-only database is unavailable on web');
}

Future<void> createProjectDatabase(String databasePath) async {
  final database = ProjectDatabase(WebDatabase('void_scriptor_$databasePath'));
  // Same asymmetry as BUG-16: the io seam closes in a finally so a failed
  // initialize never leaks the wrapper; close must run on the failure path.
  try {
    await database.initialize();
  } finally {
    await database.close();
  }
}

Future<int?> readProjectDatabaseSchemaVersion(String databasePath) async =>
    null;

Future<void> probeProjectDatabaseWrite(String databasePath) async {
  throw UnsupportedError('Write probe is unavailable on web');
}
