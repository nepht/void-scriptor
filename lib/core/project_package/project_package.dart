import 'dart:io';

import 'package:path/path.dart' as p;

final class ProjectPackage {
  const ProjectPackage({required this.projectId, required this.root});

  final String projectId;
  final Directory root;

  Directory get manifestDirectory => Directory(p.join(root.path, 'manifest'));
  File get manifestFile => File(p.join(manifestDirectory.path, 'project.json'));
  Directory get databaseDirectory => Directory(p.join(root.path, 'database'));
  File get databaseFile => File(p.join(databaseDirectory.path, 'project.db'));
  Directory get assetsDirectory => Directory(p.join(root.path, 'assets'));
  Directory get cacheDirectory => Directory(p.join(root.path, 'cache'));
  Directory get backupDirectory => Directory(p.join(root.path, 'backups'));
  Directory get exportDirectory => Directory(p.join(root.path, 'exports'));
  Directory get recoveryDirectory => Directory(p.join(root.path, 'recovery'));
  Directory get trashDirectory => Directory(p.join(root.path, 'trash'));
  File get lockFile => File(p.join(root.path, '.project.lock'));
  File get sessionFile => File(p.join(root.path, 'session.lock'));

  String resolve(String relativePath) {
    final normalized = p.posix.normalize(relativePath.replaceAll('\\', '/'));
    if (normalized == '..' || normalized.startsWith('../')) {
      throw ArgumentError.value(
        relativePath,
        'relativePath',
        'escapes package',
      );
    }
    return p.join(root.path, normalized);
  }
}
