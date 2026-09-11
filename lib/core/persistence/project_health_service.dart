import 'dart:io';

import '../../database/project/project_database.dart';
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
    this.databaseFailure,
  });

  final bool projectDirectoryExists;
  final bool manifestExists;
  final bool manifestReadable;
  final bool databaseExists;
  final bool databaseReadable;
  final bool schemaSupported;

  /// core-hunt run197 BUG-10: the typed reason the database probe failed
  /// (e.g. [SchemaVersionTooNewException], ProjectDatabaseLockedException,
  /// ProjectDatabaseUnavailableException, ProjectDatabaseWriteFailedException,
  /// ProjectDatabaseUnreadableException), or null when the probe succeeded
  /// or no database file exists. The booleans above stay as the coarse
  /// health signal; this field preserves WHICH failure the 145.42 matrix
  /// already classifies instead of collapsing it into one flag.
  final Object? databaseFailure;

  bool get isHealthy =>
      projectDirectoryExists &&
      manifestExists &&
      manifestReadable &&
      databaseExists &&
      databaseReadable &&
      schemaSupported &&
      // core-hunt run197 BUG-10: a typed probe failure (e.g. future
      // schema, lock, write-media refusal) means unhealthy even when the
      // coarse booleans above stay green - the file opened fine but the
      // package is not safe to use.
      databaseFailure == null;
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
    Object? databaseFailure;

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
      // core-hunt run197 BUG-10: probe through the read-only seam. The
      // production open path runs drift migrations plus initialize()'s
      // unconditional project_metadata upsert, so the old diagnostic
      // silently rewrote the project it was only inspecting (proven by
      // test: sabotaged metadata was rewritten during a "health check").
      // openReadOnly() opens with OpenMode.readOnly and migrations
      // disabled - it cannot create sidecars, write metadata, or mutate
      // the file in any way. Failures keep their typed classes from the
      // shared classification wrapper instead of collapsing into one
      // boolean.
      //
      // The future-schema guard that open() enforced is applied here via
      // the read-only PRAGMA reader (openReadOnly itself is version-
      // blind). A future-schema database stays databaseReadable=true -
      // the file opens and reads fine as SQLite - but the typed
      // SchemaVersionTooNewException is reported and isHealthy is false.
      try {
        final onDiskVersion = await ProjectDatabaseService().schemaVersion(
          database.path,
        );
        if (onDiskVersion != null &&
            onDiskVersion > ProjectDatabase.currentSchemaVersion) {
          databaseFailure = SchemaVersionTooNewException(
            onDiskVersion,
            ProjectDatabase.currentSchemaVersion,
          );
        }
        final opened = await ProjectDatabaseService().openReadOnly(
          database.path,
        );
        await opened.close();
        databaseReadable = true;
      } on FileSystemException catch (error) {
        databaseFailure ??= ProjectDatabaseUnavailableException(
          database.path,
          error,
        );
      } on SchemaVersionTooNewException catch (error) {
        databaseFailure ??= error;
      } on ProjectDatabaseUnavailableException catch (error) {
        databaseFailure ??= error;
      } on ProjectDatabaseLockedException catch (error) {
        databaseFailure ??= error;
      } on ProjectDatabaseWriteFailedException catch (error) {
        databaseFailure ??= error;
      } on ProjectDatabaseUnreadableException catch (error) {
        databaseFailure ??= error;
      } on Object catch (error) {
        // Last resort for an unexpected engine failure: record it typed
        // instead of discarding it, but keep the coarse boolean contract.
        databaseFailure ??= ProjectDatabaseUnreadableException(
          database.path,
          error,
        );
      }
    }

    return ProjectHealthReport(
      projectDirectoryExists: await project.exists(),
      manifestExists: await manifest.exists(),
      manifestReadable: manifestReadable,
      databaseExists: await database.exists(),
      databaseReadable: databaseReadable,
      schemaSupported: schemaSupported,
      databaseFailure: databaseFailure,
    );
  }
}
