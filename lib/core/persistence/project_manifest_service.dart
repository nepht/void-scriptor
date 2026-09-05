import 'dart:convert';

import 'project_manifest.dart';
import 'project_recovery_service.dart';
import 'project_paths.dart';

class ProjectManifestService {
  ProjectManifestService({
    ProjectPaths? paths,
    ProjectRecoveryService? recovery,
  }) : _paths = paths ?? ProjectPaths(),
       _recovery = recovery ?? const ProjectRecoveryService();
  final ProjectPaths _paths;
  final ProjectRecoveryService _recovery;

  Future<void> write(ProjectManifest manifest) async {
    final file = await _paths.manifest(manifest.id);
    await file.parent.create(recursive: true);
    const encoder = JsonEncoder.withIndent('  ');
    await _recovery.atomicWrite(
      target: file,
      content: '${encoder.convert(manifest.toJson())}\n',
    );
  }

  Future<ProjectManifest> read(String projectId) async {
    final file = await _paths.manifest(projectId);
    // 145.42 power-loss window: pulihkan manifest dari .bak sebelum
    // melempar PathNotFound seolah proyek hilang.
    await _recovery.recoverIfInterrupted(file);
    return ProjectManifest.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
  }
}
