import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../persistence/project_manifest.dart';

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
    try {
      await _createDirectories(package);
      await ProjectDatabaseService().create(package.databaseFile.path);
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
      await package.manifestFile.writeAsString(_encode(manifest));
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
