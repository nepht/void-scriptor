import 'dart:io';

import 'project_manifest.dart';
import 'project_manifest_service.dart';
import 'project_paths.dart';
import '../../database/project/project_database.dart';
import '../../database/project/project_database_service.dart';

/// Sprint 102 / C1 — minimal seam for feeding the opened project's creative
/// terms into a privacy sink. `CrashDiagnostics` satisfies this structurally;
/// core stays free of any bootstrap dependency.
abstract interface class SensitiveTermsSink {
  void updateSensitiveTerms(List<String> terms);
}

class OpenProject {
  const OpenProject({required this.manifest, required this.database});

  final ProjectManifest manifest;
  final ProjectDatabase database;

  Future<void> close() => database.close();
}

class ProjectOpenService {
  ProjectOpenService({ProjectPaths? paths, this.sink})
    : _paths = paths ?? ProjectPaths();

  /// Sprint 102 / C1 — test/alternative-root constructor.
  ProjectOpenService.withRoot(Directory root, {this.sink})
    : _paths = ProjectPaths(rootDirectory: root);

  final ProjectPaths _paths;

  /// Sprint 102 / C1 — receives creative terms of every opened project.
  final SensitiveTermsSink? sink;

  Future<OpenProject> open(String projectId) async {
    final manifest = await ProjectManifestService(
      paths: _paths,
    ).read(projectId);
    if (manifest.id != projectId) {
      throw StateError(
        'Project manifest ID does not match requested project ID',
      );
    }
    final databasePath = await _paths.database(projectId);
    final database = await ProjectDatabaseService().open(databasePath.path);

    // Sprint 102 / C1 — the opened project's creative identity must never
    // reach a crash artifact via interpolated error messages. Best-effort:
    // sink failure never blocks an open.
    try {
      final terms = <String>[manifest.name, ...manifest.tags];
      if (terms.any((t) => t.trim().isNotEmpty)) {
        sink?.updateSensitiveTerms(terms);
      }
    } on Object {
      // Privacy wiring is advisory; opening proceeds regardless.
    }

    return OpenProject(manifest: manifest, database: database);
  }

  /// Sprint 102 / C1 — explicit hook for callers that manage open lifecycle
  /// outside [open]; no-ops without a diagnostics sink.
  void noteOpened(ProjectManifest manifest) {
    try {
      final terms = <String>[manifest.name, ...manifest.tags];
      if (terms.any((t) => t.trim().isNotEmpty)) {
        sink?.updateSensitiveTerms(terms);
      }
    } on Object {
      // Advisory only.
    }
  }
}
