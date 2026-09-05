import 'dart:convert';
import 'dart:io';

import 'project_manifest.dart';
import 'project_recovery_service.dart';
import 'project_paths.dart';
import '../project_package/void_project_format.dart';

/// The project manifest at [manifestPath] cannot be parsed into a usable
/// manifest. [cause] is the underlying parse/type failure; the corrupt file
/// is preserved on disk for manual inspection.
class ProjectManifestUnreadableException implements Exception {
  ProjectManifestUnreadableException(this.manifestPath, this.cause);

  final String manifestPath;

  /// The underlying content failure (JSON syntax, manifest shape, or the
  /// type error of a field-corrupt manifest).
  final Object cause;

  @override
  String toString() =>
      'ProjectManifestUnreadableException: manifest at $manifestPath '
      'is not a readable project manifest ($cause)';
}

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
    try {
      return await _parse(file);
    } on ProjectManifestUnreadableException {
      // 145.42 corrupt manifest: isi rusak bukan power-loss window. Konten
      // durable terakhir di .bak dipulihkan ke target sebelum kegagalan
      // dilaporkan; tanpa .bak, berkas korut dipertahankan untuk inspeksi.
      final restored = await _recovery.restoreBackup(file);
      if (!restored) rethrow;
      return _parse(file);
    }
  }

  /// Corrupt content (unparsable JSON, wrong shape, field-level type
  /// failures) is reported as [ProjectManifestUnreadableException].
  /// Two deliberate non-corruption contracts are preserved raw:
  /// 1. file-level I/O failures (missing/unreadable manifest) propagate as
  ///    FileSystemException, exactly as before this slice;
  /// 2. an interpretable manifest whose schema is newer than the app keeps
  ///    the raw FormatException compatibility rejection.
  Future<ProjectManifest> _parse(File file) async {
    final Object decoded;
    try {
      decoded = jsonDecode(await file.readAsString());
    } on FileSystemException {
      rethrow;
    } on Object catch (cause) {
      throw ProjectManifestUnreadableException(file.path, cause);
    }
    if (decoded is! Map<String, dynamic>) {
      throw ProjectManifestUnreadableException(
        file.path,
        const FormatException('Project manifest must be a JSON object'),
      );
    }
    final schema = decoded['schemaVersion'];
    if (schema is int && schema > VoidProjectFormat.currentSchema) {
      // Compatibility rejection stays raw: an app-update artifact is an
      // actionable "upgrade required" signal, not corruption.
      return ProjectManifest.fromJson(decoded);
    }
    try {
      return ProjectManifest.fromJson(decoded);
    } on Object catch (cause) {
      throw ProjectManifestUnreadableException(file.path, cause);
    }
  }
}
