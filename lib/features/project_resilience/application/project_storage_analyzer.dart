import 'dart:io';

import 'package:path/path.dart' as p;

import '../../../core/project_package/project_package.dart';

enum ProjectStorageCategory {
  database,
  reference,
  image,
  video,
  audio,
  generated,
  export,
  backup,
  cache,
  other,
}

class ProjectStorageFile {
  const ProjectStorageFile({
    required this.relativePath,
    required this.bytes,
    required this.category,
  });
  final String relativePath;
  final int bytes;
  final ProjectStorageCategory category;
}

class ProjectStorageReport {
  const ProjectStorageReport({required this.files});
  final List<ProjectStorageFile> files;
  int get totalBytes => files.fold(0, (sum, file) => sum + file.bytes);
  int bytesFor(ProjectStorageCategory category) => files
      .where((file) => file.category == category)
      .fold(0, (sum, file) => sum + file.bytes);
  List<ProjectStorageFile> get largestFiles =>
      [...files]..sort((a, b) => b.bytes.compareTo(a.bytes));
}

class ProjectStorageAnalyzer {
  const ProjectStorageAnalyzer(this.package);
  final ProjectPackage package;

  Future<ProjectStorageReport> analyze() async {
    final files = <ProjectStorageFile>[];
    if (await package.root.exists()) {
      await for (final entity in package.root.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          final relative = p
              .relative(entity.path, from: package.root.path)
              .replaceAll('\\', '/');
          files.add(
            ProjectStorageFile(
              relativePath: relative,
              bytes: await entity.length(),
              category: _category(relative),
            ),
          );
        }
      }
    }
    return ProjectStorageReport(files: files);
  }

  ProjectStorageCategory _category(String relative) {
    final parts = relative.split('/');
    if (relative == 'database/project.db') {
      return ProjectStorageCategory.database;
    }
    if (parts.first == 'cache') {
      return ProjectStorageCategory.cache;
    }
    if (parts.first == 'backups') {
      return ProjectStorageCategory.backup;
    }
    if (parts.first == 'exports') {
      return ProjectStorageCategory.export;
    }
    if (parts.length < 2 || parts.first != 'assets') {
      return ProjectStorageCategory.other;
    }
    return switch (parts[1]) {
      'references' => ProjectStorageCategory.reference,
      'audio' => ProjectStorageCategory.audio,
      'video' => ProjectStorageCategory.video,
      'generated' => ProjectStorageCategory.generated,
      'images' => ProjectStorageCategory.image,
      _ => ProjectStorageCategory.other,
    };
  }
}
