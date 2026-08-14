import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../../core/project_package/project_package.dart';
import '../../../core/persistence/project_manifest.dart';
import 'project_resilience_repository.dart';

class ProjectIntegrityService {
  const ProjectIntegrityService(this.package);
  final ProjectPackage package;

  Future<ProjectIntegrityReport> scan({
    Set<String> referencedPaths = const {},
    bool databaseHealthy = true,
    int externalFiles = 0,
  }) async {
    var manifestValid = false;
    if (await package.manifestFile.exists()) {
      try {
        ProjectManifest.fromJson(
          jsonDecode(await package.manifestFile.readAsString())
              as Map<String, dynamic>,
        );
        manifestValid = true;
      } on Object {
        manifestValid = false;
      }
    }
    final missing = <String>{};
    for (final path in referencedPaths) {
      if (!File(package.resolve(path)).existsSync()) {
        missing.add(path);
      }
    }
    final actual = <String>{};
    if (await package.assetsDirectory.exists()) {
      await for (final entity in package.assetsDirectory.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          actual.add(
            p
                .relative(entity.path, from: package.root.path)
                .replaceAll('\\', '/'),
          );
        }
      }
    }
    final orphans = actual.difference(referencedPaths);
    return ProjectIntegrityReport(
      manifestValid: manifestValid,
      databaseValid: databaseHealthy,
      missingFiles: missing.length,
      externalFiles: externalFiles,
      orphanFiles: orphans.length,
    );
  }
}

class ProjectPathMigrator {
  const ProjectPathMigrator(this.package);
  final ProjectPackage package;
  String? migrate(String storedPath) {
    final normalized = storedPath.replaceAll('\\', '/');
    if (!p.isAbsolute(storedPath)) return normalized;
    final root = p.normalize(p.absolute(package.root.path));
    final absolute = p.normalize(p.absolute(storedPath));
    if (absolute == root || p.isWithin(root, absolute)) {
      return p.relative(absolute, from: root).replaceAll('\\', '/');
    }
    return null;
  }
}

class ProjectManifestWriter {
  const ProjectManifestWriter(this.package);
  final ProjectPackage package;
  Future<void> write(ProjectManifest manifest) async {
    final temp = File('${package.manifestFile.path}.tmp');
    final backup = File('${package.manifestFile.path}.bak');
    await temp.parent.create(recursive: true);
    await temp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
    );
    if (await package.manifestFile.exists()) {
      await package.manifestFile.copy(backup.path);
    }
    await temp.rename(package.manifestFile.path);
  }
}
