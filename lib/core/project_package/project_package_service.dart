import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../persistence/project_manifest.dart';
import '../persistence/project_recovery_service.dart';

import '../../database/project/project_database_service.dart';
import 'project_package.dart';
import 'project_package_paths.dart';
import 'void_project_format.dart';

class ProjectPackageService {
  ProjectPackageService({
    required this.rootDirectory,
    this.appVersion = VoidProjectFormat.applicationVersion,
  });

  final Directory rootDirectory;
  final String appVersion;

  Future<ProjectPackage> create({
    required String name,
    String description = '',
  }) async {
    final id = const Uuid().v4();
    final package = ProjectPackage(
      projectId: id,
      root: Directory(p.join(rootDirectory.path, '$id.voidproject')),
    );
    final now = DateTime.now().toUtc();
    final manifest = ProjectManifest(
      schemaVersion: VoidProjectFormat.currentSchema,
      id: id,
      name: name,
      description: description,
      projectVersion: appVersion,
      createdAt: now,
      updatedAt: now,
      appVersion: appVersion,
    );
    try {
      await _createDirectories(package);
      // 145.42 crash-window marker: staged BEFORE the database so a
      // process kill / power loss between a finished package and its
      // registry registration leaves an explicit admission signal. A
      // package without this marker is deliberately unregistered state
      // (e.g. a deleted project's folder) and is never resurrected.
      await File(
        p.join(package.root.path, ProjectRecoveryService.creationMarkerName),
      ).writeAsString(_encode(manifest), flush: true);
      await ProjectDatabaseService().create(package.databaseFile.path);
      await package.manifestFile.writeAsString(_encode(manifest));
      // The marker intentionally SURVIVES create(): the real crash window is
      // between this return and the caller's registry registration. A kill
      // there is recovered from the marker by ProjectRegistryService.load()
      // / upsert(); the folder cleanup below only runs on thrown errors.
      return package;
    } catch (_) {
      if (await package.root.exists()) {
        await package.root.delete(recursive: true);
      }
      rethrow;
    }
  }

  Future<void> _createDirectories(ProjectPackage package) async {
    final directories = <Directory>[
      package.root,
      package.manifestDirectory,
      package.databaseDirectory,
      package.assetsDirectory,
      package.cacheDirectory,
      package.backupDirectory,
      package.exportDirectory,
      package.recoveryDirectory,
      package.trashDirectory,
      ProjectPackagePaths.images(package),
      ProjectPackagePaths.references(package),
      ProjectPackagePaths.audio(package),
      ProjectPackagePaths.video(package),
      ProjectPackagePaths.generated(package),
      ProjectPackagePaths.attachments(package),
      ProjectPackagePaths.thumbnails(package),
      ProjectPackagePaths.waveforms(package),
      ProjectPackagePaths.previews(package),
    ];
    for (final directory in directories) {
      await directory.create(recursive: true);
    }
  }

  String _encode(ProjectManifest manifest) {
    return const JsonEncoder.withIndent('  ').convert(manifest.toJson());
  }
}
